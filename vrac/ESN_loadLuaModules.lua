-- launch needed modules...
local library_file = "./lua/library.lua"
local gameDatas_file = "./lua/3sGameData.lua"

dofile(library_file, "r")
dofile(gameDatas_file, "r")

--cheat(0x02011377, 94) -- timer cheat...

-- modules...
local Macro_LUA 		= "./lua/_macroLua/macro.lua"
local ESN_DisplayInput 	= "./lua/_esnDisplayInput/ESN_DisplayInput.lua"
local ESN_GaugeDisplay 	= "./lua/_esnDisplayInput/ESN_GaugeDisplay.lua"
local ESN_FrameData 	= "./lua/_esnFrameData/ESN_FrameData.lua"
local ESN_Hitboxes 		= "./lua/_esnHitboxes/ESN_Hitboxes.lua"
local ESN_FbaScreenshot = "./lua/_esnFbaScreenshot/ESN_FbaScreenshot.lua"
local ESN_FbaScreenshot_3fv = "./lua/_esnFbaScreenshot/ESN_FbaScreenshot_3fv.lua"

local mod_MacroLua 			= false
local mod_DisplayInput 		= false
local mod_DisplayGauge 		= false

local mod_Hitboxes			= false
local mod_FrameData			= false
local mod_fbaScreenshot_3fv	= true
local mod_ForceSprite		= false
local mod_fbaScreenshot		= false

if mod_MacroLua 			== true then dofile(Macro_LUA, 			"r") end
if mod_DisplayInput 		== true then dofile(ESN_DisplayInput, 	"r") end
if mod_DisplayGauge 		== true then dofile(ESN_GaugeDisplay, 	"r") end
if mod_FrameData 			== true then dofile(ESN_FrameData, 		"r") end
if mod_Hitboxes 			== true then dofile(ESN_Hitboxes, 		"r") end
if mod_fbaScreenshot 		== true then dofile(ESN_FbaScreenshot, 	"r") end

if mod_fbaScreenshot_3fv 	== true then
	index = 1
	activeHitBoxData = {}
	
	local f = io.open("./lua/_esnFbaScreenshot/hitBoxData.txt", "r")
	
	for line in f:lines() do
		activeHitBoxData[index] = line
		index = index + 1
	end
	f:close()
	
	dofile(ESN_FbaScreenshot_3fv, 	"r")
end

local allowToggle 		= false

local iToggleValue = 60
local iToggleDisplayInput = 0
local iToggleDisplayGauge = 0
local iToggleFrameData = 0
local iToggleHitboxes = 0

local isPhase_2 = false

currentFrame = 0
previousFrame = 0
bDoProcesses = false


hitStopCount = 0
counter = 0
imageToForce = 0

local function checkInputsForToggleOptions()
	local inpTmp = joypad.getdown()
	
	if isDirectionHold(inpTmp) == false then
		if in_table(emu_P1..emu_LP, inpTmp) then iToggleDisplayInput = iToggleDisplayInput + 1 end
		if in_table(emu_P1..emu_LK, inpTmp) then iToggleDisplayGauge = iToggleDisplayGauge + 1 end
		if in_table(emu_P1..emu_MP, inpTmp) then iToggleFrameData 	 = iToggleFrameData + 1 end
		if in_table(emu_P1..emu_MK, inpTmp) then iToggleHitboxes 	 = iToggleHitboxes + 1 end
		
		if iToggleDisplayInput >= iToggleValue then
			mod_DisplayInput = toggle(mod_DisplayInput)
			iToggleDisplayInput = 0
		end
		
		if iToggleDisplayGauge >= iToggleValue then
			mod_DisplayGauge = toggle(mod_DisplayGauge)
			iToggleDisplayGauge = 0
		end
		
		if iToggleFrameData >= iToggleValue then
			mod_FrameData = toggle(mod_FrameData)
			iToggleFrameData = 0
		end
		
		if iToggleHitboxes >= iToggleValue then
			mod_Hitboxes = toggle(mod_Hitboxes)
			iToggleHitboxes = 0
		end
	else
		iToggleDisplayInput = 0
		iToggleDisplayGauge = 0
		iToggleFrameData = 0
		iToggleHitboxes = 0
	end
	
	-- this line to force refresh, will bug sometimes without it...
	displayValue("", 1, 1, 0xffff0000)
	
	--displayValue("Toggle: "..iToggleDisplayInput, 10, 3, 0xffff00ff)
	--displayValue("Toggle: "..iToggleDisplayGauge, 10, 10, 0xffff00ff)
	--displayValue("Toggle: "..iToggleFrameData, 10, 17, 0xffff00ff)
	--displayValue("Toggle: "..iToggleHitboxes, 10, 24, 0xffff00ff)
end

gui.register(function()
	--displayValue("frame : "..emu.framecount(), 220, 5, 0x00ff00ff)
	
	-- avoid doing process twice...
	currentFrame = emu.framecount()
	bDoProcesses = false
	
	if currentFrame ~= previousFrame then
		bDoProcesses = true
		previousFrame = currentFrame
	end
	
	if allowToggle == true then checkInputsForToggleOptions() end;
	
	if mod_DisplayInput == true then DisplayInput() end
	if mod_DisplayGauge == true then gaugeDisplay() end
	if mod_FrameData	== true then framesData() 	end
	
	if mod_ForceSprite	== true then forceSprite(gameData.p1.anim_frame) end
	
	--cheat(0x20695B5, 0xA0) -- p1 inf jauge
end)

emu.registerbefore( function()
	if 1 or mame then
		if mod_Hitboxes	== true then render_sfiii_hitboxes() end
	end
	
	-- macroLua...
	if mod_MacroLua	== true then macroLua_registerBefore() end
end)

emu.registerafter( function()
	if mod_fbaScreenshot	 == true then fbaScreenshot() end
	if mod_fbaScreenshot_3fv == true then fbaScreenshot() end
	
	-- macroLua...
	if mod_MacroLua	== true then macroLua_registerAfter() end
end)

-- for macroLua module...
if mod_MacroLua	== true then
	while true do
		if pausenow then
			emu.pause()
			pausenow = false
		end
		emu.frameadvance()
	end
end
