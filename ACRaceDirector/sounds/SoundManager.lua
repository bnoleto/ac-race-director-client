-- SoundManager.lua
-- Gerencia a reprodução de áudios para notificações

local SoundManager = {}
SoundManager.__index = SoundManager

function SoundManager:new()
    local o = {
        cooldown = 0
    }
    setmetatable(o, self)
    return o
end

function SoundManager:play(soundName)
    if self.cooldown > 0 then return end

    -- Caminho relativo à raiz do AC
    local filename = string.format("apps/lua/ACRaceDirector/sounds/%s", soundName)
    
    -- Tenta criar o evento de áudio (Pattern sugerido pelo usuário)
    local audio = ac.AudioEvent.fromFile({
        filename = filename,
        use3D = false,
        loop = false -- Alertas curtos não devem loopar
    })
    
    if audio then
        audio:start()
        -- Não precisamos guardar referência se é one-shot fire-and-forget
        -- O garbage collector do Lua/CSP deve lidar com isso ou o evento morre ao terminar
        self.cooldown = 0.5
    else
        Logger:log("[SoundManager] Falha ao carregar áudio: " .. filename)
    end
end

function SoundManager:update(dt)
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - dt
    end
end

return SoundManager
