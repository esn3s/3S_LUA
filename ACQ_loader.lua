--[[
load needed modules for ACQ :
- macrolua (modified version)
- ACQ module

First, we detect if we are going to ACQ several macrolua files at once, by reading an optionnal file:
- batch_ACQ.lua

]]

-- load all gd stuff...
require("gd")

-- launch needed modules...
local gameDatas_file = "./lua/3sGameData.lua"
local library_file = "./lua/library.lua"

dofile(gameDatas_file, "r")
dofile(library_file, "r")

-- set playbackfile for ACQ process...
local acqMacroFile = true
if acqMacroFile then c = "./_macroLua/ACQ_macrolua.mis" end

--[[
First, if batch mode is set to true, we detect if we are going to ACQ several macrolua files at once, by reading an optionnal file:
- batch_ACQ.lua
]]

local bForceRegularMode = false
local bBatchMode = false -- default, will be set to true when loading file if it exists...
local batchModeParametersFile = "./_macroLua/ACQ_batch_param.lua"

if bForceRegularMode == false then
	if io.open(batchModeParametersFile, "r") then
		print("ACQ batch mode, reading '" .. batchModeParametersFile .. "' file as parameters...")
		dofile(batchModeParametersFile, "r")
		
		bBatchMode = ACQ_BATCH ~= nil and ACQ_BATCH.checkStatusOk()
	else
		print("Error: unable to open '" .. batchModeParametersFile .. "'")
		return
	end

	if bBatchMode then
		print("*** ACQ BATCH MODE, init OK", "Nb files to process:", ACQ_BATCH.nbFile())
	else
		print("*** ACQ BATCH MODE, init KO", "Error during checks")
		if ACQ_BATCH ~= nil then ACQ_BATCH.viewListContent() end
		return
	end
else
	print("*** ACQ REGULAR MODE", "Using file '", playbackfile, "'")
end

print()

local Macro_LUA 		= "./MacroLua-1.13/macro.lua"
dofile(Macro_LUA, "r")

local inp_display_script = "./MacroLua-1.13/input-display.lua"

previousFrame = -1

emu.registerbefore(function()
	-- reset ACQ if state has been loaded...
	--if emu.framecount() < previousFrame then resetACQ() end
	
	macroLua_registerBefore()
	
	previousFrame = emu.framecount()
end)

emu.registerafter(function()
	macroLua_registerAfter()
end)

-- acquisition parameters...
--[[


]]--
ACQ = {
	BATCH_MODE = bBatchMode == true,
	startFrameNumber = -1, -- exact frame to start ACQ...
	endFrameNumber = -1, -- exact frame to end ACQ...
	earlyEndFrameNumber = -1, -- frame from which ACQ end will be possible...
	
	flagFrame1 = -1, -- frame used as a flag for something...
	flagFrame2 = -1, -- frame used as a flag for something...
	flagFrame3 = -1, -- frame used as a flag for something...
	
	p1Has = {
		beenBusy = { status = false, frame = -1, index = -1 }, -- busy: atk parameter change from 0 to anything else...
		beenHurt = { status = false, frame = -1, index = -1 },
		jumped = { status = false, frame = -1, index = -1 },
	},
	p2Has = {
		beenBusy = { status = false, frame = -1, index = -1 },
		beenHurt = { status = false, frame = -1, index = -1 },
		jumped = { status = false, frame = -1, index = -1 },
	},
	
	coreProcess = function(frame) -- will detect every event useful...
		ACQ.frame = frame
		
		--print(ACQ.frame, emu.framecount())
		
		-- update events...
		ACQ.updateStatus(ACQ.p1Has.beenBusy, function() return P1:isAttack() end)
		ACQ.updateStatus(ACQ.p2Has.beenBusy, function() return P2:isAttack() end)
		ACQ.updateStatus(ACQ.p1Has.beenHurt, function() return P1:isBeingHit() end)
		ACQ.updateStatus(ACQ.p2Has.beenHurt, function() return P2:isBeingHit() end)
		ACQ.updateStatus(ACQ.p1Has.jumped, function() return P1:isJump() end)
		ACQ.updateStatus(ACQ.p2Has.jumped, function() return P2:isJump() end)
		
		ACQ.bStart = ACQ.triggerStart(frame)
		ACQ.bStop = ACQ.triggerEnd(frame)
		
		ACQ.started = ACQ.started or ACQ.bStart
		ACQ.stopped = ACQ.stopped or (ACQ.started and ACQ.bStop)
		
		local previousStatus = ACQ.status
		ACQ.status = ACQ.started and not ACQ.stopped
		
		if ACQ.status == false and previousStatus == true then
			-- means we just detect end of a process, but we still need to record a couple frames after, due to frame before/after shifting thing...
			ACQ.finalEndFrame = emu.framecount() + 3
		end
		
		local frameNumber = string.format("%04s", frame)
		local str = sp(tostring(ACQ.status), 5).." / "..sp(tostring(ACQ.recordFrame()), 5)
		str = str.." ("..sp(tostring(ACQ.started), 5).."/"..sp(tostring(ACQ.stopped), 5)..")"
		print(frameNumber, str)
	end,
	
	recordFrame = function()
		return ACQ.status or (ACQ.started == true and ACQ.status == false and emu.framecount() < ACQ.finalEndFrame)
	end,
	
	updateStatus = function(value, fct, name) -- will update given value using given function...
		if value.status == false then
			if fct() == true then
				value.status = true
				value.frame = emu.framecount()
				value.index = ACQ.frame
			end
		end
	end,
	
	continueProcess = false, -- used in case of several loads, if false, just stop everything...
	
	status = false, -- currently active or not...
	bStart = false,
	bStop = false,
	started = false, -- ACQ started before...
	stopped = false, -- ACQ already finished...
	frame = -1,
	finalEndFrame = -1,
	typeACQ = nil, -- define type of ACQ...
	triggerStart = nil, -- rule to start ACQ...
	triggerEnd = nil, -- rule to end ACQ...
	
	actions = { -- some forces behavior for chars...
		p1 = {
			jump = function(kt) kt["P1 Up"] = true end
		},
		p2 = {
			jump = function(kt) kt["P2 Up"] = true end
		},
		toDo = {
			forceP1P2ToJumpAfterP2Hurt = {
				status = false,
				fct = function(kt)
					if ACQ.p2Has.beenHurt.status == true then
						ACQ.actions.resetAll(kt)
						ACQ.actions.p1.jump(kt)
						ACQ.actions.p2.jump(kt)
					end
				end
			},
			forceP1ToJumpAfterEarlyFrame = {
				status = false,
				fct = function(kt)
					if ACQ.frame >= ACQ.earlyEndFrameNumber then
						ACQ.actions.resetAll(kt)
						ACQ.actions.p1.jump(kt)
					end
				end
			},
			forceP1P2ToJumpAfterEarlyFrame = {
				status = false,
				fct = function(kt)
					if ACQ.frame >= ACQ.earlyEndFrameNumber then
						ACQ.actions.resetAll(kt)
						ACQ.actions.p1.jump(kt)
						ACQ.actions.p2.jump(kt)
					end
				end
			},
		},
		resetAll = function(kt) -- empty all motions...
			for k, v in pairs(kt) do
				kt[k] = false
			end
		end,
	},
	
	addMotions = function(kt) -- will insert motions in current keytable if needed...
		if ACQ.status == true then
			for k, v in pairs(ACQ.actions.toDo) do
				if v.status == true then
					-- execute action...
					print(k)
					v.fct(kt)
				end
			end
		end
	end,
	
	triggerList = {
		byP1Hit = function() return ACQ.p1Has.beenBusy.status end,
		byP2Hit = function() return ACQ.p2Has.beenBusy.status end,
		
		byFrameEqACQStart = function(fr) return fr == ACQ.startFrameNumber end,
		byFrameSupACQStart = function(fr) return fr > ACQ.startFrameNumber end,
		byFrameSupEqACQStart = function(fr) return fr >= ACQ.startFrameNumber end,
		byFrameEqACQEnd = function(fr) return fr == ACQ.endFrameNumber end,
		byFrameSupACQEnd = function(fr) return fr > ACQ.endFrameNumber end,
		byFrameSupEqACQEnd = function(fr) return fr >= ACQ.endFrameNumber end,
		
		byFrameInfACQStart = function(fr) return fr < ACQ.startFrameNumber end,
		byFrameInfEqACQStart = function(fr) return fr <= ACQ.startFrameNumber end,
		byFrameInfACQEnd = function(fr) return fr < ACQ.endFrameNumber end,
		byFrameInfEqACQEnd = function(fr) return fr <= ACQ.endFrameNumber end,
		
		byP1Attack = function() return P1:isAttack() end,
		byP2Attack = function() return P2:isAttack() end,
		
		byP1JumpAfterFrame = function(fr) return fr >= ACQ.earlyEndFrameNumber and P1:isJump() end,
		byP1P2JumpAfterFrame = function(fr) return fr >= ACQ.earlyEndFrameNumber and P1:isJump() and P2:isJump() end,
		
		byBothNeutral = function() return P1:isNeutral() and P2:isNeutral() end,
	},
}

function ACQ_recordFrame_before(frame)
	ACQ.coreProcess(frame)
end

function ACQ_recordFrame_after()
	local bProcess = false
	
	if ACQ.recordFrame() then
		-- screenshot frame...
		local frameNumber = string.format("%04s", ACQ.frame).."-"..P1:attack().."-"..P1:state().."-"..P1:damageOfNextHit().."-"..P2:attack().."-"..P2:state()
		frameNumber = emu.framecount().." - "..frameNumber
		
		if bProcess then
			scr(frameNumber, "./_ACQ/_rawData/")
			print("--> ACQ '"..frameNumber.."'")
		end
	end
end

-- stop ACQ when p1 and p2 jump after p2 being hit...
function setAcqEndByP1P2JumpAfterP2Hit(frame)
	ACQ.earlyEndFrameNumber = frame + 5
	
	-- force game to make both player jump after p2 got hurt...
	ACQ.actions.toDo.forceP1P2ToJumpAfterP2Hurt.status = true
	
	ACQ.triggerEnd = function(frame)
		local a = ACQ.status == true
		local b = ACQ.p2Has.beenHurt.status
		local c = ACQ.p1Has.jumped.status
		local d = ACQ.p2Has.jumped.status
		
		--print((a and b and c and d), " : ", a, b, c, d)
		
		return a and b and c and d
	end
	
	print("### ACQ END BY P1 & P2 JUMP AFTER P2 BEING HIT")
end

-- stop ACQ when p1 jump after given frame + 5...
function setAcqEndByP1JumpAfterFrame(frame)
	ACQ.earlyEndFrameNumber = frame + 5
	
	-- force game to make p1 jump after early end frame...
	ACQ.actions.toDo.forceP1ToJumpAfterEarlyFrame.status = true
	
	ACQ.triggerEnd = ACQ.triggerList.byP1JumpAfterFrame
	print("### ACQ END BY P1 JUMP AFTER FRAME '"..ACQ.earlyEndFrameNumber.."'")
end

-- stop ACQ when p1 and p2 jump after given frame + 5...
function setAcqEndByP1P2JumpAfterFrame(frame)
	ACQ.earlyEndFrameNumber = frame + 5
	
	-- force game to make p1 and p2 jump after early end frame...
	ACQ.actions.toDo.forceP1P2ToJumpAfterEarlyFrame.status = true
	
	ACQ.triggerEnd = ACQ.triggerList.byP1P2JumpAfterFrame
	print("### ACQ END BY P1 & P2 JUMP AFTER FRAME '"..ACQ.earlyEndFrameNumber.."'")
end

-- start ACQ at given frame...
function setAcqStartFrame(frame)
	ACQ.startFrameNumber = frame
	ACQ.triggerStart = ACQ.triggerList.byFrameEqACQStart
	print("### ACQ START : "..ACQ.startFrameNumber)
end

-- stop ACQ at given frame...
function setAcqEndFrame(frame)
	ACQ.endFrameNumber = frame
	ACQ.triggerEnd = ACQ.triggerList.byFrameEqACQEnd
	print("### ACQ END : "..ACQ.endFrameNumber)
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
	local sColor = ACQ.recordFrame() and 0x00FF00ff or 0xFF5555ff
	displayValue("ACQ #"..ACQ.frame, 7, 5, sColor)
	
	-- inputs bits...
	displayValue(sp(a(gameData.p1.inputsDirAndPunches), 3)..sp(a(gameData.p1.inputsKicks), 3), 8, 50, 0xFFFF00FF)
	displayValue(sp(a(gameData.p2.inputsDirAndPunches), 3)..sp(a(gameData.p2.inputsKicks), 3), 350, 50, 0xFFFF00FF)
	
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
	ACQ.started = false
	ACQ.stopped = false
	ACQ.bStart = false
	ACQ.bStop = false
	ACQ.frame = -1
	ACQ.finalEndFrame = -1
	
	ACQ.p1Has = {
		beenBusy = { status = false, frame = -1, index = -1 },
		beenHurt = { status = false, frame = -1, index = -1 },
		jumped = { status = false, frame = -1, index = -1 },
	}
	ACQ.p2Has = {
		beenBusy = { status = false, frame = -1, index = -1 },
		beenHurt = { status = false, frame = -1, index = -1 },
		jumped = { status = false, frame = -1, index = -1 },
	}
	
	ACQ.actions.toDo.forceP1P2ToJumpAfterP2Hurt.status = false
	ACQ.actions.toDo.forceP1ToJumpAfterEarlyFrame.status = false
	ACQ.actions.toDo.forceP1P2ToJumpAfterEarlyFrame.status = false
	
	print("### ACQ RESETTED")
end

emu.registerstart(function()
	dofile(inp_display_script, "r")
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
