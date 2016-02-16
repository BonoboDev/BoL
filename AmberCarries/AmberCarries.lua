
--[[#########################################################################################################]]
--[[ class ScriptUdate: Download Scripts if client dont have it ]]

class 'ScriptUpdate'
class 'ScriptUpdateVersion'
class 'StartScript'

--[[#########################################################################################################]]
--[[ Check if Script Exist ]]

function ScriptUpdate:__init(UseHttps, Host, ScriptPath, SavePath, callbackUpdate, callbackError)
    self.Host = Host    
	self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
    self.SavePath = SavePath

    self.callbackUpdate = callbackUpdate
	self.callbackError = callbackError
	
    self:CreateSocket(self.ScriptPath)
    self.DownloadStatus = 'Connect to Server for ScriptDownload'
    AddTickCallback(function() self:DownloadUpdate() end)
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
            local f = io.open(self.SavePath,"w+b")
            f:write(newf)
            f:close()
            if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
                self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
            end
        end
        self.GotScriptUpdate = true
    end	
end

local useHttps = true
local Host = "raw.githubusercontent.com"
local scriptPath = "/AMBER17/BoL/master/AmberCarries/"
local savePath = SCRIPT_PATH .. "Common/AmberCarries/"
local CallbackUpdate = function() print("Updated") end
local CallbackError = function() print("Error") end

--[[#########################################################################################################]]
--[[ UpdateScript ]]

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

local isHere = SCRIPT_PATH.."/Common/AmberCarries/AmberCarries.lua"
function CheckUpdate()
    local ToUpdate = {}
    
    ToUpdate.Version = 0.2
    
    ToUpdate.Name = "AmberCarries"
    
    ToUpdate.Host = "raw.githubusercontent.com"
    
    ToUpdate.VersionPath = "/AMBER17/BoL/master/AmberCarries/AmberCarries.version"
    
    ToUpdate.ScriptPath =  "/AMBER17/BoL/master/AmberCarries/AmberCarries.lua"
    
    ToUpdate.SavePath = isHere
    
    ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) print("<font color=\"#F62459\"><b>[" .. ToUpdate.Name .. "] AutoUpdater - </font> <font color=\"#E08283\">Updated to "..NewVersion..". Please Reload with 2x F9</b></font>") end
    
    ToUpdate.CallbackNoUpdate = function() print("<font color=\"#F62459\"><b>[" .. ToUpdate.Name .. "] AutoUpdater - </font> <font color=\"#E08283\">No Updates Found</b></font>") StartScript() end
    
    ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#F62459\"><b>[" .. ToUpdate.Name .. "] AutoUpdater - </font> <font color=\"#E08283\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
    
    ToUpdate.CallbackError = function(NewVersion) print("<font color=\"#F62459\"><b>[" .. ToUpdate.Name .. "] AutoUpdater - </font> <font color=\"#E08283\">Error while Downloading. Please try again.</b></font>") end

    ScriptUpdateVersion(ToUpdate.Version,true, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
end

CheckUpdate()

--[[#########################################################################################################]]
--[[ Check if client got the Script in Local folder and launch the right Script ]]

function StartScript:__init()
    local spriteTable = 
        { 
            catchMe = { Name = "catchMe.jpg", Url = "http://i.imgur.com/QMvFelM.png" },
            executableGreen = { Name = "executableGreen.jpg", Url = "http://i.imgur.com/XDJsVGC.png"},
            executableRed ={ Name = "executableRed.png",Url = "http://i.imgur.com/vEolK8p.png" },
            gotIt = { Name = "gotIt.jpg",Url = "http://i.imgur.com/tfLIkoD.png" },
            targetGreen = { Name = "targetGreen.jpg",Url = "http://i.imgur.com/t0XsYK5.png" },
            targetRed = { Name = "targetRed.jpg",Url = "http://i.imgur.com/5cPNira.png" }
        }

    for uid, sprite in pairs(spriteTable) do
        if not FileExist(SPRITE_PATH .. "/AmberCarries/"..sprite.Name) then
            CreateDirectory(SPRITE_PATH .. "/AmberCarries")
            DownloadFile(sprite.Url.."?rand="..math.random(1,10000), SPRITE_PATH .. "/AmberCarries/"..sprite.Name, function() end)
            print("<font color=\"#F62459\"><b>[AmberCarries] - Download: </font><font color=\"#E08283\">"..sprite.Name.."</b></font>")
        end
    end 


    local scriptArray = 
        { 
            Vayne = { Name = "Vayne.lua", Url = "https://raw.githubusercontent.com/AMBER17/BoL/master/Vayne.lua" },
            Kalista = { Name = "Kalista.lua", Url = "https://raw.githubusercontent.com/AMBER17/BoL/master/Kalista.lua" },
            Twitch = { Name = "Twitch.lua", Url = "https://raw.githubusercontent.com/AMBER17/BoL/master/Twitch.lua" },
            Draven = { Name = "Draven.lua", Url = "https://raw.githubusercontent.com/AMBER17/BoL/master/Draven.lua"},
            KogMaw = { Name = "KogMaw.lua", Url = "https://raw.githubusercontent.com/AMBER17/BoL/master/KogMaw.lua"},
            Quinn = { Name = "Quinn.lua", Url = "https://raw.githubusercontent.com/AMBER17/BoL/master/Quinn.lua"},
            Lucian = { Name = "Lucian.lua", Url = "https://raw.githubusercontent.com/AMBER17/BoL/master/Lucian.lua" },
            CUtility = { Name = "CUtility.lua", Url = "https://raw.githubusercontent.com/AMBER17/BoL/master/CUtility.lua"}
        }

    for uid, script in pairs(scriptArray) do
        if not FileExist(SCRIPT_PATH .. "Common/AmberCarries/".. script.Name) then
            CreateDirectory(SCRIPT_PATH .. "Common/AmberCarries")
            ScriptUpdate(useHttps, Host , scriptPath..script.Name, savePath..script.Name, callbackUpdate, callbackError)
             print("<font color=\"#F62459\"><b>[AmberCarries] - Download: </font><font color=\"#E08283\">"..script.Name.."</b></font>")
        end
    end 

    if scriptArray and scriptArray[myHero.charName] ~= nil then
        local scriptToLoad = "AmberCarries/"..myHero.charName
        require(scriptToLoad)
    else
        print("<font color=\"#F62459\"><b>[AmberCarries] - </font><font color=\"#E08283\">Champion Not Supported</b></font>")
    end
end

--[[#########################################################################################################]]
--[[ End of Script ]]
