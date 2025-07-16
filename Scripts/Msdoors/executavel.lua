if _G.ObsidianaLib then
    warn("[Msdoors] • Script já está carregado!")
            game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Script já carregado!",
            Image = "rbxassetid://95869322194132",
            Text = "o script já está carregado!",
            Duration = 5
        })
    return
end

        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://8486683243"
        sound.Volume = 3
        sound.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)

pcall(function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Msdoors/Msdoors.gg/refs/heads/main/Scripts/Msdoors/internal/TestExecutor.luau"))()
end)

_G.msdoors_version = game:HttpGet("https://msdoors.vercel.app/version")
_G.msdoors_keyeystem_keystatus = true

--[[
local exname = {"Xeno", "Solara", "Delta"}
for i, nome in pairs(exname) do
    if _G.msdoors_executorinfo_name == nome then
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://6176997734"
        sound.Volume = 3
        sound.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Executor não suportado!",
            Text = "o executor " .._G.msdoors_executorinfo_name .. " não é suportado.",
            Duration = 5
        })
       return
    end
end
]]--

_G.msdoors_keyeystem_keystatus = true

local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    StarterGui = game:GetService("StarterGui"),
    Players = game:GetService("Players"),
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    Lighting = game:GetService("Lighting"),
    HttpService = game:GetService("HttpService"),
    CoreGui = game:GetService("CoreGui"),
    UserInputService = game:GetService("UserInputService")
}

local player = Services.Players.LocalPlayer
local placeId = game.PlaceId
local CUSTOM_ICON_ID = "95869322194132"

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    return success and result or nil
end

local function getHiddenParent()
    if typeof(gethui) == "function" then
        return safeCall(gethui) or Services.CoreGui
    end
    return Services.CoreGui
end

local placeIdList = {
    [6839171747] = true,
    [2440500124] = true,
    [10549820578] = true,
    [87716067947993] = true,
    [110258689672367] = true
}

if placeIdList[placeId] then
    local success, floor = pcall(function()
        local gameData = Services.ReplicatedStorage:WaitForChild("GameData", 5)
        return gameData and gameData:WaitForChild("Floor", 5) and gameData.Floor.Value
    end)
    
    if success and floor then
        local floornickname = {
            ["Fools"] = "Super Hard Mode",
            ["Party"] = "Ranked",
            ["Retro"] = "Retro Mode"
        }
        _G.msdoors_floor = floornickname[floor] or floor
        print("[ Msdoors ] » {DOORS} FLOOR DETECTADO: " .. _G.msdoors_floor)
    end
end

local SCRIPT_URL = "https://raw.githubusercontent.com/Sc-Rhyan57/Msdoors/refs/heads/main/Src/Loaders/"
local SUPPORTED_GAMES = {
    [6516141723] = "Doors/lobby/game.lua",
    [6839171747] = "Doors/hotel.lua",
    [2440500124] = "Doors/hotel.lua",
    [87716067947993] = "Doors/hotel.lua",
    [10549820578] = "Doors/hotel.lua",
    [110258689672367] = "Doors/hotel.lua",
    [189707] = "Natural-Disaster/places/game.lua",
    [5275822877] = "Carrinho%2Bcart-para-Giganoob/game.lua",
    [12552538292] = "pressure/game.lua"
}

local function notify(title, message)
    pcall(function()
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Msdoors | " .. title,
            Text = message,
            Duration = 5
        })
    end)
    print("[Msdoors] " .. title .. ": " .. message)
end

local function createUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MsdoorsLoader"
    gui.ResetOnSpawn = false
    gui.Parent = getHiddenParent()

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 400, 0, 280)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
    main.BorderSizePixel = 0
    main.BackgroundTransparency = 0.05
    main.Parent = gui

    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.ZIndex = -1
    shadow.Parent = main

    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 16)
    shadowCorner.Parent = shadow

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = main

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 25)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(22, 22, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 40))
    })
    gradient.Rotation = 135
    gradient.Parent = main

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(88, 101, 242)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = main

    spawn(function()
        while main.Parent do
            Services.TweenService:Create(stroke, 
                TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), 
                {Color = Color3.fromRGB(139, 69, 255)}
            ):Play()
            wait(0.1)
        end
    end)

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundTransparency = 1
    header.Parent = main

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 25, 0, 20)
    icon.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    icon.BorderSizePixel = 0
    icon.Image = "rbxassetid://" .. CUSTOM_ICON_ID
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = header

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = icon

    local iconText = Instance.new("TextLabel")
    iconText.Text = "M"
    iconText.Size = UDim2.new(1, 0, 1, 0)
    iconText.BackgroundTransparency = 1
    iconText.Font = Enum.Font.GothamBold
    iconText.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconText.TextSize = 20
    iconText.Visible = false
    iconText.Parent = icon

    spawn(function()
        task.wait(0.1)
        if icon.Image == "" or not icon.IsLoaded then
            iconText.Visible = true
            icon.BackgroundTransparency = 0
        else
            icon.BackgroundTransparency = 1
        end
    end)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "MSDOORS"
    title.Size = UDim2.new(0, 200, 0, 35)
    title.Position = UDim2.new(0, 75, 0, 15)
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 24
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Text = "dsc.gg/msdoors-gg"
    subtitle.Size = UDim2.new(0, 200, 0, 20)
    subtitle.Position = UDim2.new(0, 75, 0, 45)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextColor3 = Color3.fromRGB(157, 171, 255)
    subtitle.TextSize = 14
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.BackgroundTransparency = 1
    subtitle.Parent = header

    local statusContainer = Instance.new("Frame")
    statusContainer.Name = "StatusContainer"
    statusContainer.Size = UDim2.new(1, -50, 0, 80)
    statusContainer.Position = UDim2.new(0, 25, 0, 100)
    statusContainer.BackgroundTransparency = 1
    statusContainer.Parent = main

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, 0, 0, 25)
    status.Font = Enum.Font.Gotham
    status.TextColor3 = Color3.fromRGB(209, 213, 219)
    status.TextSize = 15
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.BackgroundTransparency = 1
    status.Parent = statusContainer

    local progressContainer = Instance.new("Frame")
    progressContainer.Name = "ProgressContainer"
    progressContainer.Size = UDim2.new(1, 0, 0, 12)
    progressContainer.Position = UDim2.new(0, 0, 0, 40)
    progressContainer.BackgroundColor3 = Color3.fromRGB(31, 41, 55)
    progressContainer.BorderSizePixel = 0
    progressContainer.Parent = statusContainer

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 6)
    progressCorner.Parent = progressContainer

    local progress = Instance.new("Frame")
    progress.Name = "Progress"
    progress.Size = UDim2.new(0, 0, 1, 0)
    progress.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    progress.BorderSizePixel = 0
    progress.Parent = progressContainer

    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 6)
    progressFillCorner.Parent = progress

    local progressGradient = Instance.new("UIGradient")
    progressGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 69, 255))
    })
    progressGradient.Parent = progress

    local percentage = Instance.new("TextLabel")
    percentage.Name = "Percentage"
    percentage.Text = "0%"
    percentage.Size = UDim2.new(0, 50, 0, 20)
    percentage.Position = UDim2.new(1, -50, 0, 55)
    percentage.Font = Enum.Font.GothamMedium
    percentage.TextColor3 = Color3.fromRGB(156, 163, 175)
    percentage.TextSize = 12
    percentage.TextXAlignment = Enum.TextXAlignment.Right
    percentage.BackgroundTransparency = 1
    percentage.Parent = statusContainer

    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, -50, 0, 60)
    footer.Position = UDim2.new(0, 25, 0, 200)
    footer.BackgroundTransparency = 1
    footer.Parent = main

    local version = Instance.new("TextLabel")
    version.Name = "Version"
    version.Text = _G.msdoors_version
    version.Size = UDim2.new(1, 0, 0, 20)
    version.Font = Enum.Font.Gotham
    version.TextColor3 = Color3.fromRGB(107, 114, 128)
    version.TextSize = 14
    version.TextXAlignment = Enum.TextXAlignment.Left
    version.BackgroundTransparency = 1
    version.Parent = footer

    local spinner = Instance.new("Frame")
    spinner.Name = "Spinner"
    spinner.Size = UDim2.new(0, 20, 0, 20)
    spinner.Position = UDim2.new(1, -25, 0, 0)
    spinner.BackgroundTransparency = 1
    spinner.Parent = footer

    local spinnerRing = Instance.new("Frame")
    spinnerRing.Size = UDim2.new(1, 0, 1, 0)
    spinnerRing.BackgroundTransparency = 1
    spinnerRing.Parent = spinner

    local spinnerStroke = Instance.new("UIStroke")
    spinnerStroke.Color = Color3.fromRGB(88, 101, 242)
    spinnerStroke.Thickness = 2
    spinnerStroke.Transparency = 0.7
    spinnerStroke.Parent = spinnerRing

    local spinnerCorner = Instance.new("UICorner")
    spinnerCorner.CornerRadius = UDim.new(1, 0)
    spinnerCorner.Parent = spinnerRing

    spawn(function()
        while spinner.Parent do
            Services.TweenService:Create(spinnerRing, 
                TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), 
                {Rotation = 360}
            ):Play()
            task.wait(0.1)
        end
    end)

    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundTransparency = 1
    
    Services.TweenService:Create(main, 
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
        {Size = UDim2.new(0, 400, 0, 280), BackgroundTransparency = 0.05}
    ):Play()

    return {
        gui = gui,
        main = main,
        status = status,
        progress = progress,
        percentage = percentage,
        updateStatus = function(text)
            status.Text = text
            status.TextTransparency = 0.5
            Services.TweenService:Create(status, 
                TweenInfo.new(0.3, Enum.EasingStyle.Quad), 
                {TextTransparency = 0}
            ):Play()
        end,
        updateProgress = function(value)
            local percent = math.floor(value * 100)
            percentage.Text = percent .. "%"
            
            Services.TweenService:Create(progress, 
                TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                {Size = UDim2.new(value, 0, 1, 0)}
            ):Play()
        end,
        destroy = function()
            Services.TweenService:Create(main, 
                TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), 
                {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}
            ):Play()
            
            task.wait(0.5)
            pcall(function()
                gui:Destroy()
            end)
        end
    }
end

local function loadScript(url)
    local httpMethods = {
        function() return game:HttpGet(url) end,
        function() 
            if typeof(http_request) == "function" then
                local response = http_request({Url = url, Method = "GET"})
                return response.Body
            end
        end,
        function() 
            if typeof(request) == "function" then
                local response = request({Url = url, Method = "GET"})
                return response.Body
            end
        end,
        function()
            if typeof(syn) == "table" and typeof(syn.request) == "function" then
                local response = syn.request({Url = url, Method = "GET"})
                return response.Body
            end
        end
    }
    
    local response = nil
    for _, method in pairs(httpMethods) do
        local success, result = pcall(method)
        if success and result then
            response = result
            break
        end
    end
    
    if not response then
        notify("Erro", "Não foi possível baixar o script")
        return false
    end
    
    local success, error = pcall(function()
        local func = loadstring(response)
        if func then
            func()
        else
            error("Falha ao carregar script")
        end
    end)
    
    if not success then
        notify("Erro", "Falha ao executar script")
        return false
    end
    
    return true
end

local function startMsdoors()
    local ui = createUI()
    local currentGame = game.PlaceId

    ui.updateStatus("Inicializando sistema...")
    ui.updateProgress(0.1)
    wait(0.6)

    ui.updateStatus("Verificando compatibilidade...")
    ui.updateProgress(0.25)
    wait(0.5)

    local scriptName = SUPPORTED_GAMES[currentGame]
    if not scriptName then
        _G.ObsidianaLib = false
        notify("Aviso", "Jogo não suportado")
        ui.updateStatus("Jogo não suportado")
        ui.updateProgress(1)
        wait(2.5)
        ui.destroy()
        return
    end

    ui.updateStatus("Preparando ambiente...")
    ui.updateProgress(0.5)
    wait(0.5)
  
    ui.updateStatus("Baixando recursos...")
    ui.updateProgress(0.75)
    wait(0.4)

    local success = loadScript(SCRIPT_URL .. scriptName)
    
    if success then
        ui.updateStatus("Carregamento concluído!")
        ui.updateProgress(1)
        notify("Sucesso", "Script executado com sucesso!")
        task.wait(1.2)
    else
        _G.ObsidianaLib = false
        ui.updateStatus("Falha no carregamento")
        ui.updateProgress(1)
        task.wait(2.5)
    end
    
    ui.destroy()
end

startMsdoors()
