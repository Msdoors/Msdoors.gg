if not shared.notifyap then shared.notifyap = {} end

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local DEFAULT_SOUND = "rbxassetid://4590657391"
local MSDOORS_SOUND_URL = "https://github.com/Msdoors/Msdoors.gg/raw/refs/heads/main/Scripts/Msdoors/Notification/DOORS-ACHIEVIMENT.mp3"
local MSDOORS_SOUND_PATH = "msdoors/DOORS-ACHIEVEMENT.mp3"
local PARADOX_SOUND_URL = "https://github.com/Msdoors/Msdoors.gg/raw/refs/heads/main/Scripts/Msdoors/Notification/PARADOX-ACHIEVIMENT.ogg"
local PARADOX_SOUND_PATH = "msdoors/PARADOX-ACHIEVEMENT.ogg"
local ABYSSAL_DEFAULT_SOUND = "rbxassetid://8784885431"

shared.ACHIDATA = shared.ACHIDATA or { template = nil, gui = nil, queue = {}, processing = false, defaultSound = nil }
local d = shared.ACHIDATA

shared.MPARADOX = shared.MPARADOX or { template = nil, holder = nil, queue = {}, processing = false, defaultSound = nil }
local mp = shared.MPARADOX

local AbyssalState = {
    Container = nil,
}

local function getAbyssalContainer()
    if AbyssalState.Container and AbyssalState.Container.Parent then
        return AbyssalState.Container
    end
    local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
    local sg = pg:FindFirstChild("AbyssalNotifyUI")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "AbyssalNotifyUI"
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.Parent = pg
    end
    local c = sg:FindFirstChild("Container")
    if not c then
        c = Instance.new("Frame")
        c.Name = "Container"
        c.Size = UDim2.new(1, 0, 1, 0)
        c.BackgroundTransparency = 1
        c.Parent = sg
    end
    AbyssalState.Container = c
    return c
end

local soundUrlCache = {}

local function resolveSound(soundpar, fallback)
    if not soundpar or soundpar == "" then return fallback or DEFAULT_SOUND end
    if soundpar:match("^rbxassetid://") then return soundpar end
    if soundpar:match("^%d+$") then return "rbxassetid://" .. soundpar end
    if soundpar:match("^https?://") then
        if soundUrlCache[soundpar] then return soundUrlCache[soundpar] end
        if not isfolder("msdoors") then makefolder("msdoors") end
        local tempPath = "msdoors/temp_" .. math.floor(tick() * 1000) .. ".mp3"
        local ok, data = pcall(game.HttpGet, game, soundpar)
        if ok then
            writefile(tempPath, data)
            local fn = getcustomasset or getsynasset
            local asset = fn(tempPath)
            soundUrlCache[soundpar] = asset
            return asset
        end
        return fallback or DEFAULT_SOUND
    end
    return fallback or DEFAULT_SOUND
end

local function getOrDownloadMsdoorsSound()
    if d.defaultSound then return d.defaultSound end
    if not isfolder("msdoors") then makefolder("msdoors") end
    if isfile(MSDOORS_SOUND_PATH) then
        local fn = getcustomasset or getsynasset
        d.defaultSound = fn(MSDOORS_SOUND_PATH)
        return d.defaultSound
    end
    task.spawn(function()
        local ok, data = pcall(game.HttpGet, game, MSDOORS_SOUND_URL)
        if ok then
            writefile(MSDOORS_SOUND_PATH, data)
            local fn = getcustomasset or getsynasset
            d.defaultSound = fn(MSDOORS_SOUND_PATH)
        else
            d.defaultSound = "rbxassetid://10469938989"
        end
    end)
    return "rbxassetid://10469938989"
end

local function getOrDownloadParadoxSound()
    if mp.defaultSound then return mp.defaultSound end
    if not isfolder("msdoors") then makefolder("msdoors") end
    if isfile(PARADOX_SOUND_PATH) then
        local fn = getcustomasset or getsynasset
        mp.defaultSound = fn(PARADOX_SOUND_PATH)
        return mp.defaultSound
    end
    task.spawn(function()
        local ok, data = pcall(game.HttpGet, game, PARADOX_SOUND_URL)
        if ok then
            writefile(PARADOX_SOUND_PATH, data)
            local fn = getcustomasset or getsynasset
            mp.defaultSound = fn(PARADOX_SOUND_PATH)
        else
            mp.defaultSound = DEFAULT_SOUND
        end
    end)
    return DEFAULT_SOUND
end

local function playSound(parent, soundId, volume)
    local snd = Instance.new("Sound")
    snd.SoundId = soundId
    snd.Volume = volume or 1
    snd.Parent = parent
    task.spawn(function()
        task.wait(0.1)
        snd:Play()
        snd.Ended:Wait()
        snd:Destroy()
    end)
end

local function initMsdoorsUI()
    if d.gui then return end

    local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "AchievementUI"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = pg

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.Size = UDim2.new(1, 0, 1, 0)
    holder.BackgroundTransparency = 1
    holder.Parent = sg

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 25)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = holder

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 15)
    pad.PaddingRight = UDim.new(0, 15)
    pad.Parent = holder

    d.gui = holder

    local a = Instance.new("Frame")
    a.Name = "Achi"
    a.Size = UDim2.new(0.28, 0, 0.11, 0)
    a.Position = UDim2.new(1.2, 0, 0, 0)
    a.AnchorPoint = Vector2.new(1, 0)
    a.BackgroundTransparency = 1
    a.ZIndex = 2000
    a.Visible = true

    local f = Instance.new("Frame")
    f.Name = "F"
    f.Size = UDim2.new(1, 0, 1, 0)
    f.Position = UDim2.new(1.1, 0, 0, 0)
    f.BackgroundColor3 = Color3.fromRGB(38, 25, 25)
    f.BackgroundTransparency = 0.25
    f.BorderSizePixel = 0
    f.ZIndex = 2000
    f.Parent = a

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 222, 189)
    stroke.Thickness = 3
    stroke.Parent = f

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = f

    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.Size = UDim2.new(2, 0, 4, 0)
    glow.Position = UDim2.new(-0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0, 0.5)
    glow.Image = "rbxassetid://61997378"
    glow.ImageColor3 = Color3.fromRGB(255, 222, 189)
    glow.ImageTransparency = 0
    glow.BackgroundTransparency = 1
    glow.ZIndex = 1999
    glow.Parent = a

    local top = Instance.new("TextLabel")
    top.Name = "Top"
    top.Size = UDim2.new(1, -10, 0.22, 0)
    top.Position = UDim2.new(0, 5, -0.35, 0)
    top.BackgroundTransparency = 1
    top.Text = "UNLOCKED ACHIEVEMENT"
    top.TextColor3 = Color3.fromRGB(255, 222, 189)
    top.TextScaled = true
    top.TextWrapped = true
    top.Font = Enum.Font.FredokaOne
    top.TextSize = 16
    top.ZIndex = 2001
    top.TextTruncate = Enum.TextTruncate.AtEnd
    top.Parent = f

    local img = Instance.new("ImageLabel")
    img.Name = "Img"
    img.Size = UDim2.new(0.2, 0, 0.85, 0)
    img.Position = UDim2.new(0.03, 0, 0.075, 0)
    img.BackgroundTransparency = 1
    img.BorderSizePixel = 0
    img.ScaleType = Enum.ScaleType.Fit
    img.ZIndex = 2001
    img.Parent = f

    local det = Instance.new("Frame")
    det.Name = "Det"
    det.Size = UDim2.new(0.73, 0, 0.95, 0)
    det.Position = UDim2.new(0.25, 0, 0.025, 0)
    det.BackgroundTransparency = 1
    det.ZIndex = 2001
    det.Parent = f

    local detl = Instance.new("UIListLayout")
    detl.Padding = UDim.new(0, 2)
    detl.SortOrder = Enum.SortOrder.LayoutOrder
    detl.Parent = det

    local function makeLabel(name, sizeY, color, font, size, order)
        local lbl = Instance.new("TextLabel")
        lbl.Name = name
        lbl.Size = UDim2.new(1, 0, sizeY, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color
        lbl.TextWrapped = true
        lbl.Font = font
        lbl.TextSize = size
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.ZIndex = 2001
        lbl.LayoutOrder = order
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = det
        local p = Instance.new("UIPadding")
        p.PaddingLeft = UDim.new(0, 5)
        if order == 1 then p.PaddingTop = UDim.new(0, 3) end
        p.Parent = lbl
        return lbl
    end

    makeLabel("Title",  0.38, Color3.fromRGB(255, 222, 189), Enum.Font.GothamBlack,  20, 1)
    makeLabel("Desc",   0.28, Color3.fromRGB(221, 180, 151), Enum.Font.GothamMedium, 14, 2)
    makeLabel("Reason", 0.28, Color3.fromRGB(200, 165, 140), Enum.Font.Gotham,       13, 3)

    d.template = a
end

local function showMsdoors(opts)
    local achi = d.template:Clone()
    achi.Parent = d.gui
    achi.LayoutOrder = tick()

    achi.F.Top.Text        = opts.Style or "UNLOCKED ACHIEVEMENT"
    achi.F.Det.Title.Text  = opts.Title or "Achievement"
    achi.F.Det.Desc.Text   = opts.Description or ""
    achi.F.Det.Reason.Text = opts.Reason or ""
    achi.F.Img.Image       = opts.Image or "rbxassetid://6023426923"

    local col = opts.Color or Color3.fromRGB(255, 222, 189)
    achi.F.Top.TextColor3  = col
    achi.F.UIStroke.Color  = col
    achi.Glow.ImageColor3  = col

    local soundId = resolveSound(opts.Sound, getOrDownloadMsdoorsSound())
    playSound(achi, soundId, 0.575)

    achi.F:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Sine", 0.8, true)
    TweenService:Create(achi.Glow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { ImageTransparency = 1 }):Play()

    task.spawn(function()
        task.wait(opts.Time or 5)
        achi.F:TweenPosition(UDim2.new(1.1, 0, 0, 0), "In", "Sine", 0.6, true)
        task.wait(0.6)
        achi:Destroy()
    end)
end

local function processMsdoorsQueue()
    if d.processing then return end
    d.processing = true
    while #d.queue > 0 do
        showMsdoors(table.remove(d.queue, 1))
        task.wait(0.35)
    end
    d.processing = false
end

local paradoxCache = {}

local function paradox_save(obj)
    local data = {}
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        data.ImageTransparency = obj.ImageTransparency
        if obj:FindFirstChildOfClass("UIStroke") then data.StrokeTransparency = obj.UIStroke.Transparency end
        obj.ImageTransparency = 1
        if obj:FindFirstChildOfClass("UIStroke") then obj.UIStroke.Transparency = 1 end
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
        data.TextTransparency = obj.TextTransparency
        data.BackgroundTransparency = obj.BackgroundTransparency
        if obj:FindFirstChildOfClass("UIStroke") then data.StrokeTransparency = obj.UIStroke.Transparency end
        obj.TextTransparency = 1
        obj.BackgroundTransparency = 1
        if obj:FindFirstChildOfClass("UIStroke") then obj.UIStroke.Transparency = 1 end
    elseif obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("ViewportFrame") then
        data.BackgroundTransparency = obj.BackgroundTransparency
        if obj:FindFirstChildOfClass("UIStroke") then data.StrokeTransparency = obj.UIStroke.Transparency end
        obj.BackgroundTransparency = 1
        if obj:FindFirstChildOfClass("UIStroke") then obj.UIStroke.Transparency = 1 end
    end
    paradoxCache[obj] = data
end

local function paradox_tweenIn(obj)
    local data = paradoxCache[obj]
    if not data then return end
    local ti = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        TweenService:Create(obj, ti, { ImageTransparency = data.ImageTransparency or 0 }):Play()
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = data.StrokeTransparency or 0 }):Play() end
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
        TweenService:Create(obj, ti, { TextTransparency = data.TextTransparency or 0, BackgroundTransparency = data.BackgroundTransparency or 1 }):Play()
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = data.StrokeTransparency or 0 }):Play() end
    elseif obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("ViewportFrame") then
        TweenService:Create(obj, ti, { BackgroundTransparency = data.BackgroundTransparency or 0 }):Play()
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = data.StrokeTransparency or 0 }):Play() end
    end
end

local function paradox_tweenOut(obj)
    local ti = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        TweenService:Create(obj, ti, { ImageTransparency = 1 }):Play()
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = 1 }):Play() end
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
        TweenService:Create(obj, ti, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = 1 }):Play() end
    elseif obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("ViewportFrame") then
        TweenService:Create(obj, ti, { BackgroundTransparency = 1 }):Play()
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = 1 }):Play() end
    end
end

local function notifyParadox(opts)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local achievementGui = playerGui
        :WaitForChild("Initiate")
        :WaitForChild("Library")
        :WaitForChild("GUI")
        :WaitForChild("Achievement")

    local template = achievementGui:WaitForChild("Template")
    local achievementHolder = playerGui:WaitForChild("MainUI"):WaitForChild("AchievementHolder")

    local clone = template:Clone()
    clone.Name = "msdoorsAchievementNotify"
    clone.Parent = achievementHolder

    local achievement = clone:WaitForChild("Achievement")
    local glow = clone:WaitForChild("Glow")

    paradox_save(clone)
    for _, obj in clone:GetDescendants() do paradox_save(obj) end

    achievement.Position = UDim2.new(0.5, 0, 1.25, 0)

    local titleLabel  = achievement:FindFirstChild("Title")
    local descLabel   = achievement:FindFirstChild("Description")
    local actionLabel = achievement:FindFirstChild("Action")
    local iconImage   = achievement:FindFirstChild("Icon")

    if titleLabel  then titleLabel.Text  = opts.Title or "Achievement" end
    if descLabel   then descLabel.Text   = opts.Description or "" end
    if actionLabel then actionLabel.Text = opts.Action or "" end
    if iconImage   then iconImage.Image  = opts.Image or "rbxassetid://6023426923" end

    local soundId = resolveSound(opts.Sound, "rbxassetid://91986934883173")
    playSound(achievementHolder, soundId, 5)

    local moveTween = TweenService:Create(achievement, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })

    task.wait(0.5)

    paradox_tweenIn(clone)
    for _, obj in clone:GetDescendants() do paradox_tweenIn(obj) end

    moveTween:Play()

    task.delay(0.8, function()
        TweenService:Create(glow, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ImageTransparency = 1 }):Play()
    end)

    task.wait(opts.Time or 5)

    paradox_tweenOut(clone)
    for _, obj in clone:GetDescendants() do paradox_tweenOut(obj) end

    task.wait(0.5)
    clone:Destroy()
end

local function notifyLinoria(opts)
    if Library and Library.Notify then
        local soundId = resolveSound(opts.Sound, DEFAULT_SOUND)
        playSound(game.Workspace, soundId, 1)
        Library:Notify({
            Title       = opts.Title or "Sem Título",
            Description = opts.Description or "Sem Descrição",
            Time        = opts.Time or 5,
        })
    else
        warn("Library não encontrada.")
    end
end

local function notifyDoors(opts)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local uiContainer = playerGui:FindFirstChild("GlobalUI") or playerGui:FindFirstChild("MainUI")
    if not uiContainer then warn("GlobalUI ou MainUI não encontradas.") return end

    local achievementsHolder = uiContainer:FindFirstChild("AchievementsHolder")
    if not achievementsHolder then warn("AchievementsHolder não encontrado.") return end

    local achievement = achievementsHolder.Achievement:Clone()
    achievement.Size = UDim2.new(0, 0, 0, 0)
    achievement.Frame.Position = UDim2.new(1.1, 0, 0, 0)
    achievement.Name = "LiveAchievement"
    achievement.Visible = true

    achievement.Frame.TextLabel.Text      = opts.Style or "NOTIFICATION"
    achievement.Frame.Details.Title.Text  = opts.Title or "Sem Título"
    achievement.Frame.Details.Desc.Text   = opts.Description or "Sem Descrição"
    achievement.Frame.Details.Reason.Text = opts.Reason or ""
    achievement.Frame.ImageLabel.Image    = opts.Image or "rbxassetid://6023426923"

    local col = opts.Color or Color3.new(1, 1, 1)
    achievement.Frame.TextLabel.TextColor3 = col
    achievement.Frame.UIStroke.Color       = col
    achievement.Frame.Glow.ImageColor3     = col

    achievement.Parent = achievementsHolder

    local soundId = resolveSound(opts.Sound, "rbxassetid://10469938989")
    playSound(achievementsHolder, soundId, 1)

    task.spawn(function()
        achievement:TweenSize(UDim2.new(1, 0, 0.2, 0), "In", "Quad", 0.8, true)
        task.wait(0.8)
        achievement.Frame:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quad", 0.5, true)
        TweenService:Create(achievement.Frame.Glow, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ImageTransparency = 1 }):Play()
        task.wait(opts.Time or 5)
        achievement.Frame:TweenPosition(UDim2.new(1.1, 0, 0, 0), "In", "Quad", 0.5, true)
        task.wait(0.5)
        achievement:TweenSize(UDim2.new(1, 0, -0.1, 0), "InOut", "Quad", 0.5, true)
        task.wait(0.5)
        achievement:Destroy()
    end)
end

local StarterGui = game:GetService("StarterGui")

local function notifyRoblox(opts)
    local soundId = resolveSound(opts.Sound, DEFAULT_SOUND)
    playSound(game.Workspace, soundId, 1)
    StarterGui:SetCore("SendNotification", {
        Title    = opts.Title or "Notificação",
        Text     = opts.Description or opts.Reason or "",
        Icon     = opts.Image or "",
        Duration = opts.Time or 5,
        Callback = opts.Callback or nil,
        Button1  = opts.Button1 or nil,
        Button2  = opts.Button2 or nil,
    })
end

local NOTIF_HEIGHT = 60

local function abyssalGetLogicalY(obj)
    return obj:GetAttribute("LogicalY") or 60
end

local function abyssalSetLogicalY(obj, y)
    obj:SetAttribute("LogicalY", y)
end

local function abyssalTweenToLogicalY(obj, xOffset)
    local y = abyssalGetLogicalY(obj)
    TweenService:Create(obj, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, xOffset, 0, y)
    }):Play()
end

local function notifyAbyssal(opts)
    task.spawn(function()
        local Container = getAbyssalContainer()

        local accentColor     = opts.Color or Color3.fromRGB(255, 100, 100)
        local backgroundColor = opts.BackgroundColor or Color3.fromRGB(30, 30, 35)
        local fontColor       = opts.FontColor or Color3.fromRGB(240, 240, 240)
        local delay           = opts.Time or 5

        for _, obj in ipairs(Container:GetChildren()) do
            if obj.Name == "Notification" then
                abyssalSetLogicalY(obj, abyssalGetLogicalY(obj) + NOTIF_HEIGHT)
                abyssalTweenToLogicalY(obj, -370)
            end
        end

        local Notification = Instance.new("Frame")
        local Line         = Instance.new("Frame")
        local Warning      = Instance.new("ImageLabel")
        local UICorner     = Instance.new("UICorner")
        local UICorner2    = Instance.new("UICorner")
        local Title        = Instance.new("TextLabel")
        local Description  = Instance.new("TextLabel")

        Notification.Name = "Notification"
        Notification.Parent = Container
        Notification.BackgroundColor3 = backgroundColor
        Notification.BackgroundTransparency = 0.4
        Notification.BorderSizePixel = 0
        Notification.Position = UDim2.new(1, 5, 0, 60)
        Notification.Size = UDim2.new(0, 420, 0, 50)
        abyssalSetLogicalY(Notification, 60)

        Line.Name = "Line"
        Line.Parent = Notification
        Line.BackgroundColor3 = accentColor
        Line.BorderSizePixel = 0
        Line.Position = UDim2.new(0, 0, 1, -3)
        Line.Size = UDim2.new(0, 0, 0, 3)

        local rawImg = opts.Image or ""
        local resolvedImg
        if rawImg:match("^rbxassetid://") then
            resolvedImg = rawImg
        elseif rawImg:match("^%d+$") and #rawImg > 0 then
            resolvedImg = "rbxassetid://" .. rawImg
        else
            resolvedImg = "rbxassetid://3944668821"
        end

        Warning.Name = "Warning"
        Warning.Parent = Notification
        Warning.BackgroundTransparency = 1
        Warning.Position = UDim2.new(0, 10, 0, 5)
        Warning.Size = UDim2.new(0, 40, 0, 40)
        Warning.Image = resolvedImg
        Warning.ImageColor3 = accentColor
        Warning.ScaleType = Enum.ScaleType.Fit

        UICorner.CornerRadius = UDim.new(0, 20)
        UICorner.Parent = Warning

        UICorner2.CornerRadius = UDim.new(0, 4)
        UICorner2.Parent = Notification

        Title.Name = "Title"
        Title.Parent = Notification
        Title.BackgroundTransparency = 1
        Title.Position = UDim2.new(0, 60, 0.155, 0)
        Title.Size = UDim2.new(0, 205, 0, 15)
        Title.Text = opts.Title or "..."
        Title.TextColor3 = fontColor
        Title.TextSize = 10
        Title.TextStrokeTransparency = 0.75
        Title.TextXAlignment = Enum.TextXAlignment.Left

        Description.Name = "Description"
        Description.Parent = Notification
        Description.BackgroundTransparency = 1
        Description.Position = UDim2.new(0, 60, 0.483, 0)
        Description.Size = UDim2.new(0, 205, 0, 18)
        Description.Text = opts.Description or opts.Reason or "..."
        Description.TextColor3 = fontColor
        Description.TextTransparency = 0.1
        Description.TextSize = 10
        Description.TextStrokeTransparency = 0.75
        Description.TextXAlignment = Enum.TextXAlignment.Left

        local soundId = resolveSound(opts.Sound, ABYSSAL_DEFAULT_SOUND)
        playSound(Container, soundId, 3)

        TweenService:Create(Notification, TweenInfo.new(1, Enum.EasingStyle.Exponential), {
            Position = UDim2.new(1, -370, 0, 60)
        }):Play()

        task.wait(0.25)
        TweenService:Create(Line, TweenInfo.new(delay - 0.25, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 400, 0, 3)
        }):Play()
        task.wait(delay - 0.25)

        TweenService:Create(Notification, TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 5, 0, abyssalGetLogicalY(Notification))
        }):Play()

        local myLogicalY = abyssalGetLogicalY(Notification)
        task.wait(0.75)
        Notification:Destroy()

        for _, obj in ipairs(Container:GetChildren()) do
            if obj.Name == "Notification" then
                local ly = abyssalGetLogicalY(obj)
                if ly > myLogicalY then
                    abyssalSetLogicalY(obj, ly - NOTIF_HEIGHT)
                    abyssalTweenToLogicalY(obj, -370)
                end
            end
        end
    end)
end

local function initMParadoxUI()
    if mp.holder then return end

    local pg = Players.LocalPlayer:WaitForChild("PlayerGui")

    local sg = Instance.new("ScreenGui")
    sg.Name = "MParadoxUI"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = pg

    local holder = Instance.new("Frame")
    holder.Name = "AchievementHolder"
    holder.Size = UDim2.new(1, 0, 1, 0)
    holder.BackgroundTransparency = 1
    holder.Parent = sg

    mp.holder = holder

    local tmpl = Instance.new("Frame")
    tmpl.Name = "Template"
    tmpl.BackgroundTransparency = 1
    tmpl.BorderSizePixel = 0
    tmpl.Position = UDim2.new(0.5, 0, 0.5, 0)
    tmpl.Size = UDim2.new(0.689964, 0, 0.163091, 0)
    tmpl.AnchorPoint = Vector2.new(0.5, 0.5)
    tmpl.Active = false

    local arc = Instance.new("UIAspectRatioConstraint")
    arc.AspectRatio = 4.53
    arc.AspectType = Enum.AspectType.FitWithinMaxSize
    arc.DominantAxis = Enum.DominantAxis.Width
    arc.Parent = tmpl

    local ach = Instance.new("Frame")
    ach.Name = "Achievement"
    ach.AnchorPoint = Vector2.new(0.5, 0.5)
    ach.BackgroundColor3 = Color3.fromRGB(38, 25, 25)
    ach.BackgroundTransparency = 0.5
    ach.BorderSizePixel = 0
    ach.ClipsDescendants = true
    ach.Position = UDim2.new(0.5, 0, 0.5, 0)
    ach.Size = UDim2.new(0.7, 0, 0.8, 0)
    ach.ZIndex = 9999
    ach.Parent = tmpl

    local achCorner = Instance.new("UICorner")
    achCorner.CornerRadius = UDim.new(1, 0)
    achCorner.Parent = ach

    local achStroke = Instance.new("UIStroke")
    achStroke.Name = "UIStroke"
    achStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    achStroke.Color = Color3.fromRGB(255, 222, 189)
    achStroke.LineJoinMode = Enum.LineJoinMode.Round
    achStroke.Thickness = 2
    achStroke.Transparency = 0
    achStroke.Parent = ach

    local bg = Instance.new("ImageLabel")
    bg.Name = "Background"
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel = 0
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.ZIndex = 30000
    bg.Image = "rbxassetid://10513034999"
    bg.ImageColor3 = Color3.fromRGB(255, 222, 189)
    bg.ResampleMode = Enum.ResamplerMode.Default
    bg.ScaleType = Enum.ScaleType.Tile
    bg.TileSize = UDim2.new(0.05, 0, 0.25, 0)
    bg.Parent = ach

    local bgGrad = Instance.new("UIGradient")
    bgGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))})
    bgGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(1, 0.956284, 0)})
    bgGrad.Enabled = true
    bgGrad.Parent = bg

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = bg

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.BorderSizePixel = 0
    icon.Position = UDim2.new(0, 0, 0.5, 0)
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.ZIndex = 9999999
    icon.Image = "rbxassetid://6023426923"
    icon.ResampleMode = Enum.ResamplerMode.Default
    icon.ScaleType = Enum.ScaleType.Crop
    icon.Parent = ach

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = icon

    local iconStroke = Instance.new("UIStroke")
    iconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    iconStroke.Color = Color3.fromRGB(255, 222, 189)
    iconStroke.LineJoinMode = Enum.LineJoinMode.Round
    iconStroke.Thickness = 1
    iconStroke.Transparency = 0.33
    iconStroke.Parent = icon

    local iconArc = Instance.new("UIAspectRatioConstraint")
    iconArc.AspectRatio = 1
    iconArc.AspectType = Enum.AspectType.FitWithinMaxSize
    iconArc.DominantAxis = Enum.DominantAxis.Width
    iconArc.Parent = icon

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name = "Title"
    titleLbl.BackgroundTransparency = 1
    titleLbl.BorderSizePixel = 0
    titleLbl.Position = UDim2.new(0.274962, 0, 0.0691536, 0)
    titleLbl.Size = UDim2.new(0.65613, 0, 0.36, 0)
    titleLbl.ZIndex = 40000
    titleLbl.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    titleLbl.Text = ""
    titleLbl.TextColor3 = Color3.fromRGB(255, 222, 189)
    titleLbl.TextScaled = true
    titleLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLbl.TextWrapped = true
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = ach

    local descLbl = Instance.new("TextLabel")
    descLbl.Name = "Description"
    descLbl.BackgroundTransparency = 1
    descLbl.BorderSizePixel = 0
    descLbl.Position = UDim2.new(0.274891, 0, 0.429154, 0)
    descLbl.Size = UDim2.new(0.525168, 0, 0.272954, 0)
    descLbl.ZIndex = 40000
    descLbl.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    descLbl.Text = ""
    descLbl.TextColor3 = Color3.fromRGB(255, 222, 189)
    descLbl.TextScaled = true
    descLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    descLbl.TextWrapped = true
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.Parent = ach

    local actionLbl = Instance.new("TextLabel")
    actionLbl.Name = "Action"
    actionLbl.BackgroundTransparency = 1
    actionLbl.BorderSizePixel = 0
    actionLbl.Position = UDim2.new(0.274962, 0, 0.699153, 0)
    actionLbl.Size = UDim2.new(0.452286, 0, 0.204789, 0)
    actionLbl.ZIndex = 40000
    actionLbl.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    actionLbl.Text = ""
    actionLbl.TextColor3 = Color3.fromRGB(255, 222, 189)
    actionLbl.TextScaled = true
    actionLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    actionLbl.TextTransparency = 0.33
    actionLbl.TextWrapped = true
    actionLbl.TextXAlignment = Enum.TextXAlignment.Left
    actionLbl.Parent = ach

    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.Size = UDim2.new(2.2, 0, 5, 0)
    glow.ZIndex = 1999
    glow.Image = "rbxassetid://61997378"
    glow.ImageColor3 = Color3.fromRGB(255, 222, 189)
    glow.ImageTransparency = 0.75
    glow.Parent = ach

    mp.template = tmpl
end

local function mp_saveTransp(obj, cache)
    local data = {}
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        data.ImageTransparency = obj.ImageTransparency
        if obj:FindFirstChildOfClass("UIStroke") then data.StrokeTransparency = obj.UIStroke.Transparency end
        obj.ImageTransparency = 1
        if obj:FindFirstChildOfClass("UIStroke") then obj.UIStroke.Transparency = 1 end
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
        data.TextTransparency = obj.TextTransparency
        data.BackgroundTransparency = obj.BackgroundTransparency
        if obj:FindFirstChildOfClass("UIStroke") then data.StrokeTransparency = obj.UIStroke.Transparency end
        obj.TextTransparency = 1
        obj.BackgroundTransparency = 1
        if obj:FindFirstChildOfClass("UIStroke") then obj.UIStroke.Transparency = 1 end
    elseif obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("ViewportFrame") then
        data.BackgroundTransparency = obj.BackgroundTransparency
        if obj:FindFirstChildOfClass("UIStroke") then data.StrokeTransparency = obj.UIStroke.Transparency end
        obj.BackgroundTransparency = 1
        if obj:FindFirstChildOfClass("UIStroke") then obj.UIStroke.Transparency = 1 end
    end
    cache[obj] = data
end

local function mp_tweenIn(obj, cache)
    local data = cache[obj]
    if not data then return end
    local ti = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        TweenService:Create(obj, ti, { ImageTransparency = data.ImageTransparency or 0 }):Play()
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = data.StrokeTransparency or 0 }):Play() end
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
        TweenService:Create(obj, ti, { TextTransparency = data.TextTransparency or 0, BackgroundTransparency = data.BackgroundTransparency or 1 }):Play()
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = data.StrokeTransparency or 0 }):Play() end
    elseif obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("ViewportFrame") then
        TweenService:Create(obj, ti, { BackgroundTransparency = data.BackgroundTransparency or 0 }):Play()
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = data.StrokeTransparency or 0 }):Play() end
    end
end

local function mp_tweenOut(obj)
    local ti = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        TweenService:Create(obj, ti, { ImageTransparency = 1 }):Play()
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = 1 }):Play() end
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
        TweenService:Create(obj, ti, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = 1 }):Play() end
    elseif obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("ViewportFrame") then
        TweenService:Create(obj, ti, { BackgroundTransparency = 1 }):Play()
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = 1 }):Play() end
    end
end

local MP_STACK_SCALE_STEP   = 0.06
local MP_STACK_Y_STEP       = -0.045
local MP_STACK_TRANSP_STEP  = 0.28
local MP_STACK_MAX          = 3
local MP_CENTER_Y           = 0.82

local function mp_applyStackState(clone, depth)
    local achievement = clone:FindFirstChild("Achievement")
    local glow        = clone:FindFirstChild("Glow")
    if not achievement then return end

    local scale      = 1 - (depth * MP_STACK_SCALE_STEP)
    local yOffset    = depth * MP_STACK_Y_STEP
    local bgTransp   = math.min(0.5 + depth * MP_STACK_TRANSP_STEP, 1)
    local textTransp = math.min(depth * MP_STACK_TRANSP_STEP, 1)
    local strokeT    = math.min(depth * MP_STACK_TRANSP_STEP, 1)

    local ti = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    TweenService:Create(achievement, ti, {
        Position = UDim2.new(0.5, 0, MP_CENTER_Y + yOffset, 0),
        Size     = UDim2.new(0.7 * scale, 0, 0.8 * scale, 0),
    }):Play()

    TweenService:Create(achievement, ti, {
        BackgroundTransparency = bgTransp,
    }):Play()

    local uiStroke = achievement:FindFirstChild("UIStroke")
    if uiStroke then
        TweenService:Create(uiStroke, ti, { Transparency = strokeT }):Play()
    end

    for _, lbl in ipairs(achievement:GetDescendants()) do
        if lbl:IsA("TextLabel") then
            TweenService:Create(lbl, ti, { TextTransparency = textTransp }):Play()
        elseif lbl:IsA("ImageLabel") and lbl.Name ~= "Background" then
            TweenService:Create(lbl, ti, { ImageTransparency = textTransp }):Play()
        end
    end

    if glow then
        TweenService:Create(glow, ti, { ImageTransparency = 1 }):Play()
    end

    clone:SetAttribute("MPDepth", depth)
end

local function showMParadox(opts)
    local clone = mp.template:Clone()
    clone.Parent = mp.holder
    clone:SetAttribute("MPDepth", 0)
    clone:SetAttribute("MPAlive", true)

    local achievement = clone:WaitForChild("Achievement")
    local glow        = achievement:WaitForChild("Glow")

    local rawImg = opts.Image or ""
    local resolvedImg
    if rawImg:match("^rbxassetid://") then
        resolvedImg = rawImg
    elseif rawImg:match("^%d+$") and #rawImg > 0 then
        resolvedImg = "rbxassetid://" .. rawImg
    else
        resolvedImg = "rbxassetid://6023426923"
    end

    achievement:WaitForChild("Icon").Image        = resolvedImg
    achievement:WaitForChild("Title").Text        = opts.Title or ""
    achievement:WaitForChild("Description").Text  = opts.Description or ""
    achievement:WaitForChild("Action").Text       = opts.Reason or ""

    local col = opts.Color or Color3.fromRGB(255, 222, 189)
    achievement:WaitForChild("UIStroke").Color                       = col
    achievement:WaitForChild("Icon"):WaitForChild("UIStroke").Color  = col
    achievement:WaitForChild("Background").ImageColor3               = col
    glow.ImageColor3 = col

    for _, existing in ipairs(mp.holder:GetChildren()) do
        if existing ~= clone and existing:GetAttribute("MPAlive") then
            local newDepth = (existing:GetAttribute("MPDepth") or 0) + 1
            if newDepth >= MP_STACK_MAX then
                existing:SetAttribute("MPAlive", false)
                local ti = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                local ach2 = existing:FindFirstChild("Achievement")
                if ach2 then
                    TweenService:Create(ach2, ti, { BackgroundTransparency = 1 }):Play()
                    for _, d in ipairs(ach2:GetDescendants()) do
                        if d:IsA("TextLabel") then
                            TweenService:Create(d, ti, { TextTransparency = 1 }):Play()
                        elseif d:IsA("ImageLabel") then
                            TweenService:Create(d, ti, { ImageTransparency = 1 }):Play()
                        end
                    end
                end
                task.delay(0.35, function() existing:Destroy() end)
            else
                mp_applyStackState(existing, newDepth)
            end
        end
    end

    local transpCache = {}
    mp_saveTransp(clone, transpCache)
    for _, obj in ipairs(clone:GetDescendants()) do
        mp_saveTransp(obj, transpCache)
    end

    achievement.Position = UDim2.new(0.5, 0, 1.25, 0)
    achievement.Size     = UDim2.new(0.7, 0, 0.8, 0)

    local soundId = resolveSound(opts.Sound, getOrDownloadParadoxSound())
    playSound(mp.holder, soundId, 1)

    task.wait(0.5)

    mp_tweenIn(clone, transpCache)
    for _, obj in ipairs(clone:GetDescendants()) do
        mp_tweenIn(obj, transpCache)
    end

    TweenService:Create(achievement, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, MP_CENTER_Y, 0),
    }):Play()

    task.delay(0.8, function()
        TweenService:Create(glow, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            ImageTransparency = 1
        }):Play()
    end)

    task.wait(opts.Time or 5)

    if not clone.Parent then return end

    clone:SetAttribute("MPAlive", false)

    mp_tweenOut(clone)
    for _, obj in ipairs(clone:GetDescendants()) do
        mp_tweenOut(obj)
    end

    task.wait(0.5)
    if clone.Parent then clone:Destroy() end
end

local function processMParadoxQueue()
    if mp.processing then return end
    mp.processing = true
    while #mp.queue > 0 do
        task.spawn(showMParadox, table.remove(mp.queue, 1))
        task.wait(0.5)
    end
    mp.processing = false
end

local function notifyMParadox(opts)
    initMParadoxUI()
    table.insert(mp.queue, opts)
    task.spawn(processMParadoxQueue)
end

local STYLES = {
    Linoria  = notifyLinoria,
    Obsidian = notifyLinoria,
    Obsdian  = notifyLinoria,
    Doors    = notifyDoors,
    msdoors  = function(opts)
        initMsdoorsUI()
        table.insert(d.queue, opts)
        processMsdoorsQueue()
    end,
    Paradox  = function(opts)
        task.spawn(notifyParadox, opts)
    end,
    MParadox = notifyMParadox,
    Roblox   = notifyRoblox,
    Abyssal  = notifyAbyssal,
}

local function normalizeOpts(opts)
    opts.Time   = opts.Time or opts.Duration
    opts.Reason = opts.Reason or opts.Action
    opts.Sound  = opts.Sound or opts.SoundId or opts.soundpar
    return opts
end

local function NOTIFY(style, opts)
    opts = normalizeOpts(opts or {})
    local handler = STYLES[style]
    if handler then
        handler(opts)
    else
        warn("Estilo de notificação inválido: " .. tostring(style))
    end
end

local function callNotify(style, opts)
    if type(style) == "table" and opts == nil then
        local s = style.NotifyStyle or "Linoria"
        NOTIFY(s, style)
    else
        NOTIFY(style, opts or {})
    end
end

shared.notifyap.Notify = callNotify

if getgenv then
    getgenv().msdoorsNAPI = callNotify
end

return callNotify
