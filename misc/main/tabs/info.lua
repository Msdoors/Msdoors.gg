local misctabs = {} -- SOGMA EZ

function misctabs:AddMiscTab(Tab)
    local GroupCredits = Tab:AddLeftGroupbox(shared.translationapi:getTranslate("tab_Credits", "Desenvolvedores"))
    local GroupContributors = Tab:AddLeftGroupbox(shared.translationapi:getTranslate("tab_Credits_Contributors", "Contribuidores"))
    local GroupTranslators = Tab:AddRightGroupbox(shared.translationapi:getTranslate("tab_Credits_Translators", "Tradutores"))

    --[[ DEVS ]]--
    local DevsCreditsRhyan = GroupCredits:AddLabel('<font color="#FFF700">[Rhyan57]</font> | OWNER ', true)
    local DevsCreditsSeek = GroupCredits:AddLabel('<font color="#FFF700">[SeekAlegriaFla]</font> | SUB-OWNER ', true)

    --[[ CONTRIBUTORS ]]--
    local EspecialCreditsSeikoso = GroupContributors:AddLabel('<font color="#00FF00">[Seikoso]</font> | It helped me with tips and to not give up on this script.', true)
    local EspecialCreditsJacob = GroupContributors:AddLabel('<font color="#00FF00">[Jacob]</font> | He is a great person and helped me with tips and optimizing some of the script functions.', true)
    local EspecialCreditsKardinCat = GroupContributors:AddLabel('<font color="#00FF00">[TheHunterSolo1]</font> | This guy made several changes to the Msdoors code and optimized it a lot, and also gave me several tips.', true)
    local EspecialCreditsG1gaBac0n = GroupContributors:AddLabel('<font color="#FF0000">[G1ga Bac0n]</font> | for a while he was my Tester and helped me find bugs in the script.', true)

    --[[ TRANSLATORS ]]--
    -- SOOON
end

return misctabs
