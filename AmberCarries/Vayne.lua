class "WebRequestAmber"
class 'Vayne'
require "AmberCarries/CUtility"
class 'ScriptUpdateVersion'

--[[#########################################################################################################]]
--[[ UpdateScript ]]
local blockUpdate = false

function ScriptUpdateVersion:__init(LocalVersion,UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
   
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

function ScriptUpdateVersion:print(str)
    
    print('<font color="#FFFFFF">'..os.clock()..': '..str)
end

function ScriptUpdateVersion:OnDraw()
    
    if self.DownloadStatus ~= 'Downloading Script (100%)' and self.DownloadStatus ~= 'Downloading VersionInfo (100%)'then
        DrawText('Download Status: '..(self.DownloadStatus or 'Unknown'),50,10,50,ARGB(0xFF,0xFF,0xFF,0xFF))
    end
end

function ScriptUpdateVersion:CreateSocket(url)
    
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

function ScriptUpdateVersion:Base64Encode(data)
    
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

function ScriptUpdateVersion:GetOnlineVersion()
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

function ScriptUpdateVersion:DownloadUpdate()   
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

local isHere = SCRIPT_PATH.."/Common/AmberCarries/"..myHero.charName..".lua"
function checkUpdate()
    
    local ToUpdate = {}
    
    ToUpdate.Version = 0.2
    
    ToUpdate.Name = myHero.charName
    
    ToUpdate.Host = "raw.githubusercontent.com"
    
    ToUpdate.VersionPath = "/AMBER17/BoL/master/AmberCarries/"..myHero.charName..".version"
    
    ToUpdate.ScriptPath =  "/AMBER17/BoL/master/AmberCarries/"..myHero.charName..".lua"
    
    ToUpdate.SavePath = isHere
    
    ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) print("<font color=\"#FE2E64\"><b>[" .. ToUpdate.Name .. "] AutoUpdater - </b></font> <font color=\"#FA58D0\">Updated to "..NewVersion..". Please Reload with 2x F9</b></font>") blockUpdate = true end
    
    ToUpdate.CallbackNoUpdate = function() print("<font color=\"#FE2E64\"><b>[" .. ToUpdate.Name .. "] AutoUpdater - </b></font> <font color=\"#FA58D0\">No Updates Found</b></font>") WebRequestAmber() end
    
    ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#FE2E64\"><b>[" .. ToUpdate.Name .. "] AutoUpdater - </b></font> <font color=\"#FA58D0\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
    
    ToUpdate.CallbackError = function(NewVersion) print("<font color=\"#FE2E64\"><b>[" .. ToUpdate.Name .. "] AutoUpdater - </b></font> <font color=\"#FA58D0\">Error while Downloading. Please try again.</b></font>") end
    --AutoUpdate(ToUpdate.Version, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)

    ScriptUpdateVersion(ToUpdate.Version,true, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
end

checkUpdate()

--[[#########################################################################################################]]
--[[ Check Auth ]]

function WebRequestAmber:__init()
	math.randomseed(os.time())
	math.random(1,9)
	math.random(1,9)
	
	key = {math.random(1,9), math.random(1,9), math.random(1,9), math.random(1,9), math.random(1,9)}
	
	callbackLicense = function(data) self:CheckLicense(data, key) end 
	
	WebRequestAmber:fetch('/aurora/api.php?username='..Base64Encode(GetUser())..'&type=license2&value='.. key[1]..key[2]..key[3]..key[4]..key[5] ..'&script=1', callbackLicense)
	
	WebRequestAmber:get('/aurora/api.php?username='..Base64Encode(GetUser())..'&type=launch&script=1')
	
	print("<b><font color=\"#F62459\">[AmberCarries] - Auth</font> <font color=\"#E08283\"> Please wait... </font>")

	AddBugsplatCallback(function() self:bugsplat() end)
	AddExitCallback(function() self:OnUnload() end)
end

function WebRequestAmber:createSocket()
	self.LuaSocket = require("socket")
	self.Socket = self.LuaSocket.tcp()
    self.Socket:settimeout(0, 'b')
    self.Socket:settimeout(99999999, 't')
	self.Socket:connect("linkpad.fr", 80)
end

function WebRequestAmber:get(url)
	self.socket = require("socket")
	self.tcp = assert(self.socket.tcp())
	self.tcp:connect("linkpad.fr", 80)
	self.tcp:send("GET "..url.." HTTP/1.0\r\nHost: linkpad.fr\r\n\r\n")
	self.tcp:close()
end

function WebRequestAmber:fetch(url, callback)
	self:createSocket()
	self.url = url
	self.shouldFetch = true
	self.started = false
	self.File = ''
	self.callback = callback
	AddTickCallback(function() self:fetchData() end)
end

function WebRequestAmber:fetchData()
	if self.shouldFetch == true then
		local Receive, Status, Snipped = self.Socket:receive(1024)
		if Status == 'timeout' and self.started == false then
			self.started = true
		    self.Socket:send("GET "..self.url.." HTTP/1.0\r\nHost: linkpad.fr\r\n\r\n")
		end
		if (Receive or (#Snipped > 0)) then
			self.File = self.File .. (Receive or Snipped)
		end
		
		if Status == "closed" then
			local _, ContentStart = self.File:find('<data>')
			local ContentEnd, _ = self.File:find('</data>')
			if not ContentStart or not ContentEnd then
				self.callback('auth_error')
				-- self.socket:close()
				self.shouldFetch = false
			else
				self.callback(self.File:sub(ContentStart + 1,ContentEnd-1))
				-- self.Socket:close()
				self.shouldFetch = false
			end
		end
	end
end

function WebRequestAmber:decrypt(str, k)

  result = ""
  
  index = 1
  
  for i=1,#str do
    index = index > 5 and 1 or index
    result = result .. string.char((string.byte(string.sub(str,i,i))) - k[index])
    index = index + 1
  end
  
  return result
end

function WebRequestAmber:CheckLicense(data, key)

	data = self:decrypt(data, key)
	
	if data:find('license_ok') then
	
		print("<b><font color=\"#F62459\">[AmberCarries] - Auth</font> <font color=\"#E08283\"> Authed as "..GetUser().."</font>")
		
		securityAgainstNulledIOBitches = true
		
		self:customLoad()
		
	elseif data:find('auth_error') then
	
		print("<b><font color=\"#F62459\">[AmberCarries] - Auth</font> <font color=\"#E08283\"> Can't connect to the Auth server, Please reload the script.</font>")
		
	elseif data:find('license_error') then
	
		print("<b><font color=\"#F62459\">[AmberCarries] - Auth</font> <font color=\"#E08283\"> Your trial is expired.</font>")
		
	elseif data:find('trial') then
	
		print("<b><font color=\"#F62459\">[AmberCarries] - Auth</font> <font color=\"#E08283\"> "..data.."</font>")
		
		securityAgainstNulledIOBitches = true
		
		self:customLoad()
		
	else
	
		print("<b><font color=\"#F62459\">[AmberCarries] - Auth</font> <font color=\"#E08283\"> Can't connect to the Auth server, Please reload the script.</font>")
	end
end

function WebRequestAmber:customLoad()

	if not securityAgainstNulledIOBitches then return end
	
	print("<b><font color=\"#F62459\">[AmberCarries] - Auth</font> <font color=\"#E08283\"> The script is successfully loaded ! </font>")
	
	WebRequestAmber:get('/aurora/api.php?username='..Base64Encode(GetUser())..'&type=playing&value=true&script=2')
	
	AddBugsplatCallback(function() bugsplat() end)
	
	self:Start()
	
	local game_end = false
	local LastEndGameCheck = os.clock()
	if myHero.charName == "Quinn" or myHero.charName == "Kalista" or myHero.charName == "Vayne" or myHero.charName == "KogMaw" or myHero.charName == "Twitch" or myHero.charName == "Draven" then
		AddTickCallback(
		function()
			if os.clock() - LastEndGameCheck > 3 then
				LastEndGameCheck = os.clock()
				for i = 1, objManager.iCount, 1 do
					local object = objManager:getObject(i)
					if object ~= nil and object.type and type(object.type) == "string" and object.type == "obj_HQ" and object.health and type(object.health) == "number" and object.health == 0 and game_end == false then
						if object.team == myHero.team then
							
							WebRequestAmber:get('/aurora/api.php?username='..Base64Encode(GetUser())..'&type=loose&script=2')
							
							WebRequestAmber:get('/aurora/api.php?username='..Base64Encode(GetUser())..'&type=playing&value=false&script=2')
							
							game_end = true
						else
							
							print("<b><font color=\"#F62459\">[AmberCarries] - Auth</font> <font color=\"#E08283\"> Well Played ! I Hope It Was a Good Game </font>")
								
							WebRequestAmber:get('/aurora/api.php?username='..Base64Encode(GetUser())..'&type=win&script=2')
							
							WebRequestAmber:get('/aurora/api.php?username='..Base64Encode(GetUser())..'&type=playing&value=false&script=2')
							
							game_end = true
						end
					end
				end
			end	
		end)
	end
end

function WebRequestAmber:bugsplat()
	
	WebRequestAmber:get('/aurora/api.php?username='..Base64Encode(GetUser())..'&type=playing&value=false&script=1')
	
end

function WebRequestAmber:OnUnload()
	WebRequestAmber:get('/aurora/api.php?username='..Base64Encode(GetUser())..'&type=playing&value=false&script=1')
	
	print("<b><font color=\"#F62459\">[AmberCarries] - Auth</font> <font color=\"#E08283\"> Unloaded </font>")		
end

function WebRequestAmber:Start()
	Vayne()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------

function Vayne:__init()
	print("<font color=\"#F62459\"><b>[AmberCarries] - Vayne</font><font color=\"#E08283\"> is successfuly loaded </b></font>")
	
	self:Variable()
	self:myMenu()
	self:resetMenu()
	AddTickCallback(function() self:OnTick() end)
	AddCreateObjCallback(function(obj) self:CreateObj(obj) end)
	AddUpdateBuffCallback(function(unit,buff,stack) self:OnUpdateBuff(unit,buff,stack) end)
	AddProcessSpellCallback(function(unit,spell) self:OnProcessSpell(unit,spell) end)
	if AddProcessAttackCallback ~= nil then
		AddProcessAttackCallback(function(unit,spell) self:OnProcessSpell(unit,spell) end)
	end
	AddRemoveBuffCallback(function(unit,buff) self:OnRemoveBuff(unit,buff) end)
	AddDrawCallback(function() self:OnDraw() end)
end

function Vayne:resetMenu()
	for i, enemy in pairs(self.myEnemyTable) do 
		self.Settings.spell.E[enemy.charName] = true
	end
end

function Vayne:OnDraw()
	if not myHero.dead then
		if self.Settings.draw.wall then
			self.CUtility:DrawCircle2(7160, 51, 8808,80, self.color)
			self.CUtility:DrawCircle2(12060, 51, 4806,80, self.color)
			self.CUtility:DrawCircle2(5830, 51, 5592,80, self.color)
		end	
		if ValidTarget(self.Target) and self.Settings.draw.currentTarget  then 
			local StartPos, EndPos = self.CUtility:GetHPBarPos(self.Target)
			if GetDistance(self.Target) > 650 then
				self.Sprite_TargetRed:Draw(StartPos.x + 10, StartPos.y - 21, 0xFF)
			else
				self.Sprite_TargetGreen:Draw(StartPos.x + 10, StartPos.y - 21, 0xFF)
			end
		end
		if self.Spells.Q.Ready() and self.Settings.draw.drawQ then
			if self.Settings.draw.typeQ == 1 then
				self.CUtility:DrawCircle2(myHero.x, myHero.y, myHero.z, self.Spells.Q.Range, ARGB(125, 200 , 50 ,170))
			else
				self.CUtility:DrawCircle2(myHero.x, myHero.y, myHero.z, 550 + self.Spells.Q.Range, ARGB(125, 200 , 50 ,170))
			end
		end
		if self.Spells.E.Ready() and self.Settings.draw.drawE then
			self.CUtility:DrawCircle2(myHero.x, myHero.y, myHero.z, 700, ARGB(125, 200 , 50 ,170))
		end
		
		if self.Spells.E.Ready() and ValidTarget(self.Target,650) and self.Settings.draw.drawStunt then
			if self.Settings.spell.E.stuntChance == 1 then
				local vector, stunnable = self:isStunt(self.Target)
				if vector ~= nil then
					if stunnable then
						DrawLine3D(self.Target.pos.x, self.Target.pos.y,self.Target.pos.z, vector.x, vector.y ,vector.z,4, ARGB(125, 0, 255 , 0))
						self.CUtility:DrawCircle2(vector.x, vector.y, vector.z, 20, ARGB(125, 0, 255 , 0))
					else
						DrawLine3D(self.Target.pos.x, self.Target.pos.y,self.Target.pos.z, vector.x, vector.y ,vector.z, 4, ARGB(125, 255, 0 , 0))
						self.CUtility:DrawCircle2(vector.x, vector.y, vector.z, 20, ARGB(125, 255, 0 , 0))
					end		
				end
			else
				local vector, stunnable = self:isStunt(self.Target)
				local vector2, stunnable2 = self:isStunt2(self.Target)
				if vector ~= nil and vector2 ~= nil then
					if stunnable then
						DrawLine3D(self.Target.pos.x, self.Target.pos.y,self.Target.pos.z, vector.x, vector.y ,vector.z,4, ARGB(125, 0, 255 , 0))
						self.CUtility:DrawCircle2(vector.x, vector.y, vector.z, 20, ARGB(125, 0, 255 , 0))
					else
						DrawLine3D(self.Target.pos.x, self.Target.pos.y,self.Target.pos.z, vector.x, vector.y ,vector.z, 4, ARGB(125, 255, 0 , 0))
						self.CUtility:DrawCircle2(vector.x, vector.y, vector.z, 20, ARGB(125, 255, 0 , 0))
					end
					if stunnable2 then
						DrawLine3D(self.Target.pos.x, self.Target.pos.y,self.Target.pos.z, vector2.x, vector2.y ,vector2.z,4, ARGB(125, 0, 255 , 0))
						self.CUtility:DrawCircle2(vector2.x, vector2.y, vector2.z, 20, ARGB(125, 0, 255 , 0))
					else
						DrawLine3D(self.Target.pos.x, self.Target.pos.y,self.Target.pos.z, vector2.x, vector2.y ,vector2.z, 4, ARGB(125, 255, 0 , 0))
						self.CUtility:DrawCircle2(vector2.x, vector2.y, vector2.z, 20, ARGB(125, 255, 0 , 0))
					end
				end
			end
		end
		if self.Settings.draw.HP then
			for i, unit in pairs(self.myEnemyTable) do
				if ValidTarget(unit) and GetDistance(unit) <= 2000 then 
					local currentP = 0
					if self.Stacks[unit.networkID] ~= nil and self.Stacks[unit.networkID].stack then currentP = self.Stacks[unit.networkID].stack end
					local spells = ""
					if myHero:GetSpellData(_W).level >= 1 then
						if self.Spells.Q.Ready() then
							local dmg = (getDmg("AD", unit, myHero)* (2 - currentP)) + (getDmg("Q", unit, myHero)+getDmg("AD", unit, myHero)) + getDmg("W", unit, myHero)
							if currentP == 2 then
								spells = "Q + W"
							else
								spells = tostring(2 - currentP).."AA + Q + W"
							end
						else
							dmg = (getDmg("AD", unit, myHero)* (3 - currentP)) + getDmg("W", unit, myHero)
							spells = tostring(3 - currentP).."AA + W"
						end
					elseif self.Spells.Q.Ready() then
						dmg = getDmg("Q", unit, myHero)+getDmg("AD", unit, myHero)
						spells = "Q"
					end
					if dmg == nil then dmg = 0 end
					self.CUtility:DrawLineHPBar(dmg,spells, unit, true)
				end
			end	
		end
	end
end

function Vayne:Variable()
	self.CUtility = CUtility()
	self.Sprite_TargetGreen= createSprite(SPRITE_PATH .. "/AmberCarries/targetGreen.jpg")
	self.Sprite_TargetRed= createSprite(SPRITE_PATH .. "/AmberCarries/targetRed.jpg")
	self.color = ARGB(200,255,0,100)
	self.color2 = ARGB(200,255,0,100)
	self.blockNextE = false
	self.vPred = VPrediction()
	self.MinionManager = minionManager(MINION_ENEMY, myHero.range + myHero.boundingRadius, myHero, MINION_SORT_HEALTH_ASC)
	self.Spells = {
		Q = { Range = 400 , Width = 0.1, Delay = 0.1, Speed = math.huge, TS = 0, Ready = function() return myHero:CanUseSpell(0) == 0 end,},
		W = { TS = 0, Ready = function() return myHero:CanUseSpell(1) == 0 end,},
		E = { Range = 550, Width = nil, Delay = 0.1, Speed = math.huge, TS = 0, Ready = function() return myHero:CanUseSpell(2) == 0 end,},
		R = { Ready = function() return myHero:CanUseSpell(3) == 0 end,}
		}
	self.isUlti = false
	
	self.myEnemyTable = GetEnemyHeroes()
	
	self.Stacks = { }
	self.lastTarget = nil
	self.isInvisible = false
end

function Vayne:myMenu()
	
	self.Settings = scriptConfig("AmberCarries - Vayne", "AMBERVayne")
	self.Settings:addSubMenu("["..myHero.charName.."] - Combo Settings (SBTW)", "combo")
		self.Settings.combo:addParam("comboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		self.Settings.combo:addParam("useQ", "Use (Q) in combo", SCRIPT_PARAM_ONOFF, true)
		self.Settings.combo:addParam("useE", "Use (E) in combo", SCRIPT_PARAM_ONOFF, true)
		self.Settings.combo:addParam("useR", "Use (R) in combo", SCRIPT_PARAM_ONOFF, true)
		self.Settings.combo:permaShow("comboKey")
		

	self.Settings:addSubMenu("["..myHero.charName.."] - Wall Tumble Settings", "wall")
		self.Settings.wall:addParam("wallKey", "Wall Tumble Key", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("T"))

	self.Settings:addSubMenu("["..myHero.charName.."] - Harass Settings", "harass")
		self.Settings.harass:addParam("harassKey", "Harass Key", SCRIPT_PARAM_ONKEYDOWN, false, 67)	
		self.Settings.harass:addParam("useQ", "Use (Q) in Harass", SCRIPT_PARAM_ONOFF, true)
		self.Settings.harass:permaShow("harassKey")
	
	self.Settings:addSubMenu("["..myHero.charName.."] - Lane Clear Settings", "laneclear")
		self.Settings.laneclear:addParam("laneclearKey", "Lane Clear Key", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("V"))
		self.Settings.laneclear:addParam("useQ", "Use (Q) in Lane Clear", SCRIPT_PARAM_ONOFF, false)
		self.Settings.laneclear:addParam("mana", "If my mana > X%",SCRIPT_PARAM_SLICE, 80, 0, 100, 0)
		self.Settings.laneclear:permaShow("laneclearKey")
	
	self.Settings:addSubMenu("["..myHero.charName.."] - Spell Settings", "spell")
		self.Settings.spell:addSubMenu("(Q) Settings", "Q")
			self.Settings.spell.Q:addParam("type", "Use (Q) for:", SCRIPT_PARAM_LIST, 1 , { "Reset AA CD", "When Castable", "Proc W + Reset AA CD"})
			self.Settings.spell.Q:addParam("info", "",SCRIPT_PARAM_INFO, "")
			self.Settings.spell.Q:addParam("kite", "Use (Q) for Kite", SCRIPT_PARAM_ONOFF, true)
			self.Settings.spell.Q:addParam("range", "Max Range to Enemy for Kite",SCRIPT_PARAM_SLICE, 150, 0, 500, 0)
			self.Settings.spell.Q:addParam("info", "",SCRIPT_PARAM_INFO, "")
			self.Settings.spell.Q:addParam("force", "Force (Q) if unit not in AA Range", SCRIPT_PARAM_ONOFF, false)
			self.Settings.spell.Q:permaShow("type")

		self.Settings.spell:addSubMenu("(E) Settings", "E")
			self.Settings.spell.E:addParam("type", "Use (E) for:", SCRIPT_PARAM_LIST, 2 , { "Stun","Reset AA & Stun" })
			self.Settings.spell.E:addParam("stuntChance", "Stun Chance", SCRIPT_PARAM_SLICE, 2, 1, 2, 0)
			self.Settings.spell.E:addParam("info", "",SCRIPT_PARAM_INFO, "")
			self.Settings.spell.E:addParam("auto", "Auto Stun", SCRIPT_PARAM_ONOFF, false)
			self.Settings.spell.E:addParam("info", "",SCRIPT_PARAM_INFO, "")
			self.Settings.spell.E:addParam("Range", "Max Wall Range For Stunt",SCRIPT_PARAM_SLICE, 430, 100, 470, 0)
			self.Settings.spell.E:addParam("info", "",SCRIPT_PARAM_INFO, "")
			for i, enemy in pairs(self.myEnemyTable) do 
				self.Settings.spell.E:addParam(tostring(enemy.charName), "Use on: "..enemy.charName.."", SCRIPT_PARAM_ONOFF, true)
			end
			self.Settings.spell.E:permaShow("auto")
			
		self.Settings.spell:addSubMenu("(R) Settings", "R")
			self.Settings.spell.R:addParam("info", "Use (R) if:",SCRIPT_PARAM_INFO, "")
			self.Settings.spell.R:addParam("lifeE", "Target life < %", SCRIPT_PARAM_SLICE, 70, 0, 100, 0)
			self.Settings.spell.R:addParam("lifeMe", "My life > %", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
			self.Settings.spell.R:addParam("info", "", SCRIPT_PARAM_INFO, "")
			self.Settings.spell.R:addParam("countEnemie","Minimum Enemi in Range: ", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
			self.Settings.spell.R:addParam("rangeE","Range: ", SCRIPT_PARAM_SLICE, 2000, 0, 3000, 0)
			self.Settings.spell.R:addParam("countAlly","Minimum Ally in Range: ", SCRIPT_PARAM_SLICE, 2, 1, 4, 0)
			self.Settings.spell.R:addParam("rangeA","Range: ", SCRIPT_PARAM_SLICE, 2000, 0, 3000, 0)
			self.Settings.spell.R:addParam("info", "", SCRIPT_PARAM_INFO, "")
			self.Settings.spell.R:addParam("keep","Keep Invisibily", SCRIPT_PARAM_ONOFF, true)
			self.Settings.spell.R:addParam("keepType","Only if closest enemy", SCRIPT_PARAM_ONOFF, true)
			self.Settings.spell.R:addParam("keepRange","Range", SCRIPT_PARAM_SLICE, 220, 0, 400, 0)		
			self.Settings.spell.R:permaShow("keep")
			
			
		self.Settings:addSubMenu("["..myHero.charName.."] - Tower Dive Settings", "tower")
			self.Settings.tower:addParam("ally", "Only if Ally is under tower", SCRIPT_PARAM_ONOFF, true)
			self.Settings.tower:addParam("hp", "Force use if enemy HP < % ", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)
			self.Settings.tower:addParam("useQ", "Use (Q) for Tower Dive", SCRIPT_PARAM_ONOFF, true)
			
		self.Settings:addSubMenu("["..myHero.charName.."] - KillSteal Settings", "killsteal")
			self.Settings.killsteal:addParam("killsteal", "Use KillSteal", SCRIPT_PARAM_ONOFF, true)
			self.Settings.killsteal:addParam("UseE", "Use (E) in KillSteal", SCRIPT_PARAM_ONOFF, true)
		
		self.Settings:addSubMenu("["..myHero.charName.."] - Gap Closer Settings", "gabcloser")
			for i, enemy in pairs(self.myEnemyTable) do 
				local isUnit = enemy.charName
				for i, posdata in pairs(self.CUtility.GabCloserList) do
					local isTable = self.CUtility.GabCloserList[i]
					if isTable.charName == isUnit then
						self.Settings.gabcloser:addParam(tostring(isUnit), ""..tostring(isUnit).." - Spell: "..isTable.spellName.."", SCRIPT_PARAM_ONOFF, true)
					end
				end
			end
		
		self.Settings:addSubMenu("["..myHero.charName.."] - Interupte Spell Settings", "interupt")
			for i, enemy in pairs(self.myEnemyTable) do 
				local isUnit = enemy.charName
				for i, posdata in pairs(self.CUtility.InteruptionSpells) do
					local isTable = self.CUtility.InteruptionSpells[i]
					if isTable.charName == isUnit then
						self.Settings.interupt:addParam(tostring(isUnit), ""..tostring(isUnit).." - Spell: "..isTable.spellName.."", SCRIPT_PARAM_ONOFF, true)
					end
				end
			end
		
	self.Settings:addSubMenu("["..myHero.charName.."] - Draw Settings ", "draw")
		self.Settings.draw:addParam("drawQ","Draw (Q) Range",SCRIPT_PARAM_ONOFF, true)
		self.Settings.draw:addParam("typeQ", "Draw (Q) type: ", SCRIPT_PARAM_LIST, 1 , { "Q","Q+AA" })
		self.Settings.draw:addParam("info", "",SCRIPT_PARAM_INFO, "")
		self.Settings.draw:addParam("drawE","Draw (E) Range",SCRIPT_PARAM_ONOFF, true)
		self.Settings.draw:addParam("currentTarget","Draw Sprite on Target",SCRIPT_PARAM_ONOFF, true)
		self.Settings.draw:addParam("info", "",SCRIPT_PARAM_INFO, "")
		self.Settings.draw:addParam("drawStunt","Draw (E) Predict on unit",SCRIPT_PARAM_ONOFF, true)
		self.Settings.draw:addParam("info", "",SCRIPT_PARAM_INFO, "")
		self.Settings.draw:addParam("HP","Draw Damage",SCRIPT_PARAM_ONOFF, true)
		self.Settings.draw:addParam("info", "",SCRIPT_PARAM_INFO, "")
		self.Settings.draw:addParam("wall","Draw WallTumble Circle",SCRIPT_PARAM_ONOFF, true)
end

function Vayne:OnProcessSpell(unit,spell) 
	if unit and spell and unit.isMe and spell.name:lower():find("attack") then self.lastTarget = spell.target end
	if self.Spells.E.Ready() and GetDistance(unit) <= self.Spells.E.Range  then
		if self.Settings.gabcloser[unit.charName] == true then
			if self.CUtility:UseAntiGabCloser(spell) then CastSpell(_E, unit) end
		end		
		if self.Settings.interupt[unit.charName] == true then
			if self.CUtility:UseInterruptSpell(spell, unit) then CastSpell(_E,unit) end
		end
	end
end

function Vayne:CreateObj(obj)
	if obj and obj.spellOwner == myHero and obj.name:lower():find("missile") then	
		if self.comboKey and self.Target then
			local vector,stunnable = self:isStunt(self.Target)
			local vector2, stunnable2 = self:isStunt2(self.Target)
			if self.Spells.E.Ready() and self.Settings.combo.useE and self.Settings.spell.E.type == 2 and ValidTarget(self.Target,600) and ((self.Settings.spell.E.stuntChance == 1 and stunnable) or (self.Settings.spell.E.stuntChance == 2 and stunnable and stunnable2)) then
				CastSpell(_E, self.Target)
			elseif self.Spells.Q.Ready() and self.Settings.combo.useQ and self.Settings.spell.Q.type == 1 and ValidTarget(self.Target) then
				CastSpell(_Q,mousePos.x,mousePos.z) 
			elseif self.Spells.Q.Ready() and self.Settings.combo.useQ and self.Settings.spell.Q.type == 3 and self.lastTarget and self.lastTarget.type == myHero.type then
				if self.Stacks[self.lastTarget.networkID] and self.Stacks[self.lastTarget.networkID].stack == 1 then
					CastSpell(_Q,mousePos.x,mousePos.z) 
				end
			end
		elseif self.harassKey and self.Target then
			if self.Spells.Q.Ready() and self.Settings.harass.useQ and ValidTarget(self.Target, 550 +self.Spells.Q.Range) and self.lastTarget.type == myHero.type then
				if  self.Settings.spell.Q.type == 1 then 
					CastSpell(_Q,mousePos.x,mousePos.z)
				elseif self.Settings.spell.Q.type == 3 then
					if self.Stacks[self.lastTarget.networkID] and self.Stacks[self.lastTarget.networkID].stack == 1 then
						CastSpell(_Q,mousePos.x,mousePos.z) 
					end
				end
			end
		elseif self.laneclearKey then
			if self.Spells.Q.Ready() and self.Settings.laneclear.useQ then
				self.MinionManager:update()
				local m = self.MinionManager.objects[1]
				if ValidTarget(m) and (myHero.mana*100)/myHero.maxMana > self.Settings.laneclear.mana then
					CastSpell(_Q ,mousePos.x,mousePos.z)
				end
			end
		end
	end
end

function Vayne:OnUpdateBuff(unit,buff,stack)

	if buff and unit and not unit.isMe and unit.type == myHero.type and buff.name == "vaynesilvereddebuff" then
		self.Stacks[unit.networkID] = {
			unit = unit,
			stack = stack,
			lastS = os.clock()
		}
	end
	if buff and unit and unit.isMe and buff.name == "VayneInquisition" then
		self.isUlti = true
	end
	if buff and unit and unit.isMe and self.isUlti and buff.name == "vaynetumblefade" then
		self.isInvisible = true
	end
end

function Vayne:OnRemoveBuff(unit,buff)
	if buff and unit and not unit.isMe and buff.name == "vaynesilvereddebuff" then
		self.Stacks[unit.networkID] = nil
	end
	if buff and unit and unit.isMe and buff.name == "VayneInquisition" then
		self.isUlti = false
	end
	if buff and unit and unit.isMe and buff.name == "vaynetumblefade" then
		self.isInvisible = false
	end
end

function Vayne:OnTick()
	self.Target = self.CUtility:GetOrbwalkerTarget()
	self.comboKey = self.Settings.combo.comboKey 
	self.harassKey = self.Settings.harass.harassKey
	self.laneclearKey = self.Settings.laneclear.laneclearKey
	self:ClosestCheck(self.Target)
	self:Combo(self.Target,self.comboKey)
	self.CUtility:CastItem(self.Target,self.comboKey)
	self:WallTumble(self.Settings.wall.wallKey)
	self:KillSteal(self.Settings.killsteal.killsteal)
	self:autoStunt()
	self:CheckPassif()
end

function Vayne:CheckPassif()
	for uid, data in pairs(self.Stacks) do
		if data.lastS and os.clock() - data.lastS > 2.9 then
			self.Stacks[data.unit.networkID] = nil
		end
	end
end

function Vayne:WallTumble(isActive)
	if not isActive then return end
	if GetDistance(D3DXVECTOR3(7160,51,8808)) <= 200 then
		self.color = ARGB(255,0,255,0)
		myHero:MoveTo(7160,8808)
		if GetDistance(D3DXVECTOR3(7160,51,8808)) <= 6 and self.Spells.Q.Ready() then
			 CastSpell(_Q,6769,8576)
		end
	elseif GetDistance(D3DXVECTOR3(12060,51,4806)) <= 200 and self.Spells.Q.Ready() then
		myHero:MoveTo(12060,4806)
		self.color2 = ARGB(255,0,255,0)
		if GetDistance(D3DXVECTOR3(12060,51,4806)) <= 6 then	
			CastSpell(_Q,11745,4625)
		end
	elseif GetDistance(D3DXVECTOR3(5830,51,5592)) <= 200 and self.Spells.Q.Ready() then
		myHero:MoveTo(5830,5592)
		self.color2 = ARGB(255,0,255,0)
		if GetDistance(D3DXVECTOR3(5830,51,5592)) <= 6 then	
			CastSpell(_Q,6053,5320)
		end
	else
		self.color = ARGB(200,255,0,100)
		self.color2 = ARGB(200,255,0,100)
		myHero:MoveTo(mousePos.x,mousePos.z)
	end
end

function Vayne:ClosestCheck(unit)
	if ValidTarget(unit) and self.isUlti and self.isInvisible then
		if self.Settings.spell.R.keepType then
			if GetDistance(unit) <= self.Settings.spell.R.keepRange then 
				myHero:MoveTo(mousePos.x,mousePos.z)
				self.CUtility:DisableAttack()
			else
				self.CUtility:EnableAttack()
			end
		elseif self.Settings.spell.R.keep then
			myHero:MoveTo(mousePos.x,mousePos.z)
			self.CUtility:DisableAttack()
		end
	else
		self.CUtility:EnableAttack()
	end
end

function Vayne:KillSteal(isActive)
	if not isActive then return end
	for i, enemy in pairs(self.myEnemyTable) do 
		if GetDistance(enemy) <= 550 and ValidTarget(enemy) then
			local data = self.Stacks[enemy.networkID]
			local dmg = 0
			if self.Settings.killsteal.UseE and self.Spells.E.Ready() then
				if data and data.stack == 2 then
					dmg = (getDmg("E", enemy, myHero) + getDmg("W", enemy, myHero)) * 0.95
				else
					dmg = getDmg("E", enemy, myHero) * 0.95
				end
				if enemy.health <= dmg then 
					CastSpell(_E, enemy)
				end
			end
		end
	end
end

function Vayne:autoStunt()
	if self.Spells.E.Ready() and self.Settings.spell.auto then
		for i, enemy in pairs(self.myEnemyTable) do 
			if self.Settings.spell.E[enemy] and GetDistance(enemy) <= 550 and ValidTarget(enemy) then
				self:CastE(enemy)
			end
		end
	end
end

function Vayne:isStunt(unit)
	if ValidTarget(unit) and self.Settings.spell.E[unit.charName] then
		local TargetDashing, CanHit, Position = self.vPred:IsDashing(unit, 0.4, 4, 40000, myHero)
		if TargetDashing then return end
		local CastPosition, HitChance = self.vPred:GetPredictedPos(unit, 0.1, 2400, myHero, false)
		for i = 0, self.Settings.spell.E.Range , 20 do
			local myVector = Vector(CastPosition) + Vector(Vector(CastPosition) - Vector(myHero)):normalized()*i
			if IsWall(D3DXVECTOR3(myVector.x,myVector.y,myVector.z)) then 
				return myVector, true
			end
		end
		local vector = Vector(CastPosition) + Vector(Vector(CastPosition) - Vector(myHero)):normalized()*self.Settings.spell.E.Range
		return vector, false
	end
end

function Vayne:isStunt2(unit)
	if ValidTarget(unit) and self.Settings.spell.E[unit.charName] then
		local TargetDashing, CanHit, Position = self.vPred:IsDashing(unit, 0.4, 4, 40000, myHero)
		if TargetDashing then return end
		for i = 0, self.Settings.spell.E.Range , 20 do
			local myVector = Vector(unit) + Vector(Vector(unit) - Vector(myHero)):normalized()*i
			if IsWall(D3DXVECTOR3(myVector.x,myVector.y,myVector.z)) then 
				return myVector, true
			end
		end
		local vector = Vector(unit) + Vector(Vector(unit) - Vector(myHero)):normalized()*self.Settings.spell.E.Range
		return vector, false
	end
end

function Vayne:Combo(unit, isActive)
	if not isActive then return end
	if ValidTarget(unit) then
		if not self.isUlti then
			if self.Settings.combo.useQ then self:CastQ(unit) end
			if self.Settings.combo.useE and self.Settings.spell.E.type == 1 then self:CastE(unit) end	
			if self.Settings.combo.useR then self:CastR(unit) end
		else
			if self.Settings.combo.useQ then self:CastQ(unit) end
			if self.Settings.combo.useE and not self.isInvisible and self.Settings.spell.E.type == 1 then self:CastE(unit) end	
		end
	end
end

function Vayne:CastE(unit)
	if GetDistance(unit) <= 710 and self.Settings.spell.E.type == 1 then
		if self.Settings.spell.E.stuntChance == 1 then
			local vector,stunnable = self:isStunt(unit)
			if stunnable then CastSpell(_E, unit) end
		else
			local vector,stunnable = self:isStunt(unit)
			local vector2, stunnable2 = self:isStunt2(unit)
			if stunnable and stunnable2 then CastSpell(_E, unit) end
		end
	end
end

function Vayne:CastQ(unit)
	if self.Spells.Q.Ready() then
		if self:useSpell(mousePos) then
			if self.Settings.spell.Q.type == 2 then
				CastSpell(_Q, mousePos.x, mousePos.z)
			end
			if self.Settings.spell.Q.force and GetDistance(unit) > 600 and GetDistance(unit) < 850 then
				CastSpell(_Q, mousePos.x, mousePos.z)
			elseif self.Settings.spell.Q.kite and GetDistance(unit) <= self.Settings.spell.Q.range then
				CastSpell(_Q, mousePos.x, mousePos.z)
			end
		end
	end
end

function Vayne:CastR(unit)
	if self.Spells.R.Ready() then
		if self.Settings.spell.R.lifeE > ((unit.health * 100) / unit.maxHealth ) and self.Settings.spell.R.lifeMe < ((myHero.health * 100) / myHero.maxHealth ) then 
			if self.CUtility:CountEnemyHeroInRange(self.Settings.spell.R.rangeE) >= self.Settings.spell.R.countEnemie then
				if self.CUtility:CountAllyHeroInRange(self.Settings.spell.R.rangeA) >= self.Settings.spell.R.countAlly then
					CastSpell(_R)
				end
			end
		end
	end
end

function Vayne:useSpell(position)
	if self.CUtility:isUnderTurret(position, enemyTurret) then
		if (self.Settings.tower.ally and self.CUtility:isUnderTurret(self.CUtility:GetAlly(), enemyTurret)) or (self.Settings.tower.hp >= ((self.Target.health * 100) / self.Target.maxHealth )) then
			return true
		else
			return false
		end
	else
		return true
	end
end
