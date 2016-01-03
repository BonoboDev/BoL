if myHero.charName ~= "Leona" then return end

local  LeonaPutYourSunglasses_Version = 2.52



function AutoUpdate:__init(localVersion, host, versionPath, scriptPath, savePath, callbackUpdate, callbackNoUpdate, callbackNewVersion, callbackError)
	
	self.localVersion = localVersion
	self.versionPath = host .. versionPath
	self.scriptPath = host .. scriptPath
	self.savePath = savePath
	
	self.callbackUpdate = callbackUpdate
	self.callbackNoUpdate = callbackNoUpdate
	self.callbackNewVersion = callbackNewVersion
	
	self.callbackError = callbackError
	self:createSocket(self.versionPath)
	
	self.downloadStatus = 'Connect to Server for VersionInfo'
	
	AddTickCallback(function() self:getVersion() end)
end
--SSL LINE
function AutoUpdate:createSocket(url)
	
	if not self.LuaSocket then
	    self.LuaSocket = require("socket")
	else
	    self.socket:close()
	    self.socket = nil
	end
	
	self.LuaSocket = require("socket")
	self.socket = self.LuaSocket.tcp()
	self.socket:settimeout(0, 'b')
	
	self.socket:settimeout(99999999, 't')
	
	self.socket:connect("linkpad.fr", 80)
	
	self.url = "/aurora/TcpUpdater/getscript.php?page=" .. url
	
	self.started = false
	self.File = ''
end
--SSL LINE
function AutoUpdate:getVersion()
	if self.gotScriptVersion then return end
	
	local Receive, Status, Snipped = self.socket:receive(1024)
	if Status == 'timeout' and self.started == false then
		self.started = true
	    self.socket:send("GET ".. self.url .." HTTP/1.0\r\nHost: linkpad.fr\r\n\r\n")
	end
	
	if (Receive or (#Snipped > 0)) then
		self.File = self.File .. (Receive or Snipped)
	end
	
	if Status == "closed" then
		local _, ContentStart = self.File:find('<script'..'data>')
		local ContentEnd, _ = self.File:find('</script'..'data>')
		if not ContentStart or not ContentEnd then
		    self.callbackError()
		else
			self.onlineVersion = tonumber(self.File:sub(ContentStart + 1,ContentEnd-1))
			if self.onlineVersion > self.localVersion then
				self.callbackNewVersion(self.onlineVersion)
				self:createSocket(self.scriptPath)
				self.DownloadStatus = 'Connect to Server for ScriptDownload'
				AddTickCallback(function() self:downloadUpdate() end)

			elseif self.onlineVersion <= self.localVersion then
				self.callbackNoUpdate()
			end
		end
		
		self.gotScriptVersion = true

	end
end
--SSL LINE
function AutoUpdate:downloadUpdate()
	if self.gotScriptUpdate then return end

	local Receive, Status, Snipped = self.socket:receive(1024)
	if Status == 'timeout' and self.started == false then
		self.started = true
	    self.socket:send("GET ".. self.url .." HTTP/1.0\r\nHost: linkpad.fr\r\n\r\n")
	end
	if (Receive or (#Snipped > 0)) then
		self.File = self.File .. (Receive or Snipped)
	end
	if Status == "closed" then
		local _, ContentStart = self.File:find('<script'..'data>')
		local ContentEnd, _ = self.File:find('</script'..'data>')

		if not ContentStart or not ContentEnd then
		    self.callbackError()
		else
			self.File = self.File:sub(ContentStart + 1,ContentEnd-1)
			local f = io.open(self.savePath,"w+b")
			f:write(self.File)
			f:close()
			self.callbackUpdate(self.onlineVersion, self.localVersion)
		end
		self.gotScriptUpdate = true

	end
end

--https://raw.githubusercontent.com/AMBER17/BoL/master/Bundle.lua
local isHere = SCRIPT_PATH.."/" .. GetCurrentEnv().FILE_NAME
function checkUpdate()
	
	local ToUpdate = {}
	
	ToUpdate.Version = 2.52
	
	ToUpdate.Name = "Leona Put Your Sunglasses"
	
	ToUpdate.Host = "raw.githubusercontent.com"
	
	ToUpdate.VersionPath = "/AMBER17/BoL/master/LeonaPutYourSunglasses.version"
	
	ToUpdate.ScriptPath =  "/AMBER17/BoL/master/LeonaPutYourSunglasses.lua"
	
	ToUpdate.SavePath = LeonaPutYourSunglasses_Version
	
	ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) print("<font color=\"#FE2E64\"><b>[" .. ToUpdate.Name .. "] AutoUpdater - </b></font> <font color=\"#FA58D0\">Updated to "..NewVersion..". Please Reload with 2x F9</b></font>") end
	
	ToUpdate.CallbackNoUpdate = function() print("<font color=\"#FE2E64\"><b>[" .. ToUpdate.Name .. "] AutoUpdater - </b></font> <font color=\"#FA58D0\">No Updates Found</b></font>") end
	
	ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#FE2E64\"><b>[" .. ToUpdate.Name .. "] AutoUpdater - </b></font> <font color=\"#FA58D0\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
	
	ToUpdate.CallbackError = function(NewVersion) print("<font color=\"#FE2E64\"><b>[" .. ToUpdate.Name .. "] AutoUpdater - </b></font> <font color=\"#FA58D0\">Error while Downloading. Please try again.</b></font>") end
	--AutoUpdate(ToUpdate.Version, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)

	ScriptUpdate(ToUpdate.Version,true, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
end
--SSL LINE
function ScriptUpdate:__init(LocalVersion,UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
   
   self.LocalVersion = LocalVersion
    self.Host = Host
	
    self.VersionPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..VersionPath)..'&rand='..math.random(99999999)
    
	self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
    self.SavePath = SavePath
    self.CallbackUpdate = CallbackUpdate
    self.CallbackNoUpdate = CallbackNoUpdate
    self.CallbackNewVersion = CallbackNewVersion
	
    self.CallbackError = CallbackError
    AddDrawCallback(function() self:OnDraw() end)
	
    self:CreateSocket(self.VersionPath)
	
    self.DownloadStatus = 'Connect to Server for VersionInfo'
    AddTickCallback(function() self:GetOnlineVersion() end)
end
--SSL LINE
function ScriptUpdate:print(str)
	
    print('<font color="#FFFFFF">'..os.clock()..': '..str)
end

function ScriptUpdate:OnDraw()
	
    if self.DownloadStatus ~= 'Downloading Script (100%)' and self.DownloadStatus ~= 'Downloading VersionInfo (100%)'then
        DrawText('Download Status: '..(self.DownloadStatus or 'Unknown'),50,10,50,ARGB(0xFF,0xFF,0xFF,0xFF))
    end
end

function ScriptUpdate:CreateSocket(url)
	
    if not self.LuaSocket then
        self.LuaSocket = require("socket")
    else
        self.Socket:close()
        self.Socket = nil
        self.Size = nil
        self.RecvStarted = false
    end
	
    self.LuaSocket = require("socket")
	
    self.Socket = self.LuaSocket.tcp()
    self.Socket:settimeout(0, 'b')
	
    self.Socket:settimeout(99999999, 't')
	
    self.Socket:connect('sx-bol.eu', 80)
	
    self.Url = url
    self.Started = false
    self.LastPrint = ""
    self.File = ""
end

--SSL LINE
function ScriptUpdate:Base64Encode(data)
	
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
	
end

function ScriptUpdate:GetOnlineVersion()
    if self.GotScriptVersion then return end
	
    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading VersionInfo (0%)'
    end
	
    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</s'..'ize>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading VersionInfo ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
	
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading VersionInfo (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
		
        local HeaderEnd, ContentStart = self.File:find('<scr'..'ipt>')
        local ContentEnd, _ = self.File:find('</sc'..'ript>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            self.OnlineVersion = (Base64Decode(self.File:sub(ContentStart + 1,ContentEnd-1)))
            self.OnlineVersion = tonumber(self.OnlineVersion)
            if self.OnlineVersion > self.LocalVersion then
                if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
                    self.CallbackNewVersion(self.OnlineVersion,self.LocalVersion)
                end
                self:CreateSocket(self.ScriptPath)
                self.DownloadStatus = 'Connect to Server for ScriptDownload'
                AddTickCallback(function() self:DownloadUpdate() end)
            else
                if self.CallbackNoUpdate and type(self.CallbackNoUpdate) == 'function' then
                    self.CallbackNoUpdate(self.LocalVersion)
                end
            end
        end
        self.GotScriptVersion = true
    end
end
--SSL LINE
function ScriptUpdate:DownloadUpdate()
	
    if self.GotScriptUpdate then return end
	
    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
	
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading Script (0%)'
    end
	
    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</si'..'ze>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading Script (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
        local HeaderEnd, ContentStart = self.NewFile:find('<sc'..'ript>')
        local ContentEnd, _ = self.NewFile:find('</scr'..'ipt>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            local newf = self.NewFile:sub(ContentStart+1,ContentEnd-1)
            local newf = newf:gsub('\r','')
            if newf:len() ~= self.Size then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
                return
            end
            local newf = Base64Decode(newf)
            if type(load(newf)) ~= 'function' then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
            else
                local f = io.open(self.SavePath,"w+b")
                f:write(newf)
                f:close()
                if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
                    self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
                end
            end
        end
        self.GotScriptUpdate = true
    end
	
end



function OnLoad()
	
	print("<b><font color=\"#FF001E\"></font></b><font color=\"#FF980F\"> Have a Good Game </font><font color=\"#FF001E\">| AMBER |</font>")
	TargetSelector = TargetSelector(TARGET_MOST_AD, 1500, DAMAGE_MAGICAL, false, true)
	Variables()
	Menu()
	Target = GetCustomTarget()

end

function OnTick()
	
	Checks()
	TargetSelector:update()
	Target = GetCustomTarget()
	SxOrb:ForceTarget(Target)
	CastAutoR()
	
	if Target ~= nil then
		if Settings.combo.comboKey then
			Combo(Target)
		end
	end
	
end

function OnDraw()
	if not myHero.dead then	
		if ValidTarget(Target) then 
			DrawText3D("Current Target",Target.x-100, Target.y-50, Target.z, 20, 0xFFFFFF00)
			DrawCircle(Target.x, Target.y, Target.z, 150, ARGB(200,100 ,100,0 ))
		end
		
		if SkillE.ready and Settings.Draw.DrawE then 
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillE.range, ARGB(200,50 ,100,0 ))
		end
		if SkillW.ready and Settings.Draw.DrawZ then 
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillW.range, ARGB(200,50 ,100,0 ))
		end
		if SkillR.ready and Settings.Draw.DrawR then 
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillR.range, ARGB(200,50 ,100,0 ))
		end
	end
end


function Checks()
	SkillQ.ready = (myHero:CanUseSpell(_Q) == READY)
	SkillW.ready = (myHero:CanUseSpell(_W) == READY)
	SkillE.ready = (myHero:CanUseSpell(_E) == READY)
	SkillR.ready = (myHero:CanUseSpell(_R) == READY)

	_G.DrawCircle = _G.oldDrawCircle 
	 
	 
end

function Variables()

	SkillQ = { range = nil, delay = nil, speed = math.huge, width = nil, ready = false }
	SkillW = { range = 430, delay = nil, speed = math.huge, width = nil, ready = false }
	SkillE = { range = 875, delay = 0.2, speed = math.huge, width = 40, ready = false }
	SkillR = { range = 1100, delay = 0.625, speed = math.huge, width = 220, ready = false }
	
	
	VP = VPrediction()
	
	_G.oldDrawCircle = rawget(_G, 'DrawCircle')
	_G.DrawCircle = DrawCircle2	
	
end


function GetCustomTarget()
	if SelectedTarget ~= nil and ValidTarget(SelectedTarget, 1500) and (Ignore == nil or (Ignore.networkID ~= SelectedTarget.networkID)) then
		return SelectedTarget
	end
	TargetSelector:update()	
	if TargetSelector.target and not TargetSelector.target.dead and TargetSelector.target.type == myHero.type then
		return TargetSelector.target
	else
		return nil
	end
end


function OnWndMsg(Msg, Key)	
	
	if Msg == WM_LBUTTONDOWN then
		local minD = 0
		local Target = nil
		for i, unit in ipairs(GetEnemyHeroes()) do
			if ValidTarget(unit) then
				if GetDistance(unit, mousePos) <= minD or Target == nil then
					minD = GetDistance(unit, mousePos)
					Target = unit
				end
			end
		end

		if Target and minD < 115 then
			if SelectedTarget and Target.charName == SelectedTarget.charName then
				SelectedTarget = nil
			else
				SelectedTarget = Target
			end
		end
	end
	
end



function DrawCircle2(x, y, z, radius, color)

  local vPos1 = Vector(x, y, z)
  local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
  local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
  local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
  
end

function Combo(unit)
	
	if Settings.combo.UseE then
		CastE(unit)
	end
	if Settings.combo.UseZ then
		CastW(unit)
	end
	myHero:Attack(unit)
	if Settings.combo.UseQ then
		CastQ(unit)
	end
	myHero:Attack(unit)
	if Settings.combo.EngageR then
		CastR2(unit)
	end
	if Settings.combo.UseR then
		CastR1(unit)	
	end
	
end


function Menu()
Settings = scriptConfig("Leona Put Your Sunglasses", "AMBER")
	
	Settings:addSubMenu("["..myHero.charName.."] - Combo", "combo")
		Settings.combo:addParam("comboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		Settings.combo:addParam("UseQ", "Use (Q) ", SCRIPT_PARAM_ONOFF, true)
		Settings.combo:addParam("UseZ", "Use (Z) ", SCRIPT_PARAM_ONOFF, true)
		Settings.combo:addParam("UseE", "Use (E) ", SCRIPT_PARAM_ONOFF, true)
		Settings.combo:addParam("UseR", "Use (R) After (E)",SCRIPT_PARAM_ONOFF, true)
		Settings.combo:addParam("EngageR", "Use (R) For Engage",SCRIPT_PARAM_ONOFF, true)
	
	Settings:addSubMenu("["..myHero.charName.."] - Auto Ult ", "AutoUlt")
		Settings.AutoUlt:addParam("UseAutoR", "Auto R if X enemie", SCRIPT_PARAM_ONKEYTOGGLE, false, GetKey("V"))
		Settings.AutoUlt:addParam("ARX", "X = ", SCRIPT_PARAM_SLICE, 3, 1, 5, 0)
	
	Settings:addSubMenu("["..myHero.charName.."] - Draw", "Draw")
			Settings.Draw:addParam("DrawZ", "Draw (Z)", SCRIPT_PARAM_ONOFF, true)
			Settings.Draw:addParam("DrawE", "Draw (E)", SCRIPT_PARAM_ONOFF, true)
			Settings.Draw:addParam("DrawR", "Draw (R)", SCRIPT_PARAM_ONOFF, true)
		
	
		Settings.combo:permaShow("comboKey")
		Settings.combo:permaShow("UseR")
		Settings.combo:permaShow("EngageR")
		Settings.AutoUlt:permaShow("UseAutoR")
		Settings.AutoUlt:permaShow("ARX")
	
	Settings:addSubMenu("["..myHero.charName.."] - Orbwalking Settings", "Orbwalking")
		SxOrb:LoadToMenu(Settings.Orbwalking)
	
	TargetSelector.name = "Leona"
	Settings:addTS(TargetSelector)
end

function CastQ(unit)
	if unit ~= nil and GetDistance(unit) <= 300 and SkillQ.ready then
		Packet("S_CAST", {spellId = _Q}):send()
	end
end

function CastW(unit)
	if unit ~= nil and GetDistance(unit) <= SkillW.range and SkillW.ready then
		Packet("S_CAST", {spellId = _W}):send()
	end
end


function CastE(unit)
	if unit ~= nil and GetDistance(unit) <= SkillE.range and GetDistance(unit) > 300 and SkillE.ready then
		CastPosition,  HitChance,  Position = VP:GetLineCastPosition(unit, SkillE.delay, SkillE.width, SkillE.range, SkillE.speed, myHero, false)	
		
		if HitChance >= 2 then
			Packet("S_CAST", {spellId = _E, fromX = CastPosition.x, fromY = CastPosition.z, toX = CastPosition.x, toY = CastPosition.z}):send()
		end
	end
end

function CastR1(unit)
if Settings.combo.UseR then
	if unit ~= nil and GetDistance(unit) <= 300 and SkillR.ready then
		CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(unit, SkillR.delay, SkillR.width, SkillR.range, SkillR.speed, myHero, false)	
		if HitChance >= 2 then
			Packet("S_CAST", {spellId = _R, fromX = CastPosition.x, fromY = CastPosition.z, toX = CastPosition.x, toY = CastPosition.z}):send()
		end
	end
end
end

function CastR2(unit)
if Settings.combo.EngageR then
	if unit ~= nil and GetDistance(unit) <= SkillR.range and SkillR.ready then
		CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(unit, SkillR.delay, SkillR.width, SkillR.range, SkillR.speed, myHero, false)	
		if HitChance >= 2 then
			Packet("S_CAST", {spellId = _R, fromX = CastPosition.x, fromY = CastPosition.z, toX = CastPosition.x, toY = CastPosition.z}):send()
		end
	end
end
end

function CastAutoR()
if SkillR.ready then
if Settings.AutoUlt.UseAutoR then
	for _, unit in pairs(GetEnemyHeroes()) do
			local rPos, HitChance, maxHit, Positions = VP:GetCircularAOECastPosition(unit, SkillR.delay, SkillR.width, SkillR.range, SkillR.speed, myHero)
			if ValidTarget(unit, SkillR.range) and rPos ~= nil and maxHit >= Settings.AutoUlt.ARX then
					Packet("S_CAST", {spellId = _R, fromX = rPos.x, fromY = rPos.z, toX = rPos.x, toY = rPos.z}):send()
			end
		end
	end
end
end

assert(load(Base64Decode("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"), nil, "bt", _ENV))() ScriptStatus("XKNLLQONOSM") 
