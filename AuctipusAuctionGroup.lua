AuctipusAuctionGroup = {}
AuctipusAuctionGroup.__index = AuctipusAuctionGroup

function AuctipusAuctionGroup:New(auction)
    local g = {name              = auction.name,
               texture           = auction.texture,
               quality           = auction.quality,
               canUse            = auction.canUse,
               level             = auction.level,
               levelColHeader    = auction.levelColHeader,
               itemId            = auction.itemId,
               link              = auction.link,
               maxCount          = 0,
               buyableCount      = 0,
               auctions          = {},
               unitPriceAuctions = {},
               buyoutAuctions    = {},
               searcher          = ASearcher:New(auction.name), 
               }
    setmetatable(g, self)

    return g
end

function AuctipusAuctionGroup:AddAuction(auction)
    assert(auction.name           == self.name)
    assert(auction.texture        == self.texture)
    assert(auction.quality        == self.quality)
    assert(auction.canUse         == self.canUse)
    assert(auction.level          == self.level)
    assert(auction.levelColHeader == self.levelColHeader)
    assert(auction.itemId         == self.itemId)
    assert(auction.link           == self.link)

    table.insert(self.auctions, auction)
    if auction.buyoutPrice > 0 then
        table.insert(self.buyoutAuctions, auction)
        table.insert(self.unitPriceAuctions, auction)
        if auction:IsBuyable() then
            self.buyableCount = self.buyableCount + auction.count
        end
    end
    self.maxCount        = max(self.maxCount, auction.count)
    auction.auctionGroup = self
end

function AuctipusAuctionGroup:RecomputeBuyableCount()
    self.buyableCount = 0
    for i, auction in ipairs(self.auctions) do
        if auction:IsBuyable() then
            self.buyableCount = self.buyableCount + auction.count
        end
    end
end

function AuctipusAuctionGroup:SortByBuyout()
    table.sort(self.auctions, AAuction.LTBuyout)
    table.sort(self.buyoutAuctions, AAuction.LTBuyout)
    table.sort(self.unitPriceAuctions, AAuction.LTUnitPrice)

    for i, auction in ipairs(self.auctions) do
        auction.auctionIndex = i
    end
    for i, auction in ipairs(self.buyoutAuctions) do
        auction.buyoutIndex = i
    end
    for i, auction in ipairs(self.unitPriceAuctions) do
        auction.unitPriceIndex = i
    end
end

function AuctipusAuctionGroup:RemoveItem(auction)
    assert(auction.auctionIndex   ~= nil)
    assert(auction.buyoutIndex    ~= nil)
    assert(auction.unitPriceIndex ~= nil)

    table.remove(self.auctions,          auction.auctionIndex)
    table.remove(self.buyoutAuctions,    auction.buyoutIndex)
    table.remove(self.unitPriceAuctions, auction.unitPriceIndex)

    self:SortByBuyout()
end
