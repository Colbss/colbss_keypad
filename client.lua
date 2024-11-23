
--[[

	Keypads
	
		h4_prop_h4_ld_keypad_01.ydr
		hei_prop_hei_keypad_03.ydr
		hei_prop_hei_keypad_01.ydr
		m23_1_prop_m31_keypad_01a.ydr
		
	Security Panel
	
		v_corp_bk_secpanel.ydr
		ba_prop_battle_security_pad.ydr

    Scanner
        w_am_digiscanner_reh

]]--

-- local txReplaceDict, txReplaceName = 'w_am_digiscanner_reh', 'script_rt_digiscanner_reh'
-- local propHash = `w_am_digiscanner_reh`

local txReplaceDict, txReplaceName = 'm23_1_prop_m31_keypad_01a', 'prop_ld_keypad'
local propHash = `m23_1_prop_m31_keypad_01a`


local x, y, z = 1525.56, 1825.29, 106.68 
local keypadProp = CreateObject(propHash, x, y, z, true, false, false)
SetEntityHeading(keypadProp, 69.22)

local duiHandle = lib.dui:new({
	url = ("nui://%s/html/ui.html"):format(cache.resource), 
	width = 512, 
	height = 1024,
	debug = true
})

lib.waitFor(function()
    if duiHandle ~= nil and duiHandle.dictName ~= nil and duiHandle.txtName ~= nil then return true end
end)
print('Wait For Complete !')



-- Replace the texture of the prop
AddReplaceTexture(txReplaceDict, txReplaceName, duiHandle.dictName, duiHandle.txtName)

Wait(500)

duiHandle:sendMessage({
    action = "STATE",
    value = true
})

AddEventHandler('onResourceStop', function (resource)
    if resource ~= GetCurrentResourceName() then return end

	-- Remove the replacement when the script ends
	RemoveReplaceTexture(txReplaceDict, txReplaceName)
    DeleteEntity(keypadProp)

end)
