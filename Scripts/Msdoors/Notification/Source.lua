if not shared.notifyap then
    shared.notifyap = {}
end

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local DEFAULT_SOUND = "rbxassetid://4590657391"
local DOORS_SOUND = "rbxassetid://10469938989"
local MSDOORS_SOUND_URL = "https://github.com/Msdoors/Msdoors.gg/raw/refs/heads/main/Scripts/Msdoors/Notification/DOORS-ACHIEVIMENT.mp3"
local MSDOORS_SOUND_PATH = "msdoors/DOORS-ACHIEVEMENT.mp3"

shared.ACHIDATA = shared.ACHIDATA or {template = nil, gui = nil, queue = {}, processing = false, defaultSound = nil}
local d = shared.ACHIDATA

local function InitMsdoorsSound()
    if d.defaultSound then return d.defaultSound end
    
    if not isfolder("msdoors") then
        makefolder("msdoors")
    end
    
    if isfile(MSDOORS_SOUND_PATH) then
        local assetFunc = getcustomasset or getsynasset
        d.defaultSound = assetFunc(MSDOORS_SOUND_PATH)
        return d.defaultSound
    end
    
    task.spawn(function()
        local success, audioData = pcall(function()
            return game:HttpGet(MSDOORS_SOUND_URL)
        end)
        
        if success then
            writefile(MSDOORS_SOUND_PATH, audioData)
            local assetFunc = getcustomasset or getsynasset
            d.defaultSound = assetFunc(MSDOORS_SOUND_PATH)
        else
            warn("Falha ao baixar som padrão do msdoors")
            d.defaultSound = "rbxassetid://10469938989"
        end
    end)
    
    return "rbxassetid://10469938989"
end

local function ProcessSoundParameter(soundpar)
    if not soundpar or soundpar == "" then
        return InitMsdoorsSound()
    end
    
    if soundpar:match("^rbxassetid://") or soundpar:match("^%d+$") then
        if soundpar:match("^%d+$") then
            return "rbxassetid://" .. soundpar
        end
        return soundpar
    end
    
    if soundpar:match("^https?://") then
        task.spawn(function()
            local tempPath = "msdoors/temp_sound_" .. tick() .. ".mp3"
            local success, audioData = pcall(function()
                return game:HttpGet(soundpar)
            end)
            
            if success then
                writefile(tempPath, audioData)
            else
                warn("Falha ao baixar som do link: " .. soundpar)
            end
        end)
    end
    
    return InitMsdoorsSound()
end

local function initMsdoorsUI()
    if not d.gui then
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
    end

    if not d.template then
        local a = Instance.new("Frame")
        a.Name = "Achi"
        a.Size = UDim2.new(0.28, 0, 0.11, 0)
        a.Position = UDim2.new(1.2, 0, 0, 0)
        a.AnchorPoint = Vector2.new(1, 0)
        a.BackgroundTransparency = 1
        a.ZIndex = 2000
        a.Visible = true
        
        local snd = Instance.new("Sound")
        snd.Name = "Snd"
        snd.SoundId = InitMsdoorsSound()
        snd.Volume = 0.575
        snd.Parent = a
        
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
        
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0.38, 0)
        title.BackgroundTransparency = 1
        title.TextColor3 = Color3.fromRGB(255, 222, 189)
        title.TextWrapped = true
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 20
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextYAlignment = Enum.TextYAlignment.Top
        title.ZIndex = 2001
        title.LayoutOrder = 1
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.Parent = det
        
        local tp = Instance.new("UIPadding")
        tp.PaddingLeft = UDim.new(0, 5)
        tp.PaddingTop = UDim.new(0, 3)
        tp.Parent = title
        
        local desc = Instance.new("TextLabel")
        desc.Name = "Desc"
        desc.Size = UDim2.new(1, 0, 0.28, 0)
        desc.BackgroundTransparency = 1
        desc.TextColor3 = Color3.fromRGB(221, 180, 151)
        desc.TextWrapped = true
        desc.Font = Enum.Font.GothamMedium
        desc.TextSize = 14
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top
        desc.ZIndex = 2001
        desc.LayoutOrder = 2
        desc.TextTruncate = Enum.TextTruncate.AtEnd
        desc.Parent = det
        
        local dp = Instance.new("UIPadding")
        dp.PaddingLeft = UDim.new(0, 5)
        dp.Parent = desc
        
        local reason = Instance.new("TextLabel")
        reason.Name = "Reason"
        reason.Size = UDim2.new(1, 0, 0.28, 0)
        reason.BackgroundTransparency = 1
        reason.TextColor3 = Color3.fromRGB(200, 165, 140)
        reason.TextWrapped = true
        reason.Font = Enum.Font.Gotham
        reason.TextSize = 13
        reason.TextXAlignment = Enum.TextXAlignment.Left
        reason.TextYAlignment = Enum.TextYAlignment.Top
        reason.ZIndex = 2001
        reason.LayoutOrder = 3
        reason.TextTruncate = Enum.TextTruncate.AtEnd
        reason.Parent = det
        
        local rp = Instance.new("UIPadding")
        rp.PaddingLeft = UDim.new(0, 5)
        rp.Parent = reason
        
        d.template = a
    end
end

local function showMsdoors(opts)
    opts = opts or {}
    local achi = d.template:Clone()
    achi.Parent = d.gui
    achi.LayoutOrder = tick()
    
    achi.F.Top.Text = opts.Style or "UNLOCKED ACHIEVEMENT"
    achi.F.Det.Title.Text = opts.Title or "Achievement"
    achi.F.Det.Desc.Text = opts.Description or ""
    achi.F.Det.Reason.Text = opts.Reason or ""
    achi.F.Img.Image = opts.Image or "rbxassetid://6023426923"
    
    local col = opts.Color or Color3.fromRGB(255, 222, 189)
    achi.F.Top.TextColor3 = col
    achi.F.UIStroke.Color = col
    achi.Glow.ImageColor3 = col
    
    if opts.soundpar then
        achi.Snd.SoundId = ProcessSoundParameter(opts.soundpar)
    end
    
    task.spawn(function()
        task.wait(0.1)
        achi.Snd:Play()
    end)
    
    achi.F:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Sine", 0.8, true)
    
    TweenService:Create(achi.Glow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        ImageTransparency = 1
    }):Play()
    
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

local function Notify(options)
    options = options or {}

    if Library and Library.Notify then
        local sound = Instance.new("Sound")
        sound.SoundId = options.Sound or DEFAULT_SOUND
        sound.Parent = game.Workspace
        sound.Volume = 1
        sound:Play()
        
        Library:Notify({
            Title = options.Title or "Sem Título",
            Description = options.Description or "Sem Descrição",
            Time = options.Time or 5
        })
    else
        warn("Library não encontrada. Verifique se está carregada corretamente.")
    end
end

local function MsdoorsNotify(title, description, reason, image, color, style, time, sound)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local uiContainer = playerGui:FindFirstChild("GlobalUI") or playerGui:FindFirstChild("MainUI")
    
    if not uiContainer then
        warn("GlobalUI ou MainUI não encontradas. Verifique se o jogo DOORS está carregado corretamente.")
        return
    end

    local achievementsHolder = uiContainer:FindFirstChild("AchievementsHolder")
    if not achievementsHolder then
        warn("AchievementsHolder não encontrado.")
        return
    end

    local achievement = achievementsHolder.Achievement:Clone()
    achievement.Size = UDim2.new(0, 0, 0, 0)
    achievement.Frame.Position = UDim2.new(1.1, 0, 0, 0)
    achievement.Name = "LiveAchievement"
    achievement.Visible = true

    achievement.Frame.TextLabel.Text = style or "NOTIFICATION"
    achievement.Frame.Details.Title.Text = title or "Sem Título"
    achievement.Frame.Details.Desc.Text = description or "Sem Descrição"
    achievement.Frame.Details.Reason.Text = reason or ""
    achievement.Frame.ImageLabel.Image = image or "rbxassetid://6023426923"

    local notificationColor = color or Color3.new(1, 1, 1)
    achievement.Frame.TextLabel.TextColor3 = notificationColor
    achievement.Frame.UIStroke.Color = notificationColor
    achievement.Frame.Glow.ImageColor3 = notificationColor

    achievement.Parent = achievementsHolder
    achievement.Sound.SoundId = "rbxassetid://10469938989"
    achievement.Sound.Volume = 1
    achievement.Sound:Play()

    task.spawn(function()
        achievement:TweenSize(UDim2.new(1, 0, 0.2, 0), "In", "Quad", 0.8, true)
        task.wait(0.8)
        
        achievement.Frame:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quad", 0.5, true)
        TweenService:Create(achievement.Frame.Glow, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            ImageTransparency = 1
        }):Play()
        
        task.wait(time or 5)
        
        achievement.Frame:TweenPosition(UDim2.new(1.1, 0, 0, 0), "In", "Quad", 0.5, true)
        task.wait(0.5)
        achievement:TweenSize(UDim2.new(1, 0, -0.1, 0), "InOut", "Quad", 0.5, true)
        task.wait(0.5)
        achievement:Destroy()
    end)
end

shared.notifyap.Notify = function(options)
    options = options or {}
    local notifyStyle = options.NotifyStyle or "Linoria"

    if notifyStyle == "Doors" then
        MsdoorsNotify(
            options.Title, 
            options.Description, 
            options.Reason, 
            options.Image, 
            options.Color, 
            options.Style,
            options.Time,
            options.Sound
        )
    elseif notifyStyle == "Linoria" then
        Notify(options)
    elseif notifyStyle == "msdoors" then
        initMsdoorsUI()
        table.insert(d.queue, options)
        processMsdoorsQueue()
    else
        warn("Estilo de notificação inválido: " .. tostring(notifyStyle))
    end
end

return shared.notifyap.Notify