if shared.testexecutor then
    return shared.testexecutor
end
print(" Testing your executor... ")

local exec = {}
local info = {}

shared.testexecutor = {}

local REQUIRED_FUNCTIONS = {
    "replicatesignal",
    "hookmetamethod",
    "isnetworkowner",
    "firesignal",
    "require",
}

local function isRequired(n)
    for _, v in ipairs(REQUIRED_FUNCTIONS) do
        if v == n then return true end
    end
    return false
end

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
    if not isRequired(n) then return end
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
    if not isRequired(n) then return end
    if getfenv()[n] then
        test(n, f, false)
    else
        exec[n] = false
        info[n] = n .. " ❌ NOT SUPPORTED [ ERROR: FUNCTION NOT AVAILABLE ]"
        shared.testexecutor[n] = false
    end
end

safe("firesignal", firesignal)
safe("replicatesignal", replicatesignal)

if isRequired("hookmetamethod") then
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
end

if isRequired("isnetworkowner") then
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
end

if isRequired("require") then
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
end

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

exec["_ExecutorName"] = name
exec["_ExecutorVersion"] = ver
exec["_ExecutorFullInfo"] = full
exec["_OSType"] = os_type
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

log("\n TESTED FUNCTIONS: ")
for _, fn in ipairs(REQUIRED_FUNCTIONS) do
    if info[fn] then
        log(info[fn])
    elseif exec[fn] ~= nil then
        log((exec[fn] and "✅" or "❌") .. " [" .. fn .. "]")
    else
        log("❓ [" .. fn .. "] (not tested)")
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
