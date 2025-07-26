local StarterGui = game:GetService("StarterGui")

local function copyDiscord()
    local discordLink = "https://dsc.gg/msdoors-gg"
    
    if setclipboard then
        setclipboard(discordLink)
        return true
    elseif toclipboard then
        toclipboard(discordLink)
        return true
    end
    return false
end

local function showNotification()
    local copied = copyDiscord()
    
    if copied then
        StarterGui:SetCore("SendNotification", {
            Title = "⚠️ SCRIPT EM MANUTENÇÃO";
            Text = "MSDOORS API IS UNDER MAINTENANCE!";
            Icon = "rbxasset://95869322194132";
            Duration = 8;
        })
    else
        StarterGui:SetCore("SendNotification", {
            Title = "⚠️ SCRIPT EM MANUTENÇÃO";
            Text = "MSDOORS API IS UNDER MAINTENANCE!";
            Icon = "rbxasset://95869322194132";
            Duration = 10;
        })
    end
end

showNotification()
