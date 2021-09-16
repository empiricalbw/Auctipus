Auctipus.Set = {}
Auctipus.Set.__index = Auctipus.Set
local ASet = Auctipus.Set

function ASet:New(elems)
    local aset = {elems        = {},
                  orderedElems = {},
                  }
    setmetatable(aset, self)

    if elems ~= nil then
        for i, e in ipairs(elems) do
            aset:Insert(e)
        end
    end

    return aset
end

function ASet:Size()
    return #self.orderedElems
end

function ASet:Empty()
    return self:Size() == 0
end

function ASet:Clear()
    self.elems        = {}
    self.orderedElems = {}
end

function ASet:Insert(elem)
    if not self:Contains(elem) then
        table.insert(self.orderedElems, elem)
        self.elems[elem] = #self.orderedElems
    end
end

function ASet:Contains(elem)
    return self.elems[elem] ~= nil
end

function ASet:Remove(elem)
    local index = self.elems[elem]
    if index ~= nil then
        self.elems[elem] = nil
        for i = index, #self.orderedElems - 1 do
            local elem = self.orderedElems[i + 1]
            self.orderedElems[i] = elem
            self.elems[elem]     = i
        end
        table.remove(self.orderedElems)
    end
end

function ASet:First()
    return self.orderedElems[1]
end

function ASet:Pop()
    if #self.orderedElems > 0 then
        local elem = self.orderedElems[1]
        self:Remove(elem)
        return elem
    end

    return nil
end

function ASet:Sort(compare)
    table.sort(self.orderedElems, compare)
    for i, elem in ipairs(self.orderedElems) do
        self.elems[elem] = i
    end
end
