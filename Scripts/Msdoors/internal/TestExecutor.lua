-- Based on: https://github.com/mspaint-cc/mspaint/blob/main/Src/Utils/ExecutorSupport.luau

if shared.testexecutor then
    return shared.testexecutor
end

local exec = {}
local errors = {}

shared.testexecutor = {}

local REQUIRED_FUNCTIONS = {
    "replicatesignal",
    "hookmetamethod",
    "isnetworkowner",
    "firesignal",
    "require",
    "fireproximityprompt"
}

local function isRequired(n)
    for _, v in ipairs(REQUIRED_FUNCTIONS) do
        if v == n then return true end
    end
    return false
end

local function fmtTime()
    local t = os.date("*t")
    return string.format("%04d-%02d-%02d_%02d-%02d-%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

local dt = fmtTime()
local dir = "msdoors/executorlog"
local file = "log-msdoors" .. dt .. ".txt"
local path = dir .. "/" .. file

local name = "Unknown"

pcall(function()
    local full = identifyexecutor() or "None"
    local parts = string.split(full, " ")
    name = parts[1] or "Unknown"
end)

shared.testexecutor.name = name

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

local function test(n, f, cb)
    if not isRequired(n) then return false end
    if broken[name] and broken[name][n] then return false end

    local success, err = false, nil
    if cb ~= false then
        success, err = pcall(f)
    else
        success = typeof(f) == "function"
    end

    if not success then
        table.insert(errors, "[" .. n .. "] " .. (err and tostring(err) or "FAILED"))
    end

    exec[n] = success
    shared.testexecutor[n] = success
    return success
end

local function safe(n, f)
    if not isRequired(n) then return end
    if getfenv()[n] then
        test(n, f, false)
    else
        exec[n] = false
        shared.testexecutor[n] = false
        table.insert(errors, "[" .. n .. "] FUNCTION NOT AVAILABLE")
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

safe("fireclickdetector", fireclickdetector)
safe("mouse1click", mouse1click)
safe("mouse1press", mouse1press)
safe("mouse1release", mouse1release)
safe("mouse2click", mouse2click)
safe("keypress", keypress)
safe("keyrelease", keyrelease)

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
        shared.testexecutor.require = false
        table.insert(errors, "[require] FUNCTION NOT AVAILABLE")
    end
end

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
        shared.testexecutor.hookmetamethod = false
        table.insert(errors, "[hookmetamethod] FUNCTION NOT AVAILABLE")
    end
end

local canFire = false
if isRequired("fireproximityprompt") then
    canFire = test("fireproximityprompt", function()
        local p = Instance.new("ProximityPrompt", Instance.new("Part", workspace))
        local triggered = false
        p.Triggered:Once(function() triggered = true end)
        fireproximityprompt(p)
        task.wait(0.1)
        p.Parent:Destroy()
        assert(triggered, "Failed to fire proximity prompt")
    end)
    shared.testexecutor.fireProximityPrompt = canFire
end

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

if canFire then
    getgenv().msdoors_fireprompt = function(prompt, look)
        return fireproximityprompt(prompt, look)
    end
else
    getgenv().msdoors_fireprompt = function(prompt, look)
        return fireProx(prompt, look)
    end
    getgenv().fireproximityprompt = getgenv().msdoors_fireprompt
end

if isRequired("isnetworkowner") then
    if getfenv()["isnetworkowner"] then
        test("isnetworkowner", function()
            local p = Instance.new("Part", workspace)
            p.Anchored = true
            local r = isnetworkowner(p)
            p:Destroy()
            assert(typeof(r) == "boolean", "Expected boolean")
        end)
    elseif getfenv()["isnetowner"] then
        local ok2, err2 = pcall(function()
            local p = Instance.new("Part", workspace)
            p.Anchored = true
            local r = isnetowner(p)
            p:Destroy()
            assert(typeof(r) == "boolean", "Expected boolean")
        end)
        exec["isnetworkowner"] = ok2
        shared.testexecutor.isnetworkowner = ok2
        if not ok2 then
            table.insert(errors, "[isnetworkowner] " .. (err2 and tostring(err2) or "FAILED"))
        end
        getgenv().isnetworkowner = function(p)
            if not p:IsA("BasePart") then
                error("BasePart expected, received " .. typeof(p))
            end
            return isnetowner(p)
        end
    else
        exec["isnetworkowner"] = false
        shared.testexecutor.isnetworkowner = false
        table.insert(errors, "[isnetworkowner] FUNCTION NOT AVAILABLE - fallback active")
        getgenv().isnetworkowner = function(p)
            if not p:IsA("BasePart") then
                error("BasePart expected, received " .. typeof(p))
            end
            return p.ReceiveAge == 0
        end
    end
end

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
safe("rconsoleprint", rconsoleprint)
safe("rconsoleclear", rconsoleclear)
safe("rconsolecreate", rconsolecreate)
safe("rconsoledestroy", rconsoledestroy)
safe("rconsoleinput", rconsoleinput)
safe("rconsolename", rconsolename)
safe("rconsolesettitle", rconsolesettitle)
safe("newcclosure", newcclosure)
safe("clonefunction", clonefunction)
safe("getscriptbytecode", getscriptbytecode)
safe("getscripthash", getscripthash)
safe("getloadedmodules", getloadedmodules)

shared.testexecutor.logPath = path
shared.testexecutor.supportFileSystem = (exec["isfile"] and exec["delfile"] and exec["listfiles"] and exec["writefile"] and exec["makefolder"] and exec["isfolder"])

for n, result in pairs(exec) do
    if result == true then
        print("✅ [" .. n .. "]")
    end
end

local function save()
    if not exec["writefile"] or not exec["makefolder"] then return false end

    if not isfolder(dir) then
        pcall(function() makefolder(dir) end)
    end

    local lines = {}

    for n, result in pairs(exec) do
        if result == true then
            table.insert(lines, "✅ [" .. n .. "]")
        end
    end

    if #errors > 0 then
        table.insert(lines, "")
        table.insert(lines, "--- ERRORS ---")
        for _, errMsg in ipairs(errors) do
            table.insert(lines, "❌ " .. errMsg)
        end
    end

    local saveOk, saveErr = pcall(function()
        writefile(path, table.concat(lines, "\n"))
    end)

    if not saveOk then
        table.insert(errors, "[save] " .. (saveErr and tostring(saveErr) or "FAILED"))
        for _, errMsg in ipairs(errors) do
            print("❌ " .. errMsg)
        end
        return false
    end

    return true
end

save()

return shared.testexecutor
