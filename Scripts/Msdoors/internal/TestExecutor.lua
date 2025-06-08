if _G.msdoors_checkexecutor then
    return
end

local ExecutorSupport = {}
local ExecutorSupportInfo = {}
local GlobalVariablePrefix = "msdoors_executorinfo_"

_G[GlobalVariablePrefix .. "timestamp"] = os.time()
_G[GlobalVariablePrefix .. "version"] = "1.3.0"

local function formatDateTime()
    local dateTime = os.date("*t")
    return string.format(
        "%04d-%02d-%02d_%02d-%02d-%02d",
        dateTime.year, 
        dateTime.month, 
        dateTime.day, 
        dateTime.hour, 
        dateTime.min, 
        dateTime.sec
    )
end

local logDateTime = formatDateTime()
local logFolder = "msdoors/executorlog"
local logFilename = "log-msdoors" .. logDateTime .. ".txt"
local logPath = logFolder .. "/" .. logFilename

local logContent = {}

local executorName = "Desconhecido"
local executorVersion = "Desconhecido"
local executorFullInfo = "Desconhecido"

if pcall(function() 
    executorFullInfo = identifyexecutor() or "None"
    local parts = string.split(executorFullInfo, " ")
    executorName = parts[1] or "Desconhecido"
    if #parts > 1 then
        table.remove(parts, 1)
        executorVersion = table.concat(parts, " ")
    end
end) then
else
    executorName = "Desconhecido"
    executorVersion = "Desconhecido"
    executorFullInfo = "Desconhecido"
end

_G[GlobalVariablePrefix .. "name"] = executorName
_G[GlobalVariablePrefix .. "version"] = executorVersion
_G[GlobalVariablePrefix .. "fullInfo"] = executorFullInfo

local brokenFeatures = {
    ["Arceus"] = { "require" },
    ["Codex"] = { "require" },
    ["VegaX"] = { "require" },
    ["Electron"] = { "gcinfo", "require" },
    ["Krnl"] = {},
    ["Synapse"] = {},
    ["Fluxus"] = {},
    ["Script-Ware"] = {},
    ["Oxygen"] = { "fireclickdetector" },
    ["Hydrogen"] = { "fireclickdetector" },
    ["Temple"] = { "require", "hookmetamethod" },
}

local osType = "Desconhecido"
if identifyexecutor and typeof(identifyexecutor) == "function" then
    local execInfo = string.lower(identifyexecutor() or "")
    if string.find(execInfo, "windows") then
        osType = "Windows"
    elseif string.find(execInfo, "mac") or string.find(execInfo, "macos") then
        osType = "MacOS"
    elseif string.find(execInfo, "ios") or string.find(execInfo, "iphone") or string.find(execInfo, "ipad") then
        osType = "iOS"
    elseif string.find(execInfo, "android") then
        osType = "Android"
    elseif string.find(execInfo, "linux") then
        osType = "Linux"
    end
end

_G[GlobalVariablePrefix .. "osType"] = osType

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
    
    ExecutorSupportInfo[name] = string.format("%s [%s]%s", (success and "✅" or "❌"), name, (errorMessage and (": " .. tostring(errorMessage)) or ""))
    ExecutorSupport[name] = success
    _G[GlobalVariablePrefix .. "support" .. name] = success
    return success
end

local function safeTest(name, func)
    if getfenv()[name] then
        test(name, func, false)
    else
        ExecutorSupport[name] = false
        ExecutorSupportInfo[name] = "❌ [" .. name .. "] (não disponível)"
        _G[GlobalVariablePrefix .. "support" .. name] = false
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
safeTest("getgenv", getgenv)
safeTest("getsenv", getsenv)
safeTest("getfenv", getfenv)
safeTest("getrawmetatable", getrawmetatable)
safeTest("setrawmetatable", setrawmetatable)
safeTest("setreadonly", setreadonly)
safeTest("getnamecallmethod", getnamecallmethod)
safeTest("setclipboard", setclipboard)
safeTest("getcustomasset", getcustomasset)
safeTest("getsynasset", getsynasset)
safeTest("isluau", isluau)
safeTest("checkcaller", checkcaller)

safeTest("request", request)
safeTest("http_request", http_request)
safeTest("syn.request", function() return syn and syn.request end)
safeTest("httprequest", httprequest)

safeTest("queue_on_teleport", queue_on_teleport)
safeTest("getcallingscript", getcallingscript)
safeTest("gethui", gethui)
safeTest("getgc", getgc)
safeTest("getinstances", getinstances)
safeTest("getnilinstances", getnilinstances)
safeTest("sethiddenproperty", sethiddenproperty)
safeTest("gethiddenproperty", gethiddenproperty)
safeTest("saveinstance", saveinstance)
safeTest("getconnections", getconnections)
safeTest("firesignal", firesignal)

safeTest("Drawing", function() return Drawing ~= nil end)
safeTest("Drawing.new", function() return Drawing and Drawing.new end)

safeTest("fireclickdetector", fireclickdetector)
safeTest("mouse1click", mouse1click)
safeTest("mouse1press", mouse1press)
safeTest("mouse1release", mouse1release)
safeTest("mouse2click", mouse2click)
safeTest("keypress", keypress)
safeTest("keyrelease", keyrelease)

if getfenv()["require"] then
    test("require", function()
        local player = game:GetService("Players").LocalPlayer
        local playerScripts = player:FindFirstChild("PlayerScripts")
        if playerScripts then
            local moduleScript = playerScripts:FindFirstChildWhichIsA("ModuleScript", true)
            if moduleScript then
                require(moduleScript)
            else
                error("ModuleScript não encontrado")
            end
        else
            error("PlayerScripts não encontrado")
        end
    end)
else
    ExecutorSupport["require"] = false
    ExecutorSupportInfo["require"] = "❌ [require] (não disponível)"
    _G[GlobalVariablePrefix .. "supportrequire"] = false
end

if getfenv()["hookmetamethod"] then
    test("hookmetamethod", function()
        local object = setmetatable({}, { __index = newcclosure(function() return false end), __metatable = "Locked!" })
        local ref = hookmetamethod(object, "__index", function() return true end)
        assert(object.test == true, "Failed to hook a metamethod and change the return value")
        assert(ref() == false, "Did not return the original function")
    end)
else
    ExecutorSupport["hookmetamethod"] = false
    ExecutorSupportInfo["hookmetamethod"] = "❌ [hookmetamethod] (não disponível)"
    _G[GlobalVariablePrefix .. "supporthookmetamethod"] = false
end

-- Teste de fireproximityprompt
local canFirePrompt = test("fireproximityprompt", function()
    local prompt = Instance.new("ProximityPrompt", Instance.new("Part", workspace))
    local triggered = false

    prompt.Triggered:Once(function() triggered = true end)
    fireproximityprompt(prompt)
    task.wait(0.1)
    prompt.Parent:Destroy()
    
    assert(triggered, "Failed to fire proximity prompt")
end)

_G[GlobalVariablePrefix .. "supportfireProximityPrompt"] = canFirePrompt

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

-- Teste de isnetworkowner
if getfenv()["isnetworkowner"] then
    test("isnetworkowner", function()
        local part = Instance.new("Part", workspace)
        part.Anchored = true
        local result = isnetworkowner(part)
        part:Destroy()
        return typeof(result) == "boolean"
    end)
elseif getfenv()["isnetowner"] then
    test("isnetowner", function()
        local part = Instance.new("Part", workspace)
        part.Anchored = true
        local result = isnetowner(part)
        part:Destroy()
        return typeof(result) == "boolean"
    end)
    
    -- Criar um alias para isnetworkowner
    function isnetworkowner(part)
        if not part:IsA("BasePart") then
            return error("BasePart esperado, recebeu " .. typeof(part))
        end
        return isnetowner(part)
    end
    
    ExecutorSupport.isnetworkowner = true
    ExecutorSupportInfo.isnetworkowner = "✅ [isnetworkowner] (usando isnetowner)"
    _G[GlobalVariablePrefix .. "supportisnetworkowner"] = true
else
    function isnetowner(part)
        if not part:IsA("BasePart") then
            return error("BasePart esperado, recebeu " .. typeof(part))
        end
        return part.ReceiveAge == 0
    end
    
    ExecutorSupport.isnetworkowner = isnetowner
    ExecutorSupport.isnetowner = isnetowner
    ExecutorSupportInfo.isnetworkowner = "⚠️ [isnetworkowner] (implementação alternativa)"
    _G[GlobalVariablePrefix .. "supportisnetworkowner"] = false
end

-- Teste de firetouchinterest
if getfenv()["firetouchinterest"] then
    test("firetouchinterest", function()
        local part1 = Instance.new("Part", workspace)
        local part2 = Instance.new("Part", workspace)
        part1.Position = Vector3.new(0, 10, 0)
        part2.Position = Vector3.new(0, 10, 5)
        
        local touched = false
        local connection = part1.Touched:Connect(function() touched = true end)
        
        firetouchinterest(part2, part1, 0)
        task.wait(0.1)
        firetouchinterest(part2, part1, 1)
        
        connection:Disconnect()
        part1:Destroy()
        part2:Destroy()
        
        assert(touched, "Failed to fire touch interest")
    end)
    
    ExecutorSupport.firetouch = firetouchinterest
elseif getfenv()["firetouchtransmitter"] then
    test("firetouchtransmitter", function()
        local part1 = Instance.new("Part", workspace)
        local part2 = Instance.new("Part", workspace)
        part1.Position = Vector3.new(0, 10, 0)
        part2.Position = Vector3.new(0, 10, 5)
        
        local touched = false
        local connection = part1.Touched:Connect(function() touched = true end)
        
        firetouchtransmitter(part2, part1)
        
        connection:Disconnect()
        part1:Destroy()
        part2:Destroy()
        
        assert(touched, "Failed to fire touch transmitter")
    end)
    
    ExecutorSupport.firetouch = firetouchtransmitter
else
    ExecutorSupport.firetouch = nil
    ExecutorSupportInfo.firetouch = "❌ [firetouch] (não disponível)"
    _G[GlobalVariablePrefix .. "supportfiretouch"] = false
end

-- Teste de debugger (evita execução direta para não quebrar o script)
if getfenv()["debug"] and debug.info then
    ExecutorSupport.debugger = true
    ExecutorSupportInfo.debugger = "✅ [debugger]"
    _G[GlobalVariablePrefix .. "supportdebugger"] = true
else
    ExecutorSupport.debugger = false
    ExecutorSupportInfo.debugger = "❌ [debugger] (não disponível)"
    _G[GlobalVariablePrefix .. "supportdebugger"] = false
end

local placeId = game.PlaceId
local universeId = nil
local success, result = pcall(function()
    return game:GetService("MarketplaceService"):GetProductInfo(placeId).UniverseId
end)
if success then
    universeId = result
end

_G[GlobalVariablePrefix .. "placeId"] = placeId
_G[GlobalVariablePrefix .. "universeId"] = universeId

_G[GlobalVariablePrefix .. "supportFileSystem"] = (ExecutorSupport["isfile"] and ExecutorSupport["delfile"] and ExecutorSupport["listfiles"] and ExecutorSupport["writefile"] and ExecutorSupport["makefolder"] and ExecutorSupport["isfolder"])
_G[GlobalVariablePrefix .. "supportEditFiles"] = (ExecutorSupport["writefile"] and ExecutorSupport["appendfile"] and ExecutorSupport["delfile"])
_G[GlobalVariablePrefix .. "supportDrawing"] = ExecutorSupport["Drawing.new"] or false
_G[GlobalVariablePrefix .. "supportHTTP"] = (ExecutorSupport["request"] or ExecutorSupport["http_request"] or ExecutorSupport["syn.request"] or ExecutorSupport["httprequest"]) or false

local capabilityGroups = {
    ["Sistema de Arquivos"] = {"readfile", "listfiles", "writefile", "makefolder", "appendfile", "isfile", "isfolder", "delfile", "delfolder", "loadfile"},
    ["Acesso ao Ambiente"] = {"getrenv", "getgenv", "getsenv", "getfenv", "getrawmetatable", "setrawmetatable", "setreadonly", "getnamecallmethod", "isluau", "checkcaller"},
    ["HTTP e Rede"] = {"request", "http_request", "syn.request", "httprequest"},
    ["Interface e Usuário"] = {"gethui", "getgc", "getinstances", "getnilinstances", "sethiddenproperty", "gethiddenproperty", "saveinstance", "setclipboard", "getcustomasset", "getsynasset"},
    ["Interação"] = {"fireclickdetector", "fireproximityprompt", "firetouchinterest", "firetouchtransmitter", "mouse1click", "mouse1press", "mouse1release", "mouse2click", "keypress", "keyrelease"},
    ["Eventos e Conexões"] = {"getconnections", "firesignal", "hookmetamethod", "queue_on_teleport"},
    ["Desenho"] = {"Drawing", "Drawing.new"},
    ["Scripts e Módulos"] = {"require", "getcallingscript", "debugger"},
    ["Física e Rede"] = {"isnetworkowner", "isnetowner"}
}

ExecutorSupport["_ExecutorName"] = executorName
ExecutorSupport["_ExecutorVersion"] = executorVersion
ExecutorSupport["_ExecutorFullInfo"] = executorFullInfo
ExecutorSupport["_OSType"] = osType
ExecutorSupport["_SupportsFileSystem"] = _G[GlobalVariablePrefix .. "supportFileSystem"]
ExecutorSupport["_SupportsHTTP"] = _G[GlobalVariablePrefix .. "supportHTTP"]
ExecutorSupport["_SupportsDrawing"] = _G[GlobalVariablePrefix .. "supportDrawing"]
ExecutorSupport["_PlaceId"] = placeId
ExecutorSupport["_UniverseId"] = universeId

local function logPrint(text)
    print(text)
    table.insert(logContent, text)
end

local function saveLogToFile()
    if not ExecutorSupport["writefile"] or not ExecutorSupport["makefolder"] then
        print("\n⚠️ Não foi possível salvar o log: sistema de arquivos não suportado")
        return false
    end
    
    if not isfolder(logFolder) then
        pcall(function() makefolder(logFolder) end)
    end
    
    local success, err = pcall(function()
        writefile(logPath, table.concat(logContent, "\n"))
    end)
    
    if success then
        print("\n✅ Log salvo em: " .. logPath)
        return true
    else
        print("\n⚠️ Erro ao salvar log: " .. tostring(err))
        return false
    end
end

_G[GlobalVariablePrefix .. "logPath"] = logPath

logPrint("\n\n")
logPrint("═════════════════════════════════════════════")
logPrint("📊 ANÁLISE DE COMPATIBILIDADE DO EXECUTOR 📊")
logPrint("═════════════════════════════════════════════")
logPrint("✨ Executor: " .. executorFullInfo)
logPrint("🖥️ Sistema: " .. osType)
logPrint("🎮 Jogo: " .. game:GetService("MarketplaceService"):GetProductInfo(placeId).Name)
logPrint("🆔 Place ID: " .. placeId)
if universeId then
    logPrint("🌌 Universe ID: " .. universeId)
end
logPrint("⏰ Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S", _G[GlobalVariablePrefix .. "timestamp"]))
logPrint("═════════════════════════════════════════════")

logPrint("\n📑 RESUMO DE CAPACIDADES:")
logPrint("✅ Sistema de Arquivos: " .. (ExecutorSupport["_SupportsFileSystem"] and "Suportado" or "Não suportado"))
logPrint("✅ HTTP: " .. (ExecutorSupport["_SupportsHTTP"] and "Suportado" or "Não suportado"))
logPrint("✅ Drawing: " .. (ExecutorSupport["_SupportsDrawing"] and "Suportado" or "Não suportado"))
logPrint("✅ ProximityPrompt: " .. (canFirePrompt and "Suportado" or "Implementação alternativa"))
logPrint("═════════════════════════════════════════════")

for groupName, features in pairs(capabilityGroups) do
    local groupCount = 0
    local totalFeatures = #features
    
    for _, featureName in ipairs(features) do
        if ExecutorSupport[featureName] then
            groupCount = groupCount + 1
        end
    end
    
    local percentage = math.floor((groupCount / totalFeatures) * 100)
    local barLength = 20
    local filledBars = math.floor((percentage / 100) * barLength)
    local bar = string.rep("█", filledBars) .. string.rep("░", barLength - filledBars)
    
    logPrint("\n📋 " .. groupName .. " (" .. percentage .. "%)")
    logPrint(bar .. " " .. groupCount .. "/" .. totalFeatures)
    
    for _, featureName in ipairs(features) do
        if ExecutorSupportInfo[featureName] then
            logPrint(ExecutorSupportInfo[featureName])
        elseif ExecutorSupport[featureName] ~= nil then
            logPrint((ExecutorSupport[featureName] and "✅" or "❌") .. " [" .. featureName .. "]")
        else
            logPrint("❓ [" .. featureName .. "] (não testado)")
        end
    end
end

logPrint("\n═════════════════════════════════════════════")
logPrint("📝 VARIÁVEIS GLOBAIS DEFINIDAS:")
logPrint("═════════════════════════════════════════════")

-- Exibir todas as variáveis globais criadas
local globalVars = {}
for key, value in pairs(_G) do
    if string.find(key, GlobalVariablePrefix) then
        table.insert(globalVars, {key = key, value = value})
    end
end

table.sort(globalVars, function(a, b) return a.key < b.key end)

for _, var in ipairs(globalVars) do
    logPrint(var.key .. " = " .. tostring(var.value))
end

logPrint("\n═════════════════════════════════════════════")
logPrint("🔍 VERIFICAÇÃO COMPLETA!")
logPrint("═════════════════════════════════════════════")

logPrint("\n═════════════════════════════════════════════")
logPrint("ℹ️ INFORMAÇÕES ADICIONAIS DO SISTEMA")
logPrint("═════════════════════════════════════════════")

pcall(function()
    local stats = game:GetService("Stats")
    logPrint("📈 FPS: " .. math.floor(1/stats.FrameRateManager.AverageFPS:GetValue()))
    logPrint("🧠 Uso de Memória: " .. math.floor(stats:GetTotalMemoryUsageMb()) .. " MB")
    logPrint("🔄 Ping: " .. math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue()) .. " ms")
end)

-- Informações de hardware (quando disponível)
pcall(function()
    if getfenv()["getgenv"] and getgenv().debug_info then
        for key, value in pairs(getgenv().debug_info) do
            logPrint("🖥️ " .. key .. ": " .. tostring(value))
        end
    end
end)

pcall(function()
    local player = game:GetService("Players").LocalPlayer
    if player then
        logPrint("👤 Nome do Jogador: " .. player.Name)
        logPrint("🆔 ID do Jogador: " .. player.UserId)
        logPrint("⭐ Idade da Conta: " .. player.AccountAge .. " dias")
    end
end)

logPrint("\n═════════════════════════════════════════════")
logPrint("📋 LOG FINALIZADO: " .. logDateTime)
logPrint("═════════════════════════════════════════════\n\n")

saveLogToFile()

return ExecutorSupport
_G.msdoors_checkexecutor = true
