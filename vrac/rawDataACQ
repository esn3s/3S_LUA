-- launch needed modules...
local library_file = "./lua/library.lua"
local gameDatas_file = "./lua/3sGameData.lua"

dofile(library_file, "r")
dofile(gameDatas_file, "r")

local SEPARATOR = ";"
local PATH_ACQ = "./_ACQ/"

-- transform memory chunk read as a table into a string with a separator between each value...
-- bCompress parameter allow to compress using basic scheme of repeated value through a single line...
-- 0,0,0,0,1,2,2,2,2,2,2,2,20, --> 0x4,1,2x7,20,
local function memoryTableToString(tbl, bCompress, sep)
	if(sep == nil) then sep = SEPARATOR end
	
	local str = ""
	local compressedTblTmp = {}
	local compressedTbl = {}
	
	--tbl = {0,0,0,0,1,2,2,2,2,2,2,2,20}
	
	if(bCompress == true) then
		-- compress string values...
		--str = "COMPRESSED DATA\n"
		
		local previousData = "first loop"
		local currentData
		local iNbValues = #tbl
		local iCount = 0
		local bWrite = false
		local bDebug = true
		
		-- store first tbl value...
		table.insert(compressedTblTmp, {["occ"] = 1, ["index"] = tbl[1]})
		local iSize = #compressedTblTmp
		
		-- browse tbl and compare with previous value...
		for i = 2, iNbValues do
			if(tbl[i] == compressedTblTmp[iSize].index) then
				-- same value, increment occurence...
				compressedTblTmp[iSize].occ = compressedTblTmp[iSize].occ + 1
				--print("--> same value, incr occ : "..compressedTblTmp[iSize].occ)
			else
				-- new value, add in compressedTblTmp...
				--print("--> new value, add new table...")
				table.insert(compressedTblTmp, {["occ"] = 1, ["index"] = tbl[i]})
				iSize = #compressedTblTmp
			end
		end
		
		-- build final table...
		for key, tmpTbl in pairs(compressedTblTmp) do
			local s = (tmpTbl.occ == 1 and tostring(tmpTbl.index) or tostring(tmpTbl.index).."x"..tostring(tmpTbl.occ))
			table.insert(compressedTbl, s)
		end
		
		--print()
		--print(tbl)
		--print(compressedTbl)
		tbl = compressedTbl
	end
	
	-- raw string values...
	--str = "RAW DATA\n"
	
	for key, value in pairs(tbl) do
		str = str..value..sep
	end
	
	--print()
	--print(tbl)
	--print(str)
	
	return str.."\n"
end

--[[
local tbl = {1,1,2,3,4,3,3,5,3,3,0,0,0}

print(memoryTableToString(tbl, false))
print(memoryTableToString(tbl, true))
]]--

local iTestLoop = 0
local iTestLoopLimit = 10000
local bEnabled = true
local bWriteFd = false

-- for now, empty file first...
--if bEnabled == true then wrFile("", nil, "w") end

local function acqFrame()
	--print(os.clock())
	
	if bEnabled == true then
		local prefix = getTimePrefix().."_"..emu.framecount().."_"..string.format("%05s", iTestLoop)
		local fdFileName = PATH_ACQ..prefix..".fd"
		local imgFileName = PATH_ACQ..prefix
		
		local _time0 = os.clock()
		
		if(bWriteFd) then
			-- read memory by range...
			local addrStart
			--addrStart = g.p1.start
			--     			view(0x040C0000)
			addrStart = 		 0x02000000
			local iBlockLength = 0x0000c000 -- 0x0000c000 is the limit with fba@home to still have valid image...
			local iAddrStart = bit.band(addrStart, 0xfffffff0)
			local iAddrEnd = bit.band((iAddrStart + iBlockLength), 0xfffffff0)
			local str = "{\n"..emu.framecount()..";"..h(iAddrStart).."\n"
			
			print(emu.framecount().." / Reading memory : "..h(iAddrStart).." -> "..h(iAddrEnd))
			
			local iLoop = 0x1000
			
			for iAddr = iAddrStart, iAddrEnd, iLoop do
				local tblReadMemory = memory.readbyterange(iAddr, iLoop)
				
				str = str..h(iAddr)..";"..memoryTableToString(tblReadMemory, true)
			end
			
			str = str..emu.framecount()..";"..h(iAddrEnd).."\n}\n"
			
			wrFile(str, fdFileName, "w+")
		end
		
		local _time1 = os.clock()

		--print("Total time : "..(_time1 - _time0))
	end
	
	iTestLoop = iTestLoop + 1
	
	if(iTestLoop >= iTestLoopLimit) then bEnabled = false end
end

local bWriteImg = function() return emu.framecount() >= 120690 and emu.framecount() <= (120670 + 2324) end

-- screenshots MUST be taken on registerafter in order to avoid emulator messages...
local function takeScreenshot()
	print(emu.framecount().." : "..tostring(bWriteImg()).." "..iTestLoop)
	
	if(bWriteImg()) then
		local prefix = getTimePrefix().."_"..emu.framecount().."_"..string.format("%05s", iTestLoop)
		local imgFileName = PATH_ACQ..prefix
		
		--imgFileName = PATH_ACQ.."3S_introduction".."_"..string.format("%05s", iTestLoop)
		
		scr(imgFileName)
		
		-- write file, tests...
		local sP1Log = a(gameData.p1.attack, "b").." / "..a(gameData.p2.bar, "b")
		local sP2Log = a(gameData.p2.life, "b").." / "..a(gameData.p2.attack, "b").." / "..a(gameData.p2.state, "b").." / "..a(gameData.p2.bar, "b")
		local str = emu.framecount().."\n"..sP1Log.."\n"..sP2Log
		
		wrFile(str, imgFileName..".fd", "w+")
		
		iTestLoop = iTestLoop + 1
	end
end

local function viewData()
	view(0x00000000)
	--todo : use sfiii4 to compare memory and find out where are 10 rom data...
	--print(emu.framecount())
end

-- display memory on screen to check if there's any useful data...
local tblPrev = {}
local addrStart 	= 0x00000000
local blockLength 	= 0x00010000
local defaultColor	= 0x9999ffff
local changesColor	= 0xff9999ff
local countIncr		= 0

local function checkIncrAddr()
	if(isHeld("numpad+")) then
		countIncr = countIncr + 1
		
		if(countIncr > 30) then
			countIncr = 0
			addrStart = addrStart + blockLength
			tblPrev = {}
			print("Incr addr...")
		end
	end
end

local function checkChangingData()
	checkIncrAddr()
	
	local tblReadMemory = memory.readbyterange(addrStart, blockLength)
	local color = defaultColor
	local str = ""
	
	-- check if data have changed...
	local strPrev = memoryTableToString(tblPrev, true)
	local strCurr = memoryTableToString(tblReadMemory, true)
	
	if(#tblPrev == 0) then
		str = "no prev data yet..."
	elseif(strPrev == strCurr) then
		str = h(addrStart).." to "..h((addrStart + blockLength)).." : no changes..."
		
		str = str.."\n\n"..strPrev.."\n"..strCurr
	else
		str = h(addrStart).." to "..h((addrStart + blockLength)).." : CHANGES !!!..."
		color = changesColor
		
		print(str)
		print("prev : "..strPrev)
		print("curr : "..strCurr)
		print()
		
		str = str.."\n\n"..strPrev.."\n"..strCurr
	end
	
	tblPrev = tblReadMemory
	
	displayValue(str, 5, 50, color)
end

emu.registerbefore(viewData)
--emu.registerbefore(checkChangingData)
--emu.registerafter(takeScreenshot)

gui.register(function()
	--displayValue("frame : "..emu.framecount(), 220, 5, 0x00ff00ff)
	--print(os.clock())
end)
