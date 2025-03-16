--[[
   ▄▄▄▄███▄▄▄▄      ▄████████ ████████▄   ▄██████▄   ▄██████▄     ▄████████    ▄████████      
 ▄██▀▀▀███▀▀▀██▄   ███    ███ ███   ▀███ ███    ███ ███    ███   ███    ███   ███    ███      
 ███   ███   ███   ███    █▀  ███    ███ ███    ███ ███    ███   ███    ███   ███    █▀       
 ███   ███   ███   ███        ███    ███ ███    ███ ███    ███  ▄███▄▄▄▄██▀   ███             
 ███   ███   ███ ▀███████████ ███    ███ ███    ███ ███    ███ ▀▀███▀▀▀▀▀   ▀███████████      
 ███   ███   ███          ███ ███    ███ ███    ███ ███    ███ ▀███████████          ███      
 ███   ███   ███    ▄█    ███ ███   ▄███ ███    ███ ███    ███   ███    ███    ▄█    ███      
  ▀█   ███   █▀   ▄████████▀  ████████▀   ▀██████▀   ▀██████▀    ███    ███  ▄████████▀       
                                                                 ███    ███                   
]]--

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

if _G.ObsidianaLib then
    warn("[Msdoors] • Script já está carregado!")
    return
end
if _G.MsdoorsLoaded then
    return warn("[Msdoors] • Já está em execução.")
end
_G.MsdoorsLoaded = true

local placeId = game.PlaceId
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = game.Players.LocalPlayer
local HttpService = game:GetService("HttpService")
--[ DEFINIR FLOOR ATUAL ]]--

local placeIdList = {
    [6839171747] = true,
    [2440500124] = true,  
    [10549820578] = true,
    [110258689672367] = true
}

if placeIdList[placeId] then

local replicatedStorage = game:GetService("ReplicatedStorage")
local gameData = replicatedStorage:WaitForChild("GameData")
local floor = gameData:WaitForChild("Floor").Value

local floornickname = {
    ["Fools"] = "Super Hard Mode",
    ["Retro"] = "Retro Mode"
}
_G.msdoors_floor = floornickname[floor] or floor

print("[ Msdoors ] » Floor name: " .. _G.msdoors_floor)
   
end


local SCRIPT_URL = "https://raw.githubusercontent.com/Sc-Rhyan57/Msdoors/refs/heads/main/Src/Loaders/"
local SUPPORTED_GAMES = {
    [6516141723] = "Doors/lobby/lobby.lua", -- lobby
    [6839171747] = "Doors/hotel.lua", -- FLOORS 2
    [2440500124] = "Doors/hotel.lua", -- FLOORS 1
    [10549820578] = "Doors/hotel.lua", -- Super Hard Mode
    [110258689672367] = "Doors/OldLobby.lua",
    [189707] = "NaturalDisaster/places/game.lua",
    [5275822877] = "Carrinho%2Bcart-para-Giganoob/game.lua",
    [12552538292] = "pressure/game.lua"
}

local function notify(title, message, tipo)
    local types = {
        success = Color3.fromRGB(0, 255, 128),
        warning = Color3.fromRGB(255, 128, 0),
        error = Color3.fromRGB(255, 0, 0)
    }
    
    StarterGui:SetCore("SendNotification", {
        Title = "Msdoors | " .. title,
        Text = message,
        Duration = 5,
        Icon = "rbxassetid://6031071053"
    })
end

local function createUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MsdoorsLoader"
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local blur = Instance.new("BlurEffect", Lighting)
    blur.Size = 0
    TweenService:Create(blur, TweenInfo.new(0.5), {Size = 10}):Play()

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 0, 0, 200)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    main.BorderSizePixel = 0
    main.Parent = gui
    TweenService:Create(main, 
        TweenInfo.new(0.5, Enum.EasingStyle.Back), 
        {Size = UDim2.new(0, 300, 0, 200)}
    ):Play()

    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(100, 100, 255)
    stroke.Thickness = 1.5

    local gradient = Instance.new("UIGradient", main)
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 50))
    })
    gradient.Rotation = 45

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "MSDOORS"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 28
    title.BackgroundTransparency = 1
    title.Parent = main

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -40, 0, 20)
    status.Position = UDim2.new(0, 20, 0, 80)
    status.Font = Enum.Font.Gotham
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.TextSize = 14
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.BackgroundTransparency = 1
    status.Parent = main

    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBg"
    progressBg.Size = UDim2.new(1, -40, 0, 6)
    progressBg.Position = UDim2.new(0, 20, 0, 120)
    progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = main

    local progressBgCorner = Instance.new("UICorner", progressBg)
    progressBgCorner.CornerRadius = UDim.new(1, 0)

    local progress = Instance.new("Frame")
    progress.Name = "Progress"
    progress.Size = UDim2.new(0, 0, 1, 0)
    progress.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    progress.BorderSizePixel = 0
    progress.Parent = progressBg

    local progressCorner = Instance.new("UICorner", progress)
    progressCorner.CornerRadius = UDim.new(1, 0)

    local progressGradient = Instance.new("UIGradient", progress)
    progressGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 255))
    })

    local version = Instance.new("TextLabel")
    version.Name = "Version"
    version.Text = "v1.0.1"
    version.Size = UDim2.new(1, -40, 0, 20)
    version.Position = UDim2.new(0, 20, 0, 160)
    version.Font = Enum.Font.Gotham
    version.TextColor3 = Color3.fromRGB(150, 150, 150)
    version.TextSize = 12
    version.TextXAlignment = Enum.TextXAlignment.Left
    version.BackgroundTransparency = 1
    version.Parent = main

    return {
        gui = gui,
        blur = blur,
        main = main,
        status = status,
        progress = progress,
        updateStatus = function(text)
            status.Text = ""
            for i = 1, #text do
                if not status.Parent then break end
                status.Text = string.sub(text, 1, i)
                task.wait(0.02)
            end
        end,
        updateProgress = function(value)
            TweenService:Create(progress, 
                TweenInfo.new(0.3, Enum.EasingStyle.Quad), 
                {Size = UDim2.new(value, 0, 1, 0)}
            ):Play()
        end,
        destroy = function()
            TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
            TweenService:Create(main, 
                TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), 
                {Size = UDim2.new(0, 0, 0, 200)}
            ):Play()
            task.wait(0.5)
            gui:Destroy()
            blur:Destroy()
        end
    }
end

-- Carregador de Scripts
local function loadScript(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success then
        local loadSuccess, error = pcall(function()
            loadstring(response)()
        end)
        
        if not loadSuccess then
            notify("Erro", "Falha ao executar o script", "error")
            return false
        end
        return true
    end
    
    notify("Erro", "Falha ao baixar o script", "error")
    return false
end

local function startMsdoors()
    local ui = createUI()
    local currentGame = game.PlaceId

    ui.updateStatus("Iniciando Msdoors...")
    ui.updateProgress(0.2)
    task.wait(0.5)

    ui.updateStatus("Verificando compatibilidade...")
    ui.updateProgress(0.4)
    task.wait(0.5)

    local scriptName = SUPPORTED_GAMES[currentGame]
    if not scriptName then
      _G.ObsidianaLib = false
      _G.MsdoorsLoaded = true
        notify("Aviso", "Este jogo não é suportado!", "warning")
        ui.updateStatus("Jogo não suportado!")
        ui.updateProgress(1)
        task.wait(1)
        ui.destroy()
        return
    end

    ui.updateStatus("Preparando carregamento...")
    ui.updateProgress(0.6)
    task.wait(0.5)
  
    ui.updateStatus("Carregando script...")
    ui.updateProgress(0.8)
    task.wait(0.5)

    local success = loadScript(SCRIPT_URL .. scriptName)
    
    if success then
        ui.updateStatus("Script carregado com sucesso!")
        ui.updateProgress(1)
        notify("Sucesso", "Script carregado com sucesso!", "success")
    else
      _G.ObsidianaLib = false
      _G.MsdoorsLoaded = true
        ui.updateStatus("Falha ao carregar script!")
        ui.updateProgress(1)
    end
    task.wait(1)
    ui.destroy()
end
startMsdoors()
