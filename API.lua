Auctipus.API = {}

--[[
-- Auctipus.API.GetAuctionBuyoutRange(itemID)
--
-- Takes a numeric itemID and returns a tuple:
--
--      minBuyout, maxBuyout, daysElapsed
--
-- Auctipus can scan the auction house multiple times during any given day.
-- For a given scan, we record the cheapest buyout for each item that was seen.
-- Since someone may then purchase that auction, a later scan may record a
-- cheapest buyout that is higher than the original scan.  Likewise, someone
-- may post an auction undercutting the original scan meaning that a later scan
-- may record a cheapest buyout that is lower than the original scan.
--
-- Auctipus records this range of "cheapest" buyouts in its daily history.
-- minBuyout and maxBuyout are the bounds of this "cheapest" buyout range.  In
-- particular, maxBuyout is NOT the highest buyout price seen for an item, but
-- rather is the high bound of the cheapest buyout prices seen for an item.
--
-- Auctipus.API.GetAuctionBuyoutRange() returns only information from the most
-- recent scan that included this item.  The daysElapsed return value tells us
-- how many days have elapsed since that most recent scan; a value of 0
-- indicates that the item was seen today while a value of 1 indicates an item
-- was seen yesterday, etc.
--]]
function Auctipus.API.GetAuctionBuyoutRange(itemID)
    local matches = Auctipus.History:MatchByItemID(itemID)
    if #matches == 0 then
        return nil
    end

    local match     = matches[1]
    local matchDate = match.history[#match.history][1]
    local minBuyout = match.history[#match.history][2]
    local maxBuyout = match.history[#match.history][3]
    for i, m in pairs(matches) do
        local mDate = m.history[#m.history][1]
        if mDate > matchDate then
            match     = m
            matchDate = mDate
            minBuyout = match.history[#match.history][2]
            maxBuyout = match.history[#match.history][3]
        elseif mDate == matchDate then
            minBuyout = min(minBuyout, m.history[#m.history][2])
            maxBuyout = max(maxBuyout, m.history[#m.history][3])
        end
    end

    local today = Auctipus.History:GetServerDay()
    return floor(minBuyout + 0.5), floor(maxBuyout + 0.5), today - matchDate
end

function Auctipus.API.GetAuctionCurrentBuyout(itemID)
    local matches = Auctipus.History:MatchByItemID(itemID)
    if #matches == 0 then
        return nil
    end

    local match     = matches[1]
    local matchDate = match.history[#match.history][1]
    local minBuyout = match.history[-1]
    for i, m in pairs(matches) do
        local mDate = m.history[#m.history][1]
        if mDate > matchDate then
            match     = m
            matchDate = mDate
            minBuyout = match.history[-1]
        elseif mDate == matchDate then
            minBuyout = min(minBuyout, m.history[-1])
        end
    end

    local today = Auctipus.History:GetServerDay()
    return floor(minBuyout + 0.5), today - matchDate
end
