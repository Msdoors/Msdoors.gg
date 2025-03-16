local ExecutorSupport = {}
local ExecutorSupportInfo = {}

local executorName = "Desconhecido"
if pcall(function() executorName = string.split(identifyexecutor() or "None", " ")[1] end) then
else
    executorName = "Desconhecido"
end

local brokenFeatures = {
    ["Arceus"] = { "require" },
    ["Codex"] = { "require" },
    ["VegaX"] = { "require" },
}

local function test(name, func, shouldCallback)
    if typeof(brokenFeatures[executorName]) == "table" and table.find(brokenFeatures[executorName], name) then
        return false
    end
    
    local success, errorMessage = false, nil
    if shouldCallback ~= false then
        success, errorMessage = pcall(func)
    else
        success = typeof(func) == "function"
    end
    
    ExecutorSupportInfo[name] = string.format("%s [%s]%s", (if success then "✅" else "❌"), name, (if errorMessage then (": " .. tostring(errorMessage)) else ""))
    ExecutorSupport[name] = success
    return success
end

local function safeTest(name, func)
    if getfenv()[name] then
        test(name, func, false)
    else
        ExecutorSupport[name] = false
        ExecutorSupportInfo[name] = "❌ [" .. name .. "] (não disponível)"
    end
end

safeTest("readfile", readfile)
safeTest("listfiles", listfiles)
safeTest("writefile", writefile)
safeTest("makefolder", makefolder)
safeTest("appendfile", appendfile)
safeTest("isfile", isfile)
safeTest("isfolder", isfolder)
safeTest("delfile", delfile)
safeTest("delfolder", delfolder)
safeTest("loadfile", loadfile)
safeTest("getrenv", getrenv)
safeTest("queue_on_teleport", queue_on_teleport)
safeTest("getcallingscript", getcallingscript)

if getfenv()["require"] then
    test("require", function()
        local player = game:GetService("Players").LocalPlayer
        local moduleScript = player:WaitForChild("PlayerScripts", math.huge):FindFirstChildWhichIsA("ModuleScript", true)
        if moduleScript then
            require(moduleScript)
        else
            error("ModuleScript não encontrado")
        end
    end)
end

if getfenv()["hookmetamethod"] then
    test("hookmetamethod", function()
        local object = setmetatable({}, { __index = newcclosure(function() return false end), __metatable = "Locked!" })
        local ref = hookmetamethod(object, "__index", function() return true end)
        assert(object.test == true, "Failed to hook a metamethod and change the return value")
        assert(ref() == false, "Did not return the original function")
    end)
end

local canFirePrompt = test("fireproximityprompt", function()
    local prompt = Instance.new("ProximityPrompt", Instance.new("Part", workspace))
    local triggered = false

    prompt.Triggered:Once(function() triggered = true end)

    fireproximityprompt(prompt)
    task.wait(0.1)

    prompt.Parent:Destroy()
    assert(triggered, "Failed to fire proximity prompt")
end)

if not canFirePrompt then
    local function fireProximityPrompt(prompt, lookToPrompt, doNotDoInstant)
        if not prompt:IsA("ProximityPrompt") then
            return error("ProximityPrompt esperado, recebeu " .. typeof(prompt))
        end

        local promptPosition = prompt.Parent:GetPivot().Position
        local originalEnabled, originalHold, originalLineOfSight = prompt.Enabled, prompt.HoldDuration, prompt.RequiresLineOfSight
        local originalCamCFrame = workspace.CurrentCamera.CFrame
        
        prompt.Enabled = true
        prompt.RequiresLineOfSight = false
        if doNotDoInstant ~= true then
            prompt.HoldDuration = 0
        end

        if lookToPrompt then
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, promptPosition)
            task.wait()
        end

        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration + 0.05)
        prompt:InputHoldEnd()

        prompt.Enabled = originalEnabled
        prompt.HoldDuration = originalHold
        prompt.RequiresLineOfSight = originalLineOfSight
        workspace.CurrentCamera.CFrame = originalCamCFrame
    end

    ExecutorSupport.fireproximityprompt = fireProximityPrompt
else
    ExecutorSupport.fireproximityprompt = fireproximityprompt
end

if not getfenv()["isnetworkowner"] then
    function isnetowner(part)
        if not part:IsA("BasePart") then
            return error("BasePart esperado, recebeu " .. typeof(part))
        end
        return part.ReceiveAge == 0
    end
    
    ExecutorSupport.isnetworkowner = isnetowner
else
    ExecutorSupport.isnetworkowner = isnetworkowner
end

if getfenv()["firetouchinterest"] then
    ExecutorSupport.firetouch = firetouchinterest
elseif getfenv()["firetouchtransmitter"] then
    ExecutorSupport.firetouch = firetouchtransmitter
else
    ExecutorSupport.firetouch = nil
end

ExecutorSupport["_ExecutorName"] = executorName
ExecutorSupport["_SupportsFileSystem"] = (ExecutorSupport["isfile"] and ExecutorSupport["delfile"] and ExecutorSupport["listfiles"] and ExecutorSupport["writefile"] and ExecutorSupport["makefolder"] and ExecutorSupport["isfolder"])

for name, result in pairs(ExecutorSupport) do
    if ExecutorSupportInfo[name] then
        print(ExecutorSupportInfo[name]) 
    elseif name:gsub("_", "") ~= name then
        print("🛠️ [" .. tostring(name) .. "]", tostring(result))
    else
        print("❓ [" .. tostring(name) .. "]", tostring(result))
    end
end

return ExecutorSupport
    
