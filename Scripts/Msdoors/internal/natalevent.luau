-- Open source because I used a bit of AI to solve certain problems, so be happy stealing code, you piece of shit.
local getgenv = getgenv or function()
    return shared
end

local Library
repeat
    Library = getgenv().Library
    if not Library then task.wait() end
until Library

local HatImageURL = "https://raw.githubusercontent.com/RhyanXG7/host-de-imagens/refs/heads/BetterStar/imagens-Host/%E2%80%94Pngtree%E2%80%94christmas%20hat%20christmas%20decoration_8400088.png"
local SnowflakeURL = "https://raw.githubusercontent.com/RhyanXG7/host-de-imagens/refs/heads/BetterStar/imagens-Host/pngwing.com.png"

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MainFrame = Library.ScreenGui:WaitForChild("Main")
local BaseZIndex = MainFrame.ZIndex + 1

local Snowflakes = {}
local SnowConnection = nil

local CachePath = "msdoors/.cache/images/"

local function EnsureCacheFolder()
    if not isfolder then return false end
    
    if not isfolder("msdoors") then
        makefolder("msdoors")
    end
    if not isfolder("msdoors/.cache") then
        makefolder("msdoors/.cache")
    end
    if not isfolder(CachePath) then
        makefolder(CachePath)
    end
    
    return true
end

local function GetImageAsset(url, name)
    if not EnsureCacheFolder() then return nil end
    
    local fileName = CachePath .. tostring(name) .. ".png"
    
    if isfile and isfile(fileName) then
        local assetFunc = getcustomasset or getsynasset
        if assetFunc then
            return assetFunc(fileName)
        end
    end
    
    local success, imageData = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        return nil
    end
    
    local writeSuccess = pcall(function()
        writefile(fileName, imageData)
    end)
    
    if not writeSuccess then
        return nil
    end
    
    local assetFunc = getcustomasset or getsynasset
    if not assetFunc then
        return nil
    end
    
    return assetFunc(fileName)
end

local HatAsset = GetImageAsset(HatImageURL, "ChristmasHat")
local SnowAsset = GetImageAsset(SnowflakeURL, "Snowflake")

if HatAsset then
    local Hat = Instance.new("ImageLabel")
    Hat.Name = "ChristmasHat"
    Hat.Image = HatAsset
    Hat.BackgroundTransparency = 1
    Hat.Size = UDim2.fromOffset(120, 120)
    Hat.AnchorPoint = Vector2.new(1, 0)
    Hat.Position = UDim2.new(1, 50, 0, -45)
    Hat.ZIndex = BaseZIndex
    Hat.Rotation = 25
    Hat.ScaleType = Enum.ScaleType.Fit
    Hat.Parent = MainFrame
end

local SnowContainer = Instance.new("Frame")
SnowContainer.Name = "SnowContainer"
SnowContainer.BackgroundTransparency = 1
SnowContainer.Size = UDim2.fromScale(1, 1)
SnowContainer.ClipsDescendants = true
SnowContainer.ZIndex = BaseZIndex
SnowContainer.Parent = MainFrame

local function CreateSnowflake()
    if not SnowAsset or not MainFrame.Visible then return end
    
    local size = math.random(8, 18)
    local startX = math.random(0, 100) / 100
    local duration = math.random(4, 7)
    local drift = math.random(-30, 30)
    
    local snowflake = Instance.new("ImageLabel")
    snowflake.Name = "Snowflake"
    snowflake.Image = SnowAsset
    snowflake.BackgroundTransparency = 1
    snowflake.Size = UDim2.fromOffset(size, size)
    snowflake.Position = UDim2.new(startX, 0, 0, -size)
    snowflake.ImageTransparency = math.random(20, 50) / 100
    snowflake.ZIndex = BaseZIndex
    snowflake.Rotation = math.random(0, 360)
    snowflake.Parent = SnowContainer
    
    table.insert(Snowflakes, snowflake)
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(snowflake, tweenInfo, {
        Position = UDim2.new(startX, drift, 1, size),
        Rotation = snowflake.Rotation + math.random(-180, 180)
    })
    
    tween:Play()
    tween.Completed:Connect(function()
        local index = table.find(Snowflakes, snowflake)
        if index then
            table.remove(Snowflakes, index)
        end
        snowflake:Destroy()
    end)
end

local lastSpawn = 0
local spawnInterval = 0.4

SnowConnection = RunService.Heartbeat:Connect(function()
    if Library.Unloaded then
        if SnowConnection then
            SnowConnection:Disconnect()
        end
        return
    end
    
    if not MainFrame.Visible then return end
    
    local now = tick()
    if now - lastSpawn >= spawnInterval then
        lastSpawn = now
        CreateSnowflake()
    end
end)

Library:OnUnload(function()
    if SnowConnection then
        SnowConnection:Disconnect()
        SnowConnection = nil
    end
    
    for _, snowflake in ipairs(Snowflakes) do
        if snowflake and snowflake.Parent then
            snowflake:Destroy()
        end
    end
    table.clear(Snowflakes)
    
    if SnowContainer and SnowContainer.Parent then
        SnowContainer:Destroy()
    end
end)
