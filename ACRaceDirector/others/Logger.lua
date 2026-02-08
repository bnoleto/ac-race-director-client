-- Logger.lua
-- Para ajudar a debugar e ao mesmo tempo mostrar no AC com timestamp

local Logger = {
    messageLog = {},
}
Logger.__index = Logger

function Logger:new()
    local o = setmetatable({
        messageLog = {},
    }, self)
    return o
end

function Logger:log(message)
    if not message then 
        message = "nil"
    end

    local message = os.date("[%Y-%m-%d %H:%M:%S]") .. ": " .. tostring(message)
    ac.log(message)
    
    table.insert(self.messageLog, message)
end

function Logger:getLog()
    return self.messageLog
end

return Logger