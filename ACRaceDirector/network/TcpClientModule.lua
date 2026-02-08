-- TcpClientModule.lua
-- Cliente TCP usando a API shared/socket do Custom Shaders Patch

local socket = require('shared/socket')

local TcpClient = {
    host = "127.0.0.1",
    port = 5001,
    
    -- Estados: "DISCONNECTED", "CONNECTING", "CONNECTED"
    state = "DISCONNECTED",
    connection = nil,
    
    -- Timers
    reconnectTimer = 0,
    reconnectInterval = 5.0,
    
    lastKeepAliveTime = 0,
    keepAliveTimeout = 8.0, -- Timeout para considerar conexão morta se não receber PING
    
    connectTimeoutTimer = 0,
    connectTimeoutMax = 10.0, -- Máximo tempo aguardando socket ficar pronto
    
    -- Throttling
    updateTimer = 0,
    updateInterval = 0.1, -- 10Hz (atualiza rede 10 vezes por segundo)
    
    messageQueue = {},
    receiveBuffer = "",
    
    onMessage = nil,
    onConnect = nil,
    onDisconnect = nil,
    handshakePending = false,
    notifications = nil
}

function TcpClient:new(config, notifications)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    if notifications then
        obj.notifications = notifications
    end
    
    if config then
        obj.host = config.host or self.host
        obj.port = config.port or self.port
        obj.onMessage = config.onMessage
        obj.onConnect = config.onConnect
        obj.onDisconnect = config.onDisconnect
    end
    
    obj.messageQueue = {}
    obj.receiveBuffer = ""
    obj.reconnectTimer = 0
    obj.lastKeepAliveTime = 0
    obj.state = "DISCONNECTED"
    obj.updateTimer = 0
    
    return obj
end

function TcpClient:connect()
    if self.state ~= "DISCONNECTED" then
        return true
    end
    
    Logger:log("[TcpClient] Iniciando conexão com " .. self.host .. ":" .. self.port)
    
    -- Cria conexão TCP
    self.connection = socket.tcp()
    
    if not self.connection then
        Logger:log("[TcpClient] Erro ao criar socket TCP")
        return false
    end
    
    -- Timeout 0 para non-blocking
    self.connection:settimeout(0)
    
    -- Desabilita Nagle's algorithm para envio imediato de pacotes pequenos
    self.connection:setoption('tcp-nodelay', true)
    
    local success, err = self.connection:connect(self.host, self.port)
    
    if success then
        -- Conectou imediatamente (raro em non-blocking remoto)
        self:setConnected()
        return true
    elseif err == "timeout" or err == "Operation already in progress" then
        -- Conexão iniciada, aguardando handshake
        self.state = "CONNECTING"
        self.connectTimeoutTimer = 0
        Logger:log("[TcpClient] Conexão em andamento...")
        return true
    else
        -- Erro real
        Logger:log("[TcpClient] Erro imediato ao conectar: " .. tostring(err))
        self:disconnect()
        return false
    end
end

function TcpClient:setConnected()
    if self.state == "CONNECTED" then return end
    
    self.state = "CONNECTED"
    self.lastKeepAliveTime = os.clock() -- Reseta timer de keepalive ao conectar
    Logger:log("[TcpClient] Conexão estabelecida com sucesso!")
    
    -- Envia Handshake para o servidor
    if self.connection then
        local sent, err = self.connection:send("HANDSHAKE:AC_CLIENT_V1:"..ac.getDriverName(0).."\r\n")
        if sent then
            Logger:log("[TcpClient] Handshake enviado: " .. sent .. " bytes.")
            self.notifications:add({
                type = "system",
                color = rgbm(0,1,0,1),
                message = "Conectado.",
                duration = 10
            })
        else
            Logger:log("[TcpClient] Erro ao enviar handshake: " .. tostring(err) .. ". Tentando novamente em breve...")
            -- Se falhou (timeout/wouldblock), agendamos uma retentativa rápida via update()
            -- Mas aqui, como estamos assumindo conectado, talvez devêssemos forçar um envio no próximo update
            self.handshakePending = true 
        end
    end
    
    if self.onConnect then
        self.onConnect()
    end
end

function TcpClient:disconnect()
    -- Se já está desconectado, não faz nada (evita loops)
    if self.state == "DISCONNECTED" and not self.connection then
        return
    end
    
    if self.connection then
        self.connection:close()
        self.connection = nil
    end
    
    local wasConnected = (self.state == "CONNECTED")
    self.state = "DISCONNECTED"
    self.receiveBuffer = ""
    self.reconnectTimer = 0 -- Reset timer para começar a contar do zero
    
    if wasConnected then
        Logger:log("[TcpClient] Desconectado.")
        if self.onDisconnect then
            self.onDisconnect()
        end
    end
end

function TcpClient:update(dt, notifications)
    -- Atualiza timers globais independente da rede
    if self.state == "DISCONNECTED" then
        self.reconnectTimer = self.reconnectTimer + dt
    elseif self.state == "CONNECTING" then
        self.connectTimeoutTimer = self.connectTimeoutTimer + dt
    end

    -- Throttling de I/O
    self.updateTimer = self.updateTimer + dt
    if self.updateTimer < self.updateInterval then
        return
    end
    self.updateTimer = 0 -- Reset timer

    -- Máquina de Estados (Executada a cada ~100ms)
    if self.state == "DISCONNECTED" then
        if self.reconnectTimer >= self.reconnectInterval then
            self.reconnectTimer = 0
            self:connect(notifications)
        end
        
    elseif self.state == "CONNECTING" then
        -- Verifica se socket está gravável
        local writable = socket.select(nil, {self.connection}, 0)
        
        if writable and #writable > 0 then
            self:setConnected()
            return
        end

        -- Tenta verificar conexão via getpeername (bypass do select se falhar)
        if self.connection:getpeername() then
            self:setConnected()
            return
        end

        -- Fallback/Timeout
        self.connectTimeoutTimer = self.connectTimeoutTimer + dt
        if self.connectTimeoutTimer > self.connectTimeoutMax then
            -- Se passou do tempo e não deu erro (o socket não fechou), 
            -- mas o select não retornou writable...
            -- O servidor diz que conectou. Vamos assumir conectado e deixar o receive falhar se for mentira.
            Logger:log("[TcpClient] Timeout de handshake, mas forçando estado CONECTADO (fallback).")
            self:setConnected()
            return
        end
        
    elseif self.state == "CONNECTED" then
        -- Tenta reenviar handshake se pendente
        if self.handshakePending then
             local sent, err = self.connection:send("HANDSHAKE:AC_CLIENT_V1:"..ac.getDriverName(0).."\r\n")
             if sent then
                 Logger:log("[TcpClient] Handshake reenviado com sucesso.")
                 self.handshakePending = false
             end
        end

        -- Verifica KeepAlive
        if os.clock() - self.lastKeepAliveTime > self.keepAliveTimeout then
            Logger:log("[TcpClient] Timeout de conexão (sem PING do servidor).")
            self:disconnect()
            return
        end
        
        self:receiveMessages()
    end
end
function TcpClient:receiveMessages()
    if not self.connection then
        self:disconnect()
        return
    end
    
    -- Lê dados
    local data, err, partial = self.connection:receive("*l")
    
    if data then
        self:processMessage(data)
        -- Tenta ler mais
        self:receiveMessages()
    elseif err == "closed" then
        Logger:log("[TcpClient] Socket fechado pelo servidor.")
        self:disconnect()
    elseif err == "timeout" then
        -- Normal, sem dados
        if partial and partial ~= "" then
            self.receiveBuffer = self.receiveBuffer .. partial
        end
    else
        Logger:log("[TcpClient] Erro de recepção: " .. tostring(err))
        self:disconnect()
    end
end

function TcpClient:processMessage(message)
    if not message or message == "" then return end
    
    -- Limpa lixo/BOM se houver
    local cleanMessage = string.match(message, "[A-Z0-9].*") or message
    
    -- Exemplo de parser (mantendo lógica anterior)
    -- Formato: COMMAND|DURATION|MESSAGE
    -- Ou outros formatos
    local parts = {}
    for part in string.gmatch(cleanMessage, "([^|]+)") do
        table.insert(parts, part)
    end
    
    -- Se string.gmatch não pegou nada (sem pipes), assume mensagem inteira
    if #parts == 0 then table.insert(parts, cleanMessage) end
    
    local parsedData = nil
    
    if #parts >= 1 then
        local command = parts[1]
        local duration = tonumber(parts[2]) or -1
        local msgText = parts[3] or ""
        
        -- Mapeamentos simples
        local map = {
            YELLOW = { type="yellow", title="BANDEIRA AMARELA" },
            RED = { type="red", title="BANDEIRA VERMELHA" },
            GREEN = { type="green", title="BANDEIRA VERDE" },
            SC = { type="safety", title="SAFETY CAR" },
            VSC = { type="vsc", title="VIRTUAL SAFETY CAR" },
            RACE = { type="race", title="DIREÇÃO DE PROVA" },
            CLEAR = { type="clear" },
            PING = { type="ping" } -- Comando interno
        }
        
        local info = map[command]
        if info then
            if info.type == "ping" then
                -- Responde ao Heartbeat
                if self.connection then
                    self.connection:send("PONG\n")
                end
                self.lastKeepAliveTime = os.clock()
                return -- Não propaga PING para a UI
            end

            parsedData = {
                type = info.type,
                title = info.title,
                message = msgText,
                duration = duration,
                showInChat = true
            }
        end
    end

    if parsedData then
        table.insert(self.messageQueue, parsedData)
        if self.onMessage then self.onMessage(parsedData) end
    end
end

function TcpClient:getMessages()
    local messages = self.messageQueue
    self.messageQueue = {}
    return messages
end

function TcpClient:isConnected()
    return self.state == "CONNECTED"
end

return TcpClient
