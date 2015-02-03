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

SEPARATOR = ";"
iTestLoop = 0
iTestLoopLimit = 10000

emu.registerbefore(function()
	-- addrStart : start address for ACQ...
	-- iBlockLength : size of block to ACQ, added to addrStart to get endAddr...
	-- iLoop : length of each line in final file...
	local addrStart 	= 0x06000000
	local iBlockLength 	= 0x00001000
	local iLoop 		= 0x00100
	
	for i = 0, 1 do
		dataACQ.acqFrame(addrStart, iBlockLength, iLoop)
		addrStart = addrStart + iBlockLength
	end
	
	print("done...")
end)

emu.registerafter(function()
	
end)

gui.register(function()
	-- some traces...
	--helpTraces()
end)
