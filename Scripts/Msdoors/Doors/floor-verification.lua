local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local PlaceId = game.PlaceId

local function fetchGameList()
    local success, response = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Msdoors/Msdoors.gg/refs/heads/main/data/doors/floors-data.json")
    end)

    if success then
        return HttpService:JSONDecode(response)
    else
        warn("[ Msdoors ] » Falha ao buscar a lista de floors: " .. tostring(response))
        return nil
    end
end

local function checkCurrentGame()
    local gameList = fetchGameList()
    
    if gameList then
        for id, data in pairs(gameList) do
            if tonumber(id) == PlaceId then
                _G.msdoors_msdoors = tonumber(id) -- Mantendo o uso de _G
                return true
            end
        end
    else
        print("[ Msdoors ] » Não foi possível verificar a lista de jogos.")
    end
    
    return false
end

local function setupFloorName()
    if _G.msdoors_msdoors then
        local gameList = fetchGameList()
        
        if gameList then
            local currentId = tostring(PlaceId)
            
            if gameList[currentId] and gameList[currentId].name then
                _G.msdoors_floor = gameList[currentId].name
                print("[ Msdoors ] » Floor name: " .. gameList[currentId].name)
                return true
            else
                print("[ Msdoors ] » ID do floor encontrado, mas nenhum nome foi especificado na lista")
            end
        else
            warn("[ Msdoors ] » Não foi possível obter a lista de jogos.")
        end
    else
        warn("[ Msdoors ] » O jogo não foi verificado!")
    end
    
    return false
end

-- Executando as funções
if checkCurrentGame() then
    task.wait(2)
    setupFloorName()
end
