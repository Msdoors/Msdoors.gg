if not _G.msdoors_ then
    _G.msdoors_ = {}
end

local function Notify(options)
    options = options or {}

    if Library and Library.Notify then
        
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://4590656842"
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

local function MsdoorsNotify(title, description, reason, image, color, style, time)
    title = title or "Sem Título"
    description = description or "Sem Descrição"
    reason = reason or ""
    image = image or "rbxassetid://133997875469993"
    color = color or Color3.new(1, 1, 1)
    style = style or "NOTIFICATION"
    time = time or 5

    local mainUI = game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MainUI")
    if not mainUI then
        warn("MainUI não encontrada. Verifique se o jogo DOORS está carregado corretamente.")
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
    achievement.Frame.ImageLabel.Image = image


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

_G.msdoors_.Notify = function(options)
    local notifyStyle = options.NotifyStyle or "Linoria"

    if notifyStyle == "Doors" then
        MsdoorsNotify(
            options.Title, 
            options.Description, 
            options.Reason, 
            options.Image, 
            options.Color, 
            options.Time
        )
    elseif notifyStyle == "Linoria" then
        Notify(options)
    else
        warn("Estilo de notificação inválido: " .. tostring(notifyStyle))
    end
end

return _G.msdoors_.Notify
