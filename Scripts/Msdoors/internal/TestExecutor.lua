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

local name, ver, full = "Desconhecido", "Desconhecido", "Desconhecido"

local ok = pcall(function()
    full = identifyexecutor() or "None"
    local parts = string.split(full, " ")
    name = parts[1] or "Desconhecido"
    if #parts > 1 then
        table.remove(parts, 1)
        ver = table.concat(parts, " ")
    end
end)

if not ok then
    name, ver, full = "Desconhecido", "Desconhecido", "Desconhecido"
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
    Temple = {require = true, hookmetamethod = true}
}

local os_type = "Desconhecido"
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
        errorMsg = " [ ERRO: " .. tostring(err) .. " ]"
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
        info[n] = n .. " ❌ NOT SUPPORTED [ ERRO: FUNCTION NOT AVAILABLE ]"
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
    info["syn.request"] = "syn.request ❌ NOT SUPPORTED [ ERRO: biblioteca syn não disponível ]"
    shared.testexecutor["syn.request"] = false
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
        info["Drawing.new"] = "Drawing.new ❌ NOT SUPPORTED [ ERRO: método new não disponível ]"
        shared.testexecutor["Drawing.new"] = false
    end
else
    exec["Drawing"] = false
    exec["Drawing.new"] = false
    info["Drawing"] = "Drawing ❌ NOT SUPPORTED [ ERRO: biblioteca Drawing não disponível ]"
    info["Drawing.new"] = "Drawing.new ❌ NOT SUPPORTED [ ERRO: biblioteca Drawing não disponível ]"
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
                error("ModuleScript não encontrado")
            end
        else
            error("PlayerScripts não encontrado")
        end
    end)
else
    exec["require"] = false
    info["require"] = "require ❌ NOT SUPPORTED [ ERRO: função não disponível ]"
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
    info["hookmetamethod"] = "hookmetamethod ❌ NOT SUPPORTED [ ERRO: função não disponível ]"
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
            error("ProximityPrompt esperado, recebeu " .. typeof(p))
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
            error("BasePart esperado, recebeu " .. typeof(p))
        end
        return isnetowner(p)
    end
    
    exec.isnetworkowner = true
    info.isnetworkowner = "isnetworkowner ✅ Supported (usando isnetowner)"
    shared.testexecutor.isnetworkowner = true
else
    function isnetowner(p)
        if not p:IsA("BasePart") then
            error("BasePart esperado, recebeu " .. typeof(p))
        end
        return p.ReceiveAge == 0
    end
    
    exec.isnetworkowner = isnetowner
    exec.isnetowner = isnetowner
    info.isnetworkowner = "isnetworkowner ❌ NOT SUPPORTED [ ERRO: implementação alternativa ]"
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
    info.firetouch = "firetouch ❌ NOT SUPPORTED [ ERRO: função não disponível ]"
    shared.testexecutor.firetouch = false
end

if getfenv()["debug"] and debug.info then
    exec.debugger = true
    info.debugger = "debugger ✅ Supported"
    shared.testexecutor.debugger = true
else
    exec.debugger = false
    info.debugger = "debugger ❌ NOT SUPPORTED [ ERRO: debug.info não disponível ]"
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

local groups = {
    ["Sistema de Arquivos"] = {"readfile", "listfiles", "writefile", "makefolder", "appendfile", "isfile", "isfolder", "delfile", "delfolder", "loadfile"},
    ["Acesso ao Ambiente"] = {"getrenv", "getgenv", "getsenv", "getfenv", "getrawmetatable", "setrawmetatable", "setreadonly", "getnamecallmethod", "isluau", "checkcaller"},
    ["HTTP e Rede"] = {"request", "http_request", "syn.request", "httprequest"},
    ["Interface e Usuário"] = {"gethui", "getgc", "getinstances", "getnilinstances", "sethiddenproperty", "gethiddenproperty", "saveinstance", "setclipboard", "getcustomasset", "getsynasset"},
    ["Interação"] = {"fireclickdetector", "fireproximityprompt", "firetouchinterest", "firetouchtransmitter", "mouse1click", "mouse1press", "mouse1release", "mouse2click", "keypress", "keyrelease"},
    ["Eventos e Conexões"] = {"getconnections", "firesignal", "hookmetamethod", "queue_on_teleport"},
    ["Desenho"] = {"Drawing", "Drawing.new"},
    ["Scripts e Módulos"] = {"require", "getcallingscript", "debugger", "newcclosure", "clonefunction", "getscriptbytecode", "getscripthash", "getloadedmodules", "getrunningscripts", "getscripts"},
    ["Física e Rede"] = {"isnetworkowner", "isnetowner"},
    ["Debugging"] = {"getconstants", "getupvalues", "setupvalue", "getprotos", "getstack", "setstack"}
}

exec["_ExecutorName"] = name
exec["_ExecutorVersion"] = ver
exec["_ExecutorFullInfo"] = full
exec["_OSType"] = os_type
exec["_SupportsFileSystem"] = shared.testexecutor.supportFileSystem
exec["_SupportsHTTP"] = shared.testexecutor.supportHTTP
exec["_SupportsDrawing"] = shared.testexecutor.supportDrawing
exec["_PlaceId"] = pid
exec["_UniverseId"] = uid

local function log(txt)
    print(txt)
    table.insert(logs, txt)
end

local function save()
    if not exec["writefile"] or not exec["makefolder"] then
        print("\n⚠️ Não foi possível salvar o log: sistema de arquivos não suportado")
        return false
    end
    
    if not isfolder(dir) then
        pcall(function() makefolder(dir) end)
    end
    
    local ok, err = pcall(function()
        writefile(path, table.concat(logs, "\n"))
    end)
    
    if ok then
        print("\n✅ Log salvo em: " .. path)
        return true
    else
        print("\n⚠️ Erro ao salvar log: " .. tostring(err))
        return false
    end
end

shared.testexecutor.logPath = path

log("\n\n")
log("═════════════════════════════════════════════")
log("EXECUTOR COMPATIBILITY ANALYSIS")
log("═════════════════════════════════════════════")
log("> Executor: " .. full)
log("> Sistema: " .. os_type)

local gameInfo = "Desconhecido"
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
log("✅ File System: " .. (exec["_SupportsFileSystem"] and "Suportado" or "Não suportado"))
log("✅ HTTP: " .. (exec["_SupportsHTTP"] and "Suportado" or "Não suportado"))
log("✅ Drawing: " .. (exec["_SupportsDrawing"] and "Suportado" or "Não suportado"))
log("✅ ProximityPrompt: " .. (canFire and "Suportado" or "Implementação alternativa"))

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
            log("❓ [" .. fn .. "] (não testado)")
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

-- save()  PAROU!

return shared.testexecutor
