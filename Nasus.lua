class "Nasus"
require "VPrediction"

function Nasus:DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
    radius = radius or 300
    quality = math.max(8,self:round(180/math.deg((math.asin((chordlength/(2*radius)))))))
    quality = 2 * math.pi / quality
    radius = radius*.92
    local points = {}
    for theta = 0, 2 * math.pi + quality, quality do
        local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
        points[#points + 1] = D3DXVECTOR2(c.x, c.y)
    end
    DrawLines2(points, width or 1, color or 4294967295)
end

function Nasus:round(num) 

    if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
end

function Nasus:DrawCircle2(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
        self:DrawCircleNextLvl(x, y, z, radius, 2, color, 75) 
    end
end

function Nasus:__init()
	if not FileExist(SCRIPT_PATH .. "/Common/MenuConfig.lua") then
     	local url = "https://raw.githubusercontent.com/linkpad/BoL/master/Common/MenuConfig.lua"
        DownloadFile(url.."?rand="..math.random(1,10000), SCRIPT_PATH .. "/Common/MenuConfig.lua", function() end)
        print("<font color=\"#F62459\"><b>[AmberCarries] - Download: </font><font color=\"#E08283\">MenuConfig.lua</b></font>")
    end
    require "MenuConfig"

	self.qStack = 0
	self.lastSet = 0
	self.VP = VPrediction()
	self.TargetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, 650 , DAMAGE_PHYSICAL, false, true)

	self.jungleTable = minionManager(MINION_JUNGLE, myHero.range + 180, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.minionTable = minionManager(MINION_ENEMY, myHero.range + 180, myHero, MINION_SORT_MAXHEALTH_DEC)


	self:Menu()
	AddTickCallback(function() self:OnTick() end)
	AddDrawCallback(function() self:OnDraw() end)
end

function Nasus:Menu()
	self.Settings = MenuConfig("amberNasus", "Nasus")
		self.Settings:Menu("combo", "Combo Settings")
			self.Settings.combo:KeyBinding("active", "Combo Key", 32)
			self.Settings.combo:Boolean("useQ", "Use (Q)", true)
			self.Settings.combo:Boolean("useW", "Use (W)", true)
			self.Settings.combo:Boolean("useE", "Use (E)", true)

		self.Settings:Menu("laneclear", "Lane Clear Settings")
			self.Settings.laneclear:KeyBinding("active", "Lane Clear Key", GetKey("V"))
			self.Settings.laneclear:Boolean("useQ", "Use (Q)", true)
			self.Settings.laneclear:Boolean("useE", "Use (E)", true)
			self.Settings.laneclear:Slider("manaE", "Mana manager (> %)", 70, 0, 100, 5)
		self.Settings:Menu("jungleclear", "Jungle Clear Settings")
			self.Settings.jungleclear:KeyBinding("active", "Jungle Clear Key", GetKey("V"))
			self.Settings.jungleclear:Boolean("useQ", "Use (Q)", true)
			self.Settings.jungleclear:Boolean("useE", "Use (E)", true)
			self.Settings.jungleclear:Slider("manaE", "Mana manager (> %)", 70, 0, 100, 5)
		self.Settings:Menu("lasthit", "Last Hit Settings")
			self.Settings.lasthit:KeyBinding("active", "Last Hit Key", GetKey("X"))
			self.Settings.lasthit:Boolean("useQ", "Use (Q)", true)
		self.Settings:Menu("drawing", "Draw Settings")
			self.Settings.drawing:Boolean("Minion", "Draw Circle on Minion", true)
			self.Settings.drawing:Boolean("Target", "Draw Circle on Target", true)
			self.Settings.drawing:Boolean("Damage", "Draw (Q) Damage on Target", true)
end

function Nasus:OnDraw()
	if myHero.dead then return end
	if self.Settings.drawing.Minion then
		local lowestMinion = self:findLowestMinion(self.minionTable.objects)
		for uid, minion in pairs(self.minionTable.objects) do
			if lowestMinion ~= nil and lowestMinion.networkID ~= minion.networkID then 
				self:DrawCircle2(minion.x, minion.y, minion.z, 60, ARGB(180,255,0,0))
			elseif lowestMinion == nil then
				self:DrawCircle2(minion.x, minion.y, minion.z, 60, ARGB(180,255,0,0)) 
			end
		end
		if lowestMinion ~= nil then
			if lowestMinion.health <= self:qDmg(lowestMinion) then 
				self:DrawCircle2(lowestMinion.x, lowestMinion.y, lowestMinion.z, 60, ARGB(180,0,255,0))
			else
				self:DrawCircle2(lowestMinion.x, lowestMinion.y, lowestMinion.z, 60, ARGB(180,255,153,0))
			end 
		end
	end

	local unit = self.TargetSelector.target
	if self.Settings.drawing.Target and ValidTarget(unit) then
		self:DrawCircle2(self.TargetSelector.target.x, self.TargetSelector.target.y, self.TargetSelector.target.z, 100, ARGB(180,30,255,30))
		self:DrawCircle2(self.TargetSelector.target.x, self.TargetSelector.target.y, self.TargetSelector.target.z, 80, ARGB(180,30,255,30)) 
	end
	if self.Settings.drawing.Damage and ValidTarget(unit) then
		local Center = GetUnitHPBarPos(unit)
		if Center.x > -100 and Center.x < WINDOW_W+100 and Center.y > -100 and Center.y < WINDOW_H+100 then
		local off = GetUnitHPBarOffset(unit)
		local y=Center.y + (off.y * 53) + 2
		local xOff = ({['AniviaEgg'] = -0.1,['Darius'] = -0.05,['Renekton'] = -0.05,['Sion'] = -0.05,['Thresh'] = -0.03,})[unit.charName]
		local x = Center.x + ((xOff or 0) * 140) - 66
		dmg = unit.health - self:qDmg(unit)
		DrawLine(x + ((unit.health /unit.maxHealth) * 104),y, x+(((dmg > 0 and dmg or 0) / unit.maxHealth) * 104),y,9, GetDistance(unit) < 3000 and ARGB(180,205,173,0))
		end
	end
end

function Nasus:findLowestMinion(table)
	local hp = 50000
	local isMinion = nil
	for uid, minion in pairs(table) do
		if minion.health < hp then
			hp = minion.health
			isMinion = minion
		end
	end
	return isMinion
end

function Nasus:OnTick()
	self.TargetSelector:update()
	self.minionTable:update()
	self.jungleTable:update()

	self:SetqStack()
	self:LaneClear(self.Settings.laneclear.active)
	self:JungleClear(self.Settings.jungleclear.active)
	self:LastHit(self.Settings.lasthit.active)
	self:Combo(self.Settings.combo.active)
end

function Nasus:SetqStack()
	if os.clock() - self.lastSet < 1 then return end
	for i = 1, myHero.buffCount do
        local tBuff = myHero:getBuff(i)
        if BuffIsValid(tBuff) and tBuff.name == "NasusQStacks" then
           	self.qStack = tBuff.stacks
           	self.lastSet = os.clock()
        end
    end
end

function Nasus:Combo(isActive)
	if not isActive then return end
	
	local unit  = self.TargetSelector.target
	if ValidTarget(unit) then
		if self.Settings.combo.useQ then self:CastQ(unit) end
		if self.Settings.combo.useW then self:CastW(unit) end
		if self.Settings.combo.useE then self:CastE(unit) end
	end
end

function Nasus:CastQ(unit)
	if GetDistance(unit) <= myHero.range + 180 and myHero:CanUseSpell(0) == 0 then 
		CastSpell(_Q)
		myHero:Attack(unit)
	end
end

function Nasus:CastW(unit)
	if GetDistance(unit) <= 650 and myHero:CanUseSpell(1) == 0 then 
		CastSpell(_W, unit)
	end	
end

function Nasus:CastE(unit)
	if GetDistance(unit) <= 400 and myHero:CanUseSpell(2) == 0 then
		local CastPosition, HitChance = self.VP:GetPredictedPos(unit, 0.6, 2400, myHero, false)
		CastSpell(_E, CastPosition.x, CastPosition.z)
	end
end

function Nasus:LastHit(isActive)
	if not isActive then return end
	self.minionTable:update()
	self:qMinion(self.Settings.lasthit.useQ, self.minionTable.objects)
end

function Nasus:JungleClear(isActive)
	if not isActive then return end

	local minion = self.jungleTable.objects[1]
	self:qMinion(self.Settings.jungleclear.useQ, self.jungleTable.objects)
	if minion and myHero:CanUseSpell(2) == 0 and self.Settings.jungleclear.useE and myHero.mana*100/myHero.maxMana > self.Settings.jungleclear.manaE then CastSpell(_E, minion.x, minion.z) end
end

function Nasus:LaneClear(isActive)
	if not isActive then return end

	local minion = self.minionTable.objects[1]
	self:qMinion(self.Settings.laneclear.useQ, self.minionTable.objects)
	if minion and myHero:CanUseSpell(2) == 0 and self.Settings.laneclear.useE and myHero.mana*100/myHero.maxMana > self.Settings.laneclear.manaE then CastSpell(_E, minion.x, minion.z) end
end

function Nasus:qMinion(isActive,table)
	if myHero:CanUseSpell(0) ~= 0 or not isActive then return end
	for uid, minion in pairs(table) do
		if minion and self:qDmg(minion) > minion.health then
			CastSpell(_Q)
			myHero:Attack(minion)
		end
	end
end

function Nasus:qDmg(unit)
	if unit then
		local qDmg = { 30, 50, 70, 90, 110}
		local bonus = myHero.totalDamage
		local stack = self.qStack
		local dmg = qDmg[myHero:GetSpellData(0).level] + stack + bonus

		return myHero:CalcDamage(unit, dmg)
	end
end

Nasus()
