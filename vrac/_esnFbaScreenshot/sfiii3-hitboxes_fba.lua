--fba-rr専用hitbox.lua。
--既存のhitbox.luaを、以下の様に変更。
--・１フレーム後の判定を表示していた					→	そのフレームでの当たり判定を表示するように変更
--・通常の食らい判定だけ表示していた					→	攻撃を出した時の食らい判定も表示するように変更
--・キャラの縦座標が０以下になると判定が表示されなかった→	表示するように変更

local SCREEN_WIDTH          = 384
local SCREEN_HEIGHT         = 224
local GROUND_OFFSET         = 40
local MAX_GAME_OBJECTS      = 30
local AXIS_COLOUR           = 0xFFFFFFFF
local AXIS_SIZE             = 25
local HITBOX_PASSIVE        = 0
local HITBOX_ACTIVE         = 1
local HITBOX_PASSIVE2       = 2
--↓fbaでは透過処理が重いようなので、最後の２桁は00にすると良い。
local HITBOX_PASSIVE_COLOUR = 0x00008000
local HITBOX_ACTIVE_COLOUR  = 0x00FF0000
local HITBOX_PASSIVE2_COLOUR = 0x0000FF00
local GAME_PHASE_PLAYING    = 2

local index = 1
local activeHitBoxData = {}

timeInLua = 0
timeInGame = 0

local address = {
	player1         = 0x02068C6C,
	player2         = 0x02069104,
	screen_center_x = 0x02026CC0,
	screen_center_y = 0x0206A121,
}
local globals = {
	screen_center_x = 0,
	screen_center_y = 0,
	num_misc_objs   = 0
}
local globals2 = {
	screen_center_x = 0,
	screen_center_y = 0,
	num_misc_objs   = 0
}

local player1 = {}
local player2 = {}
local player1_2 = {}
local player2_2 = {}
local misc_objs = {}
local misc_objs_2 = {}

--スクリーンのｘ座標とゲームフェイズを更新
function update_globals()
	
	globals2.screen_center_x = globals.screen_center_x
	globals2.screen_center_y = globals.screen_center_y
	globals2.num_misc_objs   = globals.num_misc_objs
	
	globals.screen_center_x = memory.readword(address.screen_center_x)
	globals.screen_center_y = memory.readbyte(address.screen_center_y)
end

--メモリやテーブル内から当たり判定データを読み込む
function hitbox_load(obj, i, type, facing_dir, offset_x, offset_y, addr)
	
	if type == HITBOX_ACTIVE then
	
		left   = activeHitBoxData[addr+0x14C-0x643FFFF]
		left = left*0x100 + activeHitBoxData[addr+1+0x14C-0x643FFFF]
		left = num2signed(left,2)
		
		right   = activeHitBoxData[addr+2+0x14C-0x643FFFF]
		right = right*0x100 + activeHitBoxData[addr+2+0x14C+1-0x643FFFF]
		right = num2signed(right,2)
		
		bottom   = activeHitBoxData[addr+4+0x14C-0x643FFFF]
		bottom = bottom*0x100 + activeHitBoxData[addr+4+0x14C+1-0x643FFFF]
		bottom = num2signed(bottom,2)
		
		top   = activeHitBoxData[addr+6+0x14C-0x643FFFF]
		top = top*0x100 + activeHitBoxData[addr+6+0x14C+1-0x643FFFF]
		top = num2signed(top,2)
		
	else
		left   = memory.readwordsigned(addr)
		right  = memory.readwordsigned(addr + 2)
		bottom = memory.readwordsigned(addr + 4)
		top    = memory.readwordsigned(addr + 6)
	end
	
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
			type   = type
		}
	else
		if type == HITBOX_ACTIVE then
			obj.a_hboxes[i] = {
				left   = left,
				right  = right,
				bottom = bottom,
				top    = top,
				type   = type
			}
		else
			obj.p2_hboxes[i] = {
				left   = left,
				right  = right,
				bottom = bottom,
				top    = top,
				type   = type
			}
		end
	end
end


function update_game_object(obj, base)
	obj.p_hboxes = {}
	obj.a_hboxes = {}
	obj.p2_hboxes = {}

	obj.facing_dir   = memory.readbyte(base + 0xA)
	obj.opponent_dir = memory.readbyte(base + 0xB)
	obj.pos_x        = memory.readword(base + 0x64)
	obj.pos_y        = num2signed(memory.readword(base + 0x68),2)
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
	
		-- Load the passive2 hitboxes
	local a_hb_addr = memory.readdword(base + 0x2A8)
	for i = 1, 4 do
		hitbox_load(obj, i, HITBOX_PASSIVE2, obj.facing_dir, obj.pos_x, obj.pos_y, a_hb_addr)
		a_hb_addr = a_hb_addr + 8
	end
	
end


function read_misc_objects(table)
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
		p2_hb_addr = memory.readdword(obj_addr + 0x2A8)
		
		if p_hb_addr ~= 0 and a_hb_addr ~= 0 and p2_hb_addr ~= 0 then
			table[num_misc_objs] = {}
			update_game_object(table[num_misc_objs], obj_addr)
			num_misc_objs = num_misc_objs + 1
		end

		-- Get the index to the next object in this list.
		obj_index = memory.readwordsigned(obj_addr + 0x1C)
	end
end



function game_x_to_mame(x)
	local left_edge = globals2.screen_center_x - (SCREEN_WIDTH / 2)
	return (x - left_edge)
end


function game_y_to_mame(y)
	-- Why subtract 17? No idea, the game driver does the same thing.
	return (SCREEN_HEIGHT - (y + GROUND_OFFSET - 17) + num2signed(globals2.screen_center_y,1))
end


function draw_hitbox(hb)
	local left   = game_x_to_mame(hb.left)
	local bottom = game_y_to_mame(hb.bottom)
	local right  = game_x_to_mame(hb.right)
	local top    = game_y_to_mame(hb.top)

	if(hb.type == HITBOX_PASSIVE) then
		colour = HITBOX_PASSIVE_COLOUR
	else
		if(hb.type == HITBOX_ACTIVE) then
			colour = HITBOX_ACTIVE_COLOUR
		else
			colour = HITBOX_PASSIVE2_COLOUR
		end
	end

	gui.box(left, top, right, bottom, colour)
end


function draw_game_object(obj)
	local x = game_x_to_mame(obj.pos_x)
	local y = game_y_to_mame(obj.pos_y)

	for i = 1, 4 do
		draw_hitbox(obj.p_hboxes[i])
	end
	for i = 1, 4 do
		draw_hitbox(obj.p2_hboxes[i])
	end
	for i = 1, 4 do
		draw_hitbox(obj.a_hboxes[i])
	end
	
	gui.drawline(x, y-AXIS_SIZE, x, y+AXIS_SIZE, AXIS_COLOUR)
	gui.drawline(x-AXIS_SIZE, y, x+AXIS_SIZE, y, AXIS_COLOUR)
end


function render_sfiii_hitboxes()

	--対戦中でなければ終了
	game_phase = memory.readword(0x020154A6)
	if game_phase ~= GAME_PHASE_PLAYING 
		and game_phase ~= 6
		and game_phase ~= 7
		and game_phase ~= 8 then
		
		gui.clearuncommitted()
		return
	end

	--luaを起動して最初のフレームは、
	--１フレーム前のデータがテーブルに格納されていないので描画できない
	if timeInLua > 1 then
		--ゲーム内経過時間が偶数の時は、奇数だった時の当たり判定を表示
		if memory.readbyte(0x02068AB7) % 2 == 0 then
			draw_game_object(player1)
			draw_game_object(player2)
			for i = 1, num_misc_objs-1 do
				if #misc_objs > 0 then
					draw_game_object(misc_objs[i])
				end
			end
		else--ゲーム内経過時間が奇数の時は、偶数だった時の当たり判定を表示
			draw_game_object(player1_2)
			draw_game_object(player2_2)
			for i = 1, num_misc_objs-1 do
				if #misc_objs_2 > 0 then
					draw_game_object(misc_objs_2[i])
				end
			end
		end
	end
	
	--lua起動直後のみ、テキストファイルのデータをテーブルに読み込む。
	f = io.open("hitBoxData.txt", "r")
	if timeInLua == 0 and #activeHitBoxData == 0 then
		for line in f:lines() do
			activeHitBoxData[index] = line
			index = index + 1
		end
	f:close()
	end
	
	--ゲーム内の時間が経過していたらLua内の時間も進める。
	--つまり、Luaを開始して次のフレームから↑の描画が実行される
	if timeInGame ~= memory.readbyte(0x02068AB7) then
		update_globals()
		timeInLua = timeInLua + 1
	end
	
	--ゲーム内経過時間が偶数の時は、当たり判定データをこっちに格納
	if memory.readbyte(0x02068AB7) % 2 == 0 then
		update_game_object(player1_2, address.player1)
		update_game_object(player2_2, address.player2)
		read_misc_objects(misc_objs_2)
	else--ゲーム内経過時間が奇数の時は、当たり判定データをこっちに格納
		update_game_object(player1, address.player1)
		update_game_object(player2, address.player2)
		read_misc_objects(misc_objs)
	end
		timeInGame = memory.readbyte(0x02068AB7)
end




--- Returns HEX representation of num
function num2hex(num)    
local hexstr = '0123456789ABCDEF'    
local s = ''    
while num > 0 do        
local mod = math.fmod(num, 16)        
s = string.sub(hexstr, mod+1, mod+1) .. s        
num = math.floor(num / 16)    
end    
if s == '' then s = '0' end    
return s
end



--********数値valueの、bitnum番目のビットを返す関数********
--@param value	調べたい変数
--@param bitnum	何番目を調べたいか（最下位桁は0）
function bitReturn(value,bitnum)
	re = value
	
	--bitnumより上位桁を切り捨てる
	re = SHIFT(re,bitnum-31)

	--bitnumより下位桁を切り捨てる
	re = SHIFT(re,31)
	
	return re
end


--好きなバイト分書きこんでくれる関数
function write(addr,value,byte)
	for i=1,byte,1 do
		memory.writebyte(addr,value)
		addr = addr + 1
		value = ((value-(value%0x100)) / 0x100)
	end
end

--好きなバイト分逆向きに書き込んでくれる関数
function writeReverse(addr,value,byte)
	for i=1,byte,1 do
			memory.writebyte(addr,(value % 0x100))
		addr = addr - 1
		value = ((value-(value%0x100)) / 0x100)
	end
end

--好きなバイト分読みこんでくれる関数
function read(addr,byte)
	value = 0
	for i=1,byte,1 do
		value = (value + memory.readbyte(addr+i-1)) * 0x100
	end
	return value / 0x100
end

--好きなバイト分逆向きに読み込んでくれる関数
function readReverse(addr,byte)
	value = 0
	for i=1,byte,1 do
		value = value + (memory.readbyte(addr-(i-1)) * (0x100^(i-1)))
	end
	return value
end

--メモリ内の値をリアルタイムで見たいときに使う。
--アドレス部分に、見たいアドレスの値を入力すると、その周辺の値が見える。
function viewMemory(addr)
	for i=0,20,1 do
		gui.text(10,14+i*8,num2hex(addr+(i*0x10)))
		for j=0,15,1 do
			gui.text(48+j*16,4,num2hex(j))
			gui.text(48+j*16,14+i*8,num2hex(memory.readbyte((addr)+j+(i*0x10))))
		end	
	end
end

--メモリ内の値を、ファイルに書きだしてくれる。
--startは開始アドレス、lastは最終アドレス。
function writeFileMemory(start,last)
	out = io.open("memoryOut.txt","w")
	for i=start,last,1 do
		out:write(memory.readbyte(i).."\n")
	end
end


--位置座標を数値で表示してくれる。
function viewPosition()
		--1Pの座標を16進数で表示
		offsetX1 = 52
		offsetY1 = 32
		if readReverse(0x02068CD1,2) < 0x100 then
			gui.text(offsetX1,offsetY1,"X: "..num2hex(readReverse(0x02068CD1,2)))
		else
			gui.text(offsetX1,offsetY1,"X:"..num2hex(readReverse(0x02068CD1,2)))
		end
		if (readReverse(0x02068CD2,1)) == 0 then
			gui.text(offsetX1+20,offsetY1,".00")
		else
			gui.text(offsetX1+20,offsetY1,"."..num2hex(readReverse(0x02068CD2,1)))
		end
		
		gui.text(offsetX1,offsetY1+8,"Y:")
		gui.text(offsetX1+20-string.len(readReverse(0x02068CD5,2))*4,offsetY1+8,readReverse(0x02068CD5,2))
		if (readReverse(0x02068CD6,1)) == 0 then
			gui.text(offsetX1+20,offsetY1+8,".00")
		else
			gui.text(offsetX1+20,offsetY1+8,"."..num2hex(readReverse(0x02068CD6,1)))
		end
		
		
		--2Pの座標を16進数で表示
		offsetX2 = 256
		offsetY2 = 32
		if readReverse(0x02069169,2) < 0x100 then
			gui.text(offsetX2,offsetY2,"X: "..num2hex(readReverse(0x02069169,2)))
		else
			gui.text(offsetX2,offsetY2,"X:"..num2hex(readReverse(0x02069169,2)))
		end
		if (readReverse(0x0206916A,1)) == 0 then
			gui.text(offsetX2+20,offsetY2,".00")
		else
			gui.text(offsetX2+20,offsetY2,"."..num2hex(readReverse(0x0206916A,1)))
		end
		
		gui.text(offsetX2,offsetY2+8,"Y:")
		gui.text(offsetX2+20-string.len(readReverse(0x0206916D,2))*4,offsetY2+8,readReverse(0x0206916D,2))
		if (readReverse(0x0206916E,1)) == 0 then
			gui.text(offsetX2+20,offsetY2+8,".00")
		else
			gui.text(offsetX2+20,offsetY2+8,"."..num2hex(readReverse(0x0206916E,1)))
		end
		
		
		
		
		--差分のx座標を16進数で表示
		offsetX3 = 180
		offsetY3 = 38
		
		x1P = readReverse(0x02068CD1,2)
		x2P = readReverse(0x02069169,2)
		if x2P > x1P then
			if x2P < 0x100 then
				gui.text(offsetX3,offsetY3,"2P:  "..num2hex(x2P))
			else
				gui.text(offsetX3,offsetY3,"2P: "..num2hex(x2P))
			end
			
			if x1P < 0x100 then
				gui.text(offsetX3,offsetY3+8,"1P:  "..num2hex(x1P))
			else
				gui.text(offsetX3,offsetY3+8,"1P: "..num2hex(x1P))
			end
			
			gui.drawbox(offsetX3-10,offsetY3+15,offsetX3+28,offsetY3+17,0xFFFFFFFF,0x000000FF)
			
			if x2P-x1P < 0x100 then
				gui.text(offsetX3-8,offsetY3+19,"DIFF:  "..num2hex(x2P-x1P))
			else
				gui.text(offsetX3-8,offsetY3+19,"DIFF: "..num2hex(x2P-x1P))
			end
		else
			if x1P < 0x100 then
				gui.text(offsetX3,offsetY3,"1P:  "..num2hex(x1P))
			else
				gui.text(offsetX3,offsetY3,"1P: "..num2hex(x1P))
			end
			
			if x2P < 0x100 then
				gui.text(offsetX3,offsetY3+8,"2P:  "..num2hex(x2P))
			else
				gui.text(offsetX3,offsetY3+8,"2P: "..num2hex(x2P))
			end
		
			gui.drawbox(offsetX3-10,offsetY3+15,offsetX3+28,offsetY3+17,0xFFFFFFFF,0x000000FF)

			if x1P-x2P < 0x100 then
				gui.text(offsetX3-8,offsetY3+19,"DIFF:  "..num2hex(x1P-x2P))
			else
				gui.text(offsetX3-8,offsetY3+19,"DIFF: "..num2hex(x1P-x2P))
			end
		end
end

--数値とバイト数を引数に入れると、符号付きの数値に変換して返してくれる。
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

--停止時間を表示
function viewStop()
	STOP1 = read(0x2068CB1,1)
	if STOP1 > 127 then
		STOP1 = 256 - STOP1
	end
	gui.text(140,40,"STOP:"..STOP1)
	
	STOP2 = read(0x2069149,1)
	if STOP2 > 127 then
		STOP2 = 256 - STOP2
	end
	gui.text(220,40,"STOP:"..STOP2)
end

--ゲージMAX
function gaugeMax()
	gauge = memory.readbyte(0x020286AD)
	memory.writebyte(0x02028695,0xFF)
	memory.writebyte(0x020695B5,0xFF)
	memory.writebyte(0x020286AB,gauge)
	memory.writebyte(0x020695BF,gauge)
	memory.writebyte(0x020695BD,gauge)
	gauge2 = memory.readbyte(0x020286E1)
	memory.writebyte(0x020695E1,0xFF)
	memory.writebyte(0x020286DF,gauge2)
	memory.writebyte(0x0206940D,gauge2)
	memory.writebyte(0x020695EB,gauge2)
end

gui.register( function()
	
		--簡易メモリビューワ。見たい場合はここのコメントを外す
		--viewMemory(0x020154A0)
		
		--位置座標を数値で見たい場合はここのコメントを外す
		--viewPosition()
	
		--ギルを使いたい場合はこれを00にして書く
		--memory.writebyte(0x02011387,0x00)
		--memory.writebyte(0x02011388,0x00)
		
		--1Pの体の向き
		--memory.writebyte(0x02068C76,0x01)
		--2Pの体の向き
		--memory.writebyte(0x0206910E,0x01)
		
		--viewStop()
		gaugeMax()

		render_sfiii_hitboxes()
end)