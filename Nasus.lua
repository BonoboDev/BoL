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

	self.jungleTable = minionManager(MINION_JUNGLE, myHero.range + 160, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.minionTable = minionManager(MINION_ENEMY, myHero.range + 160, myHero, MINION_SORT_MAXHEALTH_DEC)


	self:Menu()
	AddTickCallback(function() self:OnTick() end)
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
end

function Nasus:OnTick()
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
	self.TargetSelector:update()
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
	self.jungleTable:update()
	local minion = self.jungleTable.objects[1]
	self:qMinion(self.Settings.jungleclear.useQ, self.jungleTable.objects)
	if minion and myHero:CanUseSpell(2) == 0 and self.Settings.jungleclear.useE and myHero.mana*100/myHero.maxMana > self.Settings.jungleclear.manaE then CastSpell(_E, minion.x, minion.z) end
end

function Nasus:LaneClear(isActive)
	if not isActive then return end
	self.minionTable:update()
	local minion = self.minionTable.objects[1]
	self:qMinion(self.Settings.laneclear.useQ, self.minionTable.objects)
	if minion and myHero:CanUseSpell(2) == 0 and self.Settings.laneclear.useE and myHero.mana*100/myHero.maxMana > self.Settings.laneclear.manaE then CastSpell(_E, minion.x, minion.z) end
end

function Nasus:qMinion(isActive,table)
	if myHero:CanUseSpell(0) ~= 0 or not isActive then return end
	for uid, minion in pairs(table) do
		if minion and self:qDmg(minion) < minion.health then return end
		CastSpell(_Q)
		myHero:Attack(minion)
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
