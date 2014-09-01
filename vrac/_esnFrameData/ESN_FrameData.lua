-- detemernine frames data...

frameData = {
	startup = nil,
	active = {},
	framesActive = 0,
	framesActiveThrow = 0,
	recovery = nil,
	hitstun = nil,
	hitAdv = nil,
	blkAdv = nil,
	crHitAdv = nil,
	crBlkAdv = nil,
	isBlocking = false,
	isThrow = false,
	isUoh = false,
	isWhiff = false,
	isCrouching = false,
	damage = nil,
	stun = nil,
	saBarContent = nil,
	p1Total = nil,
	p2Total = nil,
}

frameDataRead = {
	startup = nil,
	framesActive = 0,
	framesActiveThrow = 0,
	recovery = nil,
	hitAdv = nil,
	blkAdv = nil,
	crHitAdv = nil,
	crBlkAdv = nil,
	damage = nil,
	stun = nil,
	saBarContent = nil,
}

-- inProgress : true when p1 atk > 0, back to false when is true and p1 atk = 0 and p2 atk = 0
inProgress = false
bFileWritten = false
bNonActiveMove = false
bActiveObjectFound = false
sFileContent = ""
bUnknownState = false
sColorProcessNotDone = 0xffcc00ff
sColorProcessDone = 0x00ff00ff

noHitboxesCounter = 0
frameP1Attack = nil
frameP1FirstActive = nil
frameP1LastActive = nil
frameP1EndActive = nil
frameP2Hit = nil
frameP1End = nil
frameP2End = nil
framesActive = 0
isNormal = false
isSpecial = false
isSA = false
isThrow = false
framesActiveThrow = 0
uohTestCounter = 0 -- counter for macrolua successive tests
isUoh = false
minBlkAdv = 100
maxBlkAdv = -100
minHitAdv = 100
maxHitAdv = -100
minCrHitAdv = 100
maxCrHitAdv = -100


isParry = false
isCrouchingParry = false
isCrouchingGuard = false
isStandingGuard = false
isWhiff = false
isCrouching = false
isSuperArt = nil
isWhiff = true
isActive = false
startActive = nil
activePreviousValue = nil
damage = {}
stun = {}
hits = {}
active = {}
joypadMotion = {}
listDamage = ""
listStun = ""
listDamageTmp = ""
listStunTmp = ""
currentSaBarContent = 0
saBarContent = ""
currentSaBarContentP2 = 0
saBarContentP2 = ""
iSJDuration = 0
isSuperJump = false

local lastHitDamage = 0

-- state values for p2:
--  0: neutral
--  1: guard high
--  2: guard low
-- 25: parry projectile
-- 24: parry projectile
--  3: back
--  2: forward
--  6: from standing to crouching, then 7
-- 12: jump startup
-- 15: jump
-- 13: superjump startup
-- 21: superjump

-- 22: being hit by normal, back to zero when hitstun end
-- 	8: being hit in air, knockdown
--  9: being hit by projectile
-- 93: being hit by projectile after parry?
-- 43: being grabbed by demon or tech throw
--  5: being grabbed
-- 64: knockdowned and wakeup
-- 72: quick roll

local increment = 0
local incr = 0

-- return true if there no passive hitboxes and no vuln hitboxes for P1n meaning...
function isNoHitboxes()
	local addr = gameData.p1.hb_base_address
	
	local bReturn = true
	
	-- passive hitboxes
	local p_hb_addr = memory.readdword(addr + 0x2A0)
	
	for i = 1, 4 do
		local left   = memory.readwordsigned(p_hb_addr)
		local right  = memory.readwordsigned(p_hb_addr + 2)
		local bottom = memory.readwordsigned(p_hb_addr + 4)
		local top    = memory.readwordsigned(p_hb_addr + 6)
		
		if left ~= 0 or right ~= 0 or top ~= 0 or bottom ~= 0 then
			-- at least one box is defined...
			bReturn = false
			break
		end
		
		p_hb_addr = p_hb_addr + 8
	end
	
	local vuln_attack_pointer_address = addr + 0x02A8 --0x02068F14 for P1, 0x020693AC for P2

	local t_hb_addr = memory.readdword(vuln_attack_pointer_address)
	
	for i = 1, 4 do
		local left   = memory.readwordsigned(t_hb_addr)
		local right  = memory.readwordsigned(t_hb_addr + 2)
		local bottom = memory.readwordsigned(t_hb_addr + 4)
		local top    = memory.readwordsigned(t_hb_addr + 6)
		
		if left ~= 0 or right ~= 0 or top ~= 0 or bottom ~= 0 then
			-- at least one box is defined...
			bReturn = false
			break
		end
		
		t_hb_addr = t_hb_addr + 8
	end
	
	return bReturn
end

-- return true if an object has an active hitbox detected...
function isActiveObject()
	local obj_index
	local obj_addr

	local p_hb_addr
	local a_hb_addr
	local bReturn = false
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
		v_hb_addr = memory.readdword(obj_addr + 0x2A8)

		--print(h(p_hb_addr)..""..h(a_hb_addr)..""..h(v_hb_addr))
		
		if p_hb_addr ~= 0 and a_hb_addr ~= 0 then
			bReturn = true
			--print("ACTIVE OBJECT")
			break
		end

		-- Get the index to the next object in this list.
		obj_index = memory.readwordsigned(obj_addr + 0x1C)
	end
	
	return bReturn
end

-- return true if P1 has an active throw...
function isP1ActiveThrow()
	bReturn = false
	
	if a(gameData.p1["activeThrow"], "b") ~= 0 then
		bReturn = true
	end
	
	return bReturn
end

function checkHits()
	if inProgress == true then
		if a(gameData.p1["hb_active_presence"], "b") ~= 0 then
			if isActive == false then
				-- new active window...
				isActive = true
				startActive = emu.framecount() -- store begin frame number...
				activePreviousValue = a(gameData.p1["hb_active_presence"], "b") -- store value to compare with on next frame...
			else
				-- active window already start, check if previous value is same as actual...
				if a(gameData.p1["hb_active_presence"], "b") ~= activePreviousValue then
					-- check if only one frame has been passed...
					if emu.framecount() - startActive == 1 then
						-- add this like another hit...
						add(active, (emu.framecount() - startActive))
						
						-- start another window
						startActive = emu.framecount()
						activePreviousValue = a(gameData.p1["hb_active_presence"], "b")
					end
				end
			end
		else
			if isActive == true then
				-- end of active window...
				isActive = false
				add(active, (emu.framecount() - startActive))
			end
		end
	end
end

-- check damage...
function checkDamageAndStun()
	local tmpDamg = a(gameData.p2["damageOfNextHit"], "b")
	local tmpStun = a(gameData.p2["stunOfNextHit"], "b")
	
	if inProgress == true then
		if tmpDamg > 0 or tmpStun > 0 then
			listDamageTmp = listDamageTmp.."#"..tmpDamg
			listStunTmp = listStunTmp.."#"..tmpStun
			
			add(damage, tmpDamg)
			add(stun, tmpStun)
			add(hits, emu.framecount())
		end
	end
end

-- check p1...
function checkP1()
	if inProgress == false then
		currentSaBarContent = a(gameData.p1["saBarContent"], "b")
		currentSaBarContentP2 = a(gameData.p2["saBarContent"], "b")
	end
	
	if inProgress == false and frameP1Attack == nil and p1Atk() == true then
		-- p1 begin
		reset()
		
		inProgress = true
		frameP1Attack = emu.framecount()
		--print("frameP1Attack : "..frameP1Attack)
		
		if a(gameData.game["superfreeze"], "b") > 0 then
			isSuperArt = true
		end
		
		-- check for throw...
		if a(gameData.p1["state"], "b") == 144 or a(gameData.p1["attack"], "b") == 2 then
			isThrow = true
			--print("THROW --")
		end
		
		-- check for UOH, value will change for some others chars...
		if a(gameData.p1["state"], "b") == 56 then
			isUoh = true
		end
		
		-- retrieve joypad...
		joypadMotion = joypad.getdown()
	end
	
	-- check for sa bar content...
	if inProgress == true then
		if a(gameData.p1["saBarContent"], "b") > currentSaBarContent then
			saBarContent = saBarContent.."#"..(a(gameData.p1["saBarContent"], "b") - currentSaBarContent)
			saBarContentP2 = saBarContentP2.."#"..(a(gameData.p2["saBarContent"], "b") - currentSaBarContentP2)
			currentSaBarContent = a(gameData.p1["saBarContent"], "b")
			currentSaBarContentP2 = a(gameData.p2["saBarContent"], "b")
		end
	end
	
	-- check for throw...
	if inProgress == true and (a(gameData.p1["attack"], "b") == 2 or isP1ActiveThrow()) and isThrow == false then
		isThrow = true
		frameP1FirstActive = emu.framecount()
		--print("THROW")
		--print("startup = "..(frameP1FirstActive - frameP1Attack))
	end
	
	-- check for throw active...
	if inProgress == true and isP1ActiveThrow() then 
		framesActiveThrow = framesActiveThrow + 1
	end
	
	-- check for end of throw active frames...
	if inProgress == true and isP1ActiveThrow() == false and framesActiveThrow > 0 then 
		frameP1LastActive = emu.framecount()
	end
	
	if inProgress == true and isSuperArt == true then
		if a(gameData.game["superfreeze"], "b") > 0 then
			-- while superfreeze, startup is shifted until the end...
			frameP1Attack = emu.framecount()
			--print("frameP1Attack (SA) : "..emu.framecount())
		end
	end
	
	if inProgress == true and frameP1FirstActive == nil and (p1ActiveHitboxes() or isActiveObject() or p2Hit()) then
		-- p1 active...
		frameP1FirstActive = emu.framecount()
		--print("frameP1FirstActive : "..frameP1FirstActive)
	end
	
	if inProgress == true and frameP1End == nil and p1Atk() == false then
		-- p1 end...
		frameP1End = emu.framecount()
		--print("frameP1End : "..frameP1End)
	end
	
	if inProgress == true and p1ActiveHitboxes() == true then
		frameP1LastActive = emu.framecount()
		framesActive = framesActive + 1
	end
	
	if inProgress == true and isNoHitboxes() == true then
		noHitboxesCounter = noHitboxesCounter + 1
	end
	
	if inProgress == true and bActiveObjectFound == false and isActiveObject() == true then
		frameP1FirstActive = emu.framecount() + 1
		frameP1LastActive = emu.framecount()
		framesActive = 1
		bActiveObjectFound = true
		--print("frameP1LastActive : "..frameP1LastActive)
	end
end

-- check p2...
function checkP2()
	if inProgress == true and frameP2Hit == nil and p2Hit() == true then
		-- p2 hit begin
		frameP2Hit = emu.framecount()
		--print("frameP2Hit : "..frameP2Hit)
	end
	
	if inProgress == true and frameP2Hit ~= nil and frameP2End == nil and p2Hit() == false then
		-- p2 end...
		frameP2End = emu.framecount()
		--print("frameP2End : "..frameP2End)
	end
	
	-- verify if it hits or whiff...
	if inProgress == true and p2Hit() == true then
		isWhiff = false
	end
	
	-- find p2 state : standing hit/block, crouching hit/block...
	if inProgress == true then
		local p2state = a(gameData.p2["state"], "b")
		
		if a(gameData.p2["hit_by_N"], "b") > 0 then isNormal = true end
		if a(gameData.p2["hit_by_S"], "b") > 0 then isSpecial = true end
		if a(gameData.p2["hit_by_SA"], "b") > 0 then isSA = true end
		if a(gameData.p2["hit_by_SA_other"], "b") > 0 then isSA = true end
		
		if 		p2state == 25 then isParry = true -- standing parry
		elseif	p2state == 26 then isCrouchingParry = true -- crouching parry
		elseif	p2state == 30 and isNormal == false then isStandingGuard = true -- standing guard
		elseif 	p2state == 2 then isCrouchingGuard = true -- crouching guard
		elseif 	p2state == 6 then isCrouching = true -- crouching state
		elseif 	p2state == 7 and isWhiff == true then isCrouching = true -- crouching state
		
		-- we suppose it's guard as p2 seems to be hit but take near no damage
		elseif 	p2Hit() == true and a(gameData.p2["damageOfNextHit"], "b") > 0 and a(gameData.p2["damageOfNextHit"], "b") < 3 then isStandingGuard = true
		end
	end
	
end

-- detect if both players are back to atk = 0 (neutral)
function checkEnd()
	if inProgress == true then
		if p1Atk() == false and p2Hit() == false then
			local header = ""
			local data = ""
			
			if isUoh == true then
				uohTestCounter = uohTestCounter + 1
				
				frameData.p1Total = frameP1End - frameP1Attack
				frameData.startup = frameP1FirstActive - frameP1Attack
				frameData.framesActive = framesActive
				frameData.recovery = frameP1End - frameP1LastActive - 1
				
				if isStandingGuard == true and isWhiff ~= true then
					frameData.blkAdv = frameP2End - frameP1End
					if frameData.blkAdv < minBlkAdv then minBlkAdv = frameData.blkAdv end
					if frameData.blkAdv > maxBlkAdv then maxBlkAdv = frameData.blkAdv end
					
					--print(uohTestCounter.." : STANDING GUARD ADV : "..frameData.blkAdv.." minBlkAdv : "..minBlkAdv.." maxBlkAdv : "..maxBlkAdv)
				elseif isWhiff == true then
					--print(uohTestCounter.." : WHIFF Startup : "..frameData.startup.." Active : "..frameData.framesActive.." Recovery : "..frameData.recovery)
				elseif isCrouching == true then
					frameData.crHitAdv = frameP2End - frameP1End
					if frameData.crHitAdv < minCrHitAdv then minCrHitAdv = frameData.crHitAdv end
					if frameData.crHitAdv > maxCrHitAdv then maxCrHitAdv = frameData.crHitAdv end
					
					--print(uohTestCounter.." : CROUCHING HIT ADV : "..frameData.crHitAdv.." minCrHitAdv : "..minCrHitAdv.." maxCrHitAdv : "..maxCrHitAdv)
				else
					-- standing hit...
					frameData.hitAdv = frameP2End - frameP1End
					if frameData.hitAdv < minHitAdv then minHitAdv = frameData.hitAdv end
					if frameData.hitAdv > maxHitAdv then maxHitAdv = frameData.hitAdv end
					
					--print(uohTestCounter.." : STANDING HIT ADV : "..frameData.hitAdv.." mminHitAdv : "..minHitAdv.." maxHitAdv : "..maxHitAdv)
				end
				
				header = "UOH;startup;active;recovery;blkAdv;hitAdv;crHitAdv"
				data = "UOH;"..frameData.startup..";"..frameData.framesActive..";"..frameData.recovery..";"
				data = data..minBlkAdv.." ~ "..maxBlkAdv..";"..minHitAdv.." ~ "..maxHitAdv..";"..minCrHitAdv.." ~ "..maxCrHitAdv
				
				--[[
				print("uohTestCounter : "..uohTestCounter)
				print(header)
				print(data)
				print()
				--]]
				
			elseif isThrow == true then
				frameData.p1Total = frameP1End - frameP1Attack
				frameData.startup = frameP1FirstActive - frameP1Attack
				frameData.framesActive = framesActiveThrow
				frameData.recovery = frameData.p1Total - frameData.startup - frameData.framesActive
				
				--print("startup = "..frameP1FirstActive.." - "..frameP1Attack.." = "..(frameP1FirstActive - frameP1Attack).." --> "..frameData.startup)
				
				header = "THROW;p1Total;startup;active;recovery"
				data = "THROW;"..frameData.p1Total..";"..frameData.startup..";"..frameData.framesActive..";"..frameData.recovery
				
				bNonActiveMove = "THROW"
			elseif isWhiff == true then
				-- whiff
				frameData.p1Total = frameP1End - frameP1Attack
				
				-- check non active moves...
				if frameP1FirstActive == nil then
					--print("NON ACTIVE MOVE")
					
					if noHitboxesCounter > 0 then
						--special cases of gouki teleport...
						frameData.startup = noHitboxesCounter
						frameData.framesActive = "-"
						frameData.recovery = frameData.p1Total - noHitboxesCounter
					else
						frameData.startup = "-"
						frameData.framesActive = "-"
						frameData.recovery = frameP1End - frameP1Attack
					end
					
					bNonActiveMove = "NON ACTIVE MOVE"
				else
					frameData.startup = frameP1FirstActive - frameP1Attack
					frameData.framesActive = framesActive
					frameData.recovery = frameP1End - frameP1LastActive - 1
				end
				
				if isSuperArt == true then frameData.startup = frameData.startup end
				
				header = "WHIFF;p1Total;startup;active;recovery"
				data = "WHIFF;"..frameData.p1Total..";"..frameData.startup..";"..frameData.framesActive..";"..frameData.recovery
				
			elseif isNormal == true or isSpecial == true or isSA == true or isStandingGuard == true or isCrouchingGuard == true then
				
				-- check frameP1FirstActive, certain move doesn't have a visible active hitboxes on hit, like Gouki fw.MP or Q st.LK...
				if frameP1FirstActive == nil or frameP1LastActive == nil then
					frameP1FirstActive = 9999999
					frameP1LastActive = 9999999
				end
				
				frameData.p1Total = frameP1End - frameP1Attack
				frameData.startup = frameP1FirstActive - frameP1Attack
				frameData.recovery = frameP1End - frameP1LastActive - 1

				if isSuperArt == true then frameData.startup = frameData.startup end
				
				-- hit/block
				frameData.p2Total = frameP2End - frameP2Hit

				if isCrouchingGuard == true then
					--frameData.crBlkAdv = frameP2End - frameP1End
					frameData.blkAdv = frameP2End - frameP1End
					
					header = "CROUCHING GUARD;p2Total;blkAdv"
					data = "CROUCHING GUARD;"..frameData.p2Total..";"..frameData.blkAdv
				elseif isCrouching == true then
					frameData.crHitAdv = frameP2End - frameP1End
					
					header = "CROUCHING HIT;p2Total;crHitAdv"
					data = "CROUCHING HIT;"..frameData.p2Total..";"..frameData.crHitAdv
				elseif isStandingGuard == true then 
					frameData.blkAdv = frameP2End - frameP1End
					
					header = "STANDING GUARD;p2Total;blkAdv"
					data = "STANDING GUARD;"..frameData.p2Total..";"..frameData.blkAdv
				else
					frameData.hitAdv = frameP2End - frameP1End
					
					header = "STANDING HIT;p2Total;hitAdv;damage;stun"
					data = "STANDING HIT;"..frameData.p2Total..";"..frameData.hitAdv..";"..string.sub(listDamageTmp, 2)..";"..string.sub(listStunTmp, 2)
					
				end
			else
				-- error?, should never happens...
				print("error : unknown state...")
				bUnknownState = true
			end
			
			-- add saBarContent data for any type of move...
			header = header..";saBarP1;saBarP2"
			data = data..";"..string.sub(saBarContent, 2)..";"..string.sub(saBarContentP2, 2)
			
			sFileContent = sFileContent.."\n"..header.."\n"..data.."\n"
			listDamageTmp = ""
			listStunTmp = ""
			saBarContent = ""
			saBarContentP2 = ""
			
			--print(header)
			--print(data)
			
			frameDataRead.startup = frameData.startup
			frameDataRead.recovery = frameData.recovery
			frameDataRead.framesActive = frameData.framesActive
			frameDataRead.framesActiveThrow = frameData.framesActiveThrow
			frameDataRead.hitAdv = frameData.hitAdv
			frameDataRead.blkAdv = frameData.blkAdv
			frameDataRead.crHitAdv = frameData.crHitAdv
			frameDataRead.damage = frameData.damage
			frameDataRead.stun = frameData.stun
			frameDataRead.isWhiff = isWhiff
			frameDataRead.isThrow = isThrow
			frameDataRead.isUoh = isUoh
			frameDataRead.bNonActiveMove = bNonActiveMove
			frameDataRead.bUnknownState = bUnknownState
			
			reset()
			
			--[[
			-- write summary file when all needed data are collected...
			if bFileWritten == false and frameDataRead.isUoh == true and uohTestCounter == 16 then
				wrFileWithAutoNumericSuffix("#BEGIN#\n"..tostring(joypadMotion).."\n"..sFileContent.."\n#END#\n", a(chars.p1addr, "b"), "_frameData.txt")
				bFileWritten = true
			elseif bFileWritten == false and frameDataRead.isUoh ~= true and frameDataRead.startup ~= nil and frameDataRead.recovery ~= nil and frameDataRead.framesActive ~= nil and frameDataRead.hitAdv ~= nil and frameDataRead.blkAdv ~= nil and frameDataRead.crHitAdv ~= nil then
				wrFileWithAutoNumericSuffix("#BEGIN#\n"..tostring(joypadMotion).."\n"..sFileContent.."\n#END#\n", a(chars.p1addr, "b"), "_frameData.txt")
				bFileWritten = true
			elseif bFileWritten == false and frameDataRead.bNonActiveMove ~= false then
				wrFileWithAutoNumericSuffix("#BEGIN#\n"..tostring(joypadMotion).."\n"..sFileContent.."\n#END#\n", a(chars.p1addr, "b"), "_frameData.txt")
				bFileWritten = true
			elseif bFileWritten == false and frameDataRead.isThrow == true then
				wrFileWithAutoNumericSuffix("#BEGIN#\n"..tostring(joypadMotion).."\n"..sFileContent.."\n#END#\n", a(chars.p1addr, "b"), "_frameData.txt")
				bFileWritten = true
			end
			--]]
		end
	end
end

function addStr(val)
	resultsToDisplay = resultsToDisplay.."\r\n"..tostring(val)
end

-- verify if p1 active hitboxes exist...
function p1ActiveHitboxes()
	bReturn = false
	
	--if a(gameData.game["superfreeze"], "b") == 0 and a(gameData.p1["hitboxes_active"], "dw") ~= 0x00000001 then
	if a(gameData.game["superfreeze"], "b") == 0 and a(gameData.p1["hb_active_presence"], "b") > 0 then
		-- at least one active hitbox is displayed...
		bReturn = true
	end
	
	return bReturn
end

-- verify if p2 active hitboxes exist...
function p2ActiveHitboxes()
	local addr = gameData.p2.hb_base_address
	
	local bReturn = false
	
	-- active hitboxes
	local a_hb_addr = memory.readdword(addr + 0x2A8)
	--print(h(a_hb_addr))
	for i = 1, 4 do
		local left   = memory.readwordsigned(a_hb_addr)
		local right  = memory.readwordsigned(a_hb_addr + 2)
		local bottom = memory.readwordsigned(a_hb_addr + 4)
		local top    = memory.readwordsigned(a_hb_addr + 6)
		
		if left ~= 0 or right ~= 0 or top ~= 0 or bottom ~= 0 then
			--print(left, right, top, bottom)
			-- at least one box is defined...
			bReturn = true
			break
		end
		
		a_hb_addr = a_hb_addr + 8
	end
	
	return bReturn
end


-- reset all values...
function reset()
	inProgress = false
	bActiveObjectFound = false
	
	frameP1Attack = nil
	frameP1FirstActive = nil
	frameP1LastActive = nil
	frameP1EndActive = nil
	frameP2Hit = nil
	frameP1End = nil
	frameP2End = nil

	framesActive = 0
	framesActiveThrow = 0
	
	isNormal = false
	isSpecial = false
	isSA = false
	
	isUoh = false
	
	isParry = false
	isCrouchingParry = false
	isCrouchingGuard = false
	isStandingGuard = false
	isWhiff = false
	isCrouching = false
	isSuperArt = nil
	isThrow = false
	isWhiff = true
	isActive = false
	startActive = nil
	activePreviousValue = nil
	bNonActiveMove = false
	noHitboxesCounter = 0
	damage = {}
	stun = {}
	hits = {}
	active = {}
	listDamage = ""
	listStun = ""
end

-- verify if p1 launch an attack...
function p1Atk()
	bReturn = false
	
	if a(gameData.p1["attack"], "b") > 0 then
		bReturn = true
	end
	
	return bReturn
end

-- verify if p2 is hit...
function p2Hit()
	if a(gameData.p2["attack"], "b") > 0 then
		bReturn = true
	else
		bReturn = false
	end
	
	return bReturn
end

-- collect frame data:
-- startup, active, recovery, hit adv., blocked adv., cr. hit adv., cr. blocked adv.
-- damage, stun...
function frameDataCollect()
	checkP1()	
	checkP2()
	checkDamageAndStun()
	checkHits()
	checkEnd()
end

-- display frames data on screen...
function displayResultsOnScreen(fd)
	local x = 260
	local y = 34
	local inc = 8
	local row = 0
	local color = sColorProcessNotDone
	
	if bFileWritten == true then color = sColorProcessDone end
	
	if fd.startup ~= nil and fd.startup ~= "-" and (fd.startup > 10000 or fd.startup < -10000) then
		color = 0xff0000ff
		fd.startup = -999999
		fd.recovery = -999999
	end
	
	displayValue("startup  : "..tostring(fd.startup), 		x, y + row * inc, color)
	row = row + 1
	displayValue("active   : "..tostring(fd.framesActive), 	x, y + row * inc, color)
	row = row + 1
	displayValue("recovery : "..tostring(fd.recovery), 		x, y + row * inc, color)
	row = row + 1
	displayValue("blkAdv   : "..tostring(fd.blkAdv), 		x, y + row * inc, color)
	row = row + 1
	displayValue("hitAdv   : "..tostring(fd.hitAdv), 		x, y + row * inc, color)
	row = row + 1
	displayValue("crHitAdv : "..tostring(fd.crHitAdv), 		x, y + row * inc, color)
	row = row + 2
	
	----[[
	displayValue("damage   : "..tostring(fd.damage), 		x, y + row * inc, color)
	row = row + 1
	displayValue("stun     : "..tostring(fd.stun), 			x, y + row * inc, color)
	row = row + 1
	
	if bUnknownState ~= false then
		displayValue("UNKNOWN STATE", x, y + row * inc, 0xff0000ff)
	end
	
	row = row + 1
	
	if frameDataRead.bNonActiveMove ~= false then
		displayValue("- "..tostring(frameDataRead.bNonActiveMove).." -", 			x, y + row * inc, 0x00ff00ff)
	else
		displayValue("-  -", 		x, y + row * inc, 0xff0000ff)
	end
	row = row + 1
	
	--]]
	
	--[[--
	startup = nil,
	active = {},
	recovery = nil,
	hitstun = nil,
	hitAdv = nil,
	blkAdv = nil,
	crHitAdv = nil,
	crBlkAdv = nil,
	isBlocking = false,
	isWhiff = false,
	isCrouching = false,
	damage = nil,
	stun = nil,
	p1Total = nil,
	p2Total = nil,
	--]]
end

function framesData()
	-- avoid doing process twice...
	if bDoProcesses then
		if currentFrame - (previousFrame - 1) ~= 1 then
			-- reset process, probably a state reloading...
			reset()
		else
			frameDataCollect()
			
			-- force file creation for some cases...
			if input.get()["end"] == true and bFileWritten == false then
				wrFileWithAutoNumericSuffix("#BEGIN#\n"..tostring(joypadMotion).."\n"..sFileContent.."\n#END#\n", a(chars.p1addr, "b"), "_frameData.txt")
				bFileWritten = true
			end
			
			-- superjump...
			if a(gameData.p1["state"], "b") == 13 and isSuperJump == false then
				-- superjump start...
				iSJDuration = 1
				isSuperJump = true
			elseif a(gameData.p1["state"], "b") == 13 and isSuperJump == true then
				iSJDuration = iSJDuration + 1
			else
				isSuperJump = false
			end
		end
	end
	
	if 1 or mame then
		local offY = 60
		local sColorP1 = 0xffff00ff
		local sColorP2 = 0x00ffffff
		
		displayValue("P1 pos_x : "..a(gameData.p1.pos_x, "ws"), 4, offY -59, 0xff00ffff)
		displayValue("P1 pos_y : "..a(gameData.p1.pos_y, "ws"), 4, offY -51, 0xff00ffff)
		
		displayValue("P2 pos_x : "..a(gameData.p2.pos_x, "ws"), 220, offY -59, 0xff00ffff)
		displayValue("P2 pos_y : "..a(gameData.p2.pos_y, "ws"), 220, offY -51, 0xff00ffff)
	
		displayValue("P1 frame : "..a(gameData.p1.anim_frame, "w"), 63, offY -51, 0xff80ffff)
		displayValue("P2 frame : "..a(gameData.p2.anim_frame, "w"), 310, offY -51, 0xff80ffff)
	
		displayValue("P1 atk   : "..a(gameData.p1["attack"], "b"), 4, offY - 10, sColorP1)
		displayValue("P1 state : "..a(gameData.p1["state"], "b"), 4, offY + 0, sColorP1)
		displayValue("P1 hurt  : "..a(gameData.p1["hurt"], "b"), 4, offY + 10, sColorP1)		
		displayValue("P1 life  : "..a(gameData.p1["life"], "b"), 4, offY + 20, sColorP1)
		
		if a(gameData.p1["damageOfNextHit"], "b") > 0 then sColorDmg = 0xff0000ff else sColorDmg = sColorP1 end
		displayValue("P1 dmg   : "..a(gameData.p1["damageOfNextHit"], "b"), 4, offY + 30, sColorDmg)
		displayValue("P1 stun  : "..a(gameData.p1["stunOfNextHit"], "b"), 4, offY + 40, sColorDmg)
		
		--displayValue("P1 active HB presence : "..p1ActiveHitboxes(), 4, offY + 40, 0xffff00ff)
		
		if p1ActiveHitboxes() then sColorActHb = 0x00ff00ff else sColorActHb = 0xccccccff end
		displayValue("P1 active HB   : "..tostring(p1ActiveHitboxes()), 4, offY + 60, sColorActHb)
		
		if isActiveObject() then sColorActHb = 0x00ff00ff else sColorActHb = 0xccccccff end
		displayValue("Active objects : "..tostring(isActiveObject()), 4, offY + 70, sColorActHb)
		
		if isNoHitboxes() then sColorActHb = 0x0000ffff else sColorActHb = 0xccccccff end
		displayValue("isNoHitboxes   : "..tostring(isNoHitboxes()), 4, offY + 80, sColorActHb)
		
		if a(gameData.p1["activeThrow"], "b") ~= 0 then sColorActHb = 0x00ff00ff else sColorActHb = 0xccccccff end
		displayValue("P1 active Throw : "..a(gameData.p1["activeThrow"], "b"), 4, offY + 90, sColorActHb)
		
		
		if a(gameData.p1["state"], "b") == 13 then sColorActHb = 0xff0000ff else sColorActHb = 0xccccccff end
		displayValue("P1 SJ registered : "..iSJDuration, 4, offY + 100, sColorActHb)
		
		if a(gameData.game.superfreeze, "b") > 0 or a(gameData.game.superfreeze_2, "b") > 0 then sColorSuperFrz = 0x0066ffff else sColorSuperFrz = 0xccccccff end
		displayValue("superpfrz : "..a(gameData.game.superfreeze, "b").." / "..a(gameData.game.superfreeze_2, "b"), 167, offY - 20, sColorSuperFrz)
		displayValue("countdown : "..a(gameData.game.superfreeze_decount, "b"), 167, offY - 10, sColorSuperFrz)
		
		displayValue("P2 atk   : "..a(gameData.p2["attack"], "b"), 326, offY - 10, sColorP2)
		displayValue("P2 state : "..a(gameData.p2["state"], "b"), 326, offY + 0, sColorP2)
		displayValue("P2 hurt  : "..a(gameData.p2["hurt"], "b"), 326, offY + 10, sColorP2)		
		displayValue("P2 life  : "..a(gameData.p2["life"], "b"), 326, offY + 20, sColorP2)
		
		if p2ActiveHitboxes() then sColorActHb = 0x00ff00ff else sColorActHb = 0xccccccff end
		displayValue("P2 active HB : "..tostring(p2ActiveHitboxes()), 300, offY + 48, sColorActHb)
		
		if a(gameData.p2["activeThrow"], "b") ~= 0 then sColorActHb = 0x00ff00ff else sColorActHb = 0xccccccff end
		displayValue("P2 active Throw : "..a(gameData.p2["activeThrow"], "b"), 300, offY + 58, sColorActHb)
		
		if a(gameData.p2["damageOfNextHit"], "b") > 0 then sColorDmg = 0xff0000ff else sColorDmg = sColorP2 end
		displayValue("P2 dmg   : "..a(gameData.p2["damageOfNextHit"], "b"), 326, offY + 70, sColorDmg)
		displayValue("P2 stun  : "..a(gameData.p2["stunOfNextHit"], "b"), 326, offY + 80, sColorDmg)
		
		displayValue("hit_by_N   : "..a(gameData.p2["hit_by_N"], "b"), 326, offY + 90, 0x00ffffff)
		displayValue("hit_by_S   : "..a(gameData.p2["hit_by_S"], "b"), 326, offY + 100, 0x00ffffff)
		displayValue("hit_by_SA  : "..a(gameData.p2["hit_by_SA"], "b"), 326, offY + 110, 0x00ffffff)
		displayValue("hit_by_SAO : "..a(gameData.p2["hit_by_SA_other"], "b"), 326, offY + 120, 0x00ffffff)
		
		displayValue(emu.framecount().." / "..a(gameData.game.game_phase, "b"), 175, 0, 0x00ff00ff)
		
		if a(gameData.p1["state"], "b") == 5 then sColorActHb = 0xff0000ff else sColorActHb = 0xccccccff end
		displayValue("P1 F.MP (gouki)", 4, offY + 110, sColorActHb)
		
		--displayValue("std grd : "..tostring(isStandingGuard), 326, offY + 100, 0x00ffffff)
		--displayValue("cr grd  : "..tostring(isCrouchingGuard), 326, offY + 110, 0x00ffffff)
		
		displayValue(a(chars.p1addr, "b"), 45, 35, 0x0ffffff)
		displayValue(a(chars.p2addr, "b"), 335, 35, 0x0000ffff)
		
		--cheat(chars.p1addr, 15)
		--cheat(chars.p2addr, 20)
		
		--[[
		local sType = "ws"
		
		displayValue("check 1 : "..a(gameData.game.test1, sType), 175, 70, 0x00ff00ff)
		displayValue("check 2 : "..a(gameData.game.test2, sType), 175, 80, 0x00ff00ff)
		displayValue("check 3 : "..a(gameData.game.test3, sType), 175, 90, 0x00ff00ff)
		displayValue("check 4 : "..a(gameData.game.test4, sType), 175, 100, 0x00ff00ff)
		displayValue("check 5 : "..a(gameData.game.test5, sType), 175, 110, 0x00ff00ff)
		displayValue("check 6 : "..a(gameData.game.test6, sType), 175, 120, 0x00ff00ff)
		--]]
		
		displayResultsOnScreen(frameDataRead)
		
		--displayGameData(gameData.p1, 20, 35)
		--displayGameData(gameData.p2, 250, 35)
		--displayGameData(gameData.game, nil, 45)
	end
end
