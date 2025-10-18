if _G.msdoors_isloading then
    print(" O SCRIPT JÁ ESTÁ CARREGANDO!!! ")
    return
end

local function copyToClipboard(text)
    local success = pcall(function()
        if setclipboard then
            setclipboard(text)
        elseif toclipboard then
            toclipboard(text)
        end
    end)
    return success
end

local function notifyError(errorMessage)
    local fullError = "[MSDOORS ERROR]\n" .. errorMessage .. "\n\n Join Discord for support: https://dsc.gg/msdoors"
    
    local copied = copyToClipboard(fullError)
    
    warn(fullError)
    
    local bindableFunction = Instance.new("BindableFunction")
    bindableFunction.OnInvoke = function(buttonText)
        if buttonText == "Copy Discord" then
            copyToClipboard("https://dsc.gg/msdoors")
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Copied!",
                Text = "Discord link copied to clipboard",
                Duration = 3
            })
        end
    end
    
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Error in Msdoors",
            Text = (copied and "Copied error! " or "") .. "Join Discord: dsc.gg/msdoors",
            Duration = 20,
            Button1 = "Copy Discord",
            Callback = bindableFunction
        })
    end)

local function mainScript()
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
            error("Unable to download script from: " .. url)
        end
        
        local func = loadstring(response)
        if not func then
            error("Failed to load script from: " .. url)
        end
        
        func()
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

        local success, err = pcall(function()
            loadScript(SCRIPT_URL .. scriptName)
        end)
        
        if success then
            notify("Sucesso", "Script executed successfully!")
        else
            shared.loaded = false
            error(err)
        end
        
        _G.msdoors_isloading = false
    end

    startMsdoors()
end

local success, errorMessage = pcall(mainScript)

if not success then
    _G.msdoors_isloading = false
    shared.loaded = false
    notifyError(tostring(errorMessage))
end
