script_version('1.4.3');

local sampev = require('lib.samp.events')
local imgui = require('mimgui');
local encoding = require('encoding');
encoding.default = 'CP1251'
u8 = encoding.UTF8
local inicfg = require('inicfg');
local ffi = require('ffi');
local monet_no_errors, moon_monet = pcall(require, 'MoonMonet')

local directIni = 'AutoPiarSadist.ini'
local lastSendKeyMessage = os.time()
local stateLastSendKeyMessage = false

local ini = inicfg.load(inicfg.load({
    main = {
        enabled = false,
        vrAdvertisementSend = true,
        inactiveShutdown = false,
        sleepInactiveShutdown = 1
    },
    delays = {
        s = 30,
        j = 30,
        vr = 30,
        fb = 30,
        f = 30,
        fam = 30,
        rb = 30,
        al = 30,
        jb = 30,
		gd = 30,
        ad = 30,
    },
    toggle = {
        s = false,
        j = false,
        vr = false,
        fb = false,
        f = false,
        fam = false,
        rb = false,
        al = false,
        jb = false,
		gd = false,
        ad = false,
    },
    ad = {
        type = 1,
        centr = 1
    },
    input = {
        s = "",
        j = "",
        vr = "",
        fb = "",
        f = "",
        fam = "",
        rb = "",
        al = "",
        jb = "",
		gd = "",
        ad = "",
    },
    lastSend = {
        s = 0,
        j = 0,
        vr = 0,
        fb = 0,
        f = 0,
        fam = 0,
        rb = 0,
        al = 0,
        jb = 0,
		gd = 0,
        ad = 0,
    }
}, directIni))

ini.main.enabled = false
inicfg.save(ini, directIni)

local SaveCfg = function()
    inicfg.save(ini, directIni)
end


local vrAdvertisementSend = imgui.new.bool(ini.main.vrAdvertisementSend)
local inactiveShutdown = imgui.new.bool(ini.main.inactiveShutdown)
local sleepInactiveShutdown = imgui.new.int(tonumber(ini.main.sleepInactiveShutdown))
local toggleScript = imgui.new.bool(ini.main.enabled)
local delays = {
    ["s"] = imgui.new.int(ini.delays.s),
    ["j"] = imgui.new.int(ini.delays.j),
    ["vr"] = imgui.new.int(ini.delays.vr),
    ["fb"] = imgui.new.int(ini.delays.fb),
    ["f"] = imgui.new.int(ini.delays.f),
    ["fam"] = imgui.new.int(ini.delays.fam),
    ["rb"] = imgui.new.int(ini.delays.rb),
    ["al"] = imgui.new.int(ini.delays.al),
    ["jb"] = imgui.new.int(ini.delays.jb),
	["gd"] = imgui.new.int(ini.delays.gd),
    ["ad"] = imgui.new.int(ini.delays.ad)
}

local toggle = {
    ["s"] = imgui.new.bool(ini.toggle.s),
    ["j"] = imgui.new.bool(ini.toggle.j),
    ["vr"] = imgui.new.bool(ini.toggle.vr),
    ["fb"] = imgui.new.bool(ini.toggle.fb),
    ["f"] = imgui.new.bool(ini.toggle.f),
    ["fam"] = imgui.new.bool(ini.toggle.fam),
    ["rb"] = imgui.new.bool(ini.toggle.rb),
    ["al"] = imgui.new.bool(ini.toggle.al),
    ["jb"] = imgui.new.bool(ini.toggle.jb),
	["gd"] = imgui.new.bool(ini.toggle.gd),
    ["ad"] = imgui.new.bool(ini.toggle.ad)
}

local ad = {
    ["type"] = imgui.new.int(ini.ad.type),
    ["centr"] = imgui.new.int(ini.ad.centr),
}


local input = {
    ["s"] = imgui.new.char[256](tostring(ini.input.s)),
    ["j"] = imgui.new.char[256](tostring(ini.input.j)),
    ["vr"] = imgui.new.char[256](tostring(ini.input.vr)),
    ["fb"] = imgui.new.char[256](tostring(ini.input.fb)),
    ["f"] = imgui.new.char[256](tostring(ini.input.f)),
    ["fam"] = imgui.new.char[256](tostring(ini.input.fam)),
    ["rb"] = imgui.new.char[256](tostring(ini.input.rb)),
    ["al"] = imgui.new.char[256](tostring(ini.input.al)),
    ["jb"] = imgui.new.char[256](tostring(ini.input.jb)),
	["gd"] = imgui.new.char[256](tostring(ini.input.gd)),
    ["ad"] = imgui.new.char[256](tostring(ini.input.ad))
}

local item_listTypeCombo = {u8('Обычное'), u8('VIP'), u8('Реклама бизнеса')}
local ImItemsTypeCombo = imgui.new['const char*'][#item_listTypeCombo](item_listTypeCombo)

local item_listCentrCombo = {u8('Автоматически'), u8('SF'), u8('LV'), u8('LS')}
local ImItemsCentrCombo = imgui.new['const char*'][#item_listCentrCombo](item_listCentrCombo)

local vrSended = false
local advSended = {
    ["state"] = false,
    ["msg"] = ""
}

local ui_meta = {
    __index = function(self, v)
        if v == "switch" then
            local switch = function()
                if self.process and self.process:status() ~= "dead" then
                    return false 
                end
                self.timer = os.clock()
                self.state = not self.state

                self.process = lua_thread.create(function()
                    local bringFloatTo = function(from, to, start_time, duration)
                        local timer = os.clock() - start_time
                        if timer >= 0.00 and timer <= duration then
                            local count = timer / (duration / 100)
                            return count * ((to - from) / 100)
                        end
                        return (timer > duration) and to or from
                    end

                    while true do wait(0)
                        local a = bringFloatTo(0.00, 1.00, self.timer, self.duration)
                        self.alpha = self.state and a or 1.00 - a
                        if a == 1.00 then break end
                    end
                end)
                return true
            end
            return switch
        end
 
        if v == "alpha" then
            return self.state and 1.00 or 0.00
        end
    end
}

local menu = { state = false, duration = 0.5 }
setmetatable(menu, ui_meta)


imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    theme()
end)

imgui.OnFrame(
    function() return menu.alpha > 0.00 end,
    function(player)
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 1000, 870
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        player.HideCursor = not menu.state
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, menu.alpha)
        if imgui.Begin('AutoPiarSadist | ' .. thisScript().version, _, imgui.WindowFlags.NoResize) then
            
            
            imgui.Columns(3, "##mainColumns", false)
            imgui.SetColumnWidth(0, 380)  
            imgui.SetColumnWidth(1, 100)  
            imgui.SetColumnWidth(2, 480)  

            
            local function drawCommandRow(cmd, sliderMin, sliderMax, tooltip)
                
                imgui.PushItemWidth(350)
                if imgui.InputText("###input"..cmd, input[cmd], 256) then
                    ini.input[cmd] = ffi.string(input[cmd])
                    ini.main.enabled = false
                    toggleScript[0] = false
                    SaveCfg()
                end
                imgui.NextColumn()
                
                
                if imgui.ToggleButton("/"..cmd.."###OnOrDisable"..cmd, toggle[cmd]) then
                    ini.lastSend[cmd] = 0
                    ini.toggle[cmd] = toggle[cmd][0]
                    SaveCfg()
                end
                imgui.NextColumn()
                
                
                imgui.PushItemWidth(450)
                if imgui.SliderInt("###Slider"..cmd, delays[cmd], sliderMin, sliderMax, u8'%d cек') then
                    ini.delays[cmd] = delays[cmd][0]
                    SaveCfg()
                end
                if tooltip and imgui.IsItemHovered() then
                    imgui.BeginTooltip()
                    imgui.Text(tooltip)
                    imgui.EndTooltip()
                end
                imgui.NextColumn()
            end

            
            drawCommandRow("s", 1, 660)
            drawCommandRow("j", 1, 660)
            drawCommandRow("vr", 1, 660)
            drawCommandRow("fb", 1, 660)
            drawCommandRow("f", 1, 660)
            drawCommandRow("fam", 1, 660)
            drawCommandRow("rb", 1, 660)
            drawCommandRow("al", 1, 660)
            drawCommandRow("jb", 1, 660)
            drawCommandRow("gd", 1, 660)
            
            imgui.Columns(1)  
            imgui.Separator()

            
            imgui.Columns(3, "##adColumns", false)
            imgui.SetColumnWidth(0, 380)
            imgui.SetColumnWidth(1, 100)
            imgui.SetColumnWidth(2, 480)
            drawCommandRow("ad", 30, 660)
            imgui.Columns(1)
            
            
            imgui.SetCursorPosX(50)
            imgui.PushItemWidth(200)
            if imgui.Combo(u8("##com3"), ad["type"], ImItemsTypeCombo, #item_listTypeCombo) then
                ini.ad.type = ad["type"][0]
                ini.main.enabled = false
                toggleScript[0] = false
                SaveCfg()
            end
            
            imgui.SameLine()
            imgui.SetCursorPosX(300)
            imgui.PushItemWidth(200)
            if imgui.Combo(u8("Радиоцентр##com4"), ad["centr"], ImItemsCentrCombo, #item_listCentrCombo) then
                ini.ad.centr = ad["centr"][0]
                ini.main.enabled = false
                toggleScript[0] = false
                SaveCfg()
            end
            
            
            imgui.Separator()

            
            if imgui.Checkbox(u8('Отправка рекламой в випчат'), vrAdvertisementSend) then
                ini.main.vrAdvertisementSend = vrAdvertisementSend[0]
                ini.main.enabled = false
                toggleScript[0] = false
                SaveCfg()
            end
            
            
     
            
            imgui.Spacing()
            if imgui.ToggleButton(u8("Состояние скрипта###scriptToggle"), toggleScript) then
                ini.main.enabled = toggleScript[0]
            end
            
           
            
            

            imgui.End()
        end
        imgui.PopStyleVar()
    end
)

function imgui.Tooltip(text)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(text)
        imgui.EndTooltip()
    end
end

function imgui.ToggleButton(str_id, bool)
    local rBool = false

    if LastActiveTime == nil then
        LastActiveTime = {}
    end
    if LastActive == nil then
        LastActive = {}
    end

    local function ImSaturate(f)
        return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
    end

    local p = imgui.GetCursorScreenPos()
    local dl = imgui.GetWindowDrawList()

    local height = imgui.GetTextLineHeightWithSpacing()
    local width = height * 1.70
    local radius = height * 0.50
    local ANIM_SPEED = type == 2 and 0.10 or 0.15
    local butPos = imgui.GetCursorPos()

    if imgui.InvisibleButton(str_id, imgui.ImVec2(width, height)) then
        bool[0] = not bool[0]
        rBool = true
        LastActiveTime[tostring(str_id)] = os.clock()
        LastActive[tostring(str_id)] = true
    end

    imgui.SetCursorPos(imgui.ImVec2(butPos.x + width + 8, butPos.y + 2.5))
    imgui.Text( str_id:gsub('##.+', '') )

    local t = bool[0] and 1.0 or 0.0

    if LastActive[tostring(str_id)] then
        local time = os.clock() - LastActiveTime[tostring(str_id)]
        if time <= ANIM_SPEED then
            local t_anim = ImSaturate(time / ANIM_SPEED)
            t = bool[0] and t_anim or 1.0 - t_anim
        else
            LastActive[tostring(str_id)] = false
        end
    end

    local col_circle = bool[0] and imgui.ColorConvertFloat4ToU32(imgui.ImVec4(imgui.GetStyle().Colors[imgui.Col.ButtonActive])) or imgui.ColorConvertFloat4ToU32(imgui.ImVec4(imgui.GetStyle().Colors[imgui.Col.TextDisabled]))
    dl:AddRectFilled(p, imgui.ImVec2(p.x + width, p.y + height), imgui.ColorConvertFloat4ToU32(imgui.GetStyle().Colors[imgui.Col.FrameBg]), height * 0.5)
    dl:AddCircleFilled(imgui.ImVec2(p.x + radius + t * (width - radius * 2.0), p.y + radius), radius - 1.5, col_circle)
    return rBool
end

function imgui.Link(link, text)
    text = text or link
    local tSize = imgui.CalcTextSize(text)
    local p = imgui.GetCursorScreenPos()
    local DL = imgui.GetWindowDrawList()
    local col = { 0xFFFF7700, 0xFFFF9900 }
    if imgui.InvisibleButton("##" .. link, tSize) then os.execute("explorer " .. link) end
    local color = imgui.IsItemHovered() and col[1] or col[2]
    DL:AddText(p, color, text)
    DL:AddLine(imgui.ImVec2(p.x, p.y + tSize.y), imgui.ImVec2(p.x + tSize.x, p.y + tSize.y), color)
end

function sms(text)
	local text = text:gsub('{mc}', '{3487ff}')
	sampAddChatMessage('[AutoPiarSadist] {FFFFFF}' .. tostring(text), 0x3487ff)
end

function main()
    while true do if isSampAvailable() and sampIsLocalPlayerSpawned() then break end wait(0) end
    sms("Успешно загружено! Активация: {mc}/autor")
    sampRegisterChatCommand('autor', function()
        menu.switch()
    end)

    sampRegisterChatCommand('adv', function (arg)
        if #arg < 1 then
            sms('Использование команды: {mc}/adv [message]')
        elseif toggle["ad"][0] and toggleScript[0] then
            sms('Данную команду можно использовать при отключенной авторекламе во избежание багов.')
        elseif #arg < 20 or #arg > 80 then
            sms('В тексте объявления должно быть от 20 до 80 символов.')
        else
            advSended.state = true
            advSended.msg = arg
            sampSendChat('/ad')
        end
    end)

    wait(3000)

    while true do
        if toggleScript[0] then
            if not stateLastSendKeyMessage and inactiveShutdown[0] and os.time() - lastSendKeyMessage > tonumber(sleepInactiveShutdown[0]) * 60 then
                stateLastSendKeyMessage = true
                sms('Состояние скрипта {mc}приостоновлено{FFFFFF}! Обнаружена не активность в течение {mc}' .. sleepInactiveShutdown[0] * 60 .. '{FFFFFF} секунд!')
            elseif not stateLastSendKeyMessage then
                for index, value in pairs(toggle) do
                    if value[0] and ini.lastSend[index] < os.time() then
                        ini.lastSend[index] = os.time() + delays[index][0]
                        SaveCfg()
                        if index == 'vr' then
                            vrSended = true
                        end
                        sampSendChat('/'..index..' '..u8:decode(ffi.string(input[index])))
                        wait(100)
                    end
                end
            end
        end
        wait(0)
    end
end


function sampev.onServerMessage(clr, text)
    if toggle["ad"][0] and toggleScript[0] and not advSended.state then
        local text = text:gsub("{......}","")
        if text:find("Объявление") and text:find(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))) and clr == 1941201407 then
            lua_thread.create(function()
                local currentTime = os.time()
                local difference = os.difftime(currentTime, startTime)
                wait(1000)
                if difference >= delays["ad"][0] + 1 then
                    sampSendChat('/ad')
                else
                    local timeLeft = delays["ad"][0] + 1 - difference
                    sms("/ad - Еще не прошло "..delays["ad"][0].." секунд, отправлю через {mc}"..timeLeft.." секунд")
                    ini.lastSend["ad"] = os.time() + timeLeft
                end
            end)
        end
        if (text:find("Используйте: /ad %[текст объявления%]") or text:find("Ваше сообщение зарегистрировано в системе и будет опубликовано после редакции!")) then
            return false
        end
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if (toggle["ad"][0] and toggleScript[0]) or advSended.state then
        if title:find("Подача объявления") and text:find("Напишите текст объявление") and not advSended.state then
            sampSendDialogResponse(id, 1, 65535, u8:decode(ffi.string(input['ad'])))
            return false
        elseif title:find("Подача объявления") and text:find("Напишите текст объявление") and advSended.state then
            sampSendDialogResponse(id, 1, 65535, advSended.msg)
            return false
        end
        if title:find("Выберите радиостанцию") and text:find("Радиостанция") then
            local lines = {}
            local line_count = 0
            for line in text:gmatch("[^\r\n]+") do
                if not line:find("{[a-fA-F0-9]+}") then
                    line_count = line_count + 1
                    lines[line_count] = line
                end
            end
            local line1, line2, line3 = lines[1], lines[2], lines[3]
            local hour1, hour2, hour3, min1, min2, min3, sec1, sec2, sec3
            local totalsec1, totalsec2, totalsec3 = 9999, 9998, 9997
            if line1:find("час") then
                hour1, min1, sec1 = line1:match("(%d+) час (%d+) мин (%d+) сек")
                totalsec1 = hour1 * 360 + min1 * 60 + sec1
            elseif line1:find("мин") and not line1:find("час") then
                min1, sec1 = line1:match("(%d+) мин (%d+) сек")
                totalsec1 = min1 * 60 + sec1
            elseif line1:find("сек") and not line1:find("мин") then
                sec1 = line1:match("(%d+) сек")
                totalsec1 = sec1
            end
            if line2:find("час") then
                hour2, min2, sec2 = line2:match("(%d+) час (%d+) мин (%d+) сек")
                totalsec2 = hour2 * 360 + min2 * 60 + sec2
            elseif line2:find("мин") and not line2:find("час") then
                min2, sec2 = line2:match("(%d+) мин (%d+) сек")
                totalsec2 = min2 * 60 + sec2
            elseif line2:find("сек") and not line2:find("мин") then
                sec2 = line2:match("(%d+) сек")
                totalsec2 = sec2
            end
            if line3:find("час") then
                hour3, min3, sec3 = line3:match("(%d+) час (%d+) мин (%d+) сек")
                totalsec3 = hour3 * 360 + min3 * 60 + sec3
            elseif line3:find("мин") and not line3:find("час") then
                min3, sec3 = line3:match("(%d+) мин (%d+) сек")
                totalsec3 = min3 * 60 + sec3
            elseif line3:find("сек") and not line3:find("мин") then
                sec3 = line3:match("(%d+) сек")
                totalsec3 = sec3
            end

            if tonumber(totalsec1) < tonumber(totalsec2) and tonumber(totalsec1) < tonumber(totalsec3) and ad["centr"][0] == 0 then
                sampSendDialogResponse(id,1,0,"")
                sms('/ad - Последняя редакция была в Радиоцентре Лос-Сантос')
            elseif tonumber(totalsec2) < tonumber(totalsec1) and tonumber(totalsec2) < tonumber(totalsec3) and ad["centr"][0] == 0 then
                sampSendDialogResponse(id,1,1,"")
                sms('/ad - Последняя редакция была в Радиоцентре Лас-Вентурас')
            elseif tonumber(totalsec3) < tonumber(totalsec1) and tonumber(totalsec3) < tonumber(totalsec2) and ad["centr"][0] == 0 then
                sampSendDialogResponse(id,1,2,"")
                sms('/ad - Последняя редакция была в Радиоцентре Сан-Фиерро')
            else
                if ad["centr"][0] == 1 then
                    sampSendDialogResponse(id,1,2,"")
                elseif ad["centr"][0] == 2 then
                    sampSendDialogResponse(id,1,1,"")
                elseif ad["centr"][0] == 3 then
                    sampSendDialogResponse(id,1,0,"")
                end
            end
            return false
        end
        if title:find("Подача объявления") and text:find("Выберите тип объявления") then
            if ad["type"][0] == 0 then
                sampSendDialogResponse(id,1,0,"")
            elseif ad["type"][0] == 1 then
                sampSendDialogResponse(id,1,1,"")
            else
                sampSendDialogResponse(id,1,3,"")
            end
            return false
        end
        if title:find("Подача объявления %| Подтверждение") then
            sampSendDialogResponse(id,1,65535,"")
            startTime = os.time()
            return false
        end
    end
    if id == 25623 or 25624 and vrSended then
        vrSended = false
        sampSendDialogResponse(id, ini.main.vrAdvertisementSend and 1 or 0, 65535, "")
        return false
    end
    if id == 15379 and ini.toggle.ad and toggleScript[0] and not advSended.state then
        ini.lastSend['ad'] = os.time() + delays['ad'][0]
        sms('/ad - Объявление не отредактировали, повторная попытка через {mc}'.. delays['ad'][0] .. ' секунд')
        sampSendDialogResponse(id, 0, 65535, "")
        return false
    end
end

function onWindowMessage(msg, wparam, lparam)
    if msg == 0x100 or msg == 0x101 or msg == 523 or msg == 513 or msg == 516 then
        if (wparam == menu.state) and not isPauseMenuActive() then
            consumeWindowMessage(true, false);
            if msg == 0x101 then menu.switch() end
        end
        lastSendKeyMessage = os.time()

        if stateLastSendKeyMessage then
            sms('Работа скрипта {mc}возобновлена{FFFFFF}!')
            stateLastSendKeyMessage = false
        end
    end
end

function explode_argb(argb)
    local a = bit.band(bit.rshift(argb, 24), 0xFF)
    local r = bit.band(bit.rshift(argb, 16), 0xFF)
    local g = bit.band(bit.rshift(argb, 8), 0xFF)
    local b = bit.band(argb, 0xFF)
    return a, r, g, b
end

function ColorAccentsAdapter(color)
    local a, r, g, b = explode_argb(color)
    local ret = {a = a, r = r, g = g, b = b}
    function ret:apply_alpha(alpha)
        self.a = alpha
        return self
    end
    function ret:as_u32()
        return join_argb(self.a, self.b, self.g, self.r)
    end
    function ret:as_vec4()
        return imgui.ImVec4(self.r / 255, self.g / 255, self.b / 255, self.a / 255)
    end
    function ret:as_argb()
        return join_argb(self.a, self.r, self.g, self.b)
    end
    function ret:as_rgba()
        return join_argb(self.r, self.g, self.b, self.a)
    end
    function ret:as_chat()
        return string.format("%06X", ARGBtoRGB(join_argb(self.a, self.r, self.g, self.b)))
    end  
    return ret
end

function theme()
    local generated_color = moon_monet.buildColors(40703, 1.0, true)
	imgui.SwitchContext()
	imgui.GetStyle().WindowPadding = imgui.ImVec2(5 * 1.0, 5 * 1.0)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5 * 1.0, 5 * 1.0)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5 * 1.0, 5 * 1.0)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2 * 1.0, 2 * 1.0)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
    imgui.GetStyle().IndentSpacing = 0
    imgui.GetStyle().ScrollbarSize = 10 * 1.0
    imgui.GetStyle().GrabMinSize = 10 * 1.0
    imgui.GetStyle().WindowBorderSize = 1 * 1.0
    imgui.GetStyle().ChildBorderSize = 1 * 1.0
    imgui.GetStyle().PopupBorderSize = 1 * 1.0
    imgui.GetStyle().FrameBorderSize = 1 * 1.0
    imgui.GetStyle().TabBorderSize = 1 * 1.0
	imgui.GetStyle().WindowRounding = 8 * 1.0
    imgui.GetStyle().ChildRounding = 8 * 1.0
    imgui.GetStyle().FrameRounding = 8 * 1.0
    imgui.GetStyle().PopupRounding = 8 * 1.0
    imgui.GetStyle().ScrollbarRounding = 8 * 1.0
    imgui.GetStyle().GrabRounding = 8 * 1.0
    imgui.GetStyle().TabRounding = 8 * 1.0
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
	imgui.GetStyle().Colors[imgui.Col.Text] = ColorAccentsAdapter(generated_color.accent2.color_50):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.TextDisabled] = ColorAccentsAdapter(generated_color.neutral1.color_600):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.WindowBg] = ColorAccentsAdapter(generated_color.accent2.color_900):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.ChildBg] = ColorAccentsAdapter(generated_color.accent2.color_800):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.PopupBg] = ColorAccentsAdapter(generated_color.accent2.color_700):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.Border] = ColorAccentsAdapter(generated_color.accent1.color_200):apply_alpha(0xcc):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.Separator] = ColorAccentsAdapter(generated_color.accent1.color_200):apply_alpha(0xcc):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
	imgui.GetStyle().Colors[imgui.Col.FrameBg] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0x60):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.FrameBgHovered] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0x70):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.FrameBgActive] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0x50):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.TitleBg] = ColorAccentsAdapter(generated_color.accent2.color_700):apply_alpha(0xcc):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed] = ColorAccentsAdapter(generated_color.accent2.color_700):apply_alpha(0x7f):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.TitleBgActive] = ColorAccentsAdapter(generated_color.accent2.color_700):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.MenuBarBg] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0x91):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0,0,0,0)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0x85):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered] = ColorAccentsAdapter(generated_color.accent1.color_600):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0xb3):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.CheckMark] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0xcc):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.SliderGrab] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0xcc):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.SliderGrabActive] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0x80):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.Button] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0xcc):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = ColorAccentsAdapter(generated_color.accent1.color_200):apply_alpha(0xb3):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.ButtonActive] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0xb3):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.Tab] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0xcc):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.TabActive] = ColorAccentsAdapter(generated_color.accent1.color_200):apply_alpha(0xb3):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.TabHovered] = ColorAccentsAdapter(generated_color.accent1.color_200):apply_alpha(0xb3):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.Header] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0xcc):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.HeaderHovered] = ColorAccentsAdapter(generated_color.accent1.color_600):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.HeaderActive] = ColorAccentsAdapter(generated_color.accent1.color_600):apply_alpha(0xb3):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.ResizeGrip] = ColorAccentsAdapter(generated_color.accent2.color_700):apply_alpha(0xcc):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered] = ColorAccentsAdapter(generated_color.accent2.color_700):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.ResizeGripActive] = ColorAccentsAdapter(generated_color.accent2.color_700):apply_alpha(0xb3):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.PlotLines] = ColorAccentsAdapter(generated_color.accent2.color_600):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered] = ColorAccentsAdapter(generated_color.accent1.color_600):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.PlotHistogram] = ColorAccentsAdapter(generated_color.accent2.color_600):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered] = ColorAccentsAdapter(generated_color.accent1.color_600):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.TextSelectedBg] = ColorAccentsAdapter(generated_color.accent1.color_600):as_vec4()
	imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg] = ColorAccentsAdapter(generated_color.accent1.color_200):apply_alpha(0x99):as_vec4()
end
