local getgenv = getgenv or function()
    return shared
end

local Library
repeat
    Library = getgenv().Library
    if not Library then task.wait() end
until Library

if not Library.ScreenGui then return end

local TweenService  = game:GetService("TweenService")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CachePath   = "msdoors/.cache/"
local SeenFile    = CachePath .. "mothers2025.txt"
local ThemeFile   = CachePath .. "mothers_theme.txt"

local LocalizationService = game:GetService("LocalizationService")

local isBrazilian = false
pcall(function()
    local region = LocalizationService.RobloxLocaleId or ""
    isBrazilian = region:lower():find("pt") ~= nil
end)
if not isBrazilian then
    pcall(function()
        local country = LocalizationService:GetCountryRegionForPlayerAsync(
            game:GetService("Players").LocalPlayer
        )
        isBrazilian = country == "BR"
    end)
end

local TITLE_TEXT    = isBrazilian and "💗  Feliz Dia das Mães  💗" or "💗  Happy Mother's Day  💗"
local COPY_TEXT     = isBrazilian and "Copiar mensagem" or "Copy message"
local CONTINUE_TEXT = isBrazilian and "Continuar para o msdoors" or "Continue to msdoors"
local NOTIFY_COPIED = isBrazilian and "Mensagem copiada!" or "Message copied!"
local SCROLL_HINT   = isBrazilian and "↕ arraste para ler" or "↕ drag to read"

local MothersText = isBrazilian and
[[Mãe,

Existem palavras que o mundo inteiro conhece,
mas nenhuma carrega tanto peso quanto essa:
mãe.

Não há abraço que aqueça mais do que o seu.
Não há voz que acalme mais do que a sua.
Não há amor que resista tanto quanto o amor
que você entrega todos os dias, sem pedir
nada em troca.

Você esteve presente nos momentos mais
simples e nos mais difíceis. Nos dias em que
tudo deu certo e também naqueles em que
nada parecia fazer sentido. E mesmo assim,
você ficou. Sempre.

Ser mãe não é uma tarefa — é uma escolha
que se renova a cada amanhecer, com
paciência, com força e com um amor que
não cabe em nenhuma definição.

Hoje e sempre, obrigado por tudo o que você
é. Pelo colo, pela escuta, pelo cuidado que
aparece até nos menores detalhes.

Feliz Dia das Mães. 🌸
Você merece todo o amor do mundo.

  — com carinho, msdoors 💗]]
or
[["Mother" is just a word
until you meet someone
who fills it with everything.

No textbook defines what you do.
No title captures what you are.
You show up — quietly, completely —
in the moments that matter most
and in the ones no one else notices.

You've held things together
when everything else fell apart.
You've believed in people
before they believed in themselves.
You've given your time, your patience,
your presence — over and over —
without ever asking for anything in return.

Today is just one day.
But the love you give lives in every day,
in the habits, the warmth, the safety
you've built around the ones you love.

To every mother, everywhere —
thank you for being exactly who you are.

Happy Mother's Day. 🌸
You deserve the whole world.

  — with love, msdoors 💗]]

local MainFrame = Library.ScreenGui:FindFirstChild("Main")
if not MainFrame then
    MainFrame = Library.ScreenGui:WaitForChild("Main", 10)
    if not MainFrame then return end
end

local BaseZIndex   = (MainFrame.ZIndex or 1) + 10
local CornerRadius = Library.CornerRadius or 8

local ROSE         = Color3.fromRGB(255, 182, 193)
local ROSE_DEEP    = Color3.fromRGB(219, 112, 147)
local ROSE_DARK    = Color3.fromRGB(180,  60, 100)
local ROSE_GLOW    = Color3.fromRGB(255, 100, 150)
local PETAL_1      = Color3.fromRGB(255, 160, 180)
local PETAL_2      = Color3.fromRGB(255, 200, 215)
local PETAL_3      = Color3.fromRGB(255, 130, 160)
local LEAF         = Color3.fromRGB(120, 200, 120)
local GOLD         = Color3.fromRGB(255, 215, 160)
local SHIMMER      = Color3.fromRGB(255, 240, 248)

local fastTween  = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local bounceTween = TweenInfo.new(0.5,  Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local smoothTween = TweenInfo.new(0.35, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local pulseIn    = TweenInfo.new(0.8,  Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut, -1, true)

local function EnsureCache()
    pcall(function()
        if not isfolder or not makefolder then return end
        if not isfolder("msdoors") then makefolder("msdoors") end
        if not isfolder(CachePath) then makefolder(CachePath) end
    end)
end

local function AlreadySeen()
    local ok, res = pcall(function()
        if not isfile then return false end
        if not isfile(SeenFile) then return false end
        return readfile(SeenFile) == "true"
    end)
    return ok and res
end

local function MarkSeen()
    pcall(function()
        EnsureCache()
        if writefile then writefile(SeenFile, "true") end
    end)
end

local function AlreadyThemed()
    local ok, res = pcall(function()
        if not isfile then return false end
        if not isfile(ThemeFile) then return false end
        return readfile(ThemeFile) == "true"
    end)
    return ok and res
end

local function MarkThemed()
    pcall(function()
        EnsureCache()
        if writefile then writefile(ThemeFile, "true") end
    end)
end

local function ApplyMothersTheme()
    Library.Scheme.AccentColor     = ROSE_DEEP
    Library.Scheme.BackgroundColor = Color3.fromRGB(22, 10, 16)
    Library.Scheme.MainColor       = Color3.fromRGB(45, 18, 30)
    Library.Scheme.OutlineColor    = Color3.fromRGB(120, 50, 80)
    Library.Scheme.FontColor       = Color3.fromRGB(255, 220, 230)
    Library:UpdateColorsUsingRegistry()
end

if AlreadyThemed() then
    ApplyMothersTheme()
end

if AlreadySeen() then
    return
end

local petals    = {}
local petalConn = nil

local function MakePetal(parent, z)
    local size   = math.random(5, 16)
    local startX = math.random(0, 100) / 100
    local dur    = math.random(4, 10)
    local drift  = math.random(-60, 60)
    local rot    = math.random(0, 360)
    local spin   = math.random(-180, 180)
    local cols   = {PETAL_1, PETAL_2, PETAL_3, ROSE}
    local col    = cols[math.random(1, #cols)]
    local shapes = {
        UDim2.fromOffset(size, size * 0.55),
        UDim2.fromOffset(size * 0.7, size * 0.7),
        UDim2.fromOffset(size, size * 0.4),
    }
    local shape = shapes[math.random(1, #shapes)]

    local petal = Instance.new("Frame")
    petal.BackgroundColor3        = col
    petal.BorderSizePixel         = 0
    petal.Size                    = shape
    petal.Position                = UDim2.new(startX, 0, 0, -size - 5)
    petal.BackgroundTransparency  = math.random(5, 35) / 100
    petal.Rotation                = rot
    petal.ZIndex                  = z
    petal.Parent                  = parent

    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(1, 0)
    uic.Parent = petal

    table.insert(petals, petal)

    local tw = TweenService:Create(petal, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
        Position = UDim2.new(startX, drift, 1, size + 20),
        Rotation = rot + spin,
        BackgroundTransparency = 0.85,
    })
    tw:Play()
    tw.Completed:Connect(function()
        local idx = table.find(petals, petal)
        if idx then table.remove(petals, idx) end
        if petal and petal.Parent then petal:Destroy() end
    end)
end

local function StopPetals()
    if petalConn then petalConn:Disconnect(); petalConn = nil end
    for i = #petals, 1, -1 do
        local p = petals[i]
        if p and p.Parent then p:Destroy() end
        table.remove(petals, i)
    end
end

local function StartPetals(parent, z)
    local last = 0
    petalConn = RunService.Heartbeat:Connect(function()
        if Library.Unloaded then
            if petalConn then petalConn:Disconnect(); petalConn = nil end
            return
        end
        local now = tick()
        if now - last >= 0.28 then
            last = now
            pcall(MakePetal, parent, z)
        end
    end)
end

local function DrawRose(parent, cx, cy, z, scale)
    scale = scale or 1
    local function Petal(ox, oy, rot, col, w, h)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = col
        f.BorderSizePixel  = 0
        f.Size             = UDim2.fromOffset(w * scale, h * scale)
        f.AnchorPoint      = Vector2.new(0.5, 0.5)
        f.Position         = UDim2.fromOffset(cx + ox * scale, cy + oy * scale)
        f.Rotation         = rot
        f.ZIndex           = z
        f.Parent           = parent
        local uic = Instance.new("UICorner")
        uic.CornerRadius = UDim.new(1, 0)
        uic.Parent = f
        return f
    end

    Petal(0,   -14, 0,    ROSE,    20, 13)
    Petal(12,  -7,  40,   PETAL_1, 19, 12)
    Petal(-12, -7,  -40,  PETAL_1, 19, 12)
    Petal(13,  5,   70,   ROSE,    20, 13)
    Petal(-13, 5,   -70,  ROSE,    20, 13)
    Petal(0,   10,  0,    PETAL_2, 18, 11)
    Petal(7,   -2,  20,   PETAL_3, 14, 9)
    Petal(-7,  -2,  -20,  PETAL_3, 14, 9)

    local center = Instance.new("Frame")
    center.BackgroundColor3 = ROSE_DARK
    center.BorderSizePixel  = 0
    center.Size             = UDim2.fromOffset(12 * scale, 12 * scale)
    center.AnchorPoint      = Vector2.new(0.5, 0.5)
    center.Position         = UDim2.fromOffset(cx, cy - 4 * scale)
    center.ZIndex           = z + 1
    center.Parent           = parent
    local uicC = Instance.new("UICorner"); uicC.CornerRadius = UDim.new(1, 0); uicC.Parent = center

    local glow = Instance.new("Frame")
    glow.BackgroundColor3       = ROSE_GLOW
    glow.BackgroundTransparency = 0.6
    glow.BorderSizePixel        = 0
    glow.Size                   = UDim2.fromOffset(26 * scale, 26 * scale)
    glow.AnchorPoint            = Vector2.new(0.5, 0.5)
    glow.Position               = UDim2.fromOffset(cx, cy - 4 * scale)
    glow.ZIndex                 = z - 1
    glow.Parent                 = parent
    local uicG = Instance.new("UICorner"); uicG.CornerRadius = UDim.new(1, 0); uicG.Parent = glow

    TweenService:Create(glow, pulseIn, {BackgroundTransparency = 0.85}):Play()

    local stem = Instance.new("Frame")
    stem.BackgroundColor3 = LEAF
    stem.BorderSizePixel  = 0
    stem.Size             = UDim2.fromOffset(3 * scale, 22 * scale)
    stem.AnchorPoint      = Vector2.new(0.5, 0)
    stem.Position         = UDim2.fromOffset(cx, cy + 7 * scale)
    stem.ZIndex           = z - 1
    stem.Parent           = parent

    local leaf = Instance.new("Frame")
    leaf.BackgroundColor3 = LEAF
    leaf.BorderSizePixel  = 0
    leaf.Size             = UDim2.fromOffset(12 * scale, 7 * scale)
    leaf.AnchorPoint      = Vector2.new(0, 0.5)
    leaf.Position         = UDim2.fromOffset(cx + 2 * scale, cy + 16 * scale)
    leaf.Rotation         = 30
    leaf.ZIndex           = z - 1
    leaf.Parent           = parent
    local uicL = Instance.new("UICorner"); uicL.CornerRadius = UDim.new(1, 0); uicL.Parent = leaf

    local leaf2 = Instance.new("Frame")
    leaf2.BackgroundColor3 = LEAF
    leaf2.BorderSizePixel  = 0
    leaf2.Size             = UDim2.fromOffset(10 * scale, 6 * scale)
    leaf2.AnchorPoint      = Vector2.new(1, 0.5)
    leaf2.Position         = UDim2.fromOffset(cx - 2 * scale, cy + 22 * scale)
    leaf2.Rotation         = -30
    leaf2.ZIndex           = z - 1
    leaf2.Parent           = parent
    local uicL2 = Instance.new("UICorner"); uicL2.CornerRadius = UDim.new(1, 0); uicL2.Parent = leaf2
end

local function DrawHeart(parent, cx, cy, size, col, z, alpha)
    alpha = alpha or 0
    local half = size / 2
    local lobe = Instance.new("Frame")
    lobe.BackgroundColor3        = col
    lobe.BackgroundTransparency  = alpha
    lobe.BorderSizePixel         = 0
    lobe.Size                    = UDim2.fromOffset(half + 2, half + 2)
    lobe.AnchorPoint             = Vector2.new(1, 0.5)
    lobe.Position                = UDim2.fromOffset(cx, cy - half / 4)
    lobe.ZIndex                  = z
    lobe.Parent                  = parent
    local u1 = Instance.new("UICorner"); u1.CornerRadius = UDim.new(1, 0); u1.Parent = lobe

    local lobe2 = Instance.new("Frame")
    lobe2.BackgroundColor3       = col
    lobe2.BackgroundTransparency = alpha
    lobe2.BorderSizePixel        = 0
    lobe2.Size                   = UDim2.fromOffset(half + 2, half + 2)
    lobe2.AnchorPoint            = Vector2.new(0, 0.5)
    lobe2.Position               = UDim2.fromOffset(cx, cy - half / 4)
    lobe2.ZIndex                 = z
    lobe2.Parent                 = parent
    local u2 = Instance.new("UICorner"); u2.CornerRadius = UDim.new(1, 0); u2.Parent = lobe2

    local tri = Instance.new("Frame")
    tri.BackgroundColor3         = col
    tri.BackgroundTransparency   = alpha
    tri.BorderSizePixel          = 0
    tri.Size                     = UDim2.fromOffset(size, size * 0.7)
    tri.AnchorPoint              = Vector2.new(0.5, 0)
    tri.Position                 = UDim2.fromOffset(cx, cy - half / 4)
    tri.ZIndex                   = z
    tri.Parent                   = parent
end

local function MakeShimmerLine(parent, y, z)
    local line = Instance.new("Frame")
    line.BackgroundColor3       = SHIMMER
    line.BackgroundTransparency = 0.88
    line.BorderSizePixel        = 0
    line.Size                   = UDim2.new(0, 0, 0, 1)
    line.Position               = UDim2.new(0, 0, 0, y)
    line.ZIndex                 = z
    line.Parent                 = parent
    TweenService:Create(line, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1, true), {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundTransparency = 0.96,
    }):Play()
end

local Overlay = Instance.new("Frame")
Overlay.Name                  = "MothersOverlay"
Overlay.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 1
Overlay.Size                  = UDim2.fromScale(1, 1)
Overlay.ZIndex                = BaseZIndex
Overlay.Parent                = MainFrame

local uicOv = Instance.new("UICorner")
uicOv.CornerRadius = UDim.new(0, CornerRadius - 1)
uicOv.Parent = Overlay

local libraryTint = Instance.new("Frame")
libraryTint.Name                  = "LibraryTint"
libraryTint.BackgroundColor3      = Color3.fromRGB(60, 5, 25)
libraryTint.BackgroundTransparency = 1
libraryTint.Size                  = UDim2.fromScale(1, 1)
libraryTint.ZIndex                = BaseZIndex - 1
libraryTint.Parent                = MainFrame

local uicTint = Instance.new("UICorner")
uicTint.CornerRadius = UDim.new(0, CornerRadius - 1)
uicTint.Parent = libraryTint

local PetalContainer = Instance.new("Frame")
PetalContainer.Name                  = "PetalContainer"
PetalContainer.BackgroundTransparency = 1
PetalContainer.Size                  = UDim2.fromScale(1, 1)
PetalContainer.ZIndex                = BaseZIndex + 1
PetalContainer.ClipsDescendants      = true
PetalContainer.Parent                = MainFrame

local OuterGlow = Instance.new("Frame")
OuterGlow.Name                  = "MothersOuterGlow"
OuterGlow.AnchorPoint           = Vector2.new(0.5, 0.5)
OuterGlow.BackgroundColor3      = ROSE_DARK
OuterGlow.BackgroundTransparency = 0.82
OuterGlow.Position              = UDim2.fromScale(0.5, 0.5)
OuterGlow.Size                  = UDim2.fromOffset(0, 0)
OuterGlow.ZIndex                = BaseZIndex + 2
OuterGlow.Parent                = Overlay

local uicOutG = Instance.new("UICorner")
uicOutG.CornerRadius = UDim.new(0, CornerRadius + 6)
uicOutG.Parent = OuterGlow

local OuterBorder = Instance.new("Frame")
OuterBorder.Name             = "MothersOuter"
OuterBorder.AnchorPoint      = Vector2.new(0.5, 0.5)
OuterBorder.BackgroundColor3 = ROSE_GLOW
OuterBorder.Position         = UDim2.fromScale(0.5, 0.5)
OuterBorder.Size             = UDim2.fromOffset(0, 0)
OuterBorder.ZIndex           = BaseZIndex + 2
OuterBorder.Parent           = Overlay

local uicOut = Instance.new("UICorner")
uicOut.CornerRadius = UDim.new(0, CornerRadius + 4)
uicOut.Parent = OuterBorder

TweenService:Create(OuterBorder, pulseIn, {BackgroundColor3 = ROSE_DARK}):Play()

local InnerBorder = Instance.new("Frame")
InnerBorder.Name             = "MothersInner"
InnerBorder.AnchorPoint      = Vector2.new(0.5, 0.5)
InnerBorder.BackgroundColor3 = ROSE_DARK
InnerBorder.Position         = UDim2.fromScale(0.5, 0.5)
InnerBorder.Size             = UDim2.fromOffset(438, 418)
InnerBorder.ZIndex           = BaseZIndex + 3
InnerBorder.Parent           = OuterBorder

local uicIn = Instance.new("UICorner")
uicIn.CornerRadius = UDim.new(0, CornerRadius + 2)
uicIn.Parent = InnerBorder

local Card = Instance.new("Frame")
Card.Name             = "MothersCard"
Card.AnchorPoint      = Vector2.new(0.5, 0.5)
Card.BackgroundColor3 = Color3.fromRGB(20, 8, 14)
Card.Position         = UDim2.fromScale(0.5, 0.5)
Card.Size             = UDim2.fromOffset(436, 416)
Card.ZIndex           = BaseZIndex + 4
Card.Parent           = InnerBorder

local uicCard = Instance.new("UICorner")
uicCard.CornerRadius = UDim.new(0, CornerRadius)
uicCard.Parent = Card

local CardGrad = Instance.new("UIGradient")
CardGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(35, 12, 22)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20,  8, 14)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(28, 10, 18)),
})
CardGrad.Rotation = 135
CardGrad.Parent = Card

MakeShimmerLine(Card, 80,  BaseZIndex + 4)
MakeShimmerLine(Card, 200, BaseZIndex + 4)
MakeShimmerLine(Card, 340, BaseZIndex + 4)

local AccentBar = Instance.new("Frame")
AccentBar.BackgroundColor3 = ROSE_GLOW
AccentBar.BorderSizePixel  = 0
AccentBar.Size             = UDim2.new(1, 0, 0, 3)
AccentBar.ZIndex           = BaseZIndex + 5
AccentBar.Parent           = Card

local uicBar = Instance.new("UICorner")
uicBar.CornerRadius = UDim.new(0, CornerRadius)
uicBar.Parent = AccentBar

TweenService:Create(AccentBar, pulseIn, {BackgroundColor3 = ROSE_DEEP}):Play()

local AccentBarBot = Instance.new("Frame")
AccentBarBot.BackgroundColor3   = ROSE_GLOW
AccentBarBot.BorderSizePixel    = 0
AccentBarBot.AnchorPoint        = Vector2.new(0, 1)
AccentBarBot.Size               = UDim2.new(1, 0, 0, 3)
AccentBarBot.Position           = UDim2.fromScale(0, 1)
AccentBarBot.ZIndex             = BaseZIndex + 5
AccentBarBot.Parent             = Card

local uicBarB = Instance.new("UICorner")
uicBarB.CornerRadius = UDim.new(0, CornerRadius)
uicBarB.Parent = AccentBarBot

TweenService:Create(AccentBarBot, pulseIn, {BackgroundColor3 = ROSE_DEEP}):Play()

local EmojiLabel = Instance.new("TextLabel")
EmojiLabel.BackgroundTransparency = 1
EmojiLabel.Size                   = UDim2.new(1, -80, 0, 40)
EmojiLabel.Position               = UDim2.new(0, 40, 0, 0)
EmojiLabel.Text                   = TITLE_TEXT
EmojiLabel.TextColor3             = ROSE
EmojiLabel.TextSize               = 18
EmojiLabel.FontFace               = Library.Scheme.Font
EmojiLabel.ZIndex                 = BaseZIndex + 6
EmojiLabel.Parent                 = Card

local RoseLeft = Instance.new("Frame")
RoseLeft.BackgroundTransparency = 1
RoseLeft.Size                   = UDim2.fromOffset(36, 48)
RoseLeft.Position               = UDim2.fromOffset(2, 0)
RoseLeft.ZIndex                 = BaseZIndex + 6
RoseLeft.Parent                 = Card
DrawRose(RoseLeft, 18, 24, BaseZIndex + 6, 0.7)

local RoseRight = Instance.new("Frame")
RoseRight.BackgroundTransparency = 1
RoseRight.Size                   = UDim2.fromOffset(36, 48)
RoseRight.Position               = UDim2.new(1, -38, 0, 0)
RoseRight.ZIndex                 = BaseZIndex + 6
RoseRight.Parent                 = Card
DrawRose(RoseRight, 18, 24, BaseZIndex + 6, 0.7)

local ScrollArea = Instance.new("Frame")
ScrollArea.Name                  = "ScrollArea"
ScrollArea.BackgroundTransparency = 1
ScrollArea.Position              = UDim2.new(0, 52, 0, 44)
ScrollArea.Size                  = UDim2.new(1, -104, 1, -92)
ScrollArea.ZIndex                = BaseZIndex + 5
ScrollArea.ClipsDescendants      = true
ScrollArea.Parent                = Card

local ScrollBg = Instance.new("Frame")
ScrollBg.BackgroundColor3       = Color3.fromRGB(30, 10, 20)
ScrollBg.BackgroundTransparency = 0.5
ScrollBg.BorderSizePixel        = 0
ScrollBg.Size                   = UDim2.fromScale(1, 1)
ScrollBg.ZIndex                 = BaseZIndex + 5
ScrollBg.Parent                 = ScrollArea

local uicSBg = Instance.new("UICorner")
uicSBg.CornerRadius = UDim.new(0, 6)
uicSBg.Parent = ScrollBg

local TextScroll = Instance.new("ScrollingFrame")
TextScroll.BackgroundTransparency = 1
TextScroll.BorderSizePixel        = 0
TextScroll.Position               = UDim2.new(0, 0, 0, 0)
TextScroll.Size                   = UDim2.new(1, 0, 1, 0)
TextScroll.CanvasSize             = UDim2.fromScale(0, 0)
TextScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
TextScroll.ScrollBarThickness     = 0
TextScroll.ScrollingDirection     = Enum.ScrollingDirection.Y
TextScroll.ElasticBehavior        = Enum.ElasticBehavior.Always
TextScroll.ScrollingEnabled       = true
TextScroll.Active                 = true
TextScroll.ZIndex                 = BaseZIndex + 7
TextScroll.Parent                 = ScrollArea

local ScrollPad = Instance.new("UIPadding")
ScrollPad.PaddingTop    = UDim.new(0, 10)
ScrollPad.PaddingBottom = UDim.new(0, 24)
ScrollPad.PaddingLeft   = UDim.new(0, 12)
ScrollPad.PaddingRight  = UDim.new(0, 12)
ScrollPad.Parent        = TextScroll

local TextList = Instance.new("Frame")
TextList.BackgroundTransparency = 1
TextList.Size                   = UDim2.new(1, 0, 0, 0)
TextList.AutomaticSize          = Enum.AutomaticSize.Y
TextList.ZIndex                 = BaseZIndex + 8
TextList.Parent                 = TextScroll

local TextListLayout = Instance.new("UIListLayout")
TextListLayout.FillDirection     = Enum.FillDirection.Vertical
TextListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TextListLayout.SortOrder         = Enum.SortOrder.LayoutOrder
TextListLayout.Padding           = UDim.new(0, 0)
TextListLayout.Parent            = TextList

local function MakeTextChunk(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size                   = UDim2.new(1, 0, 0, 0)
    lbl.AutomaticSize          = Enum.AutomaticSize.Y
    lbl.Text                   = text
    lbl.TextColor3             = Color3.fromRGB(255, 215, 225)
    lbl.TextSize               = 14
    lbl.LineHeight             = 1.62
    lbl.FontFace               = Library.Scheme.Font
    lbl.TextWrapped            = true
    lbl.RichText               = false
    lbl.TextXAlignment         = Enum.TextXAlignment.Center
    lbl.TextYAlignment         = Enum.TextYAlignment.Top
    lbl.Active                 = false
    lbl.Selectable             = false
    lbl.LayoutOrder            = order
    lbl.ZIndex                 = BaseZIndex + 8
    lbl.Parent                 = TextList
    return lbl
end

local paragraphs = string.split(MothersText, "\n\n")
for i, para in ipairs(paragraphs) do
    local trimmed = para:match("^%s*(.-)%s*$")
    if trimmed ~= "" then
        MakeTextChunk(trimmed, i)
        if i < #paragraphs then
            local spacer = Instance.new("Frame")
            spacer.BackgroundTransparency = 1
            spacer.Size                   = UDim2.new(1, 0, 0, 10)
            spacer.LayoutOrder            = i
            spacer.ZIndex                 = BaseZIndex + 8
            spacer.Parent                 = TextList
        end
    end
end

local HintLabel = Instance.new("TextLabel")
HintLabel.BackgroundTransparency = 1
HintLabel.Size                   = UDim2.new(1, 0, 0, 16)
HintLabel.AnchorPoint           = Vector2.new(0.5, 1)
HintLabel.Position              = UDim2.new(0.5, 0, 1, -44)
HintLabel.Text                  = SCROLL_HINT
HintLabel.TextColor3            = ROSE_DEEP
HintLabel.TextSize              = 10
HintLabel.FontFace              = Library.Scheme.Font
HintLabel.TextTransparency      = 0.3
HintLabel.ZIndex                = BaseZIndex + 9
HintLabel.Parent                = Card

TweenService:Create(HintLabel, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    TextTransparency = 0.75
}):Play()

local isDragging   = false
local autoScrollActive = true
local autoScrollConn   = nil

local function StopAutoScroll()
    if autoScrollConn then
        autoScrollConn:Disconnect()
        autoScrollConn = nil
    end
    autoScrollActive = false
end

local function StartAutoScroll()
    if autoScrollConn then autoScrollConn:Disconnect() end
    autoScrollActive = true
    local SPEED = 28
    local lastTick = tick()
    autoScrollConn = RunService.Heartbeat:Connect(function()
        if not autoScrollActive then return end
        if not TextScroll or not TextScroll.Parent then
            StopAutoScroll()
            return
        end
        local now = tick()
        local dt  = now - lastTick
        lastTick  = now
        local maxY = math.max(0, TextScroll.AbsoluteCanvasSize.Y - TextScroll.AbsoluteSize.Y)
        if maxY <= 0 then return end
        local newY = TextScroll.CanvasPosition.Y + SPEED * dt
        if newY >= maxY then
            TextScroll.CanvasPosition = Vector2.new(0, maxY)
            StopAutoScroll()
            return
        end
        TextScroll.CanvasPosition = Vector2.new(0, newY)
    end)
end

TextScroll.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        StopAutoScroll()
        isDragging = true
    end
end)

TextScroll.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

local ScrollIndicator = Instance.new("Frame")
ScrollIndicator.BackgroundColor3       = ROSE_DEEP
ScrollIndicator.BackgroundTransparency = 0.5
ScrollIndicator.BorderSizePixel        = 0
ScrollIndicator.AnchorPoint           = Vector2.new(1, 0)
ScrollIndicator.Position              = UDim2.new(1, -3, 0, 0)
ScrollIndicator.Size                  = UDim2.new(0, 3, 0.25, 0)
ScrollIndicator.ZIndex                = BaseZIndex + 9
ScrollIndicator.Parent                = ScrollArea

local uicSI = Instance.new("UICorner")
uicSI.CornerRadius = UDim.new(1, 0)
uicSI.Parent = ScrollIndicator

RunService.Heartbeat:Connect(function()
    if not ScrollArea.Parent then return end
    local total  = TextScroll.AbsoluteCanvasSize.Y
    local vis    = TextScroll.AbsoluteSize.Y
    local pos    = TextScroll.CanvasPosition.Y
    if total <= vis then
        ScrollIndicator.Visible = false
        return
    end
    ScrollIndicator.Visible = true
    local ratio    = vis / total
    local thumbPos = (pos / (total - vis)) * (1 - ratio)
    ScrollIndicator.Size     = UDim2.new(0, 3, ratio, 0)
    ScrollIndicator.Position = UDim2.new(1, -3, thumbPos, 0)
end)

task.delay(1.2, function()
    if TextScroll and TextScroll.Parent then
        StartAutoScroll()
    end
end)

local ButtonHolder = Instance.new("Frame")
ButtonHolder.Name                  = "ButtonHolder"
ButtonHolder.AnchorPoint           = Vector2.new(0.5, 1)
ButtonHolder.BackgroundTransparency = 1
ButtonHolder.Position              = UDim2.new(0.5, 0, 1, -10)
ButtonHolder.Size                  = UDim2.new(1, -24, 0, 30)
ButtonHolder.ZIndex                = BaseZIndex + 6
ButtonHolder.Parent                = Card

local UIList = Instance.new("UIListLayout")
UIList.FillDirection       = Enum.FillDirection.Horizontal
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIList.HorizontalFlex      = Enum.UIFlexAlignment.Fill
UIList.Padding             = UDim.new(0, 10)
UIList.Parent              = ButtonHolder

local function MakeButton(name, text, parent, accent)
    local btn = Instance.new("TextButton")
    btn.Name                = name
    btn.BackgroundColor3    = accent and ROSE_DARK or Color3.fromRGB(42, 16, 28)
    btn.Size                = UDim2.fromScale(1, 1)
    btn.ZIndex              = BaseZIndex + 7
    btn.Text                = text
    btn.TextColor3          = Color3.fromRGB(255, 220, 230)
    btn.TextSize            = 13
    btn.FontFace            = Library.Scheme.Font
    btn.AutoButtonColor     = false
    btn.BorderSizePixel     = 0
    btn.TextTransparency    = 0
    btn.Parent              = parent

    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, CornerRadius)
    uic.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color           = accent and ROSE_GLOW or ROSE_DARK
    stroke.Thickness       = accent and 1.5 or 1
    stroke.Parent          = btn

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   accent and Color3.fromRGB(200, 70, 110) or Color3.fromRGB(50, 18, 32)),
        ColorSequenceKeypoint.new(1,   accent and Color3.fromRGB(160, 40,  80) or Color3.fromRGB(35, 12, 22)),
    })
    grad.Rotation = 90
    grad.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,    fastTween, {BackgroundColor3 = ROSE_DEEP}):Play()
        TweenService:Create(stroke, fastTween, {Color = ROSE, Thickness = 2}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn,    fastTween, {
            BackgroundColor3 = accent and ROSE_DARK or Color3.fromRGB(42, 16, 28),
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0, 0),
        }):Play()
        TweenService:Create(stroke, fastTween, {Color = accent and ROSE_GLOW or ROSE_DARK, Thickness = accent and 1.5 or 1}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
        }):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, fastTween, {
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0, 0),
        }):Play()
    end)

    return btn
end

local CopyBtn     = MakeButton("CopyBtn",     COPY_TEXT,     ButtonHolder, false)
local ContinueBtn = MakeButton("ContinueBtn", CONTINUE_TEXT, ButtonHolder, true)

local function CloseCard()
    MarkSeen()
    MarkThemed()
    ApplyMothersTheme()
    StopPetals()
    StopAutoScroll()

    local fadeTween = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    for _, child in ipairs(Card:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            TweenService:Create(child, fadeTween, {TextTransparency = 1}):Play()
        end
        if child:IsA("Frame") and child.BackgroundTransparency < 1 then
            TweenService:Create(child, fadeTween, {BackgroundTransparency = 1}):Play()
        end
    end
    TweenService:Create(Card,        fadeTween, {BackgroundTransparency = 1}):Play()
    TweenService:Create(InnerBorder, fadeTween, {BackgroundTransparency = 1}):Play()
    TweenService:Create(OuterBorder, fadeTween, {BackgroundTransparency = 1}):Play()
    TweenService:Create(OuterGlow,   fadeTween, {BackgroundTransparency = 1}):Play()
    TweenService:Create(Overlay,     fadeTween, {BackgroundTransparency = 1}):Play()
    TweenService:Create(libraryTint, fadeTween, {BackgroundTransparency = 1}):Play()

    task.delay(0.5, function()
        if Overlay        and Overlay.Parent        then Overlay:Destroy()        end
        if libraryTint    and libraryTint.Parent    then libraryTint:Destroy()    end
        if PetalContainer and PetalContainer.Parent then PetalContainer:Destroy() end
    end)
end

CopyBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then setclipboard(MothersText) end
    end)
    if Library.Notify then
        Library:Notify({
            Title       = "msdoors 💗",
            Description = NOTIFY_COPIED,
            Time        = 3,
        })
    end
    local oldText = CopyBtn.Text
    CopyBtn.Text = "✓ " .. (isBrazilian and "Copiado!" or "Copied!")
    TweenService:Create(CopyBtn, fastTween, {BackgroundColor3 = Color3.fromRGB(60, 140, 80)}):Play()
    task.delay(1.8, function()
        if CopyBtn and CopyBtn.Parent then
            CopyBtn.Text = oldText
            TweenService:Create(CopyBtn, fastTween, {BackgroundColor3 = Color3.fromRGB(42, 16, 28)}):Play()
        end
    end)
end)

ContinueBtn.MouseButton1Click:Connect(CloseCard)

Library:OnUnload(function()
    StopPetals()
    StopAutoScroll()
    if Overlay        and Overlay.Parent        then Overlay:Destroy()        end
    if libraryTint    and libraryTint.Parent    then libraryTint:Destroy()    end
    if PetalContainer and PetalContainer.Parent then PetalContainer:Destroy() end
end)

StartPetals(PetalContainer, BaseZIndex + 1)

TweenService:Create(Overlay, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0.4,
}):Play()

TweenService:Create(libraryTint, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0.8,
}):Play()

task.delay(0.05, function()
    TweenService:Create(OuterGlow, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(468, 436),
    }):Play()

    task.delay(0.08, function()
        TweenService:Create(OuterBorder, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(444, 424),
        }):Play()
    end)
end)

task.delay(2.5, function()
    if HintLabel and HintLabel.Parent then
        TweenService:Create(HintLabel, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1,
        }):Play()
        task.delay(0.7, function()
            if HintLabel and HintLabel.Parent then HintLabel:Destroy() end
        end)
    end
end)
