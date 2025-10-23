if not shared.notifyap then
    shared.notifyap = {}
end

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local DEFAULT_SOUND = "rbxassetid://4590657391"
local DOORS_SOUND = "rbxassetid://10469938989"

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
    local globalUI = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("GlobalUI")
    if not globalUI then
        warn("GlobalUI não encontrada. Verifique se o jogo DOORS está carregado corretamente.")
        return
    end

    local achievementsHolder = globalUI:FindFirstChild("AchievementsHolder")
    if not achievementsHolder then
        warn("AchievementsHolder não encontrado dentro de GlobalUI.")
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
    achievement.Frame.ImageLabel.Image = image or "4590657391"

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
    else
        warn("Estilo de notificação inválido: " .. tostring(notifyStyle))
    end
end

return shared.notifyap.Notify
