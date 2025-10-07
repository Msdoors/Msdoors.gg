if _G.msdoors_isloading then
    print(" O SCRIPT JÁ ESTÁ CARREGANDO!!! ")
    return
end

_G.msdoors_version = game:HttpGet("https://oficial.msdoors.xyz/msdoors/version")

if shared.loaded then
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

loadstring(game:HttpGet("https://raw.githubusercontent.com/Msdoors/Msdoors.gg/refs/heads/main/Scripts/Msdoors/internal/TestExecutor.lua"))()

local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    StarterGui = game:GetService("StarterGui"),
    Players = game:GetService("Players"),
    HttpService = game:GetService("HttpService")
}

local player = Services.Players.LocalPlayer
local placeId = game.PlaceId

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    return success and result or nil
end

local SCRIPT_URL = "https://raw.githubusercontent.com/Sc-Rhyan57/Msdoors/refs/heads/main/Src/Loaders/"
local SUPPORTED_GAMES = {
    [6516141723] = "Doors/lobby/lobby.lua",
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
            Image = "rbxassetid://95869322194132",
            Text = message,
            Duration = 5
        })
    end)
    print("[Msdoors] " .. title .. ": " .. message)
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
        notify("Erro", "Unable to download script")
        return false
    end
    
    local success, error = pcall(function()
        local func = loadstring(response)
        if func then
            func()
        else
            error("Failed to load script")
        end
    end)
    
    if not success then
        notify("Erro", "Failed to execute script")
        return false
    end
    
    return true
end

local function startMsdoors()
    local currentGame = game.PlaceId
    _G.msdoors_isloading = true

    local scriptName = SUPPORTED_GAMES[currentGame]
    if not scriptName then
        shared.loaded = false
        notify("Aviso", "Game not supported")
        _G.msdoors_isloading = false
        print("[ Msdoors ] » Script não está mais carregando. ")
        return
    end

    local success = loadScript(SCRIPT_URL .. scriptName)
    
    if success then
        notify("Sucesso", "Script executed successfully!")
    else
        shared.loaded = false
    end
    
    _G.msdoors_isloading = false
end

startMsdoors()
