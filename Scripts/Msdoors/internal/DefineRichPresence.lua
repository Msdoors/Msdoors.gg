local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local DiscordRPC = {}
DiscordRPC.__index = DiscordRPC

local CACHE_PATH = "msdoors/cache/"
local TOKEN_FILE = CACHE_PATH .. "token.txt"
local CONFIG_FILE = CACHE_PATH .. "config.json"
local LOG_FILE = CACHE_PATH .. "logs.txt"

local DISCORD_API = "https://discord.com/api/v10"
local GATEWAY_URLS = {
    "wss://gateway.discord.gg/?v=10&encoding=json",
    "wss://gateway-us-east1-b.discord.gg/?v=10&encoding=json", 
    "wss://gateway-us-west1-a.discord.gg/?v=10&encoding=json"
}

local ACTIVITY_TYPES = {
    PLAYING = 0,
    STREAMING = 1,
    LISTENING = 2,
    WATCHING = 3,
    CUSTOM = 4,
    COMPETING = 5
}

local STATUS_TYPES = {
    ONLINE = "online",
    IDLE = "idle", 
    DND = "dnd",
    INVISIBLE = "invisible"
}

local function initFileSystem()
    local fs = {
        isfolder = isfolder or function() return false end,
        makefolder = makefolder or function() end,
        writefile = writefile or function() end,
        readfile = readfile or function() return "" end,
        delfile = delfile or function() end,
        isfile = isfile or function() return false end,
        available = false
    }
    
    fs.available = (isfolder and makefolder and writefile and readfile and delfile and isfile) and true or false
    
    if fs.available then
        local success = pcall(function()
            if not fs.isfolder("msdoors") then fs.makefolder("msdoors") end
            if not fs.isfolder(CACHE_PATH) then fs.makefolder(CACHE_PATH) end
        end)
        if not success then
            fs.available = false
            warn("[DiscordRPC] Sistema de arquivos indisponível")
        end
    end
    
    return fs
end

local fs = initFileSystem()

local function getHttpRequest()
    local methods = {
        syn and syn.request,
        request,
        http_request,
        http and http.request
    }
    
    for _, method in ipairs(methods) do
        if method then return method end
    end
    
    return function(options)
        local success, result = pcall(function()
            return HttpService:RequestAsync(options)
        end)
        return success and {
            StatusCode = result.StatusCode,
            Body = result.Body,
            Headers = result.Headers
        } or {StatusCode = 0, Body = "", Headers = {}}
    end
end

local function getWebSocket()
    local methods = {
        syn and syn.websocket and syn.websocket.connect,
        WebSocket and WebSocket.connect,
        websocket and websocket.connect
    }
    
    for _, method in ipairs(methods) do
        if method then return method end
    end
    
    return nil
end

local function validateToken(token)
    if not token or type(token) ~= "string" then return false end
    if #token < 50 then return false end
    return token:match("^[A-Za-z0-9._%-]+$") ~= nil
end

local function formatTimestamp(timestamp)
    if not timestamp then return nil end
    return math.floor(tonumber(timestamp) or 0)
end

local function sanitizeString(str, maxLength)
    if not str then return nil end
    str = tostring(str)
    return #str > 0 and str:sub(1, maxLength or 128) or nil
end

local function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function DiscordRPC.new()
    local self = setmetatable({}, DiscordRPC)
    
    self.token = nil
    self.user = nil
    self.websocket = nil
    self.websocket_connect = getWebSocket()
    self.request = getHttpRequest()
    
    self.connected = false
    self.authenticated = false
    self.sequence = nil
    self.session_id = nil
    self.heartbeat_interval = 41250
    self.heartbeat_task = nil
    self.last_heartbeat = 0
    
    self.activities = {}
    self.current_status = STATUS_TYPES.ONLINE
    self.last_activity_update = 0
    self.activity_cooldown = 1
    
    self.reconnect_attempts = 0
    self.max_reconnect_attempts = 5
    self.reconnect_delay = 2
    
    self.config = {
        auto_reconnect = true,
        debug_mode = false,
        cache_activities = true,
        heartbeat_timeout = 30
    }
    
    self.callbacks = {
        on_ready = nil,
        on_disconnect = nil,
        on_activity_update = nil,
        on_error = nil
    }
    
    self.stats = {
        connection_time = 0,
        messages_sent = 0,
        messages_received = 0,
        activity_updates = 0,
        errors = 0
    }
    
    self:loadConfig()
    return self
end

function DiscordRPC:log(message, level)
    level = level or "INFO"
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local log_message = string.format("[%s] [%s] %s", timestamp, level, tostring(message))
    
    if self.config.debug_mode then
        print("[DiscordRPC]", log_message)
    end
    
    if fs.available then
        pcall(function()
            local existing = ""
            if fs.isfile(LOG_FILE) then
                existing = fs.readfile(LOG_FILE)
            end
            fs.writefile(LOG_FILE, existing .. log_message .. "\n")
        end)
    end
end

function DiscordRPC:saveConfig()
    if not fs.available then return end
    
    pcall(function()
        local config_json = HttpService:JSONEncode(self.config)
        fs.writefile(CONFIG_FILE, config_json)
    end)
end

function DiscordRPC:loadConfig()
    if not fs.available or not fs.isfile(CONFIG_FILE) then return end
    
    pcall(function()
        local config_data = fs.readfile(CONFIG_FILE)
        local loaded_config = HttpService:JSONDecode(config_data)
        
        for key, value in pairs(loaded_config) do
            self.config[key] = value
        end
    end)
end

function DiscordRPC:saveToken(token)
    if not fs.available then return end
    
    pcall(function()
        fs.writefile(TOKEN_FILE, token)
    end)
end

function DiscordRPC:loadToken()
    if not fs.available or not fs.isfile(TOKEN_FILE) then
        return nil
    end
    
    local success, token = pcall(function()
        return fs.readfile(TOKEN_FILE)
    end)
    
    return success and token or nil
end

function DiscordRPC:clearToken()
    if fs.available and fs.isfile(TOKEN_FILE) then
        pcall(function()
            fs.delfile(TOKEN_FILE)
        end)
    end
end

function DiscordRPC:authenticate(token)
    if not validateToken(token) then
        self:log("Token inválido fornecido", "ERROR")
        return false, "Token inválido"
    end
    
    local auth_header = token:sub(1, 3) == "Bot" and token or ("Bot " .. token)
    
    local success, response = pcall(function()
        return self.request({
            Url = DISCORD_API .. "/users/@me",
            Method = "GET",
            Headers = {
                ["Authorization"] = auth_header,
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "RobloxDiscordRPC/2.0.0"
            }
        })
    end)
    
    if not success then
        self:log("Erro de rede durante autenticação: " .. tostring(response), "ERROR")
        self.stats.errors = self.stats.errors + 1
        return false, "Erro de rede"
    end
    
    if response.StatusCode == 401 then
        self:log("Token inválido ou expirado", "ERROR")
        self:clearToken()
        return false, "Token inválido ou expirado"
    elseif response.StatusCode == 429 then
        self:log("Rate limit atingido", "WARN")
        return false, "Rate limit atingido - tente novamente em alguns segundos"
    elseif response.StatusCode ~= 200 then
        self:log("Erro HTTP " .. response.StatusCode, "ERROR")
        return false, "Erro HTTP: " .. response.StatusCode
    end
    
    local decode_success, user_data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    
    if not decode_success then
        self:log("Resposta inválida do Discord", "ERROR")
        return false, "Resposta inválida do servidor"
    end
    
    self.token = auth_header
    self.user = user_data
    self.authenticated = true
    
    self:saveToken(token)
    self:log("Autenticado como: " .. (user_data.username or "Unknown"), "INFO")
    
    return true, user_data
end

function DiscordRPC:tryLoadSavedToken()
    local saved_token = self:loadToken()
    if not saved_token or #saved_token == 0 then
        return false, "Nenhum token salvo encontrado"
    end
    
    self:log("Tentando autenticar com token salvo", "INFO")
    return self:authenticate(saved_token)
end

function DiscordRPC:connect()
    if not self.authenticated then
        return false, "Não autenticado - use authenticate() primeiro"
    end
    
    if not self.websocket_connect then
        self:log("WebSocket não disponível - usando fallback HTTP", "WARN")
        self.connected = true
        return true, "Conectado via HTTP (sem WebSocket)"
    end
    
    for i, gateway_url in ipairs(GATEWAY_URLS) do
        self:log("Tentando conectar ao gateway " .. i, "INFO")
        
        local success, ws = pcall(function()
            return self.websocket_connect(gateway_url)
        end)
        
        if success and ws then
            self.websocket = ws
            self.reconnect_attempts = 0
            self.stats.connection_time = tick()
            
            self:setupWebSocketHandlers()
            self:log("Conectado ao gateway " .. i, "INFO")
            
            return true, "Conectado ao gateway " .. i
        else
            self:log("Falha ao conectar gateway " .. i .. ": " .. tostring(ws), "WARN")
        end
        
        task.wait(0.5)
    end
    
    self:log("Todos os gateways falharam", "ERROR")
    self.connected = true
    return true, "Conectado via HTTP (WebSocket falhou)"
end

function DiscordRPC:setupWebSocketHandlers()
    if not self.websocket then return end
    
    if self.websocket.OnMessage then
        self.websocket.OnMessage:Connect(function(message)
            self:handleWebSocketMessage(message)
        end)
    end
    
    if self.websocket.OnClose then
        self.websocket.OnClose:Connect(function(code, reason)
            self:handleWebSocketClose(code, reason)
        end)
    end
end

function DiscordRPC:handleWebSocketMessage(message)
    self.stats.messages_received = self.stats.messages_received + 1
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(message)
    end)
    
    if not success or not data then
        self:log("Mensagem WebSocket inválida", "WARN")
        return
    end
    
    if data.s then
        self.sequence = data.s
    end
    
    if data.op == 10 then
        self:log("Received Hello, enviando Identify", "DEBUG")
        self.heartbeat_interval = data.d.heartbeat_interval
        self:identify()
        self:startHeartbeat()
    elseif data.op == 0 and data.t == "READY" then
        self:log("Sessão pronta", "INFO")
        self.connected = true
        self.session_id = data.d and data.d.session_id
        if self.callbacks.on_ready then
            self.callbacks.on_ready(data.d)
        end
    elseif data.op == 11 then
        self.last_heartbeat = tick()
        self:log("Heartbeat ACK recebido", "DEBUG")
    elseif data.op == 9 then
        self:log("Sessão inválida, reconectando", "WARN")
        self:reconnect()
    elseif data.op == 7 then
        self:log("Reconnect solicitado pelo servidor", "INFO")
        self:reconnect()
    end
end

function DiscordRPC:handleWebSocketClose(code, reason)
    self:log("WebSocket fechado: " .. (code or "unknown") .. " - " .. (reason or "no reason"), "WARN")
    self.connected = false
    
    if self.callbacks.on_disconnect then
        self.callbacks.on_disconnect(code, reason)
    end
    
    if self.config.auto_reconnect and self.reconnect_attempts < self.max_reconnect_attempts then
        local delay = self.reconnect_delay * (2 ^ self.reconnect_attempts)
        self:log("Reconectando em " .. delay .. " segundos", "INFO")
        
        task.wait(delay)
        self.reconnect_attempts = self.reconnect_attempts + 1
        self:connect()
    end
end

function DiscordRPC:identify()
    if not self.websocket or not self.token then return end
    
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
            intents = 512
        }
    }
    
    self:sendWebSocketPayload(payload)
end

function DiscordRPC:startHeartbeat()
    if self.heartbeat_task then
        task.cancel(self.heartbeat_task)
    end
    
    local interval = math.max(self.heartbeat_interval / 1000, 5)
    self.last_heartbeat = tick()
    
    self.heartbeat_task = task.spawn(function()
        while self.websocket and self.connected do
            task.wait(interval * 0.9)
            
            if not self.websocket or not self.connected then break end
            
            if tick() - self.last_heartbeat > self.config.heartbeat_timeout then
                self:log("Heartbeat timeout, reconectando", "WARN")
                self:reconnect()
                break
            end
            
            self:sendHeartbeat()
        end
    end)
end

function DiscordRPC:sendHeartbeat()
    local payload = {
        op = 1,
        d = self.sequence
    }
    return self:sendWebSocketPayload(payload)
end

function DiscordRPC:sendWebSocketPayload(payload)
    if not self.websocket or not self.websocket.Send then
        return false
    end
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(payload)
    end)
    
    if not success then
        self:log("Erro ao codificar payload", "ERROR")
        return false
    end
    
    local send_success = pcall(function()
        self.websocket:Send(encoded)
    end)
    
    if send_success then
        self.stats.messages_sent = self.stats.messages_sent + 1
    else
        self:log("Erro ao enviar payload WebSocket", "ERROR")
    end
    
    return send_success
end

function DiscordRPC:updatePresence(activities, status)
    if not self.connected then
        return false, "Não conectado"
    end
    
    if tick() - self.last_activity_update < self.activity_cooldown then
        return false, "Cooldown de atividade ativo"
    end
    
    local presence_data = {
        activities = activities or {},
        status = status or self.current_status,
        since = nil,
        afk = false
    }
    
    local success = false
    
    if self.websocket then
        local payload = {
            op = 3,
            d = presence_data
        }
        success = self:sendWebSocketPayload(payload)
    else
        success = self:updatePresenceHTTP(presence_data)
    end
    
    if success then
        self.last_activity_update = tick()
        self.stats.activity_updates = self.stats.activity_updates + 1
        self:log("Presença atualizada", "INFO")
        
        if self.callbacks.on_activity_update then
            self.callbacks.on_activity_update(activities, status)
        end
    end
    
    return success, success and "Presença atualizada" or "Falha ao atualizar presença"
end

function DiscordRPC:updatePresenceHTTP(presence_data)
    if not self.token then return false end
    
    local success, response = pcall(function()
        return self.request({
            Url = DISCORD_API .. "/users/@me/settings",
            Method = "PATCH",
            Headers = {
                ["Authorization"] = self.token,
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                custom_status = presence_data
            })
        })
    end)
    
    return success and (response.StatusCode == 200 or response.StatusCode == 204)
end

function DiscordRPC:setActivity(config)
    if not config or type(config) ~= "table" then
        return false, "Configuração inválida"
    end
    
    local activity = {
        name = sanitizeString(config.name, 128) or "Roblox Game",
        type = tonumber(config.type) or ACTIVITY_TYPES.PLAYING
    }
    
    if config.details then
        activity.details = sanitizeString(config.details, 128)
    end
    
    if config.state then
        activity.state = sanitizeString(config.state, 128)
    end
    
    if config.url and activity.type == ACTIVITY_TYPES.STREAMING then
        activity.url = sanitizeString(config.url, 512)
    end
    
    if config.start_time or config.end_time then
        activity.timestamps = {}
        if config.start_time then
            activity.timestamps.start = formatTimestamp(config.start_time)
        end
        if config.end_time then
            activity.timestamps["end"] = formatTimestamp(config.end_time)
        end
    end
    
    if config.large_image or config.small_image then
        activity.assets = {}
        if config.large_image then
            activity.assets.large_image = sanitizeString(config.large_image, 256)
            if config.large_text then
                activity.assets.large_text = sanitizeString(config.large_text, 128)
            end
        end
        if config.small_image then
            activity.assets.small_image = sanitizeString(config.small_image, 256)
            if config.small_text then
                activity.assets.small_text = sanitizeString(config.small_text, 128)
            end
        end
    end
    
    if config.party_current and config.party_max then
        local current = tonumber(config.party_current)
        local max = tonumber(config.party_max)
        if current and max and current > 0 and max > 0 and current <= max then
            activity.party = {
                id = sanitizeString(config.party_id, 128) or "default_party",
                size = {current, max}
            }
        end
    end
    
    if config.buttons and type(config.buttons) == "table" then
        activity.buttons = {}
        for i = 1, math.min(2, #config.buttons) do
            local button = config.buttons[i]
            if button and button.label and button.url then
                local label = sanitizeString(button.label, 32)
                local url = sanitizeString(button.url, 512)
                if label and url and url:match("^https?://") then
                    table.insert(activity.buttons, {label = label, url = url})
                end
            end
        end
        if #activity.buttons == 0 then
            activity.buttons = nil
        end
    end
    
    if config.secrets then
        activity.secrets = {}
        if config.secrets.join then
            activity.secrets.join = sanitizeString(config.secrets.join, 128)
        end
        if config.secrets.spectate then
            activity.secrets.spectate = sanitizeString(config.secrets.spectate, 128)
        end
        if config.secrets.match then
            activity.secrets.match = sanitizeString(config.secrets.match, 128)
        end
    end
    
    local id = tostring(config.id or "default")
    self.activities[id] = activity
    
    if self.config.cache_activities and fs.available then
        self:saveActivities()
    end
    
    local activities_list = {}
    for _, act in pairs(self.activities) do
        table.insert(activities_list, act)
    end
    
    return self:updatePresence(activities_list)
end

function DiscordRPC:saveActivities()
    if not fs.available then return end
    
    pcall(function()
        local activities_json = HttpService:JSONEncode(self.activities)
        fs.writefile(CACHE_PATH .. "activities.json", activities_json)
    end)
end

function DiscordRPC:loadActivities()
    if not fs.available then return end
    
    local file_path = CACHE_PATH .. "activities.json"
    if not fs.isfile(file_path) then return end
    
    pcall(function()
        local activities_data = fs.readfile(file_path)
        self.activities = HttpService:JSONDecode(activities_data)
    end)
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
    local config = {name = "Custom Activity"}
    
    if size == "small" then
        config.small_image = image_url
        config.small_text = text
    else
        config.large_image = image_url
        config.large_text = text
    end
    
    return self:setActivity(config)
end

function DiscordRPC:setElapsedTime(seconds, id)
    if not seconds or seconds < 0 then return false end
    
    local start_time = (tick() - seconds) * 1000
    local activity = self:getActivity(id)
    
    if activity then
        activity.timestamps = activity.timestamps or {}
        activity.timestamps.start = start_time
        return self:refreshActivities()
    else
        return self:setActivity({
            id = id,
            start_time = start_time
        })
    end
end

function DiscordRPC:setRemainingTime(seconds, id)
    if not seconds or seconds < 0 then return false end
    
    local end_time = (tick() + seconds) * 1000
    local activity = self:getActivity(id)
    
    if activity then
        activity.timestamps = activity.timestamps or {}
        activity.timestamps["end"] = end_time
        return self:refreshActivities()
    else
        return self:setActivity({
            id = id,
            end_time = end_time
        })
    end
end

function DiscordRPC:setTimestamp(start_time, end_time, id)
    id = id or "default"
    local activity = self:getActivity(id)
    
    if activity then
        if start_time or end_time then
            activity.timestamps = {}
            if start_time then
                activity.timestamps.start = formatTimestamp(start_time)
            end
            if end_time then
                activity.timestamps["end"] = formatTimestamp(end_time)
            end
        else
            activity.timestamps = nil
        end
        return self:refreshActivities()
    end
    
    return false
end

function DiscordRPC:setParty(current, max, party_id, id)
    if not current or not max or current < 1 or max < 1 or current > max then
        return false
    end
    
    id = id or "default"
    local activity = self:getActivity(id)
    
    if activity then
        activity.party = {
            id = party_id or "default_party",
            size = {tonumber(current), tonumber(max)}
        }
        return self:refreshActivities()
    end
    
    return false
end

function DiscordRPC:addButton(label, url, id)
    if not label or not url or #label == 0 or #label > 32 or not url:match("^https?://") then
        return false
    end
    
    id = id or "default"
    local activity = self:getActivity(id)
    
    if activity then
        activity.buttons = activity.buttons or {}
        table.insert(activity.buttons, {label = label, url = url})
        
        if #activity.buttons > 2 then
            table.remove(activity.buttons, 1)
        end
        
        return self:refreshActivities()
    end
    
    return false
end

function DiscordRPC:removeButton(index, id)
    id = id or "default"
    index = index or #(self:getActivity(id) and self:getActivity(id).buttons or {})
    
    local activity = self:getActivity(id)
    if activity and activity.buttons and activity.buttons[index] then
        table.remove(activity.buttons, index)
        if #activity.buttons == 0 then
            activity.buttons = nil
        end
        return self:refreshActivities()
    end
    
    return false
end

function DiscordRPC:clearButtons(id)
    id = id or "default"
    local activity = self:getActivity(id)
    
    if activity then
        activity.buttons = nil
        return self:refreshActivities()
    end
    
    return false
end

function DiscordRPC:setSecrets(join, spectate, match, id)
    id = id or "default"
    local activity = self:getActivity(id)
    
    if activity then
        if join or spectate or match then
            activity.secrets = {}
            if join then activity.secrets.join = sanitizeString(join, 128) end
            if spectate then activity.secrets.spectate = sanitizeString(spectate, 128) end
            if match then activity.secrets.match = sanitizeString(match, 128) end
        else
            activity.secrets = nil
        end
        return self:refreshActivities()
    end
    
    return false
end

function DiscordRPC:getActivity(id)
    return self.activities[id or "default"]
end

function DiscordRPC:removeActivity(id)
    id = id or "default"
    if self.activities[id] then
        self.activities[id] = nil
        return self:refreshActivities()
    end
    return false
end

function DiscordRPC:clearActivities()
    self.activities = {}
    return self:updatePresence({})
end

function DiscordRPC:refreshActivities()
    local activities_list = {}
    for _, activity in pairs(self.activities) do
        table.insert(activities_list, activity)
    end
    return self:updatePresence(activities_list)
end

function DiscordRPC:setUserStatus(status)
    if not STATUS_TYPES[status:upper()] then
        return false, "Status inválido"
    end
    
    self.current_status = STATUS_TYPES[status:upper()]
    
    local activities_list = {}
    for _, activity in pairs(self.activities) do
        table.insert(activities_list, activity)
    end
    
    return self:updatePresence(activities_list, self.current_status)
end

function DiscordRPC:reconnect()
    self:log("Iniciando reconexão", "INFO")
    
    if self.heartbeat_task then
        task.cancel(self.heartbeat_task)
        self.heartbeat_task = nil
    end
    
    if self.websocket and self.websocket.Close then
        pcall(function() self.websocket:Close() end)
    end
    
    self.websocket = nil
    self.connected = false
    self.sequence = nil
    
    return self:connect()
end

function DiscordRPC:isConnected()
    return self.connected
end

function DiscordRPC:isAuthenticated()
    return self.authenticated
end

function DiscordRPC:getUser()
    return self.user
end

function DiscordRPC:getStats()
    return deepCopy(self.stats)
end

function DiscordRPC:getConfig()
    return deepCopy(self.config)
end

function DiscordRPC:setConfig(key, value)
    if self.config[key] ~= nil then
        self.config[key] = value
        self:saveConfig()
        return true
    end
    return false
end

function DiscordRPC:setCallback(event, callback)
    if self.callbacks[event] ~= nil then
        self.callbacks[event] = callback
        return true
    end
    return false
end

function DiscordRPC:getConnectionInfo()
    return {
        connected = self.connected,
        authenticated = self.authenticated,
        user = self.user,
        websocket_available = self.websocket_connect ~= nil,
        session_id = self.session_id,
        sequence = self.sequence,
        heartbeat_interval = self.heartbeat_interval,
        last_heartbeat = self.last_heartbeat,
        reconnect_attempts = self.reconnect_attempts,
        stats = self:getStats()
    }
end

function DiscordRPC:startAutoUpdater(interval)
    if self.auto_update_task then
        task.cancel(self.auto_update_task)
    end
    
    interval = math.max(interval or 5, 1)
    
    self.auto_update_task = task.spawn(function()
        while self.connected do
            task.wait(interval)
            
            if self.connected and #self.activities > 0 then
                local activities_list = {}
                for _, activity in pairs(self.activities) do
                    local activity_copy = deepCopy(activity)
                    
                    if activity_copy.timestamps then
                        if activity_copy.timestamps.start then
                            local elapsed = tick() - (activity_copy.timestamps.start / 1000)
                            if elapsed < 0 then
                                activity_copy.timestamps.start = tick() * 1000
                            end
                        end
                    end
                    
                    table.insert(activities_list, activity_copy)
                end
                
                self:updatePresence(activities_list)
            end
        end
    end)
end

function DiscordRPC:stopAutoUpdater()
    if self.auto_update_task then
        task.cancel(self.auto_update_task)
        self.auto_update_task = nil
    end
end

function DiscordRPC:createQuickActivity(name, details, state)
    return self:setActivity({
        name = name or "Roblox Game",
        details = details,
        state = state,
        type = ACTIVITY_TYPES.PLAYING,
        start_time = tick() * 1000
    })
end

function DiscordRPC:setGameActivity(game_name, server_info, player_count)
    local config = {
        name = game_name or "Roblox Game",
        type = ACTIVITY_TYPES.PLAYING,
        start_time = tick() * 1000
    }
    
    if server_info then
        config.details = server_info
    end
    
    if player_count then
        config.state = "Players: " .. tostring(player_count)
    end
    
    return self:setActivity(config)
end

function DiscordRPC:setStreamActivity(title, url, viewer_count)
    if not url or not url:match("^https?://") then
        return false, "URL inválida para streaming"
    end
    
    local config = {
        name = title or "Streaming",
        type = ACTIVITY_TYPES.STREAMING,
        url = url,
        start_time = tick() * 1000
    }
    
    if viewer_count then
        config.details = "Viewers: " .. tostring(viewer_count)
    end
    
    return self:setActivity(config)
end

function DiscordRPC:setListeningActivity(song, artist, album)
    local config = {
        name = song or "Music",
        type = ACTIVITY_TYPES.LISTENING,
        start_time = tick() * 1000
    }
    
    if artist then
        config.details = "by " .. artist
    end
    
    if album then
        config.state = "on " .. album
    end
    
    return self:setActivity(config)
end

function DiscordRPC:setWatchingActivity(title, episode, season)
    local config = {
        name = title or "Video",
        type = ACTIVITY_TYPES.WATCHING,
        start_time = tick() * 1000
    }
    
    if season and episode then
        config.details = "S" .. season .. "E" .. episode
    elseif episode then
        config.details = "Episode " .. episode
    end
    
    return self:setActivity(config)
end

function DiscordRPC:setCustomActivity(text)
    return self:setActivity({
        name = "Custom Status",
        type = ACTIVITY_TYPES.CUSTOM,
        state = text or "Custom activity"
    })
end

function DiscordRPC:setCompetingActivity(event, rank, score)
    local config = {
        name = event or "Competition",
        type = ACTIVITY_TYPES.COMPETING,
        start_time = tick() * 1000
    }
    
    if rank then
        config.details = "Rank: " .. tostring(rank)
    end
    
    if score then
        config.state = "Score: " .. tostring(score)
    end
    
    return self:setActivity(config)
end

function DiscordRPC:animateActivity(id, animations)
    if not animations or type(animations) ~= "table" then
        return false
    end
    
    id = id or "default"
    local activity = self:getActivity(id)
    if not activity then return false end
    
    if self.animation_task then
        task.cancel(self.animation_task)
    end
    
    local animation_index = 1
    
    self.animation_task = task.spawn(function()
        while self.connected and self:getActivity(id) do
            local anim = animations[animation_index]
            if not anim then break end
            
            local current_activity = self:getActivity(id)
            if current_activity then
                for key, value in pairs(anim) do
                    if key ~= "duration" then
                        current_activity[key] = value
                    end
                end
                
                self:refreshActivities()
            end
            
            task.wait(anim.duration or 3)
            
            animation_index = animation_index + 1
            if animation_index > #animations then
                animation_index = 1
            end
        end
    end)
    
    return true
end

function DiscordRPC:stopAnimation()
    if self.animation_task then
        task.cancel(self.animation_task)
        self.animation_task = nil
        return true
    end
    return false
end

function DiscordRPC:rotateImages(id, images, interval)
    if not images or #images == 0 then return false end
    
    id = id or "default"
    interval = interval or 5
    
    if self.image_rotation_task then
        task.cancel(self.image_rotation_task)
    end
    
    local image_index = 1
    
    self.image_rotation_task = task.spawn(function()
        while self.connected and self:getActivity(id) do
            local activity = self:getActivity(id)
            if not activity then break end
            
            local current_image = images[image_index]
            if current_image then
                activity.assets = activity.assets or {}
                activity.assets.large_image = current_image.url
                activity.assets.large_text = current_image.text or "Image " .. image_index
                
                self:refreshActivities()
            end
            
            task.wait(interval)
            
            image_index = image_index + 1
            if image_index > #images then
                image_index = 1
            end
        end
    end)
    
    return true
end

function DiscordRPC:stopImageRotation()
    if self.image_rotation_task then
        task.cancel(self.image_rotation_task)
        self.image_rotation_task = nil
        return true
    end
    return false
end

function DiscordRPC:addProgressBar(id, current, max, show_percentage)
    id = id or "default"
    local activity = self:getActivity(id)
    if not activity then return false end
    
    current = math.max(0, tonumber(current) or 0)
    max = math.max(1, tonumber(max) or 100)
    
    local percentage = math.floor((current / max) * 100)
    local bar_length = 20
    local filled = math.floor((current / max) * bar_length)
    
    local bar = "["
    for i = 1, bar_length do
        bar = bar .. (i <= filled and "█" or "░")
    end
    bar = bar .. "]"
    
    if show_percentage then
        bar = bar .. " " .. percentage .. "%"
    end
    
    activity.state = bar
    
    return self:refreshActivities()
end

function DiscordRPC:cleanup()
    self:log("Iniciando limpeza", "INFO")
    
    if self.heartbeat_task then
        task.cancel(self.heartbeat_task)
        self.heartbeat_task = nil
    end
    
    if self.auto_update_task then
        task.cancel(self.auto_update_task)
        self.auto_update_task = nil
    end
    
    if self.animation_task then
        task.cancel(self.animation_task)
        self.animation_task = nil
    end
    
    if self.image_rotation_task then
        task.cancel(self.image_rotation_task)
        self.image_rotation_task = nil
    end
    
    if self.websocket and self.websocket.Close then
        pcall(function()
            self.websocket:Close()
        end)
    end
    
    self:clearActivities()
    
    self.connected = false
    self.authenticated = false
    self.websocket = nil
    self.sequence = nil
    self.session_id = nil
    
    self:log("Limpeza concluída", "INFO")
end

function DiscordRPC:destroy()
    self:cleanup()
    
    for event, _ in pairs(self.callbacks) do
        self.callbacks[event] = nil
    end
    
    if fs.available then
        pcall(function()
            if fs.isfile(CACHE_PATH .. "activities.json") then
                fs.delfile(CACHE_PATH .. "activities.json")
            end
        end)
    end
    
    setmetatable(self, nil)
end

DiscordRPC.SetActivity = DiscordRPC.setActivity
DiscordRPC.SetStatus = DiscordRPC.setStatus
DiscordRPC.SetImage = DiscordRPC.setImage
DiscordRPC.Connect = DiscordRPC.connect
DiscordRPC.Authenticate = DiscordRPC.authenticate
DiscordRPC.Disconnect = DiscordRPC.cleanup

DiscordRPC.ActivityTypes = ACTIVITY_TYPES
DiscordRPC.StatusTypes = STATUS_TYPES

local DefaultInstance = nil

function DiscordRPC.GetDefault()
    if not DefaultInstance then
        DefaultInstance = DiscordRPC.new()
    end
    return DefaultInstance
end

function DiscordRPC.QuickSetup(token, activity_name, details, state)
    local rpc = DiscordRPC.GetDefault()
    
    local auth_success, auth_msg = rpc:authenticate(token)
    if not auth_success then
        return false, auth_msg
    end
    
    local connect_success, connect_msg = rpc:connect()
    if not connect_success then
        return false, connect_msg
    end
    
    if activity_name then
        local activity_success, activity_msg = rpc:setActivity({
            name = activity_name,
            details = details,
            state = state,
            type = ACTIVITY_TYPES.PLAYING,
            start_time = tick() * 1000
        })
        
        if not activity_success then
            return false, activity_msg
        end
    end
    
    return true, "Setup completo com sucesso"
end

local function onGameClose()
    if DefaultInstance then
        DefaultInstance:cleanup()
    end
end

if game then
    game.Players.PlayerRemoving:Connect(function(player)
        if player == Players.LocalPlayer then
            onGameClose()
        end
    end)
    
    if game.CoreGui then
        local connection
        connection = game.CoreGui.AncestryChanged:Connect(function()
            if not game.CoreGui.Parent then
                onGameClose()
                connection:Disconnect()
            end
        end)
    end
end

return DiscordRPC