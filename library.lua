-- functions library
--require "gd"

local resultsToDisplay = ""

-- check if fba or mame...
emu_UP, emu_DOWN, emu_LEFT, emu_RIGHT = "Up", "Down", "Left", "Right"
emu_LP, emu_MP, emu_HP, emu_LK, emu_MK, emu_HK = ""
emu_P1, emu_P2 = "P1 ", "P2 "

if mame then
	emu_LP, emu_MP, emu_HP = "Button 1", "Button 2", "Button 3"
	emu_LK, emu_MK, emu_HK = "Button 4", "Button 5", "Button 6"
elseif fba then
	emu_LP, emu_MP, emu_HP = "Weak Punch", "Medium Punch", "Strong Punch"
	emu_LK, emu_MK, emu_HK = "Weak Kick", "Medium Kick", "Strong Kick"
else
	
end

-- !!!!!!
-- to simulate a ternary operator : condition and "first string" or "second string"

-- --------------------
-- states detections...
-- --------------------

-- determine if player 1 is at neutral...
function isP1Neutral()
	return a(gameData.p1.attack) == 0 and a(gameData.p1.state) == 0
end

function isP2Neutral()
	return a(gameData.p2.attack) == 0 and a(gameData.p2.state) == 0
end

function isP1Attack()
	return a(gameData.p1.attack) > 0
end

function isP2Attack()
	return a(gameData.p2.attack) > 0
end

function isP1Hurt()
	return a(gameData.p1.hurt) > 0
end

function isP2Hurt()
	return a(gameData.p2.hurt) > 0
end

function isP1Jump()
	return a(gameData.p1.state) == 12 or a(gameData.p1.state) == 15
end

function isP2Jump()
	return a(gameData.p2.state) == 12 or a(gameData.p2.state) == 15
end

-- ------------------------
-- end states detections...
-- ------------------------

function scr(indice, path)
	if path == nil then path = "./" end
	local gdstr = gui.gdscreenshot()

	imgName = indice..".png"
	--print("--> "..imgName)
	gd.createFromGdStr(gdstr):png(path..imgName)
end

-- display inputs with a basic text method...
function displayInputsOnScreen(player, x_start, y_start)
	local inputsTmp = getInputsTest(player)
	local color = 0xffff00ff
	local colorHeld = 0xff0000ff
	
	local l = {y_start + 0, y_start + 10, y_start + 20}
	local c = {x_start + 0, x_start + 10, x_start + 20,
				x_start + 30, x_start + 40, x_start + 50, x_start + 60, x_start + 70, x_start + 80}
	
	inputsTmp["N"] = inputsTmp["U"] == nil and inputsTmp["D"] == nil and inputsTmp["B"] == nil and inputsTmp["F"] == nil
	
	--print(inputsTmp)
	
	local positions = {
		["U"] = {["x"] = c[2], ["y"] = l[1], ["c"] = inputsTmp["U"] ~= nil and colorHeld or color},
		["B"] = {["x"] = c[1], ["y"] = l[2], ["c"] = inputsTmp["B"] ~= nil and colorHeld or color},
		["N"] = {["x"] = c[2], ["y"] = l[2], ["c"] = inputsTmp["N"] ~= false and colorHeld or color},
		["F"] = {["x"] = c[3], ["y"] = l[2], ["c"] = inputsTmp["F"] ~= nil and colorHeld or color},
		["D"] = {["x"] = c[2], ["y"] = l[3], ["c"] = inputsTmp["D"] ~= nil and colorHeld or color},

		["1"] = {["x"] = c[4], ["y"] = l[1], ["c"] = inputsTmp["LP"] ~= nil and colorHeld or color},
		["2"] = {["x"] = c[5], ["y"] = l[1], ["c"] = inputsTmp["MP"] ~= nil and colorHeld or color},
		["3"] = {["x"] = c[6], ["y"] = l[1], ["c"] = inputsTmp["HP"] ~= nil and colorHeld or color},
		["4"] = {["x"] = c[4], ["y"] = l[3], ["c"] = inputsTmp["LK"] ~= nil and colorHeld or color},
		["5"] = {["x"] = c[5], ["y"] = l[3], ["c"] = inputsTmp["MK"] ~= nil and colorHeld or color},
		["6"] = {["x"] = c[6], ["y"] = l[3], ["c"] = inputsTmp["HK"] ~= nil and colorHeld or color}
	}
	
	-- display on screen...
	for k, v in pairs(positions) do
		displayValue(k, v.x, v.y, v.c)
	end
end

function trim(s)
	if s ~= nil then
		return (s:gsub("^%s*(.-)%s*$", "%1"))
	end
end

function getInputsTest(player)
	local inputsTmp = joypad.getdown()
	local inputs = {}
	
	for k, v in pairs(inputsTmp) do
		--displayValue(k, 60, 58, 0xff00ffff)
		local playerRead = string.sub(k, 0, 2)
		
		if "P"..player == playerRead then
			local action = string.sub(k, 4)
			
			if action == "Up" 		then inputs["U"] = true end
			if action == "Down" 	then inputs["D"] = true end
			if action == "Right" 	then inputs["F"] = true end
			if action == "Left" 	then inputs["B"] = true end
			
			if action == emu_LP then inputs["LP"] = true end
			if action == emu_MP then inputs["MP"] = true end
			if action == emu_HP then inputs["HP"] = true end
			if action == emu_LK then inputs["LK"] = true end
			if action == emu_MK then inputs["MK"] = true end
			if action == emu_HK then inputs["HK"] = true end
		end
	end
	
	return inputs
end

-- read given table and return a string, beginning and ending with given separator...
function dp(tbl, s)
	local str = " ["..s.."] "
	
	for name, value in pairs(tbl) do
		str = str..value.." "
	end
	
	return str.."[/"..s.."] "
end

-- return a string: timestamp..milliseconds...
function getTimePrefix()
	return os.time().."_"..string.gsub(string.format("%015s", string.format("%f", os.clock())), ",", "_")
end

-- return current directory...
function getCwd()
	return io.popen"cd":read'*l'
end

-- check if a button/dir is hold...
function isHeld(action)
	--print(input.get())
	return input.get()[action] == true
end

-- force a sprite to be displayed...
function forceSprite(pXanimFrame)
	-- gouki start : 21500, kkz : 22600
	
	local iFrameBegin = 22400
	local ilimit = 10000
	local iLoop = 5
	
	-- only one time per frame...
	if(bDoProcesses == false) then return false end
	
	-- incr/decr iFrameBegin with buttons...
	local iStep = 10
	
	if isHeld("numpad-") then imageToForce = imageToForce - iStep end
	if isHeld("numpad+") then imageToForce = imageToForce + iStep end
	
	cheat(gameData.game.timer, 99) -- inf time
	--cheat(gameData.p1.pos_x, 511) -- force p1 x
	--cheat(gameData.p1.pos_y, -100) -- force p1 y
	--cheat(gameData.p2.pos_y, 1190) -- force p2 x
	--cheat(gameData.p2.pos_y, -1900) -- force p2 y
		
	-- force p1 sprite during x frames...
	writeAddr(pXanimFrame, (iFrameBegin + imageToForce), "w")
	
	-- take screenshot...
	--scr(string.format("%06s", tostring((iFrameBegin + imageToForce))).."_"..counter)
	
	-- to take a valid screenshot, char used in P1 must be different than the one 
	-- currently parsed, to get rid of interference animations...
	
	displayValue("Force frame img : "..(iFrameBegin + imageToForce), 150, 10, 0x00ff00ff)
	--displayValue("p1 pos : "..a(gameData.p1.pos_x, "ws").." x "..a(gameData.p1.pos_y, "ws"), 150, 20, 0xff0000ff)
	
	imageToForce = imageToForce + 1
	
	return false
	
	--[[
	counter = counter + 1
	
	if counter > iLoop then
		imageToForce = imageToForce + 1
		counter = 0
	else
		
	end
	
	if imageToForce >= ilimit then
		-- force bug to stop...
		--print(""..true)
	end
	--]]
	
	--[[
	if memory.readbyte(0x0206914B) > 0x00 then
		hitStopCount = hitStopCount + 1
	end

	if hitStopCount == 1 then
		memory.writebyte(0x02069149,0x80)
	end

	if memory.readbyte(0x0206914B) == 0x00 then 
		hitStopCount = 0
	end
	--]]
end

-- read all entry of the given list and return string formatted like "indice:hexAddr:value\nindice2:hexAddr2:value2\n etc..."
function getFullDataToString(lList)
	sReturn = ""
	
	for name, value in pairs(lList) do
		type = "b"
		
		if dataType[name] ~= nil then type = dataType[name] end
		
		iValue = a(value, type)
		sReturn = sReturn.."\n"..name..":"..iValue..":"..h(value)
	end
	
	return sReturn
end

function cheat(addr, val, type)
	if type == nil then type = "b" end
	
	writeAddr(addr, val, type)
end

-- write value to address, with format...
function writeAddr(addr, val, type)
	if type == nil then type = "w" end
	
	if type == "dw" then
		memory.writedword(addr, val)
	elseif type == "w" or type == "ws" then
		memory.writeword(addr, val)
	elseif type == "b" then
		memory.writebyte(addr, val)
	end
end

-- return a string with name : values for each row...
function testListValues(lList, bOnScreen)
	local str = ""
	
	local i = 0
	
	gui.clearuncommitted()
	
	for name, value in pairs(lList) do
		if bOnScreen then
			displayValue(h(value).." : "..sp(name, 10).." = "..a(value, "b"), 125, 80 + i * 8, 0x00ff00ff)
		else
			print(h(value).." : "..sp(name, 10).." = "..a(value, "b"))
		end
		
		i = i + 1
		
		--str = str.."\n"..name.." = "..value
	end
	
	--return str
end

-- return hold buttons/dir in string...
function getJoypadState(frameNumber)
	local held = joypad.getdown()
	local tbl = {}
	local bAtLeastOneHold = false
	
	for name in pairs(held) do
		if name == emu_P1..emu_DOWN 	then table.insert(tbl, emu_DOWN) end
		if name == emu_P1..emu_UP 		then table.insert(tbl, emu_UP) end
		if name == emu_P1..emu_LEFT 	then table.insert(tbl, emu_LEFT) end
		if name == emu_P1..emu_RIGHT 	then table.insert(tbl, emu_RIGHT) end
		
		if name == emu_P1..emu_LP 		then table.insert(tbl, "LP") end
		if name == emu_P1..emu_MP 		then table.insert(tbl, "MP") end
		if name == emu_P1..emu_HP 		then table.insert(tbl, "HP") end
		if name == emu_P1..emu_LK 		then table.insert(tbl, "LK") end
		if name == emu_P1..emu_MK		then table.insert(tbl, "MK") end
		if name == emu_P1..emu_HK 		then table.insert(tbl, "HK") end
		
		if name ~= "Region" then bAtLeastOneHold = true end -- fix fba issue...
	end
	
	local str = ""
	
	if bAtLeastOneHold == true then 
		str = "_"..frameNumber.."_"..table.concat(tbl, "-").."_"
	end
	
	return str
end

-- return true if no game isNoDirection hold, or false...
function isDirectionHold(t)
	if in_table(emu_P1..emu_DOWN, t) or in_table(emu_P1..emu_UP, t) or in_table(emu_P1..emu_RIGHT, t) or in_table(emu_P1..emu_LEFT, t) then
		return true
	end
	
	return false
end


-- add value in table, in order...
function add(tbl, val)
	if type(tbl) == "table" then
		table.insert(tbl, val)
		--print("add "..val)
	end
end

-- read current state of game...
function readState()
	for i, v in ipairs(data) do
		local val1 = a(gameData.p1[v])
		local val2 = a(gameData.p2[v])
		
		frame.current.p1[v] = val1
		frame.current.p2[v] = val2
		
		--frame.current.p1.life = a(gameData.p1.stun)
	end
end

-- display value on screen...
function displayValue(val, pos_x, pos_y, col)
	local i = 0
	local color  = 0xffffffff
	local border = 0x000000ff
	local x, y = emu.screenwidth() / 2 - 50, 50
	
	if col ~= nil then color = col end
	if pos_x ~= nil then x = pos_x end
	if pos_y ~= nil then y = pos_y end
	
	str = val
	gui.text(x, y + i * 8, str, color, border)
end

-- display game data on screen...
function displayGameData(tbl, pos_x, pos_y, col)
	local i = 0
	local color  = 0xffffffff
	local border = 0x000000ff
	local x, y = emu.screenwidth() / 2 - 50, 50
	
	if col ~= nil then color = col end
	if pos_x ~= nil then x = pos_x end
	if pos_y ~= nil then y = pos_y end
	
	if tostring(tbl) == tbl then
		-- single value to display
		str = space(name, 15).." = "..r(value, "b")
		gui.text(x, y + i * 8, str, color, border)
	else
		for name, value in orderedPairs(tbl) do
			if type(value) ~= "table" then
				str = space(name, 15).." = "..r(value, "b")
				gui.text(x, y + i * 8, str, color, border)
				i = i + 1
			end
		end
	end
end

-- display all infos about hitboxes...
function hitboxesInfos(p1, p2)
	local incr = 0
	local x, y = 4, 45
	
	local color  = 0x0000ffff
	local border = 0x000000ff
	
	for name in pairs(p1.p_hboxes) do
		local tmp = p1.p_hboxes[name]
		str = space(tmp.top, 4).." x "..space(tmp.left, 3).."  "..space(tmp.bottom, 4).." x "..space(tmp.right, 3)
		gui.text(x, y + incr * 8, str, color, border)
		incr = incr + 1
	end
	
	gui.pixel(98, 441, 0x00ffffff)
	
	local color  = 0x00ff00ff
	local border = 0x000000ff
	
	for name in pairs(p1.a_hboxes) do
		local tmp = p1.a_hboxes[name]
		str = space(tmp.top, 4).." x "..space(tmp.left, 3).."  "..space(tmp.bottom, 4).." x "..space(tmp.right, 3)
		gui.text(x, y + incr * 8, str, color, border)
		incr = incr + 1
	end
	
	local color  = 0xff0000ff
	local border = 0x000000ff
	
	for name in pairs(p1.t_hboxes) do
		local tmp = p1.t_hboxes[name]
		str = space(tmp.top, 4).." x "..space(tmp.left, 3).."  "..space(tmp.bottom, 4).." x "..space(tmp.right, 3)
		gui.text(x, y + incr * 8, str, color, border)
		incr = incr + 1
	end
end

-- create and write in a file following the rule: nameGiven.."_"..theFirstNumberAvailableStartingAt1
function wrFileWithAutoNumericSuffix(data, fileName, ext)
	local i = 1
	local limit = 200
	
	while i < limit and os.rename(fileName.."_"..string.format("%03s", i)..ext, fileName.."_"..string.format("%03s", i)..ext) ~= nil do
		i = i + 1
	end
	
	wrFile(data, fileName.."_"..string.format("%03s", i)..ext)
end

function wrFile(toWrite, filename, openType)
	if filename == nil then filename = "file.txt" end
	if openType == nil then openType = "w+" end
	
	file = io.open(filename, openType)
	file:write(toWrite)
	file:close()
end

function makeScreenshot(indice)
	local width = emu.screenwidth()
	local height = emu.screenheight()

	local img = gd.createTrueColor(width, height)

	for x = 70, width - 130 do
		for y = 70, height do
			local r, g, b = gui.getpixel(x, y)
			local color = img:colorAllocate(r, g, b)
			img:setPixel(x, y, color)
		end
	end

	img:png(indice..".png")
end

-- display address content of given table on screen...
function displayData(tbl)
	local i = 0
	local x, y = 20, 20
	local color, border = 0xff0000ff, 0x000000ff
	
	for name in pairs(tbl) do
		-- display addr value and its content...
		str = incr..h(tbl[name]).." "..name.." = "..memory.readword(tbl[name])
		
		gui.text(x, y + i * 8, str, color, border)
		--"(0x"..string.format("%08X", tmpAddrPx[name])..") "..name.." = "..memory.readbyte(tmpAddrPx[name]), color, border)
		i = i + 1
	end
end

function h(var, content)
	if content ~= nil then
		str = "0x"..string.format("%08X", var).." = "..r(var, content)
	else
		str = "0x"..string.format("%08X", var)
	end
	
	return str
end

-- read address content for display...
function r(addr, type)
	dw 	= memory.readdword(addr)
	w 	= sp(memory.readword(addr), 6)
	ws 	= sp(memory.readwordsigned(addr), 6)
	b 	= sp(memory.readbyte(addr), 4)
	
	if type == "dw" then str = h(dw).." ("..dw..")"
	elseif type == "w" then str = w
	elseif type == "ws" then str = ws
	elseif type == "b" then str = b
	else
		str = h(dw).." / "..w.." / "..ws.." / "..b
	end
	
	return str
end

-- read address content...
function a(addr, type)
	if(addr ~= nil) then
		dw 	= memory.readdword(addr)
		w 	= memory.readword(addr)
		ws 	= memory.readwordsigned(addr)
		b 	= memory.readbyte(addr)
		bs 	= memory.readbytesigned(addr)
		
		if type == "dw" then str = dw
		elseif type == "w" then str = w
		elseif type == "ws" then str = ws
		elseif type == "bs" then str = bs
		else
			str = b
		end
	else
		str = "nil"
	end
	
	return str
end

-- display on screen data from a given address
-- numpad+ will increase address, - decrease, 
local displayType = {"b", "w", "ws", "dw", "c", "r", "rd"}
local indexDisplayType = 6
local fastDisplayStep = {0x1, 0x10, 0x100, 0x1000, 0x10000}
local fastDisplay = 2
local addrToDisplay = nil
local addrDefault = 0x02026CB0

function view(addr)
	local limit = 25
	local col_limit = 3
	local x = 4
	local y = 3
	local x_offset = 100
	local color = 0xffbb00ff
	local incr = 2
	local add = 1
	local display = ""
	
	local pressed = input.get()
	
	if addr == nil then addr = addrDefault end
	if addrToDisplay == nil then addrToDisplay = addr end
	
	-- define all possible types of display...
	local action = {
		[1] = function()
			incr = 1
			add = 2 * (limit + 1)
			display = "byte"
		end,
		[2] = function()
			incr = 4
			add = 4 * (limit + 1)
			display = "word"
			x_offset = 120
			col_limit = 2
		end,
		[3] = function()
			incr = 4
			add = 4 * (limit + 1)
			display = "word signed"
			x_offset = 120
			col_limit = 2
		end,
		[4] = function()
			incr = 8
			x_offset = 190
			col_limit = 1
			add = 8 * (limit + 1)
			display = "dword"
		end,
		[5] = function()
			incr = 8
			x_offset = 190
			col_limit = 1
			add = 8 * (limit + 1)
			display = "dword / RGB"
		end,
		[6] = function()
			incr = 0x10
			x_offset = 200
			col_limit = 0
			display = "default (bytes)"
			-- default, raw view, 8 bytes in a row, 2 rows, displayed bytes...
		end,
		[7] = function()
			incr = 0x10
			x_offset = 200
			col_limit = 0
			display = "default (dec)"
			-- default, raw view, 8 bytes in a row, 2 rows, displayed decimal values...
		end,
	}
	
	-- displayType key handling...
	if(pressed["numpad/"]) then
		-- change display speed...
		indexDisplayType = indexDisplayType + 1
		if indexDisplayType > 7 then indexDisplayType = 1 end
	end
	
	-- execute display type actions...
	action[indexDisplayType]()
	
	--print("@indexDisplayType : "..indexDisplayType)
	
	-- address incr/decr keys handling...
	if pressed["numpad-"] == true then
		addrToDisplay = addrToDisplay - fastDisplayStep[fastDisplay]
	elseif pressed["numpad+"] == true then
		addrToDisplay = addrToDisplay + fastDisplayStep[fastDisplay]
	end
	
	--print("@addrToDisplay : "..h(addrToDisplay))
	
	-- fastDisplay key handling...
	if(pressed["numpad*"]) then
		-- change display speed...
		fastDisplay = fastDisplay + 1
		if fastDisplay > 5 then fastDisplay = 1 end
	end
	
	--print("@fastDisplay : "..fastDisplay)
	
	local addrTmp = addrToDisplay
	
	for c = 0, col_limit do
		for i = 0, limit do
			finalColor = color
			
			if displayType[indexDisplayType] == "c" then
				rgb_r = a(addrTmp + 4, "b")
				rgb_g = a(addrTmp + 2, "b")
				rgb_b = a(addrTmp + 0, "b")
				
				rgbcolor = {};
				rgbcolor["r"] = rgb_r;
				rgbcolor["g"] = rgb_g;
				rgbcolor["b"] = rgb_b;

				hexcolor = rgbToHex(rgbcolor);
				
				if hexcolor == nil then hexcolor = 0x0 end
				
				rgbColor = tonumber(hexcolor, 10);
				
				str = h(addrTmp).." "..string.format("%08X", hexcolor)
				displayValue(str, x + c * x_offset, y + i * 8, rgbColor)
			else
				if displayType[indexDisplayType] == "r" or displayType[indexDisplayType] == "rd" then
					-- raw display of 8 bytes by row on two columns...
					str = h(addrTmp).." :"
					
					finalColor = 0xff4422ff
					
					for k = 0, 15 do
						local valTmp = memory.readbyte(addrTmp + k)
						if(valTmp > 0) then finalColor = 0xffbb00ff end
						
						if(displayType[indexDisplayType] == "rd") then
							str = str.."  "..string.format("%03d", valTmp)
						else
							str = str.."   "..string.format("%02X", valTmp)
						end
					end
				elseif displayType[indexDisplayType] == "b" then
					str = h(addrTmp).." : "..string.format("%02X", r(addrTmp, displayType[indexDisplayType])).." "..r(addrTmp, displayType[indexDisplayType])
				elseif displayType[indexDisplayType] == "dw" then
					val = string.format("%08X", a(addrTmp, displayType[indexDisplayType]))
					
					if string.sub(val, 0, 3) == "020" or string.sub(val, 0, 3) == "060" then finalColor = 0x00ff00ff end
					
					str = h(addrTmp).." : "..val.." : "..string.sub(val, 0, 3)
				else
					str = h(addrTmp).." : "..r(addrTmp, displayType[indexDisplayType])
				end
				
				displayValue(str, x + c * x_offset, y + i * 8, finalColor)
				--break
			end
			
			addrTmp = addrTmp + incr
		end
	end
	
	-- footer...
	str = "start @: "..sp(h(addrToDisplay), 12)
	str = str.." type displayed : "..sp(display, 12)
	str = str.." fastDisplay : "..fastDisplay.." (0x"..decToHex(fastDisplayStep[fastDisplay]).." step)"
	displayValue(str, 3, 215, 0x5599ffff)
end

-- Function decToHex (renamed, updated): http://lua-users.org/lists/lua-l/2004-09/msg00054.html
function decToHex(IN)
        local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
        while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),math.fmod(IN,B)+1
        OUT=string.sub(K,D,D)..OUT
        end
        return OUT
end

-- Function rgbToHex: http://gameon365.net/index.php
function rgbToHex(c)
        local output = "0x"..decToHex(c["r"]) .. decToHex(c["g"]) .. decToHex(c["b"]) .. decToHex(255);
        return output
end

-- read all addresses and search one of the three value
-- if found, look for others before or after...
function searchColor(addr, v1, v2, v3)
	if addr == nil then addr = 0x00000000 end
	
	print("begin : "..h(addr))
	
	local limit = 0x009FFFFFF
	local found = false
	local j = 0
	
	for i = 0, limit do
		val1 = a(addr		, "b")
		
		if val1 == v1 then
			--print(string.format("%02X", v1).." found !!!")
			
			val2 = a(addr + 2	, "b")
			val0 = a(addr - 2	, "b")
			
			if val2 == v2 then
				print(h(addr).." "..string.format("%02X", v1).." "..string.format("%02X", v2).." found")
				
				val3 = a(addr + 4	, "b")
				
				if val3 == v3 then
					print(h(addr).." --> "..string.format("%02X", v1).." "..string.format("%02X", v2).." "..string.format("%02X", v3).." found")
					
					if a(addr + 6	, "b") == 0x0 then
						print("yaiiiiiiiiisssssssssseeeeeeeeeeeeeee")
					end
					
					found = true
				end
			elseif val0 == v2 then
				print(h(addr).." "..string.format("%02X", val0).." "..string.format("%02X", v1).." found (inverse order)")
				
				val3 = a(addr - 4	, "b")
				
				if val3 == v3 then
					print(h(addr).." ===> "..string.format("%02X", v3).." "..string.format("%02X", v2).." "..string.format("%02X", v1).." found (inverse order)")
					found = true
				end
			end
			
			--[[
			
			if val2 == v2 then
				print(string.format("%02X", v1).." "..string.format("%02X", v2).." found")
				
				val3 = a(addr + 4	, "b")
				
				if val3 == v3 then
					print(addr.." --> "..string.format("%02X", v1).." "..string.format("%02X", v2).." "..string.format("%02X", v3).." found")
					found = true
				end
			end
			
			--]]
		end
		
		addr = addr + 2
		j = i
	end
	print("end : "..h(addr))
	print()
	print(string.format("%09X", j).." ("..j..")")
	print()
	
	if found == false then
		print("NOT FOUND !!!")
	end
end

function sp(var, nb)
	if nb == nil then nb = 3 end
	formatage = "%- "..nb.."s"
	
	return string.format(formatage, var)
end

function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
        return key, t[key]
    end
    -- fetch the next value
    key = nil
    for i = 1,table.getn(t.__orderedIndex) do
        if t.__orderedIndex[i] == state then
            key = t.__orderedIndex[i+1]
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

function toggle(bValue)
	if bValue == true then bValue = false
	elseif bValue == false then bValue = true end
	
	return bValue
end

function in_table(e, t)
	for k, v in pairs(t) do
		if k == e then
			return true
		end
	end
	
	return false
end
