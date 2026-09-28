if not shared.notifyap then shared.notifyap = {} end

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local DEFAULT_SOUND = "rbxassetid://4590657391"
local MSDOORS_SOUND_URL = "https://github.com/Msdoors/Msdoors.gg/raw/refs/heads/main/Scripts/Msdoors/Notification/DOORS-ACHIEVIMENT.mp3"
local MSDOORS_SOUND_PATH = "msdoors/DOORS-ACHIEVEMENT.mp3"
local PARADOX_SOUND_URL = "https://github.com/Msdoors/Msdoors.gg/raw/refs/heads/main/Scripts/Msdoors/Notification/PARADOX-ACHIEVIMENT.ogg"
local PARADOX_SOUND_PATH = "msdoors/PARADOX-ACHIEVIMENT.ogg"
local ABYSSAL_DEFAULT_SOUND = "rbxassetid://8784885431"

shared.ACHIDATA = shared.ACHIDATA or { template = nil, gui = nil, queue = {}, processing = false, defaultSound = nil }
local d = shared.ACHIDATA

shared.MPARADOX = shared.MPARADOX or { template = nil, holder = nil, queue = {}, processing = false, defaultSound = nil }
local mp = shared.MPARADOX

local AbyssalState = {
    Container = nil,
}

local function getMainUiContainer()
    local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
    local main = pg:FindFirstChild("msdoors")
    if not main then
        main = Instance.new("ScreenGui")
        main.Name = "msdoors"
        main.ResetOnSpawn = false
        main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        main.Parent = pg
    end
    return main
end

local function getAbyssalContainer()
    if AbyssalState.Container and AbyssalState.Container.Parent then
        return AbyssalState.Container
    end
    local sg = getMainUiContainer():FindFirstChild("AbyssalNotifyUI")
    if not sg then
        sg = Instance.new("Frame")
        sg.Name = "AbyssalNotifyUI"
        sg.Size = UDim2.new(1, 0, 1, 0)
        sg.BackgroundTransparency = 1
        sg.Parent = getMainUiContainer()
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
local _soundCacheReady = false

local function ensureSoundCache()
    if _soundCacheReady then return end
    _soundCacheReady = true
    if not isfolder("msdoors") then makefolder("msdoors") end
    if not isfolder("msdoors/.cache") then makefolder("msdoors/.cache") end
    if not isfolder("msdoors/.cache/sounds") then makefolder("msdoors/.cache/sounds") end
    if isfolder("msdoors/.cache/sounds/notifys") then
        local ok, files = pcall(listfiles, "msdoors/.cache/sounds/notifys")
        if ok then
            for _, path in ipairs(files) do pcall(delfile, path) end
        end
    else
        makefolder("msdoors/.cache/sounds/notifys")
    end
end

local function resolveSound(soundpar, fallback)
    if not soundpar or soundpar == "" then return fallback or DEFAULT_SOUND end
    if soundpar:match("^rbxassetid://") then return soundpar end
    if soundpar:match("^%d+$") then return "rbxassetid://" .. soundpar end
    if soundpar:match("^https?://") then
        if soundUrlCache[soundpar] then return soundUrlCache[soundpar] end
        ensureSoundCache()
        local ext = soundpar:match("%.(%a+)%f[%A]") or "mp3"
        local key = tostring(#soundpar) .. "_" .. soundpar:sub(-16):gsub("[^%w]", "") .. "." .. ext
        local cachedPath = "msdoors/.cache/sounds/notifys/snd_" .. key
        if isfile(cachedPath) then
            local fn = getcustomasset or getsynasset
            local asset = fn(cachedPath)
            soundUrlCache[soundpar] = asset
            return asset
        end
        local ok, data = pcall(game.HttpGet, game, soundpar)
        if ok then
            writefile(cachedPath, data)
            local fn = getcustomasset or getsynasset
            local asset = fn(cachedPath)
            soundUrlCache[soundpar] = asset
            return asset
        end
        return fallback or DEFAULT_SOUND
    end
    return fallback or DEFAULT_SOUND
end

local imageUrlCache = {}

local function resolveImage(imagepar)
    if not imagepar or imagepar == "" then return "" end
    if imagepar:match("^rbxassetid://") then return imagepar end
    if imagepar:match("^%d+$") and #imagepar > 0 then return "rbxassetid://" .. imagepar end
    if imagepar:match("^https?://") then
        if imageUrlCache[imagepar] then return imageUrlCache[imagepar] end
        if not isfolder("msdoors") then makefolder("msdoors") end
        if not isfolder("msdoors/.cache") then makefolder("msdoors/.cache") end
        if not isfolder("msdoors/.cache/images") then makefolder("msdoors/.cache/images") end
        local filename = imagepar:match("/([^/]+)$") or "image.png"
        local cachedPath = "msdoors/.cache/images/" .. filename
        if isfile(cachedPath) then
            local fn = getcustomasset or getsynasset
            local asset = fn(cachedPath)
            imageUrlCache[imagepar] = asset
            return asset
        end
        local ok, data = pcall(game.HttpGet, game, imagepar)
        if ok then
            writefile(cachedPath, data)
            local fn = getcustomasset or getsynasset
            local asset = fn(cachedPath)
            imageUrlCache[imagepar] = asset
            return asset
        end
        return ""
    end
    return ""
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

local function darkenColor(c, amount)
    return Color3.new(c.R * amount, c.G * amount, c.B * amount)
end

local function initMsdoorsUI()
    if d.gui then return end

    local sg = getMainUiContainer():FindFirstChild("AchievementUI")
    if not sg then
        sg = Instance.new("Frame")
        sg.Name = "AchievementUI"
        sg.Size = UDim2.new(1, 0, 1, 0)
        sg.BackgroundTransparency = 1
        sg.Parent = getMainUiContainer()
    end

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
    achi.F.Img.Image       = resolveImage(opts.Image) ~= "" and resolveImage(opts.Image) or "rbxassetid://6023426923"

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
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = data.StrokeTransparency or 0}):Play() end
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
    task.spawn(function()
        local ok, playerGui = pcall(function() return Players.LocalPlayer:WaitForChild("PlayerGui", 5) end)
        if not ok or not playerGui then return warn("PlayerGui não encontrado para Paradox.") end

        local ok2, achievementGui = pcall(function()
            return playerGui:WaitForChild("Initiate", 5):WaitForChild("Library", 5):WaitForChild("GUI", 5):WaitForChild("Achievement", 5)
        end)
        if not ok2 or not achievementGui then return warn("UI do Paradox não encontrada.") end

        local ok3, template = pcall(function() return achievementGui:WaitForChild("Template", 5) end)
        if not ok3 or not template then return warn("Template do Paradox não encontrado.") end

        local ok4, achievementHolder = pcall(function()
            return playerGui:WaitForChild("MainUI", 5):WaitForChild("AchievementHolder", 5)
        end)
        if not ok4 or not achievementHolder then return warn("AchievementHolder do Paradox não encontrado.") end

        local clone = template:Clone()
        clone.Name = "msdoorsAchievementNotify"
        clone.Parent = achievementHolder

        local achievement = clone:WaitForChild("Achievement", 5)
        local glow = clone:WaitForChild("Glow", 5)
        if not achievement or not glow then return warn("Elementos do Paradox não encontrados.") end

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
        if iconImage   then
            local resolved = resolveImage(opts.Image)
            iconImage.Image = resolved ~= "" and resolved or "rbxassetid://6023426923"
        end

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
    end)
end

local function notifyLibrary(opts)
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

local Linoria_Active = {}
local function notifyLinoria(opts)
    task.spawn(function()
        local Title = opts.Title or ""
        local Desc = opts.Description or ""
        local Time = opts.Time or 5
        local Icon = opts.Image or ""
        
        local soundId = resolveSound(opts.Sound, DEFAULT_SOUND)
        playSound(getMainUiContainer(), soundId, 1)

        local MainColor = Color3.fromRGB(45, 45, 45)
        local OutlineColor = Color3.fromRGB(20, 20, 20)
        local AccentColor = Color3.fromRGB(100, 100, 255)
        local FontColor = Color3.fromRGB(240, 240, 240)
        if Library then
            MainColor = Library.MainColor or MainColor
            OutlineColor = Library.OutlineColor or OutlineColor
            AccentColor = Library.AccentColor or AccentColor
            FontColor = Library.FontColor or FontColor
        end

        local Text = (Title == "" and "" or "[" .. Title .. "] ") .. Desc
        local bounds = TextService:GetTextSize(Text, 14, Enum.Font.Code, Vector2.new(300, 1000))
        local YSize = bounds.Y + 7
        local XSize = bounds.X

        local container = getMainUiContainer()

        for _, notif in ipairs(Linoria_Active) do
            local currY = notif.Position.Y.Offset
            TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -10, 0, currY + YSize + 5)
            }):Play()
        end

        local NotifyOuter = Instance.new("Frame")
        NotifyOuter.AnchorPoint = Vector2.new(1, 0)
        NotifyOuter.Position = UDim2.new(1, 10, 0, 10)
        NotifyOuter.Size = UDim2.new(0, 0, 0, YSize)
        NotifyOuter.BackgroundTransparency = 1
        NotifyOuter.ClipsDescendants = true
        NotifyOuter.ZIndex = 9999
        NotifyOuter.Parent = container
        table.insert(Linoria_Active, 1, NotifyOuter)

        local NotifyInner = Instance.new("Frame")
        NotifyInner.BackgroundColor3 = MainColor
        NotifyInner.BorderColor3 = OutlineColor
        NotifyInner.Size = UDim2.new(1, 0, 1, 0)
        NotifyInner.ZIndex = 10000
        NotifyInner.Parent = NotifyOuter

        local InnerFrame = Instance.new("Frame")
        InnerFrame.BackgroundColor3 = Color3.new(1, 1, 1)
        InnerFrame.BorderSizePixel = 0
        InnerFrame.Position = UDim2.new(0, 1, 0, 1)
        InnerFrame.Size = UDim2.new(1, -2, 1, -2)
        InnerFrame.ZIndex = 10001
        InnerFrame.Parent = NotifyInner

        local Gradient = Instance.new("UIGradient")
        Gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, darkenColor(MainColor, 0.8)),
            ColorSequenceKeypoint.new(1, MainColor),
        })
        Gradient.Rotation = -90
        Gradient.Parent = InnerFrame

        local ExtraWidth = 0
        local IconLabel
        if Icon ~= "" then
            ExtraWidth = 20
            IconLabel = Instance.new("ImageLabel")
            IconLabel.BackgroundTransparency = 1
            IconLabel.AnchorPoint = Vector2.new(0, 0.5)
            IconLabel.Position = UDim2.new(0, 4, 0.5, 0)
            IconLabel.Size = UDim2.fromOffset(14, 14)
            IconLabel.Image = resolveImage(Icon)
            IconLabel.ImageColor3 = FontColor
            IconLabel.ZIndex = 10003
            IconLabel.Parent = InnerFrame
        end

        local NotifyLabel = Instance.new("TextLabel")
        NotifyLabel.AnchorPoint = Vector2.new(1, 0)
        NotifyLabel.Position = UDim2.new(1, -4, 0, 0)
        NotifyLabel.Size = UDim2.new(1, -8 - ExtraWidth, 1, 0)
        NotifyLabel.BackgroundTransparency = 1
        NotifyLabel.Text = Text
        NotifyLabel.TextColor3 = FontColor
        NotifyLabel.Font = Enum.Font.Code
        NotifyLabel.TextSize = 14
        NotifyLabel.TextXAlignment = Enum.TextXAlignment.Right
        NotifyLabel.TextYAlignment = Enum.TextYAlignment.Center
        NotifyLabel.RichText = true
        NotifyLabel.ZIndex = 10002
        NotifyLabel.Parent = InnerFrame

        local SideColor = Instance.new("Frame")
        SideColor.AnchorPoint = Vector2.new(1, 0)
        SideColor.Position = UDim2.new(1, 0, 0, 0)
        SideColor.BackgroundColor3 = AccentColor
        SideColor.BorderSizePixel = 0
        SideColor.Size = UDim2.new(0, 3, 1, 0)
        SideColor.ZIndex = 10004
        SideColor.Parent = NotifyOuter

        TweenService:Create(NotifyOuter, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -10, 0, 10)
        }):Play()
        NotifyOuter:TweenSize(UDim2.new(0, XSize + 8 + ExtraWidth, 0, YSize), "Out", "Quad", 0.4, true)

        task.wait(Time)
        TweenService:Create(NotifyOuter, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, 10, 0, 10)
        }):Play()
        NotifyOuter:TweenSize(UDim2.new(0, 0, 0, YSize), "Out", "Quad", 0.4, true)
        task.wait(0.4)
        NotifyOuter:Destroy()

        local index = table.find(Linoria_Active, NotifyOuter)
        if index then table.remove(Linoria_Active, index) end

        for _, notif in ipairs(Linoria_Active) do
            local currY = notif.Position.Y.Offset
            TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -10, 0, currY - YSize - 5)
            }):Play()
        end
    end)
end

local Obsidian_Active = {}
local function notifyObsidian(opts)
    task.spawn(function()
        local Title = opts.Title or ""
        local Desc = opts.Description or ""
        local Time = opts.Time or 5
        local Icon = opts.Image or ""
        local Closable = opts.Closable == true
        
        local soundId = resolveSound(opts.Sound, DEFAULT_SOUND)
        playSound(getMainUiContainer(), soundId, 1)

        local MainColor = Color3.fromRGB(45, 45, 45)
        local OutlineColor = Color3.fromRGB(20, 20, 20)
        local AccentColor = Color3.fromRGB(100, 100, 255)
        local FontColor = Color3.fromRGB(240, 240, 240)
        if Library then
            MainColor = Library.MainColor or MainColor
            OutlineColor = Library.OutlineColor or OutlineColor
            AccentColor = Library.AccentColor or AccentColor
            FontColor = Library.FontColor or FontColor
        end

        local container = getMainUiContainer()
        local MaxWidth = 300
        local TitleBounds = TextService:GetTextSize(Title, 15, Enum.Font.GothamMedium, Vector2.new(MaxWidth, 1000))
        local DescBounds = TextService:GetTextSize(Desc, 14, Enum.Font.GothamMedium, Vector2.new(MaxWidth, 1000))
        local NotifHeight = 8 + (Title ~= "" and TitleBounds.Y + 4 or 0) + DescBounds.Y + 8 + 4

        for _, notif in ipairs(Obsidian_Active) do
            local currY = notif.Position.Y.Offset
            TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -10, 0, currY + NotifHeight + 8)
            }):Play()
        end

        local FakeBackground = Instance.new("Frame")
        FakeBackground.AnchorPoint = Vector2.new(1, 0)
        FakeBackground.AutomaticSize = Enum.AutomaticSize.Y
        FakeBackground.Position = UDim2.new(1, 10, 0, 10)
        FakeBackground.Size = UDim2.new(0, 0, 0, 0)
        FakeBackground.BackgroundTransparency = 1
        FakeBackground.ZIndex = 9999
        FakeBackground.Parent = container
        table.insert(Obsidian_Active, 1, FakeBackground)

        local Holder = Instance.new("Frame")
        Holder.AutomaticSize = Enum.AutomaticSize.Y
        Holder.BackgroundColor3 = MainColor
        Holder.Size = UDim2.new(1, 0, 0, 0)
        Holder.ZIndex = 10000
        Holder.Parent = FakeBackground
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = Holder
        local stroke = Instance.new("UIStroke")
        stroke.Color = OutlineColor
        stroke.Parent = Holder

        local ContentHolder = Instance.new("Frame")
        ContentHolder.AutomaticSize = Enum.AutomaticSize.Y
        ContentHolder.BackgroundTransparency = 1
        ContentHolder.Size = UDim2.new(1, 0, 0, 0)
        ContentHolder.Parent = Holder
        local cl = Instance.new("UIListLayout")
        cl.Padding = UDim.new(0, 4)
        cl.Parent = ContentHolder
        local pad = Instance.new("UIPadding")
        pad.PaddingBottom = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        pad.PaddingTop = UDim.new(0, 8)
        pad.Parent = ContentHolder

        local ContentWidth = math.max(TitleBounds.X, DescBounds.X)

        local TextContainer = Instance.new("Frame")
        TextContainer.AutomaticSize = Enum.AutomaticSize.Y
        TextContainer.BackgroundTransparency = 1
        TextContainer.Size = UDim2.new(0, ContentWidth, 0, 0)
        TextContainer.Parent = ContentHolder
        local tcl = Instance.new("UIListLayout")
        tcl.Padding = UDim.new(0, 4)
        tcl.Parent = TextContainer

        if Title ~= "" then
            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Size = UDim2.new(0, TitleBounds.X, 0, TitleBounds.Y)
            TitleLbl.Text = Title
            TitleLbl.TextColor3 = FontColor
            TitleLbl.Font = Enum.Font.GothamMedium
            TitleLbl.TextSize = 15
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = TextContainer
        end

        if Desc ~= "" then
            local DescLbl = Instance.new("TextLabel")
            DescLbl.BackgroundTransparency = 1
            DescLbl.Size = UDim2.new(0, DescBounds.X, 0, DescBounds.Y)
            DescLbl.Text = Desc
            DescLbl.TextColor3 = FontColor
            DescLbl.Font = Enum.Font.GothamMedium
            DescLbl.TextSize = 14
            DescLbl.TextXAlignment = Enum.TextXAlignment.Left
            DescLbl.TextWrapped = true
            DescLbl.Parent = TextContainer
        end

        local TimerHolder = Instance.new("Frame")
        TimerHolder.BackgroundTransparency = 1
        TimerHolder.Size = UDim2.new(1, 0, 0, 4)
        TimerHolder.Parent = ContentHolder
        local TimerBar = Instance.new("Frame")
        TimerBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        TimerBar.BorderSizePixel = 0
        TimerBar.Position = UDim2.new(0, 0, 0, 1)
        TimerBar.Size = UDim2.new(1, 0, 0, 2)
        TimerBar.Parent = TimerHolder
        local TimerFill = Instance.new("Frame")
        TimerFill.BackgroundColor3 = AccentColor
        TimerFill.BorderSizePixel = 0
        TimerFill.Size = UDim2.new(1, 0, 1, 0)
        TimerFill.Parent = TimerBar

        local TargetWidth = ContentWidth + 16
        FakeBackground.Size = UDim2.new(0, TargetWidth, 0, 0)

        TweenService:Create(FakeBackground, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -10, 0, 10)
        }):Play()

        task.wait(0.1)
        TweenService:Create(TimerFill, TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
            Size = UDim2.new(0, 0, 1, 0)
        }):Play()

        task.wait(Time)

        TweenService:Create(FakeBackground, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, 20, 0, 10)
        }):Play()
        task.wait(0.4)

        FakeBackground:Destroy()
        local index = table.find(Obsidian_Active, FakeBackground)
        if index then table.remove(Obsidian_Active, index) end

        for _, notif in ipairs(Obsidian_Active) do
            local currY = notif.Position.Y.Offset
            TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -10, 0, currY - NotifHeight - 8)
            }):Play()
        end
    end)
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

    local resolvedImg = resolveImage(opts.Image)
    achievement.Frame.ImageLabel.Image = resolvedImg ~= "" and resolvedImg or "rbxassetid://6023426923"

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
        Notification.ZIndex = 9999
        abyssalSetLogicalY(Notification, 60)

        Line.Name = "Line"
        Line.Parent = Notification
        Line.BackgroundColor3 = accentColor
        Line.BorderSizePixel = 0
        Line.Position = UDim2.new(0, 0, 1, -3)
        Line.Size = UDim2.new(0, 0, 0, 3)
        Line.ZIndex = 10000

        local resolvedImg = resolveImage(opts.Image or "")
        if resolvedImg == "" then resolvedImg = "rbxassetid://3944668821" end

        Warning.Name = "Warning"
        Warning.Parent = Notification
        Warning.BackgroundTransparency = 1
        Warning.Position = UDim2.new(0, 10, 0, 5)
        Warning.Size = UDim2.new(0, 40, 0, 40)
        Warning.Image = resolvedImg
        Warning.ImageColor3 = accentColor
        Warning.ScaleType = Enum.ScaleType.Fit
        Warning.ZIndex = 10000

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
        Title.ZIndex = 10000

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
        Description.ZIndex = 10000

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

    local sg = getMainUiContainer():FindFirstChild("MParadoxUI")
    if not sg then
        sg = Instance.new("Frame")
        sg.Name = "MParadoxUI"
        sg.Size = UDim2.new(1, 0, 1, 0)
        sg.BackgroundTransparency = 1
        sg.Parent = getMainUiContainer()
    end

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
    tmpl.Size = UDim2.new(0.689964, 0, 0.163091, 0)
    tmpl.AnchorPoint = Vector2.new(0.5, 1)
    tmpl.Position = UDim2.new(0.5, 0, 0.82, 0)
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
    glow.Size = UDim2.new(1.5, 0, 2, 0)
    glow.ZIndex = 1999
    glow.Image = "rbxassetid://61997378"
    glow.ImageColor3 = Color3.fromRGB(255, 222, 189)
    glow.ImageTransparency = 0.75
    glow.Parent = tmpl

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
        if obj:FindFirstChildOfClass("UIStroke") then TweenService:Create(obj.UIStroke, ti, { Transparency = data.StrokeTransparency or 0}):Play() end
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
local MP_STACK_Y_STEP       = -0.06
local MP_STACK_TRANSP_STEP  = 0.28
local MP_STACK_MAX          = 3
local MP_CENTER_Y           = 0.5

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

local function mp_promoteStack(removedDepth)
    for _, existing in ipairs(mp.holder:GetChildren()) do
        if existing:GetAttribute("MPAlive") then
            local currentDepth = existing:GetAttribute("MPDepth") or 0
            if currentDepth > removedDepth then
                local newDepth = currentDepth - 1
                mp_applyStackState(existing, newDepth)
            end
        end
    end
end

local function showMParadox(opts)
    local clone = mp.template:Clone()
    clone.Parent = mp.holder
    clone:SetAttribute("MPDepth", 0)
    clone:SetAttribute("MPAlive", true)

    local achievement = clone:WaitForChild("Achievement")
    local glow        = clone:WaitForChild("Glow")

    local resolvedImg = resolveImage(opts.Image or "")
    if resolvedImg == "" then resolvedImg = "rbxassetid://6023426923" end

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
                    for _, d2 in ipairs(ach2:GetDescendants()) do
                        if d2:IsA("TextLabel") then
                            TweenService:Create(d2, ti, { TextTransparency = 1 }):Play()
                        elseif d2:IsA("ImageLabel") then
                            TweenService:Create(d2, ti, { ImageTransparency = 1 }):Play()
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

    achievement.Position = UDim2.new(0.5, 0, 1.5, 0)
    achievement.Size     = UDim2.new(0.7, 0, 0.8, 0)
    glow.Position        = UDim2.new(0.5, 0, 1.5, 0)

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
    TweenService:Create(glow, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
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

    local myDepth = clone:GetAttribute("MPDepth") or 0

    mp_tweenOut(clone)
    for _, obj in ipairs(clone:GetDescendants()) do
        mp_tweenOut(obj)
    end

    task.wait(0.5)
    if clone.Parent then clone:Destroy() end

    mp_promoteStack(myDepth)
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

local function MakeElement(class, ...)
    local obj
    if class == "TFrame" then
        obj = Instance.new("Frame")
        obj.BackgroundTransparency = 1
    elseif class == "RoundFrame" then
        local color, transp, radius = ...
        obj = Instance.new("Frame")
        obj.BackgroundColor3 = color
        obj.BackgroundTransparency = transp
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius)
        corner.Parent = obj
    elseif class == "Image" then
        local img = ...
        obj = Instance.new("ImageLabel")
        obj.Image = img
        obj.BackgroundTransparency = 1
    elseif class == "Label" then
        local text, size = ...
        obj = Instance.new("TextLabel")
        obj.Text = text
        obj.TextSize = size
        obj.BackgroundTransparency = 1
    elseif class == "Stroke" then
        local color, thick = ...
        obj = Instance.new("UIStroke")
        obj.Color = color
        obj.Thickness = thick
    elseif class == "Padding" then
        local p1, p2, p3, p4 = ...
        obj = Instance.new("UIPadding")
        obj.PaddingTop = UDim.new(0, p1)
        obj.PaddingRight = UDim.new(0, p2)
        obj.PaddingBottom = UDim.new(0, p3)
        obj.PaddingLeft = UDim.new(0, p4)
    end
    return obj
end

local function SetProps(obj, props)
    for k, v in pairs(props) do
        pcall(function()
            obj[k] = v
        end)
    end
    return obj
end

local function SetChildren(obj, children)
    for _, child in ipairs(children) do
        child.Parent = obj
    end
    return obj
end

local Orion = getMainUiContainer():FindFirstChild("OrionNotifyHolder")
if not Orion then
    Orion = Instance.new("Frame")
    Orion.Name = "OrionNotifyHolder"
    Orion.Size = UDim2.new(1, 0, 1, 0)
    Orion.BackgroundTransparency = 1
    Orion.Parent = getMainUiContainer()
end

local NotificationHolder = SetProps(MakeElement("TFrame"), {
    Position = UDim2.new(1, -25, 1, -25),
    Size = UDim2.new(0, 300, 1, -25),
    AnchorPoint = Vector2.new(1, 1),
    Parent = Orion
})

local Orion_Active = {}

local function notifyOrion(opts)
    task.spawn(function()
        local NotificationConfig = {
            Name = opts.Title or "Notification",
            Content = opts.Description or "Test",
            Image = opts.Image or "rbxassetid://4384403532",
            Time = opts.Time or 15
        }

        local soundId = resolveSound(opts.Sound, DEFAULT_SOUND)
        playSound(NotificationHolder, soundId, 1)

        local NotificationParent = SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = NotificationHolder
        })

        local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(25, 25, 25), 0, 10), {
            Parent = NotificationParent, 
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 0,
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 9999
        }), {
            SetProps(MakeElement("Stroke", Color3.fromRGB(93, 93, 93), 1.2), {}),
            SetProps(MakeElement("Padding", 12, 12, 12, 12), {}),
            SetProps(MakeElement("Image", NotificationConfig.Image), {
                Size = UDim2.new(0, 20, 0, 20),
                ImageColor3 = Color3.fromRGB(240, 240, 240),
                Name = "Icon",
                ZIndex = 10000
            }),
            SetProps(MakeElement("Label", NotificationConfig.Name, 15), {
                Size = UDim2.new(1, -30, 0, 20),
                Position = UDim2.new(0, 30, 0, 0),
                Font = Enum.Font.GothamBold,
                Name = "Title",
                ZIndex = 10000
            }),
            SetProps(MakeElement("Label", NotificationConfig.Content, 14), {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 25),
                Font = Enum.Font.GothamSemibold,
                Name = "Content",
                AutomaticSize = Enum.AutomaticSize.Y,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextWrapped = true,
                ZIndex = 10000
            })
        })

        task.wait(0.2)
        local notifHeight = NotificationParent.AbsoluteSize.Y
        local holderHeight = NotificationHolder.AbsoluteSize.Y
        local baseYOffset = holderHeight - notifHeight

        for _, notif in ipairs(Orion_Active) do
            local currY = notif.Position.Y.Offset
            TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, currY - notifHeight - 5)
            }):Play()
        end

        table.insert(Orion_Active, 1, NotificationParent)

        NotificationParent.Position = UDim2.new(0, 0, 0, baseYOffset)

        TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()

        task.wait(NotificationConfig.Time - 0.88)
        TweenService:Create(NotificationFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
        TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6}):Play()
        task.wait(0.3)
        if NotificationFrame:FindFirstChild("UIStroke") then
            TweenService:Create(NotificationFrame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.9}):Play()
        end
        TweenService:Create(NotificationFrame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
        TweenService:Create(NotificationFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
        task.wait(0.05)

        NotificationFrame:TweenPosition(UDim2.new(1, 20, 0, 0),'In','Quint',0.8,true)
        task.wait(1.35)
        NotificationFrame:Destroy()
        NotificationParent:Destroy()

        local index = table.find(Orion_Active, NotificationParent)
        if index then table.remove(Orion_Active, index) end

        for _, notif in ipairs(Orion_Active) do
            local currY = notif.Position.Y.Offset
            TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, currY + notifHeight + 5)
            }):Play()
        end
    end)
end

local STX_Active = {}

local function destroySTX(ambientShadow, height)
    local index = table.find(STX_Active, ambientShadow)
    if index then table.remove(STX_Active, index) end

    ambientShadow:TweenSize(UDim2.new(0, 0, 0, 0), "Out", "Linear", 0.2)
    task.wait(0.2)
    ambientShadow:Destroy()

    for _, notif in ipairs(STX_Active) do
        local currYOffset = notif.Position.Y.Offset
        TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(notif.Position.X.Scale, notif.Position.X.Offset, notif.Position.Y.Scale, currYOffset + height + 10)
        }):Play()
    end
end

local function notifySTX(opts)
    local GUI = getMainUiContainer():FindFirstChild("STX_Nofitication")
    if not GUI then
        GUI = Instance.new("Frame")
        GUI.Name = "STX_Nofitication"
        GUI.Size = UDim2.new(1, 0, 1, 0)
        GUI.BackgroundTransparency = 1
        GUI.Parent = getMainUiContainer()
    end

    local nofdebug = { Title = opts.Title or "Notification", Description = opts.Description or "" }
    local middledebug = { Type = string.lower(tostring(opts.Type or "default")), OutlineColor = opts.Color or Color3.fromRGB(93, 93, 93), Time = opts.Time or 5 }
    local all = { Image = opts.Image or "rbxassetid://0", ImageColor = opts.ImageColor or Color3.fromRGB(255, 255, 255), Callback = opts.Callback or function() end }

    local soundId = resolveSound(opts.Sound, DEFAULT_SOUND)
    playSound(GUI, soundId, 1)

    local ambientShadow = Instance.new("ImageLabel")
    local Window = Instance.new("Frame")
    local Outline_A = Instance.new("Frame")
    local WindowTitle = Instance.new("TextLabel")
    local WindowDescription = Instance.new("TextLabel")

    ambientShadow.Name = "ambientShadow"
    ambientShadow.Parent = GUI
    ambientShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    ambientShadow.BackgroundTransparency = 1.000
    ambientShadow.BorderSizePixel = 0
    ambientShadow.Position = UDim2.new(0.91525954, 0, 0.936809778, 0)
    ambientShadow.Size = UDim2.new(0, 0, 0, 0)
    ambientShadow.Image = "rbxassetid://1316045217"
    ambientShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    ambientShadow.ImageTransparency = 0.400
    ambientShadow.ScaleType = Enum.ScaleType.Slice
    ambientShadow.SliceCenter = Rect.new(10, 10, 118, 118)

    Window.Name = "Window"
    Window.Parent = ambientShadow
    Window.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Window.BorderSizePixel = 0
    Window.Position = UDim2.new(0, 5, 0, 5)
    Window.Size = UDim2.new(0, 230, 0, 80)
    Window.ZIndex = 9999

    Outline_A.Name = "Outline_A"
    Outline_A.Parent = Window
    Outline_A.BackgroundColor3 = middledebug.OutlineColor
    Outline_A.BorderSizePixel = 0
    Outline_A.Position = UDim2.new(0, 0, 0, 25)
    Outline_A.Size = UDim2.new(0, 230, 0, 2)
    Outline_A.ZIndex = 10000

    WindowTitle.Name = "WindowTitle"
    WindowTitle.Parent = Window
    WindowTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    WindowTitle.BackgroundTransparency = 1.000
    WindowTitle.BorderColor3 = Color3.fromRGB(27, 42, 53)
    WindowTitle.BorderSizePixel = 0
    WindowTitle.Position = UDim2.new(0, 8, 0, 2)
    WindowTitle.Size = UDim2.new(0, 222, 0, 22)
    WindowTitle.ZIndex = 10001
    WindowTitle.Font = Enum.Font.GothamSemibold
    WindowTitle.Text = nofdebug.Title
    WindowTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
    WindowTitle.TextSize = 12.000
    WindowTitle.TextXAlignment = Enum.TextXAlignment.Left

    WindowDescription.Name = "WindowDescription"
    WindowDescription.Parent = Window
    WindowDescription.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    WindowDescription.BackgroundTransparency = 1.000
    WindowDescription.BorderColor3 = Color3.fromRGB(27, 42, 53)
    WindowDescription.BorderSizePixel = 0
    WindowDescription.Position = UDim2.new(0, 8, 0, 34)
    WindowDescription.Size = UDim2.new(0, 216, 0, 40)
    WindowDescription.ZIndex = 10001
    WindowDescription.Font = Enum.Font.GothamSemibold
    WindowDescription.Text = nofdebug.Description
    WindowDescription.TextColor3 = Color3.fromRGB(180, 180, 180)
    WindowDescription.TextSize = 12.000
    WindowDescription.TextWrapped = true
    WindowDescription.TextXAlignment = Enum.TextXAlignment.Left
    WindowDescription.TextYAlignment = Enum.TextYAlignment.Top

    local height = 90
    if middledebug.Type == "option" then height = 110 end

    for _, notif in ipairs(STX_Active) do
        local currYOffset = notif.Position.Y.Offset
        TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(notif.Position.X.Scale, notif.Position.X.Offset, notif.Position.Y.Scale, currYOffset - height - 10)
        }):Play()
    end

    table.insert(STX_Active, ambientShadow)

    ambientShadow.Position = UDim2.new(0.91525954, 0, 0.936809778, height + 10)

    TweenService:Create(ambientShadow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.91525954, 0, 0.936809778, 0)
    }):Play()

    if middledebug.Type == "default" then
        task.spawn(function()
            ambientShadow:TweenSize(UDim2.new(0, 240, 0, 90), "Out", "Linear", 0.2)
            Window.Size = UDim2.new(0, 230, 0, 80)
            Outline_A:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Linear", middledebug.Time)
            task.wait(middledebug.Time)
            destroySTX(ambientShadow, 90)
        end)
    elseif middledebug.Type == "image" then
        ambientShadow:TweenSize(UDim2.new(0, 240, 0, 90), "Out", "Linear", 0.2)
        Window.Size = UDim2.new(0, 230, 0, 80)
        WindowTitle.Position = UDim2.new(0, 24, 0, 2)
        local ImageButton = Instance.new("ImageButton")
        ImageButton.Parent = Window
        ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ImageButton.BackgroundTransparency = 1.000
        ImageButton.BorderSizePixel = 0
        ImageButton.Position = UDim2.new(0, 4, 0, 4)
        ImageButton.Size = UDim2.new(0, 18, 0, 18)
        ImageButton.ZIndex = 10002
        ImageButton.AutoButtonColor = false
        ImageButton.Image = all.Image
        ImageButton.ImageColor3 = all.ImageColor

        task.spawn(function()
            Outline_A:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Linear", middledebug.Time)
            task.wait(middledebug.Time)
            destroySTX(ambientShadow, 90)
        end)
    elseif middledebug.Type == "option" then
        ambientShadow:TweenSize(UDim2.new(0, 240, 0, 110), "Out", "Linear", 0.2)
        Window.Size = UDim2.new(0, 230, 0, 100)
        local Uncheck = Instance.new("ImageButton")
        local Check = Instance.new("ImageButton")

        Uncheck.Name = "Uncheck"
        Uncheck.Parent = Window
        Uncheck.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Uncheck.BackgroundTransparency = 1.000
        Uncheck.BorderSizePixel = 0
        Uncheck.Position = UDim2.new(0, 7, 0, 76)
        Uncheck.Size = UDim2.new(0, 18, 0, 18)
        Uncheck.ZIndex = 10002
        Uncheck.AutoButtonColor = false
        Uncheck.Image = "http://www.roblox.com/asset/?id=6031094678"
        Uncheck.ImageColor3 = Color3.fromRGB(255, 84, 84)

        Check.Name = "Check"
        Check.Parent = Window
        Check.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Check.BackgroundTransparency = 1.000
        Check.BorderSizePixel = 0
        Check.Position = UDim2.new(0, 28, 0, 76)
        Check.Size = UDim2.new(0, 18, 0, 18)
        Check.ZIndex = 10002
        Check.AutoButtonColor = false
        Check.Image = "http://www.roblox.com/asset/?id=6031094667"
        Check.ImageColor3 = Color3.fromRGB(83, 230, 50)

        task.spawn(function()
            local Stilthere = true
            local function Unchecked()
                pcall(function()
                    all.Callback(false)
                end)
                if not Stilthere then return end
                Stilthere = false
                destroySTX(ambientShadow, 110)
            end
            local function Checked()
                pcall(function()
                    all.Callback(true)
                end)
                if not Stilthere then return end
                Stilthere = false
                destroySTX(ambientShadow, 110)
            end
            Uncheck.MouseButton1Click:Connect(Unchecked)
            Check.MouseButton1Click:Connect(Checked)

            Outline_A:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Linear", middledebug.Time)

            task.wait(middledebug.Time)

            if Stilthere == true then
                destroySTX(ambientShadow, 110)
            end
        end)
    end
end

local STYLES = {
    Library  = notifyLibrary,
    Linoria  = notifyLinoria,
    Obsidian = notifyObsidian,
    Doors    = notifyDoors,
    msdoors  = function(opts)
        initMsdoorsUI()
        table.insert(d.queue, opts)
        processMsdoorsQueue()
    end,
    Paradox  = notifyParadox,
    MParadox = notifyMParadox,
    Roblox   = notifyRoblox,
    Abyssal  = notifyAbyssal,
    Orion    = notifyOrion,
    STX      = notifySTX,
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
        local s = style.NotifyStyle or "Library"
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
