local BANK_MIN_ID = BankButtonIDToInvSlotID(1)
local BANK_MAX_ID = BankButtonIDToInvSlotID(NUM_BANKGENERIC_SLOTS)

local function ASetTooltipMoney(tt, money, text, text2, dx)
    text2 = text2 or " "
    dx    = dx or 0

    tt:AddDoubleLine(text, text2, 1, 1, 1, 1, 1, 1)
    local numLines  = tt:NumLines()
    local textRight = _G[tt:GetName().."TextRight"..numLines]
    local textLeft  = _G[tt:GetName().."TextLeft"..numLines]

    if not tt._auctipusFreeBMFFrames then
        tt._auctipusFreeBMFFrames = {}
        tt._auctipusUsedBMFFrames = {}
    end

    local bmf
    if #tt._auctipusFreeBMFFrames > 0 then
        bmf = table.remove(tt._auctipusFreeBMFFrames)
    else
        bmf = CreateFrame("Frame", nil, tt,
                          "BetterMoneyFrameFixedCollapsedTemplate")
    end
    table.insert(tt._auctipusUsedBMFFrames, bmf)
    bmf:SetMoney(money)
    bmf:SetPoint("RIGHT", textRight, "RIGHT", dx, 0)
    bmf:Show()
    
    local minWidth = textLeft:GetWidth() + bmf:GetWidth() + 10 - dx
    tt:SetMinimumWidth(max(tt:GetMinimumWidth(), minWidth))
end

local function ATooltipClearMoney(tt)
    if not tt._auctipusUsedBMFFrames then
        return
    end

    while #tt._auctipusUsedBMFFrames > 0 do
        local bmf = table.remove(tt._auctipusUsedBMFFrames)
        table.insert(tt._auctipusFreeBMFFrames, bmf)
        bmf:Hide()
    end
end

local function AuctipusAddPrice(tt, itemID, suffixID, n, onlyVendor)
    if IsShiftKeyDown() then
        n = 1
    end

    if not onlyVendor then
        local low, elapsed = Auctipus.API.GetAuctionCurrentBuyout(itemID,
                                                                  suffixID,
                                                                  true)
        if low then
            if elapsed == 0 then
                elapsed = "today"
            elseif elapsed == 1 then
                elapsed = "yesterday"
            else
                elapsed = ""..elapsed.." days ago"
            end
            ASetTooltipMoney(tt, low * n,
                             "Auctipus price for "..n.." ("..elapsed.."):")
        end
    end

    if AUCTIPUS_OPTIONS.showVendorPrice then
        local _, _, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(itemID)
        if vendorPrice then
            if vendorPrice > 0 then
                --print("Vendor price", vendorPrice)
                ASetTooltipMoney(tt, vendorPrice * n,
                                 "Vendor sell price for "..n..":")
            end
        else
            --print("Vendor price not known for", itemID)
        end
    end

    if AUCTIPUS_OPTIONS.showDisenchantInfo then
        local ilvl, deInfo = AuctipusGetDEInfo(itemID)
        if ilvl ~= nil then
            tt:AddLine(" ")
            tt:AddLine("Disenchanting ("..tostring(ilvl).."):")
            if deInfo ~= nil then
                local percentLen = 40
                for _, deEntry in ipairs(deInfo.results) do
                    if tostring(deEntry.percent):sub(-2) == ".5" then
                        percentLen = 50
                    end
                end

                for _, deEntry in ipairs(deInfo.results) do
                    local deID = Auctipus.Link.GetItemID(deEntry.link)
                    local low, _ = Auctipus.API.GetAuctionCurrentBuyout(deID)
                    local percent = tostring(deEntry.percent)
                    low = low or 0
                    ASetTooltipMoney(tt, low, 
                                     " "..tostring(deEntry.min).."-"..tostring(deEntry.max).." "..deEntry.link,
                                     tostring(deEntry.percent).."%",
                                     -percentLen)
                end
            else
                tt:AddLine("No DE info.")
            end
        end
    end

    tt:Show()
end

-- Each of the different things we have to hook.
local HookMethods = {
    -- For items in your bags.
    ["SetBagItem"] = function(tt, bag, slot)
        local _, n, _, _, _, _, link = GetContainerItemInfo(bag, slot)
        if link then
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- For equipped item slots including bag slots.
    ["SetInventoryItem"] = function(tt, unit, i)
        local link = GetInventoryItemLink(unit, i)
        if link then
            local n = 1
            if i == INVSLOT_AMMO or (BANK_MIN_ID <= i and i <= BANK_MAX_ID) then
                n = max(GetInventoryItemCount(unit, i), 1)
            end
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- For items in your guild bank.
    ["SetGuildBankItem"] = function(tt, tab, i)
        local link = GetGuildBankItemLink(tab, i)
        if link then
            local _, n = GetGuildBankItemInfo(tab, i)
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- For when a vendor is open.
    ["SetMerchantItem"] = function(tt, i)
        local link = GetMerchantItemLink(i)
        if link then
            local _, _, _, n = GetMerchantItemInfo(i)
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- Any hyperlink.
    ["SetHyperlink"] = function(tt, link)
        local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
        if not itemID then
            return
        end

        local owner      = tt:GetOwner()
        local onlyVendor = false
        local n          = 1
        if owner._is_auctipus then
            if owner.auctionGroup then
                onlyVendor = true
            elseif owner.count then
                n = owner.count
            end
        end

        AuctipusAddPrice(tt, itemID, suffixID, n, onlyVendor)
    end,

    -- Items in the vendor buyback tab as well as in the bottom of the main
    -- vendor tab.
    ["SetBuybackItem"] = function(tt, i)
        local itemID = C_MerchantFrame.GetBuybackItemID(i)
        if itemID then
            local _, _, _, n = GetBuybackItemInfo(i)
            local link = GetBuybackItemLink(i)
            local _, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- Items in the regular loot window when looting a corpse.
    ["SetLootItem"] = function(tt, i)
        if LootSlotHasItem(i) then
            local link    = GetLootSlotLink(i)
            local _, _, n = GetLootSlotInfo(i)
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- Reagents used to make an item as well as the item icon itself.
    ["SetTradeSkillItem"] = function(tt, skill, i)
        local link, n
        if i then
            link    = GetTradeSkillReagentItemLink(skill, i)
            _, _, n = GetTradeSkillReagentInfo(skill, i)
        else
            link = GetTradeSkillItemLink(skill)
            n    = GetTradeSkillNumMade(skill)
        end

        if link then
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- Items in the quest log.
    ["SetQuestLogItem"] = function(tt, typ, i)
        local link = GetQuestLogItemLink(typ, i)
        if link then
            local n
            if typ == "choice" then
                -- Quest rewards we can choose.
                _, _, n = GetQuestLogChoiceInfo(i)
            elseif typ == "reward" then
                -- Mandatory quest rewards.
                _, _, n = GetQuestLogRewardInfo(i)
            end
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- Items in the inbox.
    ["SetInboxItem"] = function(tt, i, ai)
        local link = GetInboxItemLink(i, ai or 1)
        if link then
            local _, _, _, n = GetInboxItem(i, ai or 1)
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- Items attached to a message being composed.
    ["SetSendMailItem"] = function(tt, i)
        local link = GetSendMailItemLink(i)
        if link then
            local _, _, _, n = GetSendMailItem(i)
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- Action bar items.
    -- There doesn't seem to be a way to get an item link for an item on the
    -- action bar.  Try our best; if we get multiple matches then
    -- AuctipusAddPrice won't add any at all.
    ["SetAction"] = function(tt, i)
        local typ, itemID, _ = GetActionInfo(i)
        if typ == "item" then
            AuctipusAddPrice(tt, itemID, nil, max(GetActionCount(i), 1))
        end
    end,

    -- When rolling on an item in a party.
    ["SetLootRollItem"] = function(tt, i)
        local link = GetLootRollItemLink(i)
        if link then
            local _, _, n = GetLootRollItemInfo(i)
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- Items in our side of the trade window.
    ["SetTradePlayerItem"] = function(tt, i)
        local link = GetTradePlayerItemLink(i)
        if link then
            local _, _, n = GetTradePlayerItemInfo(i)
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- Items in our target's side of the trade window.
    ["SetTradeTargetItem"] = function(tt, i)
        local link = GetTradeTargetItemLink(i)
        if link then
            local _, _, n = GetTradeTargetItemInfo(i)
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- Items in a quest window when talking to a quest giver.
    ["SetQuestItem"] = function(tt, typ, i)
        local link = GetQuestItemLink(typ, i)
        if link then
            local _, _, n = GetQuestItemInfo(typ, i)
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,

    -- For reagents used in things like enchanting.
    ["SetCraftItem"] = function(tt, i, ri)
        local link = GetCraftReagentItemLink(i, ri)
        if link then
            local _, _, n = GetCraftReagentInfo(i, ri)
            local itemID, suffixID = Auctipus.Link.GetItemAndSuffixIDs(link)
            AuctipusAddPrice(tt, itemID, suffixID, n)
        end
    end,
}

-- Hook methods.
for k, f in pairs(HookMethods) do
    hooksecurefunc(GameTooltip, k, f)
end

hooksecurefunc("GameTooltip_ClearMoney", ATooltipClearMoney)
