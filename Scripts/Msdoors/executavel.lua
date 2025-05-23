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
--// TEST EXECUTOR \\--
loadstring(game:HttpGet("https://raw.githubusercontent.com/Msdoors/Msdoors.gg/refs/heads/main/Scripts/Msdoors/internal/TestExecutor.luau"))()

if _G.ObsidianaLib then
    warn("[Msdoors] • Script já está carregado!")
    return
end
if _G.MsdoorsLoaded then
    return warn("[Msdoors] • Já está em execução.")
end
_G.MsdoorsLoaded = true
_G.msdoors_keyeystem_keystatus = true -- Bypass Key Sytem

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
    [87716067947993] = true,
    [110258689672367] = true
}

if placeIdList[placeId] then

local replicatedStorage = game:GetService("ReplicatedStorage") -- POR QUE DIABOS EU REMOVI ISSO?!
local gameData = replicatedStorage:WaitForChild("GameData")
local floor = gameData:WaitForChild("Floor").Value

local floornickname = {
    ["Fools"] = "Super Hard Mode",
    ["Party"] = "Ranked",
    ["Retro"] = "Retro Mode"
}
_G.msdoors_floor = floornickname[floor] or floor

print("[ Msdoors ] » Floor name: " .. _G.msdoors_floor)
   
end


local SCRIPT_URL = "https://raw.githubusercontent.com/Sc-Rhyan57/Msdoors/refs/heads/main/Src/Loaders/"
local SUPPORTED_GAMES = {
    [6516141723] = "Doors/lobby/game.lua", -- lobby
    [6839171747] = "Doors/hotel.lua", -- FLOORS 2
    [2440500124] = "Doors/hotel.lua", -- FLOORS 1
    [87716067947993] = "Doors/hotel.lua", -- Ranked(soon)
    [10549820578] = "Doors/hotel.lua", -- Super Hard Mode
    [110258689672367] = "Doors/OldLobby.lua",
    [189707] = "Natural-Disaster/places/game.lua",
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
        Icon = "rbxassetid://112673545263214"
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
    title.Text = "Msdoors"
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
    version.Text = "v1.1.1"
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
                task.wait(0.01)
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
            task.wait(0.2)
            gui:Destroy()
            blur:Destroy()
        end
    }
end

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
    ui.updateProgress(0.1)
    task.wait(0.3)

    ui.updateStatus("Verificando compatibilidade...")
    ui.updateProgress(0.3)
    task.wait(0.3)

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
    ui.updateProgress(0.5)
    task.wait(0.5)
  
    ui.updateStatus("Carregando script... \n [ Pode congelar, basta esperar! ]")
    ui.updateProgress(0.6)
    task.wait(0.3)

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
