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
local hitbox_file = "./LUA_ESN/ESN_HITBOX.lua"
local cheat_file = "./LUA_ESN/ESN_CHEAT.lua"

dofile(gameDatas_file, "r")
dofile(library_file, "r")
dofile(hitbox_file, "r")
dofile(cheat_file, "r")

SEPARATOR = ";"
iTestLoop = 0
iTestLoopLimit = 10000

function launchAcq()
	-- addrStart : start address for ACQ...
	-- iBlockLength : size of block to ACQ, added to addrStart to get endAddr...
	-- iLoop : length of each line in final file...
	local addrStart 	= 0x02000000
	local iBlockLength 	= 0x00100000
	local iLoop 		= 0x00000100
	
	local acqPrefix = getTimePrefix()
	acqPrefix = "Check"
	
	--for i = 1, (16 * 10) do
	for i = 1, (16) do
		print(acqPrefix, emu.framecount(), " : processing from", "0x"..string.format("%08X", addrStart), "to", "0x"..string.format("%08X", (addrStart +  iBlockLength)))
		dataACQ.acqFrame(addrStart, iBlockLength, iLoop, acqPrefix)
		addrStart = addrStart + iBlockLength
		
		print("--> done")
	end
	
	print("end...")
end

done = false
done1 = false
done2 = false

emu.registerbefore(function()
	if P2:life() == 155 and done1 == false then
		--launchAcq()
		done1 = true
		return
	elseif P2:life() == 149 and done2 == false then
		--launchAcq()
		done2 = true
		return
	end
	
	if done == false then
		--launchAcq()
		done = true
	end
	
	--print(emu.framecount())
	
	HITBOX.display()
	print("P1 - P2 x : ", P1:x() - P2:x(), " / ", a(0x02026CB0, "ws"))
end)

emu.registerafter(function()
	--local tmpAddr = gameData.p2.hb_active_base_address
	--print(h(a(tmpAddr, "dw")), h(a(tmpAddr)))
	--debugHB(a(tmpAddr, "dw"))
	
end)

gui.register(function()
	-- some traces...
	--view(0x0200DC50)
	
	CHEAT.force_no_zoom()
	
	--cheat(0x02015683, 17) -- change p1 color palette, from 0 to 6, more will be random other palette or black...
	--cheat(0x02068E86, 0x6789, "w")
	
	--CHEAT.blank(0x02007D20, 4)
	
	--CHEAT.update()
	
	--cheat(0x0200DCD0, CHEAT.incr, "w") -- zoom active ???
	--cheat(0x0200DCD2, CHEAT.incr, "w") -- X offset
	--cheat(0x0200DCD4, CHEAT.incr, "w") -- Y offset
	--cheat(0x040c006c, CHEAT.incr, "b")
	--cheat(0x0200DCD0, 0x00, "b")
	--cheat(0x0200DCBA, 0x01f0, "w")
	--cheat(0x0200DCC2, 0x01f0, "w")
	--cheat(0x0200DCD4, 0xff32, "w")
	--cheat(0x020695B5, 0xf0)
	
	--CHEAT.blank(0x0200DCA0, 4)
	--CHEAT.blank(0x0200DCB0, 4)
	--CHEAT.blank(0x0200DCC0, 2)
	--CHEAT.blank(0x0200DCCa, 2)
	--CHEAT.blank(0x0200DCD0, 4)
end)

--[[
rom 10 -> copied in game RAM @ 0x06000000

ADDR to ACQ:
- 0x02007F00 to 0x02007F03 : internal CPS3 counter? +1 on each frame...
- 0x02009DC5
]]--











