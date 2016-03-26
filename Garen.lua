if myHero.charName ~= "Garen" then return end

class "Garen"


function Garen:DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
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

function Garen:round(num) 

    if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
end

function Garen:DrawCircle2(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
        self:DrawCircleNextLvl(x, y, z, radius, 2, color, 75) 
    end
end

function Garen:__init()
	if not FileExist(SCRIPT_PATH .. "/Common/MenuConfig.lua") then
     	local url = "https://raw.githubusercontent.com/linkpad/BoL/master/Common/MenuConfig.lua"
        DownloadFile(url.."?rand="..math.random(1,10000), SCRIPT_PATH .. "/Common/MenuConfig.lua", function() end)
        print("<font color=\"#F62459\"><b>[AmberCarries] - Download: </font><font color=\"#E08283\">MenuConfig.lua</b></font>")
    end
    require "MenuConfig"

    print("<b><font color=\"#F62459\">Garen - Demacia</font> <font color=\"#E08283\">Loaded</font>")
	self.TargetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, 500 , DAMAGE_PHYSICAL, false, true)
	self.jungleTable = minionManager(MINION_JUNGLE, myHero.range + 185, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.minionTable = minionManager(MINION_ENEMY, myHero.range + 185, myHero, MINION_SORT_MAXHEALTH_DEC)

	self.Victim = nil
	self.isQ = false
	self.isE = false

	self:Menu()
	AddTickCallback(function() self:OnTick() end)
	AddDrawCallback(function() self:OnDraw() end)
	AddUpdateBuffCallback(function(...) self:OnUpdateBuff(...) end)
	AddProcessAttackCallback(function(...) self:OnProcessAttack(...) end)
	AddProcessSpellCallback(function(...) self:OnProcessAttack(...) end)
	AddRemoveBuffCallback(function(...) self:OnRemoveBuff(...) end)
end

function Garen:Menu()
	self.Settings = MenuConfig("amberGaren", "Garen - Demacia")
		self.Settings:Section("Fight")
		self.Settings:Menu("combo", "Combo Settings")
			self.Settings.combo:Section("Key")
			self.Settings.combo:KeyBinding("active", "Combo Key", 32)
			self.Settings.combo:Section("Settings")
			self.Settings.combo:Boolean("useQ", "Use (Q)", true)
			self.Settings.combo:Boolean("useW", "Use (W)", true)
			self.Settings.combo:Boolean("useE", "Use (E)", true)
			self.Settings.combo:Boolean("useR", "Use (R)", true)
		self.Settings:Section("Farm")
		self.Settings:Menu("laneclear", "Lane Clear Settings")
			self.Settings.laneclear:Section("Key")
			self.Settings.laneclear:KeyBinding("active", "Lane Clear Key", GetKey("V"))
			self.Settings.laneclear:Section("Settings")
			self.Settings.laneclear:Boolean("useQ", "Use (Q)", false)
			self.Settings.laneclear:Boolean("useE", "Use (E)", true)
		self.Settings:Menu("jungleclear", "Jungle Clear Settings")
			self.Settings.jungleclear:Section("Key")
			self.Settings.jungleclear:KeyBinding("active", "Jungle Clear Key", GetKey("V"))
			self.Settings.jungleclear:Section("Settings")
			self.Settings.jungleclear:Boolean("useQ", "Use (Q)", true)
			self.Settings.jungleclear:Boolean("useE", "Use (E)", true)
		self.Settings:Section("Other")
		self.Settings:Menu("killsteal", "killsteal Settings")
			self.Settings.killsteal:Section("Settings")
			self.Settings.killsteal:Boolean("autoR", "Use Auto (R)", true)
		self.Settings:Menu("misc", "Misc Settings")
			self.Settings.misc:Boolean("autoW", "Auto (W) when Attacked", true)
			self.Settings.misc:Boolean("autoQ", "Auto (Q) when slow", true)
		self.Settings:Menu("drawing", "Draw Settings")
			self.Settings.drawing:Section("Enemy")
			self.Settings.drawing:Boolean("target", "Draw Circle on target", true)
			self.Settings.drawing:Boolean("damage", "Draw Damage on target", true)
			self.Settings.drawing:Section("My Hero")
			self.Settings.drawing:Boolean("eRange", "Draw (E) Range", true)
			self.Settings.drawing:Boolean("rRange", "Draw (R) Range", true)
		self.Settings:Section("Info")
            self.Settings:Info("Author: AMBER - Aurora Scripters")
            self.Settings:Info("Version: 1.0")
end

function Garen:OnDraw()
	if myHero.dead then return end

	if self.Settings.drawing.eRange and myHero:CanUseSpell(2) == 0 then self:DrawCircle2(myHero.x, myHero.y, myHero.z, 325, ARGB(180,255,255,51)) end
	if self.Settings.drawing.rRange and myHero:CanUseSpell(3) == 0 then self:DrawCircle2(myHero.x, myHero.y, myHero.z, 500, ARGB(180,255,153,51)) end

	local unit = self.TargetSelector.target
	if ValidTarget(unit) and self.Settings.drawing.target then 
		self:DrawCircle2(unit.x, unit.y, unit.z, 100, ARGB(180,30,255,30))
		self:DrawCircle2(unit.x,unit.y, unit.z, 80, ARGB(180,30,255,30)) 
	end

	if self.Settings.drawing.damage then
		for uid, enemy in pairs(GetEnemyHeroes()) do
			if not ValidTarget(enemy) then return end
			local Center = GetUnitHPBarPos(enemy)
			if Center.x > -100 and Center.x < WINDOW_W+100 and Center.y > -100 and Center.y < WINDOW_H+100 then
				local off = GetUnitHPBarOffset(enemy)
				local y=Center.y + (off.y * 53) + 2
				local xOff = ({['AniviaEgg'] = -0.1,['Darius'] = -0.05,['Renekton'] = -0.05,['Sion'] = -0.05,['Thresh'] = -0.03,})[enemy.charName]
				local x = Center.x + ((xOff or 0) * 140) - 66
				dmg = enemy.health - self:rDmg(enemy)
				DrawLine(x + ((enemy.health /enemy.maxHealth) * 104),y, x+(((dmg > 0 and dmg or 0) / enemy.maxHealth) * 104),y,9, ARGB(180,255,102,255))
			end
		end
	end
end

function Garen:OnProcessAttack(unit,spell)

	if self.Settings.misc.autoW and unit and spell and unit.type == myHero.type and spell.target and spell.target.isMe then CastSpell(_W) end
end

function Garen:OnUpdateBuff(unit,buff,stack)
	if unit and buff and unit.team ~= myHero.team and buff.name == "garenpassiveenemytarget" then self.Victime = unit end
	if unit and buff and unit.isMe and buff.name == "GarenE" then self.isE = true end
	if unit and buff and unit.isMe and buff.name == "GarenQ" then self.isQ = true end

	if self.Settings.misc.autoQ and unit and buff and unit.isMe and buff.type == 10 then CastSpell(_Q) end
end

function Garen:OnRemoveBuff(unit,buff)
	if unit and buff and unit.team ~= myHero.team and buff.name == "garenpassiveenemytarget" then self.Victime = nil end
	if unit and buff and unit.isMe and buff.name == "GarenE" then self.isE = false end
	if unit and buff and unit.isMe and buff.name == "GarenQ" then self.isQ = false end
end

function Garen:OnTick()
	self:UpdateVictim()
	self.TargetSelector:update()
	self.minionTable:update()
	self.jungleTable:update()

	self:LaneClear(self.Settings.laneclear.active)
	self:JungleClear(self.Settings.jungleclear.active)

	self:Combo(self.Settings.combo.active)
	self:AutoR(self.Settings.killsteal.autoR)

	self:CheckEOrb()
end

function Garen:CheckEOrb()
	if self.isE then
		if _G.AutoCarry and _G.Reborn_Loaded ~= nil then
			_G.AutoCarry.MyHero:AttacksEnabled(false)
	    elseif (_G.MMA_Loaded or _G.MMA_IsLoaded) then
	    	_G.MMA_StopAttacks(true)
	    elseif _Pewalk ~= nil then
	    	_Pewalk.AllowAttack(false)
	    elseif _G.SxOrb then
			_G.SxOrb:DisableAttacks()
	    end
	else
		if _G.AutoCarry and _G.Reborn_Loaded ~= nil then
			_G.AutoCarry.MyHero:AttacksEnabled(true)
	    elseif (_G.MMA_Loaded or _G.MMA_IsLoaded) then
	    	 _G.MMA_StopAttacks(false)
	    elseif _Pewalk ~= nil then
	    	_Pewalk.AllowAttack(true)
	    elseif _G.SxOrb then
			_G.SxOrb:EnableAttacks()
	    end
	end
end

function Garen:UpdateVictim()
	for uid, enemy in pairs(GetEnemyHeroes()) do
	    for i = 1, myHero.buffCount do
	        local tBuff = enemy:getBuff(i)
	        if BuffIsValid(tBuff) and tBuff.name == "garenpassiveenemytarget" then
	        	self.Victim = enemy
	        end
	    end
	end
end

function Garen:checkOrbwalker()
	if self.isE then
		self:DisableAttack()
	else
		self:EnableAttack()
	end
end

function Garen:AutoR(isActive)
	if not isActive then return end
	
	for uid, enemy in pairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then self:CastR(enemy) end
	end
end

function Garen:Combo(isActive)
	if not isActive then return end
	
	local unit  = self.TargetSelector.target

	if ValidTarget(unit) then
		if self.Settings.combo.useQ then self:CastQ(unit) end
		if self.Settings.combo.useW then self:CastW(unit) end
		if self.Settings.combo.useE then self:CastE(unit) end
		if self.Settings.combo.useR then self:CastR(unit) end
	end
end

function Garen:CastQ(unit)
	if myHero:CanUseSpell(_Q) ~= 0 and not self.isE then return end
	CastSpell(_Q)
end

function Garen:CastW(unit)
 	if GetDistance(unit) <= 200 or myHero:CanUseSpell(_W) ~= 0 then return end
	CastSpell(_W)
end

function Garen:CastE(unit)
	if myHero:CanUseSpell(_E) ~= 0 then return end
	if GetDistance(unit) <= 300 and not self.isQ and not self.isE then CastSpell(_E) end
end

function Garen:CastR(unit)
	if myHero:CanUseSpell(_R) ~= 0 then return end
	if GetDistance(unit) <= 400 and self:rDmg(unit) >= unit.health then CastSpell(_R,unit) end
end

function Garen:JungleClear(isActive)
	if not isActive then return end

	local minion = self.jungleTable.objects[1]
	if not minion then return end
	if self.Settings.jungleclear.useQ then self:CastQ(minion) end
	if self.Settings.jungleclear.useE then self:CastE(minion) end
end

function Garen:LaneClear(isActive)
	if not isActive then return end

	local minion = self.minionTable.objects[1]
	if not minion then return end
	if self.Settings.laneclear.useQ then self:CastQ(minion) end
	if self.Settings.laneclear.useE then self:CastE(minion) end
end

function Garen:rDmg(unit)
	if myHero:CanUseSpell(3) ~= 0 then return 0 end

	local basicDmg = { 175, 350, 525}
	local bonusDmgArray = { 0.28, 0.33, 0.40 }
	local bonusDmg = (unit.maxHealth - unit.health) * bonusDmgArray[myHero:GetSpellData(3).level]
	local dmg = basicDmg[myHero:GetSpellData(3).level] + bonusDmg

	if self.Victim and self.Victim.networkID == unit.networkID then return dmg
	else return myHero:CalcMagicDamage(unit, dmg) end
end

Garen()
