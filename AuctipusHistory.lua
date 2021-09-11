AHistory = {}
AHistory.__index = AHistory

-- Saved variables.
AUCTIPUS_ITEM_HISTORY_DB = {}
AUCTIPUS_ITEM_HISTORY_DB_VERSION = 0
AUCTIPUS_IGNORED_SELLERS_DB = {}
AUCTIPUS_IGNORED_SELLERS = nil

local AUCTIPUS_ITEM_HISTORY = nil
local LOCAL_DB = {}

function AHistory.ProcessSavedVars()
    Auctipus.info("Processing saved variables...")
    AHistory:UpdateDB()
    local rf = GetRealmName()..":"..UnitFactionGroup("player")
    local ih = AUCTIPUS_ITEM_HISTORY_DB[rf] or {}
    local is = AUCTIPUS_IGNORED_SELLERS_DB[rf] or {}
    AUCTIPUS_ITEM_HISTORY = ih
    AUCTIPUS_ITEM_HISTORY_DB[rf] = ih
    AUCTIPUS_IGNORED_SELLERS = is
    AUCTIPUS_IGNORED_SELLERS_DB[rf] = is
    AHistory:ProcessDB()
    Auctipus.info("Saved variables processed.")
end

function AHistory:GetServerDay()
    local serverTime = GetServerTime()
    return floor(serverTime / (60*60*24))
end

function AHistory:FullScan()
    Auctipus.info("Initiating full scan...")
    self.scan = AScan:New({{getAll=true}}, self)
end

function AHistory:ScanComplete(scan)
    local serverDay = self:GetServerDay()

    for _, ag in ipairs(scan.auctionGroups) do
        --[[
        for _, a in ipairs(ag.auctions) do
            if not a.owner then
                a:Print()
            end
        end
        ]]
        if #ag.unitPriceAuctions == 0 then
            Auctipus.dbg("Item "..ag.link.." has no buyout.")
        else
            ag:SortByBuyout()
            local hg = AUCTIPUS_ITEM_HISTORY[ag.link] or {}
            local minUnitBuyout = ag.unitPriceAuctions[1].unitPrice
            if #hg > 0 and hg[#hg][1] == serverDay then
                local elem = hg[#hg]
                elem[2] = min(elem[2], minUnitBuyout)
                elem[3] = max(elem[3], minUnitBuyout)
            else
                table.insert(hg, {serverDay, minUnitBuyout, minUnitBuyout})
            end
            AUCTIPUS_ITEM_HISTORY[ag.link] = hg
        end
    end

    self:ProcessDB()

    if scan.query.getAll then
        Auctipus.info("Full scan complete.")
    end
end

function AHistory:ScanAborted(scan)
    Auctipus.info("Scan aborted.")
end

function AHistory:UpdateDB()
    local versionStr, buildStr, dateStr, tocVersion = GetBuildInfo()

    if AUCTIPUS_ITEM_HISTORY_DB_VERSION < 20502 and tocVersion >= 20502 then
        AHistory:Update0To20502()
    end
end

function AHistory:Update0To20502()
    -- In 2.5.2, an extra field was added to the end of item links.  Prior to
    -- 2.5.2 there would be 17 attributes in an item link.  Scan for old link
    -- formats in the database.
    assert(AUCTIPUS_ITEM_HISTORY_DB_VERSION < 20502)
    for realm, realmHistory in pairs(AUCTIPUS_ITEM_HISTORY_DB) do
        local oldLinks = {}
        for link, history in pairs(realmHistory) do
            if ALink.CountAttrs(link) == 17 then
                table.insert(oldLinks, link)
            end
        end

        -- Update the old links to new links and concatenate them into the
        -- database.
        for _, link in ipairs(oldLinks) do
            local newLink = ALink.UpdateLink(link)
            assert(ALink.CountAttrs(newLink) == 18)

            local oldData = realmHistory[link]
            local newData = realmHistory[newLink] or {}

            if #newData > 0 then
                assert(newData[1][1] > oldData[#oldData][1])
            end

            for i=1, #newData do
                oldData[#oldData] = newData[i]
            end

            realmHistory[newLink] = oldData
            realmHistory[link]    = nil
        end
    end

    AUCTIPUS_ITEM_HISTORY_DB_VERSION = 20502
    Auctipus.info("Updated database to 2.5.2.")
end

function AHistory:ProcessDB()
    local newDB = {}
    for link, history in pairs(AUCTIPUS_ITEM_HISTORY) do
        local l = ALink:New(link)
        l.history = history
        table.insert(newDB, l)
    end
    LOCAL_DB = newDB
end

function AHistory:Match(substring)
    local matches = {}

    if substring:len() >= 2 then
        local s = substring:upper()
        for i = 1, #LOCAL_DB do
            local elem = LOCAL_DB[i]
            if elem.uname:find(s, 1, true) then
                table.insert(matches, elem)
            end
        end
    end

    return matches
end

function AHistory:MatchByItemID(itemID)
    local matches = {}

    for i = 1, #LOCAL_DB do
        local elem = LOCAL_DB[i]
        if elem.itemId == itemID then
            table.insert(matches, elem)
        end
    end

    return matches
end
