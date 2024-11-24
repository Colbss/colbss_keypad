local txReplaceDict, txReplaceName = 'ch_prop_casino_keypads', 'prop_ld_keypad'
local propHash = `ch_prop_casino_keypad_01`
local keypadHandle = nil
local keypadCam = nil
local duiHandle = nil

local buttonOffsets = {
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

    -- Calculate initial rotation to face the keypad
    local initialRot = CalculateInitialCameraRotation(camOffset, keypadCoords)
    SetCamRot(keypadCam, initialRot.x, initialRot.y, initialRot.z, 2)

    SetCamActive(keypadCam, true)
    RenderScriptCams(true, true, 1000, true, true)
    
    local defaultFOV = GetCamFov(keypadCam)

    -- Freeze player controls   
    FreezeEntityPosition(cache.ped, true)
    TriggerEvent('zoom:updateBlock', true)
    TriggerEvent('hud:client:ToggleHUD', false)

    local camRot = initialRot

    -- Track the camera's rotation and determine which button is being looked at
    CreateThread(function()
        while DoesCamExist(keypadCam) and IsCamActive(keypadCam) do
            -- Disable player controls but allow mouse input
            DisableAllControlActions(0)

            -- Get mouse input
            local xMagnitude = GetDisabledControlNormal(0, 1) * 8.0 -- Mouse X
            local yMagnitude = GetDisabledControlNormal(0, 2) * 8.0 -- Mouse Y
            camRot = vector3(math.clamp(camRot.x - yMagnitude, -23.0, 15.0), camRot.y, math.clamp(camRot.z - xMagnitude, 75.0, 105.0)) ----
            SetCamRot(keypadCam, camRot.x, camRot.y, camRot.z, 2)
            print('Cam (' .. tostring(keypadCam) .. ') Rot : ' .. tostring(camRot))

            -- Check which button the camera is looking at
            local camDirection = RotationToDirection(camRot)
            for buttonId, offset in pairs(buttonOffsets) do
                local buttonCoords = keypadCoords + offset
                if IsCameraLookingAtButton(keypadCoords, camDirection, buttonCoords) then
                    HighlightButton(buttonId) -- Highlight or interact with the button
                end
            end

            -- Exit interaction on Escape
            if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177) then -- ESC or Back
                ResetToDefaultCam()
                break
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
    -- Unfreeze player
    FreezeEntityPosition(cache.ped, false)
end

-- Converts rotation angles to a direction vector
function RotationToDirection(rotation)
    local radZ = math.rad(rotation.z)
    local radX = math.rad(rotation.x)
    local cosX = math.cos(radX)
    return vec3(-math.sin(radZ) * cosX, math.cos(radZ) * cosX, math.sin(radX))
end

-- Check if the camera is looking at a button
function IsCameraLookingAtButton(keypadCoords, camDirection, buttonCoords)
    local toButton = buttonCoords - keypadCoords
    toButton = toButton / #(toButton) -- Normalize vector
    local dot = camDirection.x * toButton.x + camDirection.y * toButton.y + camDirection.z * toButton.z
    return dot > 0.98 -- Adjust threshold as needed
end

-- Highlight a button (optional)
function HighlightButton(buttonId)
    print("Looking at button:", buttonId)
    -- Add highlighting logic or button interaction here
end

-- Create the keypad and start the resource
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CreateDUI()
    keypadHandle = CreateKeypad(1557.11, 2160.97, 79.15, 90.51)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    -- Cleanup on resource stop
    RemoveReplaceTexture(txReplaceDict, txReplaceName)
    DeleteEntity(keypadHandle)
    ResetToDefaultCam()
end)

-- Helper to clamp values
function math.clamp(value, min, max)
    return math.max(min, math.min(value, max))
end
