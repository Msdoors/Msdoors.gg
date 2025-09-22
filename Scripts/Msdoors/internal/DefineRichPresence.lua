local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local CACHE_PATH = "msdoors/cache/"
local TOKEN_FILE = CACHE_PATH .. "token.txt"

if not isfolder then
    function isfolder() return false end
    function makefolder() end
    function writefile() end
    function readfile() return "" end
    function delfile() end
    function isfile() return false end
end

do
    if not isfolder("msdoors") then makefolder("msdoors") end
    if not isfolder(CACHE_PATH) then makefolder(CACHE_PATH) end
end

local function getHttpMethod()
    if syn and syn.request then return syn.request
    elseif request then return request
    elseif http_request then return http_request
    elseif http and http.request then return http.request
    else
        return function()
            error("No HTTP method available in this executor")
        end
    end
end

local function createWebSocket(url)
    if WebSocket and WebSocket.connect then 
        return WebSocket.connect(url)
    elseif syn and syn.websocket and syn.websocket.connect then 
        return syn.websocket.connect(url)
    else
        error("No WebSocket support available in this executor")
    end
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
    self.request = getHttpMethod()
    self.activities = {}
    self.connected = false
    return self
end

function DiscordRPC:authenticate(token)
    if not token or type(token) ~= "string" or #token < 50 then
        return false, "Invalid token format"
    end
    
    local success, response = pcall(self.request, {
        Url = "https://discord.com/api/v10/users/@me",
        Method = "GET",
        Headers = {
            Authorization = token,
            ["Content-Type"] = "application/json"
        }
    })
    
    if not success then
        return false, "Request failed: " .. tostring(response)
    end
    
    if response.StatusCode ~= 200 then
        return false, "Authentication failed: " .. tostring(response.StatusCode)
    end
    
    local userData = HttpService:JSONDecode(response.Body)
    self.token = token
    self.user = userData
    
    if writefile then
        writefile(TOKEN_FILE, token)
    end
    
    return true, userData
end

function DiscordRPC:loadToken()
    if isfile and isfile(TOKEN_FILE) then
        local token = readfile(TOKEN_FILE)
        if token and #token > 0 then
            local success, user = self:authenticate(token)
            if success then 
                return true, user 
            end
            if delfile then delfile(TOKEN_FILE) end
        end
    end
    return false, "No cached token"
end

function DiscordRPC:connect()
    if not self.token then 
        return false, "No token set" 
    end
    
    local success, ws = pcall(createWebSocket, "wss://gateway.discord.gg/?v=10&encoding=json")
    if not success then 
        return false, "WebSocket creation failed: " .. tostring(ws)
    end
    
    self.ws = ws
    
    if ws.OnMessage then
        ws.OnMessage:Connect(function(message)
            self:handleMessage(message)
        end)
    end
    
    if ws.OnClose then
        ws.OnClose:Connect(function()
            self.connected = false
            if self.heartbeat_task then
                task.cancel(self.heartbeat_task)
                self.heartbeat_task = nil
            end
        end)
    end
    
    return true, "Connected"
end

function DiscordRPC:handleMessage(message)
    local success, data = pcall(HttpService.JSONDecode, HttpService, message)
    if not success then return end
    
    local op = data.op
    local payload = data.d
    
    if data.s then 
        self.sequence = data.s 
    end
    
    if op == 10 then
        self:identify()
        self:startHeartbeat(payload.heartbeat_interval)
        self.connected = true
    elseif op == 0 and data.t == "READY" then
        self.session_id = payload.session_id
    end
end

function DiscordRPC:identify()
    if not self.ws or not self.token then return end
    
    local payload = {
        op = 2,
        d = {
            token = self.token,
            properties = {
                ["$os"] = "windows",
                ["$browser"] = "chrome", 
                ["$device"] = "desktop"
            },
            compress = false,
            large_threshold = 50
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
    
    self.heartbeat_task = task.spawn(function()
        while self.ws and self.connected do
            task.wait(interval / 1000)
            if self.ws and self.ws.Send then
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
    if not self.ws or not self.connected then return false end
    
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
    if not config then return nil end
    
    local activity = {
        name = config.name or "Custom Activity",
        type = config.type or 0
    }
    
    if config.details then activity.details = config.details end
    if config.state then activity.state = config.state end
    if config.url then activity.url = config.url end
    
    if config.start_time or config.end_time then
        activity.timestamps = {}
        if config.start_time then activity.timestamps.start = config.start_time end
        if config.end_time then activity.timestamps.end = config.end_time end
    end
    
    if config.large_image or config.small_image then
        activity.assets = {}
        if config.large_image then
            activity.assets.large_image = config.large_image
            activity.assets.large_text = config.large_text or ""
        end
        if config.small_image then
            activity.assets.small_image = config.small_image
            activity.assets.small_text = config.small_text or ""
        end
    end
    
    if config.party_current and config.party_max then
        activity.party = {
            size = {config.party_current, config.party_max}
        }
    end
    
    if config.buttons and type(config.buttons) == "table" then
        activity.buttons = {}
        for i = 1, math.min(#config.buttons, 2) do
            local button = config.buttons[i]
            if button.label and button.url then
                table.insert(activity.buttons, {
                    label = button.label,
                    url = button.url
                })
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
        self.activities[id].timestamps = {}
        if start_time then self.activities[id].timestamps.start = start_time end
        if end_time then self.activities[id].timestamps.end = end_time end
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
    local start_time = math.floor((tick() - seconds) * 1000)
    self:setTimestamp(start_time, nil, id)
end

function DiscordRPC:addButton(label, url, id)
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

function DiscordRPC:setParty(current, max, id)
    id = id or "default"
    if self.activities[id] then
        self.activities[id].party = {size = {current, max}}
        self:refreshActivities()
    end
end

function DiscordRPC:refreshActivities()
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
    end
end

function DiscordRPC:turnOff()
    self:updatePresence({}, "invisible")
end

function DiscordRPC:turnOn()
    self:setUserStatus("online")
end

function DiscordRPC:reset()
    if self.heartbeat_task then
        task.cancel(self.heartbeat_task)
        self.heartbeat_task = nil
    end
    
    if self.ws then
        if self.ws.Close then self.ws:Close() end
        self.ws = nil
    end
    
    self.connected = false
    self.activities = {}
    self.sequence = nil
    self.session_id = nil
end

function DiscordRPC:destroy()
    self:reset()
    self.token = nil
    self.user = nil
    
    if delfile and isfile(TOKEN_FILE) then
        delfile(TOKEN_FILE)
    end
end

return DiscordRPC.new()