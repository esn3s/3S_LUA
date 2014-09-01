--Frame data collector script
-- originally created by Dammit fromdammit.typepad.com

--[[
to do:
- read startup : detect button pressed, end when at least a green box appears
- read recovery : force jump and detect when char state change to jump
	--> on whiff
	--> on hit
	--> on block
- take screenshot of each frame
- read damage on hit for each hit of the move
- read stun for each hit of the move

description "attack":
- 0 : 
- 4 : attack

description "state":
- 0 : neutral
- 1 : back to ground from jump / on standing guard?
- 2 : dir forward / on crouching guard?
- 3 : dir back
- 4 : dash forward
- 5 : dash backward
- 5 : throw attempt from opp
- 6 : crouch startup
- 7 : crouch state
- 8 : active throw
- 9 : being hit by projectile
- 11 : crouch to neutral
- 12 : jump startup
- 13 : superjump startup
- 15 : in air
- 21 : superjump
- 22 : being hit
- 23 : dir to neutral
- 24 : parry?
- 25 : being hit
- 29 : standing hit
- 30 : hit but standing guard?
- 34 : being hit
- 43 : throw tech / caught by demon
- 44 : throw being teched
- 45 : UOH recovery
- 49 : crouching hit
- 56 : UOH (for gouki, 24 for makoto)
- 64 : knockdowned
- 144 : throw startup

p1 pal:

0x060CDA46 
0x060CE91A 
0x060D1E4E 
0x060D2B6A 

--]]

ALEX 	= 0x01
RYU 	= 0x02
HUGO 	= 0x06
ORO 	= 0x09
URIEN 	= 0x0D
CHUN 	= 0x10
Q 		= 0x12
REMY 	= 0x14

UP = 0
DW = 1
FO = 2
BA = 3
LP = 4
MP = 5
HP = 6
LK = 0
MK = 1
HK = 2
START = 0x01

g = {
	p1 = {
		start = 0x02068C6C,
		stop  = 0x02100000,
	},
	p2 = {
		start = 0x0200E910,
		stop  = 0x02100000,
	},
	game = {
		start = 0x02000000,
		stop  = 0x02100000,
	}
}

gameData = {
	tests = {
		
		
		
		
	}
	,p1 = {
		life 			= 0x02028655, -- max = 160, death = 255
		stun 			= 0x02028805, --  ??? max/stun = 72 or 0x48
		hurt			= 0x020288A8,
		attack 			= 0x02068C93,
		state 			= 0x02068E75,
		hit_by_N		= 0x0202884D, -- hit by normal
		hit_by_S 		= 0x0202884F, -- hit by special
		hit_by_SA_other	= 0x02028855, -- hit by FB SA? only akuma air SA1?
		hit_by_SA 		= 0x02028859, -- hit by SA?
		damageOfNextHit = 0x020691A7,
		stunOfNextHit 	= 0x02069437,
		combo 			= 0x020696C5,
		
		selectedSuperArt = 0x0201138B,
		stunRecoveryRate = 0x02069602,
		
		inputsDirAndPunches	= 0x0202563D, -- binary addition of 2^n for each input hold, kicks are located at this - 1
		inputsKicks			= 0x0202563C,
		
		maxSaBar 		= 0x020286AD,
		saBarCount 		= 0x020286AB,
		exAvailable 	= 0x020695A8,
		saBarContent 	= 0x020286A5,
		
		bar				= 0x020695E1,
		life2			= 0x02068D0B,
		stunBarLength	= 0x020695F7,
		stunStatus		= 0x020695FD,
		
		hitboxes_active = 0x02009EFC, -- address 
		hb_active_presence = 0x02068F05,
		hb_vulnerability_presence = 0x02068F07,
		
		--[[
		hb_active_list = {
			0x0644D248,
			0x0644D250,
			0x0644D258,
			0x0644D260,
		},
		--]]
		
		activeThrow = 0x02068F01,
		
		jumpRecoveryTrigger1 = 0x02068CA7,
		jumpRecoveryTrigger2 = 0x02068E81, -- jump recovery can be cancelled when trigger1 = 2 and trigger2 = 3
		
		hb_base_address = 0x02068C6C, -- base address, not used directly
		facing_dir		= 0x02068C76, -- facing_dir
		opponent_dir 	= 0x02068C77, -- opponent_dir
		pos_x 			= 0x02068CD0, -- pos_x
		pos_y 			= 0x02068CD4, -- pos_y
		anim_frame 		= 0x02068E86, -- anim_frame
		
		hb_passive_base_address 	= 0x02068F0C, -- passive hitboxes base address, base + 0x2a0
		hb_active_base_address 		= 0x02068F34, -- active hitboxes base address, base + 0x2c8
		hb_vulnerability_pointer 	= 0x02068F14, -- vulnerability attack box pointer address, base + 0x2a8
		
		hb_throw_base_address		= 0x02068F24, -- throw attack box pointer address, base + 0x2b8
		hb_throwable_base_address	= 0x02068F2C, -- throwable box pointer address, base + 0x2c0
		hb_push_base_address		= 0x02068F40, -- pushboxes pointer address, base + 0x2d4
		
		hayateCharge		= 0x02025665, -- hayate charge
		
		
		charge1 			= 0x02025A49,
		chargeResetter1 	= 0x02025A47,
		
		charge2 			= 0x02025A2D,
		chargeResetter2 	= 0x02025A2B,
		
		charge3 			= 0x02025A11,
		chargeResetter3 	= 0x02025A0F,
		
		charge4 			= 0x020259F5,
		chargeResetter4 	= 0x020259F3,
		
		charge5 			= 0x020259D9,
		chargeResetter5 	= 0x020259D7,
		
		denjin				= 0x02068D2D,
		denjin2				= 0x02068D27,
		
		rotation1			= 0x0202590F,
		rotationResetter1	= 0x020258F7,
		
		rotation2			= 0x020259EF,
		rotationResetter2	= 0x020259D7,
		
		rotation3			= 0x02025A0B,
		rotationResetter3	= 0x020259F3,
		
		hyakuretsu1			= 0x02025A03,
		hyakuretsu2			= 0x02025A05,
		hyakuretsu3			= 0x02025A07,
		
		p1addr 	= 0x02011387,
		p1color	= 0x02015684,
		
		mameCheatInfiniteFireball 		= 0x02068FB8,
		mameCheatNoComboDamageReduction = 0x0206903E,
		mameCheatSemiInfiniteJuggle 	= 0x02069031,
		mameCheatTrueInfiniteJuggle 	= 0x0206902E,
		mameCheatBonusResistance 		= 0x020690AD,
		mameCheatBonusDamage	 		= 0x020690A7,
		mameCheatBonusStun		 		= 0x020690AB,
		mameCheatUniversalCancel		= 0x02068E8D,
		mameCheatGroundParryHigh 		= 0x02026335,
		mameCheatGroundParryLow 		= 0x02026337,
		mameCheatAntiAirGround 			= 0x02026347,
		mameCheatAntiAirInAir 			= 0x02026339,
		mameCheatGrabTech 				= 0x02026328,
		
		_3fv_p1_stop = 0x2068CB1,
		_3fv_p1_damageDone = 0x02010D61,
	},
	p2 = {
		life 		= 0x0202866D, -- max = 160, death = 255
		stun 		= 0x02028829, -- max/stun = 72 or 0x48
		hurt		= 0x020288A9, -- ??
		state 		= 0x020691B3,
		attack		= 0x0206912B,
		hit_by_N	= 0x02028861, -- hit by normal
		hit_by_S 	= 0x02028863, -- hit by special
		hit_by_SA_other	= 0x02028869, -- hit by FB SA? only akuma air SA1?
		hit_by_SA 	= 0x0202886D, -- hit by SA?
		damageOfNextHit = 0x02068D0F,
		stunOfNextHit 	= 0x02068F9F,
		combo 			= 0x0206961D,
		
		inputsDirAndPunches	= 0x02025681, -- binary addition of 2^n for each input hold...
		inputsKicks			= 0x02025680, -- kicks are located at this - 1
		
		maxSuperBar = 0x020695BD,
		exAvailable = 0x020695D4,
		saBarContent = 0x020286D9,
		
		hb_base_address = 0x02069104, -- base address, not used directly
		facing_dir		= 0x0206910E, -- facing_dir
		opponent_dir 	= 0x0206910F, -- opponent_dir
		pos_x 			= 0x02069168, -- pos_x
		pos_y 			= 0x0206916C, -- pos_y
		anim_frame 		= 0x0206931E, -- anim_frame, needed to force frame display
		
		hb_passive_base_address 	= 0x020693A4, -- passive hitboxes base address
		hb_active_base_address 		= 0x020693CC, -- active hitboxes base address
		hb_vulnerability_pointer 	= 0x020693AC, -- vulnerability attack box pointer address
		
		hb_throw_base_address		= 0x020693BC, -- throw attack box pointer address, base + 0x2b8
		hb_throwable_base_address	= 0x020693C4, -- throwable box pointer address, base + 0x2c0
		hb_push_base_address		= 0x020693D8, -- pushboxes pointer address, base + 0x2d4
		
		activeThrow = 0x02069399,
		
		p2addr 	= 0x02011388,
		p2color	= 0x02015684,
		
		life2 			= 0x020691A3,
		stunBarLength 	= 0x0206960B,
		stunStatus 		= 0x02069611,
		bar				= 0x020695B5,
		
		selectedSuperArt = 0x0201138C,
		stunRecoveryRate = 0x02069616,
		
		charge1 		= 0x02025FF9,
		chargeResetter1 = 0x02025FF7,
		charge2 		= 0x02026031,
		chargeResetter2 = 0x0202602F,
		charge3 		= 0x02026015,
		chargeResetter3 = 0x02026013,
		charge4 		= 0x0202604D,
		chargeResetter4 = 0x0202604B,
		charge5 		= 0x02026069,
		chargeResetter5 = 0x02026067,
		
		mameCheatInfiniteFireball 		= 0x02069450,
		mameCheatNoComboDamageReduction = 0x020694D6,
		mameCheatSemiInfiniteJuggle 	= 0x020694C9,
		mameCheatTrueInfiniteJuggle 	= 0x020694C6,
		mameCheatBonusResistance 		= 0x02069545,
		mameCheatBonusDamage	 		= 0x0206953F,
		mameCheatBonusStun		 		= 0x02069543,
		mameCheatUniversalCancel 		= 0x02069325,
		mameCheatGroundParryHigh 		= 0x0202673B,
		mameCheatGroundParryLow 		= 0x0202673D,
		mameCheatAntiAirGround 			= 0x0202674D,
		mameCheatAntiAirInAir 			= 0x0202673F,
		mameCheatGrabTech 				= 0x0202672E,
		_3fv_p2_stop = 0x2069149,
	},
	game = {
		superfreeze 	= 0x02069520, -- P1
		superfreeze_2 	= 0x02069088, -- P2
		superfreeze_decount = 0x0202922B, -- from 56 to 0 when superfreeze begins
		superfreeze_decount = 0x02028A2B,
		
		zoom = 0x040C006E,
		zoom_X = 0x0200DCD3,
		zoom_Y = 0x0200DCD5,
		zoom_Y_current = 0x0206A169,
		
		p1addr 	= 0x02011387,
		p1color	= 0x02015684,
		p2addr 	= 0x02011388,
		p2color	= 0x02015684,
		
		objects_base_address = 0x02028990,
		
		screen_center_x = 0x02026CB0, -- from 272 to 752, middle = 512
		screen_center_y = 0x0206A160, -- middle = 764
		game_phase      = 0x020154A7, -- fight = 2, pre fight = 1, end of round = 3 then 6 one frame after
		hb_objects		= 0x02068A96, -- objects list for hb, useful one is third one
		hb_third_obj	= 0x02068A9C, -- third list of objects for hb
		timer			= 0x02011377,
		timer2			= 0x02028679,
		credits			= 0x02007CE0,
		background		= 0x02026BB0,
		mameCheatScreenLock = 0x02026CB1,
		mameCheatMusic = 0x02078D06,
		
		_3fv_airTimer = 0x020694C9,
		_3fv_airComboInf = 0x020694C7,
		_3fv_hitStop = 0x0206914B,
		_3fv_hitStop2 = 0x02069149,
		_3fv_zeroHitStop = 0x02068CB3,
		_3fv_zeroHitStop2 = 0x02068CB1,
	},
}
dataType = {
	life 			= "b", -- max = 160, death = 255
	stun 			= "b", --  ??? max/stun = 72 or 0x48
	hurt			= "b",
	attack 			= "b",
	state 			= "b",
	hit_by_N		= "b", -- hit by normal
	hit_by_S 		= "b", -- hit by special
	hit_by_SA_other	= "b", -- hit by FB SA? only akuma air SA1?
	hit_by_SA 		= "b", -- hit by SA?
	damageOfNextHit = "b",
	stunOfNextHit 	= "b",
	combo 			= "b",
	
	inputs 			= "b", -- binary addition of 2^n for each input hold, kicks are located at this - 1
	inputs2			= "b",
	
	maxSaBar 	= "b",
	saBarCount 	= "b",
	exAvailable = "b",
	saBarContent = "b",
	
	hitboxes_active = "dw", -- address 
	hb_active_presence = "b",
	hb_vulnerability_presence = "b",
	
	activeThrow = "b",
	
	jumpRecoveryTrigger1 = "b",
	jumpRecoveryTrigger2 = "b", -- jump recovery can be cancelled when trigger1 = 2 and trigger2 = 3
	
	hb_base_address = "b", -- base address, not used directly
	facing_dir		= "b", -- facing_dir
	opponent_dir 	= "b", -- opponent_dir
	pos_x 			= "ws", -- pos_x
	pos_y 			= "ws", -- pos_y
	anim_frame 		= "w", -- anim_frame
	
	hb_passive_base_address 	= "dw", -- passive hitboxes base address
	hb_active_base_address 		= "dw", -- active hitboxes base address
	hb_vulnerability_pointer 	= "dw", -- vulnerability attack box pointer address
	
	charge1 			= "b",
	chargeResetter1 	= "b",
	
	charge2 			= "b",
	chargeResetter2 	= "b",
	
	charge3 			= "b",
	chargeResetter3 	= "b",
	
	charge4 			= "b",
	chargeResetter4 	= "b",
	
	charge5 			= "b",
	chargeResetter5 	= "b",
	
	denjin				= "b",
	chargeResetter		= "b",
	
	rotation1			= "b",
	rotationResetter1	= "b",
	
	rotation2			= "b",
	rotationResetter2	= "b",
	
	rotation3			= "b",
	rotationResetter3	= "b",
	
	hyakuretsu1			= "b",
	hyakuretsu2			= "b",
	hyakuretsu3			= "b",
	
	superfreeze 	= "b", -- P1
	superfreeze_2 	= "b", -- P2
	superfreeze_decount = "b", -- from 56 to 0 when superfreeze begins
	superfreeze_decount = "b",
	
	screen_center_x = "ws", -- from 272 to 752, middle = 512
	screen_center_y = "ws", -- middle = 764
	game_phase      = "b", -- fight = 2, pre fight = 1, end of round = 3 then 6 one frame after
	hb_objects		= "dw", -- objects list for hb, useful one is third one
	hb_third_obj	= "dw", -- third list of objects for hb
	timer			= "b",
	timer2			= "b",
	objects_base_address = "dw",
}

--[[
0;
1;tame1:0x02025A49, 0x02025A47;tame2:0x02025A2D, 0x02025A2B;kaiten1:0x0202590F, 0x020258F7;
2;denjin:0x02068D2D;denjin2:0x02068D27;
3;
4;
5;
6;kaiten1:0x020259EF, 0x020259D7;kaiten2:0x02025A0B, 0x020259F3;
7;
8;
9;tame1:0x02025A11, 0x02025A0F;tame2:0x020259D9, 0x020259D7;
10;
11;
12;
13;tame1:0x020259D9, 0x020259D7;tame2:0x02025A2D, 0x02025A2B;tame3:0x020259F5, 0x020259F3;
14;
15;
16;tame1:0x020259D9, 0x020259D7;hyakuretsu1:0x02025A03;hyakuretsu2:0x02025A05;hyakuretsu3:0x02025A07;
17;
18;tame1:0x020259D9, 0x020259D7;tame2:0x020259F5, 0x020259F3;
19;
20;tame1:0x020259F5, 0x020259F3;tame2:0x02025A11, 0x02025A0F;tame3:0x020259D9, 0x020259D7
--]]

chars = {
	p1addr = 0x02011387,
	p1color= 0x02015684,
	p2color= 0x02015684,
	p2addr = 0x02011388,
	
	alex = {
		charge_h = 0x02025A49,
		timer_h = 0x02025A47,
		charge_v = 0x02025A2D,
		timer_v = 0x02025A2B,
	},
	chun = {
		charge_h = 0x02025A49,
		timer_h = 0x02025A47,
		charge_v = 0x02025A2D,
		timer_v = 0x02025A2B,
	},
	q = {
		charge_h = 0x0202604D,
		timer_h = 0x0202604B,
		charge_v = 0x02025A2D,
		timer_v = 0x02025A2B,
	},
	idChar = {
		_0 = "gill",
		_1 = "alex",
		_2 = "ryu",
		_3 = "yun",
		_4 = "dudley",
		_5 = "necro",
		_6 = "hugo",
		_7 = "ibuki",
		_8 = "elena",
		_9 = "oro",
		_10 = "yang",
		_11 = "ken",
		_12 = "sean",
		_13 = "urien",
		_14 = "gouki",
		_15 = "shingouki",
		_16 = "chun",
		_17 = "makoto",
		_18 = "q",
		_19 = "twelve",
		_20 = "remy",
		_21 = "",
	}
}

data = {
	"life",
	"stun",
	"hurt",
	"state",
	"attack",
	"hit_by_N",
	"hit_by_S",
	"hit_by_SA_other",
	"hit_by_SA",
	"damageOfNextHit",
	"stunOfNextHit"
}