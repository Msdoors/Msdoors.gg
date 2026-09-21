local getgenv = getgenv or function()
    return shared
end

local Library
repeat
    Library = getgenv().Library
    if not Library then task.wait() end
until Library

if not Library.ScreenGui then return end

local HatImageURL = "https://raw.githubusercontent.com/Sc-Rhyan57/RandomStuff/refs/heads/main/Novo%20projeto%2091%20%5B97224CD%5D.png"

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MainFrame = Library.ScreenGui:FindFirstChild("Main")
if not MainFrame then
    MainFrame = Library.ScreenGui:WaitForChild("Main", 10)
    if not MainFrame then return end
end

local BaseZIndex = (MainFrame.ZIndex or 1) + 1

local activeConfetti = {}
local ConfettiConnection = nil
local Hat = nil
local ConfettiContainer = nil

local CONFETTI_COLORS = {
    Color3.fromRGB(255, 89, 94),
    Color3.fromRGB(255, 202, 58),
    Color3.fromRGB(138, 201, 38),
    Color3.fromRGB(25, 130, 196),
    Color3.fromRGB(106, 76, 156),
    Color3.fromRGB(255, 158, 0),
}

local CachePath = "msdoors/.cache/images/"

local function EnsureCacheFolder()
    local success = pcall(function()
        if not isfolder or not makefolder then return end
        if not isfolder("msdoors") then makefolder("msdoors") end
        if not isfolder("msdoors/.cache") then makefolder("msdoors/.cache") end
        if not isfolder(CachePath) then makefolder(CachePath) end
    end)
    return success and isfolder and isfolder(CachePath)
end

local function GetImageAsset(url, name)
    if not EnsureCacheFolder() then return nil end
    if not writefile or not isfile then return nil end
    local assetFunc = getcustomasset or getsynasset
    if not assetFunc then return nil end
    local fileName = CachePath .. tostring(name) .. ".png"
    local cacheSuccess, cacheResult = pcall(function()
        if isfile(fileName) then return assetFunc(fileName) end
        return nil
    end)
    if cacheSuccess and cacheResult then return cacheResult end
    local downloadSuccess, imageData = pcall(function() return game:HttpGet(url) end)
    if not downloadSuccess or not imageData then return nil end
    local writeSuccess = pcall(function() writefile(fileName, imageData) end)
    if not writeSuccess then return nil end
    local assetSuccess, asset = pcall(function() return assetFunc(fileName) end)
    if not assetSuccess then return nil end
    return asset
end

local HatAsset = GetImageAsset(HatImageURL, "HappyBirthdayHat")

if HatAsset and MainFrame and MainFrame.Parent then
    pcall(function()
        Hat = Instance.new("ImageLabel")
        Hat.Name = "ChristmasHat"
        Hat.Image = HatAsset
        Hat.BackgroundTransparency = 1
        Hat.Size = UDim2.fromOffset(120, 120)
        Hat.AnchorPoint = Vector2.new(1, 0)
        Hat.Position = UDim2.new(1, 50, 0, -66)
        Hat.ZIndex = BaseZIndex
        Hat.Rotation = 25
        Hat.ScaleType = Enum.ScaleType.Fit
        Hat.Parent = MainFrame
    end)
end

if MainFrame and MainFrame.Parent then
    pcall(function()
        ConfettiContainer = Instance.new("Frame")
        ConfettiContainer.Name = "ConfettiContainer"
        ConfettiContainer.BackgroundTransparency = 1
        ConfettiContainer.Size = UDim2.fromScale(1, 1)
        ConfettiContainer.ClipsDescendants = true
        ConfettiContainer.ZIndex = BaseZIndex
        ConfettiContainer.Parent = MainFrame
    end)
end

local function spawnConfettiPiece()
    if not ConfettiContainer or not ConfettiContainer.Parent then return end
    if not MainFrame or not MainFrame.Parent then return end
    if not MainFrame.Visible then return end
    pcall(function()
        local piece = Instance.new("Frame")
        piece.Size = UDim2.fromOffset(math.random(6, 12), math.random(6, 12))
        piece.BackgroundColor3 = CONFETTI_COLORS[math.random(1, #CONFETTI_COLORS)]
        piece.BorderSizePixel = 0
        piece.AnchorPoint = Vector2.new(0.5, 0.5)
        local screenWidth = ConfettiContainer.AbsoluteSize.X
        local startX = math.random(0, screenWidth)
        local startY = -20
        piece.Position = UDim2.fromOffset(startX, startY)
        piece.Rotation = math.random(0, 360)
        piece.ZIndex = BaseZIndex
        piece.Parent = ConfettiContainer
        local vy = math.random(110, 200)
        local swayAmplitude = math.random(15, 45)
        local swayFrequency = math.random(2, 5)
        local swayOffset = math.random(0, math.pi * 2)
        local rotationSpeed = math.random(-120, 120)
        activeConfetti[piece] = {
            startX = startX,
            x = startX,
            y = startY,
            vy = vy,
            swayAmp = swayAmplitude,
            swayFreq = swayFrequency,
            swayOff = swayOffset,
            rotSpeed = rotationSpeed,
            life = 0,
        }
    end)
end

local lastSpawn = 0
local spawnInterval = 0.2

if ConfettiContainer then
    ConfettiConnection = RunService.Heartbeat:Connect(function(dt)
        local success = pcall(function()
            if Library.Unloaded then
                if ConfettiConnection then
                    ConfettiConnection:Disconnect()
                    ConfettiConnection = nil
                end
                return
            end
            if not MainFrame or not MainFrame.Parent then return end
            if not MainFrame.Visible then return end
            local now = tick()
            if now - lastSpawn >= spawnInterval then
                lastSpawn = now
                spawnConfettiPiece()
                spawnConfettiPiece()
            end
            local screenHeight = ConfettiContainer.AbsoluteSize.Y
            for piece, data in pairs(activeConfetti) do
                data.life += dt
                data.y += data.vy * dt
                data.x = data.startX + math.sin(data.life * data.swayFreq + data.swayOff) * data.swayAmp
                piece.Position = UDim2.fromOffset(data.x, data.y)
                piece.Rotation += data.rotSpeed * dt
                if data.y > screenHeight + 50 then
                    if piece and piece.Parent then
                        piece:Destroy()
                    end
                    activeConfetti[piece] = nil
                end
            end
        end)
        if not success and ConfettiConnection then
            ConfettiConnection:Disconnect()
            ConfettiConnection = nil
        end
    end)
end

local function Cleanup()
    pcall(function()
        if ConfettiConnection then
            ConfettiConnection:Disconnect()
            ConfettiConnection = nil
        end
    end)
    pcall(function()
        for piece, data in pairs(activeConfetti) do
            if piece and piece.Parent then
                piece:Destroy()
            end
        end
        activeConfetti = {}
    end)
    pcall(function()
        if ConfettiContainer and ConfettiContainer.Parent then
            ConfettiContainer:Destroy()
        end
    end)
    pcall(function()
        if Hat and Hat.Parent then
            Hat:Destroy()
        end
    end)
end

if Library.OnUnload then
    Library:OnUnload(Cleanup)
end

if MainFrame then
    MainFrame.AncestryChanged:Connect(function(_, parent)
        if not parent then
            Cleanup()
        end
    end)
end
