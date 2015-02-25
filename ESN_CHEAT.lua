--[[
CHEAT helper...
- update : allow to increment/decrement a value which can be used in a cheat command by pressing U/J key...
- blank : will set given range to 0...
]]
CHEAT = {
	loop = 1,
	incr = 0x00,
	step = 0,
	update = function()
		if input.get()["U"] then CHEAT.step = CHEAT.step + 1 end
		if input.get()["J"] then CHEAT.step = CHEAT.step - 1 end
		if CHEAT.step > CHEAT.loop then
			CHEAT.incr = CHEAT.incr + 1
			CHEAT.step = 0
			print(string.format("%04X", CHEAT.incr))
		end
		
		if CHEAT.step < 0 then
			CHEAT.incr = CHEAT.incr - 2
			CHEAT.step = 1
			print(string.format("%04X", CHEAT.incr))
		end
	end,
	blank = function(addr, nb)
		if nb == nil then nb = 16 end
		
		for k = 1, nb do
			cheat(addr + (k - 1) * 4, 0x00000000, "dw")
		end
	end,
	force_no_zoom = function()
		view(0x0206A050)
		--print(emu.framecount(), h(a(0x0200DCBB), nil, 2), h(a(0x0200DCC3), nil, 2))
		cheat(0x0200DCBB, 0x40, "b") -- 40 = no zoom, less than 40 will zoom in, more will zoom out...
		cheat(0x0200DCC3, 0x40, "b")
		
		CHEAT.blank(0x0206A050, 64) -- block partially scrolling during zoom...
		
		-- cheat(0x0206A104, 0x0140, "w")
		-- cheat(0x0206A108, 0x0140, "w")
		-- cheat(0x0206A114, 0x0140, "w")
		-- cheat(0x0206A118, 0x0140, "w")
		
		-- cheat(0x0206A094, 0x02c0, "w")
		-- cheat(0x0206A098, 0x02c0, "w")
		-- cheat(0x0206A194, 0x02c0, "w")
		-- cheat(0x0206A198, 0x02c0, "w")
		
		--cheat(0x0200DCD0, 0x00, "b") -- zoom active ???
		--cheat(0x0200DCD2, 0x0000, "w") -- X offset
		--cheat(0x0200DCD4, 0x0000, "w") -- Y offset
		--cheat(0x02026CB0, 512, "w") -- screen center X
		--cheat(0x040c006c, 0x00, "b")
	end,
}
