if getgenv().msaddons then 
    return getgenv().msaddons
end

local AddonsAPI = {}
local LoadedAddons = {}
local AddonTab = nil
local LastGroupSide = "Right"

local function checkFileSystem()
    if shared and shared.testexecutor and shared.testexecutor.supportFileSystem ~= nil then
        return shared.testexecutor.supportFileSystem == true
    end
    
    return (type(isfolder) == "function" and type(listfiles) == "function" and type(readfile) == "function")
end

function AddonsAPI:Initialize(Window)
    if not checkFileSystem() then
        warn("[msdoors] Executor doesn't support FileSystem. Addons disabled.")
        return false
    end

    if not isfolder("msdoors/addons") then
        makefolder("msdoors/addons")
        warn("[msdoors] Created addons folder at msdoors/addons")
        return false
    end

    self.Window = Window
    self:LoadAddons()
    return true
end

function AddonsAPI:CreateAddonTab()
    if not AddonTab then
        AddonTab = self.Window:AddTab("Addons", "puzzle-piece")
    end
    return AddonTab
end

function AddonsAPI:ValidateAddon(addon, fileName)
    if type(addon) ~= "table" then
        return false, "Returned invalid type"
    end

    if type(addon.Name) ~= "string" or #addon.Name == 0 then
        return false, "Missing valid Name"
    end

    if type(addon.Elements) ~= "table" then
        return false, "Missing Elements table"
    end

    if addon.Game then
        local currentPlaceId = game.PlaceId
        local gameList = type(addon.Game) == "table" and addon.Game or {addon.Game}
        
        local gameMatches = false
        for _, gameId in ipairs(gameList) do
            if type(gameId) == "number" and gameId == currentPlaceId then
                gameMatches = true
                break
            elseif tostring(gameId) == "*" then
                gameMatches = true
                break
            end
        end

        if not gameMatches then
            return false, "Game ID mismatch"
        end
    end

    return true
end

function AddonsAPI:AddElement(container, addonName, element)
    if type(element) ~= "table" or not element.Type then
        return nil
    end

    local elemType = element.Type
    local args = element.Arguments or {}
    local name = element.Name and (addonName .. "_" .. element.Name) or nil

    if elemType == "Label" then
        return container:AddLabel(args.Text or "Label", args.DoesWrap, name)
    elseif elemType == "BlankSpace" then
        return container:AddBlankSpace()
    elseif elemType == "Divider" then
        return container:AddDivider()
    elseif elemType == "Button" then
        return container:AddButton({
            Text = args.Text or "Button",
            Func = args.Func or args.Callback,
            DoubleClick = args.DoubleClick,
            Tooltip = args.Tooltip,
            DisabledTooltip = args.DisabledTooltip,
            Risky = args.Risky,
            Disabled = args.Disabled,
            Visible = args.Visible
        })
    elseif elemType == "Toggle" and name then
        return container:AddToggle(name, {
            Text = args.Text or "Toggle",
            Default = args.Default,
            Tooltip = args.Tooltip,
            DisabledTooltip = args.DisabledTooltip,
            Callback = args.Callback or args.Changed,
            Risky = args.Risky,
            Disabled = args.Disabled,
            Visible = args.Visible
        })
    elseif elemType == "Checkbox" and name then
        return container:AddCheckbox(name, {
            Text = args.Text or "Checkbox",
            Default = args.Default,
            Tooltip = args.Tooltip,
            DisabledTooltip = args.DisabledTooltip,
            Callback = args.Callback or args.Changed,
            Risky = args.Risky,
            Disabled = args.Disabled,
            Visible = args.Visible
        })
    elseif elemType == "Slider" and name then
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
            Visible = args.Visible
        })
    elseif elemType == "Input" and name then
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
            Visible = args.Visible
        })
    elseif elemType == "Dropdown" and name then
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
            Visible = args.Visible
        })
    elseif elemType == "ColorPicker" and name then
        return container:AddColorPicker(name, {
            Default = args.Default or Color3.new(1, 1, 1),
            Title = args.Title,
            Transparency = args.Transparency,
            Tooltip = args.Tooltip,
            DisabledTooltip = args.DisabledTooltip,
            Callback = args.Callback or args.Changed,
            Visible = args.Visible
        })
    elseif elemType == "KeyPicker" and name then
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
            Visible = args.Visible
        })
    elseif elemType == "DependencyBox" then
        return container:AddDependencyBox()
    elseif elemType == "Paragraph" then
        return container:AddLabel(args.Text or "", true)
    elseif elemType == "Viewport" then
        return container:AddViewport({
            Object = args.Object,
            Camera = args.Camera,
            Clone = args.Clone,
            AutoFocus = args.AutoFocus,
            Interactive = args.Interactive,
            Height = args.Height or 200,
            Visible = args.Visible
        })
    elseif elemType == "Image" then
        return container:AddImage({
            Image = args.Image,
            Transparency = args.Transparency or 0,
            BackgroundTransparency = args.BackgroundTransparency or 0,
            Color = args.Color or Color3.new(1, 1, 1),
            RectOffset = args.RectOffset or Vector2.zero,
            RectSize = args.RectSize or Vector2.zero,
            ScaleType = args.ScaleType or Enum.ScaleType.Fit,
            Height = args.Height or 200,
            Visible = args.Visible
        })
    elseif elemType == "Video" then
        return container:AddVideo({
            Video = args.Video,
            Looped = args.Looped,
            Playing = args.Playing,
            Volume = args.Volume or 1,
            Height = args.Height or 200,
            Visible = args.Visible
        })
    elseif elemType == "UIPassthrough" then
        return container:AddUIPassthrough({
            Instance = args.Instance,
            Height = args.Height or 24,
            Visible = args.Visible
        })
    end

    return nil
end

function AddonsAPI:LoadElements(container, addonName, elements)
    if type(elements) ~= "table" then return end

    for _, element in ipairs(elements) do
        local createdElement = self:AddElement(container, addonName, element)
        
        if createdElement and element.Elements then
            self:LoadElements(createdElement, addonName, element.Elements)
        end
    end
end

function AddonsAPI:CreateErrorUI(tab, addonName, errorMsg)
    local side = LastGroupSide
    local groupbox
    
    if side == "Left" then
        groupbox = tab:AddLeftGroupbox("❌ " .. addonName, "alert-circle")
        LastGroupSide = "Right"
    else
        groupbox = tab:AddRightGroupbox("❌ " .. addonName, "alert-circle")
        LastGroupSide = "Left"
    end

    groupbox:AddLabel("Erro ao carregar addon", false)
    groupbox:AddBlankSpace()
    
    local errorLabel = groupbox:AddLabel(errorMsg, true)
    errorLabel:SetSize(12)
    
    groupbox:AddBlankSpace()
    groupbox:AddButton({
        Text = "Copy Error",
        Func = function()
            if setclipboard then
                setclipboard(errorMsg)
                print("[msdoors] Error copied to clipboard")
            else
                print("[msdoors] The setclipboard function is not available.")
            end
        end,
        Risky = false
    })
end

function AddonsAPI:CreateAddonContainer(addon)
    local tab = self:CreateAddonTab()
    local side = addon.Side or LastGroupSide
    local title = addon.Title or addon.Name
    local icon = addon.Icon
    
    local groupbox
    if side == "Left" then
        groupbox = tab:AddLeftGroupbox(title, icon)
        LastGroupSide = "Right"
    else
        groupbox = tab:AddRightGroupbox(title, icon)
        LastGroupSide = "Left"
    end

    if addon.Description then
        groupbox:AddLabel(addon.Description, true)
    end

    if addon.Author then
        local authors = type(addon.Author) == "table" and table.concat(addon.Author, ", ") or tostring(addon.Author)
        groupbox:AddLabel("By: " .. authors)
    end

    if addon.Version then
        groupbox:AddLabel("Version: " .. tostring(addon.Version))
    end

    if addon.Description or addon.Author or addon.Version then
        groupbox:AddDivider()
    end

    return groupbox
end

function AddonsAPI:LoadAddon(filePath)
    local fileName = filePath:match("([^/]+)$")
    
    local success, result = pcall(function()
        local fileContent = readfile(filePath)
        local addonFunc, loadErr = loadstring(fileContent)
        
        if not addonFunc then
            error("Syntax error: " .. tostring(loadErr))
        end

        setfenv(addonFunc, _G)
        return addonFunc()
    end)

    if not success then
        local errorMsg = string.format("[msdoors] Failed to load '%s':\n%s", fileName, tostring(result))
        warn(errorMsg)
        
        local tab = self:CreateAddonTab()
        local addonName = fileName:gsub("%.luau?$", ""):gsub("%.txt$", "")
        self:CreateErrorUI(tab, addonName, tostring(result))
        
        return false
    end

    local addon = result
    local isValid, validError = self:ValidateAddon(addon, fileName)
    if not isValid then
        local errorMsg = string.format("[msdoors] Validation failed '%s': %s", fileName, validError)
        warn(errorMsg)
        
        local tab = self:CreateAddonTab()
        local addonName = fileName:gsub("%.luau?$", ""):gsub("%.txt$", "")
        self:CreateErrorUI(tab, addonName, validError)
        
        return false
    end

    local addonName = addon.Name:gsub("%s+", "_"):gsub("[^%w_]", "")
    
    local containerSuccess, containerErr = pcall(function()
        local container = self:CreateAddonContainer(addon)
        self:LoadElements(container, addonName, addon.Elements)
        LoadedAddons[addonName] = addon
    end)

    if not containerSuccess then
        local errorMsg = string.format("[msdoors] Failed to create UI for '%s':\n%s", fileName, tostring(containerErr))
        warn(errorMsg)
        
        local tab = self:CreateAddonTab()
        self:CreateErrorUI(tab, addon.Name, tostring(containerErr))
        
        return false
    end

    return true
end

function AddonsAPI:LoadAddons()
    local files = listfiles("msdoors/addons")
    local loadCount = 0
    local failCount = 0

    for _, file in ipairs(files) do
        local ext = file:match("%.([^%.]+)$")
        if ext == "lua" or ext == "luau" or file:match("%.lua%.txt$") then
            if self:LoadAddon(file) then
                loadCount = loadCount + 1
            else
                failCount = failCount + 1
            end
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
end

getgenv().msaddons = AddonsAPI
return AddonsAPI
