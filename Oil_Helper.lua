local sampev = require('lib.samp.events')

-- buy
-- install 
-- deinstall
-- sell
local status = ''

function main()
    
    sampRegisterChatCommand('oil_sell', function ()
        status = 'deinstall'
        msg('Установлен статус: разгрузка и продажа бочек')
    end)

end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if title:find('Покупка бочки') then
        sampSendDialogResponse(id, 1, 0, 0)
        msg('Бочка нефти успешно куплена!')
        status = 'install'
        return false
    end
    if title:find('Бочки в транспорте') then
        for line in string.gmatch(text, "[^\r\n]+") do
            if status == 'install' and line:find('%№(%d+).+Положить') then
                local i = line:match('%№(%d+).+Положить')
                sampSendDialogResponse(id, 1, i - 1, 0)
                return false
            end
            if status == 'deinstall' and line:find('%№(%d+).+Забрать') then
                local i = line:match('%№(%d+).+Забрать')
                sampSendDialogResponse(id, 1, i - 1, 0)
                return false
            end
        end
    end
end
function sampev.onServerMessage(color, text)
    if text:find('Вы успешно продали бочку с .+ литров нефти и получили (.+) AZ-Coins') then
        status = 'deinstall'
    end
    if text:find('Режим погрузки включен') then
        -- status = 'deinstall'
    end
end
function sampev.onDisplayGameText(style, time, text)
    if text:find('%~b%~PRESS%: %~w%~H') and status == 'install' then
        msg('Устанавливаю бочку в грузовик')
        sendClickKeySync(192)
        status = ''
    end
    if text:find('~b~PRESS%: ~w~ALT') and status == 'deinstall' then
        msg('Достаю бочку из грузовика')
        sendAlt()
    end
end

function sendClickKeySync(key)
    local data = allocateMemory(68)
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    sampStorePlayerOnfootData(myId, data)

    local weaponId = getCurrentCharWeapon(PLAYER_PED)
    setStructElement(data, 36, 1, weaponId + tonumber(key), true)
    sampSendOnfootData(data)
    freeMemory(data)
end
function sendAlt()
    lua_thread.create(function () 
        setGameKeyState(21, 255)
        wait(200)
        setGameKeyState(21, -255)
    end)
end

function msg(text)
    sampAddChatMessage('[Oil Helper by MTG MODS] {ffffff}' .. text, 0x00bfff)
end