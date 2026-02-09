-- TcpClient.lua
-- App principal para Assetto Corsa
-- Controlador que coordena Rede, Lógica e UI

local NotificationManager = require("ui/NotificationManager")
local TcpClientModule = require("network/TcpClientModule")
local UIRenderer = require("ui/UIRenderer")
local SoundManager = require("sounds/SoundManager")
Logger = require("others/Logger")
local Localization = require("regional/Localization")

-- Usando variável global para debug
debug = false

-- Inicializa sistema de localização
Localization:initialize()

-- Estado do App
local state = {
    notifications = NotificationManager:new(5),
    client = nil,
    renderer = UIRenderer:new(),
    sound = SoundManager:new(),
    connectionStatus = Localization:get("system.initializing"),
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
    Logger:log(Localization:get("log.acrd_message_format", msg.message or tostring(msg)))

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

    Logger:log(Localization:get("system.connecting", host, port))
    state.notifications:add({
        type = "system",
        color = rgbm(1,1,1,1),
        message = Localization:get("system.connecting", host, port),
        duration = 10
    })

    state.client = TcpClientModule:new({
        host = host,
        port = port,
        onConnect = function() 
            Logger:log(Localization:get("system.connected"))
        end,
        onDisconnect = function() 
            Logger:log(Localization:get("system.disconnected"))
        end
    }, state.notifications)
    state.client:connect()
    state.waitingForServer = false
end

-- Inicialização
local function initialize()
    if state.init then return end
    state.init = true
    
    Logger:log(Localization:get("log.acrd_initializing"))
    
    local sim = ac.getSim()
    
    if not sim.isOnlineRace then
        -- MODO OFFLINE
        state.isOfflineMode = true
        state.connectionStatus = Localization:get("status.race_director_unavailable")
        Logger:log(Localization:get("system.offline_mode"))
    else
        -- MODO ONLINE
        state.isOfflineMode = false
        state.waitingForServer = true
        state.connectionStatus = Localization:get("status.waiting")
        Logger:log(Localization:get("system.online_mode"))
        
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
                        Logger:log(Localization:get("system.server_found", host, port))
                        connectToServer(host, port)
                    end
                end
            else
                Logger:log(Localization:get("system.server_not_using_acrd"))
                state.waitingForServer = false
                state.connectionStatus = Localization:get("status.acrd_unavailable")
                state.notifications:add({
                    type = "system",
                    color = rgbm(1,1,1,1),
                    message = Localization:get("system.server_not_using_acrd"),
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
            state.connectionStatus = Localization:get("status.connected")
        else
            state.connected = false
            state.connectionStatus = Localization:get("status.connecting")
            state.notifications:add({
                type = "system",
                color = rgbm(1,1,1,1),
                message = Localization:get("status.connecting"),
                duration = 10
            })
        end
        
        -- Processa fila de mensagens
        local messages = state.client:getMessages()
        for _, msg in ipairs(messages) do
            onNetworkMessage(msg)
        end
    elseif state.waitingForServer then
        state.connectionStatus = Localization:get("status.loading")
        state.notifications:add({
            type = "system",
            color = rgbm(1,1,1,1),
            message = Localization:get("status.loading"),
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
