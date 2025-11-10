local misctabs = {} -- SOGMA EZ

-- CREDITS, TRANSLATORS, ETC...
function misctabs:AddMiscTab(Tab)
    local GroupCredits = Tab:AddLeftGroupbox(shared.translationapi:getTranslate("tab_Credits", "Desenvolvedores"))
    local GroupContributors = Tab:AddLeftGroupbox(shared.translationapi:getTranslate("tab_Credits_Contributors", "Contribuidores"))
    local GroupTranslators = Tab:AddRightGroupbox(shared.translationapi:getTranslate("tab_Credits_Translators", "Tradutores"))

    --[[ DEVS ]]--
    local DevsCreditsRhyan = GroupCredits:AddLabel('[Rhyan57] | OWNER ', true)
    local DevsCreditsSeek = GroupCredits:AddLabel('[SeekAlegriaFla] | SUB-OWNER ', true)

    --[[ CONTRIBUTORS ]]--
    local EspecialCreditsSeikoso = GroupContributors:AddLabel('[Seikoso] | It helped me with tips and to not give up on this script.', true)
    local EspecialCreditsJacob = GroupContributors:AddLabel('[Jacob] | He is a great person and helped me with tips and optimizing some of the script functions.', true)
    local EspecialCreditsKardinCat = GroupContributors:AddLabel('[TheHunterSolo1] | This guy made several changes to the Msdoors code and optimized it a lot, and also gave me several tips.', true)
    local EspecialCreditsG1gaBac0n = GroupContributors:AddLabel('[G1ga Bac0n] | for a while he was my Tester and helped me find bugs in the script.', true)

    --[[ TRANSLATORS ]]--
    -- SOOON
end

-- SUMMARY UPDATE: DOORS
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
-- SUMMARY UPDATE: NATURAL DISASTER
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

return misctabs
