-- display inputs on screen...

-- display only from a given frame...
local iFrameBegin = 79872
local bDisplayBegin = function() return (emu.framecount() > iFrameBegin) or a(gameData.game.game_phase, "b") == 2 or false end

local imagesFolder = "./lua/_esnDisplayInput/Images/"

prevFrame = 0

icon = {
	u = gd.createFromPng(imagesFolder.."icon_u.png"),
	d = gd.createFromPng(imagesFolder.."icon_d.png"),
	f = gd.createFromPng(imagesFolder.."icon_f.png"),
	b = gd.createFromPng(imagesFolder.."icon_b.png"),
	
	db = gd.createFromPng(imagesFolder.."icon_db.png"),
	df = gd.createFromPng(imagesFolder.."icon_df.png"),
	ub = gd.createFromPng(imagesFolder.."icon_ub.png"),
	uf = gd.createFromPng(imagesFolder.."icon_uf.png"),
	
	n = gd.createFromPng(imagesFolder.."icon_n.png"),
	c = gd.createFromPng(imagesFolder.."icon_c.png")
}

boxes = {
	x1 = 72,
	y1 = 33,
	width = 63,
	height = 22,
	width2 = 26,
	height2 = 22,
	space = 176,
	offset = 3,
	
	buttons_offset_x = 18,
	buttons_offset_y = -4,
	buttons_between_x = 12,
	buttons_between_y = 8,
	
	color = 0x000000ff,
	border = 0xcacaffff,
	border2 = 0x555555ff,
}

stick = {
	-- neutral position
	x = boxes.x1 + 10, y = boxes.y1 + 8,
	
	-- directions
	o_ux = 0, o_uy = -5,
	o_dx = 0, o_dy = 3,
	o_bx = -7, o_by = 0,
	o_fx = 3, o_fy = 0,
	
	-- diagonals
	o_ubx = -4, o_uby = -4,
	o_ufx = 3, o_ufy = -4,
	o_dbx = -4, o_dby = 3,
	o_dfx = 3, o_dfy = 3,
}

display = {
	n = {x = stick.x, y = stick.y, img = icon.n:gdStr()},
	c = {x = stick.x, y = stick.y, img = icon.c:gdStr()},
	
	u = {x = stick.x + stick.o_ux, y = stick.y + stick.o_uy, img = icon.u:gdStr()},
	d = {x = stick.x + stick.o_dx, y = stick.y + stick.o_dy, img = icon.d:gdStr()},
	b = {x = stick.x + stick.o_bx, y = stick.y + stick.o_by, img = icon.b:gdStr()},
	f = {x = stick.x + stick.o_fx, y = stick.y + stick.o_fy, img = icon.f:gdStr()},
	
	ub = {x = stick.x + stick.o_ubx, y = stick.y + stick.o_ufy, img = icon.ub:gdStr()},
	uf = {x = stick.x + stick.o_ufx, y = stick.y + stick.o_ufy, img = icon.uf:gdStr()},
	db = {x = stick.x + stick.o_dbx, y = stick.y + stick.o_dby, img = icon.db:gdStr()},
	df = {x = stick.x + stick.o_dfx, y = stick.y + stick.o_dfy, img = icon.df:gdStr()},
	
	lp = {x = stick.x + boxes.buttons_offset_x, y = stick.y + boxes.buttons_offset_y, text = "LP"},
	mp = {x = stick.x + boxes.buttons_offset_x + boxes.buttons_between_x * 1, y = stick.y + boxes.buttons_offset_y, text = "MP"},
	hp = {x = stick.x + boxes.buttons_offset_x + boxes.buttons_between_x * 2, y = stick.y + boxes.buttons_offset_y, text = "HP"},
	lk = {x = stick.x + boxes.buttons_offset_x, y = stick.y + boxes.buttons_offset_y + boxes.buttons_between_y, text = "LK"},
	mk = {x = stick.x + boxes.buttons_offset_x + boxes.buttons_between_x * 1, y = stick.y + boxes.buttons_offset_y + boxes.buttons_between_y, text = "MK"},
	hk = {x = stick.x + boxes.buttons_offset_x + boxes.buttons_between_x * 2, y = stick.y + boxes.buttons_offset_y + boxes.buttons_between_y, text = "HK"},
}

local function getInputsTest(player)
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

local function displayStick(toDisplay, player)
	local x = display[toDisplay].x
	local y = display[toDisplay].y
	
	if player == 2 then
		x = x + boxes.space
	end
	
	gui.gdoverlay(x, y, display[toDisplay].img)
end

local function displayButton(input, button, player)
	local colorDefault 	= 0x33a333ff
	local borderDefault = 0x111111ff
	local colorHold 	= 0x111111ff
	local borderHold 	= 0x00ff00ff
	
	local color 		= colorDefault
	local border 		= borderDefault
	local text = ""
	
	local x = button.x
	local y = button.y
	
	if input == true then
		color = colorHold
		border = borderHold
	end
	
	if player == 2 then
		x = x + boxes.space
	end
	
	gui.text(x, y, button.text, color, border)
end

-- draw boxes, stick and buttons...
local function drawInputs(inputs, player)
	-- draw box...
	local x1, x2, y1, y2 = 0
	
	if player == 1 then
		x1 = boxes.x1
		y1 = boxes.y1
		x2 = boxes.x1 + boxes.width
		y2 = boxes.y1 + boxes.height
	else
		x1 = boxes.x1 + boxes.space
		y1 = boxes.y1
		x2 = boxes.x1 + boxes.width + boxes.space
		y2 = boxes.y1 + boxes.height
	end
	
	gui.box(x1, y1, x2, y2, boxes.color, boxes.border)
	gui.box(x1 + boxes.offset, y1 + boxes.offset, x1 + boxes.width2 - boxes.offset, y1 + boxes.height2 - boxes.offset, boxes.color, boxes.border2)
	
	if inputs["U"] ~= true and inputs["D"] ~= true and inputs["F"] ~= true and inputs["B"] ~= true then
		displayStick("n", player)
	else
		if inputs["U"] == true then
			if inputs["F"] == true then
				displayStick("uf", player)
			elseif inputs["B"] == true then
				displayStick("ub", player)
			else
				displayStick("u", player)
			end
		end
		
		if inputs["D"] == true then
			if inputs["F"] == true then
				displayStick("df", player)
			elseif inputs["B"] == true then
				displayStick("db", player)
			else
				displayStick("d", player)
			end
		end
		
		if inputs["F"] == true and inputs["D"] ~= true and inputs["U"] ~= true then displayStick("f", player) end
		if inputs["B"] == true and inputs["D"] ~= true and inputs["U"] ~= true then displayStick("b", player) end
		
		displayStick("c", player)
	end
	
	displayButton(inputs["LP"], display.lp, player)
	displayButton(inputs["MP"], display.mp, player)
	displayButton(inputs["HP"], display.hp, player)
	displayButton(inputs["LK"], display.lk, player)
	displayButton(inputs["MK"], display.mk, player)
	displayButton(inputs["HK"], display.hk, player)
	
	-- denjin view from 3fv script...
	offsetX = 30
	offsetY = 50
	
	frame = emu.framecount()
	
	if memory.readbyte(0x020154D3) == 2 then
		if memory.readbyte(0x02069520) ~= 0 then
			-- denjin start detection...
			iChargeFrames = 0
			bDenjinStarted = true
		else
			if bDenjinStarted == true then
				if memory.readbyte(0x02068D2D) == 19 and memory.readbyte(0x02068D27) == 0 then
					-- denjin charge reached...
				else
					if frame ~= prevFrame then
						iChargeFrames = iChargeFrames + 1
					end
				end
				
				sDenjin = "CHARGE COUNT : "..string.format("%03s", iChargeFrames)
				gui.text(80, 77, sDenjin, 0x80FFFFFF, 0x000000FF)
			end
		end
		
		offsetX = offsetX + 3
		offsetY = offsetY + 16
		
		gui.drawbox(offsetX,offsetY,offsetX+16,offsetY+6,0x00000000,0x000000FF)
		gui.drawbox(offsetX,offsetY,offsetX+48,offsetY+6,0x00000000,0x000000FF)
		gui.drawbox(offsetX,offsetY,offsetX+96,offsetY+6,0x00000000,0x000000FF)
		gui.drawbox(offsetX,offsetY,offsetX+160,offsetY+6,0x00000000,0x000000FF)
		
		--“dn‚ÌƒŒƒxƒ‹‚É‰ž‚¶‚Ä’l‚ª•Ï‚í‚é•Ï”
		--							«
		denjin = memory.readbyte(0x02068D2D)
		
		if denjin == 3 then
			gui.drawbox(offsetX,offsetY,offsetX+(memory.readbyte(0x02068D27)*2),offsetY+6,0x0080FFFF,0x000000FF)
		elseif denjin == 9 then
			gui.drawbox(offsetX,offsetY,offsetX+(memory.readbyte(0x02068D27)*2),offsetY+6,0x00FFFFFF,0x000000FF)
		elseif denjin == 14 then
			gui.drawbox(offsetX,offsetY,offsetX+(memory.readbyte(0x02068D27)*2),offsetY+6,0x80FFFFFF,0x000000FF)
		elseif denjin == 19 then
			gui.drawbox(offsetX,offsetY,offsetX+(memory.readbyte(0x02068D27)*2),offsetY+6,0xFFFFFFFF,0x000000FF)
		end
		
		if memory.readbyte(0x02068D27) ~= 0 then
			--memory.writebyte(0x02068D27,memory.readbyte(0x02068D27)+1)
		end
	end
		
	displayValue(frame, 70, 5, 0xffff00ff)
	
	--[[
	displayValue("P1 denjin  : "..a(gameData.p1.denjin, "b"), 170, 40, 0x0ffffff)
	displayValue("P1 denjin2 : "..a(gameData.p1.denjin2, "b"), 170, 50, 0x0ffffff)
	displayValue("SF         : "..memory.readbyte(0x02069520), 170, 60, 0x0ffffff)
	displayValue("P1 stun status : "..a(gameData.p1.stunStatus, "b"), 170, 70, 0x0ffffff)
	--]]
	
	displayValue(a(gameData.p1.attack, "b").." : atk : "..a(gameData.p2.attack, "b"), 170, 40, 0x0ffffff)
	displayValue(a(gameData.p1.state, "b").." : state : "..a(gameData.p2.state, "b"), 170, 50, 0x0ffffff)
	displayValue(a(gameData.p1.combo, "b").." : combo : "..a(gameData.p2.combo, "b"), 170, 60, 0x0ffffff)
	displayValue(a(gameData.p1.pos_x, "w").." : pos_x : "..a(gameData.p2.pos_x, "w"), 170, 70, 0x0ffffff)
	displayValue(a(gameData.p1.pos_y, "w").." : pos_y : "..a(gameData.p2.pos_y, "w"), 170, 80, 0x0ffffff)
	displayValue(a(gameData.game.superfreeze, "b").." : superfreeze 1/2 : "..a(gameData.game.superfreeze_2, "b"), 160, 90, 0xffff00ff)
	displayValue(a(gameData.game._3fv_hitStop, "b").." : hitStop : "..a(gameData.game._3fv_hitStop2, "b"), 170, 100, 0x0ffffff)
	displayValue(a(gameData.game._3fv_zeroHitStop, "b").." : zeroHitStop : "..a(gameData.game._3fv_zeroHitStop2, "b"), 170, 110, 0x0ffffff)
	displayValue(a(gameData.p1._3fv_p1_stop, "b").." : 3fv_stop : "..a(gameData.p2._3fv_p2_stop, "b"), 170, 120, 0x0ffffff)
	displayValue(a(gameData.p1.mameCheatUniversalCancel, "b").." : cancel : "..a(gameData.p2.mameCheatUniversalCancel, "b"), 170, 130, 0x0ffffff)
	
	prevFrame = frame
	
	-- dumb Remy/Yun stage will make screen_center_y wrong...
	displayValue("screen_center_y : "..a(gameData.game.screen_center_y, "w"), 160, 0, 0xff0000ff)
end

function DisplayInput()
	if bDoProcesses then
		local bDisplay = bDisplayBegin()
		--print(emu.framecount().." : "..tostring(bDisplay))
		
		if bDisplay == true then
			--print("--> "..emu.framecount().." : "..tostring(bDisplay))
			drawInputs(getInputsTest(1), 1)
			drawInputs(getInputsTest(2), 2)
		end
	end
	
	--displayValue(emu.framecount().." / "..a(gameData.game.game_phase, "b"), 175, 0, 0x00ff00ff)
end
