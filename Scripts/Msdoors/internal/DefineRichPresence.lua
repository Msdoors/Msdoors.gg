local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local CACHE_PATH = "msdoors/cache/"
local TOKEN_FILE = CACHE_PATH .. "token.txt"
local TEMPLATES_FILE = CACHE_PATH .. "templates.json"
local CONFIG_FILE = CACHE_PATH .. "config.json"

local function ensureDirectories()
    if not isfolder("msdoors") then makefolder("msdoors") end
    if not isfolder(CACHE_PATH) then makefolder(CACHE_PATH) end
end

local function getHttpMethod()
    if syn and syn.request then return syn.request
    elseif http and http.request then return http.request
    elseif http_request then return http_request
    elseif request then return request
    else error("No HTTP method available") end
end

local function createWebSocket(url)
    if WebSocket and WebSocket.connect then return WebSocket.connect(url)
    elseif syn and syn.websocket and syn.websocket.connect then return syn.websocket.connect(url)
    else error("No WebSocket support available") end
end

local DiscordRPC = {}
DiscordRPC.__index = DiscordRPC

function DiscordRPC.new()
    ensureDirectories()
    return setmetatable({
        token = nil,
        user = nil,
        ws = nil,
        heartbeat = nil,
        sequence = nil,
        session_id = nil,
        resume_url = nil,
        request = getHttpMethod(),
        activities = {},
        templates = {},
        config = {
            auto_reconnect = true,
            heartbeat_ack = true,
            debug = false
        },
        connections = {},
        start_time = tick(),
        presence_history = {}
    }, DiscordRPC)
end

function DiscordRPC:log(message, level)
    if self.config.debug then
        print(string.format("[DiscordRPC] [%s] %s", level or "INFO", message))
    end
end

function DiscordRPC:authenticate(token)
    if not token or type(token) ~= "string" or #token < 50 then
        return false, "Invalid token format"
    end
    
    self:log("Authenticating with Discord API...")
    local success, response = pcall(self.request, {
        Url = "https://discord.com/api/v10/users/@me",
        Method = "GET",
        Headers = {
            Authorization = token,
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "DiscordBot (https://github.com/discord/discord-api-docs, 1.0.0)"
        }
    })
    
    if not success or response.StatusCode ~= 200 then
        self:log("Authentication failed: " .. tostring(response and response.StatusCode or "Network error"), "ERROR")
        return false, "Authentication failed"
    end
    
    local userData = HttpService:JSONDecode(response.Body)
    self.token = token
    self.user = userData
    
    writefile(TOKEN_FILE, token)
    self:log("Authenticated as " .. userData.username .. "#" .. userData.discriminator)
    return true, userData
end

function DiscordRPC:loadToken()
    if isfile(TOKEN_FILE) then
        local token = readfile(TOKEN_FILE)
        if token and #token > 0 then
            local success, user = self:authenticate(token)
            if success then return true, user end
            delfile(TOKEN_FILE)
        end
    end
    return false, "No cached token"
end

function DiscordRPC:connect()
    if not self.token then return false, "No token set" end
    
    self:log("Connecting to Discord Gateway...")
    local success, ws = pcall(createWebSocket, "wss://gateway.discord.gg/?v=10&encoding=json")
    if not success then return false, "WebSocket creation failed" end
    
    self.ws = ws
    
    self.connections.message = ws.OnMessage:Connect(function(message)
        self:handleMessage(message)
    end)
    
    self.connections.close = ws.OnClose:Connect(function()
        self:log("WebSocket closed", "WARN")
        if self.config.auto_reconnect then
            task.wait(5)
            self:connect()
        end
    end)
    
    return true, "Connected"
end

function DiscordRPC:handleMessage(message)
    local success, data = pcall(HttpService.JSONDecode, HttpService, message)
    if not success then return end
    
    local op, payload, event = data.op, data.d, data.t
    
    if data.s then self.sequence = data.s end
    
    if op == 10 then
        self:log("Received HELLO, starting heartbeat...")
        self:identify()
        self:startHeartbeat(payload.heartbeat_interval)
    elseif op == 11 then
        self.config.heartbeat_ack = true
    elseif op == 0 then
        if event == "READY" then
            self.session_id = payload.session_id
            self.resume_url = payload.resume_gateway_url
            self:log("Ready! Session ID: " .. self.session_id)
        elseif event == "RESUMED" then
            self:log("Session resumed successfully")
        end
    elseif op == 7 then
        self:log("Reconnect requested by Discord", "WARN")
        self:reconnect()
    elseif op == 9 then
        self:log("Invalid session, re-identifying...", "WARN")
        self.session_id = nil
        self:identify()
    end
end

function DiscordRPC:identify()
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
            large_threshold = 50,
            presence = self:getCurrentPresence()
        }
    }
    
    if self.session_id then
        payload.op = 6
        payload.d = {
            token = self.token,
            session_id = self.session_id,
            seq = self.sequence
        }
    end
    
    self:send(payload)
end

function DiscordRPC:startHeartbeat(interval)
    if self.heartbeat then task.cancel(self.heartbeat) end
    
    self.heartbeat = task.spawn(function()
        while self.ws do
            task.wait(interval / 1000)
            if not self.config.heartbeat_ack then
                self:log("Heartbeat ACK not received, reconnecting...", "WARN")
                self:reconnect()
                break
            end
            
            self.config.heartbeat_ack = false
            self:send({op = 1, d = self.sequence})
        end
    end)
end

function DiscordRPC:send(data)
    if self.ws then
        local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if success then
            self.ws:Send(encoded)
        end
    end
end

function DiscordRPC:updatePresence(activities, status, since, afk)
    activities = activities or {}
    status = status or "online"
    
    local presence = {
        op = 3,
        d = {
            since = since,
            activities = activities,
            status = status,
            afk = afk or false
        }
    }
    
    self:send(presence)
    
    table.insert(self.presence_history, {
        timestamp = tick(),
        activities = activities,
        status = status
    })
    
    if #self.presence_history > 50 then
        table.remove(self.presence_history, 1)
    end
end

function DiscordRPC:getCurrentPresence()
    local latest = self.presence_history[#self.presence_history]
    if latest then
        return {
            activities = latest.activities,
            status = latest.status,
            since = nil,
            afk = false
        }
    end
    return nil
end

function DiscordRPC:setActivity(config)
    config = config or {}
    
    local activity = {
        name = config.name or "Custom Activity",
        type = config.type or 0,
        url = config.url,
        created_at = math.floor(tick() * 1000)
    }
    
    if config.details then activity.details = config.details end
    if config.state then activity.state = config.state end
    
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
    
    if config.party_current or config.party_max then
        activity.party = {
            size = {config.party_current or 1, config.party_max or 1}
        }
    end
    
    if config.match_secret or config.join_secret or config.spectate_secret then
        activity.secrets = {}
        if config.match_secret then activity.secrets.match = config.match_secret end
        if config.join_secret then activity.secrets.join = config.join_secret end
        if config.spectate_secret then activity.secrets.spectate = config.spectate_secret end
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

function DiscordRPC:setRemainingTime(seconds, id)
    local end_time = math.floor((tick() + seconds) * 1000)
    self:setTimestamp(nil, end_time, id)
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

function DiscordRPC:removeButton(index, id)
    id = id or "default"
    if self.activities[id] and self.activities[id].buttons then
        table.remove(self.activities[id].buttons, index or 1)
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

function DiscordRPC:setSecrets(match, join, spectate, id)
    id = id or "default"
    if self.activities[id] then
        self.activities[id].secrets = {}
        if match then self.activities[id].secrets.match = match end
        if join then self.activities[id].secrets.join = join end
        if spectate then self.activities[id].secrets.spectate = spectate end
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

function DiscordRPC:saveTemplate(name, config)
    self:loadTemplates()
    self.templates[name] = config
    writefile(TEMPLATES_FILE, HttpService:JSONEncode(self.templates))
end

function DiscordRPC:loadTemplate(name)
    self:loadTemplates()
    local template = self.templates[name]
    if template then
        return self:setActivity(template)
    end
    return nil
end

function DiscordRPC:loadTemplates()
    if isfile(TEMPLATES_FILE) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(TEMPLATES_FILE))
        end)
        if success then
            self.templates = data
        end
    end
end

function DiscordRPC:listTemplates()
    self:loadTemplates()
    local names = {}
    for name in pairs(self.templates) do
        table.insert(names, name)
    end
    return names
end

function DiscordRPC:deleteTemplate(name)
    self:loadTemplates()
    self.templates[name] = nil
    writefile(TEMPLATES_FILE, HttpService:JSONEncode(self.templates))
end

function DiscordRPC:exportTemplates()
    self:loadTemplates()
    return HttpService:JSONEncode(self.templates)
end

function DiscordRPC:importTemplates(json_data)
    local success, data = pcall(HttpService.JSONDecode, HttpService, json_data)
    if success and type(data) == "table" then
        for name, template in pairs(data) do
            self.templates[name] = template
        end
        writefile(TEMPLATES_FILE, HttpService:JSONEncode(self.templates))
        return true
    end
    return false
end

function DiscordRPC:getHistory()
    return self.presence_history
end

function DiscordRPC:clearHistory()
    self.presence_history = {}
end

function DiscordRPC:getStats()
    return {
        uptime = tick() - self.start_time,
        activities_count = #self.activities,
        templates_count = self:countTemplates(),
        history_count = #self.presence_history,
        connected = self.ws ~= nil,
        user = self.user,
        session_id = self.session_id
    }
end

function DiscordRPC:countTemplates()
    self:loadTemplates()
    local count = 0
    for _ in pairs(self.templates) do count = count + 1 end
    return count
end

function DiscordRPC:setConfig(key, value)
    self.config[key] = value
    writefile(CONFIG_FILE, HttpService:JSONEncode(self.config))
end

function DiscordRPC:getConfig()
    if isfile(CONFIG_FILE) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if success then
            for key, value in pairs(data) do
                self.config[key] = value
            end
        end
    end
    return self.config
end

function DiscordRPC:reconnect()
    self:disconnect()
    task.wait(2)
    self:connect()
end

function DiscordRPC:disconnect()
    if self.heartbeat then task.cancel(self.heartbeat) end
    
    for _, connection in pairs(self.connections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    
    if self.ws then
        self.ws:Close()
    end
    
    self.ws = nil
    self.heartbeat = nil
    self.connections = {}
end

function DiscordRPC:reset()
    self:disconnect()
    self.activities = {}
    self.sequence = nil
    self.session_id = nil
end

function DiscordRPC:destroy()
    self:reset()
    self.token = nil
    self.user = nil
    
    local files = {TOKEN_FILE, TEMPLATES_FILE, CONFIG_FILE}
    for _, file in ipairs(files) do
        if isfile(file) then
            delfile(file)
        end
    end
end

return DiscordRPC.new()