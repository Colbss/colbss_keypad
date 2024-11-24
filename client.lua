local txReplaceDict, txReplaceName = 'ch_prop_casino_keypads', 'prop_ld_keypad'
local propHash = `ch_prop_casino_keypad_01`
local keypadHandle = nil
local keypadCam = nil
local duiHandle = nil
local prevButtonID = -1
local codeInput = ''
local passcode = 0

local buttonCamRots = {
    [1] = vec3(-3.52, 0.0, 98.37),
    [2] = vec3(-3.46, 0.0, 93.21),
    [3] = vec3(-3.40, 0.0, 87.85),
    [4] = vec3(-8.56, 0.0, 98.50),
    [5] = vec3(-8.56, 0.0, 93.27),
    [6] = vec3(-8.56, 0.0, 87.92),
    [7] = vec3(-13.35, 0.0, 98.63),
    [8] = vec3(-13.48, 0.0, 93.21),
    [9] = vec3(-13.54, 0.0, 87.86),
    [10] = vec3(-17.95, 0.0, 98.44), -- Cancel
    [11] = vec3(-18.20, 0.0, 93.21), -- 0
    [12] = vec3(-18.20, 0.0, 87.79)  -- #
}
local buttonThreshold = 2.5

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
        action = "KEYPAD",
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
                TransitionToKeypadCam(data.entity) 
            end
        }
    })
    return prop
end

function CalculateInitialCameraRotation(fromCoords, toCoords)
    local dir = toCoords - fromCoords
    local yaw = math.atan2(-dir.x, dir.y)
    local heading = yaw * (180.0 / math.pi)
    return vec3(0.0, 0.0, heading)
end

function TransitionToKeypadCam(prop)
    -- Get the keypad's coordinates
    local keypadCoords = GetEntityCoords(prop)

    -- Offset the camera to be in front of the keypad
    local camOffset = GetOffsetFromEntityInWorldCoords(prop, 0.0, -0.25, 0.0)

    -- Create a new camera
    keypadCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(keypadCam, camOffset.x, camOffset.y, camOffset.z)
    local initialRot = CalculateInitialCameraRotation(camOffset, keypadCoords)
    SetCamRot(keypadCam, initialRot.x, initialRot.y, initialRot.z, 2)
    SetCamActive(keypadCam, true)
    RenderScriptCams(true, true, 1000, true, true)
    
    FreezeEntityPosition(cache.ped, true)
    TriggerEvent('zoom:updateBlock', true)
    TriggerEvent('hud:client:ToggleHUD', false)

    CreateThread(function()
        Wait(1000)
        SendNUIMessage({
            action = 'MOUSE',
            value = true
        })
    end)

    local camRot = initialRot
    local btnLookingAt = -1

    -- Track the camera's rotation and determine which button is being looked at
    CreateThread(function()
        while DoesCamExist(keypadCam) and IsCamActive(keypadCam) do

            DisableAllControlActions(0)
            local xMagnitude = GetDisabledControlNormal(0, 1) * 8.0 -- Mouse X
            local yMagnitude = GetDisabledControlNormal(0, 2) * 8.0 -- Mouse Y
            camRot = vector3(math.clamp(camRot.x - yMagnitude, -23.0, 15.0), camRot.y, math.clamp(camRot.z - xMagnitude, 75.0, 105.0))
            SetCamRot(keypadCam, camRot.x, camRot.y, camRot.z, 2)

            -- Check which button the camera is looking at
            for buttonId, buttonRot in pairs(buttonCamRots) do
                if IsCameraLookingAtButton(camRot, buttonRot) then
                    btnLookingAt = buttonId
                end
            end

            if btnLookingAt ~= -1 then 
                HighlightButton(btnLookingAt)
            else
                HighlightButton(0)
            end

            if IsDisabledControlJustPressed(0, 24)  then -- ESC or Back
                -- exports.qbx_core:Notify('Click Button ' .. btnLookingAt, 'success')
                ClickButton(btnLookingAt)
            end

            if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177) then -- ESC or Back
                ResetToDefaultCam()
                break
            end

            btnLookingAt = -1
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
    HighlightButton(0)
    -- Unfreeze player
    FreezeEntityPosition(cache.ped, false)
    TriggerEvent('zoom:updateBlock', false)
    TriggerEvent('hud:client:ToggleHUD', true)
    SendNUIMessage({
        action = 'MOUSE',
        value = false
    })
    codeInput = ''
    duiHandle:sendMessage({
        action = "DISPLAY",
        value = 'ENTER CODE'
    })
end

-- Converts rotation angles to a direction vector
function RotationToDirection(rotation)
    local radZ = math.rad(rotation.z)
    local radX = math.rad(rotation.x)
    local cosX = math.cos(radX)
    return vec3(-math.sin(radZ) * cosX, math.cos(radZ) * cosX, math.sin(radX))
end

-- Check if the camera is looking at a button
function IsCameraLookingAtButton(camRot, buttonRot)
    -- Calculate the angular difference for each axis (X, Y, Z)
    local deltaX = math.abs(camRot.x - buttonRot.x)
    local deltaY = math.abs(camRot.y - buttonRot.y)
    local deltaZ = math.abs(camRot.z - buttonRot.z)

    -- Check if all differences are within the threshold
    return deltaX <= buttonThreshold and deltaY <= buttonThreshold and deltaZ <= buttonThreshold
end

-- Helper to clamp values
function math.clamp(value, min, max)
    return math.max(min, math.min(value, max))
end

function PlayKeypadSound(sType)
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

function ClickButton(buttonId)

    if buttonId ~= 12 then
        PlayKeypadSound(1)
    end

    if ((buttonId > 0 and buttonId < 10) or buttonId == 11) and #codeInput < 5 then
        if buttonId == 11 then buttonId = 0 end
        codeInput = tostring(codeInput) .. tostring(buttonId)
        duiHandle:sendMessage({
            action = "DISPLAY",
            value = codeInput
        })
    elseif buttonId == 10 then -- Cancel
        codeInput = ''
        duiHandle:sendMessage({
            action = "DISPLAY",
            value = 'ENTER CODE'
        })
    elseif buttonId == 12 then -- Submit
        if codeInput == code then
            PlayKeypadSound(3)
            duiHandle:sendMessage({
                action = "DISPLAY",
                value = 'SUCCESS'
            })
        else
            codeInput = ''
            PlayKeypadSound(2)
            duiHandle:sendMessage({
                action = "DISPLAY",
                value = 'INVALID'
            })
        end
    end


end

-- Highlight a button (optional)
function HighlightButton(buttonId)
    if prevButtonID ~= buttonId then
        duiHandle:sendMessage({
            action = "BUTTON",
            value = buttonId
        })
        prevButtonID = buttonId
    end
end

-- Create the keypad and start the resource
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CreateDUI()
    keypadHandle = CreateKeypad(1557.11, 2160.97, 79.15, 90.51)

    code = tostring(math.random(11111,99999))
    print('Code : ' .. code)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    -- Cleanup on resource stop
    RemoveReplaceTexture(txReplaceDict, txReplaceName)
    DeleteEntity(keypadHandle)
    ResetToDefaultCam()
end)

