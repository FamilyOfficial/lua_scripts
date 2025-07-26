script_name('AutoStyle')
script_author('Theopka')

local sampev = require('lib.samp.events')
local active = false

function sampev.onShowDialog(did, style, title, button1, button2, text)
    if active then
        if string.find(title, 'Меню группы') then
            if string.find(text, 'COMFORT') then
                sampSendDialogResponse(did, 1, 0, 0)
                active = false
            elseif string.find(text, 'SPORT') then
                sampSendDialogResponse(did, 0, 0, 0)
                active = false
            end
            return false
        end
    end
end

function sampev.onServerMessage(color, text)
    if text:find('Этот транспорт зарегистрирован на жителя') then
        active = true
        sampSendChat('/style')
    end
end

function main()
    if not isSampAvailable() then return end
    
    while true do
        wait(0)
    end
end