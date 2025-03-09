local HttpService = game:GetService("HttpService")
local PlaceId = game.PlaceId

local function fetchGameList()
    local success, response = pcall(function()
        local url = "https://raw.githubusercontent.com/Msdoors/Msdoors.gg/refs/heads/main/data/doors/floors-data.json"
        return HttpService:GetAsync(url)
    end)
    
    if success then
        local gameList = HttpService:JSONDecode(response)
        return gameList
    else
        warn("[ Msdoors ] » Falha ao buscar a lista de floors: " .. tostring(response))
        return nil
    end
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
setupFloorName()
