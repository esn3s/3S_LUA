--[[
HITBOX display...
- HITBOX.init() must be called in emu.registerbefore...
- 
]]
HITBOX = {
	display = function() HITBOX.init() end,
	init = function()
		HITBOX.currentFrame = emu.framecount()
		HITBOX.screen_center_x = a(0x02026CB0, "w")
		HITBOX.screen_center_y = a(0x0206A160, "w")
		
		-- update param values for each objects...
		HITBOX.data.p1 = {}
		HITBOX.data.p2 = {}
		
		if true then
			-- temp objects tests...
			--HITBOX.objectsTest()
			--return
		end
		
		-- update param and hitbox raw data for each objects...
		for player, v in pairs(HITBOX.data) do
			if HITBOX.entity[player].display then
				for paramName, vv in pairs(HITBOX.param) do
					HITBOX.data[player][paramName] = a(HITBOX.entity[player].base + vv.offset, vv.type)
				end
				
				for name, vv in pairs(HITBOX.hbType) do
					HITBOX.data[player][name] = {}
					
					if HITBOX.hbType[name].display then
						local base = a(HITBOX.entity[player].base + HITBOX.hbType[name].offset, "dw")
						
						for j = 1, vv.number do
							local addr = base + (j - 1) * 8
							
							HITBOX.data[player][name] = {
								addr = addr,
								boxData = HITBOX.readHB(addr, HITBOX.data[player])
							}
							
							-- draw it...
							HITBOX.draw(HITBOX.data[player][name].boxData.emul, HITBOX.hbType[name].color)
							
							--print(player, name, h(addr), HITBOX.data[player].FACING_DIR, HITBOX.data[player].POS_X.."x"..HITBOX.data[player].POS_Y, HITBOX.debugHb(HITBOX.data[player][name].boxData.raw))
							--print("\t\t\tprepared: "..HITBOX.debugHb(HITBOX.data[player][name].boxData.prepared))
							--print("\t\t\temul: "..HITBOX.debugHb(HITBOX.data[player][name].boxData.emul))
						end
					end
					
					-- draw axis...
					if HITBOX.AXIS.display then HITBOX.drawAxis(HITBOX.game_x_to_emul(HITBOX.data[player].POS_X), HITBOX.game_y_to_emul(HITBOX.data[player].POS_Y)) end
				end
			end
		end
	end,
	objectsTest = function()
		local list = 1

		local num_misc_objs = 1
		obj_index = memory.readwordsigned(0x02068A96 + (list * 2))
		print(num_misc_objs, "obj_index", obj_index)
		
		while num_misc_objs <= HITBOX.MAX_GAME_OBJECTS and obj_index ~= -1 do
			obj_addr = 0x02028990 + (obj_index * 0x800)
			print(num_misc_objs, "obj_base", h(obj_addr, nil, 8))
			
			-- Get the index to the next object in this list.
			obj_index = memory.readwordsigned(obj_addr + 0x1C)
			print(num_misc_objs, "obj_index2", obj_index)
		end
	end,
	draw = function(hb, color) gui.box(hb.left, hb.top, hb.right, hb.bottom, color) end,
	AXIS = { SIZE = 5, color = 0xFFFFFFFF, display = true },
	drawAxis = function(x, y)
		local AXIS_SIZE = HITBOX.AXIS.SIZE
		gui.drawline(x, y - AXIS_SIZE, x, y + AXIS_SIZE, HITBOX.AXIS.color)
		gui.drawline(x - AXIS_SIZE, y, x + AXIS_SIZE, y, HITBOX.AXIS.color)
	end,
	readHB = function(addr, param)
		-- retrieve hitbox coordinates and prepare for display...
		local raw = {
			cx 		= memory.readwordsigned(addr),
			cy 		= memory.readwordsigned(addr + 4),
			width 	= memory.readwordsigned(addr + 2),
			height 	= memory.readwordsigned(addr + 6)
		}
		
		-- depending on FACING_DIR, add or substract values to get in game full coordinates...
		-- left = position x object +/- cx raw hb...
		-- right = position x object +/- (cx raw hb - width), -width cause game draw draw box from x to before it...
		local left, right
		if param.FACING_DIR == 1 then
			left 	= param.POS_X - raw.cx
			right	= param.POS_X - (raw.cx + raw.width)
		else
			left 	= param.POS_X + raw.cx
			right	= param.POS_X + (raw.cx + raw.width)
		end
		
		-- bottom = position y object + cy raw hb...
		-- top = position y object + (cy raw hb + height)
		local bottom 	= param.POS_Y + raw.cy
		local top 		= param.POS_Y + (raw.cy + raw.height)
		
		-- box coordinates (2 corners coord to draw rectangle) in game representation...
		local prepared = {
			left	= left,
			right	= right,
			bottom	= bottom,
			top		= top
		}
		
		-- box coordinates (2 corners coord to draw rectangle) in emul representation...
		local emul = {
			left   = HITBOX.game_x_to_emul(left),
			bottom = HITBOX.game_y_to_emul(bottom),
			right  = HITBOX.game_x_to_emul(right),
			top    = HITBOX.game_y_to_emul(top)
		}
	
		return {raw = raw, prepared = prepared, emul = emul }
	end,
	
	game_x_to_emul = function(x) return x - (HITBOX.screen_center_x - (HITBOX.SCREEN_WIDTH / 2)) end,
	game_y_to_emul = function(y) return HITBOX.SCREEN_HEIGHT - (y + HITBOX.GROUND_OFFSET - 17) end,
	
	debugHb = function(hb, bHex)
		-- return a string with given box data...
		-- keys depends if HB raw or not...
		local a = hb.left and hb.left or hb.cx
		local b = hb.right and hb.right or hb.width
		local c = hb.bottom and hb.bottom or hb.cy
		local d = hb.top and hb.top or hb.height
		
		if bHex == nil then
			return a..","..b..","..c..","..d
		else
			return h(a, nil, 4, "")..","..h(b, nil, 4, "")..","..h(c, nil, 4, "")..","..h(d, nil, 4, "")
		end
	end,
	currentFrame = -1,
	SCREEN_WIDTH = 384,
	SCREEN_HEIGHT = 224,
	GROUND_OFFSET = 40,
	MAX_GAME_OBJECTS = 30,
	
	data = {
		-- contains raw hitboxes data, and ready to be displayed data for each objects...
		p1 = {},
		p2 = {},
		--obj = {},
	},
	param = {
		FACING_DIR	= { offset = 0x0A, type = "b" },
		OPPONENT_DIR= { offset = 0x0B, type = "b" },
		POS_X		= { offset = 0x64, type = "w" },
		POS_Y		= { offset = 0x68, type = "w" },
		SPRITE		= { offset = 0x021A, type = "w" },
	},
	hbType = {
		PASSIVE 	= { offset = 0x02A0, number = 4, color = 0x0000FF00, display = true },
		ACTIVE 		= { offset = 0x02C8, number = 4, color = 0xFF000000, display = true },
		LIMB 		= { offset = 0x02A8, number = 4, color = 0x0099FF00, display = true },
		THROW 		= { offset = 0x02B8, number = 1, color = 0xFF009900, display = false },
		THROWABLE 	= { offset = 0x02C0, number = 1, color = 0x00FF0000, display = false },
		PUSH 		= { offset = 0x02D4, number = 1, color = 0xFF990000, display = false },
		--TEST 		= { offset = 0x02E8, number = 1, color = 0xFF00FF00, display = true },
	},
	entity = {
		p1 = { name = "P1", base = 0x02068C6C, display = true },
		p2 = { name = "P2", base = 0x02069104, display = true },
		obj = { name = "OBJ", base = 0x02028990, display = false }
	},
	forceNoZoom = function()
		
	end,
}
