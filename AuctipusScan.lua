AScan = {}
AScan.__index = AScan

function AScan:New(queries, handler)
    local as = {
        queries          = queries,
        query            = nil,
        handler          = handler,
        auctions         = {},
        auctionHash      = {},
        auctionHashOrder = {},
        auctionGroups    = {},
        startTime        = GetTime(),
        apage            = nil,
    }
    setmetatable(as, self)

    as:StartNextQuery()

    return as
end

function AScan:StartNextQuery()
    self.query = table.remove(self.queries)
    self.apage = APage.OpenListPage(self.query, 0, "QUALITY", self)
end

function AScan:LoadNextPage()
    self.apage = APage.OpenListPage(self.query, self.apage.page + 1, "QUALITY",
                                    self)
end

function AScan:PageUpdated(p)
    assert(self.apage == p)

    if #self.apage.nilAuctions > 0 then
        return
    end

    self.apage:ClosePage()

    local totalPages
    if self.query.getAll then
        totalPages = 0
        Auctipus.dbg("Got ALL page.")
    else
        totalPages = ceil(self.apage.totalAuctions / 50)
        Auctipus.dbg("Got page "..self.apage.page.." / "..totalPages)
        if self.handler then
            self.handler:ScanProgress(self, self.apage.page, totalPages)
        end
    end

    for i, auction in ipairs(self.apage.auctions) do
        if auction.hasAllInfo then
            table.insert(self.auctions, auction)
        end
    end

    if #self.apage.auctions > 0 and not self.query.getAll then
        self:LoadNextPage()
    elseif #self.queries > 0 then
        self:StartNextQuery()
    else
        self:ScanComplete()
    end
end

function AScan:PageClosed(p, forced)
    if forced and self.handler then
        self.handler:ScanAborted(self)
    end
end

function AScan:ScanComplete()
    self.apage       = nil
    self.elapsedTime = GetTime() - self.startTime

    for i, auction in ipairs(self.auctions) do
        local aag = self.auctionHash[auction.link]
        if not aag then
            aag = AuctipusAuctionGroup:New(auction)
            self.auctionHash[auction.link] = aag
            table.insert(self.auctionHashOrder, auction.link)
        end

        aag:AddAuction(auction)
    end

    for i, link in ipairs(self.auctionHashOrder) do
        table.insert(self.auctionGroups, self.auctionHash[link])
    end

    if self.handler then
        self.handler:ScanComplete(self)
    end
end
