local Localization = {}
local Logger = require("others/Logger")

Localization.currentLanguage = "en" -- Default language
Localization.strings = {}

-- Lista de idiomas suportados (ID deve bater com nome do arquivo em locales/)
Localization.supportedLanguages = {
    { id = "en",    name = "English" },
    { id = "pt_BR", name = "Português (Brasil)" }
}

function Localization:load(lang)
    self.currentLanguage = lang
    local success, result = pcall(require, "regional/locales/" .. lang)
    if success then
        self.strings = result
        Logger:log(self:get("log.loc_loaded", lang))
        ac.storage("acrd_language", nil):set(lang)
    else
        Logger:log(self:get("log.loc_load_error", lang, tostring(result)))
        -- Fallback to empty or keep previous
        self.strings = {} 
    end
end

function Localization:get(key, ...)
    local val = self.strings[key] or "(missing string)[" .. key .. "]"
    if select("#", ...) > 0 then
        return string.format(val, ...)
    end
    return val
end

function Localization:getSupportedLanguages()
    return self.supportedLanguages
end

function Localization:detectSystemLanguage()
    -- Attempt to detect system language
    -- In Assetto Corsa Lua, ac.getSim() might return system info, or we use os.getenv
    local sysLang = "en"
    
    -- Try standard OS environment variables
    local osLang = os.getenv("LANG") or os.getenv("LANGUAGE")
    if osLang then
        if string.find(osLang, "pt_BR") or string.find(osLang, "pt-BR") then
            sysLang = "pt_BR"
        elseif string.find(osLang, "en") then
            sysLang = "en"
        end
    end

    return sysLang
end

function Localization:initialize()
    
    languageSelected = ac.storage("acrd_language", nil):get() or self:detectSystemLanguage() or "en"
    self:load(languageSelected)
end

return Localization
