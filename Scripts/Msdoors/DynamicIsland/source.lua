local ENV_ISLAND = (getgenv and getgenv()) or shared
if type(ENV_ISLAND.DynamicIslandLib) == "table" and type(ENV_ISLAND.DynamicIslandLib.new) == "function" then
    return ENV_ISLAND.DynamicIslandLib
end

local cloneref = cloneref or clonereference or function(instance)
    return instance
end

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TextService = cloneref(game:GetService("TextService"))
local GuiService = cloneref(game:GetService("GuiService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local Workspace = cloneref(game:GetService("Workspace"))

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local Scheme = {
    BackgroundColor = Color3.fromRGB(15, 15, 15),
    MainColor = Color3.fromRGB(25, 25, 25),
    AccentColor = Color3.fromRGB(125, 85, 255),
    OutlineColor = Color3.fromRGB(40, 40, 40),
    FontColor = Color3.new(1, 1, 1),
    DimColor = Color3.fromRGB(170, 170, 170),
    LyricDimColor = Color3.fromRGB(120, 120, 120),
    RedColor = Color3.fromRGB(255, 50, 50),
    GreenColor = Color3.fromRGB(80, 200, 120),
    YellowColor = Color3.fromRGB(255, 190, 60),
    DarkColor = Color3.new(0, 0, 0),
    Font = Font.fromEnum(Enum.Font.Code),
}

local Defaults = {
    TopOffset = 10,
    Scale = 1,
    Lyrics = true,
    LyricsInCompact = true,
    ShowIdle = true,
    IdleText = "",
    HoverDelay = 0.22,
    NotifyDuration = 4,
    NotifyPlacement = "Island",
    MaxQueue = 30,
    DisplayOrder = 999999,
    Visible = true,
    Accent = nil,
    Discreet = false,
    DockDelay = 2.5,
}

local Glyphs = {
    Info = "i",
    Success = "+",
    Warning = "!",
    Error = "x",
}

local LYRIC_TEXT_SIZE = 13
local LYRIC_SLOTS = 7
local EXP_LYRIC_TOP = 72
local EXP_LYRIC_H = 70
local EXP_SPACING = 22
local COMPACT_LYRIC_Y = 36
local EXP_H_LYRIC = 150
local EXP_H_PLAIN = 78
local CARD_PLATE_STEP = 6
local CARD_PLATE_SHRINK = 0.05
local CARD_PLATE_MAX = 2
local CARD_PLACEMENTS = { "Island", "Corner" }
local COVER_CACHE_MAX = 12

local CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

local function randomName()
    local len = math.random(10, 18)
    local out = table.create(len)
    for i = 1, len do
        local r = math.random(1, #CHARS)
        out[i] = CHARS:sub(r, r)
    end
    return table.concat(out)
end

local function new(class, props)
    local inst = Instance.new(class)
    inst.Name = randomName()
    if inst:IsA("GuiObject") then
        inst.BorderSizePixel = 0
    end
    if class == "TextLabel" or class == "TextButton" then
        inst.FontFace = Scheme.Font
        inst.RichText = false
    end
    if class == "TextButton" or class == "ImageButton" then
        inst.AutoButtonColor = false
    end
    local parent
    for key, value in pairs(props) do
        if key == "Parent" then
            parent = value
        else
            inst[key] = value
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function label(parent, props)
    props.BackgroundTransparency = 1
    props.TextColor3 = props.TextColor3 or Scheme.FontColor
    props.TextSize = props.TextSize or 13
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    props.TextTruncate = props.TextTruncate or Enum.TextTruncate.AtEnd
    props.Text = props.Text or ""
    props.Parent = parent
    return new("TextLabel", props)
end

local function parentGui(gui)
    pcall(function()
        local protect = protectgui or (syn and syn.protect_gui)
        if protect then
            protect(gui)
        end
    end)
    local ok = pcall(function()
        gui.Parent = (gethui and gethui()) or CoreGui
    end)
    if not ok or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function viewport()
    local camera = Workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function fmt(sec)
    sec = math.max(0, math.floor((sec or 0) + 0.5))
    return string.format("%d:%02d", sec // 60, sec % 60)
end

local function measureHeight(text, size, width)
    local params = Instance.new("GetTextBoundsParams")
    params.Text = text
    params.Font = Scheme.Font
    params.Size = size
    params.Width = math.max(width, 24)
    local ok, bounds = pcall(function()
        return TextService:GetTextBoundsAsync(params)
    end)
    if ok and bounds then
        return bounds.Y
    end
    local perLine = math.max(1, math.floor(width / (size * 0.55)))
    return math.ceil(#text / perLine) * size * 1.3
end

local widthCache = {}
local widthCacheCount = 0

local function textWidth(text)
    local cached = widthCache[text]
    if cached then
        return cached
    end
    local ok, size = pcall(function()
        return TextService:GetTextSize(text, LYRIC_TEXT_SIZE, Scheme.Font, Vector2.new(10000, 100))
    end)
    local w = (ok and size and size.X) or (#text * 7)
    if widthCacheCount > 800 then
        widthCache = {}
        widthCacheCount = 0
    end
    widthCache[text] = w
    widthCacheCount += 1
    return w
end

local TEMP_DIR = "msdoors/DynamicIsland"
local customAsset = getcustomasset or getsynasset
local warned = {}
local coverCache = {}
local coverOrder = {}

local function warnOnce(key, msg)
    if warned[key] then
        return
    end
    warned[key] = true
    warn("[DynamicIsland] " .. msg)
end

local function ensureTempDir()
    if not (makefolder and isfolder) then
        return false
    end
    if not isfolder("msdoors") then
        makefolder("msdoors")
    end
    if not isfolder(TEMP_DIR) then
        makefolder(TEMP_DIR)
    end
    return true
end

local function clearTempDir()
    if not (listfiles and isfolder and delfile) then
        return
    end
    if not isfolder(TEMP_DIR) then
        return
    end
    local ok, files = pcall(listfiles, TEMP_DIR)
    if ok and files then
        for _, path in ipairs(files) do
            pcall(delfile, path)
        end
    end
end

local function deleteImageFile(path)
    if path and typeof(delfile) == "function" and typeof(isfile) == "function" and isfile(path) then
        pcall(delfile, path)
    end
end

local function removeWhenLoaded(imageLabel, path)
    task.spawn(function()
        local t0 = os.clock()
        while not imageLabel.IsLoaded and os.clock() - t0 < 15 and imageLabel.Parent do
            task.wait(0.1)
        end
        deleteImageFile(path)
    end)
end

local function tempPath(src)
    local hash = 5381
    for i = 1, #src do
        hash = (hash * 33 + src:byte(i)) % 4294967296
    end
    local ext = (src:match("%.(%a+)%f[%A]") or "png"):lower()
    local allowed = { png = true, jpg = true, jpeg = true, bmp = true, tga = true }
    if not allowed[ext] then
        ext = "png"
    end
    return TEMP_DIR .. "/img_" .. string.format("%08x", hash) .. "." .. ext
end

local function fetchToTemp(url)
    if not (writefile and readfile and isfile) then
        return nil, "writefile/readfile indisponíveis"
    end
    ensureTempDir()
    local path = tempPath(url)
    if isfile(path) then
        local ok, data = pcall(readfile, path)
        if ok and type(data) == "string" and #data > 0 then
            return path
        end
    end
    local ok, data = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or type(data) ~= "string" or #data == 0 then
        return nil, "HttpGet falhou: " .. tostring(data)
    end
    writefile(path, data)
    return path
end

local function copyLocalToTemp(src)
    if not (writefile and readfile and isfile) then
        return nil, "writefile/readfile indisponíveis"
    end
    if not isfile(src) then
        return nil, "arquivo não existe: " .. src
    end
    ensureTempDir()
    local ok, data = pcall(readfile, src)
    if not ok or type(data) ~= "string" or #data == 0 then
        return nil, "leitura falhou: " .. src
    end
    local path = tempPath(src)
    writefile(path, data)
    return path
end

local function touchCover(src)
    for i = #coverOrder, 1, -1 do
        if coverOrder[i] == src then
            table.remove(coverOrder, i)
        end
    end
    table.insert(coverOrder, src)
    while #coverOrder > COVER_CACHE_MAX do
        local old = table.remove(coverOrder, 1)
        local entry = coverCache[old]
        coverCache[old] = nil
        if entry then
            deleteImageFile(entry.path)
        end
    end
end

local function clearCovers()
    for src, entry in pairs(coverCache) do
        coverCache[src] = nil
        deleteImageFile(entry.path)
    end
    table.clear(coverOrder)
end

local function loadAsset(src)
    if src == nil or src == "" then
        return nil
    end
    if typeof(src) == "number" then
        return "rbxassetid://" .. src
    end
    src = tostring(src)
    if src:match("^rbxasset") then
        return src
    end
    if src:match("^%d+$") then
        return "rbxassetid://" .. src
    end
    local cached = coverCache[src]
    if cached then
        touchCover(src)
        return cached.asset
    end
    if not customAsset then
        warnOnce("no_custom_asset", "getcustomasset/getsynasset indisponível: capas por URL não aparecem neste executor.")
        return nil
    end
    local path, reason
    if src:match("^https?://") then
        path, reason = fetchToTemp(src)
    else
        path, reason = copyLocalToTemp(src)
    end
    if not path then
        warnOnce("download:" .. src, "Falha ao obter imagem " .. src .. " (" .. tostring(reason) .. ")")
        return nil
    end
    local ok, asset = pcall(customAsset, path)
    if not ok or not asset then
        warnOnce("asset:" .. src, "Falha ao carregar imagem no executor: " .. tostring(asset))
        deleteImageFile(path)
        return nil
    end
    coverCache[src] = { asset = asset }
    touchCover(src)
    return asset, path
end

pcall(clearTempDir)

local function darkMix(color)
    return Scheme.BackgroundColor:Lerp(color, 0.3)
end

local Spring = {}
Spring.__index = Spring

function Spring.new(value, frequency, damping)
    return setmetatable({
        Value = value,
        Target = value,
        Velocity = 0,
        Frequency = frequency,
        Damping = damping,
    }, Spring)
end

function Spring:Step(dt)
    local d = self.Damping
    local w = self.Frequency * 2 * math.pi
    local x0 = self.Value - self.Target
    local v0 = self.Velocity
    local x, v
    if d == 1 then
        local e = math.exp(-w * dt)
        x = (x0 + (v0 + w * x0) * dt) * e
        v = (v0 - (v0 + w * x0) * w * dt) * e
    elseif d < 1 then
        local c = math.sqrt(1 - d * d)
        local i = math.cos(w * c * dt)
        local j = math.sin(w * c * dt)
        local e = math.exp(-d * w * dt)
        x = (x0 * (i + d * j / c) + v0 * j / (w * c)) * e
        v = (v0 * (i - d * j / c) - x0 * j * w / c) * e
    else
        local c = math.sqrt(d * d - 1)
        local r1 = -w * (d + c)
        local r2 = -w * (d - c)
        local co2 = (v0 - x0 * r1) / (2 * w * c)
        local co1 = x0 - co2
        local e1 = co1 * math.exp(r1 * dt)
        local e2 = co2 * math.exp(r2 * dt)
        x = e1 + e2
        v = r1 * e1 + r2 * e2
    end
    self.Value = x + self.Target
    self.Velocity = v
end

local function parseWordTags(line)
    local body = line:match("^<(.*)>$")
    if not body then
        return nil
    end
    local words = {}
    for token in (body .. "|"):gmatch("([^|]*)|") do
        local text, s, e = token:match("^(.*):([%d%.]+):([%d%.]+)$")
        if text and text ~= "" and tonumber(s) and tonumber(e) then
            table.insert(words, { Text = text, Start = tonumber(s), End = tonumber(e) })
        end
    end
    if #words == 0 then
        return nil
    end
    return words
end

local function strip(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function parseLyricLines(source)
    local lines = {}
    if type(source) == "table" then
        for _, entry in ipairs(source) do
            if type(entry) == "table" then
                local t = tonumber(entry.Time or entry.time or entry[1])
                local text = entry.Text or entry.text or entry[2]
                if t and text then
                    table.insert(lines, { Time = t, Text = strip(tostring(text)), Words = nil })
                end
            end
        end
    elseif type(source) == "string" then
        local lastGroup = {}
        for raw in (source:gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do
            local line = strip(raw)
            if line:sub(1, 1) == "<" then
                local words = parseWordTags(line)
                if words then
                    for _, entry in ipairs(lastGroup) do
                        entry.Words = words
                    end
                end
            elseif line ~= "" then
                local times = {}
                local rest = line
                while true do
                    local mm, ss, frac, after = rest:match("^%[(%d+):(%d+)[%.:]?(%d*)%](.*)$")
                    if not mm then
                        break
                    end
                    local t = tonumber(mm) * 60 + tonumber(ss)
                    if frac ~= "" then
                        t = t + tonumber(frac) / (10 ^ #frac)
                    end
                    table.insert(times, t)
                    rest = after
                end
                if #times > 0 then
                    local text = strip((rest:gsub("{[^}]*}", "")))
                    lastGroup = {}
                    for _, t in ipairs(times) do
                        local entry = { Time = t, Text = text, Words = nil }
                        table.insert(lines, entry)
                        table.insert(lastGroup, entry)
                    end
                end
            end
        end
    end
    table.sort(lines, function(a, b)
        return a.Time < b.Time
    end)
    for i, ln in ipairs(lines) do
        local nxt = lines[i + 1]
        ln.End = nxt and nxt.Time or (ln.Time + 6)
    end
    return lines
end

local function lyricIndexAt(lyrics, pos)
    local lo, hi, idx = 1, #lyrics, 0
    while lo <= hi do
        local mid = (lo + hi) // 2
        if lyrics[mid].Time <= pos then
            idx = mid
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return idx
end

local function lineProgress(line, pos)
    if not line or pos <= line.Time then
        return 0
    end
    if line.Words then
        local total, done = 0, 0
        for _, w in ipairs(line.Words) do
            total += #w.Text
        end
        for _, w in ipairs(line.Words) do
            local len = #w.Text
            if pos >= w.End then
                done += len
            elseif pos > w.Start then
                done += len * (pos - w.Start) / math.max(w.End - w.Start, 0.01)
                break
            else
                break
            end
        end
        if total <= 0 then
            return 0
        end
        return math.clamp(done / total, 0, 1)
    end
    return math.clamp((pos - line.Time) / math.max(line.End - line.Time, 0.2), 0, 1)
end

local function sweepSequence(p)
    if p <= 0 then
        return NumberSequence.new(1)
    end
    if p >= 1 then
        return NumberSequence.new(0)
    end
    local a = math.max(0, p - 0.04)
    local b = math.min(p, 0.999)
    return NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(a, 0),
        NumberSequenceKeypoint.new(b, 1),
        NumberSequenceKeypoint.new(1, 1),
    })
end

local Island = {}
Island.__index = Island

local instances = {}

function Island.new(config)
    local self = setmetatable({}, Island)
    local cfg = {}
    for k, v in pairs(Defaults) do
        cfg[k] = v
    end
    if type(config) == "table" then
        for k, v in pairs(config) do
            cfg[k] = v
        end
    end
    self.Config = cfg
    self.Accent = cfg.Accent or Scheme.AccentColor
    self.glowColor = self.Accent
    self.connections = {}
    self.stacks = { Island = {}, Corner = {} }
    self.cardShown = {}
    self.lyrics = {}
    self.currentIdx = 0
    self.frameDt = 0
    self.S = 1
    self.over = false
    self.cardOver = false
    self.hover = false
    self.pinned = false
    self.destroyed = false
    self.progress = 0
    self.specT = 0
    self.idleSince = os.clock()
    self.specLevels = { 0.2, 0.3, 0.25, 0.3, 0.2 }
    self.coverSrc = nil
    self.coverOk = false
    self.sW = Spring.new(40, 4, 1)
    self.sH = Spring.new(24, 4, 1)
    self.sE = Spring.new(0, 4, 1)
    self.sShow = Spring.new(0, 3, 0.68)
    self.sGlow = Spring.new(0, 2.2, 1)
    self.sDock = Spring.new(0, 1.6, 1)
    self.sScroll = Spring.new(0, 3.2, 1)
    self.cardSprings = {
        Island = Spring.new(0, 2.6, 1),
        Corner = Spring.new(0, 2.6, 1),
    }
    self.layerSprings = {
        media = Spring.new(0, 6, 1),
        idle = Spring.new(0, 6, 1),
    }
    self.springList = {
        self.sW,
        self.sH,
        self.sE,
        self.sShow,
        self.sGlow,
        self.sDock,
        self.sScroll,
        self.cardSprings.Island,
        self.cardSprings.Corner,
        self.layerSprings.media,
        self.layerSprings.idle,
    }
    self:_build()
    self:_bind()
    self:_retarget()
    table.insert(instances, self)
    return self
end

function Island:_makeCard(parent, accent, anchorX)
    local c = {}
    c.targetW = 300
    c.targetH = 60
    c.group = new("CanvasGroup", {
        AnchorPoint = Vector2.new(anchorX, 0),
        BackgroundColor3 = Scheme.BackgroundColor,
        BackgroundTransparency = 0.35,
        ClipsDescendants = true,
        Position = UDim2.fromOffset(0, -200),
        Size = UDim2.fromOffset(300, 60),
        GroupTransparency = 1,
        Visible = false,
        ZIndex = 30,
        Parent = parent,
    })
    c.radius = new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = c.group })
    new("UIStroke", {
        Color = Scheme.OutlineColor,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = c.group,
    })
    c.icon = new("Frame", {
        BackgroundColor3 = darkMix(accent),
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.fromOffset(28, 28),
        ZIndex = 31,
        Parent = c.group,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = c.icon })
    c.iconStroke = new("UIStroke", {
        Color = accent,
        Thickness = 1,
        Transparency = 0.35,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        ZIndex = 32,
        Parent = c.icon,
    })
    c.glyph = label(c.icon, {
        Size = UDim2.fromScale(1, 1),
        TextSize = 14,
        TextColor3 = accent,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 32,
    })
    c.iconImage = new("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ScaleType = Enum.ScaleType.Fit,
        Visible = false,
        ZIndex = 32,
        Parent = c.icon,
    })
    c.title = label(c.group, {
        Position = UDim2.fromOffset(46, 8),
        Size = UDim2.new(1, -56, 0, 16),
        TextSize = 14,
        ZIndex = 31,
    })
    c.text = label(c.group, {
        Position = UDim2.fromOffset(46, 26),
        Size = UDim2.fromOffset(236, 14),
        TextSize = 12,
        TextColor3 = Scheme.DimColor,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 31,
    })
    c.timer = new("Frame", {
        BackgroundColor3 = accent,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 32,
        Parent = c.group,
    })
    c.hit = new("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        ZIndex = 33,
        Parent = c.group,
    })
    c.plates = {}
    for i = 1, CARD_PLATE_MAX do
        local plate = new("Frame", {
            BackgroundColor3 = Scheme.BackgroundColor,
            BackgroundTransparency = 0.5,
            Size = UDim2.fromOffset(300, 60),
            ZIndex = 29 - i,
            Visible = false,
            Parent = parent,
        })
        new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = plate })
        c.plates[i] = plate
    end
    return c
end

function Island:_build()
    local cfg = self.Config

    self.gui = new("ScreenGui", {
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = cfg.DisplayOrder,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    parentGui(self.gui)

    self.holder = new("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, -80),
        Size = UDim2.fromOffset(0, 0),
        ZIndex = 10,
        Parent = self.gui,
    })

    self.glow = new("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://61997378",
        ImageColor3 = self.glowColor,
        ImageTransparency = 1,
        ZIndex = 0,
        Parent = self.holder,
    })

    self.shell = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(40, 24),
        BackgroundColor3 = Scheme.BackgroundColor,
        Visible = false,
        Parent = self.holder,
    })
    self.scaleObj = new("UIScale", { Parent = self.shell })
    self.shellCorner = new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = self.shell })
    new("UIStroke", {
        Color = Scheme.OutlineColor,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        ZIndex = 2,
        Parent = self.shell,
    })
    new("UIStroke", {
        Color = Scheme.DarkColor,
        Thickness = 1.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        ZIndex = 1,
        Parent = self.shell,
    })
    self.accentStroke = new("UIStroke", {
        Color = self.glowColor,
        Thickness = 1.5,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        ZIndex = 3,
        Parent = self.shell,
    })

    self.body = new("CanvasGroup", {
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Size = UDim2.fromScale(1, 1),
        Parent = self.shell,
    })
    self.bodyCorner = new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = self.body })

    local function makeLayer()
        return new("CanvasGroup", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            GroupTransparency = 1,
            Visible = false,
            Parent = self.body,
        })
    end
    self.layers = {
        media = makeLayer(),
        idle = makeLayer(),
    }

    self.hit = new("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        ZIndex = 20,
        Parent = self.shell,
    })

    self.cards = {
        Island = self:_makeCard(self.gui, self.Accent, 0.5),
        Corner = self:_makeCard(self.gui, self.Accent, 1),
    }

    local ml = self.layers.media
    local m = {}
    m.cover = new("Frame", { BackgroundColor3 = self.Accent, Parent = ml })
    new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = m.cover })
    m.letter = label(m.cover, {
        Size = UDim2.fromScale(1, 1),
        TextSize = 13,
        TextColor3 = Scheme.DarkColor,
        TextXAlignment = Enum.TextXAlignment.Center,
        Visible = true,
    })
    m.image = new("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ScaleType = Enum.ScaleType.Crop,
        Visible = false,
        Parent = m.cover,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = m.image })
    m.title = label(ml, { TextSize = 14 })
    m.artist = label(ml, { TextSize = 12, TextColor3 = Scheme.DimColor })
    m.time = label(ml, {
        TextSize = 12,
        TextColor3 = Scheme.DimColor,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.None,
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.fromOffset(92, 14),
    })
    m.track = new("Frame", { BackgroundColor3 = Scheme.MainColor, BackgroundTransparency = 1, Parent = ml })
    m.trackCorner = new("UICorner", { CornerRadius = UDim.new(0, 0), Parent = m.track })
    m.fill = new("Frame", { BackgroundColor3 = self.Accent, Parent = ml })
    m.fillCorner = new("UICorner", { CornerRadius = UDim.new(0, 0), Parent = m.fill })
    m.bars = {}
    for i = 1, 5 do
        local bar = new("Frame", { BackgroundColor3 = self.Accent, Parent = ml })
        new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
        m.bars[i] = bar
    end
    m.play = new("TextButton", {
        BackgroundColor3 = Scheme.DarkColor,
        BackgroundTransparency = 0.5,
        Text = "II",
        TextSize = 14,
        TextColor3 = Scheme.FontColor,
        Visible = false,
        ZIndex = 30,
        Parent = self.shell,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = m.play })
    self.m = m

    self.lyricClip = new("Frame", {
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Size = UDim2.fromOffset(10, 10),
        Visible = false,
        Parent = ml,
    })

    self.slots = {}
    for k = 1, LYRIC_SLOTS do
        local dim = label(self.lyricClip, {
            TextSize = LYRIC_TEXT_SIZE,
            TextColor3 = Scheme.LyricDimColor,
            TextTruncate = Enum.TextTruncate.None,
            Size = UDim2.fromOffset(10, 18),
            Visible = false,
        })
        local bright = label(self.lyricClip, {
            TextSize = LYRIC_TEXT_SIZE,
            TextColor3 = Scheme.FontColor,
            TextTruncate = Enum.TextTruncate.None,
            Size = UDim2.fromOffset(10, 18),
            Visible = false,
        })
        local grad = new("UIGradient", { Parent = bright })
        self.slots[k] = { dim = dim, bright = bright, grad = grad, idx = nil, w = 0, p = -1, x = 0 }
    end

    local il = self.layers.idle
    local i = {}
    i.dot = new("Frame", {
        BackgroundColor3 = self.Accent,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(8, 8),
        Parent = il,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = i.dot })
    i.text = label(il, {
        TextSize = 12,
        TextColor3 = Scheme.DimColor,
        Text = cfg.IdleText,
    })
    self.i = i
end

function Island:_bind()
    local function add(conn)
        table.insert(self.connections, conn)
        return conn
    end

    add(RunService.RenderStepped:Connect(function(dt)
        self:_step(dt)
    end))

    add(self.hit.Activated:Connect(function()
        self:_onActivated()
    end))

    add(self.cards.Island.hit.Activated:Connect(function()
        self:_onCardTap("Island")
    end))

    add(self.cards.Corner.hit.Activated:Connect(function()
        self:_onCardTap("Corner")
    end))

    add(UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = UserInputService:GetMouseLocation()
            self.over = self:_inside(pos)
            self.cardOver = self:_insideCard(pos)
        elseif input.UserInputType == Enum.UserInputType.Touch then
            local raw = Vector2.new(input.Position.X, input.Position.Y)
            self.over = self:_insideTouch(input.Position)
            self.cardOver = self:_insideCard(raw) or self:_insideCard(raw + GuiService:GetGuiInset())
        end
    end))

    add(UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local inside = self:_insideTouch(input.Position)
            self.over = inside
            if not inside and self.pinned then
                self:_setPinned(false)
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.pinned and not self:_inside(UserInputService:GetMouseLocation()) then
                self:_setPinned(false)
            end
        end
    end))

    add(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            self.over = false
            self.cardOver = false
        end
    end))
end

function Island:_inside(pos)
    local p, s = self.shell.AbsolutePosition, self.shell.AbsoluteSize
    local pad = 8
    local w = math.max(s.X, self.sW.Target * self.S)
    local h = math.max(s.Y, self.sH.Target * self.S)
    local cx = p.X + s.X / 2
    return pos.X >= cx - w / 2 - pad and pos.X <= cx + w / 2 + pad and pos.Y >= p.Y - pad and pos.Y <= p.Y + h + pad
end

function Island:_insideCard(pos)
    for _, placement in ipairs(CARD_PLACEMENTS) do
        local c = self.cards[placement]
        if c.group.Visible then
            local p, s = c.group.AbsolutePosition, c.group.AbsoluteSize
            local pad = 8
            if pos.X >= p.X - pad and pos.X <= p.X + s.X + pad and pos.Y >= p.Y - pad and pos.Y <= p.Y + s.Y + pad then
                return true
            end
        end
    end
    return false
end

function Island:_insideTouch(position)
    if self.sShow.Value < 0.5 then
        return false
    end
    local raw = Vector2.new(position.X, position.Y)
    return self:_inside(raw) or self:_inside(raw + GuiService:GetGuiInset())
end

function Island:_hasNotification()
    for _, placement in ipairs(CARD_PLACEMENTS) do
        if #self.stacks[placement] > 0 then
            return true
        end
    end
    return false
end

function Island:_activeLayer()
    if self.media then
        return "media"
    end
    if self.Config.ShowIdle then
        return "idle"
    end
    return nil
end

function Island:_lyricsActive()
    return self.Config.Lyrics and #self.lyrics > 0 and self.media ~= nil
end

function Island:_mediaAccent()
    return (self.media and self.media.Color) or self.Accent
end

function Island:_paint(color)
    self.m.cover.BackgroundColor3 = color
    self.m.fill.BackgroundColor3 = color
    self.i.dot.BackgroundColor3 = color
    for _, bar in ipairs(self.m.bars) do
        bar.BackgroundColor3 = color
    end
end

function Island:_retarget()
    if self.destroyed then
        return
    end
    local cfg = self.Config
    local vp = viewport()
    self.lastVp = vp
    local S = math.clamp(math.min(vp.X / 1100, vp.Y / 620), 0.62, 1.25) * (cfg.Scale or 1)
    self.S = S
    local maxW = (vp.X * 0.94) / S
    self.maxW = maxW

    local layer = self:_activeLayer()
    if layer == nil or layer == "idle" then
        self.pinned = false
    end
    local expanded = (self.hover or self.pinned) and layer == "media"
    self.expanded = expanded

    local Wc, Hc, We, He = 40, 24, 40, 24
    if layer == "media" then
        local lyr = self:_lyricsActive()
        Wc = math.min(cfg.Discreet and 200 or 255, maxW)
        Hc = 34 + ((lyr and cfg.LyricsInCompact and not cfg.Discreet) and 22 or 0)
        We = math.min(350, maxW)
        He = lyr and EXP_H_LYRIC or EXP_H_PLAIN
    elseif layer == "idle" then
        local text = cfg.IdleText or ""
        Wc = text == "" and 38 or math.min(#text * 7.3 + 42, maxW)
        Hc = 24
        We, He = Wc, Hc
    end

    for name, spring in pairs(self.layerSprings) do
        spring.Target = (name == layer) and 1 or 0
    end
    self.sW.Target = expanded and We or Wc
    self.sH.Target = expanded and He or Hc
    self.sE.Target = expanded and 1 or 0
    self.sShow.Target = (cfg.Visible and layer ~= nil) and 1 or 0
end

function Island:_setPinned(value)
    if self.pinned == value then
        return
    end
    self.pinned = value
    self:_retarget()
end

function Island:_onActivated()
    self:_setPinned(not self.pinned)
end

function Island:_onCardTap(placement)
    local stack = self.stacks[placement]
    local front = stack[#stack]
    if not front or self.cardSprings[placement].Value < 0.5 then
        return
    end
    if front.Callback then
        task.spawn(front.Callback, front)
    end
    front.Skip = true
end

function Island:_setCover(src)
    if src == self.coverSrc then
        return
    end
    self.coverSrc = src
    local asset, path = loadAsset(src)
    if asset then
        self.m.image.Image = asset
        if path then
            removeWhenLoaded(self.m.image, path)
        end
        self.m.image.Visible = true
        self.m.letter.Visible = false
        self.coverOk = true
    else
        self.m.image.Image = ""
        self.m.image.Visible = false
        self.m.letter.Visible = true
        self.coverOk = false
    end
end

function Island:_syncMedia()
    local media = self.media
    local m = self.m
    m.title.Text = media.Title or ""
    m.artist.Text = media.Artist or ""
    self:_setCover(media.Cover)
    if not self.coverOk then
        m.letter.Text = (media.Title or ""):sub(1, 1):upper()
    end
    self:_paint(self:_mediaAccent())
    self.lastTime = nil
end

function Island:_refreshTime()
    local media = self.media
    if not media then
        return
    end
    self.progress = (media.Duration and media.Duration > 0) and math.clamp(media.Position / media.Duration, 0, 1) or 0
    local ts = media.Duration and (fmt(media.Position) .. " / " .. fmt(media.Duration)) or fmt(media.Position)
    if ts ~= self.lastTime then
        self.lastTime = ts
        self.m.time.Text = ts
    end
end

function Island:_clearLyricSlots()
    for _, slot in ipairs(self.slots) do
        slot.dim.Visible = false
        slot.bright.Visible = false
        slot.idx = nil
    end
end

function Island:SetMedia(opts)
    opts = opts or {}
    local duration = tonumber(opts.Duration)
    self.media = {
        Title = tostring(opts.Title or ""),
        Artist = tostring(opts.Artist or ""),
        Cover = opts.Cover,
        Color = opts.Color,
        Duration = (duration and duration > 0) and duration or nil,
        Position = tonumber(opts.Position) or 0,
        Playing = opts.Playing ~= false,
    }
    self:SetLyrics("")
    self:_syncMedia()
    self:_refreshTime()
    self:_retarget()
end

function Island:UpdateMedia(opts)
    if not self.media then
        return self:SetMedia(opts)
    end
    opts = opts or {}
    local m = self.media
    if opts.Title ~= nil then
        m.Title = tostring(opts.Title)
    end
    if opts.Artist ~= nil then
        m.Artist = tostring(opts.Artist)
    end
    if opts.Cover ~= nil then
        m.Cover = opts.Cover
    end
    if opts.Color ~= nil then
        m.Color = opts.Color
    end
    local duration = tonumber(opts.Duration)
    if duration and duration > 0 then
        m.Duration = duration
    end
    local position = tonumber(opts.Position)
    if position then
        m.Position = position
        if self.boundSound and self.boundSound.Parent then
            pcall(function()
                self.boundSound.TimePosition = position
            end)
        end
    end
    if opts.Playing ~= nil then
        m.Playing = opts.Playing and true or false
    end
    self:_syncMedia()
    self:_refreshTime()
    self:_retarget()
end

function Island:SetPosition(seconds)
    self:UpdateMedia({ Position = seconds })
end

function Island:SetPlaying(value)
    self:UpdateMedia({ Playing = value and true or false })
end

function Island:TogglePlaying()
    local media = self.media
    if not media then
        return
    end
    local value = not media.Playing
    media.Playing = value
    local snd = self.boundSound
    if snd and snd.Parent then
        if value then
            snd:Resume()
        else
            snd:Pause()
        end
    end
end

function Island:ClearMedia()
    self.media = nil
    self.boundSound = nil
    self:SetLyrics("")
    self:_paint(self.Accent)
    self:_retarget()
end

function Island:SetLyrics(source)
    self.lyrics = parseLyricLines(source)
    self:_clearLyricSlots()
    local pos = self.media and self.media.Position or 0
    self.currentIdx = lyricIndexAt(self.lyrics, pos)
    self.sScroll.Target = self.currentIdx
    self.sScroll.Value = self.currentIdx
    self.sScroll.Velocity = 0
    self:_retarget()
end

function Island:SetLyricsEnabled(value)
    self.Config.Lyrics = value and true or false
    self:_retarget()
end

function Island:SetDiscreet(value)
    self.Config.Discreet = value and true or false
    self:_retarget()
end

function Island:SetNotifyPlacement(value)
    self.Config.NotifyPlacement = value == "Corner" and "Corner" or "Island"
end

function Island:SetAccent(color)
    self.Accent = color
    self:_paint(self:_mediaAccent())
end

function Island:BindSound(sound, opts)
    opts = opts or {}
    self:SetMedia({
        Title = opts.Title or sound.Name,
        Artist = opts.Artist or "",
        Cover = opts.Cover,
        Color = opts.Color,
        Duration = sound.TimeLength > 0 and sound.TimeLength or nil,
        Position = sound.TimePosition,
        Playing = sound.IsPlaying,
    })
    self.boundSound = sound
end

function Island:UnbindSound()
    self.boundSound = nil
end

function Island:_glowOn(color)
    self.glowColor = color
    self.sGlow.Target = 1
end

function Island:_glowOff()
    self.sGlow.Target = 0
end

function Island:_fillCard(c, n)
    c.title.Text = n.Title
    c.text.Text = n.Text
    local textH = measureHeight(n.Text, 12, 236)
    c.text.Size = UDim2.fromOffset(236, textH + 6)
    c.targetW = 300
    c.targetH = math.clamp(34 + textH + 16, 52, 420)
    c.icon.BackgroundColor3 = darkMix(n.Color)
    c.iconStroke.Color = n.Color
    c.glyph.TextColor3 = n.Color
    c.timer.BackgroundColor3 = n.Color
    c.glyph.Text = Glyphs[n.Kind] or "i"
    c.glyph.Visible = true
    c.iconImage.Visible = false
    c.iconImage.Image = ""
    local token = {}
    c.iconToken = token
    if n.Icon ~= nil and n.Icon ~= "" then
        task.spawn(function()
            local asset, path = loadAsset(n.Icon)
            if c.iconToken ~= token or not asset then
                return
            end
            c.iconImage.Image = asset
            c.iconImage.Visible = true
            c.glyph.Visible = false
            if path then
                removeWhenLoaded(c.iconImage, path)
            end
        end)
    end
end

function Island:Notify(opts)
    if type(opts) == "string" then
        opts = { Text = opts }
    end
    opts = opts or {}
    local kind = opts.Type or "Info"
    local color = opts.Color
    if not color then
        if kind == "Success" then
            color = Scheme.GreenColor
        elseif kind == "Warning" then
            color = Scheme.YellowColor
        elseif kind == "Error" then
            color = Scheme.RedColor
        else
            color = self.Accent
        end
    end
    local placement = self.Config.NotifyPlacement == "Corner" and "Corner" or "Island"
    local n = {
        Title = tostring(opts.Title or "Notice"),
        Text = tostring(opts.Text or opts.Content or ""),
        Duration = opts.Duration or self.Config.NotifyDuration,
        Elapsed = 0,
        Color = color,
        Kind = kind,
        Icon = opts.Icon,
        Callback = opts.Callback,
        Skip = false,
        Placement = placement,
    }
    local stack = self.stacks[placement]
    table.insert(stack, n)
    while #stack > self.Config.MaxQueue do
        table.remove(stack, 1)
    end
    return n
end

function Island:Dismiss()
    for _, placement in ipairs(CARD_PLACEMENTS) do
        local front = self.stacks[placement][#self.stacks[placement]]
        if front then
            front.Skip = true
        end
    end
end

function Island:ClearNotifications()
    for _, placement in ipairs(CARD_PLACEMENTS) do
        table.clear(self.stacks[placement])
    end
end

function Island:Show()
    self.Config.Visible = true
    self:_retarget()
end

function Island:Hide()
    self.Config.Visible = false
    self:_retarget()
end

function Island:Destroy()
    if self.destroyed then
        return
    end
    self.destroyed = true
    for _, c in ipairs(self.connections) do
        c:Disconnect()
    end
    if self.gui then
        self.gui:Destroy()
    end
    local idx = table.find(instances, self)
    if idx then
        table.remove(instances, idx)
    end
end

function Island:_tickNotifications(dt)
    for _, placement in ipairs(CARD_PLACEMENTS) do
        local stack = self.stacks[placement]
        local front = stack[#stack]
        if front then
            if not self.cardOver then
                front.Elapsed += dt
            end
            if front.Elapsed >= front.Duration or front.Skip then
                table.remove(stack)
            end
        end
    end
end

function Island:_step(dt)
    if self.destroyed then
        return
    end
    dt = math.min(dt, 1 / 20)
    self.frameDt = dt
    local now = os.clock()
    local cfg = self.Config

    local vp = viewport()
    if vp ~= self.lastVp then
        self:_retarget()
    end

    if self.over then
        self.leaveAt = nil
        if not self.hover then
            self.hover = true
            self:_retarget()
        end
    elseif self.hover then
        self.leaveAt = self.leaveAt or (now + cfg.HoverDelay)
        if now >= self.leaveAt then
            self.hover = false
            self.leaveAt = nil
            self:_retarget()
        end
    end

    self:_tickNotifications(dt)

    local busy = self.over or self.hover or self.pinned or self:_hasNotification()
    if busy then
        self.idleSince = now
    end
    self.sDock.Target = (cfg.Discreet and (now - self.idleSince) > cfg.DockDelay) and 1 or 0

    local media = self.media
    if media then
        local snd = self.boundSound
        if snd then
            if snd.Parent == nil then
                self.boundSound = nil
            else
                media.Position = snd.TimePosition
                media.Playing = snd.IsPlaying
                media.Duration = snd.TimeLength > 0 and snd.TimeLength or nil
            end
        elseif media.Playing then
            media.Position += dt
            if media.Duration and media.Position >= media.Duration then
                media.Position = media.Duration
            end
        end

        if media.Playing then
            self.specT += dt
            local st = self.specT
            local lv = self.specLevels
            for i = 1, #lv do
                local v = 0.5 + 0.5 * math.sin(st * (3.1 + i * 0.9) + i * 1.7)
                local w = 0.5 + 0.5 * math.sin(st * (5.3 + i * 1.3) + i * 0.6)
                local target = 0.18 + 0.82 * (0.6 * v + 0.4 * w)
                lv[i] = lerp(lv[i], target, math.min(1, dt * 10))
            end
        end

        self:_refreshTime()

        if #self.lyrics > 0 then
            local idx = lyricIndexAt(self.lyrics, media.Position)
            if idx ~= self.currentIdx then
                self.currentIdx = idx
                self.sScroll.Target = idx
            end
        end
    end

    for _, spring in ipairs(self.springList) do
        spring:Step(dt)
    end

    self:_render(now)
end

function Island:_renderPlates(card, stack, p)
    local depth = math.min(#stack - 1, CARD_PLATE_MAX)
    for i, plate in ipairs(card.plates) do
        if i <= depth and p > 0.5 then
            local shrink = 1 - CARD_PLATE_SHRINK * i
            local size = card.group.Size
            plate.AnchorPoint = card.group.AnchorPoint
            plate.Size = UDim2.fromOffset(size.X.Offset * shrink, size.Y.Offset)
            plate.Position = card.group.Position + UDim2.fromOffset(0, CARD_PLATE_STEP * i)
            plate.BackgroundTransparency = 0.45 + 0.15 * (i - 1)
            plate.Visible = true
        else
            plate.Visible = false
        end
    end
end

function Island:_renderCards(top, W, H, k)
    local belowY = top + H * k + 6
    for _, placement in ipairs(CARD_PLACEMENTS) do
        local card = self.cards[placement]
        local stack = self.stacks[placement]
        local front = stack[#stack]
        local spring = self.cardSprings[placement]
        local shown = self.cardShown[placement]
        if shown ~= nil and shown ~= front then
            spring.Target = 0
            if spring.Value <= 0.02 then
                self.cardShown[placement] = nil
                shown = nil
            end
        end
        if shown == nil then
            if front then
                self.cardShown[placement] = front
                self:_fillCard(card, front)
                spring.Target = 1
            else
                spring.Target = 0
            end
        end

        local p = math.clamp(spring.Value, 0, 1)
        if p <= 0.003 then
            card.group.Visible = false
            for _, plate in ipairs(card.plates) do
                plate.Visible = false
            end
        else
            local bodyA = math.clamp(p * 2.2, 0, 1)
            local contentA = math.clamp((p - 0.45) / 0.55, 0, 1)
            card.group.Visible = true
            card.group.GroupTransparency = 1 - bodyA
            card.title.TextTransparency = 1 - contentA
            card.text.TextTransparency = 1 - contentA
            card.glyph.TextTransparency = 1 - contentA
            card.iconImage.ImageTransparency = 1 - contentA
            if placement == "Island" then
                local w = lerp(W, card.targetW, p) * k
                local h = lerp(H, card.targetH, p) * k
                card.group.AnchorPoint = Vector2.new(0.5, 0)
                card.group.Size = UDim2.fromOffset(w, h)
                card.group.Position = UDim2.new(0.5, 0, 0, lerp(top, belowY, p))
                card.radius.CornerRadius = UDim.new(0, math.min(h / 2, 12))
            else
                card.group.AnchorPoint = Vector2.new(1, 0)
                card.group.Size = UDim2.fromOffset(card.targetW * k, card.targetH * k)
                card.group.Position = UDim2.new(1, lerp(320, -16, p), 0, top)
                card.radius.CornerRadius = UDim.new(0, 12)
            end
            self:_renderPlates(card, stack, p)
        end

        local timed = self.cardShown[placement]
        if timed then
            local frac = math.clamp(1 - timed.Elapsed / timed.Duration, 0, 1)
            card.timer.Size = UDim2.new(frac, 0, 0, 2)
        end
    end
end

function Island:_render(t)
    local cfg = self.Config
    local S = self.S
    local W = math.max(self.sW.Value, 24)
    local H = math.max(self.sH.Value, 14)
    local e = self.sE.Value
    local ec = math.clamp(e, 0, 1)
    local show = self.sShow.Value
    local dock = math.clamp(self.sDock.Value, 0, 1)
    local ds = lerp(1, 0.62, dock)
    local k = S * ds

    local r = math.min(H / 2, 14)
    self.shellCorner.CornerRadius = UDim.new(0, r)
    self.bodyCorner.CornerRadius = UDim.new(0, r)
    self.shell.Size = UDim2.fromOffset(W, H)
    self.scaleObj.Scale = k
    self.shell.BackgroundTransparency = (cfg.Discreet and 0.3 or 0) + 0.45 * dock

    local top = cfg.TopOffset * S
    local y = top + (1 - show) * -(H * S + top + 30)
    local xOff = -dock * (W * k / 2 + 14)
    self.holder.Position = UDim2.new(lerp(0.5, 1, dock), xOff, 0, y)
    self.shell.Visible = show > 0.02 or self.sShow.Target > 0

    local g = math.clamp(self.sGlow.Value, 0, 1)
    self.glow.ImageColor3 = self.glowColor
    self.glow.ImageTransparency = 1 - 0.3 * g
    self.glow.Size = UDim2.fromOffset((W + 60) * k, (H + 60) * k)
    self.glow.Position = UDim2.fromOffset(0, H * k / 2)

    self.accentStroke.Color = self.glowColor
    self.accentStroke.Transparency = 1 - 0.85 * g

    local fade = lerp(1, 0.5, dock)
    local alphas = {}
    for name, spring in pairs(self.layerSprings) do
        local alpha = math.clamp(spring.Value, 0, 1)
        alphas[name] = alpha
        local layer = self.layers[name]
        layer.GroupTransparency = 1 - alpha * fade
        layer.Visible = alpha > 0.01
    end

    if alphas.media > 0.01 and self.media then
        self:_layoutMedia(W, H, e, ec)
    end
    self.m.play.Visible = self.media ~= nil and alphas.media > 0.5 and ec > 0.5
    if alphas.idle > 0.01 then
        self:_layoutIdle(W, H, t)
    end

    self:_renderCards(top, W, H, k)
end

function Island:_setSlotLine(slot, idx)
    if slot.idx == idx then
        return false
    end
    slot.idx = idx
    local text = self.lyrics[idx].Text
    if text == "" then
        text = "..."
    end
    slot.w = textWidth(text)
    slot.dim.Text = text
    slot.bright.Text = text
    slot.dim.Size = UDim2.fromOffset(slot.w + 2, 18)
    slot.bright.Size = UDim2.fromOffset(slot.w + 2, 18)
    slot.p = -1
    return true
end

function Island:_setSweep(slot, p)
    if math.abs(p - slot.p) < 0.002 then
        return
    end
    slot.p = p
    slot.grad.Transparency = sweepSequence(p)
end

function Island:_hideSlot(slot)
    slot.dim.Visible = false
    slot.bright.Visible = false
    slot.idx = nil
end

function Island:_lineOffset(w, regionW, pos, idx)
    if w <= regionW then
        return (regionW - w) / 2
    end
    local p = lineProgress(self.lyrics[idx], pos)
    return -math.clamp(w * p - regionW * 0.42, 0, w - regionW)
end

function Island:_layoutLyrics(W, e, ec)
    local cfg = self.Config
    local hasLyr = self:_lyricsActive()
    local cur = self.currentIdx or 0
    local la
    if not hasLyr then
        la = 0
    elseif ec > 0.5 then
        la = ec
    else
        la = (cfg.LyricsInCompact and not cfg.Discreet) and (1 - ec) or 0
    end

    if la <= 0.01 or cur < 1 then
        self.lyricClip.Visible = false
        for _, slot in ipairs(self.slots) do
            self:_hideSlot(slot)
        end
        return
    end

    self.lyricClip.Visible = true
    local pos = self.media and self.media.Position or 0
    local dt = self.frameDt or 0
    local expanded = ec > 0.5
    local regionW, clipX, clipY, clipH
    if expanded then
        clipX, clipY = 12, EXP_LYRIC_TOP
        regionW = W - 24
        clipH = EXP_LYRIC_H
    else
        clipX, clipY = 8, COMPACT_LYRIC_Y
        regionW = W - 34
        clipH = 18
    end
    regionW = math.max(regionW, 10)
    self.lyricClip.Position = UDim2.fromOffset(clipX, clipY)
    self.lyricClip.Size = UDim2.fromOffset(regionW, clipH)

    if expanded then
        local s = self.sScroll.Value
        local nearest = math.floor(s + 0.5)
        local centerY = EXP_LYRIC_H / 2 - 9
        for k, slot in ipairs(self.slots) do
            local idx = nearest - 4 + k
            local dist = math.abs(idx - s)
            if idx >= 1 and idx <= #self.lyrics and dist < 2.6 then
                local changed = self:_setSlotLine(slot, idx)
                local tx = self:_lineOffset(slot.w, regionW, pos, idx)
                if idx == cur then
                    if changed then
                        slot.x = tx
                    else
                        slot.x = lerp(slot.x, tx, math.min(1, dt * 12))
                    end
                else
                    slot.x = tx
                end
                local y = centerY + (idx - s) * EXP_SPACING
                local a = math.clamp(1 - dist * 0.5, 0, 1)
                slot.dim.Visible = true
                slot.dim.Position = UDim2.fromOffset(slot.x, y)
                slot.dim.TextTransparency = 1 - a * la * 0.6
                if idx == cur then
                    slot.bright.Visible = true
                    slot.bright.Position = UDim2.fromOffset(slot.x, y)
                    slot.bright.TextTransparency = 1 - la
                    self:_setSweep(slot, lineProgress(self.lyrics[idx], pos))
                else
                    slot.bright.Visible = false
                end
            else
                self:_hideSlot(slot)
            end
        end
    else
        for k, slot in ipairs(self.slots) do
            if k == 1 then
                local changed = self:_setSlotLine(slot, cur)
                local tx = self:_lineOffset(slot.w, regionW, pos, cur)
                if changed then
                    slot.x = tx
                else
                    slot.x = lerp(slot.x, tx, math.min(1, dt * 12))
                end
                slot.dim.Visible = true
                slot.dim.Position = UDim2.fromOffset(slot.x, 0)
                slot.dim.TextTransparency = 1 - la * 0.6
                slot.bright.Visible = true
                slot.bright.Position = UDim2.fromOffset(slot.x, 0)
                slot.bright.TextTransparency = 1 - la
                self:_setSweep(slot, lineProgress(self.lyrics[cur], pos))
            else
                self:_hideSlot(slot)
            end
        end
    end
end

function Island:_layoutMedia(W, H, e, ec)
    local m = self.m

    local cs = lerp(22, 44, e)
    local cx = lerp(8, 12, e)
    local cy = lerp(6, 12, e)
    m.cover.Position = UDim2.fromOffset(cx, cy)
    m.cover.Size = UDim2.fromOffset(cs, cs)

    m.play.Position = UDim2.fromOffset(cx, cy)
    m.play.Size = UDim2.fromOffset(cs, cs)
    m.play.Text = (self.media and self.media.Playing) and "II" or ">"

    local tx = cx + cs + lerp(8, 10, e)
    m.title.Position = UDim2.fromOffset(tx, lerp(9, 12, e))
    m.title.Size = UDim2.fromOffset(math.max(W - tx - 100, 10), 16)
    m.artist.Position = UDim2.fromOffset(tx, lerp(24, 30, e))
    m.artist.Size = UDim2.fromOffset(math.max(W - tx - 12, 10), 14)
    m.artist.TextTransparency = 1 - ec
    m.time.Position = UDim2.fromOffset(W - lerp(8, 12, e) - 26, lerp(10, 13, e))

    local py = lerp(H - 2, 60, e)
    local pt = lerp(2, 4, e)
    local px = lerp(0, 12, e)
    local pw = math.max(lerp(W, W - 24, e), 1)
    m.track.Position = UDim2.fromOffset(px, py)
    m.track.Size = UDim2.fromOffset(pw, pt)
    m.track.BackgroundTransparency = 1 - ec
    m.fill.Position = UDim2.fromOffset(px, py)
    m.fill.Size = UDim2.fromOffset(pw * self.progress, pt)
    local rad = UDim.new(0, (pt / 2) * ec)
    m.trackCorner.CornerRadius = rad
    m.fillCorner.CornerRadius = rad

    local base = lerp(H - 8, 46, e)
    local maxBar = lerp(H - 18, 34, e)
    for i, bar in ipairs(m.bars) do
        local bh = math.max(2, maxBar * (self.specLevels[i] or 0))
        bar.Position = UDim2.fromOffset(W - 22 + (i - 1) * 4, base - bh)
        bar.Size = UDim2.fromOffset(2, bh)
    end

    self:_layoutLyrics(W, e, ec)
end

function Island:_layoutIdle(W, H, t)
    local i = self.i
    local text = self.Config.IdleText or ""
    if text == "" then
        i.dot.Position = UDim2.fromOffset(W / 2, H / 2)
        i.text.TextTransparency = 1
    else
        i.dot.Position = UDim2.fromOffset(15, H / 2)
        i.text.Position = UDim2.fromOffset(28, 0)
        i.text.Size = UDim2.fromOffset(math.max(W - 34, 10), H)
        i.text.Text = text
        i.text.TextTransparency = 0
    end
    i.dot.BackgroundTransparency = 0.15 + 0.35 * (0.5 + 0.5 * math.sin(t * 2.2))
end

local Library = {}

function Library.new(config)
    if Library.instance and not Library.instance.destroyed then
        return Library.instance
    end
    Library.instance = Island.new(config)
    return Library.instance
end

function Library.DestroyAll()
    for i = #instances, 1, -1 do
        instances[i]:Destroy()
    end
    Library.instance = nil
    clearCovers()
    pcall(clearTempDir)
end

Library.Scheme = Scheme

local env = (getgenv and getgenv()) or shared
env.DynamicIslandLib = Library

return Library
