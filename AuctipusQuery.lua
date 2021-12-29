Auctipus.Query = {}
Auctipus.Query.__index = Auctipus.Query

function Auctipus.Query:New(q)
    setmetatable(q, self)
    return q
end

function Auctipus.Query:AddFilter(classID, subClassID, invType)
    if type(invType) == "table" then
        for i=1, #invType do
            table.insert(self.filters, {classID       = classID,
                                        subClassID    = subClassID,
                                        inventoryType = invType[i]})
        end
    else
        table.insert(self.filters, {classID       = classID,
                                    subClassID    = subClassID,
                                    inventoryType = invType})
    end
end

function Auctipus.Query:GetFilterIndexPath(f)
    for i, p in ipairs(Auctipus.Paths.paths) do
        local classID, subClassID, invType = unpack(p.path)
        if (f.classID    == classID and
            f.subClassID == subClassID and
            f.invType    == invType)
        then
            return i, p
        end
    end
end

function Auctipus.Query:IsSame(q)
    if (self.text:upper() ~= q.text:upper() or
        self.minLevel     ~= q.minLevel or
        self.maxLevel     ~= q.maxLevel or
        self.rarity       ~= q.rarity or
        self.usable       ~= q.usable or
        #self.filters     ~= #q.filters)
    then
        return false
    end

    for i=1, #self.filters do
        local f1 = self.filters[i]
        local f2 = q.filters[i]
        if (f1.classID       ~= f2.classID or
            f1.subClassID    ~= f2.subClassID or
            f1.inventoryType ~= f2.inventoryType)
        then
            return false
        end
    end

    return true
end

function Auctipus.Query:ToString()
    if self.userTitle then
        return "|cFF00FFFF"..self.userTitle.."|r"
    end

    local sections = {}
    local colorStart = 2
    if self.text ~= "" then
        table.insert(sections, self.text)
    else
        colorStart = 1
    end
    if self.minLevel > 0 and self.maxLevel > 0 then
        table.insert(sections, "["..self.minLevel.." - "..self.maxLevel.."]")
    elseif self.minLevel > 0 then
        table.insert(sections, "["..self.minLevel.." - ]")
    elseif self.maxLevel > 0 then
        table.insert(sections, "[ - "..self.maxLevel.."]")
    end
    if self.rarity >= 0 then
        table.insert(sections,
                     "[".._G["ITEM_QUALITY"..self.rarity.."_DESC"].."]")
    end
    if self.usable then
        table.insert(sections, "[Usable]")
    end
    if #self.filters > 0 then
        local names = {}
        for _, f in ipairs(self.filters) do
            local _, p = self:GetFilterIndexPath(f)
            if p then
                table.insert(names, p.name)
            end
        end
        table.insert(sections, "["..table.concat(names, ", ").."]")
    end
    if #sections >= colorStart then
        sections[colorStart] = "|cFFFFFF80"..sections[colorStart]
        sections[#sections]  = sections[#sections].."|r"
    end

    return table.concat(sections, " ")
end
