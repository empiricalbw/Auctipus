AAuction = {}
AAuction.__index = AAuction

local function SaneLink(l)
    -- Remove the uniqueID, linkLevel and specializationID fields from the link
    -- since they contain no information usable by the client but can vary for
    -- items that otherwise seem identical.  An example is "Dreadhawk's
    -- Schynbald of the Hunt" which has different uniqueIDs.
    if not l then
        return nil
    end
    return l:gsub(
        "(|Hitem:[^:]+:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*):[^:]*:%d+:%d*",
        "%1::70:")
end

local function GoldString(c)
    local cost = ""
    if c >=10000 then
        cost = cost..floor(c / 10000).."g "
    end
    if c >= 100 then
        cost = cost..mod(floor(c / 100), 100).."s "
    end
    cost = cost..mod(c, 100).."c"

    return cost
end

function AAuction:FromGetAuctionItemInfo(index, list)
    list = list or "list"
    local name, texture, count, quality, canUse, level, levelColHeader, minBid,
        minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName,
        owner, ownerFullName, saleStatus, itemId, hasAllInfo =
            GetAuctionItemInfo(list, index)

    local aa = {name            = name,
                texture         = texture,
                count           = count,
                quality         = quality,
                canUse          = canUse,
                level           = level,
                levelColHeader  = levelColHeader,
                minBid          = minBid,
                minIncrement    = minIncrement,
                buyoutPrice     = buyoutPrice,
                unitPrice       = buyoutPrice / count,
                bidAmount       = bidAmount,
                highBidder      = highBidder,
                bidderFullName  = bidderFullName,
                owner           = owner,
                ownerFullName   = ownerFullName,
                saleStatus      = saleStatus,
                itemId          = itemId,
                hasAllInfo      = hasAllInfo,
                link            = SaneLink(GetAuctionItemLink(list, index)),
                duration        = GetAuctionItemTimeLeft(list, index),
                pageIndex       = index,
                missing         = false,
                }
    setmetatable(aa, self)

    return aa
end

function AAuction:ToString()
    local owner = self.owner
    if owner == nil then
        owner = "<NIL SELLER>"
    end
    return "Link: "..self.link.." Seller: "..owner.." Cost: "..
           GoldString(self.buyoutPrice)--[[.." Link: "..
           self.link:gsub("|","||")]]
end

function AAuction:Print()
    Auctipus.info(self:ToString())
end

function AAuction.CompareByBuyout(l, r)
    -- Compares two auctions based on their buyout price, item count and seller.
    -- Note that this doesn't compare things like the item name or item link;
    -- it's assumed that the client has already filtered these appropriately.
    if l.buyoutPrice ~= r.buyoutPrice then
        if l.buyoutPrice < r.buyoutPrice then
            return -1
        else
            return 1
        end
    end

    if l.count ~= r.count then
        if l.count < r.count then
            return -1
        else
            return 1
        end
    end

    if l.owner ~= r.owner then
        if l.owner < r.owner then
            return -1
        else
            return 1
        end
    end

    return 0
end

function AAuction.LTBuyout(l, r)
    return AAuction.CompareByBuyout(l, r) == -1
end

function AAuction.CompareByUnitPrice(l, r)
    -- Compares two auctions based on their unit price, item count and seller.
    -- Note that this doesn't compare things like the item name or item link;
    -- it's assumed that the client has already filtered these appropriately.
    if l.unitPrice ~= r.unitPrice then
        if l.unitPrice < r.unitPrice then
            return -1
        else
            return 1
        end
    end

    if l.count ~= r.count then
        if l.count < r.count then
            return -1
        else
            return 1
        end
    end

    if l.owner ~= r.owner then
        if l.owner < r.owner then
            return -1
        else
            return 1
        end
    end

    if l.unitPriceIndex ~= nil and r.unitPriceIndex ~= nil then
        if l.unitPriceIndex ~= r.unitPriceIndex then
            if l.unitPriceIndex < r.unitPriceIndex then
                return -1
            else
                return 1
            end
        end
    end

    return 0
end

function AAuction.LTUnitPrice(l, r)
    return AAuction.CompareByUnitPrice(l, r) == -1
end

function AAuction:Matches(a)
    return (self.count       == a.count and
            self.buyoutPrice == a.buyoutPrice and
            self.owner       == a.owner and
            self.link        == a.link)
end
