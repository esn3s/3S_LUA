-- hit confirm training...

iTotal, iBlock, iNoBlock = 0, 0, 0
local iEmuFramePrev, iEmuFrameCurrent, iEmuLimit = 0, 0, 0
bActionStarted = false
bBlock = false

function randomGuard()
	iEmuFrameCurrent = emu.framecount()
	
	if(iEmuFrameCurrent < iEmuFramePrev) then
		-- state reload probably happened, reset all parameters...
		resetTraining()
	end
	
	-- detect P1 action...
	if(bActionStarted == false and p1Atk()) then
		bActionStarted = true
	elseif(bActionStarted == true) then -- and p2Hit()
		-- block it or not...
		if(randomGen() == true) then
			-- block it!
			bBlock = true
			bActionStarted = false
		end
	end
	
	if(bBlock) then p2Block() end
	
	--2000000
	--print(iEmuFrameCurrent.." : "..a(gameData.p1.damageOfNextHit, "b").." / "..a(gameData.p1.attack, "b").." / "..a(gameData.p2.attack, "b").." / "..a(gameData.p2.hurt, "b"))
	
	--displayData(gameData.game)
	
	iEmuFramePrev = iEmuFrameCurrent
end

function p2Block()
	tbl = {}
	tbl["P2 Right"] = 1
	-- make it crouching block randomly...
	--if(randomGen()) then tbl["P2 Down"] = 1 end
	tbl["P2 Down"] = 1
	
	joypad.set(tbl)
	print("p2 block!")
	
	if(iEmuLimit > 20) then
		resetTraining()
	else
		iEmuLimit = iEmuLimit + 1
	end
end

function randomGen()
	math.randomseed(math.random() * 10000)
	local c = math.random()
	math.random()
	math.random()
	local b = (c > 0.5)
	print(emu.framecount().." : "..os.time().." "..c)
	return b
	
	--[[
	iTotal = iTotal + 1
	local i = math.random()
	local b = (i > 0.5)
	
	if(b) then
		iBlock = iBlock + 1
	else
		iNoBlock = iNoBlock + 1
	end
	
	local ratio = (iBlock / iNoBlock)
	local txt = iTotal.." ("..tostring(b)..") : "..string.sub(ratio, 0, 4)
	print(txt)
	gui.text(30, 2, txt, 0xffff00ff, 0x000000ff)
	]]--
end

function resetTraining()
	bActionStarted = false
	bBlock = false
	iEmuLimit = 0
	
	print("...RESETTED...")
end

-- verify if p1 launch an attack...
function p1Atk()
	return a(gameData.p1["attack"], "b") > 0
end

-- verify if p2 is hit...
function p2Hit()
	return a(gameData.p2["attack"], "b") > 0
end