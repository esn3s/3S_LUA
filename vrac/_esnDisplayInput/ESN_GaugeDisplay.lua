-- display charge gauge on screen if available...

-- display a gauge
function displayGauge(label, charge, timer, x, y)
	local height = 3
	local noColor = 0x00000000
	local bgColor = 0x222222ff
	local colorReset = 0xff0000ff
	local colorChargeOk = 0x0000ffff
	local colorCharge = 0x5599ffff
	local colorTimer = 0xff6633ff
	local border = 0x000000ff
	local grayBorder = 0xd0e0e8ff
	
	local boxBorder_fill, box_border, box_fill
	
	gui.drawtext(x + 47, y + 1, label)
	--x = x + 10
	
	charge = a(charge)
	timer = a(timer)
	
	-- charge part...
	boxBorder_fill = bgColor
	box_fill = colorCharge
	box_border = grayBorder
	
	if charge == 255 then
		box_border = colorChargeOk
		charge = 0
	end
	
	charge = 42 - charge
	
	gui.drawbox(x, y, x + 43, y + height, boxBorder_fill, box_border)
	if charge > 0 then gui.drawbox(x + 1, y + 1, x + charge, y + 2, box_fill) end
	--gui.drawtext(x + 50, y - 2, charge)
	
	-- timer part...
	boxBorder_fill = bgColor
	box_fill = colorTimer
	box_border = grayBorder
	
	if timer == 255 then
		box_border = colorReset
		timer = 0
	end
	
	y = y + 5
	gui.drawbox(x, y, x + 43, y + height, boxBorder_fill, box_border)
	if timer > 0 then gui.drawbox(x + 1, y + 1, x + timer, y + 2, box_fill) end
	--gui.drawtext(x + 50, y, timer)
end

function gaugeDisplay()
	displayValue("Hyakuretsu LK : "..a(gameData.p1.hyakuretsu1, "b"), 315, 40, 0x00ff00ff)
	displayValue("Hyakuretsu MK : "..a(gameData.p1.hyakuretsu2, "b"), 315, 50, 0x00ff00ff)
	displayValue("Hyakuretsu HK : "..a(gameData.p1.hyakuretsu3, "b"), 315, 60, 0x00ff00ff)
	
	displayValue("Denjin : "..a(gameData.p1.denjin, "b"), 315, 70, 0xffff00ff)
	displayValue("Denjin2: "..a(gameData.p1.denjin2, "b"), 315, 80, 0xffff00ff)
	
	displayValue("Rotation1: "..sp(a(gameData.p1.rotation1, "b"), 3).." / "..sp(a(gameData.p1.rotationResetter1, "b"), 3), 300, 90, 0x00ffffff)
	displayValue("Rotation2: "..sp(a(gameData.p1.rotation2, "b"), 3).." / "..sp(a(gameData.p1.rotationResetter2, "b"), 3), 300, 100, 0x00ffffff)
	displayValue("Rotation3: "..sp(a(gameData.p1.rotation3, "b"), 3).." / "..sp(a(gameData.p1.rotationResetter3, "b"), 3), 300, 110, 0x00ffffff)
	
	displayValue("Charge1: "..sp(a(gameData.p1.charge1, "b"), 3).." / "..sp(a(gameData.p1.chargeResetter1, "b"), 3), 300, 120, 0x00ffffff)
	displayValue("Charge2: "..sp(a(gameData.p1.charge2, "b"), 3).." / "..sp(a(gameData.p1.chargeResetter2, "b"), 3), 300, 130, 0x00ffffff)
	displayValue("Charge3: "..sp(a(gameData.p1.charge3, "b"), 3).." / "..sp(a(gameData.p1.chargeResetter3, "b"), 3), 300, 140, 0x00ffffff)
	displayValue("Charge4: "..sp(a(gameData.p1.charge4, "b"), 3).." / "..sp(a(gameData.p1.chargeResetter4, "b"), 3), 300, 150, 0x00ffffff)
	displayValue("Charge5: "..sp(a(gameData.p1.charge5, "b"), 3).." / "..sp(a(gameData.p1.chargeResetter5, "b"), 3), 300, 160, 0x00ffffff)
	
	displayGauge("Charge 1", gameData.p1.charge1, gameData.p1.chargeResetter1, 2, 50)
	displayGauge("Charge 2", gameData.p1.charge2, gameData.p1.chargeResetter2, 2, 60)
	displayGauge("Charge 3", gameData.p1.charge3, gameData.p1.chargeResetter3, 2, 80)
	displayGauge("Charge 4", gameData.p1.charge4, gameData.p1.chargeResetter4, 2, 70)
	displayGauge("Charge 5", gameData.p1.charge5, gameData.p1.chargeResetter5, 2, 90)
	
	displayValue("P1 Attack : "..a(gameData.p1.attack, "b"), 2, 110, 0x55ff99ff)
	displayValue("P2 Attack : "..a(gameData.p2.attack, "b"), 2, 120, 0x55ff99ff)
	
	displayValue("_3fv_p2_stop : "..a(gameData.p1._3fv_p1_stop, "b").." / "..a(gameData.p2._3fv_p2_stop, "b"), 2, 140, 0x9955ffff)
	displayValue("_3fv_airTimer : "..a(gameData.game._3fv_airTimer, "b"), 2, 150, 0x9955ffff)
	displayValue("_3fv_airComboInf : "..a(gameData.game._3fv_airComboInf, "b"), 2, 160, 0x9955ffff)
	displayValue("mameCheatSemiInfiniteJuggle : "..a(gameData.p1.mameCheatSemiInfiniteJuggle, "b").." / "..a(gameData.p2.mameCheatSemiInfiniteJuggle, "b"), 2, 170, 0x9955ffff)
	displayValue("mameCheatTrueInfiniteJuggle : "..a(gameData.p1.mameCheatTrueInfiniteJuggle, "b").." / "..a(gameData.p1.mameCheatTrueInfiniteJuggle, "b"), 2, 180, 0x9955ffff)
	
	
	--cheat(gameData.p2.mameCheatSemiInfiniteJuggle, 0) -- force juggle count to 0...
	
	
	--displayGauge("Vert P", chars.q.charge_v, chars.q.timer_v, 2, 62)
	--displayGauge("V", chars.q.charge_v, chars.q.timer_v, 2, 74)
end