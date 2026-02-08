-- TcpClient.lua
-- App principal para Assetto Corsa
-- Controlador que coordena Rede, Lógica e UI

local NotificationManager = require("ui/NotificationManager")
local TcpClientModule = require("network/TcpClientModule")
local UIRenderer = require("ui/UIRenderer")
local SoundManager = require("sounds/SoundManager")
Logger = require("others/Logger")

-- Estado do App
local state = {
    notifications = NotificationManager:new(5),
    client = nil,
    renderer = UIRenderer:new(),
    sound = SoundManager:new(),
    connectionStatus = "Inicializando...",
    init = false,
    connected = false,
    
    -- Controle Offline
    isOfflineMode = false,
    offlineTimer = 0,
    offlineMaxTime = 10, -- segundos para esconder a UI offline
    
    -- Controle Online
    waitingForServer = false
}

-- Callback de mensagens de rede
local function onNetworkMessage(msg)
    Logger:log("[ACRaceDirector] " .. msg.message or tostring(msg))

    if msg.type == "clear" then
        state.notifications:clear()
        return
    end

    -- Toca som baseado no tipo
    if msg.type then
        state.sound:play("radio.wav")
    end

    -- Adiciona via gerenciador
    state.notifications:add(msg)
    
    if msg.showInChat then
        --ac.sendChatMessage(msg.message)
    end
end

-- Helper para conectar
local function connectToServer(host, port)
    if state.client then return end -- Já tem cliente instanciado (fechar se necessário?)

    Logger:log("[ACRaceDirector] Tentando conectar em " .. host .. ":" .. port)
    state.notifications:add({
        type = "system",
        color = rgbm(1,1,1,1),
        message = "Tentando conectar ao servidor ACRD em " .. host .. ":" .. port,
        duration = 10
    })

    state.client = TcpClientModule:new({
        host = host,
        port = port,
        onConnect = function() 
            Logger:log("[ACRaceDirector] Conectado ao servidor.")
        end,
        onDisconnect = function() 
            Logger:log("[ACRaceDirector] Desconectado do servidor.")
        end
    }, state.notifications)
    state.client:connect()
    state.waitingForServer = false
end

-- Inicialização
local function initialize()
    if state.init then return end
    state.init = true
    
    Logger:log("[ACRaceDirector] Inicializando...")
    
    local sim = ac.getSim()
    
    if not sim.isOnlineRace then
        -- MODO OFFLINE
        state.isOfflineMode = true
        state.connectionStatus = "Race Director não disponível offline"
        Logger:log("[ACRaceDirector] Modo Offline detectado. Cliente não será executado.")
    else
        -- MODO ONLINE
        state.isOfflineMode = false
        state.waitingForServer = true
        state.connectionStatus = "Aguardando servidor..."
        Logger:log("[ACRaceDirector] Modo Online. Tentando obter dados do servidor ACRD...")
        
        -- Listener de Chat para descobrir servidor
        ac.onOnlineWelcome(function(msg, extraData)
             -- Padrão esperado: RD:HOST:PORT 
             -- Exemplo: RD:127.0.0.1:5000

            if string.startsWith(msg, "RD:") then
                local parts = string.split(msg, ":") 
                -- parts[1] = "RD", parts[2] = HOST, parts[3] = PORT
                
                if #parts >= 3 then
                    local host = parts[2]
                    local port = tonumber(parts[3])
                    
                    if host and port then
                        Logger:log("[ACRaceDirector] Obtido servidor ACRD no host: " .. host .. " / porta: " .. port)
                        connectToServer(host, port)
                    end
                end
            else
                Logger:log("[ACRaceDirector] Servidor não utiliza ACRD. Interrompendo inicialização.")
                state.waitingForServer = false
                state.connectionStatus = "ACRD não disponível neste servidor."
                state.notifications:add({
                    type = "system",
                    color = rgbm(1,1,1,1),
                    message = "Servidor não utiliza ACRD. Interrompendo inicialização.",
                    duration = 10
                })
            end
        end)
    end
end

-- Função Principal (Main Loop)
-- Lógica Compartilhada (Executada por qualquer janela ativa)
local lastUpdateTime = 0

local function updateAppLogic(dt)
    -- Evita atualização dupla no mesmo frame (se ambas janelas estiverem abertas)
    local now = os.clock()
    if math.abs(now - lastUpdateTime) < 0.001 then
        return
    end
    lastUpdateTime = now

    initialize()
    
    -- Se offline, contar tempo
    if state.isOfflineMode then
        state.offlineTimer = state.offlineTimer + dt
    end
    
    -- 1. Atualiza Rede
    if state.client then
        state.client:update(dt, state.notifications)
        
        if state.client:isConnected() then
            state.connectionStatus = "Conectado"
        else
            state.connected = false
            state.connectionStatus = "Tentando conexão..."
            state.notifications:add({
                type = "system",
                color = rgbm(1,1,1,1),
                message = "Tentando conexão.",
                duration = 10
            })
        end
        
        -- Processa fila de mensagens
        local messages = state.client:getMessages()
        for _, msg in ipairs(messages) do
            onNetworkMessage(msg)
        end
    elseif state.waitingForServer then
        state.connectionStatus = "Carregando Race Director..."
        state.notifications:add({
            type = "system",
            color = rgbm(1,1,1,1),
            message = "Carregando Race Director.",
            duration = 10
        })
    end
    
    -- 2. Atualiza Lógica (Timers e Sons)
    state.notifications:update(dt)
    state.sound:update(dt)
end

-- Função Principal Janela Configs
function raceControlMain(dt)
    updateAppLogic(dt)
    
    -- 3. Desenha UI de Configuração
    state.renderer:drawConfig(
        state.connectionStatus,
        state.client and state.client:isConnected(),
        (state.client and state.client.host) or "---",
        (state.client and state.client.port) or "---"
    )
end

-- Função Principal Janela HUD (Transparente)
function hudMain(dt)
    updateAppLogic(dt)
    
    -- Se estiver offline e passou do tempo, não desenha nada (fade out visual seria no renderer, mas aqui ocultamos tudo)
    if state.isOfflineMode and state.offlineTimer > state.offlineMaxTime then
        return
    end
    
    -- HUD Apenas desenha as notificações ativas ou status
    state.renderer:drawHUD(state.notifications, state.client and state.client:isConnected())
end
