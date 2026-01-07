if shared.testexecutor then
    return shared.testexecutor
end
print(" Testing your executor... ")

local exec = {}
local info = {}

shared.testexecutor = {}

local function getVersion()
    local ok, ver = pcall(function()
        return _G.msdoors_version
    end)
    return ok and ver or "unknown"
end

shared.testexecutor.timestamp = os.time()
shared.testexecutor.version = getVersion()

local function fmtTime()
    local t = os.date("*t")
    return string.format("%04d-%02d-%02d_%02d-%02d-%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

local dt = fmtTime()
local dir = "msdoors/executorlog"
local file = "log-msdoors" .. dt .. ".txt"
local path = dir .. "/" .. file
local logs = {}

local name, ver, full = "Unknown", "Unknown", "Unknown"

local ok = pcall(function()
    full = identifyexecutor() or "None"
    local parts = string.split(full, " ")
    name = parts[1] or "Unknown"
    if #parts > 1 then
        table.remove(parts, 1)
        ver = table.concat(parts, " ")
    end
end)

if not ok then
    name, ver, full = "Unknown", "Unknown", "Unknown"
end

shared.testexecutor.name = name
shared.testexecutor.executorVersion = ver
shared.testexecutor.fullInfo = full

local broken = {
    Arceus = {require = true},
    Codex = {require = true},
    VegaX = {require = true},
    Electron = {gcinfo = true, require = true},
    Krnl = {},
    Synapse = {},
    Fluxus = {},
    ["Script-Ware"] = {},
    Oxygen = {fireclickdetector = true},
    Hydrogen = {fireclickdetector = true},
    Temple = {require = true, hookmetamethod = true},
    Xeno = {require = true},
    Solara = {require = true}
}

local os_type = "Unknown"
if identifyexecutor and typeof(identifyexecutor) == "function" then
    local ei = string.lower(identifyexecutor() or "")
    if string.find(ei, "windows") then
        os_type = "Windows"
    elseif string.find(ei, "mac") or string.find(ei, "macos") then
        os_type = "MacOS"
    elseif string.find(ei, "ios") or string.find(ei, "iphone") or string.find(ei, "ipad") then
        os_type = "iOS"
    elseif string.find(ei, "android") then
        os_type = "Android"
    elseif string.find(ei, "linux") then
        os_type = "Linux"
    end
end

shared.testexecutor.osType = os_type

local function test(n, f, cb)
    if broken[name] and broken[name][n] then
        return false
    end
    
    local ok, err = false, nil
    if cb ~= false then
        ok, err = pcall(f)
    else
        ok = typeof(f) == "function"
    end
    
    local status = ok and "✅ Supported" or "❌ NOT SUPPORTED"
    local errorMsg = ""
    if not ok and err then
        errorMsg = " [ ERROR: " .. tostring(err) .. " ]"
    end
    
    info[n] = n .. " " .. status .. errorMsg
    exec[n] = ok
    shared.testexecutor[n] = ok
    return ok
end

local function safe(n, f)
    if getfenv()[n] then
        test(n, f, false)
    else
        exec[n] = false
        info[n] = n .. " ❌ NOT SUPPORTED [ ERROR: FUNCTION NOT AVAILABLE ]"
        shared.testexecutor[n] = false
    end
end

safe("readfile", readfile)
safe("listfiles", listfiles)
safe("writefile", writefile)
safe("makefolder", makefolder)
safe("appendfile", appendfile)
safe("isfile", isfile)
safe("isfolder", isfolder)
safe("delfile", delfile)
safe("delfolder", delfolder)
safe("loadfile", loadfile)

safe("getrenv", getrenv)
safe("getgenv", getgenv)
safe("getsenv", getsenv)
safe("getfenv", getfenv)
safe("getrawmetatable", getrawmetatable)
safe("setrawmetatable", setrawmetatable)
safe("setreadonly", setreadonly)
safe("getnamecallmethod", getnamecallmethod)
safe("setclipboard", setclipboard)
safe("getcustomasset", getcustomasset)
safe("getsynasset", getsynasset)
safe("isluau", isluau)
safe("checkcaller", checkcaller)

safe("request", request)
safe("http_request", http_request)
safe("httprequest", httprequest)

if syn and syn.request then
    exec["syn.request"] = true
    info["syn.request"] = "syn.request ✅ Supported"
    shared.testexecutor["syn.request"] = true
else
    exec["syn.request"] = false
    info["syn.request"] = "syn.request ❌ NOT SUPPORTED [ ERROR: syn library not available ]"
    shared.testexecutor["syn.request"] = false
end

if WebSocket then
    exec["WebSocket"] = true
    info["WebSocket"] = "WebSocket ✅ Supported"
    shared.testexecutor["WebSocket"] = true
    
    if typeof(WebSocket.connect) == "function" then
        exec["WebSocket.connect"] = true
        info["WebSocket.connect"] = "WebSocket.connect ✅ Supported"
        shared.testexecutor["WebSocket.connect"] = true
    else
        exec["WebSocket.connect"] = false
        info["WebSocket.connect"] = "WebSocket.connect ❌ NOT SUPPORTED [ ERROR: connect method not available ]"
        shared.testexecutor["WebSocket.connect"] = false
    end
else
    exec["WebSocket"] = false
    exec["WebSocket.connect"] = false
    info["WebSocket"] = "WebSocket ❌ NOT SUPPORTED [ ERROR: WebSocket library not available ]"
    info["WebSocket.connect"] = "WebSocket.connect ❌ NOT SUPPORTED [ ERROR: WebSocket library not available ]"
    shared.testexecutor["WebSocket"] = false
    shared.testexecutor["WebSocket.connect"] = false
end

safe("queue_on_teleport", queue_on_teleport)
safe("getcallingscript", getcallingscript)
safe("gethui", gethui)
safe("getgc", getgc)
safe("getinstances", getinstances)
safe("getnilinstances", getnilinstances)
safe("sethiddenproperty", sethiddenproperty)
safe("gethiddenproperty", gethiddenproperty)
safe("saveinstance", saveinstance)
safe("getconnections", getconnections)
safe("firesignal", firesignal)

if Drawing then
    exec["Drawing"] = true
    info["Drawing"] = "Drawing ✅ Supported"
    shared.testexecutor.Drawing = true
    
    if Drawing.new then
        exec["Drawing.new"] = true
        info["Drawing.new"] = "Drawing.new ✅ Supported"
        shared.testexecutor["Drawing.new"] = true
    else
        exec["Drawing.new"] = false
        info["Drawing.new"] = "Drawing.new ❌ NOT SUPPORTED [ ERROR: new method not available ]"
        shared.testexecutor["Drawing.new"] = false
    end
else
    exec["Drawing"] = false
    exec["Drawing.new"] = false
    info["Drawing"] = "Drawing ❌ NOT SUPPORTED [ ERROR: Drawing library not available ]"
    info["Drawing.new"] = "Drawing.new ❌ NOT SUPPORTED [ ERROR: Drawing library not available ]"
    shared.testexecutor.Drawing = false
    shared.testexecutor["Drawing.new"] = false
end

safe("fireclickdetector", fireclickdetector)
safe("mouse1click", mouse1click)
safe("mouse1press", mouse1press)
safe("mouse1release", mouse1release)
safe("mouse2click", mouse2click)
safe("keypress", keypress)
safe("keyrelease", keyrelease)

if getfenv()["require"] then
    test("require", function()
        local plr = game:GetService("Players").LocalPlayer
        local ps = plr:FindFirstChild("PlayerScripts")
        if ps then
            local ms = ps:FindFirstChildWhichIsA("ModuleScript", true)
            if ms then
                require(ms)
            else
                error("ModuleScript not found")
            end
        else
            error("PlayerScripts not found")
        end
    end)
else
    exec["require"] = false
    info["require"] = "require ❌ NOT SUPPORTED [ ERROR: function not available ]"
    shared.testexecutor.require = false
end

if getfenv()["hookmetamethod"] then
    test("hookmetamethod", function()
        local obj = setmetatable({}, {__index = newcclosure(function() return false end), __metatable = "Locked!"})
        local ref = hookmetamethod(obj, "__index", function() return true end)
        assert(obj.test == true, "Failed to hook a metamethod and change the return value")
        assert(ref() == false, "Did not return the original function")
    end)
else
    exec["hookmetamethod"] = false
    info["hookmetamethod"] = "hookmetamethod ❌ NOT SUPPORTED [ ERROR: function not available ]"
    shared.testexecutor.hookmetamethod = false
end

local canFire = test("fireproximityprompt", function()
    local p = Instance.new("ProximityPrompt", Instance.new("Part", workspace))
    local triggered = false
    p.Triggered:Once(function() triggered = true end)
    fireproximityprompt(p)
    task.wait(0.1)
    p.Parent:Destroy()
    assert(triggered, "Failed to fire proximity prompt")
end)

shared.testexecutor.fireProximityPrompt = canFire

if not canFire then
    local function fireProx(p, look, instant)
        if not p:IsA("ProximityPrompt") then
            error("ProximityPrompt expected, received " .. typeof(p))
        end
        
        local pos = p.Parent:GetPivot().Position
        local oe, oh, ol = p.Enabled, p.HoldDuration, p.RequiresLineOfSight
        local oc = workspace.CurrentCamera.CFrame
        
        p.Enabled = true
        p.RequiresLineOfSight = false
        if instant ~= true then
            p.HoldDuration = 0
        end
        
        if look then
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, pos)
            task.wait()
        end
        
        p:InputHoldBegin()
        task.wait(p.HoldDuration + 0.05)
        p:InputHoldEnd()
        
        p.Enabled = oe
        p.HoldDuration = oh
        p.RequiresLineOfSight = ol
        workspace.CurrentCamera.CFrame = oc
    end
    exec.fireproximityprompt = fireProx
else
    exec.fireproximityprompt = fireproximityprompt
end

if getfenv()["isnetworkowner"] then
    test("isnetworkowner", function()
        local p = Instance.new("Part", workspace)
        p.Anchored = true
        local r = isnetworkowner(p)
        p:Destroy()
        return typeof(r) == "boolean"
    end)
elseif getfenv()["isnetowner"] then
    test("isnetowner", function()
        local p = Instance.new("Part", workspace)
        p.Anchored = true
        local r = isnetowner(p)
        p:Destroy()
        return typeof(r) == "boolean"
    end)
    
    function isnetworkowner(p)
        if not p:IsA("BasePart") then
            error("BasePart expected, received " .. typeof(p))
        end
        return isnetowner(p)
    end
    
    exec.isnetworkowner = true
    info.isnetworkowner = "isnetworkowner ✅ Supported (using isnetowner)"
    shared.testexecutor.isnetworkowner = true
else
    function isnetowner(p)
        if not p:IsA("BasePart") then
            error("BasePart expected, received " .. typeof(p))
        end
        return p.ReceiveAge == 0
    end
    
    exec.isnetworkowner = isnetowner
    exec.isnetowner = isnetowner
    info.isnetworkowner = "isnetworkowner ❌ NOT SUPPORTED [ ERROR: alternative implementation ]"
    shared.testexecutor.isnetworkowner = false
end

if getfenv()["firetouchinterest"] then
    test("firetouchinterest", function()
        local p1 = Instance.new("Part", workspace)
        local p2 = Instance.new("Part", workspace)
        p1.Position = Vector3.new(0, 10, 0)
        p2.Position = Vector3.new(0, 10, 5)
        
        local touched = false
        local conn = p1.Touched:Connect(function() touched = true end)
        
        firetouchinterest(p2, p1, 0)
        task.wait(0.1)
        firetouchinterest(p2, p1, 1)
        
        conn:Disconnect()
        p1:Destroy()
        p2:Destroy()
        
        assert(touched, "Failed to fire touch interest")
    end)
    exec.firetouch = firetouchinterest
elseif getfenv()["firetouchtransmitter"] then
    test("firetouchtransmitter", function()
        local p1 = Instance.new("Part", workspace)
        local p2 = Instance.new("Part", workspace)
        p1.Position = Vector3.new(0, 10, 0)
        p2.Position = Vector3.new(0, 10, 5)
        
        local touched = false
        local conn = p1.Touched:Connect(function() touched = true end)
        
        firetouchtransmitter(p2, p1)
        
        conn:Disconnect()
        p1:Destroy()
        p2:Destroy()
        
        assert(touched, "Failed to fire touch transmitter")
    end)
    exec.firetouch = firetouchtransmitter
else
    exec.firetouch = nil
    info.firetouch = "firetouch ❌ NOT SUPPORTED [ ERROR: function not available ]"
    shared.testexecutor.firetouch = false
end

if getfenv()["debug"] and debug.info then
    exec.debugger = true
    info.debugger = "debugger ✅ Supported"
    shared.testexecutor.debugger = true
else
    exec.debugger = false
    info.debugger = "debugger ❌ NOT SUPPORTED [ ERROR: debug.info not available ]"
    shared.testexecutor.debugger = false
end

safe("newcclosure", newcclosure)
safe("clonefunction", clonefunction)
safe("getscriptbytecode", getscriptbytecode)
safe("getscripthash", getscripthash)
safe("getloadedmodules", getloadedmodules)
safe("getrunningscripts", getrunningscripts)
safe("getscripts", getscripts)
safe("getconstants", getconstants)
safe("getupvalues", getupvalues)
safe("setupvalue", setupvalue)
safe("getprotos", getprotos)
safe("getstack", getstack)
safe("setstack", setstack)

safe("getthreadidentity", getthreadidentity)
safe("setthreadidentity", setthreadidentity)
safe("getidentity", getidentity)
safe("setidentity", setidentity)

if crypt then
    exec["crypt"] = true
    info["crypt"] = "crypt ✅ Supported"
    shared.testexecutor["crypt"] = true
    
    if typeof(crypt.encrypt) == "function" then
        exec["crypt.encrypt"] = true
        info["crypt.encrypt"] = "crypt.encrypt ✅ Supported"
        shared.testexecutor["crypt.encrypt"] = true
    else
        exec["crypt.encrypt"] = false
        info["crypt.encrypt"] = "crypt.encrypt ❌ NOT SUPPORTED"
        shared.testexecutor["crypt.encrypt"] = false
    end
    
    if typeof(crypt.decrypt) == "function" then
        exec["crypt.decrypt"] = true
        info["crypt.decrypt"] = "crypt.decrypt ✅ Supported"
        shared.testexecutor["crypt.decrypt"] = true
    else
        exec["crypt.decrypt"] = false
        info["crypt.decrypt"] = "crypt.decrypt ❌ NOT SUPPORTED"
        shared.testexecutor["crypt.decrypt"] = false
    end
    
    if typeof(crypt.base64encode) == "function" or typeof(crypt.base64_encode) == "function" then
        exec["crypt.base64encode"] = true
        info["crypt.base64encode"] = "crypt.base64encode ✅ Supported"
        shared.testexecutor["crypt.base64encode"] = true
    else
        exec["crypt.base64encode"] = false
        info["crypt.base64encode"] = "crypt.base64encode ❌ NOT SUPPORTED"
        shared.testexecutor["crypt.base64encode"] = false
    end
    
    if typeof(crypt.base64decode) == "function" or typeof(crypt.base64_decode) == "function" then
        exec["crypt.base64decode"] = true
        info["crypt.base64decode"] = "crypt.base64decode ✅ Supported"
        shared.testexecutor["crypt.base64decode"] = true
    else
        exec["crypt.base64decode"] = false
        info["crypt.base64decode"] = "crypt.base64decode ❌ NOT SUPPORTED"
        shared.testexecutor["crypt.base64decode"] = false
    end
else
    exec["crypt"] = false
    exec["crypt.encrypt"] = false
    exec["crypt.decrypt"] = false
    exec["crypt.base64encode"] = false
    exec["crypt.base64decode"] = false
    info["crypt"] = "crypt ❌ NOT SUPPORTED [ ERROR: crypt library not available ]"
    info["crypt.encrypt"] = "crypt.encrypt ❌ NOT SUPPORTED [ ERROR: crypt library not available ]"
    info["crypt.decrypt"] = "crypt.decrypt ❌ NOT SUPPORTED [ ERROR: crypt library not available ]"
    info["crypt.base64encode"] = "crypt.base64encode ❌ NOT SUPPORTED [ ERROR: crypt library not available ]"
    info["crypt.base64decode"] = "crypt.base64decode ❌ NOT SUPPORTED [ ERROR: crypt library not available ]"
    shared.testexecutor["crypt"] = false
    shared.testexecutor["crypt.encrypt"] = false
    shared.testexecutor["crypt.decrypt"] = false
    shared.testexecutor["crypt.base64encode"] = false
    shared.testexecutor["crypt.base64decode"] = false
end

safe("rconsoleprint", rconsoleprint)
safe("rconsoleclear", rconsoleclear)
safe("rconsolecreate", rconsolecreate)
safe("rconsoledestroy", rconsoledestroy)
safe("rconsoleinput", rconsoleinput)
safe("rconsolename", rconsolename)
safe("rconsolesettitle", rconsolesettitle)

local pid = game.PlaceId
local uid = nil
local ok, res = pcall(function()
    return game:GetService("MarketplaceService"):GetProductInfo(pid).UniverseId
end)
if ok then
    uid = res
end

shared.testexecutor.placeId = pid
shared.testexecutor.universeId = uid

shared.testexecutor.supportFileSystem = (exec["isfile"] and exec["delfile"] and exec["listfiles"] and exec["writefile"] and exec["makefolder"] and exec["isfolder"])
shared.testexecutor.supportEditFiles = (exec["writefile"] and exec["appendfile"] and exec["delfile"])
shared.testexecutor.supportDrawing = exec["Drawing.new"] or false
shared.testexecutor.supportHTTP = (exec["request"] or exec["http_request"] or exec["syn.request"] or exec["httprequest"]) or false
shared.testexecutor.supportWebSocket = exec["WebSocket"] or false
shared.testexecutor.supportCrypt = exec["crypt"] or false

local groups = {
    ["File System"] = {"readfile", "listfiles", "writefile", "makefolder", "appendfile", "isfile", "isfolder", "delfile", "delfolder", "loadfile"},
    ["Environment Access"] = {"getrenv", "getgenv", "getsenv", "getfenv", "getrawmetatable", "setrawmetatable", "setreadonly", "getnamecallmethod", "isluau", "checkcaller"},
    ["HTTP & Network"] = {"request", "http_request", "syn.request", "httprequest", "WebSocket", "WebSocket.connect"},
    ["Interface & User"] = {"gethui", "getgc", "getinstances", "getnilinstances", "sethiddenproperty", "gethiddenproperty", "saveinstance", "setclipboard", "getcustomasset", "getsynasset"},
    ["Interaction"] = {"fireclickdetector", "fireproximityprompt", "firetouchinterest", "firetouchtransmitter", "mouse1click", "mouse1press", "mouse1release", "mouse2click", "keypress", "keyrelease"},
    ["Events & Connections"] = {"getconnections", "firesignal", "hookmetamethod", "queue_on_teleport"},
    ["Drawing"] = {"Drawing", "Drawing.new"},
    ["Scripts & Modules"] = {"require", "getcallingscript", "debugger", "newcclosure", "clonefunction", "getscriptbytecode", "getscripthash", "getloadedmodules", "getrunningscripts", "getscripts"},
    ["Physics & Network"] = {"isnetworkowner", "isnetowner"},
    ["Debugging"] = {"getconstants", "getupvalues", "setupvalue", "getprotos", "getstack", "setstack"},
    ["Identity"] = {"getthreadidentity", "setthreadidentity", "getidentity", "setidentity"},
    ["Cryptography"] = {"crypt", "crypt.encrypt", "crypt.decrypt", "crypt.base64encode", "crypt.base64decode"},
    ["Console"] = {"rconsoleprint", "rconsoleclear", "rconsolecreate", "rconsoledestroy", "rconsoleinput", "rconsolename", "rconsolesettitle"}
}

exec["_ExecutorName"] = name
exec["_ExecutorVersion"] = ver
exec["_ExecutorFullInfo"] = full
exec["_OSType"] = os_type
exec["_SupportsFileSystem"] = shared.testexecutor.supportFileSystem
exec["_SupportsHTTP"] = shared.testexecutor.supportHTTP
exec["_SupportsDrawing"] = shared.testexecutor.supportDrawing
exec["_SupportsWebSocket"] = shared.testexecutor.supportWebSocket
exec["_SupportsCrypt"] = shared.testexecutor.supportCrypt
exec["_PlaceId"] = pid
exec["_UniverseId"] = uid

local function log(txt)
    print(txt)
    table.insert(logs, txt)
end

local function save()
    if not exec["writefile"] or not exec["makefolder"] then
        print("\n⚠️ Cannot save log: file system not supported")
        return false
    end
    
    if not isfolder(dir) then
        pcall(function() makefolder(dir) end)
    end
    
    local ok, err = pcall(function()
        writefile(path, table.concat(logs, "\n"))
    end)
    
    if ok then
        print("\n✅ Log saved at: " .. path)
        return true
    else
        print("\n⚠️ Error saving log: " .. tostring(err))
        return false
    end
end

shared.testexecutor.logPath = path

log("\n\n")
log("═════════════════════════════════════════════")
log("EXECUTOR COMPATIBILITY ANALYSIS")
log("═════════════════════════════════════════════")
log("> Executor: " .. full)
log("> System: " .. os_type)

local gameInfo = "Unknown"
pcall(function()
    gameInfo = game:GetService("MarketplaceService"):GetProductInfo(pid).Name
end)
log("> Game: " .. gameInfo)
log("> Place ID: " .. pid)
if uid then
    log("🌌 Universe ID: " .. uid)
end
log("⏰ Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S", shared.testexecutor.timestamp))

log("\n CAPABILITY SUMMARY: ")
log("✅ File System: " .. (exec["_SupportsFileSystem"] and "Supported" or "Not supported"))
log("✅ HTTP: " .. (exec["_SupportsHTTP"] and "Supported" or "Not supported"))
log("✅ Drawing: " .. (exec["_SupportsDrawing"] and "Supported" or "Not supported"))
log("✅ WebSocket: " .. (exec["_SupportsWebSocket"] and "Supported" or "Not supported"))
log("✅ Cryptography: " .. (exec["_SupportsCrypt"] and "Supported" or "Not supported"))
log("✅ ProximityPrompt: " .. (canFire and "Supported" or "Alternative implementation"))

for gn, feats in pairs(groups) do
    local gc = 0
    local tf = #feats
    
    for _, fn in ipairs(feats) do
        if exec[fn] then
            gc = gc + 1
        end
    end
    
    local pct = math.floor((gc / tf) * 100)
    local bl = 20
    local fb = math.floor((pct / 100) * bl)
    local bar = string.rep("█", fb) .. string.rep("░", bl - fb)
    
    log("\n " .. gn .. " (" .. pct .. "%)")
    log(bar .. " " .. gc .. "/" .. tf)
    
    for _, fn in ipairs(feats) do
        if info[fn] then
            log(info[fn])
        elseif exec[fn] ~= nil then
            log((exec[fn] and "✅" or "❌") .. " [" .. fn .. "]")
        else
            log("❓ [" .. fn .. "] (not tested)")
        end
    end
end

local gvs = {}
for k, v in pairs(shared.testexecutor) do
    table.insert(gvs, {key = k, value = v})
end

table.sort(gvs, function(a, b) return a.key < b.key end)

for _, gv in ipairs(gvs) do
    log(gv.key .. " = " .. tostring(gv.value))
end

return shared.testexecutor
