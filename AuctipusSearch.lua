--[[
--  Class for finding a specific auction in the AH so that you can place a bid
--  or buyout on it.  This tracks the target auction until the auction page has
--  stabilized and notifies as the auction page changes.  It allows you to buy
--  the auction and then notifies again once that succeeds (or fails) and the
--  page has re-stabilized.
--
--  Global error strings relevant to placing a bid or buyout:
--  
--  ERR_AUCTION_ALREADY_BID = "You have already bid on this item."
--  ERR_AUCTION_BID_INCREMENT = "Your bid increment is too small."
--  ERR_AUCTION_BID_OWN = "You cannot bid on your own auction."
--  ERR_AUCTION_DATABASE_ERROR = "Internal auction error."
--  ERR_AUCTION_HIGHER_BID = "There is already a higher bid on that item."
--  ERR_AUCTION_HOUSE_DISABLED =
--      "The auction house is closed at the moment.|nPlease try again later."
--  ERR_AUCTION_MIN_BID = "You must meet the min bid."
--
--  Global success string relevant to placing a bid or buyout:
--
--  ERR_AUCTION_BID_PLACED = "Bid accepted."
--
--  Global status strings relevant to the outcome of a prior bid:
--
--  ERR_AUCTION_WON_S = "You won an auction for %s"
--  ERR_AUCTION_OUTBID_S = "You have been outbid on %s."
--]]
ASearcher = {}
ASearcher.__index = ASearcher

local STATE_INITIAL                     = "STATE_INITIAL"
local STATE_WAIT_PAGE_STABLE            = "STATE_WAIT_PAGE_STABLE"
local STATE_WAIT_SELECTED               = "STATE_WAIT_SELECTED"
local STATE_WAIT_BUYOUT_RESULT          = "STATE_WAIT_BUYOUT_RESULT"
local STATE_WAIT_BUYOUT_RESULT_CLOSED   = "STATE_WAIT_BUYOUT_RESULT_CLOSED"
local STATE_INITIAL_OPENED              = "STATE_INITIAL_OPENED"

local buyoutSearcher = nil

function ASearcher:New(name)
    local as = {
        state             = nil,
        query             = {text       = name,
                             exactMatch = true,
                             filters    = {},
                             },
        ERR_AUCTION_WON   = ERR_AUCTION_WON_S:format(name),
        targetAuction     = nil,
        handler           = nil,
        searchQueue       = nil,
        searchedPages     = ASet:New(),
        apage             = nil,
        gotBidAcceptedMsg = nil,
        gotAuctionWonMsg  = nil,
        gotPageShrank     = nil,
        buyoutHandler     = nil,
    }
    setmetatable(as, self)

    as:_TRANSITION(STATE_INITIAL)

    return as
end

function ASearcher:_TRANSITION(newState)
    assert(newState)
    if self.state ~= newState then
        Auctipus.dbg("ASearcher: ", tostring(self.state), " -> ", newState)
        self.state = newState
    end
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
        if self.apage.page == index then
            self:SearchPage()
            return
        end

        self.apage:ClosePage()
    end

    if index then
        self.apage = APage.OpenListPage(self.query, index, "BUYOUT", self)
        self:_TRANSITION(STATE_WAIT_PAGE_STABLE)
        self:NotifySearchPending()
    else
        self:_TRANSITION(STATE_INITIAL)
        self:NotifySearchFailed()
    end
end

function ASearcher:SearchPage()
    if #self.apage.nilAuctions > 0 then
        self:_TRANSITION(STATE_WAIT_PAGE_STABLE)
        return
    end

    if #self.apage.auctions > 0 then
        -- Mark this page.
        self:MarkPage(self.apage.page)

        -- Auctions needed for edge checking.
        local firstAuction = self.apage.auctions[1]
        local lastAuction  = self.apage.auctions[#self.apage.auctions]
        
        -- Check if the target auction comes before this page.
        local ctf = self.targetAuction:CompareByBuyout(firstAuction)
        if ctf == -1 then
            Auctipus.dbg("Target auction comes before this page.")
            Auctipus.dbg("First auction:")
            firstAuction:DbgPrint()

            if self.apage.page > 0 then
                self:PushPage(self.apage.page - 1)
            end
        end

        -- Check if the target auction comes after this page.
        local ctl = self.targetAuction:CompareByBuyout(lastAuction)
        if ctl == 1 then
            Auctipus.dbg("Target auction comes after this page.")
            Auctipus.dbg("Last auction:")
            lastAuction:DbgPrint()

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
                self.targetAuction:DbgPrint()
                a:DbgPrint()

                self.apage:SelectItem(i)
                self.searchQueue = {}
                self.searchedPages:Clear()

                self:_TRANSITION(STATE_WAIT_SELECTED)
                self:NotifySearchSucceeded(i)
                return
            end
        end
    end

    -- No match, so continue searching.
    self:LoadNextPage()
end

function ASearcher:_PlaceAuctionBid(copper)
    -- Places a bid on the currently-found auction.
    local selectedItem = self.apage:GetSelectedItem()
    Auctipus.dbg("Selected auction item: "..selectedItem)

    local auction = AAuction:FromGetAuctionItemInfo(selectedItem)
    assert(self.targetAuction:Matches(auction))

    PlaceAuctionBid("list", selectedItem, copper)
end

function ASearcher:CheckBuyoutState()
    if self.state == STATE_WAIT_BUYOUT_RESULT then
        if self.gotBidAcceptedMsg and self.gotAuctionWonMsg and
           self.gotPageShrank and self.apage:GetSelectedItem() == 0
        then
            buyoutSearcher = nil
            self:_TRANSITION(STATE_INITIAL_OPENED)
            self:NotifyAuctionWon()
        end
    elseif self.state == STATE_WAIT_BUYOUT_RESULT_CLOSED then
        if self.gotBidAccepted and self.gotAuctionWonMsg then
            buyoutSearcher = nil
            self:_TRANSITION(STATE_INITIAL)
            self:NotifyAuctionWon()
        end
    else
        error("Unexpected CheckBuyoutState in "..self.state)
    end
end

function ASearcher:FindAuction(auction, handler)
    assert(auction.name == self.query.text)

    if self.state == STATE_WAIT_BUYOUT_RESULT or
       self.state == STATE_WAIT_BUYOUT_RESULT_CLOSED
    then
        error("FindAuction illegal in "..self.state)
    end

    if self.state == STATE_WAIT_PAGE_STABLE then
        self.apage:ClosePage()
    elseif self.state == STATE_WAIT_SELECTED then
        self.apage:SelectItem(0)
    end

    self.targetAuction = auction
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

function ASearcher:PageUpdated(p, delta)
    assert(p == self.apage)

    if self.state == STATE_INITIAL or
       self.state == STATE_WAIT_SELECTED or
       self.state == STATE_WAIT_BUYOUT_RESULT_CLOSED or
       self.state == STATE_INITIAL_OPENED
    then
        error("PageUpdated not expected in "..self.state)
    end

    if self.state == STATE_WAIT_PAGE_STABLE then
        assert(delta >= 0)
        self:SearchPage()
    elseif self.state == STATE_WAIT_BUYOUT_RESULT then
        assert(delta <= 0)
        if delta < 0 then
            self.gotPageShrank = true
            self:CheckBuyoutState()
        end
    end
end

function ASearcher:PageClosed(p, forced)
    assert(p == self.apage)
    self.apage = nil

    if forced == false then
        return
    end

    if self.state == STATE_INITIAL or
       self.state == STATE_WAIT_BUYOUT_RESULT_CLOSED
    then
        error("PageForceClosed not expected in "..self.state)
    end

    if self.state == STATE_WAIT_PAGE_STABLE or
       self.state == STATE_WAIT_SELECTED
    then
        self:_TRANSITION(STATE_INITIAL)
        self:NotifySearchAborted()
    elseif self.state == STATE_WAIT_BUYOUT_RESULT then
        self:_TRANSITION(STATE_WAIT_BUYOUT_RESULT_CLOSED)
        self:CheckBuyoutState()
    elseif self.state == STATE_INITIAL_OPENED then
        self:_TRANSITION(STATE_INITIAL)
    end
end

function ASearcher:BuyoutAuction(buyoutHandler)
    if self.state == STATE_INITIAL or
       self.state == STATE_WAIT_PAGE_STABLE or
       self.state == STATE_WAIT_BUYOUT_RESULT or
       self.state == STATE_WAIT_BUYOUT_RESULT_CLOSED or
       self.state == STATE_WAIT_INITIAL_OPENED
    then
        error("BuyoutAuction not expected in "..self.state)
    end

    assert(self.state == STATE_WAIT_SELECTED)
    assert(not buyoutSearcher)

    Auctipus.dbg("***** BUYING INDEX "..self.apage:GetSelectedItem().." *****")
    buyoutSearcher         = self
    self.buyoutHandler     = buyoutHandler
    self.gotBidAcceptedMsg = false
    self.gotAuctionWonMsg  = false
    self.gotPageShrank     = false
    self:_TRANSITION(STATE_WAIT_BUYOUT_RESULT)
    self:_PlaceAuctionBid(self.targetAuction.buyoutPrice)
end

function ASearcher.CHAT_MSG_SYSTEM(msg)
    local self = buyoutSearcher
    if not self then
        return
    end

    local stateGood = (self.state == STATE_WAIT_BUYOUT_RESULT or
                       self.state == STATE_WAIT_BUYOUT_RESULT_CLOSED)

    if msg == ERR_AUCTION_BID_PLACED then
        Auctipus.dbg("Got bid accepted event.")
        assert(stateGood)
        self.gotBidAcceptedMsg = true
        self:CheckBuyoutState()
    elseif msg == self.ERR_AUCTION_WON then
        Auctipus.dbg("Got auction won event.")
        assert(stateGood)
        self.gotAuctionWonMsg = true
        self:CheckBuyoutState()
    elseif msg == ERR_AUCTION_ALREADY_BID or
           msg == ERR_AUCTION_BID_INCREMENT or
           msg == ERR_AUCTION_BID_OWN or
           msg == ERR_AUCTION_DATABASE_ERROR or
           msg == ERR_AUCTION_HIGHER_BID or
           msg == ERR_AUCTION_HOUSE_DISABLED or
           msg == ERR_AUCTION_MIN_BID
    then
        Auctipus.dbg("Got bid rejected event.")
        buyoutSearcher = nil
        if self.state == STATE_WAIT_BUYOUT_RESULT then
            self.apage:ClosePage()
        end

        self:_TRANSITION(STATE_INITIAL)
        self:NotifyAuctionLost()
    end
end

function ASearcher:Reset()
    if self.state == STATE_WAIT_PAGE_STABLE or
       self.state == STATE_WAIT_SELECTED or
       self.state == STATE_INITIAL_OPENED
    then
        self.apage:ClosePage()
        self:_TRANSITION(STATE_INITIAL)
    elseif self.state == STATE_WAIT_BUYOUT_RESULT or
           self.state == STATE_WAIT_BUYOUT_RESULT_CLOSED
    then
        error("Cannot Reset in "..self.state)
    end
end

function ASearcher:NotifySearchPending()
    if self.handler then
        self.handler:SearchPending(self)
    end
end

function ASearcher:NotifySearchSucceeded(index)
    if self.handler then
        self.handler:SearchSucceeded(self, self.apage.page, index)
    end
end

function ASearcher:NotifySearchFailed()
    if self.handler then
        self.handler:SearchFailed(self)
    end
end

function ASearcher:NotifySearchAborted()
    if self.handler then
        self.handler:SearchAborted(self)
    end
end

function ASearcher:NotifyAuctionWon()
    if self.buyoutHandler then
        self.buyoutHandler:AuctionWon(self)
    end
end

function ASearcher:NotifyAuctionLost()
    if self.buyoutHandler then
        self.buyoutHandler:AuctionLost(self)
    end
end

AEventManager.Register(ASearcher)
