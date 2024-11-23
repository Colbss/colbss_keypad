local txReplaceDict, txReplaceName = 'ch_prop_casino_keypads', 'prop_ld_keypad'
local propHash = `ch_prop_casino_keypad_01`
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

    -- Create a new camera
    keypadCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(keypadCam, camOffset.x, camOffset.y, camOffset.z)
    PointCamAtCoord(keypadCam, propCoords.x, propCoords.y, propCoords.z)
    SetCamActive(keypadCam, true)
    RenderScriptCams(true, true, 1000, true, true)

    -- Enable mouse input tracking
    local duiObj = duiHandle.duiObject -- Assuming this is your current DUI handle
    local duiWidth, duiHeight = 512, 1024 -- Match your DUI's dimensions
    local mouseEnabled = true

    --SetNuiFocus(false, true)
    FreezeEntityPosition(cache.ped, true)
    duiHandle:sendMessage({
        action = "MOUSE",
        value = true
    })
    TriggerEvent('zoom:updateBlock', true)
    TriggerEvent('hud:client:ToggleHUD', false)

    -- Track mouse movement and clicks
    CreateThread(function()
        while DoesCamExist(keypadCam) and IsCamActive(keypadCam) and mouseEnabled do
            -- Capture normalized mouse position (0.0 to 1.0)
            local mouseX = GetControlNormal(0, 239) -- Horizontal mouse movement
            local mouseY = GetControlNormal(0, 240) -- Vertical mouse movement

            -- Scale mouse position to DUI resolution
            local scaledX = math.floor(mouseX * duiWidth)
            local scaledY = math.floor(mouseY * duiHeight)

            -- Send the mouse movement to the DUI
            SendDuiMouseMove(duiObj, scaledX, scaledY)

            -- Handle mouse down
            if IsControlJustPressed(0, 24) then -- Left mouse button
                SendDuiMouseDown(duiObj, "left")
            end

            -- Handle mouse up
            if IsControlJustReleased(0, 24) then -- Left mouse button
                SendDuiMouseUp(duiObj, "left")
            end

            Wait(0)
        end
    end)

    -- Listen for escape/back input to reset the camera
    CreateThread(function()
        while DoesCamExist(keypadCam) and IsCamActive(keypadCam) do
            
            if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 200) then -- Back or Escape
                mouseEnabled = false -- Stop tracking mouse input
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
    --SetNuiFocus(false, false)
    FreezeEntityPosition(cache.ped, false)
    duiHandle:sendMessage({
        action = "MOUSE",
        value = false
    })
    TriggerEvent('zoom:updateBlock', false)
    TriggerEvent('hud:client:ToggleHUD', true)
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    CreateDUI()
    keypadHandle = CreateKeypad(1525.56, 1825.29, 106.68 , 69.22) -- keypadHandle = CreateKeypad(1530.86,1831.26,105.87, -8.51)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    -- Remove the replacement when the script ends
    RemoveReplaceTexture(txReplaceDict, txReplaceName)
    DeleteEntity(keypadHandle)

    -- Ensure camera is reset
    ResetToDefaultCam()
end)
