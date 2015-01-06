--[[
load needed modules for ACQ :
- macrolua (modified version)
- ACQ module

in .mis file :
- a : start acquisition trigger
- e : end acquisition trigger
]]

-- load all gd stuff...
require("gd")

-- launch needed modules...
local library_file = "./lua/library.lua"
local gameDatas_file = "./lua/3sGameData.lua"

dofile(library_file, "r")
dofile(gameDatas_file, "r")

local Macro_LUA 		= "./MacroLua-1.13/macro.lua"
dofile(Macro_LUA, "r")

-- set playbackfile for ACQ process...
local acqMacroFile = true
if acqMacroFile then playbackfile = "./_macroLua/ACQ_macrolua.mis" end

local inp_display_script = "./MacroLua-1.13/input-display.lua"

previousFrame = -1
macroFrameNumber = 0 -- current frame number of the read macro...

emu.registerbefore(function()
	-- reset ACQ if state has been loaded...
	--if emu.framecount() < previousFrame then resetACQ() end
	
	macroLua_registerBefore()
	
	previousFrame = emu.framecount()
end)

-- acquisition parameters...
--[[


]]--
ACQ = {
	startFrameNumber = -1,
	endFrameNumber = -1,
	triggerList = {
		byFrameSupACQStart = function(fr) return fr > ACQ.startFrameNumber end,
		byFrameSupEqACQStart = function(fr) return fr >= ACQ.startFrameNumber end,
		byFrameSupACQEnd = function(fr) return fr > ACQ.endFrameNumber end,
		byFrameSupEqACQEnd = function(fr) return fr >= ACQ.endFrameNumber end,
		
		byFrameInfACQStart = function(fr) return fr < ACQ.startFrameNumber end,
		byFrameInfEqACQStart = function(fr) return fr <= ACQ.startFrameNumber end,
		byFrameInfACQEnd = function(fr) return fr < ACQ.endFrameNumber end,
		byFrameInfEqACQEnd = function(fr) return fr <= ACQ.endFrameNumber end,
		
		byP1Attack = function() return isP1Attack() end,
		byP2Attack = function() return isP2Attack() end,
		
		byP1JumpAfterFrame = function(fr) return ACQ.triggerList.byFrameSupEqACQEnd(fr) and isP1Jump() end,
		byP1P2JumpAfterFrame = function(fr) return ACQ.triggerList.byFrameSupEqACQEnd(fr) and isP1Jump() and isP2Jump() end,
		
		byBothNeutral = function() return isP1Neutral() and isP2Neutral() end,
	},
	status = false, -- currently active or not...
	typeACQ = nil, -- define type of ACQ...
	triggerStart = nil, -- rule to start ACQ...
	triggerEnd = nil, -- rule to end ACQ...
}

-- start ACQ at given frame...
function setAcqStartFrame(frame)
	ACQ.startFrameNumber = frame
	ACQ.triggerStart = ACQ.triggerList.byFrameSupEqACQStart
	print("### ACQ START : "..ACQ.startFrameNumber)
end

-- stop ACQ at given frame...
function setAcqEndFrame(frame)
	ACQ.endFrameNumber = frame
	ACQ.triggerStart = ACQ.triggerList.byFrameInfEqACQEnd
	print("### ACQ END : "..ACQ.endFrameNumber)
end

-- stop ACQ when p1 jump after given frame...
function setAcqEndByP1JumpAfterFrame(frame)
	ACQ.endFrameNumber = frame
	ACQ.triggerEnd = ACQ.triggerList.byP1JumpAfterFrame
	print("### ACQ END BY P1 JUMP AFTER FRAME '"..frame.."'")
end

-- stop ACQ when p1 and p2 jump after given frame...
function setAcqEndByP1P2JumpAfterFrame(frame)
	ACQ.endFrameNumber = frame
	ACQ.triggerEnd = ACQ.triggerList.byP1P2JumpAfterFrame
	print("### ACQ END BY P1 & P2 JUMP AFTER FRAME '"..frame.."'")
end

function ACQ_recordFrame(frame, inputstream)
	local frameNumber = string.format("%04s", frame)
	local triggerStart = ACQ.triggerStart(frame)
	local triggerEnd = ACQ.triggerEnd(frame)
	local str = "("..sp(tostring(triggerStart), 5).."/"..sp(tostring(triggerEnd), 5)..")"
	
	macroFrameNumber = frame
	
	print(str.." frame #"..frameNumber, inputstream)
	ACQ.status = false
	
	-- if recording...
	if triggerStart and not triggerEnd then
		-- screenshot frame...
		--scr(frameNumber, "./_ACQ/_rawData/")
		
		ACQ.status = true
	end
end

gui.register(function()
	-- some traces...
	helpTraces()
	
	-- input display...
	displayfunc(showinput)
end)

function helpTraces()
	-- frame counter...
	displayValue(emu.framecount(), 180, 38, 0xBBBBffff)
	
	-- ACQ status...
	local sColor = ACQ.status and 0x00FF00ff or 0xFF5555ff
	displayValue("ACQ #"..macroFrameNumber, 7, 5, sColor)
	
	-- inputs bits...
	--displayValue(sp(a(gameData.p1.inputsDirAndPunches), 3)..sp(a(gameData.p1.inputsKicks), 3), 8, 50, 0xFFFF00FF)
	--displayValue(sp(a(gameData.p2.inputsDirAndPunches), 3)..sp(a(gameData.p2.inputsKicks), 3), 350, 50, 0xFFFF00FF)
	local h = 50
	local incr = 7
	
	-- states...
	displayValue(sp(a(gameData.p1.attack), 2).." / "..sp(a(gameData.p2.attack), 2), 180, h, 0xFFFF00FF) h = h + incr
	displayValue(sp(a(gameData.p1.state), 2).." / "..sp(a(gameData.p2.state), 2), 180, h, 0xFFFF00FF) h = h + incr
	displayValue(sp(a(gameData.p1.hurt), 2).." / "..sp(a(gameData.p2.hurt), 2), 180, h, 0xFFFF00FF) h = h + incr
	displayValue(sp(a(gameData.p1.hit_by_N), 2).." / "..sp(a(gameData.p2.hit_by_N), 2), 180, h, 0xFFFF00FF) h = h + incr
	displayValue(sp(a(gameData.p1.hit_by_S), 2).." / "..sp(a(gameData.p2.hit_by_S), 2), 180, h, 0xFFFF00FF) h = h + incr
	displayValue(sp(a(gameData.p1.hit_by_SA_other), 2).." / "..sp(a(gameData.p2.hit_by_SA_other), 2), 180, h, 0xFFFF00FF) h = h + incr
	displayValue(sp(a(gameData.p1.hit_by_SA), 2).." / "..sp(a(gameData.p2.hit_by_SA), 2), 180, h, 0xFFFF00FF) h = h + incr
	displayValue(sp(a(gameData.p1.damageOfNextHit), 2).." / "..sp(a(gameData.p2.damageOfNextHit), 2), 180, h, 0xFFFF00FF) h = h + incr
	displayValue(sp(a(gameData.p1.stunOfNextHit), 2).." / "..sp(a(gameData.p2.stunOfNextHit), 2), 180, h, 0xFFFF00FF) h = h + incr
	displayValue(sp(a(gameData.p1.combo), 2).." / "..sp(a(gameData.p2.combo), 2), 180, h, 0xFFFF00FF) h = h + incr
	
	-- charges...
	--displayValue(a(gameData.p1.charge4).." / "..a(gameData.p1.chargeResetter4), 180, 60, 0x99FF99FF)
end

function resetACQ()
	ACQ.startFrameNumber = -1
	ACQ.endFrameNumber = -1
	macroFrameNumber = 0
	
	print("### ACQ RESET")
end

emu.registerstart(function()
	dofile(inp_display_script, "r")
end)

-- onlu necessary for recording using macrolua...
--[[
emu.registerafter(function()
	macroLua_registerAfter()
end)
]]

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
