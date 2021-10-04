local function ASetTooltipMoney(tt, money, text)
    tt:AddDoubleLine(text, " ", 1, 1, 1)
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
    bmf:SetPoint("RIGHT", textRight)
    bmf:Show()
    
    local minWidth = textLeft:GetWidth() + bmf:GetWidth() + 10
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

local function AuctipusAddPrice(tt, itemID, n, onlyVendor)
    if IsShiftKeyDown() then
        n = 1
    end

    if not onlyVendor then
        local low, elapsed = Auctipus.API.GetAuctionCurrentBuyout(itemID)
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

    tt:Show()
end

-- Each of the different things we have to hook.
local HookMethods = {
    -- For items in your bags.
    ["SetBagItem"] = function(tt, bag, slot)
        local _, n, _, _, _, _, _, _, _, itemID =
            GetContainerItemInfo(bag, slot)
        if itemID then
            AuctipusAddPrice(tt, itemID, n)
        end
    end,

    -- For equipped item slots including bag slots.
    ["SetInventoryItem"] = function(tt, unit, i)
        local itemID = GetInventoryItemID(unit, i)
        if itemID then
            local n = 1
            if i == INVSLOT_AMMO then
                n = max(GetInventoryItemCount(unit, i), 1)
            end
            AuctipusAddPrice(tt, itemID, n)
        end
    end,

    -- For items in your guild bank.
    ["SetGuildBankItem"] = function(tt, tab, i)
        local link = GetGuildBankItemLink(tab, i)
        if link then
            local _, n = GetGuildBankItemInfo(tab, i)
            AuctipusAddPrice(tt, Auctipus.Link.GetItemID(link), n)
        end
    end,

    -- For when a vendor is open.
    ["SetMerchantItem"] = function(tt, i)
        local _, _, _, n = GetMerchantItemInfo(i)
        AuctipusAddPrice(tt, GetMerchantItemID(i), n)
    end,

    -- Any hyperlink.
    ["SetHyperlink"] = function(tt, link)
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

        AuctipusAddPrice(tt, Auctipus.Link.GetItemID(link), n, onlyVendor)
    end,

    -- Items in the vendor buyback tab as well as in the bottom of the main
    -- vendor tab.
    ["SetBuybackItem"] = function(tt, i)
        local itemID = C_MerchantFrame.GetBuybackItemID(i)
        if itemID then
            local _, _, _, n = GetBuybackItemInfo(i)
            AuctipusAddPrice(tt, itemID, n)
        end
    end,

    -- Items in the regular loot window when looting a corpse.
    ["SetLootItem"] = function(tt, i)
        if LootSlotHasItem(i) then
            local link    = GetLootSlotLink(i)
            local _, _, n = GetLootSlotInfo(i)
            AuctipusAddPrice(tt, Auctipus.Link.GetItemID(link), n)
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

        AuctipusAddPrice(tt, Auctipus.Link.GetItemID(link), n)
    end,

    -- Items in the quest log.
    ["SetQuestLogItem"] = function(tt, typ, i)
        local n, itemID
        if typ == "choice" then
            -- Quest rewards we can choose.
            local link = GetQuestLogItemLink(typ, i)
            _, _, n    = GetQuestLogChoiceInfo(i)
            itemID     = Auctipus.Link.GetItemID(link)
        else
            -- Mandatory quest rewards.
            _, _, n, _, _, itemID = GetQuestLogRewardInfo(i)
        end
        AuctipusAddPrice(tt, itemID, n)
    end,

    -- Items in the inbox.
    ["SetInboxItem"] = function(tt, i, ai)
        local _, itemID, _, n = GetInboxItem(i, ai or 1)
        AuctipusAddPrice(tt, itemID, n)
    end,

    -- Items attached to a message being composed.
    ["SetSendMailItem"] = function(tt, i)
        local _, itemID, _, n = GetSendMailItem(i)
        AuctipusAddPrice(tt, itemID, n)
    end,

    -- Action bar items.
    ["SetAction"] = function(tt, i)
        local typ, itemID, _ = GetActionInfo(i)
        if typ == "item" then
            AuctipusAddPrice(tt, itemID, max(GetActionCount(i), 1))
        end
    end,

    -- When rolling on an item in a party.
    ["SetLootRollItem"] = function(tt, i)
        local link    = GetLootRollItemLink(i)
        local _, _, n = GetLootRollItemInfo(i)
        AuctipusAddPrice(tt, Auctipus.Link.GetItemID(link), n)
    end,

    -- Items in our side of the trade window.
    ["SetTradePlayerItem"] = function(tt, i)
        local link = GetTradePlayerItemLink(i)
        if link then
            local _, _, n = GetTradePlayerItemInfo(i)
            AuctipusAddPrice(tt, Auctipus.Link.GetItemID(link), n)
        end
    end,

    -- Items in our target's side of the trade window.
    ["SetTradeTargetItem"] = function(tt, i)
        local link = GetTradeTargetItemLink(i)
        if link then
            local _, _, n = GetTradeTargetItemInfo(i)
            AuctipusAddPrice(tt, Auctipus.Link.GetItemID(link), n)
        end
    end,

    -- Items in a quest window when talking to a quest giver.
    ["SetQuestItem"] = function(tt, typ, i)
        local _, _, n = GetQuestItemInfo(typ, i)
        local link    = GetQuestItemLink(typ, i)
        AuctipusAddPrice(tt, Auctipus.Link.GetItemID(link), n)
    end,

    -- For reagents used in things like enchanting.
    ["SetCraftItem"] = function(tt, i, ri)
        local _, _, n = GetCraftReagentInfo(i, ri)
        local link    = GetCraftReagentItemLink(i, ri)
        AuctipusAddPrice(tt, Auctipus.Link.GetItemID(link), n)
    end,
}

-- Hook methods.
for k, f in pairs(HookMethods) do
    hooksecurefunc(GameTooltip, k, f)
end

hooksecurefunc("GameTooltip_ClearMoney", ATooltipClearMoney)
