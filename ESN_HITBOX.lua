--modified april 27, 2011 to add previously omitted vulnerable hitbox

-- load library if needed...
local loadLib = true

if loadLib then
	local gameDatas_file = "../3sGameData.lua"
	local library_file = "../library.lua"

	dofile(gameDatas_file, "r")
	dofile(library_file, "r")
end

local SCREEN_WIDTH          = 384
local SCREEN_HEIGHT         = 224
local GROUND_OFFSET         = 40
local MAX_GAME_OBJECTS      = 30
local AXIS_COLOUR           = 0xFFFFFFFF
local AXIS_SIZE             = 5
local HITBOX_PASSIVE        = 0
local HITBOX_ACTIVE         = 1
local HITBOX_TEST           = 2

local HITBOX_THROW          = 3
local HITBOX_THROWABLE      = 4
local HITBOX_PUSH           = 5

local HITBOX_PASSIVE_COLOUR 	= 0x0000FF00
local HITBOX_ACTIVE_COLOUR  	= 0xFF000000
local HITBOX_TEST_COLOUR    	= 0x0099FF00
local HITBOX_THROW_COLOUR 		= 0xFF009900
local HITBOX_THROWABLE_COLOUR  	= 0x00FF0000
local HITBOX_PUSH_COLOUR    	= 0xFF990000

local GAME_PHASE_PLAYING = 2

local displayHb_P1 = true
local displayHb_P2 = true
local displayHb_Objects = true

local HB_display = {
	P1 = {
		P = true,
		V = true,
		A = true,
		T = false,
		TA = false,
		PU = false
	},
	P2 = {
		P = true,
		V = true,
		A = true,
		T = true,
		TA = true,
		PU = true
	},
	OBJ = {
		P = true,
		V = true,
		A = true,
		T = true,
		TA = true,
		PU = true
	}
}

local address = {
	player1         = 0x02068C6C,
	player2         = 0x02069104,
	screen_center_x = 0x02026CB0,
	game_phase      = 0x020154A6
}
local globals = {
	game_phase      = 0,
	screen_center_x = 0,
	num_misc_objs   = 0
}

player1 = {}
player2 = {}
misc_objs = {}
globalHitboxesStorage = ""
frameDataRecoltDone = false

motionInProgress = ""

hb_currentFrame = 0
hb_previousFrame = 0
hb_p1Atk_counter = 0

-- 3fv shenanigans for fba...
if fba and false then
	print("Processing 3fv shenanigans for fba...")
	
	index = 1
	activeHitBoxData = {}
	
	--local f = io.open("./lua/_esnHitboxes/hitBoxData.txt", "r")
	local f = io.input("./hitBoxData.txt")
	
	for line in f:lines() do
		activeHitBoxData[index] = line
		index = index + 1
	end
	f:close()
end

function update_globals()
	globals.screen_center_x = memory.readword(address.screen_center_x)
	globals.game_phase      = memory.readword(address.game_phase)
end

function hitbox_load(obj, i, typeHb, facing_dir, offset_x, offset_y, addr, type, base)
	local left   = memory.readwordsigned(addr)
	local right  = memory.readwordsigned(addr + 2)
	local bottom = memory.readwordsigned(addr + 4)
	local top    = memory.readwordsigned(addr + 6)
	
	--local checkPresence = math.abs(left) + math.abs(right) + math.abs(bottom) + math.abs(top)
	local checkPresence = true
	
	if type == "P1" and typeHb == HITBOX_ACTIVE and checkPresence then
		print(type, typeHb, h(base), h(addr), i, left, right, bottom, top)
		--left = left - 20
	end
	
	if false and fba and typeHb == HITBOX_ACTIVE then
		-- 3fv shenanigans to get actual active hitboxes with fba-rr...
		left = activeHitBoxData[addr + 0x14C - 0x643FFFF]
		left = left * 0x100 + activeHitBoxData[addr + 1 + 0x14C - 0x643FFFF]
		left = num2signed(left, 2)
		
		right = activeHitBoxData[addr + 2 + 0x14C - 0x643FFFF]
		right = right * 0x100 + activeHitBoxData[addr + 2 + 0x14C + 1 - 0x643FFFF]
		right = num2signed(right, 2)
		
		bottom = activeHitBoxData[addr + 4 + 0x14C - 0x643FFFF]
		bottom = bottom * 0x100 + activeHitBoxData[addr + 4 + 0x14C + 1 - 0x643FFFF]
		bottom = num2signed(bottom, 2)
		
		top = activeHitBoxData[addr + 6 + 0x14C - 0x643FFFF]
		top = top * 0x100 + activeHitBoxData[addr + 6 + 0x14C + 1 - 0x643FFFF]
		top = num2signed(top, 2)
		
		--if type == "P1" then print("("..emu.framecount()..") 3fv method    : object "..i.." , coord read at "..h(addr).." --> "..left.." "..right.." "..top.." "..bottom) end
		--if type == "P2" then print("("..emu.framecount()..") 3fv method    : object "..i.." , coord read at "..h(addr).." --> "..left.." "..right.." "..top.." "..bottom) end
		--if type == "OBJECTS" then print("("..emu.framecount()..") 3fv method    : object "..i.." , coord read at "..h(addr).." --> "..left.." "..right.." "..top.." "..bottom) end
	end
	
	local l_orig = left
	local r_orig = right
	local b_orig = bottom
	local t_orig = top
	
	if facing_dir == 1 then
		left  = -left
		right = -right
	end

	left   = offset_x 	+ left
	right  = left 		+ right
	bottom = offset_y 	+ bottom
	top    = bottom 	+ top

	--[[
	print("l :  "..l_orig.." --> "..game_x_to_mame(left))
	print("r :  "..r_orig.." --> "..game_x_to_mame(right))
	print("t :  "..t_orig.." --> "..game_y_to_mame(top))
	print("b :  "..b_orig.." --> "..game_y_to_mame(bottom))
	print()
	--]]
	
	--[[
	if typeHb == HITBOX_TEST then
		--print(" --> left   : "..l_orig.." + "..offset_x.." = "..left.." ==> "..game_x_to_mame(left))
		--print(" --> right  : "..r_orig.." + "..left	 .." = "..right.." ==> "..game_x_to_mame(right))
		print(" --> bottom : "..b_orig.." + "..offset_y.." = "..bottom.." ==> "..game_y_to_mame(bottom))
		print(" --> top    : "..t_orig.." + "..bottom  .." = "..top.." ==> "..game_y_to_mame(top))
	end
	--]]
	
	local tmp = {
		l_orig = l_orig,
		r_orig = r_orig,
		t_orig = t_orig,
		b_orig = b_orig,
		left   = left,
		right  = right,
		bottom = bottom,
		top    = top,
		type   = typeHb
	}
	
	if typeHb == HITBOX_PASSIVE then obj.p_hboxes[i] = tmp
	elseif typeHb == HITBOX_ACTIVE then obj.a_hboxes[i] = tmp
	elseif typeHb == HITBOX_TEST then obj.v_hboxes[i] = tmp
	elseif typeHb == HITBOX_THROW then obj.t_hboxes[i] = tmp
	elseif typeHb == HITBOX_THROWABLE then obj.ta_hboxes[i] = tmp
	elseif typeHb == HITBOX_PUSH then obj.pu_hboxes[i] = tmp end
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

function update_game_object(obj, base, type)
	obj.p_hboxes = {}
	obj.a_hboxes = {}
	obj.v_hboxes = {}
	
	obj.t_hboxes = {}
	obj.ta_hboxes = {}
	obj.pu_hboxes = {}

	obj.facing_dir   = memory.readbyte(base + 0xA)
	obj.opponent_dir = memory.readbyte(base + 0xB)
	obj.pos_x        = memory.readword(base + 0x64)
	obj.pos_y        = memory.readword(base + 0x68)
	obj.anim_frame   = memory.readword(base + 0x21A)
	
	--print("update_game_object : "..h(base))
	
	-- Load the passive hitboxes
	local p_hb_addr = memory.readdword(base + 0x2A0)
	for i = 1, 4 do
		hitbox_load(obj, i, HITBOX_PASSIVE, obj.facing_dir, obj.pos_x, obj.pos_y, p_hb_addr, type)
		--print("P "..i.." --> "..obj.p_hboxes[i].l_orig.." "..obj.p_hboxes[i].r_orig.." "..obj.p_hboxes[i].t_orig.." "..obj.p_hboxes[i].b_orig.." ")
		p_hb_addr = p_hb_addr + 8
	end

	-- Load the active hitboxes
	local a_hb_addr = memory.readdword(base + 0x2C8)
	
	--if type == "P1" then print(emu.framecount(), h(base), 0x2C8, h(a_hb_addr)) end
	
	for i = 1, 4 do
		hitbox_load(obj, i, HITBOX_ACTIVE, obj.facing_dir, obj.pos_x, obj.pos_y, a_hb_addr, type, base + 0x2C8)
		--print("A "..i.." --> "..obj.p_hboxes[i].l_orig.." "..obj.p_hboxes[i].r_orig.." "..obj.p_hboxes[i].t_orig.." "..obj.p_hboxes[i].b_orig.." ")
		a_hb_addr = a_hb_addr + 8
	end

	local vuln_attack_address
	
	local vuln_attack_pointer_address = base + 0x02A8 --0x02068F14 for P1, 0x020693AC for P2

	local t_hb_addr = memory.readdword(vuln_attack_pointer_address)
	
	for i = 1, 4 do
		hitbox_load(obj, i, HITBOX_TEST, obj.facing_dir, obj.pos_x, obj.pos_y, t_hb_addr, type)
		--print("V "..i.." --> "..obj.p_hboxes[i].l_orig.." "..obj.p_hboxes[i].r_orig.." "..obj.p_hboxes[i].t_orig.." "..obj.p_hboxes[i].b_orig.." ")
		t_hb_addr = t_hb_addr + 8
	end
	
	-- throw box...
	local hb_addr = memory.readdword(base + 0x2B8)
	hitbox_load(obj, 1, HITBOX_THROW, obj.facing_dir, obj.pos_x, obj.pos_y, hb_addr, type)
	
	-- throwable box...
	local hb_addr = memory.readdword(base + 0x2C0)
	hitbox_load(obj, 1, HITBOX_THROWABLE, obj.facing_dir, obj.pos_x, obj.pos_y, hb_addr, type)
	
	-- push box...
	local hb_addr = memory.readdword(base + 0x2D4)
	hitbox_load(obj, 1, HITBOX_PUSH, obj.facing_dir, obj.pos_x, obj.pos_y, hb_addr, type)
	
	
end


function read_misc_objects()
	local obj_index
	local obj_addr

	local p_hb_addr
	local a_hb_addr

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

	while num_misc_objs <= MAX_GAME_OBJECTS and obj_index ~= -1 do
		obj_addr = 0x02028990 + (obj_index * 0x800)

		-- I don't really know how to tell different game objects types apart yet so
		-- just read everything that has non-zero hitbox addresses. Seems to
		-- work fine...
		p_hb_addr = memory.readdword(obj_addr + 0x2A0)
		a_hb_addr = memory.readdword(obj_addr + 0x2C8)
		v_hb_addr = memory.readdword(obj_addr + 0x2A8)

		--print(h(p_hb_addr)..""..h(a_hb_addr)..""..h(v_hb_addr))
		
		if p_hb_addr ~= 0 and a_hb_addr ~= 0 then
			misc_objs[num_misc_objs] = {}
			update_game_object(misc_objs[num_misc_objs], obj_addr, "OBJECTS")
			
			--[[
			local coord = misc_objs[num_misc_objs].p_hboxes[2]
			print(coord.l_orig.." "..coord.r_orig.." "..coord.t_orig.." "..coord.b_orig)
			--]]
			
			num_misc_objs = num_misc_objs + 1
		end

		-- Get the index to the next object in this list.
		obj_index = memory.readwordsigned(obj_addr + 0x1C)
	end
end


function game_x_to_mame(x)
	local left_edge = globals.screen_center_x - (SCREEN_WIDTH / 2)
	return (x - left_edge)
end


function game_y_to_mame(y)
	-- Why subtract 17? No idea, the game driver does the same thing.
	--print("??? : "..SCREEN_HEIGHT.." - ("..y.." + "..GROUND_OFFSET.." - 17) = "..(SCREEN_HEIGHT - (y + GROUND_OFFSET - 17)))
	return (SCREEN_HEIGHT - (y + GROUND_OFFSET - 17))
end


function draw_hitbox(hb, i)
	local left   = game_x_to_mame(hb.left)
	local bottom = game_y_to_mame(hb.bottom)
	local right  = game_x_to_mame(hb.right)
	local top    = game_y_to_mame(hb.top)

	local str = ""
	
	if(hb.type == HITBOX_PASSIVE) then
		colour = HITBOX_PASSIVE_COLOUR
		str = "PASSIVE:"..left.."x"..top.."-"..right.."x"..bottom
		--displayValue("Hb P "..i.." : "..hb.left.."x"..hb.top.."-"..hb.right.."x"..hb.bottom.." --> "..left.."x"..top.."-"..right.."x"..bottom, 100, 34 + i * 8, 0x0000ffff)
		--displayValue("Hb P "..i.." : "..hb.left.."x"..hb.top.."-"..hb.right.."x"..hb.bottom, 200, 34 + i * 8, 0x0000ffff)
		--print("Hb P "..i.." ("..colour..") : "..hb.left.."x"..hb.top.."-"..hb.right.."x"..hb.bottom)
	elseif(hb.type == HITBOX_ACTIVE) then
		colour = HITBOX_ACTIVE_COLOUR
		str = "ACTIVE:"..left.."x"..top.."-"..right.."x"..bottom
		--displayValue("Hb A "..i.." : "..hb.left.."x"..hb.top.."-"..hb.right.."x"..hb.bottom.." --> "..left.."x"..top.."-"..right.."x"..bottom, 100, 34 + i * 8, 0x00ff00ff)
		--displayValue("Hb A "..i.." : "..hb.left.."x"..hb.top.."-"..hb.right.."x"..hb.bottom, 200, 84 + i * 8, 0x00ff00ff)
		--print("Hb A "..i.." ("..colour..") : "..hb.left.."x"..hb.top.."-"..hb.right.."x"..hb.bottom)
		
		--[[
		if i ~= nil and left ~= 280 and top ~= 201 and right ~= 280 and bottom ~= 201 then
			displayValue("Active hitbox "..i.." : "..left.."x"..top.."-"..right.."x"..bottom, 200, 50 + i * 8, 0xff0000ff)
		end
		--]]
	elseif(hb.type == HITBOX_TEST) then
		colour = HITBOX_TEST_COLOUR
		str = "OBJECT:"..left.."x"..top.."-"..right.."x"..bottom.." from "..hb.left.."x"..hb.top.."-"..hb.right.."x"..hb.bottom
		--print(str)
		
		--displayValue("Hb V "..i.." : "..hb.left.."x"..hb.top.."-"..hb.right.."x"..hb.bottom.." --> "..left.."x"..top.."-"..right.."x"..bottom, 100, 34 + i * 8, 0xff0000ff)
		--displayValue("Hb V "..i.." : "..hb.left.."x"..hb.top.."-"..hb.right.."x"..hb.bottom, 200, 124 + i * 8, 0xff0000ff)
		--print("Hb V "..i.." : "..hb.left.."x"..hb.top.."-"..hb.right.."x"..hb.bottom)
		
		--[[
		if i ~= nil and left ~= 282 and top ~= 201 and right ~= 282 and bottom ~= 201 then
			--print("Vuln hitbox "..i.." : "..hb.left.."x"..hb.top.."-"..hb.right.."x"..hb.bottom.." --> "..left.."x"..top.."-"..right.."x"..bottom)
			--displayValue("Vuln hitbox "..i.." : "..hb.left.."x"..hb.top.."-"..hb.right.."x"..hb.bottom.." --> "..left.."x"..top.."-"..right.."x"..bottom, 200, 50 + i * 8, 0xff0000ff)
		end
		--]]
	else
		if hb.type == HITBOX_THROW then colour = HITBOX_THROW_COLOUR end
		if hb.type == HITBOX_THROWABLE then colour = HITBOX_THROWABLE_COLOUR end
		if hb.type == HITBOX_PUSH then colour = HITBOX_PUSH_COLOUR end
	end
	
	--print("Hb "..hb.type)
	
	gui.box(left, top, right, bottom, colour)
	
	return str
end


function draw_game_object(obj, aToDisplay)
	local x = game_x_to_mame(obj.pos_x)
	local y = game_y_to_mame(obj.pos_y)

	local sReturn = "AXE:"..x.."x"..y
	
	for i = 1, 4 do
		if aToDisplay.P then sReturn = sReturn.."\n"..draw_hitbox(obj.p_hboxes[i], i) end
		if aToDisplay.V then sReturn = sReturn.."\n"..draw_hitbox(obj.v_hboxes[i], i) end
		if aToDisplay.A then sReturn = sReturn.."\n"..draw_hitbox(obj.a_hboxes[i], i) end
	end

	if aToDisplay.T then draw_hitbox(obj.t_hboxes[1], 1) end
	if aToDisplay.TA then draw_hitbox(obj.ta_hboxes[1], 1) end
	if aToDisplay.PU then draw_hitbox(obj.pu_hboxes[1], 1) end
	
	gui.drawline(x, y-AXIS_SIZE, x, y+AXIS_SIZE, AXIS_COLOUR)
	gui.drawline(x-AXIS_SIZE, y, x+AXIS_SIZE, y, AXIS_COLOUR)
	
	return sReturn
end


function render_sfiii_hitboxes()
	update_globals()
	if globals.game_phase ~= GAME_PHASE_PLAYING then
		gui.clearuncommitted()
		return
	end

	update_game_object(player1, address.player1, "P1")
	
	update_game_object(player2, address.player2, "P2")
	read_misc_objects()
	
	
	if displayHb_P1 == true then draw_game_object(player1, HB_display.P1) end
	if displayHb_P2 == true then draw_game_object(player2, HB_display.P2) end

	for i = 1, num_misc_objs-1 do
		if displayHb_Objects == true then draw_game_object(misc_objs[i], HB_display.OBJ) end
	end
	
	displayValue("Pos diff : "..(a(gameData.p2.pos_x, "w") - a(gameData.p1.pos_x, "w")), 220, 8, 0xffff00ff)
	displayValue(emu.framecount(), 170, 1, 0x00ff00ff)
	displayValue("P1 Atk   : "..a(gameData.p1.attack, "b"), 3, 1, 0xffff00ff)
	displayValue("P1 State : "..a(gameData.p1.state, "b"), 	3, 9, 0xffff00ff)
	displayValue("P2 Atk   : "..a(gameData.p2.attack, "b"), 330, 1, 0xffff00ff)
	displayValue("P2 State : "..a(gameData.p2.state, "b"), 	330, 9, 0xffff00ff)
	
	displayValue("P1 Cancel : "..a(gameData.p1.mameCheatUniversalCancel, "b"), 3, 50, 0xffff00ff)
	displayValue("P2 Cancel : "..a(gameData.p2.mameCheatUniversalCancel, "b"), 325, 50, 0xffff00ff)
	
	displayValue(a(gameData.p1.pos_x, "w").." : pos_x : "..a(gameData.p2.pos_x, "w"), 160, 45, 0xffff00ff)
	displayValue(a(gameData.p1.opponent_dir, "b").." : opp_d : "..a(gameData.p2.opponent_dir, "b"), 160, 55, 0xffff00ff)
	displayValue(a(gameData.p1.facing_dir, "b").." : fac_d : "..a(gameData.p2.facing_dir, "b"), 160, 65, 0xffff00ff)
	displayValue(a(gameData.p1.inputsDirAndPunches, "b").." : inp_D : "..a(gameData.p2.inputsDirAndPunches, "b"), 160, 75, 0xffff00ff)
	displayValue(a(gameData.p1.inputsKicks, "b").." : inp_K : "..a(gameData.p2.inputsKicks, "b"), 160, 85, 0xffff00ff)
	displayValue(a(gameData.game.superfreeze, "b").." : superfreeze 1/2 : "..a(gameData.game.superfreeze_2, "b"), 160, 95, 0xffff00ff)
	
	displayInputsOnScreen(1, 85, 35) -- P1
	displayInputsOnScreen(2, 245, 35) -- P2
	
	displayValue("Q charge 4       : "..a(gameData.p1.charge4, "b"), 3, 60, 0xffff00ff)
	displayValue("Q charge reset 4 : "..a(gameData.p1.chargeResetter4, "b"), 3, 70, 0xffff00ff)
	
	--[[
	displayValue("Frame FBA  : "..frameFba, 	3, 50, 0xff0000ff)
	displayValue("Frame MAME : "..frameMame, 	3, 60, 0xff0000ff)
	displayValue(efc,						   55, 35, 0xff0000ff)
	
	displayValue("P1 Atk   : "..a(gameData.p1.attack, "b"), 3, 1, 0xffff00ff)
	displayValue("P1 State : "..a(gameData.p1.state, "b"), 	3, 9, 0xffff00ff)
	--]]
	--displayValue("P1 Atk   : "..a(gameData.p1.attack, "b"), 3, 1, 0xffff00ff)
end

emu.registerbefore(function()
	render_sfiii_hitboxes()
	local tmpAddr = gameData.p2.hb_active_base_address
	print(h(a(tmpAddr, "dw")), h(a(tmpAddr)))
	debugHB(a(tmpAddr, "dw"))
end)

gui.register(function()
	--view(0x06444960)
	
	-- trying to hack hitbox directly in data storage...
	local addr = gameData.p1.pos_x
	local value = 500
	
	--cheat(addr, value, "w")
	--cheat(0x02068F34, 0x0644D628, "dw")
end)

