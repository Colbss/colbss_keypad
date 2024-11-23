local txReplaceDict, txReplaceName = 'm23_1_prop_m31_keypad_01a', 'prop_ld_keypad'
local propHash = `m23_1_prop_m31_keypad_01a`
local keypadHandle = nil
local keypadCam = nil -- To hold the camera handle
local duiHandle = nil

function CreateDUI()
    if duiHandle ~= nil then return end
    duiHandle = lib.dui:new({
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
                TransitionToKeypadCam(data.entity) -- Transition to keypad camera
            end
        }
    })
    return prop
end

function TransitionToKeypadCam(prop)
    -- Get the keypad's coordinates
    local propCoords = GetEntityCoords(prop)

    -- Offset the camera to be in front of the keypad
    local camOffset = GetOffsetFromEntityInWorldCoords(prop, 0.0, -0.2, 0.0)

    SendDuiMouseMove(duiHandle.duiObject, 109, 580)

    -- Create a new camera
    keypadCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(keypadCam, camOffset.x, camOffset.y, camOffset.z)
    PointCamAtCoord(keypadCam, propCoords.x, propCoords.y, propCoords.z)
    SetCamActive(keypadCam, true)
    RenderScriptCams(true, true, 1000, true, true)

    -- Listen for escape/back input to reset the camera
    CreateThread(function()
        while DoesCamExist(keypadCam) and IsCamActive(keypadCam) do
            if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 200) then -- Back or Escape
                ResetToDefaultCam()
            end
            Wait(0)
        end
    end)
end

function ResetToDefaultCam()
    -- Reset the camera to the player's default view
    if DoesCamExist(keypadCam) then
        RenderScriptCams(false, true, 1000, true, true)
        DestroyCam(keypadCam, false)
        keypadCam = nil
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    CreateDUI()
    keypadHandle = CreateKeypad(1525.56, 1825.29, 106.68 , 69.22)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    -- Remove the replacement when the script ends
    RemoveReplaceTexture(txReplaceDict, txReplaceName)
    DeleteEntity(keypadHandle)

    -- Ensure camera is reset
    ResetToDefaultCam()
end)
