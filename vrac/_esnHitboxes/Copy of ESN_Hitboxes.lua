--modified april 27, 2011 to add previously omitted vulnerable hitbox
local SCREEN_WIDTH          = 384
local SCREEN_HEIGHT         = 224
local GROUND_OFFSET         = 40
local MAX_GAME_OBJECTS      = 30
local AXIS_COLOUR           = 0xFFFFFFFF
local AXIS_SIZE             = 10
local HITBOX_PASSIVE        = 0
local HITBOX_ACTIVE         = 1
local HITBOX_TEST           = 2
local HITBOX_PASSIVE_COLOUR = 0x0000FF44
local HITBOX_ACTIVE_COLOUR  = 0x00FF0044
local HITBOX_TEST_COLOUR    = 0xFF000044
local GAME_PHASE_PLAYING    = 2
local GAME_PHASE_PREFIGHT   = 1

local address = { player1 = 0x02068C6C, player2 = 0x02069104, screen_center_x = 0x02026CB0,	game_phase = 0x020154A7 }
local globals = { game_phase = 0, screen_center_x = 0, num_misc_objs   = 0 }
local player1 = {}
local player2 = {}
local misc_objs = {}

local hitboxes = {}

currentFrame = 0
previousFrame = 0

function update_globals()
	globals.screen_center_x = memory.readword(address.screen_center_x)
	globals.game_phase      = memory.readword(address.game_phase)
	
end

function hitbox_load(obj, i, type, facing_dir, offset_x, offset_y, addr)
	local left   = memory.readwordsigned(addr)
	local right  = memory.readwordsigned(addr + 2)
	local bottom = memory.readwordsigned(addr + 4)
	local top    = memory.readwordsigned(addr + 6)
	
	local _left   = memory.readwordsigned(addr)
	local _right  = memory.readwordsigned(addr + 2)
	local _bottom = memory.readwordsigned(addr + 4)
	local _top    = memory.readwordsigned(addr + 6)
	
	if facing_dir == 1 then
		left  = -left
		right = -right
	end

	left   = left   + offset_x
	right  = right  + left
	bottom = bottom + offset_y
	top    = top    + bottom

	if type == HITBOX_PASSIVE then
		obj.p_hboxes[i] = {
			left   = left,
			right  = right,
			bottom = bottom,
			top    = top,
			type   = type,
			_left   = _left,
			_right  = _right,
			_bottom = _bottom,
			_top    = _top,
			_facing_dir = facing_dir,
			_offset_x = offset_x,
			_offset_y = offset_y,
			_addr = addr,
		}
	end

	if type == HITBOX_ACTIVE then
		obj.a_hboxes[i] = {
			left   = left,
			right  = right,
			bottom = bottom,
			top    = top,
			type   = type,
			_left   = _left,
			_right  = _right,
			_bottom = _bottom,
			_top    = _top,
			_facing_dir = facing_dir,
			_offset_x = offset_x,
			_offset_y = offset_y,
			_addr = addr,
		}
	end

	if type == HITBOX_TEST then
		obj.t_hboxes[i] = {
			left   = left,
			right  = right,
			bottom = bottom,
			top    = top,
			type   = type,
			_left   = _left,
			_right  = _right,
			_bottom = _bottom,
			_top    = _top,
			_facing_dir = facing_dir,
			_offset_x = offset_x,
			_offset_y = offset_y,
			_addr = addr,
		}
	end
end

function update_game_object(obj, base)
	obj.p_hboxes = {}
	obj.a_hboxes = {}
	obj.t_hboxes = {}
	
	obj.facing_dir   = memory.readbyte(base + 0xA)
	obj.opponent_dir = memory.readbyte(base + 0xB)
	obj.pos_x        = memory.readword(base + 0x64)
	obj.pos_y        = memory.readword(base + 0x68)
	obj.anim_frame   = memory.readword(base + 0x21A)

	-- Load the passive hitboxes
	local p_hb_addr = memory.readdword(base + 0x2A0)
	
	for i = 1, 4 do
		hitbox_load(obj, i, HITBOX_PASSIVE, obj.facing_dir, obj.pos_x, obj.pos_y, p_hb_addr)
		p_hb_addr = p_hb_addr + 8
	end
	
	-- Load the active hitboxes
	local a_hb_addr = memory.readdword(base + 0x2C8)
	
	for i = 1, 4 do
		hitbox_load(obj, i, HITBOX_ACTIVE, obj.facing_dir, obj.pos_x, obj.pos_y, a_hb_addr)
		a_hb_addr = a_hb_addr + 8
	end

	-- the vuln attack box pointer address is -0x2A8 away from base
	-- however, lua won't let me subtract from hex for some dumb reason so i'm using this stupid if/else

	local vuln_attack_address

	if (obj == player1) then
		vuln_attack_pointer_address = 0x02068F14
	else --obj == player2
		vuln_attack_pointer_address = 0x020693AC
	end

	local t_hb_addr = memory.readdword(vuln_attack_pointer_address)
	for i = 1, 4 do
		hitbox_load(obj, i, HITBOX_TEST, obj.facing_dir, obj.pos_x, obj.pos_y, t_hb_addr)
		t_hb_addr = t_hb_addr + 8
	end
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

		if p_hb_addr ~= 0 and a_hb_addr ~= 0 then
			misc_objs[num_misc_objs] = {}
			update_game_object(misc_objs[num_misc_objs], obj_addr)
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
	
	--local offset_y = 252 - a(gameData.game.screen_y, "b")
	--displayValue(offset_y, 175, 40, 0xffffffff)
	--return (SCREEN_HEIGHT - (y + GROUND_OFFSET - 17 + offset_y))
	
	return (SCREEN_HEIGHT - (y + GROUND_OFFSET - 17))
end


function draw_hitbox(hb)
	local left   = game_x_to_mame(hb.left)
	local bottom = game_y_to_mame(hb.bottom)
	local right  = game_x_to_mame(hb.right)
	local top    = game_y_to_mame(hb.top)

	if(hb.type == HITBOX_PASSIVE) then
		colour = HITBOX_PASSIVE_COLOUR		
	end

	if(hb.type == HITBOX_ACTIVE) then
		colour = HITBOX_ACTIVE_COLOUR
	end

	if(hb.type == HITBOX_TEST) then
		colour = HITBOX_TEST_COLOUR
	end

	-- useful when scroll up active...
	--local offset_y = a(gameData.game.screen_y, "b")
	--gui.box(left, top + (244 -offset_y), right, bottom + (244 - offset_y), colour)
	gui.box(left, top , right, bottom, colour)
end


function draw_game_object(obj, bDisplayInfos)
	local x = game_x_to_mame(obj.pos_x)
	local y = game_y_to_mame(obj.pos_y)

	for i = 1, 4 do
		draw_hitbox(obj.p_hboxes[i])
		
		draw_hitbox(obj.a_hboxes[i])
		draw_hitbox(obj.t_hboxes[i])
		
		--if bDisplayInfos == true then displayHitboxesCoord(i, obj.a_hboxes[i], 0xff0000ff, x, y) end
	end

	--local offset_y = a(gameData.game.screen_y, "b")
	
	gui.drawline(x, y-AXIS_SIZE, x, y+AXIS_SIZE, AXIS_COLOUR)
	gui.drawline(x-AXIS_SIZE, y, x+AXIS_SIZE, y, AXIS_COLOUR)
end

-- display corrd infos of hitboxes...
function displayHitboxesCoord(index, hb, color, x_axis, y_axis)
	local i = index
	local col_x, col_y = 5, 76
	local base_x = 50 + (i - 1) * 45
	local base_y = 60
	local line, incr = 0, 8

	local x = base_x + i * 25
	
	displayValue("Hitbox "..i	, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(""				, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(hb._facing_dir	, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(hb._offset_x	, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(hb._offset_y	, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(h(hb._addr)	, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(""				, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(hb._left		, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(hb._right		, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(hb._bottom		, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(hb._top		, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(""				, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(hb.left		, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(hb.right		, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(hb.bottom		, base_x, base_y + incr * line, color)
	line = line + 1
	displayValue(hb.top			, base_x, base_y + incr * line, color)
	line = line + 1
	
	displayValue("facing", col_x, col_y, color)
	displayValue("offset_x", col_x, col_y + 8, color)
	displayValue("offset_y", col_x, col_y + 16, color)
	displayValue("addr", col_x, col_y + 24, color)
	displayValue("_L", col_x, col_y + 40, color)
	displayValue("_R", col_x, col_y + 48, color)
	displayValue("_B", col_x, col_y + 56, color)
	displayValue("_T", col_x, col_y + 64, color)
	displayValue("L", col_x, col_y + 80, color)
	displayValue("R", col_x, col_y + 88, color)
	displayValue("B", col_x, col_y + 96, color)
	displayValue("T", col_x, col_y + 104, color)
	displayValue("(left   = _left   + offset_x)"	, col_x + 250, col_y - 16, color)
	displayValue("(right  = _right  + left)"		, col_x + 250, col_y - 16 + 8, color)
	displayValue("(bottom = _bottom + offset_y)"	, col_x + 250, col_y - 16 + 16, color)
	displayValue("(top    = _top    + bottom)"	, col_x + 250, col_y - 16 + 24, color)
end

function render_sfiii_hitboxes()
	update_globals()
	
	if globals.game_phase == GAME_PHASE_PLAYING or globals.game_phase == GAME_PHASE_PREFIGHT then
		gui.clearuncommitted()
		return
	end

	update_game_object(player1, address.player1)
	update_game_object(player2, address.player2)
	read_misc_objects()
	
	draw_game_object(player1)
	draw_game_object(player2)
	
	for i = 1, num_misc_objs-1 do
		draw_game_object(misc_objs[i])
	end
	
	--displayValue(player1.t_hboxes[1].left, 150, 80, 0xff0000ff)
	--displayValue(player1.t_hboxes[1].right, 150, 90, 0xff0000ff)
	--displayValue(player1.t_hboxes[1].bottom, 150, 100, 0xff0000ff)
	--displayValue(player1.t_hboxes[1].top, 150, 110, 0xff0000ff)
end

emu.registerbefore( function()
	-- launch collect process...
	
	render_sfiii_hitboxes()
end)

--[[
gui.register( function()
	--render_sfiii_hitboxes()
	
	-- avoid doing process twice...
	currentFrame = emu.framecount()
	
	if currentFrame ~= previousFrame then
		--test(emu.framecount())
		frameDataCollect()
		previousFrame = currentFrame
	end
	
	--hitboxesInfos(player1, player2)

	if typeView == nil then typeView = "b" end
	
	input.registerhotkey(4, function()
		-- switch between typeView
		if typeView == "b" then typeView = "w"
		elseif typeView == "w" then typeView = "ws"
		elseif typeView == "ws" then typeView = "dw"
		elseif typeView == "dw" then typeView = "c"
		elseif typeView == "c" then typeView = "b"
		else typeView = "b"
		end
	end)
	
	if a(gameData.p2["damageOfNextHit"], "b") ~= 0 then
		lastHitDamage = a(gameData.p2["damageOfNextHit"], "b")
	end
	
	getInputs(gameData.p1.inputs)
	
	--displayValue("lastHitDamage : "..lastHitDamage, 200, 3, 0xff00ffff)
	
	--displayValue("hitboxes_active : "..r(gameData.p1["hitboxes_active"], "dw"), 4, 3, 0xffff00ff)
	--displayValue("active HB presence : "..r(gameData.p1["hb_active_presence"], "b"), 4, 10, 0x00ff00ff)
	
	--displayGameData(gameData.p1, 20, 35)
	--displayGameData(gameData.p2, 250, 35)
	--displayGameData(gameData.game, nil, 45)
	
	--displayValue(emu.framecount(), 182, 210, 0xff00ffff)
end)
--]]