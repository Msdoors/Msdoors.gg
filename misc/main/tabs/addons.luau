if getgenv().msaddons then
    return getgenv().msaddons
end

if not getgenv().Linoria then
    getgenv().Linoria = {
        Toggles = shared.Toggles,
        Options = shared.Options,
    }
else
    if not getgenv().Linoria.Toggles then getgenv().Linoria.Toggles = shared.Toggles end
    if not getgenv().Linoria.Options then getgenv().Linoria.Options = shared.Options end
end

getgenv().lib = getgenv().Linoria or getgenv().Library

local AddonsAPI = {}
local AddonTab = nil
local LastGroupSide = "Right"

local _realenv = getfenv(0)

local function checkFileSystem()
    if shared and shared.testexecutor and shared.testexecutor.supportFileSystem ~= nil then
        return shared.testexecutor.supportFileSystem == true
    end
    return type(isfolder) == "function" and type(listfiles) == "function" and type(readfile) == "function"
end

local function waitForLoaded()
    if shared and shared.loaded ~= nil then
        repeat task.wait() until shared.loaded == true
        return
    end
    repeat task.wait() until getgenv().mspaint_loaded == true
end

local function validateGame(addon, fileName)
    local gameField = addon.Game
    if not gameField then return true end
    if type(gameField) == "string" then return true end

    local currentPlaceId = game.PlaceId

    if type(gameField) == "number" then
        if gameField == currentPlaceId then return true end
        warn("[msdoors] Addon '" .. fileName .. "' didn't load: Wrong game.")
        return false
    end

    if type(gameField) == "table" then
        local hasNumber = false
        for _, v in pairs(gameField) do
            if type(v) == "number" then
                hasNumber = true
                if v == currentPlaceId then return true end
            end
        end
        if not hasNumber then return true end
        warn("[msdoors] Addon '" .. fileName .. "' didn't load: Wrong game.")
        return false
    end

    return true
end



local function addElement(container, addonName, element)
    if type(element) ~= "table" or not element.Type then return nil end

    local elemType = element.Type
    if elemType:sub(1, 3) == "Add" then elemType = elemType:sub(4) end

    local args = element.Arguments or {}
    local name = element.Name and (addonName .. "_" .. element.Name) or nil

    if elemType == "Divider" then
        return container:AddDivider(args.Text)
    end

    if elemType == "DependencyBox" then
        return container:AddDependencyBox()
    end

    if elemType == "Label" then
        if type(args) == "table" and not args.Text then
            return container:AddLabel(table.unpack(args))
        end
        return container:AddLabel(args.Text or "Label", args.DoesWrap)
    end

    if elemType == "Paragraph" then
        return container:AddLabel(args.Text or "", true)
    end

    if elemType == "Button" then
        return container:AddButton({
            Text = args.Text or "Button",
            Func = args.Func or args.Callback,
            DoubleClick = args.DoubleClick,
            Tooltip = args.Tooltip,
            DisabledTooltip = args.DisabledTooltip,
            Risky = args.Risky,
            Disabled = args.Disabled,
            Visible = args.Visible,
        })
    end

    if not name then
        warn("[msdoors] Element '" .. tostring(element.Name) .. " (" .. tostring(elemType) .. ")' didn't load: Invalid name.")
        return nil
    end

    if elemType == "Toggle" then
        return container:AddToggle(name, {
            Text = args.Text or "Toggle",
            Default = args.Default,
            Tooltip = args.Tooltip,
            DisabledTooltip = args.DisabledTooltip,
            Callback = args.Callback or args.Changed,
            Risky = args.Risky,
            Disabled = args.Disabled,
            Visible = args.Visible,
        })
    end

    if elemType == "Checkbox" then
        return container:AddCheckbox(name, {
            Text = args.Text or "Checkbox",
            Default = args.Default,
            Tooltip = args.Tooltip,
            DisabledTooltip = args.DisabledTooltip,
            Callback = args.Callback or args.Changed,
            Risky = args.Risky,
            Disabled = args.Disabled,
            Visible = args.Visible,
        })
    end

    if elemType == "Slider" then
        return container:AddSlider(name, {
            Text = args.Text or "Slider",
            Min = args.Min or 0,
            Max = args.Max or 100,
            Default = args.Default or 0,
            Rounding = args.Rounding or 0,
            Prefix = args.Prefix,
            Suffix = args.Suffix,
            Compact = args.Compact,
            HideMax = args.HideMax,
            FormatDisplayValue = args.FormatDisplayValue,
            Tooltip = args.Tooltip,
            DisabledTooltip = args.DisabledTooltip,
            Callback = args.Callback or args.Changed,
            Disabled = args.Disabled,
            Visible = args.Visible,
        })
    end

    if elemType == "Input" then
        return container:AddInput(name, {
            Text = args.Text or "Input",
            Default = args.Default or "",
            Numeric = args.Numeric,
            Finished = args.Finished,
            ClearTextOnFocus = args.ClearTextOnFocus,
            ClearTextOnBlur = args.ClearTextOnBlur,
            Placeholder = args.Placeholder,
            AllowEmpty = args.AllowEmpty,
            EmptyReset = args.EmptyReset,
            MaxLength = args.MaxLength,
            VerifyValue = args.VerifyValue,
            Tooltip = args.Tooltip,
            DisabledTooltip = args.DisabledTooltip,
            Callback = args.Callback or args.Changed,
            Disabled = args.Disabled,
            Visible = args.Visible,
        })
    end

    if elemType == "Dropdown" then
        return container:AddDropdown(name, {
            Text = args.Text,
            Values = args.Values or {},
            DisabledValues = args.DisabledValues or {},
            Default = args.Default,
            Multi = args.Multi,
            AllowNull = args.AllowNull,
            Searchable = args.Searchable,
            MaxVisibleDropdownItems = args.MaxVisibleDropdownItems,
            SpecialType = args.SpecialType,
            ExcludeLocalPlayer = args.ExcludeLocalPlayer,
            EnablePlayerImages = args.EnablePlayerImages,
            FormatDisplayValue = args.FormatDisplayValue,
            FormatListValue = args.FormatListValue,
            ValueImages = args.ValueImages,
            Tooltip = args.Tooltip,
            DisabledTooltip = args.DisabledTooltip,
            Callback = args.Callback or args.Changed,
            Disabled = args.Disabled,
            Visible = args.Visible,
        })
    end

    if elemType == "ColorPicker" then
        return container:AddColorPicker(name, {
            Default = args.Default or Color3.new(1, 1, 1),
            Title = args.Title,
            Transparency = args.Transparency,
            Tooltip = args.Tooltip,
            DisabledTooltip = args.DisabledTooltip,
            Callback = args.Callback or args.Changed,
            Visible = args.Visible,
        })
    end

    if elemType == "KeyPicker" then
        return container:AddKeyPicker(name, {
            Text = args.Text,
            Default = args.Default or "None",
            DefaultModifiers = args.DefaultModifiers or {},
            Mode = args.Mode or "Toggle",
            Modes = args.Modes or {"Always", "Toggle", "Hold"},
            SyncToggleState = args.SyncToggleState,
            WaitForCallback = args.WaitForCallback,
            Blacklist = args.Blacklist or args.Blacklisted,
            Whitelisted = args.Whitelisted,
            BlacklistModifiers = args.BlacklistModifiers or args.BlacklistedModifiers,
            WhitelistedModifiers = args.WhitelistedModifiers,
            NoUI = args.NoUI,
            Tooltip = args.Tooltip,
            DisabledTooltip = args.DisabledTooltip,
            Callback = args.Callback or args.Changed,
            ChangedCallback = args.ChangedCallback,
            Clicked = args.Clicked,
            Visible = args.Visible,
        })
    end

    if elemType == "Viewport" then
        return container:AddViewport({
            Object = args.Object,
            Camera = args.Camera,
            Clone = args.Clone,
            AutoFocus = args.AutoFocus,
            Interactive = args.Interactive,
            Height = args.Height or 200,
            Visible = args.Visible,
        })
    end

    if elemType == "Image" then
        return container:AddImage({
            Image = args.Image,
            Transparency = args.Transparency or 0,
            BackgroundTransparency = args.BackgroundTransparency or 0,
            Color = args.Color or Color3.new(1, 1, 1),
            RectOffset = args.RectOffset or Vector2.zero,
            RectSize = args.RectSize or Vector2.zero,
            ScaleType = args.ScaleType or Enum.ScaleType.Fit,
            Height = args.Height or 200,
            Visible = args.Visible,
        })
    end

    if elemType == "Video" then
        return container:AddVideo({
            Video = args.Video,
            Looped = args.Looped,
            Playing = args.Playing,
            Volume = args.Volume or 1,
            Height = args.Height or 200,
            Visible = args.Visible,
        })
    end

    if elemType == "UIPassthrough" then
        return container:AddUIPassthrough({
            Instance = args.Instance,
            Height = args.Height or 24,
            Visible = args.Visible,
        })
    end

    warn("[msdoors] Element '" .. tostring(element.Name) .. " (" .. tostring(elemType) .. ")' didn't load: Invalid element type.")
    return nil
end

local function loadElements(container, addonName, elements)
    if not elements or type(elements) ~= "table" then return end
    for _, element in pairs(elements) do
        local ok, err = pcall(function()
            local created = addElement(container, addonName, element)
            if created then
                loadElements(created, addonName, element.Elements)
            end
        end)
        if not ok then
            warn("[msdoors] Element error in '" .. addonName .. "': " .. tostring(err))
        end
    end
end

local function createErrorUI(addonName, errorMsg)
    local groupbox
    if LastGroupSide == "Right" then
        groupbox = AddonTab:AddLeftGroupbox("❌ " .. addonName)
        LastGroupSide = "Left"
    else
        groupbox = AddonTab:AddRightGroupbox("❌ " .. addonName)
        LastGroupSide = "Right"
    end
    pcall(function()
        groupbox:AddLabel(tostring(errorMsg), true)
        groupbox:AddDivider()
        groupbox:AddButton({
            Text = "Copy Error",
            Func = function()
                if setclipboard then
                    setclipboard(tostring(errorMsg))
                end
            end,
        })
    end)
end

local function buildAddonEnv(extras)
    local env = setmetatable(extras or {}, {
        __index = function(_, k)
            local v = rawget(_realenv, k)
            if v ~= nil then return v end
            return _realenv[k]
        end,
    })
    return env
end

local function tryLoadAddon(file, fileName)
    local fileContent = readfile(file)

    local addonFunc, loadErr = loadstring(fileContent)
    if not addonFunc then
        error("Syntax error: " .. tostring(loadErr))
    end

    local isMspaintStyle = fileContent:find("mspaint%.AddonInfo") or fileContent:find("mspaint%.Groupbox")

    if isMspaintStyle then
        local addonInfo = nil
        local groupbox = nil

        local mspaintProxy = setmetatable({}, {
            __newindex = function(_, k, v)
                if k == "AddonInfo" then
                    addonInfo = v
                end
            end,
            __index = function(_, k)
                if k == "Groupbox" then return groupbox end
                return nil
            end
        })

        local captureEnv = setmetatable({ mspaint = mspaintProxy }, { __index = _realenv })
        local captureFunc, _ = loadstring("mspaint = ...\n" .. fileContent)
        if captureFunc then
            pcall(setfenv(captureFunc, captureEnv), mspaintProxy)
        end

        if not addonInfo or type(addonInfo.Name) ~= "string" then
            error("mspaint.AddonInfo not found or invalid.")
        end

        if not validateGame(addonInfo, fileName) then return true end

        addonInfo.Name = addonInfo.Name:gsub("%s+", "")
        local title = type(addonInfo.Title) == "string" and addonInfo.Title or addonInfo.Name

        if LastGroupSide == "Right" then
            groupbox = AddonTab:AddLeftGroupbox("")
            LastGroupSide = "Left"
        else
            groupbox = AddonTab:AddRightGroupbox("")
            LastGroupSide = "Right"
        end

        groupbox:AddLabel(title)

        if type(addonInfo.Description) == "string" then
            groupbox:AddLabel(addonInfo.Description, true)
        end

        local Library = getgenv().Library or getgenv().lib

        local realFunc, realErr = loadstring(fileContent)
        if not realFunc then
            realFunc = addonFunc
        end

        local realEnv = buildAddonEnv({
            mspaint = setmetatable({}, {
                __newindex = function() end,
                __index = function(_, k)
                    if k == "AddonInfo" then return addonInfo end
                    if k == "Groupbox" then return groupbox end
                    return nil
                end
            }),
            Library = Library,
            Toggles = shared.Toggles or {},
            Options = shared.Options or {},
        })

        setfenv(realFunc, realEnv)()
        return true
    else
        local addon = addonFunc()

        if type(addon) ~= "table" then
            error("Addon returned invalid type.")
        end

        if type(addon.Name) ~= "string" or type(addon.Elements) ~= "table" then
            error("Invalid Name/Elements.")
        end

        if not validateGame(addon, fileName) then return true end

        addon.Name = addon.Name:gsub("%s+", "")
        if type(addon.Title) ~= "string" then
            addon.Title = addon.Name
        end

        local groupbox
        if LastGroupSide == "Right" then
            groupbox = AddonTab:AddLeftGroupbox("")
            LastGroupSide = "Left"
        else
            groupbox = AddonTab:AddRightGroupbox("")
            LastGroupSide = "Right"
        end

        groupbox:AddLabel(addon.Title)

        if type(addon.Description) == "string" then
            groupbox:AddLabel(addon.Description, true)
        end

        if addon.Author ~= nil then
            local authors = type(addon.Author) == "table" and table.concat(addon.Author, ", ") or tostring(addon.Author)
            groupbox:AddLabel("By: " .. authors)
        end

        if type(addon.Version) == "string" then
            groupbox:AddLabel("v" .. addon.Version)
        end

        if addon.Description or addon.Author or addon.Version then
            groupbox:AddDivider()
        end

        loadElements(groupbox, addon.Name, addon.Elements)
        return true
    end
end

function AddonsAPI:Initialize(Window)
    if not checkFileSystem() then
        warn("[msdoors] Executor doesn't support FileSystem. Addons disabled.")
        return false
    end

    self.Window = Window

    AddonTab = Window:AddTab({
        Name = "Addons",
        Icon = "diamond-plus"
    })

    task.spawn(function()
        waitForLoaded()

        if not isfolder("msdoors/addons") then
            makefolder("msdoors/addons")
            warn("[msdoors] Created addons folder at msdoors/addons")
            return
        end

        local files = listfiles("msdoors/addons")
        local loadCount, failCount = 0, 0

        for _, file in pairs(files) do
            local fileName = file:match("([^/\\]+)$") or file
            local ext = fileName:match("%.([^%.]+)$")
            if ext ~= "lua" and ext ~= "luau" and ext ~= "txt" then
                continue
            end

            local success, errorMessage = pcall(tryLoadAddon, file, fileName)

            if not success then
                warn("[msdoors] Failed to load addon '" .. fileName .. "': " .. tostring(errorMessage))
                pcall(createErrorUI, fileName:gsub("%.luau?$", ""):gsub("%.txt$", ""), errorMessage)
                failCount += 1
            else
                loadCount += 1
            end
        end

        if loadCount > 0 then
            print(string.format("[msdoors] Loaded %d addon(s) successfully", loadCount))
        end
        if failCount > 0 then
            warn(string.format("[msdoors] Failed to load %d addon(s)", failCount))
        end
        if loadCount == 0 and failCount == 0 then
            warn("[msdoors] No addons found in msdoors/addons folder")
        end
    end)

    return true
end

getgenv().msaddons = AddonsAPI
return AddonsAPI
