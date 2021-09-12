ALink = {}
ALink.__index = ALink

local function LinkDecode(l)
    local _, _, a, r, g, b, itemId = l:find("|c(..)(..)(..)(..)|Hitem:(%d+):")
    a = tonumber(a, 16)
    r = tonumber(r, 16)
    g = tonumber(g, 16)
    b = tonumber(b, 16)
    itemId = tonumber(itemId, 10)
    local _, _, _, _, texture = GetItemInfoInstant(itemId)
    return itemId, texture, CreateColor(r / 255, g / 255, b / 255, a / 255)
end

function ALink:New(l)
    local al = {
        link = ALink.SaneLink(l),
        name = ALink.GetLinkName(l),
    }
    al.itemId, al.texture, al.color = LinkDecode(l)
    al.uname = al.name:upper()
    setmetatable(al, self)

    return al
end

function ALink.GetLinkName(l)
    local _, _, name = l:find("|h%[(.*)%]|h")
    return name
end

function ALink.SaneLink(l)
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

function ALink.CountAttrs(l)
    -- Counts the number of colon-separated attributes in the hyperlink.
    local attrs = l:match("|Hitem:(.*)|h.*|h|r")
    return select(2, attrs:gsub(":", "")) + 1
end

function ALink.UpdateLink(l)
    -- In 2.5.2, an extra field was added to item links.  Unknown what is in
    -- this field, but we need to update old links to support it.
    if ALink.CountAttrs(l) >= 18 then
        return l
    end

    return l:gsub("|Hitem:(.*)|h(.*)|h|r", "|Hitem:%1:|h%2|h|r")
end
