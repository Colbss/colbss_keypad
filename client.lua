

local txReplaceDict, txReplaceName = 'm23_1_prop_m31_keypad_01a', 'prop_ld_keypad'
local propHash = `m23_1_prop_m31_keypad_01a`
local keypadHandle = nil

function CreateDUI()

    local duiHandle = lib.dui:new({
        url = ("nui://%s/html/ui.html"):format(cache.resource), 
        width = 512, 
        height = 1024,
        debug = true
    })
    lib.waitFor(function()
        if duiHandle ~= nil and duiHandle.dictName ~= nil and duiHandle.txtName ~= nil then return true end
    end)    
    AddReplaceTexture(txReplaceDict, txReplaceName, duiHandle.dictName, duiHandle.txtName)
    Wait(500)
    duiHandle:sendMessage({
        action = "STATE",
        value = true
    })

end

function CreateKeypad(x, y, z, w)
    local prop = CreateObject(propHash, x, y, z, true, false, false)
    SetEntityHeading(prop, w)
    exports.ox_target:addLocalEntity(prop, {
        {
            name = 'keypad_interaction',
            icon = 'fas fa-hashtag',
            label = 'Interact with Keypad',
            onSelect = function(data)
                print('Interact !')
            end
        }
    })
    return prop
end


AddEventHandler('onResourceStart', function (resource)
    if resource ~= GetCurrentResourceName() then return end

    CreateDUI()
    keypadHandle = CreateKeypad(1525.56, 1825.29, 106.68 , 69.22)

end)

AddEventHandler('onResourceStop', function (resource)
    if resource ~= GetCurrentResourceName() then return end

	-- Remove the replacement when the script ends
	RemoveReplaceTexture(txReplaceDict, txReplaceName)
    DeleteEntity(keypadHandle)

end)
