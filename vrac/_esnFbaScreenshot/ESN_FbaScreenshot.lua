-- take a screenshot as long as P1 state is not 0...

--
-- THIS SCRIPT MUST BE REGISTERED BEFORE !!!
--

-- write or not files...
local bWriteFiles = false

-- separator
local sep = ";"

-- begin/end trigger...
local bTriggerBegin = false
local bTriggerEnd 	= false
local bProcessBegan	= false

local aListUse = {
	normal 			= { begin = function() return (a(gameData.p1.attack, "b") > 0) end, end_ = function() return (a(gameData.p1.attack, "b") == 0) 	end	},
	dashForward 	= { begin = function() return (a(gameData.p1.state, "b") == 4) end, end_ = function() return (a(gameData.p1.state, "b") ~= 4) 	end	},
	dashBackward 	= { begin = function() return (a(gameData.p1.state, "b") == 5) end, end_ = function() return (a(gameData.p1.state, "b") ~= 5) 	end	},
	
	jumpNeutral	 	= { begin = function() return (a(gameData.p1.state, "b") == 12) end, 
						end_ = function() return (a(gameData.p1.pos_y, "ws") > 0) end },
						--end_ = function() return (a(gameData.p1.jumpRecoveryTrigger1, "b") == 2 and a(gameData.p1.jumpRecoveryTrigger2, "b") == 3) 	end	},
	jumpForward	 	= { begin = function() return (a(gameData.p1.state, "b") == 12) end, 
						end_ = function() return (a(gameData.p1.pos_y, "ws") > 0) end },
						--end_ = function() return (a(gameData.p1.jumpRecoveryTrigger1, "b") == 2 and a(gameData.p1.jumpRecoveryTrigger2, "b") == 3)	end	},
	jumpBackward 	= { begin = function() return (a(gameData.p1.state, "b") == 12) end, 
						end_ = function() return (a(gameData.p1.pos_y, "ws") > 0) end },
						--end_ = function() return (a(gameData.p1.jumpRecoveryTrigger1, "b") == 2 and a(gameData.p1.jumpRecoveryTrigger2, "b") == 3) 	end	},
	
	superjumpNeutral	= { begin = function() return (a(gameData.p1.state, "b") == 13) end, 
						end_ = function() return (a(gameData.p1.pos_y, "ws") > 0) end },
						--end_ = function() return (a(gameData.p1.jumpRecoveryTrigger1, "b") == 2 and a(gameData.p1.jumpRecoveryTrigger2, "b") == 3) 	end	},
	superjumpForward 	= { begin = function() return (a(gameData.p1.state, "b") == 13) end, 
						end_ = function() return (a(gameData.p1.pos_y, "ws") > 0) end },
						--end_ = function() return (a(gameData.p1.jumpRecoveryTrigger1, "b") == 2 and a(gameData.p1.jumpRecoveryTrigger2, "b") == 3) 	end	},
	superjumpBackward	= { begin = function() return (a(gameData.p1.state, "b") == 13) end, 
						end_ = function() return (a(gameData.p1.pos_y, "ws") > 0) end },
						--end_ = function() return (a(gameData.p1.jumpRecoveryTrigger1, "b") == 2 and a(gameData.p1.jumpRecoveryTrigger2, "b") == 3) 	end	},
	
	
	-- P1 sa bar MUST BE empty first!!!
	wakeUp 			= { begin = function() return (a(gameData.p1.saBarContent, "b") > 0) end, end_ = function() return (a(gameData.p1.attack, "b") == 0) 	end	}, -- makoto state --> 78, others 5
	wakeUpQuickRoll = { begin = function() return (a(gameData.p1.saBarContent, "b") > 0) end, end_ = function() return (a(gameData.p1.attack, "b") == 0) 	end	},
	
	combo		 	= { begin = function() return (a(gameData.p1.state, "b") > 0)  end, end_ = function() return (a(gameData.p1.state, "b") == 0 and a(gameData.p2.state, "b") == 0) 	end	},
}

sScriptUse = "normal"

iMiscListIndexToRead = 12
sMiscIndexPrefix = "line_"

aMiscList = {

line_1 = "dashForward",
line_2 = "dashBackward",
line_3 = "jumpBackward",
line_4 = "jumpNeutral",
line_5 = "jumpForward",
line_6 = "superjumpBackward",
line_7 = "superjumpNeutral",
line_8 = "superjumpForward",

-- recovery cancelled by jump...
line_9 = "dashForward",
line_10 = "dashBackward",

line_11 = "wakeUp",
line_12 = "wakeUpQuickRoll",
}

print(aMiscList[sMiscIndexPrefix..iMiscListIndexToRead])

iSimpleCounter = 0
sResultToWriteInFile = ""

-- end trigger...

hb_currentFrame = 0
hb_previousFrame = 0
hb_p1Atk_counter = 0
local prevFileName = "" -- previous frame
local prevDataMame = "" -- previous frame data
local antepenultianFileName = "" -- antepenultian frame
local iResetIn = 2 -- countdown to continue to take 2 screenshot event after p1Atk back to 0...

-- get coord hitbox data...
function getRealHitboxCoord(hb_addr)
	local left   = memory.readwordsigned(hb_addr)
	local right  = memory.readwordsigned(hb_addr + 2)
	local bottom = memory.readwordsigned(hb_addr + 4)
	local top    = memory.readwordsigned(hb_addr + 6)

	--print("scr : coord read at "..h(hb_addr).." --> "..left.." "..right.." "..top.." "..bottom)
	
	return { left = left, right = right, top = top, bottom = bottom }
end

-- get all datas for hitbox addr...
function getHitboxData(base, type)
	local obj = {}
	
	obj.type			= type
	obj.facing_dir		= memory.readbyte(base + 0xA)
	obj.opponent_dir	= memory.readbyte(base + 0xB)
	obj.pos_x			= memory.readwordsigned(base + 0x64)
	obj.pos_y			= memory.readwordsigned(base + 0x68)
	obj.anim_frame		= memory.readwordsigned(base + 0x21A)
	
	obj.p_hb = {}
	obj.a_hb = {}
	obj.v_hb = {}
	
	--print("scr : P addr : "..h(base + 0x2A0).." --> "..h(base + 0x2A0))
	--print("scr : A addr : "..h(base + 0x2C8).." --> "..h(base + 0x2C8))
	--print("scr : V addr : "..h(base + 0x2A8).." --> "..h(base + 0x2A8))
	
	-- passive hitboxes...
	local hb_addr = memory.readdword(base + 0x2A0)
	
	for i = 1, 4 do
		obj.p_hb[i] = getRealHitboxCoord(hb_addr)
		hb_addr = hb_addr + 8
		--print(type.." "..i.." --> "..obj.p_hb[i].left.." "..obj.p_hb[i].right.." "..obj.p_hb[i].top.." "..obj.p_hb[i].bottom)
	end
	
	-- active hitboxes...
	local hb_addr = memory.readdword(base + 0x2C8)

	for i = 1, 4 do
		obj.a_hb[i] = getRealHitboxCoord(hb_addr)
		hb_addr = hb_addr + 8
		
		--print(type.." "..i.." --> "..obj.a_hb[i].left.." "..obj.a_hb[i].right.." "..obj.a_hb[i].top.." "..obj.a_hb[i].bottom)
	end
	
	-- vulnerability hitboxes...
	local hb_addr = memory.readdword(base + 0x2A8)

	for i = 1, 4 do
		obj.v_hb[i] = getRealHitboxCoord(hb_addr)
		hb_addr = hb_addr + 8
		
		--print(type.." "..i.." --> "..obj.v_hb[i].left.." "..obj.v_hb[i].right.." "..obj.v_hb[i].top.." "..obj.v_hb[i].bottom)
	end
	
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
			local data = getHitboxData(obj_addr, "Object_"..num_misc_objs)
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
		
		hb[i] = { left = left, right = right, top = top, bottom = bottom }
		
		--[[
		if type == "V" then
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
function formatHitboxStringFromData(hb, bOnScreen)
	local str = "#BEGIN#"
	
	for iObj, oObj in pairs(hb) do
		for iIndex, oVal in pairs(oObj) do
			if iIndex == "p_hb" or iIndex == "a_hb" or iIndex == "v_hb" then
				str = str.."\n"..iIndex..":"
				
				for i = 1, 4 do
					str = str..oVal[i].left..","..oVal[i].right..","..oVal[i].top..","..oVal[i].bottom..sep
				end
				
				str = string.sub(str, 0, -2)
			else
				str = str.."\n"..iIndex..":"..oVal
			end
		end
	end
	
	str = str.."\n".."#END#"
	
	--print(str)
	
	return str
end

function fbaScreenshot()
	--gui.clearuncommitted()
	
	-- only fba, mame crash while screenshot...
	if fba or mame then
		-- avoid doing process several times...
		hb_currentFrame = emu.framecount()
		
		if hb_currentFrame ~= hb_previousFrame then
			
			local efc = emu.framecount()
			local fileName_Fba = ""
			local data_Mame = ""
			
			local p1Atk 	= a(gameData.p1.attack, "b")
			local p1State 	= a(gameData.p1.state, "b")
			local p1pos_x 	= a(gameData.p1.pos_x, "ws")
			local p1pos_y 	= a(gameData.p1.pos_y, "ws")
			local p1Frame 	= a(gameData.p1.anim_frame, "w")
			local p2Atk 	= a(gameData.p2.attack, "b")
			local p2State 	= a(gameData.p2.state, "b")
			local p2pos_x 	= a(gameData.p2.pos_x, "ws")
			local p2pos_y 	= a(gameData.p2.pos_y, "ws")
			local p2Frame 	= a(gameData.p2.anim_frame, "w")
			local p1activeThrow		= a(gameData.p1.activeThrow, "b")
			local p2activeThrow		= a(gameData.p2.activeThrow, "b")
			local p1saBarContent	= a(gameData.p1.saBarContent, "b")
			local p2saBarContent	= a(gameData.p2.saBarContent, "b")
			
			local p1jumpRecoveryTrigger1	= a(gameData.p1.jumpRecoveryTrigger1, "b")
			local p1jumpRecoveryTrigger2	= a(gameData.p1.jumpRecoveryTrigger2, "b")
			
			local gamePhase = a(gameData.game.game_phase, "b")
			local screen_center_x = a(gameData.game.screen_center_x, "ws")
			local screen_center_y = a(gameData.game.screen_center_y, "ws")
			local superfreeze = a(gameData.game.superfreeze, "b")
			
			if bWriteFiles == false then
				sScriptUse = aMiscList[sMiscIndexPrefix..iMiscListIndexToRead]
			end
			
			bTriggerBegin = aListUse[sScriptUse].begin()
			bTriggerEnd = aListUse[sScriptUse].end_() and iSimpleCounter > 3
			
			if bProcessBegan == false and bTriggerBegin then
				bProcessBegan = true
			end
			
			if bProcessBegan then
				iSimpleCounter = iSimpleCounter + 1
				print(iSimpleCounter.." : "..tostring(bTriggerEnd).." / "..tostring((iSimpleCounter > 3)))
			end
			
			if bTriggerEnd then
				if p1State == 12 then sCancel = "CancelledRecovery" else sCancel = "" end
				print(sScriptUse..sCancel.." : "..(iSimpleCounter - 1).." frames")
				sResultToWriteInFile = sScriptUse..sCancel..":"..(iSimpleCounter - 1).."\n"
				wrFile(sResultToWriteInFile, a(chars.p1addr, "b").."_misc_frames_data.txt")
				
				if bWriteFiles == false then iMiscListIndexToRead = iMiscListIndexToRead + 1 end
				
				bProcessBegan = false
				iSimpleCounter = 0
			end
			
			--print(tostring(bTriggerBegin).." / "..tostring(bTriggerEnd).." / "..tostring(bProcessBegan))
			
			local p1_hb_P = getHitboxCoord(gameData.p1, "P")
			local p1_hb_A = getHitboxCoord(gameData.p1, "A")
			local p1_hb_V = getHitboxCoord(gameData.p1, "V")

			local p2_hb_P = getHitboxCoord(gameData.p2, "P")
			local p2_hb_A = getHitboxCoord(gameData.p2, "A")
			local p2_hb_V = getHitboxCoord(gameData.p2, "V")
			
			data_Mame = 				 "ScriptUse:"..sScriptUse
			data_Mame = data_Mame.."\n".."P1:"..a(chars.p1addr, "b")
			data_Mame = data_Mame.."\n".."P2:"..a(chars.p2addr, "b")
			data_Mame = data_Mame.."\n".."screen_center_x:"..screen_center_x
			data_Mame = data_Mame.."\n".."screen_center_y:"..screen_center_y
			data_Mame = data_Mame.."\n".."superfreeze:"..superfreeze
			data_Mame = data_Mame.."\n".."p1Atk:"..p1Atk
			data_Mame = data_Mame.."\n".."p2Atk:"..p2Atk
			data_Mame = data_Mame.."\n".."p1State:"..p1State
			data_Mame = data_Mame.."\n".."p2State:"..p2State
			data_Mame = data_Mame.."\n".."p1activeThrow:"..p1activeThrow
			data_Mame = data_Mame.."\n".."p2activeThrow:"..p2activeThrow
			data_Mame = data_Mame.."\n".."p1saBarContent:"..p1saBarContent
			data_Mame = data_Mame.."\n".."p2saBarContent:"..p2saBarContent
			data_Mame = data_Mame.."\n".."p1jumpRecoveryTrigger1:"..p1jumpRecoveryTrigger1
			data_Mame = data_Mame.."\n".."p1jumpRecoveryTrigger2:"..p1jumpRecoveryTrigger2
			
			data_Mame = data_Mame.."\n"..formatHitboxStringFromData({getHitboxData(gameData.p1.hb_base_address, "P1")})
			data_Mame = data_Mame.."\n"..formatHitboxStringFromData({getHitboxData(gameData.p2.hb_base_address, "P2")})
			data_Mame = data_Mame.."\n"..formatHitboxStringFromData(getObjectsHitboxesCoord())
			
			--print(data_Mame)
			
			-- format the future filename...
			local prefix = a(chars.p1addr, "b")..sep..a(chars.p2addr, "b")
			
			fileName_Fba = fileName_Fba..sScriptUse
			fileName_Fba = fileName_Fba..sep..screen_center_x
			fileName_Fba = fileName_Fba..sep..screen_center_y
			fileName_Fba = fileName_Fba..sep..p1pos_x
			fileName_Fba = fileName_Fba..sep..p1pos_y
			fileName_Fba = fileName_Fba..sep..p2pos_x
			fileName_Fba = fileName_Fba..sep..p2pos_y
			fileName_Fba = fileName_Fba..sep..superfreeze
			fileName_Fba = fileName_Fba..sep.."p1_hb_P"..sep..formatHitboxString(p1_hb_P)..sep.."p1_hb_P"
			
			
			
			if fba then
				-- fba, screenshot function...
				
				local bTakeScreenshot = false
				
				-- for fba screenshot function :
				-- current frame screenshot must be done next frame, but correct frame data are those from the current frame...

				if bTriggerBegin or bProcessBegan then
					-- increment counter...
					hb_p1Atk_counter = hb_p1Atk_counter + 1
					
					-- only take screenshot after 2 incrementations...
					if hb_p1Atk_counter > 2 then
						bTakeScreenshot = true
					end
				elseif bTriggerEnd then
					-- verify counter to get the last two screenshot after p1Atk back to 0...
					if hb_p1Atk_counter > 2 and iResetIn > 0 then
						bTakeScreenshot = true
						
						iResetIn = iResetIn - 1
						hb_p1Atk_counter = hb_p1Atk_counter + 1
					else
						hb_p1Atk_counter = 0
						iResetIn = 2
					end
				else
					--print("???")
				end
				
				if bTakeScreenshot == true then
					--print(hb_p1Atk_counter.." --> "..prefix..sep..string.format("%03s", (hb_p1Atk_counter - 2))..sep..antepenultianFileName)
					if bWriteFiles then scr(prefix..sep..string.format("%03s", (hb_p1Atk_counter - 2))..sep..antepenultianFileName) end
				elseif hb_p1Atk_counter == 2 then
					-- process begin, also store previous data for frame 0...
					--print(hb_p1Atk_counter.." --> "..prefix..sep..string.format("%03s", (hb_p1Atk_counter - 2))..sep..antepenultianFileName)
					if bWriteFiles then scr(prefix..sep..string.format("%03s", (hb_p1Atk_counter - 2))..sep..antepenultianFileName) end
				end
				
				antepenultianFileName = prevFileName
				prevFileName = fileName_Fba
			else
				-- mame, frame data stored in file...
				if bTriggerBegin or bProcessBegan then
					-- if process begin, also store previous data for frame 0...
					if hb_p1Atk_counter == 0 then
						local finalNameMame = prefix..sep..string.format("%03s", hb_p1Atk_counter)..sep..prevFileName
						--print(finalNameMame)
						
						-- for mame, store all data in a file...
						if bWriteFiles then wrFile("frame:"..string.format("%03s", hb_p1Atk_counter).."\n"..prevDataMame, finalNameMame..".frame") end
						displayValue("File written : "..hb_p1Atk_counter, 170, 68, 0x99ff99ff)
					end
					
					-- increment counter...
					hb_p1Atk_counter = hb_p1Atk_counter + 1
					
					local finalNameMame = prefix..sep..string.format("%03s", hb_p1Atk_counter)..sep..fileName_Fba
					--print(finalNameMame)
					
					-- for mame, store all data in a file...
					if bWriteFiles then wrFile("frame:"..string.format("%03s", hb_p1Atk_counter).."\n"..data_Mame, finalNameMame..".frame") end
					displayValue("File written : "..hb_p1Atk_counter, 170, 68, 0x99ff99ff)
				elseif bTriggerEnd then
					hb_p1Atk_counter = 0
				else
					--print("???")
				end
				
				prevDataMame = data_Mame
				prevFileName = fileName_Fba
			end
			
			hb_previousFrame = hb_currentFrame
			
			----[[
			if bWriteFiles == false or mame then
				displayValue(sScriptUse, 170, 38, 0xff0000ff)
				displayValue(sScriptUse, 170, 38, 0xff0000ff)
				displayValue("bTriggerBegin : "..tostring(bTriggerBegin), 	170, 48, 0xff9999ff)
				displayValue("bTriggerEnd   : "..tostring(bTriggerEnd), 	170, 58, 0xff9999ff)
				
				displayValue("screen_center_x : "..screen_center_x, 3, 1, 0x00ffffff)
				displayValue("screen_center_y : "..screen_center_y, 3, 9, 0x00ffffff)
				
				displayValue("superfreeze : "..superfreeze, 170, 0, 0x00ffffff)
				displayValue(emu.framecount(), 250, 0, 0x00ffffff)
				
				displayValue("P1 Atk   : "..p1Atk, 			3, 50, 0xffff00ff)
				displayValue("P1 State : "..p1State, 		3, 58, 0xffff00ff)
				displayValue("P1 pos X : "..p1pos_x, 		3, 70, 0xffff00ff)
				displayValue("P1 pos Y : "..p1pos_y,		3, 78, 0xffff00ff)
				displayValue("P1 frame : "..p1Frame,		3, 90, 0xffff00ff)
				
				displayValue(sp(p2pos_x, 4).." : P2 pos X", 320, 50, 0xff00ffff)
				displayValue(sp(p2pos_y, 4).." : P2 pos Y",	320, 58, 0xff00ffff)
				displayValue(sp(p2Atk, 4).." : P2 Atk", 	320, 70, 0xff00ffff)
				displayValue(sp(p2State, 4).." : P2 State", 320, 78, 0xff00ffff)
				displayValue(sp(p2Frame, 4).." : P2 frame", 320, 98, 0xff00ffff)
				
				--displayValue(formatHitboxString(p1_hb_P, "HB P "), 160, 70, 0x00ffffff)
			end
		end
		
		--]]
		
		--[[
		
		displayValue(formatHitboxString(p1_hb_P, "HB P "), 285, 50, 0x00ffffff)
		displayValue(formatHitboxString(p1_hb_A, "HB A "), 285, 85, 0x00ff00ff)
		displayValue(formatHitboxString(p1_hb_V, "HB V "), 285, 120, 0xff0000ff)
		
		--]]
	end
end
