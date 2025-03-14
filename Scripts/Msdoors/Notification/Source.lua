if not _G.msdoors_ then
    _G.msdoors_ = {}
end

local Linoria = {}

function Linoria:Notify(options)
    options = options or {}
    local description = options.Description or "Sem mensagem"
    local time = options.Duration or 5
end

function Linoria:Alert(options)
    self:Notify(options)

    local sound = Instance.new("Sound", game:GetService("SoundService")) 
    sound.SoundId = "rbxassetid://4590656842"
    sound.Volume = 0.5
    sound.PlayOnRemove = true
    sound:Destroy()
end

local function MsdoorsNotify(title, description, reason, image, color, time, style)
    title = title or "Sem Título"
    description = description or "Sem Descrição"
    reason = reason or ""
    image = image or "rbxassetid://6023426923"
    color = color or Color3.new(1, 1, 1)
    time = time or 5
    style = style or "NOTIFICATION"

    local mainUI = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainUI", 2.5)
    if not mainUI then
        warn("[ Doors Notification ] » MainUI não encontrada. Verifique se o jogo DOORS está carregado corretamente.")
        return
    end

    local achievement = mainUI.AchievementsHolder.Achievement:Clone()
    achievement.Size = UDim2.new(0, 0, 0, 0)
    achievement.Frame.Position = UDim2.new(1.1, 0, 0, 0)
    achievement.Name = "LiveAchievement"
    achievement.Visible = true

    achievement.Frame.TextLabel.Text = style
    achievement.Frame.Details.Title.Text = title
    achievement.Frame.Details.Desc.Text = description
    achievement.Frame.Details.Reason.Text = reason

    if image:match("rbxthumb://") or image:match("rbxassetid://") then
        achievement.Frame.ImageLabel.Image = image
    else
        achievement.Frame.ImageLabel.Image = "rbxassetid://" .. image
    end

    achievement.Frame.TextLabel.TextColor3 = color
    achievement.Frame.UIStroke.Color = color
    achievement.Frame.Glow.ImageColor3 = color

    achievement.Parent = mainUI.AchievementsHolder
    achievement.Sound.SoundId = "rbxassetid://10469938989"
    achievement.Sound.Volume = 1
    achievement.Sound:Play()

    task.spawn(function()
        achievement:TweenSize(UDim2.new(1, 0, 0.2, 0), "In", "Quad", 0.8, true)

        task.wait(0.8)

        achievement.Frame:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quad", 0.5, true)

        game:GetService("TweenService"):Create(achievement.Frame.Glow, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            ImageTransparency = 1
        }):Play()

        task.wait(time)

        achievement.Frame:TweenPosition(UDim2.new(1.1, 0, 0, 0), "In", "Quad", 0.5, true)
        task.wait(0.5)
        achievement:TweenSize(UDim2.new(1, 0, -0.1, 0), "InOut", "Quad", 0.5, true)
        task.wait(0.5)
        achievement:Destroy()
    end)
end

local function Notify(options)
    options = options or {}

    local title = options.Title or "Sem Título"
    local description = options.Description or "Sem Descrição"
    local reason = options.Reason or ""
    local color = options.Color or Color3.new(1, 1, 1)
    local style = options.Style or "NOTIFICATION"
    local duration = options.Duration or 5
    local notifyStyle = options.NotifyStyle or "Linoria"
    local image = options.Image or "rbxassetid://133997875469993"

    if notifyStyle == "Linoria" then
        Linoria:Notify({
            Description = description,
            Duration = duration,
            Title = title,
            Color = color
        })
    local sound = Instance.new("Sound", game:GetService("SoundService")) 
    sound.SoundId = "rbxassetid://4590662766"
    sound.Volume = 0.5
    sound.PlayOnRemove = true
    sound:Destroy()
    elseif notifyStyle == "Doors" then
        MsdoorsNotify(
            title,
            description,
            reason,
            image,
            color,
            duration,
            style
        )
    else
        warn("Estilo de notificação inválido: " .. tostring(notifyStyle))
    end
end

local function Alert(options)
    options = options or {}

    options.Style = options.Style or "ALERT"
    if not options.Color then
        options.Color = Color3.fromRGB(255, 0, 0)
    end

    local notifyStyle = options.NotifyStyle or "Linoria"

    if notifyStyle == "Linoria" then
        Linoria:Alert(options)
    else
        Notify(options)
    end
end

_G.msdoors_.Notify = Notify
_G.msdoors_.Alert = Alert
_G.msdoors_.Linoria = Linoria
_G.msdoors_.MsdoorsNotify = MsdoorsNotify

_G.msdoors_.SetDefaultStyle = function(style)
    if style == "Linoria" or style == "Doors" then
        _G.msdoors_.DefaultStyle = style
    else
        warn("Estilo de notificação inválido: " .. tostring(style))
    end
end
local function CreateNotifier(defaultOptions)
    defaultOptions = defaultOptions or {}

    local notifier = {}

    function notifier:Notify(options)
        options = options or {}
        for key, value in pairs(defaultOptions) do
            if options[key] == nil then
                options[key] = value
            end
        end
        return Notify(options)
    end

    function notifier:Alert(options)
        options = options or {}
        for key, value in pairs(defaultOptions) do
            if options[key] == nil then
                options[key] = value
            end
        end
        return Alert(options)
    end

    return notifier
end

_G.msdoors_.CreateNotifier = CreateNotifier

return Notify
