local misctabs = {}
local HttpService = game:GetService("HttpService")

function misctabs:AddMiscTab(Tab)
    local GroupCredits = Tab:AddLeftGroupbox(shared.translationapi:getTranslate("tab_Credits", "Desenvolvedores"))
    local GroupContributors = Tab:AddLeftGroupbox(shared.translationapi:getTranslate("tab_Credits_Contributors", "Contribuidores"))
    local GroupTranslators = Tab:AddRightGroupbox(shared.translationapi:getTranslate("tab_Credits_Translators", "Tradutores"))

    local DevsCreditsRhyan = GroupCredits:AddLabel('<font color="rgb(255, 87, 87)">[Rhyan57] | OWNER</font>', true)
    local DevsCreditsSeek = GroupCredits:AddLabel('<font color="rgb(255, 165, 0)">[SeekAlegriaFla] | SUB-OWNER</font>', true)

    local EspecialCreditsSeikoso = GroupContributors:AddLabel('<font color="rgb(138, 43, 226)">[Seikoso]</font> | It helped me with tips and to not give up on this script.', true)
    local EspecialCreditsJacob = GroupContributors:AddLabel('<font color="rgb(30, 144, 255)">[Jacob]</font> | He is a great person and helped me with tips and optimizing some of the script functions.', true)
    local EspecialCreditsKardinCat = GroupContributors:AddLabel('<font color="rgb(255, 20, 147)">[TheHunterSolo1]</font> | This guy made several changes to the Msdoors code and optimized it a lot, and also gave me several tips.', true)
    local EspecialCreditsG1gaBac0n = GroupContributors:AddLabel('<font color="rgb(50, 205, 50)">[G1ga Bac0n]</font> | for a while he was my Tester and helped me find bugs in the script.', true)

    local success, result = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/msdoors-gg/msdoors-translations/refs/heads/main/translators.json")
    end)

    if success and result then
        local translators = HttpService:JSONDecode(result)
        local isFirst = true
        
        for discordId, data in pairs(translators) do
            if not isFirst then
                GroupTranslators:AddDivider()
            end
            isFirst = false
            
            local colors = {
                "rgb(73, 230, 133)",
                "rgb(255, 107, 107)",
                "rgb(86, 204, 242)",
                "rgb(255, 184, 77)",
                "rgb(199, 125, 255)",
                "rgb(255, 121, 198)"
            }
            local colorIndex = (tonumber(discordId:sub(1, 3)) or 0) % #colors + 1
            local color = colors[colorIndex]
            
            GroupTranslators:AddLabel('<font color="' .. color .. '">' .. data.username .. '</font>', true)
            
            for langCode, langData in pairs(data.languages) do
                GroupTranslators:AddLabel('  • ' .. langData.displayName, true)
            end
        end
    end
end

function misctabs:AddWarnTabDoors(Tab)
    Tab:UpdateWarningBox({
        Title = shared.translationapi:getTranslate("Update Summary", "Resumo de Atualizações"),
        Icon = "layout-grid",
        Text = "[ ✓ ] It doesnt jump when using godmode.\n[ + ] Now the ESPs are fully synchronized.\n[ + ] We switched from MSESP to BOCAJESP (more optimized).\n[ + ] ESP subtitles no longer get smaller when the FOV is high (thanks to the new Library).\n[ + ] Now it doesnt glitch when finishing the circuit breaker game.\n[ + ] Optimized code\n[ + ] NOTIFY ANCHOR CODE\n[ + ] New auto-interaction (beta)\n» join our Discord to suggest features! «",
        IsNormal = true,
        Visible = true,
        LockSize = true,
    })
end

function misctabs:AddWarnTabNaturalDisaster(Tab)
    Tab:UpdateWarningBox({
        Title = shared.translationapi:getTranslate("Update Summary", "Resumo de Atualizações"),
        Icon = "layout-grid",
        Text = "[ ✓ ] FIXED NOTIFY DISASTERS\n[ ✓ ] FIXED ORBITAL PARTS\n[ ✓ ] FIXED TARGET PLAYERS\n[ ✓ ] OPTIMIZED\n» join our Discord to suggest features! «",
        IsNormal = true,
        Visible = true,
        LockSize = true,
    })
end

function misctabs:AddWarnTabCamposFFa(Tab)
    Tab:UpdateWarningBox({
        Title = shared.translationapi:getTranslate("Update Summary", "Resumo de Atualizações"),
        Icon = "layout-grid",
        Text = "Testing\n» join our Discord to suggest features! «",
        IsNormal = true,
        Visible = true,
        LockSize = true,
    })
end
return misctabs
