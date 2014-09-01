-- take a screenshot as long as P1 state is not 0...

--
-- THIS SCRIPT MUST BE REGISTERED BEFORE !!!
--

-- write or not files...
local bFrameDataMode = true
local bWrite = true
local bForceFrameDataMode = false

-- separator
local sep = ";"

-- begin/end trigger...
local bTriggerBegin 	= false
local bTriggerEnd 	= false
local bProcessBegan	= false
local bProcessEnd	= false
local bOneVeryLastFrame	= false
local iNbProcessed = 0
local iMaxCombo = 0

-- force the end trigger to be the jump (state 12) for char 1...
bForceJumpAsEnd = false

local aListUse = {
	fd_normals		= { begin = function() return (a(gameData.p1.attack, "b") > 0) end, end_ = function() return (a(gameData.p1.attack, "b") == 0) 	end	},
	fd_specials		= { begin = function() return (a(gameData.p1.attack, "b") > 0) end, end_ = function() return (a(gameData.p1.attack, "b") == 0) 	end	},
	fd_supers		= { begin = function() return (a(gameData.p1.attack, "b") > 0) end, end_ = function() return (a(gameData.p1.attack, "b") == 0) 	end	},
	fd_gj_normals	= { begin = function() return (a(gameData.p1.attack, "b") > 0) end, end_ = function() return (a(gameData.p1.attack, "b") == 0) 	end	},
	fd_gj_specials	= { begin = function() return (a(gameData.p1.attack, "b") > 0) end, end_ = function() return (a(gameData.p1.attack, "b") == 0) 	end	},
	
	dashForwardFull = { begin = function() return (a(gameData.p1.state, "b") == 4) end, end_ = function() return (a(gameData.p1.state, "b") ~= 4) 	end	},
	dashBackwardFull= { begin = function() return (a(gameData.p1.state, "b") == 5) end, end_ = function() return (a(gameData.p1.state, "b") ~= 5) 	end	},
	dashForward 	= { begin = function() return (a(gameData.p1.state, "b") == 4) end, end_ = function() return (a(gameData.p1.state, "b") ~= 4) 	end	},
	dashBackward 	= { begin = function() return (a(gameData.p1.state, "b") == 5) end, end_ = function() return (a(gameData.p1.state, "b") ~= 5) 	end	},
	
	dash = { begin = function() return (a(gameData.p1.state, "b") == 5 or a(gameData.p1.state, "b") == 4) end, 
			 end_ = function() return (a(gameData.p1.state, "b") ~= 5 and a(gameData.p1.state, "b") ~= 4) 	end	},
	
	jumpNeutral	 	= { begin = function() return (a(gameData.p1.state, "b") == 12) end, 
						end_ = function() return (a(gameData.p1.state, "b") == 0) end },
						--end_ = function() return (a(gameData.p1.pos_y, "ws") > 0) end },
						--end_ = function() return (a(gameData.p1.jumpRecoveryTrigger1, "b") == 2 and a(gameData.p1.jumpRecoveryTrigger2, "b") == 3) 	end	},
	jumpForward	 	= { begin = function() return (a(gameData.p1.state, "b") == 12) end, 
						end_ = function() return (a(gameData.p1.state, "b") == 0) end },
						--end_ = function() return (a(gameData.p1.pos_y, "ws") > 0) end },
						--end_ = function() return (a(gameData.p1.jumpRecoveryTrigger1, "b") == 2 and a(gameData.p1.jumpRecoveryTrigger2, "b") == 3)	end	},
	jumpBackward 	= { begin = function() return (a(gameData.p1.state, "b") == 12) end, 
						end_ = function() return (a(gameData.p1.state, "b") == 0) end },
						--end_ = function() return (a(gameData.p1.pos_y, "ws") > 0) end },
						--end_ = function() return (a(gameData.p1.jumpRecoveryTrigger1, "b") == 2 and a(gameData.p1.jumpRecoveryTrigger2, "b") == 3) 	end	},
	
	superjumpNeutral	= { begin = function() return (a(gameData.p1.state, "b") == 13) end, 
						end_ = function() return (a(gameData.p1.state, "b") == 0) end },
						--end_ = function() return (a(gameData.p1.pos_y, "ws") > 0) end },
						--end_ = function() return (a(gameData.p1.jumpRecoveryTrigger1, "b") == 2 and a(gameData.p1.jumpRecoveryTrigger2, "b") == 3) 	end	},
	superjumpForward 	= { begin = function() return (a(gameData.p1.state, "b") == 13) end, 
						end_ = function() return (a(gameData.p1.state, "b") == 0) end },
						--end_ = function() return (a(gameData.p1.pos_y, "ws") > 0) end },
						--end_ = function() return (a(gameData.p1.jumpRecoveryTrigger1, "b") == 2 and a(gameData.p1.jumpRecoveryTrigger2, "b") == 3) 	end	},
	superjumpBackward	= { begin = function() return (a(gameData.p1.state, "b") == 13) end, 
						end_ = function() return (a(gameData.p1.state, "b") == 0) end },
						--end_ = function() return (a(gameData.p1.pos_y, "ws") > 0) end },
						--end_ = function() return (a(gameData.p1.jumpRecoveryTrigger1, "b") == 2 and a(gameData.p1.jumpRecoveryTrigger2, "b") == 3) 	end	},
	
	jump = { begin = function() return (a(gameData.p1.state, "b") == 13 or a(gameData.p1.state, "b") == 12) end, 
						end_ = function() return (a(gameData.p1.state, "b") == 0) end },
	
	-- P1 sa bar MUST BE empty first!!!
	wakeUp 			= { begin = function() return (a(gameData.p1.state, "b") == 6) end, end_ = function() return (a(gameData.p1.state, "b") == 12) 	end	}, -- makoto state --> 78, q --> 64, others 5
	wakeUpQuickRoll = { begin = function() return (a(gameData.p1.state, "b") == 17) end, end_ = function() return (a(gameData.p1.state, "b") == 12) 	end	},
	
	various		 	= { begin = function() return (a(gameData.p1.attack, "b") > 0 or a(gameData.p2.state, "b") > 0)  end, 
						end_ = function() return (iNbProcessed > 15 and a(gameData.p1.state, "b") == 12) 	end	},
						--[[
						 begin = function() return (a(gameData.p1.state, "b") == 64)  end, 
						end_ = function() return (a(gameData.p2.state, "b") == 12) 	end	},
						--end_ = function() return (iNbProcessed > 15 and a(gameData.p1.state, "b") == 0 and a(gameData.p2.state, "b") == 0) 	end	},
						--]]
	combos		 	= { begin = function() return (a(gameData.p2.attack, "b") > 0)  end, end_ = function() return (a(gameData.p1.state, "b") == 12 and a(gameData.p2.attack, "b") == 0) 	end	},
	collectMode	 	= { begin = function() return (a(gameData.p1.attack, "b") > 0)  end, end_ = function() return (a(gameData.p1.attack, "b") == 0 and a(gameData.p2.attack, "b") == 0) 	end	},
	stateTrigger 	= { begin = function() return (a(gameData.p1.state, "b") == 0)  end, end_ = function() return (a(gameData.p1.state, "b") == 12) end	},
	buttonTrigger	= {	begin = function() return (input.get()["U"] == true)  end, end_ = function() return (input.get()["J"] == true)  end	},
	parryChecks		= {	begin = function() return (a(gameData.p2.state, "b") == 12)  end, end_ = function() return (a(gameData.p1.state, "b") ~= 3)  end	},
	frameTrigger	= { begin = function() return (a(gameData.p1.anim_frame, "w") == 16903) end, end_ = function() return (input.get()["K"] == true)  end },
	hitConfirm		= { begin = function() return (a(gameData.p1.attack, "b") > 0) end, end_ = function() return (input.get()["K"] == true)  end },
	superfreeze		= { begin = function() return (a(gameData.game.superfreeze, "b") == 2)  end, end_ = function() return (input.get()["K"] == true)  end },
}

sScriptUse = "buttonTrigger"

sScriptUseTxt = sScriptUse

iMiscListIndexToRead = 12
sMiscIndexPrefix = "line_"

aMiscList = {

line_1 = "dashForward",
line_2 = "dashBackward",

-- recovery cancelled by jump...
line_9 = "dashForwardFull",
line_10 = "dashBackwardFull",

line_3 = "jumpBackward",
line_4 = "jumpNeutral",
line_5 = "jumpForward",
line_6 = "superjumpBackward",
line_7 = "superjumpNeutral",
line_8 = "superjumpForward",

line_11 = "wakeUp",
line_12 = "wakeUpQuickRoll",
}

--print(aMiscList[sMiscIndexPrefix..iMiscListIndexToRead])

iSimpleCounter = -1
sResultToWriteInFile = ""

-- end trigger...

hb_currentFrame = 0
hb_previousFrame = 0
hb_p1Atk_counter = 0

local prevFileName = "" -- previous frame
local prevDataMame = "" -- previous frame data
local antepenultianFileName = "" -- antepenultian frame

local previousP1Life = 160
local previousP2Life = 160
local previousP1Stun = 0
local previousP2Stun = 0

bTimerCheat = false
bForceStage = false
bForceP2Y = false
bForceP2X = false

function fbaScreenshot()
	if bTimerCheat then cheat(gameData.game.timer, 94) end -- timer cheat...
	if bForceStage then cheat(gameData.game.background, 0x05) end -- force Necro BG...
	if bForceP2Y then cheat(gameData.p2.pos_y, -120, "ws") end -- force P2 pos Y...
	if bForceP2X then cheat(gameData.p2.pos_x, 3200, "ws") end -- force P2 pos X...
	
	--cheat(gameData.p1.pos_y, 0, "ws")
	
	hb_currentFrame = emu.framecount()
	
	--print(hb_currentFrame.." / "..hb_previousFrame)
	
	iGamePhase = a(gameData.game.game_phase, "b")
	
	if hb_currentFrame ~= hb_previousFrame and iGamePhase == 2 then --> 0 and iGamePhase < 4 then
		-- toggle frameData mode...
		if input.get()["end"] == true then
			gui.clearuncommitted()
			if bFrameDataMode == true then
				bFrameDataMode = false
			else
				bFrameDataMode = true
			end
		end

		if input.get()["pageup"] == true then
			bWrite = not bWrite
		end
		
		-- allow to increase P2 bar with the 'B' key button...
		if input.get()["B"] == true then
			local iBarTmp = a(gameData.p1.bar, "b") + 1
			cheat(gameData.p1.bar, iBarTmp)
			print(iBarTmp + 1)
		end
		
		-- allow to increase P2 bar with the 'B' key button...
		if input.get()["N"] == true then
			local iBarTmp = a(gameData.p2.bar, "b") + 1
			cheat(gameData.p2.bar, iBarTmp)
			print(iBarTmp + 1)
		end
		
		-- old method : switch to another sScriptUse : whiff/hit/cr.hit/blocked...
		if bFrameDataMode and string.sub(sScriptUse, 0, 3) == "fd_"  and input.get()["pagedown"] == true then
			if 		string.len(sScriptUseTxt) < 11 then sScriptUseTxt = sScriptUse.."_whiff"
			elseif 	string.find(sScriptUseTxt, "_whiff") ~= nil then sScriptUseTxt = sScriptUse.."_hit"
			--elseif 	string.find(sScriptUseTxt, "_hit") ~= nil then sScriptUseTxt = sScriptUse.."_blk"
			elseif 	string.find(sScriptUseTxt, "_hit") ~= nil then sScriptUseTxt = sScriptUse.."_crHit"
			elseif 	string.find(sScriptUseTxt, "_crHit") ~= nil then sScriptUseTxt = sScriptUse.."_blk"
			elseif 	string.find(sScriptUseTxt, "_blk") ~= nil then sScriptUseTxt = sScriptUse
			end
		end
		
		-- switch directly with numpad0/1/2/3 being respectively whiff/hit/blk/crHit...
		if bFrameDataMode then
			if isHeld("numpad0") then sScriptUseTxt = sScriptUse.."_whiff" end
			if isHeld("numpad1") then sScriptUseTxt = sScriptUse.."_hit" end
			if isHeld("numpad2") then sScriptUseTxt = sScriptUse.."_blk" end
			if isHeld("numpad3") then sScriptUseTxt = sScriptUse.."_crHit" end
		end
		
		if bFrameDataMode == false then
			sScriptUseTxt = sScriptUse
		end
		
		bTriggerBegin = aListUse[sScriptUse].begin()
		bTriggerEnd = aListUse[sScriptUse].end_()
		
		if string.sub(sScriptUse, 0, 3) == "fd_"  and bFrameDataMode then
			bTriggerEnd = aListUse["collectMode"].end_()
			
			if sScriptUseTxt == sScriptUse then sScriptUseTxt = sScriptUse.."_whiff" end
		end
		
		-- force end when jump begins for special cases like throws tech...
		if bForceJumpAsEnd == true then bTriggerEnd = (a(gameData.p1.state, "b") == 12 and iNbProcessed > 10) end
		--if bForceJumpAsEnd == true then bTriggerEnd = (a(gameData.p1.state, "b") == 12 and iNbProcessed > 10 and a(gameData.p2.state, "b") == 12) end -- both char must jump to stop process...
		
		-- for all jumps, force end to this when counter is > 10...
		if iSimpleCounter > 10 and (string.sub(sScriptUse, 0, 4) == "jump" or string.sub(sScriptUse, 0, 9) == "superjump") then
			bTriggerEnd = (a(gameData.p1.state, "b") == 12) -- end when state = 12 (jump again) and pos_y back to 0
			bTriggerBegin = false
			--print(iSimpleCounter.." --> "..tostring(bTriggerBegin).." / "..tostring(bTriggerEnd))
		end
		
		local bScreenshot = false
		local bFrameDataFile = false
		
		--print(testListValues(gameData.tests, true))
		
		initGameValues()
		
		-- values of P1 for P2...
		strRealP2 = "realDamageOfNextHit:"..p1_RealDamageOfNextHit.."\nrealStunOfNextHit:"..p1_RealStunOfNextHit
		strRealP1 = "realDamageOfNextHit:"..p2_RealDamageOfNextHit.."\nrealStunOfNextHit:"..p2_RealStunOfNextHit
		
		--print(strRealP1)
		--print(strRealP2)
		
		local dataToWrite = "#GLOBAL DATA BEGIN#".."\nemu_frame:"..emu.framecount()..""..getFullDataToString(gameData.game).."\n#GLOBAL DATA END#\n"
		dataToWrite = dataToWrite.."\n\n#P1 DATA BEGIN#"..getFullDataToString(gameData.p1).."\n"..strRealP1.."\n#P1 DATA END#\n"
		dataToWrite = dataToWrite.."\n\n#P2 DATA BEGIN#"..getFullDataToString(gameData.p2).."\n"..strRealP2.."\n#P2 DATA END#\n"
		
		dataToWrite = dataToWrite.."\n"..formatHitboxStringFromData({getHitboxData(gameData.p1.hb_base_address, "P1")}, "P1")
		dataToWrite = dataToWrite.."\n"..formatHitboxStringFromData({getHitboxData(gameData.p2.hb_base_address, "P2")}, "P2")
		dataToWrite = dataToWrite.."\n"..formatHitboxStringFromData(getObjectsHitboxesCoord(), "OBJECT")
		
		-- reset all data on reload...
		if emu.framecount() < hb_previousFrame then
			iSimpleCounter = -1
			previousData = ""
			previousFileName = ""
			antepenultianFileName = ""
			bOneVeryLastFrame = false
			--print()
		end
		
		if bProcessBegan == false and bTriggerBegin then
			bProcessBegan = true
			iSimpleCounter = -1
		end
		
		if bProcessBegan then
			iSimpleCounter = iSimpleCounter + 1
			iNbProcessed = iNbProcessed + 1
			
			bFrameDataFile = true
			
			if iSimpleCounter > 0 then bScreenshot = true end -- take screenshot after the first frame detected...
		end
		
		if bProcessEnd or bOneVeryLastFrame then
			-- take the last screenshot one frame after end detection...
			bScreenshot = true
			iSimpleCounter = iSimpleCounter + 1
			
			if bProcessEnd then bFrameDataFile = true end -- allow last frame data file...
			
			bProcessEnd = false
			bOneVeryLastFrame = not bOneVeryLastFrame
		end
		
		if bTriggerEnd and bProcessBegan then
			bProcessBegan = false
			bProcessEnd = true -- flag to allow fba to take a last screenshot next frame...
			print("end")
		end
		
		finalFileName = prefix..sep..string.format("%03s", (iSimpleCounter + 1))..sep..fileName_Fba
		
		--displayValue("charge1 : "..sp(a(gameData.p1.charge1, "b"), 4).." / "..sp(a(gameData.p1.chargeResetter1, "b"), 4), 150, 10, 0xffff00ff)
		--displayValue("charge2 : "..sp(a(gameData.p1.charge2, "b"), 4).." / "..sp(a(gameData.p1.chargeResetter2, "b"), 4), 150, 20, 0xffff00ff)
		--displayValue("charge3 : "..sp(a(gameData.p1.charge3, "b"), 4).." / "..sp(a(gameData.p1.chargeResetter3, "b"), 4), 150, 30, 0xffff00ff)
		--displayValue("charge4 : "..sp(a(gameData.p1.charge4, "b"), 4).." / "..sp(a(gameData.p1.chargeResetter4, "b"), 4), 150, 80, 0xffff00ff)
		--displayValue("charge5 : "..sp(a(gameData.p1.charge5, "b"), 4).." / "..sp(a(gameData.p1.chargeResetter5, "b"), 4), 150, 50, 0xffff00ff)
		
		if bForceFrameDataMode or bFrameDataMode then
			--displayValue(formatHitboxString(p1_hb_A, "HB A "), 285, 130, 0x00ff00ff)
			
			if bWrite then sColorWrite = 0x00ff00ff else sColorWrite = 0xff0000ff end
			displayValue(sScriptUse.." / "..sScriptUseTxt.." ("..tostring(bWrite)..")", 170, 38, sColorWrite)
			
			displayValue("bTriggerBegin : "..tostring(bTriggerBegin), 	170, 48, 0xff9999ff)
			displayValue("bTriggerEnd   : "..tostring(bTriggerEnd), 	170, 58, 0xff9999ff)
			
			displayValue("screen_center_x : "..screen_center_x, 3, 1, 0x00ffffff)
			displayValue("screen_center_y : "..screen_center_y, 3, 9, 0x00ffffff)
			
			displayValue("superfreeze : "..superfreeze, 170, 0, 0x00ffffff)
			displayValue("zoom : "..zoom.." / "..a(gameData.game.zoom_X, "b").." / "..a(gameData.game.zoom_Y, "b").." / "..a(gameData.game.zoom_Y_current, "b"), 198, 8, 0x00ffffff)
			
			displayValue("iGamePhase : "..iGamePhase,	320, 0, 0x00ffffff)
			displayValue(emu.framecount().." : "..a(gameData.game.timer, "b"), 250, 0, 0x00ffffff)
			
			displayValue("P1 Atk   : "..p1Atk, 			3, 50, 0xffff00ff)
			displayValue("P1 State : "..p1State, 		3, 58, 0xffff00ff)
			displayValue("P1 pos X : "..p1pos_x, 		3, 70, 0xffff00ff)
			displayValue("P1 pos Y : "..p1pos_y,		3, 78, 0xffff00ff)
			displayValue("P1 frame : "..p1Frame,		3, 90, 0xffff00ff)
			displayValue("P1 facing: "..a(gameData.p1.facing_dir, "b"), 3, 100, 0xffff00ff)
			displayValue("P1 life : "..p1Life,			3, 110, 0xffff00ff)
			displayValue("P1 stun : "..p1Stun,			3, 118, 0xffff00ff)
			displayValue("P1 Bar : "..p1Bar.." : "..p1Stock,	3, 125, 0xffff00ff)
			
			displayValue("P1 next damage : "..p2_RealDamageOfNextHit, 3, 135, 0xffff00ff)
			displayValue("P1 next stun   : "..p2_RealStunOfNextHit,	3, 145, 0xffff00ff)
			
			displayValue("P1 combos : "..iCombo.." (max: "..iMaxCombo..")", 3, 160, 0xffff00ff)
			
			displayValue("P1 cancel : "..p1Cancel,		3, 170, 0xffff00ff)
			displayValue("P1 Dir/Punches : "..a(gameData.p1.inputsDirAndPunches, "b"), 	3, 180, 0xffff00ff)
			displayValue("P1 Kicks       : "..a(gameData.p1.inputsKicks, "b"), 		3, 190, 0xffff00ff)
			
			displayValue(sp(p2pos_x, 4).." : P2 pos X", 320, 50, 0xff9900ff)
			displayValue(sp(p2pos_y, 4).." : P2 pos Y",	320, 58, 0xff9900ff)
			displayValue(sp(p2Atk, 4)  .." : P2 Atk", 	320, 70, 0xff9900ff)
			displayValue(sp(p2State, 4).." : P2 State", 320, 78, 0xff9900ff)
			displayValue(sp(p2Frame, 4).." : P2 frame", 320, 90, 0xff9900ff)
			displayValue(sp(p2Life, 4).." : P2 life",			320, 110, 0xffff00ff)
			displayValue(sp(p2Stun, 4).." : P2 stun",			320, 120, 0xffff00ff)
			displayValue(sp(a(gameData.p2.bar, "b"), 4).." : P2 bar",	320, 130, 0xffff00ff)
			
			displayValue(a(gameData.p2.mameCheatSemiInfiniteJuggle, "b").." : P2 Semi inf juggle", 	300, 150, 0xffff00ff)
			displayValue(a(gameData.p2.mameCheatTrueInfiniteJuggle, "b").." : P2 Inf juggle", 	300, 160, 0xffff00ff)
			
			displayValue(a(gameData.p2.inputsDirAndPunches, "b").." : P2 Dir/Punches", 	300, 180, 0xffff00ff)
			displayValue(a(gameData.p2.inputsKicks, "b").." : P2 Kicks", 			300, 190, 0xffff00ff)
		end
		
		--displayValue("cancel? : "..a(gameData.p1.mameCheatUniversalCancel, "b"), 3, 160, 0xffff00ff)
		--displayValue("P1 cancel : "..p1Cancel,		3, 170, 0xffff00ff)
		
		local sDebug = p1Char.." - "..a(gameData.game.background, "b").." | frame : "..tostring(iSimpleCounter).." ("..emu.framecount().." / "..a(gameData.game.timer, "b")..") _ screen_center : "..sp(screen_center_x, 4).." / "..sp(screen_center_y, 4).." _ "
		sDebug = sDebug.."chars frame : "..sp(p1Frame, 4).." / "..sp(p2Frame, 4).." _ " -- frames number
		sDebug = sDebug.."p1 Atk/State : "..sp(p1Atk, 4).." / "..sp(p1State, 4).." _ p1pos : "..sp(p1pos_x, 4).." / "..sp(p1pos_y, 4).." _ "--cancel : "..sp(p1Cancel, 4).." _ "
		sDebug = sDebug.."p2 Atk/State : "..sp(p2Atk, 4).." / "..sp(p2State, 4).." _ p2pos : "..sp(p2pos_x, 4).." / "..sp(p2pos_y, 4).." _ "..sp(p1Bar, 4).." _ "..sp(p1Stock, 4)
		print(sDebug)
		
		-- only allow to write files if both filenames are available...
		if previousFileName and antepenultianFileName then
			-- write files...
			if bScreenshot then
				-- take screenshot...
				fileNameToWrite = antepenultianFileName
				if bWrite and bFrameDataMode == false then scr(fileNameToWrite) end
			end
			
			if bFrameDataFile then
				-- write frame data file...
				fileNameToWrite = previousFileName..".frame"
				if bWrite then wrFile("frame:"..string.format("%03s", iSimpleCounter).."\n"..previousData, fileNameToWrite) end
				--print(string.format("%03s", iSimpleCounter).." : "..fileNameToWrite)
			end
		end
		
		previousData  = dataToWrite
		antepenultianFileName = previousFileName
		previousFileName = finalFileName
		
		iRealCounter = iSimpleCounter - 2
		if iSimpleCounter < 1 then iRealCounter = "-" end
		if bForceFrameDataMode or bFrameDataMode then displayValue("Process count : "..iSimpleCounter.." ( --> "..iRealCounter..")", 170, 68, 0x99ff99ff) end
	end
	
	hb_previousFrame = emu.framecount()
end

function initGameValues()
	iCombo		= a(gameData.p1.combo, "b")
	if iMaxCombo < iCombo then iMaxCombo = iCombo end
	
	p1Char		= a(chars.p1addr, "b")
	p2Char		= a(chars.p2addr, "b")
	p1Atk 		= a(gameData.p1.attack, "b")
	p1Cancel 	= a(gameData.p1.mameCheatUniversalCancel, "b")
	p1State 	= a(gameData.p1.state, "b")
	p1pos_x 	= a(gameData.p1.pos_x, "ws")
	p1pos_y 	= a(gameData.p1.pos_y, "ws")
	p1Frame 	= a(gameData.p1.anim_frame, "w")
	p2Atk 		= a(gameData.p2.attack, "b")
	p2State 	= a(gameData.p2.state, "b")
	p2pos_x 	= a(gameData.p2.pos_x, "ws")
	p2pos_y 	= a(gameData.p2.pos_y, "ws")
	p2Frame 	= a(gameData.p2.anim_frame, "w")
	p1activeThrow	= a(gameData.p1.activeThrow, "b")
	p2activeThrow	= a(gameData.p2.activeThrow, "b")
	p1saBarContent	= a(gameData.p1.saBarContent, "b")
	p2saBarContent	= a(gameData.p2.saBarContent, "b")
	p1Bar = a(gameData.p1.saBarContent, "b")
	p1Stock = a(gameData.p1.saBarCount, "b")
	
	p1jumpRecoveryTrigger1	= a(gameData.p1.jumpRecoveryTrigger1, "b")
	p1jumpRecoveryTrigger2	= a(gameData.p1.jumpRecoveryTrigger2, "b")
	
	gamePhase 		= a(gameData.game.game_phase, "b")
	screen_center_x = a(gameData.game.screen_center_x, "ws")
	screen_center_y = a(gameData.game.screen_center_y, "ws")
	superfreeze 	= a(gameData.game.superfreeze, "b")
	zoom		= a(gameData.game.zoom, "b")
	
	fileName_Fba = ""
	data_Mame = ""
	
	p1_hb_P = getHitboxCoord(gameData.p1, "P")
	p1_hb_A = getHitboxCoord(gameData.p1, "A")
	p1_hb_V = getHitboxCoord(gameData.p1, "V")
	p1_hb_T = getHitboxCoord(gameData.p1, "T")
	p1_hb_TA = getHitboxCoord(gameData.p1, "TA")
	p1_hb_PU = getHitboxCoord(gameData.p1, "PU")

	p2_hb_P = getHitboxCoord(gameData.p2, "P")
	p2_hb_A = getHitboxCoord(gameData.p2, "A")
	p2_hb_V = getHitboxCoord(gameData.p2, "V")
	p2_hb_T = getHitboxCoord(gameData.p2, "T")
	p2_hb_TA = getHitboxCoord(gameData.p2, "TA")
	p2_hb_PU = getHitboxCoord(gameData.p2, "PU")
	
	-- format the future filename...
	prefix = p1Char..sep..p2Char
	
	-- add time in filename to help sorting files...
	local iTime = os.clock()
	
	fileName_Fba = fileName_Fba..sScriptUseTxt..sep..iTime..sep..p1Cancel..sep..p1Atk..sep..p1State..sep..p2Atk..sep..p2State
	fileName_Fba = fileName_Fba..sep..screen_center_x
	fileName_Fba = fileName_Fba..sep..screen_center_y
	fileName_Fba = fileName_Fba..sep..p1pos_x
	fileName_Fba = fileName_Fba..sep..p1pos_y
	fileName_Fba = fileName_Fba..sep..p2pos_x
	fileName_Fba = fileName_Fba..sep..p2pos_y
	fileName_Fba = fileName_Fba..sep..superfreeze
	fileName_Fba = fileName_Fba..sep..emu.framecount()
	fileName_Fba = fileName_Fba..sep.."p1_hb_A"..sep..formatHitboxString(p1_hb_A)..sep.."p1_hb_A"--..sep.."p1_hb_P"..sep..formatHitboxString(p1_hb_P)
	
	-- as parameter damage/stunOfNextHit doesn't work, process damage/stun value here...
	p1Life = a(gameData.p1.life, "b")
	p1Stun = a(gameData.p1.stunStatus, "b")
	
	p1_RealDamageOfNextHit = 0
	p1_RealStunOfNextHit = 0
	
	if p1Life < previousP1Life then p1_RealDamageOfNextHit = previousP1Life - p1Life end
	if p1Stun > previousP1Stun and p1_RealDamageOfNextHit > 0 then p1_RealStunOfNextHit = p1Stun - previousP1Stun end
	
	--print("P1 : "..p1Life.." / "..previousP1Life.." "..p1Stun.." / "..previousP1Stun.." --> "..p1_RealDamageOfNextHit.." / "..p1_RealStunOfNextHit)
	
	previousP1Life = p1Life
	previousP1Stun = p1Stun
	
	p2Life = a(gameData.p2.life, "b")
	p2Stun = a(gameData.p2.stunStatus, "b")
	
	p2_RealDamageOfNextHit = 0
	p2_RealStunOfNextHit = 0
	
	if p2Life < previousP2Life then p2_RealDamageOfNextHit = previousP2Life - p2Life end
	if p2Stun > previousP2Stun and p2_RealDamageOfNextHit > 0 then p2_RealStunOfNextHit = p2Stun - previousP2Stun end
	
	--print("P2 : "..p2Life.." / "..previousP2Life.." "..p2Stun.." / "..previousP2Stun.." --> "..p2_RealDamageOfNextHit.." / "..p2_RealStunOfNextHit)
	
	previousP2Life = p2Life
	previousP2Stun = p2Stun
	
end

-- get coord hitbox data...
function getRealHitboxCoord(hb_addr, type, i, player)
	local left
	local right
	local bottom
	local top
	
	local bUse3fvShenanigans = false;
	
	if bUse3fvShenanigans and type == "active" then
		-- 3fv shenanigans to get actual active hitboxes with fba-rr...
		left = activeHitBoxData[hb_addr + 0x14C - 0x643FFFF]
		left = left * 0x100 + activeHitBoxData[hb_addr + 1 + 0x14C - 0x643FFFF]
		left = num2signed(left, 2)
		
		right = activeHitBoxData[hb_addr + 2 + 0x14C - 0x643FFFF]
		right = right * 0x100 + activeHitBoxData[hb_addr + 2 + 0x14C + 1 - 0x643FFFF]
		right = num2signed(right, 2)
		
		bottom = activeHitBoxData[hb_addr + 4 + 0x14C - 0x643FFFF]
		bottom = bottom * 0x100 + activeHitBoxData[hb_addr + 4 + 0x14C + 1 - 0x643FFFF]
		bottom = num2signed(bottom, 2)
		
		top = activeHitBoxData[hb_addr + 6 + 0x14C - 0x643FFFF]
		top = top * 0x100 + activeHitBoxData[hb_addr + 6 + 0x14C + 1 - 0x643FFFF]
		top = num2signed(top, 2)
		
		--print("("..emu.framecount()..") "..player.." : "..string.sub(player, 0, 2))
		
		--if player == "P1" then print("("..emu.framecount()..") 3fv method : "..player.."/"..type.." : object "..i.." : coord read at "..h(hb_addr).." --> "..left.." "..right.." "..top.." "..bottom) end
		--if player == "P2" then print("("..emu.framecount()..") 3fv method : "..player.."/"..type.." : object "..i.." : coord read at "..h(hb_addr).." --> "..left.." "..right.." "..top.." "..bottom) end
		--if string.sub(player, 2) == "OB" then print("("..emu.framecount()..") 3fv method : "..player.."/"..type.." : object "..i.." : coord read at "..h(hb_addr).." --> "..left.." "..right.." "..top.." "..bottom) end
	else
		left   = memory.readwordsigned(hb_addr)
		right  = memory.readwordsigned(hb_addr + 2)
		bottom = memory.readwordsigned(hb_addr + 4)
		top    = memory.readwordsigned(hb_addr + 6)
	end
	
	--print(type.." : coord read at "..h(hb_addr).." --> "..left.." "..right.." "..top.." "..bottom)
	
	return { left = left, right = right, top = top, bottom = bottom }
end

-- ???
function num2signed(value,byte)
	local subValue = 1
	for i=1,byte,1 do
		subValue = subValue * 0x100
	end
	if value >= (subValue/2) then
		value = value - subValue
	end
	return value
end

-- get all datas for hitbox addr...
function getHitboxData(base, player)
	local obj = {}
	
	obj.type			= player
	obj.facing_dir		= memory.readbyte(base + 0xA)
	obj.opponent_dir	= memory.readbyte(base + 0xB)
	obj.pos_x			= memory.readwordsigned(base + 0x64)
	obj.pos_y			= memory.readwordsigned(base + 0x68)
	obj.anim_frame		= memory.readword(base + 0x21A)
	
	obj.p_hb = {}
	obj.a_hb = {}
	obj.v_hb = {}
	
	obj.t_hb = {}
	obj.ta_hb = {}
	obj.pu_hb = {}
	
	--print("scr : P addr : "..h(base + 0x2A0).." --> "..h(base + 0x2A0))
	--print("scr : A addr : "..h(base + 0x2C8).." --> "..h(base + 0x2C8))
	--print("scr : V addr : "..h(base + 0x2A8).." --> "..h(base + 0x2A8))
	
	-- passive hitboxes...
	local hb_addr = memory.readdword(base + 0x2A0)
	
	for i = 1, 4 do
		obj.p_hb[i] = getRealHitboxCoord(hb_addr, "passive", i, player)
		hb_addr = hb_addr + 8
		--print(player.." "..i.." --> "..obj.p_hb[i].left.." "..obj.p_hb[i].right.." "..obj.p_hb[i].top.." "..obj.p_hb[i].bottom)
	end
	
	-- active hitboxes...
	local hb_addr = memory.readdword(base + 0x2C8)

	for i = 1, 4 do
		obj.a_hb[i] = getRealHitboxCoord(hb_addr, "active", i, player)
		hb_addr = hb_addr + 8
		
		--print(player.." "..i.." --> "..obj.a_hb[i].left.." "..obj.a_hb[i].right.." "..obj.a_hb[i].top.." "..obj.a_hb[i].bottom)
	end
	
	-- vulnerability hitboxes...
	local hb_addr = memory.readdword(base + 0x2A8)

	for i = 1, 4 do
		obj.v_hb[i] = getRealHitboxCoord(hb_addr, "vuln", i, player)
		hb_addr = hb_addr + 8
		
		--print(player.." "..i.." --> "..obj.v_hb[i].left.." "..obj.v_hb[i].right.." "..obj.v_hb[i].top.." "..obj.v_hb[i].bottom)
	end
	
	-- throw box...
	local hb_addr = memory.readdword(base + 0x2B8)
	obj.t_hb[1] = getRealHitboxCoord(hb_addr, "throw", 1, player)
	
	-- throwable box...
	local hb_addr = memory.readdword(base + 0x2C0)
	obj.ta_hb[1] = getRealHitboxCoord(hb_addr, "throwable", 1, player)
	
	-- push box...
	local hb_addr = memory.readdword(base + 0x2D4)
	obj.pu_hb[1] = getRealHitboxCoord(hb_addr, "push", 1, player)
	
	return obj
end

--misc objects hitboxes...
function getObjectsHitboxesCoord()
	local obj_index
	local obj_addr
	local p_hb_addr
	local a_hb_addr

	local objects = {}
	
	-- This function reads all game objects other than the two player characters.
	-- This includes all projectiles and even Yang's Seiei-Enbu shadows.

	-- The game uses the same structure all over the place and groups them
	-- into lists with each element containing an index to the next element
	-- in that list. An index of -1 signals the end of the list.

	-- I believe there are at least 7 lists (0-6) but it seems everything we need
	-- (and lots we don't) is in list 3.
	local list = 3

	num_misc_objs = 1
	obj_index = memory.readwordsigned(0x02068A96 + (list * 2))

	while num_misc_objs <= 30 and obj_index ~= -1 do
		obj_addr = 0x02028990 + (obj_index * 0x800)
		
		-- I don't really know how to tell different game objects types apart yet so
		-- just read everything that has non-zero hitbox addresses. Seems to
		-- work fine...
		p_hb_addr = memory.readdword(obj_addr + 0x2A0)
		a_hb_addr = memory.readdword(obj_addr + 0x2C8)
		v_hb_addr = memory.readdword(obj_addr + 0x2A8) -- for test...

		if p_hb_addr ~= 0 and a_hb_addr ~= 0 then
			local data = getHitboxData(obj_addr, "OBJECT_"..num_misc_objs)
			objects[num_misc_objs] = data
			num_misc_objs = num_misc_objs + 1
			
			--print("scr : obj_addr : "..h(obj_addr))
			--print(data.p_hb[2].left.." "..data.p_hb[2].right.." "..data.p_hb[2].top.." "..data.p_hb[2].bottom)
		end

		-- Get the index to the next object in this list.
		obj_index = memory.readwordsigned(obj_addr + 0x1C)
	end
	
	return objects
end

-- retrieve hitboxes coord...
function getHitboxCoord(player, type)
	local hb = {}
	local addr = 0x0000
	
	if type == "P" then 
		addr = player.hb_passive_base_address
	elseif type == "A" then 
		addr = player.hb_active_base_address
	elseif type == "V" then 
		addr = player.hb_vulnerability_pointer
	elseif type == "T" then 
		addr = player.hb_throw_base_address
	elseif type == "TA" then 
		addr = player.hb_throwable_base_address
	elseif type == "PU" then 
		addr = player.hb_push_base_address
	elseif type == "O" then 
		addr = player
	end
	
	local hb_addr = memory.readdword(addr)
	--print("search at "..h(addr).." --> "..h(hb_addr))

	for i = 1, 4 do
		
		local left   = memory.readwordsigned(hb_addr)
		local right  = memory.readwordsigned(hb_addr + 2)
		local bottom = memory.readwordsigned(hb_addr + 4)
		local top    = memory.readwordsigned(hb_addr + 6)
		
		
		--[[ no more needed with fba006test
		if type == "A" then
			-- 3fv shenanigans to get actual active hitboxes with fba-rr...
			left = activeHitBoxData[hb_addr + 0x14C - 0x643FFFF]
			left = left * 0x100 + activeHitBoxData[hb_addr + 1 + 0x14C - 0x643FFFF]
			left = num2signed(left, 2)
			
			right = activeHitBoxData[hb_addr + 2 + 0x14C - 0x643FFFF]
			right = right * 0x100 + activeHitBoxData[hb_addr + 2 + 0x14C + 1 - 0x643FFFF]
			right = num2signed(right, 2)
			
			bottom = activeHitBoxData[hb_addr + 4 + 0x14C - 0x643FFFF]
			bottom = bottom * 0x100 + activeHitBoxData[hb_addr + 4 + 0x14C + 1 - 0x643FFFF]
			bottom = num2signed(bottom, 2)
			
			top = activeHitBoxData[hb_addr + 6 + 0x14C - 0x643FFFF]
			top = top * 0x100 + activeHitBoxData[hb_addr + 6 + 0x14C + 1 - 0x643FFFF]
			top = num2signed(top, 2)
			
			--if player == "P1" then print("3fv method    : coord read at "..h(hb_addr).." --> "..left.." "..right.." "..top.." "..bottom) end
		end
		--]]
		
		hb[i] = { left = left, right = right, top = top, bottom = bottom }
		
		--[[
		if type == "P" then
			print(" --> value read at "..h(addr).." = "..left)
			print(" --> value read at "..h(addr + 2).." = "..top)
			print(" --> value read at "..h(addr + 4).." = "..right)
			print(" --> value read at "..h(addr + 6).." = "..bottom)
		end
		--]]
		
		hb_addr = hb_addr + 8
	end
	
	--if type == "O" then print(hb) end
	
	return hb
end

-- take a table of 4 hitbox coords and return a string with these data concatened...
function formatHitboxString(hb, bOnScreen)
	local str = ""
	
	for i = 1, 4 do
		if bOnScreen ~= nil then
			str = str.."\n"..bOnScreen.." "..i.." : "..hb[i].left..","..hb[i].right..","..hb[i].top..","..hb[i].bottom
		else
			str = str..sep..hb[i].left..","..hb[i].right..","..hb[i].top..","..hb[i].bottom
		end
	end
	
	return string.sub(str, 2)
end

-- take a complete object and return a string with these data concatened...
function formatHitboxStringFromData(hb, type)
	local strFinal = ""
	local sType = "xxx"
	local bObject = (type == "OBJECT")
	
	-- create OBJECT block first for objects...
	if bObject then
		for iObj, oObj in pairs(hb) do
			sType = type.."_"..iObj
			
			--print(sType)
			
			local str = "\n#"..sType.." DATA BEGIN#"
		
			for iIndex, sVal in pairs(oObj) do
				if iIndex ~= "p_hb" and iIndex ~= "a_hb" and iIndex ~= "v_hb" and iIndex ~= "t_hb" and iIndex ~= "ta_hb" and iIndex ~= "pu_hb" then
					str = str.."\n"..iIndex..":"..sVal
				end
			end
			
			str = str.."\n#"..sType.." DATA END#\n\n"
			strFinal = strFinal.."\n\n"..str
			--print(str)
		end
	end
	
	
	for iObj, oObj in pairs(hb) do
		if bObject then sType = type.."_"..iObj else sType = type end
		--print("--> "..sType)
		
		local str = "#"..sType.." HITBOXES BEGIN#"
		
		for iIndex, oVal in pairs(oObj) do
			if iIndex == "p_hb" or iIndex == "a_hb" or iIndex == "v_hb" then
				str = str.."\n"..iIndex..":"
				
				for i = 1, 4 do
					str = str..oVal[i].left..","..oVal[i].right..","..oVal[i].top..","..oVal[i].bottom..sep
				end
				
				str = string.sub(str, 0, -2)
			elseif iIndex == "t_hb" or iIndex == "ta_hb" or iIndex == "pu_hb" then
				str = str.."\n"..iIndex..":"
				str = str..oVal[1].left..","..oVal[1].right..","..oVal[1].top..","..oVal[1].bottom..sep
				str = string.sub(str, 0, -2)
			end
		end
		
		str = str.."\n#"..sType.." HITBOXES END#\n\n"
		strFinal = strFinal..str
		
		--print("("..emu.framecount()..") "..str)
	end
	
	--print("("..emu.framecount()..") "..strFinal)
	
	return strFinal
end


