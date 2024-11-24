local txReplaceDict, txReplaceName = 'ch_prop_casino_keypads', 'prop_ld_keypad'
local propHash = `ch_prop_casino_keypad_01`
local keypadHandle = nil
local keypadCam = nil -- To hold the camera handle
local duiHandle = nil

local code = 0

local buttonOffsets = {
    [1] = vec3(0,0,0),
    [2] = vec3(0,0,0),
    [3] = vec3(0,0,0),
    [4] = vec3(0,0,0),
    [5] = vec3(0,0,0),
    [6] = vec3(0,0,0),
    [7] = vec3(0,0,0),
    [8] = vec3(0,0,0),
    [9] = vec3(0,0,0),
    [10] = vec3(0,0,0), -- Cancel
    [11] = vec3(0,0,0), -- 0
    [12] = vec3(0,0,0), -- #
}

function CreateDUI()
    if duiHandle ~= nil then return end
    duiHandle = lib.dui:new({
        url = ("nui://%s/html/ui.html"):format(cache.resource), 
        width = 512, 
        height = 1024,
        debug = false
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

function TransitionToKeypadCam(prop, xMulti, yMulti)
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
    local duiWidth, duiHeight = 512, 1024 -- Your DUI resolution
    local mouseEnabled = true

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

            -- Disable all controls
            DisableAllControlActions(0)

            -- Enable necessary mouse controls
            EnableControlAction(0, 1, true) -- Look left/right
            EnableControlAction(0, 2, true) -- Look up/down
            EnableControlAction(0, 239, true) -- Cursor X
            EnableControlAction(0, 240, true) -- Cursor Y
            EnableControlAction(0, 24, true) -- Left click
            EnableControlAction(0, 25, true) -- Right click (if needed)
            EnableControlAction(0, 237, true) -- Left click confirm

            -- Capture normalized mouse position (0.0 to 1.0)
            local mouseX = GetControlNormal(0, 239) -- Horizontal mouse movement
            local mouseY = GetControlNormal(0, 240) -- Vertical mouse movement

            -- Scale mouse position to DUI resolution with multiplier
            local scaledX = math.floor(mouseX * duiWidth)
            local scaledY = math.floor(mouseY * duiHeight)

            -- Send the mouse movement to the DUI
            SendDuiMouseMove(duiObj, scaledX, scaledY)

            -- Handle mouse down
            if IsDisabledControlPressed(0, 24) then -- Left mouse button
                SendDuiMouseDown(duiObj, "left")
            end

            -- Handle mouse up
            if IsDisabledControlPressed(0, 24) then -- Left mouse button
                SendDuiMouseUp(duiObj, "left")
            end

            Wait(0)
        end
    end)

    -- Listen for escape/back input to reset the camera
    CreateThread(function()
        while DoesCamExist(keypadCam) and IsCamActive(keypadCam) do
            
            if IsDisabledControlPressed(0, 177) or IsDisabledControlPressed(0, 200) then -- Back or Escape
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

function PlayKeypadSound(sType)   -- Type 1 : Pan, Type 2: Camera Switch
    local sounds = {
        [1] = { -- Key press
            name = "Press",
            ref = "DLC_SECURITY_BUTTON_PRESS_SOUNDS"
        },
        [2] = { -- Error
            name = "Hack_Fail",
            ref = "DLC_sum20_Business_Battle_AC_Sounds"
        },
        [3] = { -- Success
            name = "Keypad_Access",
            ref = "DLC_Security_Data_Leak_2_Sounds"
        }

    }
    sid = GetSoundId()
    PlaySoundFrontend(sid, sounds[sType].name, sounds[sType].ref, 1)
    ReleaseSoundId(sid)
end

function CheckInput(input)
    print('Input : ' .. input .. ' | Code : ' .. code)
    if tonumber(input) == code then
        PlayKeypadSound(3)
        duiHandle:sendMessage({
            action = "INPUT",
            value = true
        })
    else
        PlayKeypadSound(2)
        duiHandle:sendMessage({
            action = "INPUT",
            value = false
        })
    end

end

RegisterNUICallback("button", function(data, cb)
    PlayKeypadSound(1)
end)

RegisterNUICallback("submit", function(data, cb)
    CheckInput(data.value)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    code = math.random(11111,99999)
    print('Code : ' .. code)
    CreateDUI()
    keypadHandle = CreateKeypad(1557.11,2160.97,79.15,90.51) -- keypadHandle = CreateKeypad(1530.86,1831.26,105.87, -8.51)
    -- 1557.11,2160.97,79.15,90.51
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    -- Remove the replacement when the script ends
    RemoveReplaceTexture(txReplaceDict, txReplaceName)
    DeleteEntity(keypadHandle)

    -- Ensure camera is reset
    ResetToDefaultCam()
end)
