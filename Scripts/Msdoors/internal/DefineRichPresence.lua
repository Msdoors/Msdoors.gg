local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local CACHE_PATH = "msdoors/cache/"
local TOKEN_FILE = CACHE_PATH .. "token.txt"

local GATEWAY_URLS = {
    "wss://gateway.discord.gg/?v=10&encoding=json",
    "wss://gateway-us-east1-b.discord.gg/?v=10&encoding=json",
    "wss://gateway-us-west1-a.discord.gg/?v=10&encoding=json"
}

local function setupFileSystem()
    local fs = {}
    if isfolder and makefolder and writefile and readfile and delfile and isfile then
        fs.isfolder = isfolder
        fs.makefolder = makefolder
        fs.writefile = writefile
        fs.readfile = readfile
        fs.delfile = delfile
        fs.isfile = isfile
        fs.available = true
    else
        fs.isfolder = function() return false end
        fs.makefolder = function() end
        fs.writefile = function() end
        fs.readfile = function() return "" end
        fs.delfile = function() end
        fs.isfile = function() return false end
        fs.available = false
        warn("File system functions not available - token caching disabled")
    end
    return fs
end

local fs = setupFileSystem()

if fs.available then
    pcall(function()
        if not fs.isfolder("msdoors") then fs.makefolder("msdoors") end
        if not fs.isfolder(CACHE_PATH) then fs.makefolder(CACHE_PATH) end
    end)
end

local function getRequestFunction()
    if syn and syn.request then
        return syn.request
    elseif request then
        return request
    elseif http_request then
        return http_request
    elseif http and http.request then
        return http.request
    elseif HttpService and HttpService.RequestAsync then
        return function(options)
            local success, result = pcall(HttpService.RequestAsync, HttpService, options)
            if success then
                return {StatusCode = result.StatusCode, Body = result.Body}
            else
                return {StatusCode = 0, Body = ""}
            end
        end
    else
        error("No HTTP method available")
    end
end

local function getWebSocketFunction()
    if WebSocket and WebSocket.connect then
        return WebSocket.connect
    elseif syn and syn.websocket and syn.websocket.connect then
        return syn.websocket.connect
    elseif websocket and websocket.connect then
        return websocket.connect
    else
        error("No WebSocket support available")
    end
end

local function validateToken(token)
    if not token or type(token) ~= "string" then
        return false
    end
    
    if #token < 50 then
        return false
    end
    
    if not token:match("^[A-Za-z0-9._%-]+$") then
        return false
    end
    
    return true
end

local DiscordRPC = {}
DiscordRPC.__index = DiscordRPC

function DiscordRPC.new()
    local self = setmetatable({}, DiscordRPC)
    self.token = nil
    self.user = nil
    self.ws = nil
    self.heartbeat_task = nil
    self.sequence = nil
    self.session_id = nil
    self.activities = {}
    self.connected = false
    self.reconnect_attempts = 0
    self.max_reconnect_attempts = 3
    self.connection_timeout = 10
    self.last_heartbeat = 0
    
    local success1, req = pcall(getRequestFunction)
    if not success1 then
        error("Failed to initialize HTTP: " .. tostring(req))
    end
    self.request = req
    
    local success2, ws_func = pcall(getWebSocketFunction)
    if not success2 then
        error("Failed to initialize WebSocket: " .. tostring(ws_func))
    end
    self.websocket_connect = ws_func
    
    return self
end

function DiscordRPC:authenticate(token)
    if not validateToken(token) then
        return false, "Invalid token format"
    end
    
    if not self.request then
        return false, "HTTP not available"
    end
    
    local auth_header = token:sub(1, 3) == "Bot" and token or ("Bot " .. token)
    
    local success, response = pcall(function()
        return self.request({
            Url = "https://discord.com/api/v10/users/@me",
            Method = "GET",
            Headers = {
                Authorization = auth_header,
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "DiscordBot (Custom, 1.0.0)"
            }
        })
    end)
    
    if not success then
        return false, "Network error: " .. tostring(response)
    end
    
    if response.StatusCode == 401 then
        return false, "Invalid token - Unauthorized"
    elseif response.StatusCode == 429 then
        return false, "Rate limited - Try again later"
    elseif response.StatusCode ~= 200 then
        return false, "HTTP " .. response.StatusCode
    end
    
    local decode_success, user_data = pcall(HttpService.JSONDecode, HttpService, response.Body)
    if not decode_success then
        return false, "Invalid response format"
    end
    
    self.user = user_data
    self.token = auth_header
    
    if fs.available then
        pcall(fs.writefile, TOKEN_FILE, token)
    end
    
    return true, self.user
end

function DiscordRPC:loadToken()
    if not fs.available or not fs.isfile(TOKEN_FILE) then
        return false, "No cached token"
    end
    
    local token = fs.readfile(TOKEN_FILE)
    if not token or #token == 0 then
        return false, "Empty token file"
    end
    
    local success, user = self:authenticate(token)
    if success then 
        return true, user 
    end
    
    pcall(fs.delfile, TOKEN_FILE)
    return false, "Cached token invalid"
end

function DiscordRPC:connect()
    if not self.token then 
        return false, "No token available" 
    end
    
    if not self.websocket_connect then
        return false, "WebSocket not available"
    end
    
    for i, gateway_url in ipairs(GATEWAY_URLS) do
        local success, ws = pcall(function()
            return self.websocket_connect(gateway_url)
        end)
        
        if success and ws then
            self.ws = ws
            self.reconnect_attempts = 0
            
            if ws.OnMessage then
                ws.OnMessage:Connect(function(msg) 
                    self:handleMessage(msg) 
                end)
            end
            
            if ws.OnClose then
                ws.OnClose:Connect(function(code) 
                    self.connected = false
                    if self.heartbeat_task then 
                        task.cancel(self.heartbeat_task) 
                        self.heartbeat_task = nil
                    end
                    
                    if code ~= 1000 and self.reconnect_attempts < self.max_reconnect_attempts then
                        task.wait(2 ^ self.reconnect_attempts)
                        self.reconnect_attempts = self.reconnect_attempts + 1
                        self:connect()
                    end
                end)
            end
            
            return true, "Connected to gateway " .. i
        end
    end
    
    return false, "All gateway connections failed"
end

function DiscordRPC:handleMessage(message)
    local success, data = pcall(HttpService.JSONDecode, HttpService, message)
    if not success or not data then 
        return 
    end
    
    if data.s then 
        self.sequence = data.s 
    end
    
    if data.op == 10 then
        self:identify()
        if data.d and data.d.heartbeat_interval then
            self:startHeartbeat(data.d.heartbeat_interval)
            self.connected = true
        end
    elseif data.op == 0 and data.t == "READY" then
        if data.d and data.d.session_id then
            self.session_id = data.d.session_id
        end
    elseif data.op == 11 then
        self.last_heartbeat = tick()
    elseif data.op == 9 then
        self.connected = false
        if self.ws and self.ws.Close then
            self.ws:Close()
        end
    end
end

function DiscordRPC:identify()
    if not self.ws or not self.token then 
        return 
    end
    
    local payload = {
        op = 2,
        d = {
            token = self.token,
            properties = {
                ["$os"] = "windows",
                ["$browser"] = "roblox",
                ["$device"] = "desktop"
            },
            compress = false,
            large_threshold = 50,
            intents = 0
        }
    }
    
    local success, encoded = pcall(HttpService.JSONEncode, HttpService, payload)
    if success and self.ws.Send then 
        self.ws:Send(encoded) 
    end
end

function DiscordRPC:startHeartbeat(interval)
    if self.heartbeat_task then 
        task.cancel(self.heartbeat_task) 
    end
    
    local interval_seconds = math.max(interval / 1000, 1)
    self.last_heartbeat = tick()
    
    self.heartbeat_task = task.spawn(function()
        while self.ws and self.connected do
            task.wait(interval_seconds)
            
            if not self.ws or not self.connected then
                break
            end
            
            if tick() - self.last_heartbeat > interval_seconds * 2 then
                self.connected = false
                if self.ws and self.ws.Close then
                    self.ws:Close()
                end
                break
            end
            
            if self.ws.Send then
                local heartbeat = {op = 1, d = self.sequence}
                local success, encoded = pcall(HttpService.JSONEncode, HttpService, heartbeat)
                if success then 
                    self.ws:Send(encoded) 
                end
            end
        end
    end)
end

function DiscordRPC:updatePresence(activities, status)
    if not self.ws or not self.connected then 
        return false 
    end
    
    local presence = {
        op = 3,
        d = {
            since = nil,
            activities = activities or {},
            status = status or "online",
            afk = false
        }
    }
    
    local success, encoded = pcall(HttpService.JSONEncode, HttpService, presence)
    if success and self.ws.Send then
        self.ws:Send(encoded)
        return true
    end
    return false
end

function DiscordRPC:setActivity(config)
    if not config or type(config) ~= "table" then 
        return nil 
    end
    
    local activity = {
        name = config.name or "Custom Activity",
        type = config.type or 0
    }
    
    if config.details and type(config.details) == "string" and #config.details <= 128 then
        activity.details = config.details
    end
    
    if config.state and type(config.state) == "string" and #config.state <= 128 then
        activity.state = config.state
    end
    
    if config.url and type(config.url) == "string" then
        activity.url = config.url
    end
    
    if config.start_time or config.end_time then
        activity.timestamps = {}
        if config.start_time and type(config.start_time) == "number" then
            activity.timestamps.start = math.floor(config.start_time)
        end
        if config.end_time and type(config.end_time) == "number" then
            activity.timestamps.end = math.floor(config.end_time)
        end
    end
    
    if config.large_image or config.small_image then
        activity.assets = {}
        if config.large_image then
            activity.assets.large_image = config.large_image
            if config.large_text and #config.large_text <= 128 then
                activity.assets.large_text = config.large_text
            end
        end
        if config.small_image then
            activity.assets.small_image = config.small_image
            if config.small_text and #config.small_text <= 128 then
                activity.assets.small_text = config.small_text
            end
        end
    end
    
    if config.party_current and config.party_max and 
       type(config.party_current) == "number" and type(config.party_max) == "number" and
       config.party_current > 0 and config.party_max > 0 and config.party_current <= config.party_max then
        activity.party = {size = {config.party_current, config.party_max}}
    end
    
    if config.buttons and type(config.buttons) == "table" then
        activity.buttons = {}
        for i = 1, math.min(#config.buttons, 2) do
            local button = config.buttons[i]
            if button and button.label and button.url and 
               type(button.label) == "string" and type(button.url) == "string" and
               #button.label <= 32 and button.url:match("^https?://") then
                table.insert(activity.buttons, {label = button.label, url = button.url})
            end
        end
    end
    
    local id = config.id or "default"
    self.activities[id] = activity
    
    local activities = {}
    for _, act in pairs(self.activities) do 
        table.insert(activities, act) 
    end
    
    self:updatePresence(activities)
    return activity
end

function DiscordRPC:setStatus(details, state, large_image, large_text, small_image, small_text)
    return self:setActivity({
        details = details,
        state = state,
        large_image = large_image,
        large_text = large_text,
        small_image = small_image,
        small_text = small_text
    })
end

function DiscordRPC:setImage(image_url, text, size)
    if not image_url then return nil end
    
    size = size or "large"
    local config = {details = "Custom Activity"}
    
    if size == "large" then
        config.large_image = image_url
        config.large_text = text
    else
        config.small_image = image_url
        config.small_text = text
    end
    
    return self:setActivity(config)
end

function DiscordRPC:setTimestamp(start_time, end_time, id)
    id = id or "default"
    if self.activities[id] then
        if start_time or end_time then
            self.activities[id].timestamps = {}
            if start_time then 
                self.activities[id].timestamps.start = math.floor(start_time)
            end
            if end_time then 
                self.activities[id].timestamps.end = math.floor(end_time)
            end
        else
            self.activities[id].timestamps = nil
        end
        self:refreshActivities()
    end
end

function DiscordRPC:setStartTime(timestamp, id)
    self:setTimestamp(timestamp, nil, id)
end

function DiscordRPC:setEndTime(timestamp, id)
    self:setTimestamp(nil, timestamp, id)
end

function DiscordRPC:setElapsedTime(seconds, id)
    if not seconds or seconds < 0 then return end
    local start_time = math.floor((tick() - seconds) * 1000)
    self:setTimestamp(start_time, nil, id)
end

function DiscordRPC:setRemainingTime(seconds, id)
    if not seconds or seconds < 0 then return end
    local end_time = math.floor((tick() + seconds) * 1000)
    self:setTimestamp(nil, end_time, id)
end

function DiscordRPC:addButton(label, url, id)
    if not label or not url or #label > 32 or not url:match("^https?://") then
        return
    end
    
    id = id or "default"
    if self.activities[id] then
        self.activities[id].buttons = self.activities[id].buttons or {}
        table.insert(self.activities[id].buttons, {label = label, url = url})
        if #self.activities[id].buttons > 2 then 
            table.remove(self.activities[id].buttons, 1) 
        end
        self:refreshActivities()
    end
end

function DiscordRPC:removeButton(index, id)
    id = id or "default"
    if self.activities[id] and self.activities[id].buttons then
        table.remove(self.activities[id].buttons, index or 1)
        if #self.activities[id].buttons == 0 then
            self.activities[id].buttons = nil
        end
        self:refreshActivities()
    end
end

function DiscordRPC:clearButtons(id)
    id = id or "default"
    if self.activities[id] then
        self.activities[id].buttons = nil
        self:refreshActivities()
    end
end

function DiscordRPC:setParty(current, max, id)
    if not current or not max or current < 1 or max < 1 or current > max then
        return
    end
    
    id = id or "default"
    if self.activities[id] then
        self.activities[id].party = {size = {current, max}}
        self:refreshActivities()
    end
end

function DiscordRPC:removeParty(id)
    id = id or "default"
    if self.activities[id] then
        self.activities[id].party = nil
        self:refreshActivities()
    end
end

function DiscordRPC:refreshActivities()
    if not self.connected then
        return
    end
    
    local activities = {}
    for _, activity in pairs(self.activities) do 
        table.insert(activities, activity) 
    end
    self:updatePresence(activities)
end

function DiscordRPC:getActivity(id)
    return self.activities[id or "default"]
end

function DiscordRPC:removeActivity(id)
    self.activities[id or "default"] = nil
    self:refreshActivities()
end

function DiscordRPC:clearActivities()
    self.activities = {}
    self:updatePresence({})
end

function DiscordRPC:setUserStatus(status)
    local validStatuses = {online = true, idle = true, dnd = true, invisible = true}
    if validStatuses[status] then
        local activities = {}
        for _, activity in pairs(self.activities) do 
            table.insert(activities, activity) 
        end
        self:updatePresence(activities, status)
        return true
    end
    return false
end

function DiscordRPC:turnOff()
    return self:updatePresence({}, "invisible")
end

function DiscordRPC:turnOn()
    return self:setUserStatus("online")
end

function DiscordRPC:isConnected()
    return self.connected and self.ws ~= nil
end

function DiscordRPC:getConnectionInfo()
    return {
        connected = self.connected,
        user = self.user,
        session_id = self.session_id,
        activities_count = #self.activities,
        last_heartbeat = self.last_heartbeat
    }
end

function DiscordRPC:reset()
    if self.heartbeat_task then
        task.cancel(self.heartbeat_task)
        self.heartbeat_task = nil
    end
    
    if self.ws then
        if self.ws.Close then 
            self.ws:Close() 
        end
        self.ws = nil
    end
    
    self.connected = false
    self.activities = {}
    self.sequence = nil
    self.session_id = nil
    self.reconnect_attempts = 0
end

function DiscordRPC:destroy()
    self:reset()
    self.token = nil
    self.user = nil
    
    if fs.available and fs.isfile(TOKEN_FILE) then 
        pcall(fs.delfile, TOKEN_FILE) 
    end
end

return DiscordRPC.new()