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
    local matches = AHistory:MatchByItemID(itemID)
    if #matches == 0 then
        return nil
    end

    assert(#matches == 1)
    local link  = matches[1]
    local today = AHistory:GetServerDay()
    local last  = link.history[#link.history]
    return last[2], last[3], today - last[1]
end
