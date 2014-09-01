-- launch needed modules...
local library_file = "./lua/library.lua"
local gameDatas_file = "./lua/3sGameData.lua"

dofile(library_file, "r")
dofile(gameDatas_file, "r")

local b = false

local function fctRegisterBefore()
	--print(emu.framecount())
	--print(os.clock())
	--print("scale? : "..a(gameData.p1.anim_frame, "w"))
	
	if b == false then
		b = true
		print("screenshot")
		makeScreenshot(1)
	end
	--view(0x040C0000)
end

gui.register(function()
	--displayValue("frame : "..emu.framecount(), 220, 5, 0x00ff00ff)
	--print(os.clock())
end)

emu.registerbefore(fctRegisterBefore)

--emu.registerafter()
