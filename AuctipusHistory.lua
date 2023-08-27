Auctipus.History = {}
Auctipus.History.__index = Auctipus.History
local AHistory = Auctipus.History

-- Saved variables.
AUCTIPUS_ITEM_HISTORY_DB = {revision = 1, realms = {}}
AUCTIPUS_ITEM_HISTORY_DB_VERSION = 0    -- TOC version we are following
AUCTIPUS_IGNORED_SELLERS_DB = {}
AUCTIPUS_IGNORED_SELLERS = nil

-- Points at the saved variable for the current realm and faction.
local AUCTIPUS_ITEM_HISTORY = nil

-- A copy of AUCTIPUS_ITEM_HISTORY converted into Auctipus.Link objects during
-- ProcessDB().
local LOCAL_DB = {}

function AHistory.ProcessSavedVars()
    --Auctipus.info("Processing saved variables...")
    AHistory:UpdateDB()
    local rf = GetRealmName()..":"..UnitFactionGroup("player")
    local ih = AUCTIPUS_ITEM_HISTORY_DB.realms[rf] or {}
    local is = AUCTIPUS_IGNORED_SELLERS_DB[rf] or {}
    AUCTIPUS_ITEM_HISTORY = ih
    AUCTIPUS_ITEM_HISTORY_DB.realms[rf] = ih
    AUCTIPUS_IGNORED_SELLERS = is
    AUCTIPUS_IGNORED_SELLERS_DB[rf] = is
    AHistory:PruneDB()
    AHistory:ProcessDB()
    --Auctipus.info("Saved variables processed.")
end

function AHistory:GetServerDay()
    local serverTime = C_DateAndTime.GetServerTimeLocal()
    return floor(serverTime / (60*60*24))
end

function AHistory:FullScan()
    Auctipus.info("Initiating full scan...")
    self.scan = Auctipus.Scan:New({{getAll=true}}, self)
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
            if #hg > 0 and hg[#hg][1] >= serverDay then
                local elem = hg[#hg]
                elem[2] = min(elem[2], minUnitBuyout)
                elem[3] = max(elem[3], minUnitBuyout)
            else
                table.insert(hg, {serverDay, minUnitBuyout, minUnitBuyout})
            end
            hg[-1] = minUnitBuyout
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
    --[[
    --  AUCTIPUS_ITEM_HISTORY_DB structure:
    --
    --      {
    --          revision = 1,
    --          realms = {
    --              ["Realm1:Faction1"] = {
    --                  ["itemLink1"] = {
    --                      [-1] = lastScanPrice,
    --                      [1] = {serverDay1,
    --                             lowest minBuyout, highest minBuyout},
    --                      [2] = {serverDay2,
    --                             lowest minBuyout, highest minBuyout},
    --                      ...
    --                  },
    --                  ["itemLink2"] = {
    --                      [-1] = lastScanPrice,
    --                      [1] = {serverDay1,
    --                             lowest minBuyout, highest minBuyout},
    --                      [2] = {serverDay2,
    --                             lowest minBuyout, highest minBuyout},
    --                      ...
    --                  },
    --                  ...
    --              },
    --              ["RealmX:FactionY"] = {
    --                  ...
    --              },
    --          },
    --      }
    --
    --  Where:
    --      serverDayX is the AHistory:GetServerDay() value when the scan was
    --      taken.  Lowest and highest minBuyout is the range of minimum
    --      buyouts observed on that day.  Index -1 gives the price recorded
    --      in the most recent scan (whose serverDay is the same as the last
    --      entry in the array and whose price will be bounded by the lowest
    --      and highest prices in the last entry but may not be equal to either
    --      of them).
    --]]
    local versionStr, buildStr, dateStr, tocVersion = GetBuildInfo()

    -- Migrate old realm data to realms sub-table.
    if AUCTIPUS_ITEM_HISTORY_DB.realms == nil then
        AUCTIPUS_ITEM_HISTORY_DB = {
            revision = AUCTIPUS_ITEM_HISTORY_DB.revision,
            realms   = AUCTIPUS_ITEM_HISTORY_DB,
        }
        AUCTIPUS_ITEM_HISTORY_DB.realms.revision = nil
        Auctipus.info("Migrated database to realms sub-table.")
    end

    -- Migrate from first version to 2.5.2.
    if AUCTIPUS_ITEM_HISTORY_DB_VERSION < 20502 and tocVersion >= 20502 then
        AHistory:Update0To20502()
    end

    -- Migrate from 2.5.2 to 2.5.2r1.
    if (AUCTIPUS_ITEM_HISTORY_DB_VERSION == 20502 and
        AUCTIPUS_ITEM_HISTORY_DB.revision == nil)
    then
        AHistory:Update20502To20502_1()
    end
end

function AHistory:Update0To20502()
    -- In 2.5.2, an extra field was added to the end of item links.  Prior to
    -- 2.5.2 there would be 17 attributes in an item link.  Scan for old link
    -- formats in the database.
    assert(AUCTIPUS_ITEM_HISTORY_DB_VERSION < 20502)
    for realm, realmHistory in pairs(AUCTIPUS_ITEM_HISTORY_DB.realms) do
        local oldLinks = {}
        for link, history in pairs(realmHistory) do
            if Auctipus.Link.CountAttrs(link) == 17 then
                table.insert(oldLinks, link)
            end
        end

        -- Update the old links to new links and concatenate them into the
        -- database.
        for _, link in ipairs(oldLinks) do
            local newLink = Auctipus.Link.UpdateLink(link)
            assert(Auctipus.Link.CountAttrs(newLink) == 18)

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

function AHistory:Update20502To20502_1()
    -- We want to store the most recent scan's lowest buyout price in the
    -- history for tooltip use.  We synthesize it here.
    assert(AUCTIPUS_ITEM_HISTORY_DB_VERSION == 20502)
    for realm, realmHistory in pairs(AUCTIPUS_ITEM_HISTORY_DB.realms) do
        for link, history in pairs(realmHistory) do
            history[-1] = history[#history][2]
        end
    end

    AUCTIPUS_ITEM_HISTORY_DB.revision = 1
    Auctipus.info("Updated database to 2.5.2 revision 1.")
end

function AHistory:PruneDB()
    -- We want to prune all entries that are more than 30 days old.
    local cutoffDay = self:GetServerDay() - 30
    Auctipus.dbg("Cutoff day: "..tostring(cutoffDay))
    for link, history in pairs(AUCTIPUS_ITEM_HISTORY) do
        while #history > 1 and history[1][1] < cutoffDay do
            Auctipus.dbg("Removing expired history for "..link..".")
            table.remove(history, 1)
        end
    end
end

function AHistory:ProcessDB()
    local newDB = {}
    for link, history in pairs(AUCTIPUS_ITEM_HISTORY) do
        local l = Auctipus.Link:New(link)
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

function AHistory:MatchByItemID(itemID, suffixID)
    local matches = {}

    for i = 1, #LOCAL_DB do
        local elem = LOCAL_DB[i]
        if elem.itemId == itemID then
            if suffixID == nil or suffixID == elem.suffixID then
                table.insert(matches, elem)
            end
        end
    end

    return matches
end
