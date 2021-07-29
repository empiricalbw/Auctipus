ASearcher = {}
ASearcher.__index = ASearcher

local buyoutSearcher = nil

function ASearcher:New(name)
    local as = {
        targetAuction  = nil,
        targetIndex    = nil,
        handler        = nil,
        query          = {text       = name,
                          exactMatch = true,
                          filters    = {},
                          },
        searchQueue    = {},
        searchedPages  = ASet:New(),
        apage          = nil,
        lastPageSize   = nil,
        gotBidAccepted = nil,
        gotPageShrank  = nil,
        buyoutHandler  = nil,
    }
    setmetatable(as, self)

    return as
end

function ASearcher:FindAuction(auction, handler)
    assert(auction.name == self.query.text)

    self.targetAuction = auction
    self.targetIndex   = nil
    self.handler       = handler
    self.searchQueue   = {}
    self.searchedPages:Clear()
    if auction.buyoutIndex ~= nil then
        self:PushPage(floor((auction.buyoutIndex - 1) / 50))
    else
        self:PushPage(0)
    end

    self:LoadNextPage()
end

function ASearcher:CancelFind()
    self.targetAuction = nil
end

function ASearcher:PushPage(index)
    if not self.searchedPages:Contains(index) then
        table.insert(self.searchQueue, index)
    end
end

function ASearcher:PopPage()
    return table.remove(self.searchQueue)
end

function ASearcher:MarkPage(index)
    self.searchedPages:Insert(index)
end

function ASearcher:LoadNextPage()
    local index = self:PopPage()

    if self.apage then
        if not self.apage:IsLoading() and self.apage:IsActivePage() and
            self.apage.page == index
        then
            self:SearchPage()
            return
        end

        self.apage:ClosePage()
    end

    if index then
        self.lastPageSize = nil
        APage.OpenListPage(self.query, index, "BUYOUT", self)
        self:SearchPending()
    else
        self:SearchFailed()
    end
end

function ASearcher:PageOpened(p)
    self.apage = p
end

function ASearcher:PageUpdated(p)
    assert(p == self.apage)

    local prevLastPageSize = self.lastPageSize
    self.lastPageSize = #p.auctions

    if prevLastPageSize then
        if #p.auctions < prevLastPageSize then
            self:PageShrank()
        end
    end

    self:SearchPage()
end

function ASearcher:PageClosed(p, forced)
    assert(p == self.apage)
    self.apage = nil
    if forced and self.targetAuction then
        self:SearchAborted()
    end
end

function ASearcher:SearchPage()
    if self.targetAuction == nil then
        return
    end

    if #self.apage.nilAuctions > 0 then
        self:SearchPending()
        return
    end

    if #self.apage.auctions > 0 then
        local firstAuction = self.apage.auctions[1]
        local lastAuction  = self.apage.auctions[#self.apage.auctions]
        
        -- Check if the target auction comes before this page.
        local ctf = self.targetAuction:CompareByBuyout(firstAuction)
        if ctf == -1 then
            Auctipus.dbg("Target auction comes before this page.")
            Auctipus.dbg("First auction:")
            firstAuction:Print()

            if self.apage.page > 0 then
                self:PushPage(self.apage.page - 1)
            end
        end

        -- Check if the target auction comes after this page.
        local ctl = self.targetAuction:CompareByBuyout(lastAuction)
        if ctl == 1 then
            Auctipus.dbg("Target auction comes after this page.")
            Auctipus.dbg("Last auction:")
            lastAuction:Print()

            self:PushPage(self.apage.page + 1)
        end

        -- Check if the first auction is equivalent up to the item link (which
        -- may have different enchants).  Push the next-lowest page if
        -- possible, but don't return.
        if ctf == 0 and self.apage.page > 0 then
            self:PushPage(self.apage.page - 1)
        end

        -- Check if the last auction is equivalent up to the item link (which
        -- may have different enchants).  Push the next-highest page if
        -- possible, but don't return.
        if ctl == 0 then
            self:PushPage(self.apage.page + 1)
        end

        -- A matching auction could be on the current page, so search it.
        for i, a in ipairs(self.apage.auctions) do
            if self.targetAuction:Matches(a) then
                Auctipus.dbg("Found matching auction at index "..i.."!")
                self.targetAuction:Print()
                a:Print()

                self.targetIndex = i
                self.searchQueue = {}
                self.searchedPages:Clear()
                self:SearchSucceeded(i)
                return
            end
        end
    end

    -- No match, so continue searching.
    self:SearchPending()
    self:LoadNextPage()
end

function ASearcher:SearchPending()
    if self.handler then
        self.handler:SearchPending(self)
    end
end

function ASearcher:SearchSucceeded(index)
    if self.handler then
        self.handler:SearchSucceeded(self, self.apage.page, index)
    end
end

function ASearcher:SearchFailed()
    if self.handler then
        self.handler:SearchFailed(self)
    end
end

function ASearcher:SearchAborted()
    if self.handler then
        self.handler:SearchAborted(self)
    end
end

function ASearcher.CHAT_MSG_SYSTEM(msg)
    if buyoutSearcher ~= nil then
        if msg == ERR_AUCTION_BID_PLACED then
            Auctipus.dbg("Got bid placed event.")
            buyoutSearcher:BidAccepted()
        elseif msg == ERR_AUCTION_BID_OWN then
            Auctipus.dbg("Tried to bid on own auction.")
            buyoutSearcher:BidRejected()
        end
    end
end

function ASearcher:PlaceAuctionBid(copper)
    -- Places a bid on the currently-found auction.
    assert(self.targetIndex ~= nil)

    local auction = AAuction:FromGetAuctionItemInfo(self.targetIndex)
    assert(self.targetAuction:Matches(auction))

    PlaceAuctionBid("list", self.targetIndex, copper)
end

function ASearcher:BuyoutAuction(buyoutHandler)
    Auctipus.dbg("***** BUYING INDEX "..self.targetIndex.." *****")
    buyoutSearcher      = self
    self.buyoutHandler  = buyoutHandler
    self.gotBidAccepted = false
    self.gotPageShrank  = false
    self:PlaceAuctionBid(self.targetAuction.buyoutPrice)
end

function ASearcher:BidAccepted()
    assert(self == buyoutSearcher)
    self.gotBidAccepted = true
    if self.gotPageShrank then
        self:AuctionWon()
    end
end

function ASearcher:BidRejected()
    assert(self == buyoutSearcher)
    self:AuctionLost()
end

function ASearcher:PageShrank()
    assert(self == buyoutSearcher)
    self.gotPageShrank = true
    if self.gotBidAccepted then
        self:AuctionWon()
    end
end

function ASearcher:AuctionWon()
    assert(self == buyoutSearcher)
    buyoutSearcher = nil
    if self.buyoutHandler then
        self.buyoutHandler:AuctionWon(self)
    end
end

function ASearcher:AuctionLost()
    assert(self == buyoutSearcher)
    buyoutSearcher = nil
    if self.buyoutHandler then
        self.buyoutHandler:AuctionLost(self)
    end
end

TGEventManager.Register(ASearcher)
