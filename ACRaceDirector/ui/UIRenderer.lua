-- UIRenderer.lua
-- Responsável por desenhar a interface na tela

-- Placeholder para forçar a aparecer o display em preto (efeito piscada)
local noImage = ""

local UIRenderer = {}
UIRenderer.__index = UIRenderer

function UIRenderer:new()
    local o = {
        appFolder = ac.getFolder(ac.FolderID.ACApps) .. "/lua/ACRaceDirector/",
        animationSequences = {
            yellow = {
                frames = {
                    "flags/yellow.png",
                    noImage
                }
            },
            red = {
                frames = {
                    "flags/red.png",
                    noImage
                }
            },
            green = {
                frames = {
                    "flags/green.png",
                    noImage
                }
            },
            blue = {
                frames = {
                    "flags/blue.png",
                    noImage
                }
            },
            white = {
                frames = {
                    "flags/white.png",
                    noImage
                }
            },
            safety = {
                frames = {
                    "flags/sc1.png",
                    "flags/sc2.png",
                }
            },
            vsc = {
                frames = {
                    "flags/vsc1.png",
                    "flags/vsc2.png",
                }
            }
        }
    }
    setmetatable(o, self)
    return o
end

-- Desenha APENAS a janela de configuração
local Localization = require("regional/Localization")

-- Desenha APENAS a janela de configuração
function UIRenderer:drawConfig(connectionStatus, isConnected, host, port)

    -- Status de Conexão
    if isConnected then
        ui.textColored(Localization:get("ui.connected_full", host, port), rgbm(0, 1, 0, 1))
    else
        ui.textColored("● " .. connectionStatus, rgbm(1, 0, 0, 1))
    end
    
    ui.newLine()

    ui.separator()

    -- Seletor de Idioma
    ui.newLine()
    
    ui.text(Localization:get("ui.language_label"))
    ui.sameLine()
    
    -- Constrói lista para o Combo
    local supported = Localization.supportedLanguages or {}
    local items = {}
    local currentItem = 1
    
    -- Finding current item index
    for i, lang in ipairs(supported) do
        table.insert(items, lang.name)
        if lang.id == Localization.currentLanguage then
            currentItem = i -- ui.combo é 0-indexed
        end
    end

    -- ui.combo(label, current_item, items) -> returns new_item, changed
    local newItem, changed = ui.combo("##language", currentItem, ui.ComboFlags.None, items)
    
    if changed then
        -- newItem também é 0-indexed
        local selectedLang = supported[newItem]
        
        if selectedLang and selectedLang.id ~= Localization.currentLanguage then
            Logger:log(Localization:get("ui.changing_language", selectedLang.id))
            Localization:load(selectedLang.id)
        end
    end

    ui.newLine()
    ui.separator()
    ui.newLine()
    
    if debug then
        -- Log de Debug
        ui.newLine()
        ui.text(Localization:get("ui.log_label"))
        ui.sameLine()
        local clicked = ui.button(Localization:get("ui.copy_clipboard"))

        if clicked then
            local log = ""
            for _, entry in ipairs(Logger:getLog()) do
                log = log .. entry .. "\n"
            end
            ac.setClipboardText(log)
        end

        ui.newLine()

        ui.childWindow("messageLog", vec2(0, 100), function()
            for _, entry in ipairs(Logger:getLog()) do
                ui.text(entry)
            end
        end)
    end
end

function UIRenderer:drawHUD(notificationsState, isConnected)
    
    local notifications = notificationsState:getAll()
    
    if #notifications == 0 and isConnected then
        notificationsState:add({
            type = "system",
            color = rgbm(1,1,1,1),
            message = Localization:get("ui.no_messages"),
            duration = -1
        })
    elseif #notifications > 1 then
        for i, notif in ipairs(notifications) do
            if notif.message == Localization:get("ui.no_messages") then
                notificationsState:remove(i)
            end
        end
    end

    -- Loop reverso para desenhar
    for i, notif in ipairs(notifications) do
        ui.pushStyleVar(ui.StyleVar.WindowPadding, vec2(0,0))
        self:drawNotificationHUD(notif)
        ui.popStyleVar()
        
        -- Adiciona espaçamento entre notificações
        ui.dummy(vec2(0, 5))
    end
end

function UIRenderer:drawNotificationHUD(notif)
    -- Configuração visual
    local bgColor = rgbm(0, 0, 0, 0.25) -- Fundo mais escuro
    local cornerRadius = 15
    local padding = vec2(15, 15)
    
    -- Fade out logic
    local alpha = 1.0
    if notif.duration > 0 and notif.timer < 0.5 then 
        alpha = notif.timer / 0.5 
    end
    
    ui.pushStyleVar(ui.StyleVar.Alpha, alpha)
    
    local startCursor = ui.getCursor()
    
    -- PASS 1: Medição (Desenha invisível mas presente)
    ui.pushStyleVar(ui.StyleVar.Alpha, 0.001) -- Alpha 0 pode causar culling no ImGui do AC
    ui.beginGroup()
        self:drawContent(notif)
    ui.endGroup()
    ui.popStyleVar() -- Restaura Alpha do Pass 1
    
    local contentSize = ui.getItemRectSize()
    
    -- Desenha Fundo (Agora sabemos o tamanho)
    -- Ajusta retângulo para incluir padding
    local rectMin = startCursor
    local rectMax = startCursor + contentSize + (padding * 2)
    
    ui.drawRectFilled(rectMin, rectMax, bgColor, cornerRadius)
    
    -- PASS 2: Desenho Real (Sobre o fundo)
    ui.setCursor(startCursor + padding) -- Aplica padding
    ui.beginGroup()
        self:drawContent(notif)
    ui.endGroup()
    
    -- Aumenta cursor para o próximo item (considerando padding)
    local finalCursor = vec2(startCursor.x, rectMax.y)
    ui.setCursor(finalCursor)

    if notif.duration > 0 then
        --self:drawProgressBar(notif, rectMax.x - rectMin.x)
    end

    ui.popStyleVar() -- Restaura Alpha Geral
end

function UIRenderer:drawContent(notif)
    local iconSize = vec2(64, 56) -- Ícone Aumentado
    
    -- Ícone Piscante
    if(notif.type ~= "system") then
        self:drawIcon(notif, iconSize)
    
        ui.sameLine()
        ui.dummy(vec2(15, 0))
        ui.sameLine()
    end
    
    -- Texto
    ui.beginGroup()
        local tint = rgbm(notif.color.r, notif.color.g, notif.color.b, 1)
        
        if(notif.type ~= "system") then
            -- Título Maior e em Negrito
            ui.pushFont(ui.Font.Title) 
            ui.textColored(string.upper(notif.title), tint)
            ui.popFont()
            ui.dummy(vec2(0, 5))
        end
        
        -- Mensagem levemente maior se possível ou normal
        if(notif.type ~= "system") then
            ui.textColored(notif.message, rgbm(1,1,1,1))
        else
            ui.textColored(notif.message, notif.color)
        end

        if notif.type == "vsc" then
            local velAtual = ac.getCar(0).speedKmh
            local velLimite = 80
            local velLimiteStr = Localization:get("ui.current_speed", math.floor(velAtual))

            if velAtual > velLimite and math.floor(os.clock()*(1000/400)) % 2 == 1 then
                ui.textColored(velLimiteStr, rgbm(1,0,0,1))
            else
                ui.textColored(velLimiteStr, rgbm(1,1,1,1))
            end
        end
    ui.endGroup()
end

function UIRenderer:drawProgressBar(notif, width)
    local progress = notif.timer / notif.duration
    ui.setCursor(vec2(32, 0))
    ui.drawRectFilled(vec2(0, 0), vec2(width * progress, 1), rgbm(1, 1, 1, 0.5))
end

function UIRenderer:drawIcon(notif, size)
    local iconSize = size or vec2(64, 56)
    
    local intervaloMilissegundos = 500

    local frames = self.animationSequences[notif.type].frames
    local qtdAnimacoes = #frames

    local currentState = (math.floor(os.clock()*(1000/intervaloMilissegundos)) % (qtdAnimacoes))+1

    local iconPath
    if frames[currentState] and frames[currentState] ~= "" then
        iconPath = self.appFolder .. frames[currentState]
    end

    local cursor = ui.getCursor()
    local displaySize = iconSize

    if iconPath then
        local nativeWidth, nativeHeight = self:getPNGDimensions(iconPath)
        
        if nativeWidth and nativeHeight and nativeWidth > 0 and nativeHeight > 0 then
            local aspect = nativeWidth / nativeHeight
            local boxAspect = iconSize.x / iconSize.y
            
            if aspect > boxAspect then
                displaySize = vec2(iconSize.x, iconSize.x / aspect)
            else
                displaySize = vec2(iconSize.y * aspect, iconSize.y)
            end
        end
    end

    local offset = (iconSize - displaySize) / 2

    -- Desenha ícone centralizado e proporcional
    -- Usando ui.drawImage, passando coordenadas min e max
    local p_min = cursor + offset
    local p_max = p_min + displaySize
    
    -- Fundo escuro (display apagado)
    ui.drawRectFilled(p_min, p_max, rgbm(0.1, 0.1, 0.1, 1))

    -- PNG da bandeira se especificado que irá usar a img no frame atual, se não, não desenha nada dando o efeito de "display apagado"
    if iconPath then
        ui.drawImage(iconPath, p_min, p_max, rgbm(1, 1, 1, 1))
    end

    -- Grelha do display
    ui.drawImage(self.appFolder .. "flags/display.png", p_min, p_max, rgbm(1,1,1,1))    

    -- Padding inferior para não encostar no texto
    ui.dummy(iconSize)
end

function UIRenderer:getPNGDimensions(path)
    --[[ -- desnecessário nesse momento, usando tamanho fixo de 64x56, para melhor performance
    local f = io.open(path, "rb")
    if not f then return nil, nil end
    
    local header = f:read(24)
    f:close()
    
    if not header then return nil, nil end
    
    -- Verifica assinatura PNG
    if string.byte(header, 2) ~= 80 or string.byte(header, 3) ~= 78 or string.byte(header, 4) ~= 71 then
        return nil, nil
    end
    
    -- Width em big-endian nos bytes 17-20 (index 1-based: 17,18,19,20)
    local w1 = string.byte(header, 17)
    local w2 = string.byte(header, 18)
    local w3 = string.byte(header, 19)
    local w4 = string.byte(header, 20)
    local width = w1 * 16777216 + w2 * 65536 + w3 * 256 + w4
    
    -- Height em big-endian nos bytes 21-24 (index 1-based: 21,22,23,24)
    local h1 = string.byte(header, 21)
    local h2 = string.byte(header, 22)
    local h3 = string.byte(header, 23)
    local h4 = string.byte(header, 24)
    local height = h1 * 16777216 + h2 * 65536 + h3 * 256 + h4
    
    return width, height
     ]]
    return 64, 56
end

return UIRenderer
