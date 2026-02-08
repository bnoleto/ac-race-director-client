-- NotificationManager.lua
-- Gerencia a lista de notificações, tempos de vida e cores

local NotificationManager = {}
NotificationManager.__index = NotificationManager

-- Definição de cores
local eventColors = {
    yellow = {r = 1, g = 0.9, b = 0, a = 1},      -- Amarelo
    red = {r = 1, g = 0, b = 0, a = 1},           -- Vermelho
    green = {r = 0, g = 1, b = 0, a = 1},         -- Verde
    blue = {r = 0.2, g = 0.5, b = 1, a = 1},      -- Azul
    white = {r = 1, g = 1, b = 1, a = 1},         -- Branco
}

function NotificationManager:new(maxNotifications)
    local o = {
        items = {},
        maxItems = 999
    }
    setmetatable(o, self)
    return o
end

function NotificationManager:add(item)

    -- Verifica se já existe para não duplicar
    for _, v in ipairs(self.items) do
        if v.message == item.message then
            return
        end
    end
    
    if not item.color then
        -- Define cor baseada no tipo ou flag
        if item.type == "yellow" then
            item.color = eventColors.yellow
        elseif item.type == "red" then
            item.color = eventColors.red
        elseif item.type == "green" then
            item.color = eventColors.green
        elseif item.type == "blue" then
            item.color = eventColors.blue
        elseif item.type == "white" then
            item.color = eventColors.white
        elseif item.type == "safety" then
            item.color = eventColors.yellow
        elseif item.type == "vsc" then
            item.color = eventColors.yellow
        else
            item.color = eventColors.white
        end
    end
    
    -- Configura timer
    item.timer = item.duration or -1

    -- Insere no início
    table.insert(self.items, 1, item)

    -- Limita tamanho
    while #self.items > self.maxItems do
        table.remove(self.items)
    end
    
    Logger:log("[NotificationManager] Adicionada: " .. tostring(item.title))
end

function NotificationManager:update(dt)
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        
        -- Se duration > 0, decrementa
        if item.duration > 0 then
            item.timer = item.timer - dt
            if item.timer <= 0 then
                table.remove(self.items, i)
            end
        end
    end
end

function NotificationManager:clear()
    for i = #self.items, 1, -1 do
        if self.items[i].duration == -1 then
            self.items[i].duration = 1
        end
    end
    Logger:log("[NotificationManager] Limpar tudo")
end

function NotificationManager:getAll()
    return self.items
end

function NotificationManager:remove(index)
    self.items[index].duration = 1
end

return NotificationManager
