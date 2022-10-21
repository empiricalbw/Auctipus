-- DE Tables taken from:
-- https://wowpedia.fandom.com/wiki/Disenchanting_tables

-- Item links.
local STRANGE_DUST            = "|cffffffff|Hitem:10940::::::::70:::::::::|h[Strange Dust]|h|r"
local SOUL_DUST               = "|cffffffff|Hitem:11083::::::::70:::::::::|h[Soul Dust]|h|r"
local VISION_DUST             = "|cffffffff|Hitem:11137::::::::70:::::::::|h[Vision Dust]|h|r"
local DREAM_DUST              = "|cffffffff|Hitem:11176::::::::70:::::::::|h[Dream Dust]|h|r"
local ILLUSION_DUST           = "|cffffffff|Hitem:16204::::::::70:::::::::|h[Illusion Dust]|h|r"
local ARCANE_DUST             = "|cffffffff|Hitem:22445::::::::70:::::::::|h[Arcane Dust]|h|r"
local INFINITE_DUST           = "|cffffffff|Hitem:34054::::::::70:::::::::|h[Infinite Dust]|h|r"

local LESSER_MAGIC_ESSENCE    = "|cff1eff00|Hitem:10938::::::::70:::::::::|h[Lesser Magic Essence]|h|r"
local GREATER_MAGIC_ESSENCE   = "|cff1eff00|Hitem:10939::::::::70:::::::::|h[Greater Magic Essence]|h|r"
local LESSER_ASTRAL_ESSENCE   = "|cff1eff00|Hitem:10998::::::::70:::::::::|h[Lesser Astral Essence]|h|r"
local GREATER_ASTRAL_ESSENCE  = "|cff1eff00|Hitem:11082::::::::70:::::::::|h[Greater Astral Essence]|h|r"
local LESSER_MYSTIC_ESSENCE   = "|cff1eff00|Hitem:11134::::::::70:::::::::|h[Lesser Mystic Essence]|h|r"
local GREATER_MYSTIC_ESSENCE  = "|cff1eff00|Hitem:11135::::::::70:::::::::|h[Greater Mystic Essence]|h|r"
local LESSER_NETHER_ESSENCE   = "|cff1eff00|Hitem:11174::::::::70:::::::::|h[Lesser Nether Essence]|h|r"
local GREATER_NETHER_ESSENCE  = "|cff1eff00|Hitem:11175::::::::70:::::::::|h[Greater Nether Essence]|h|r"
local LESSER_ETERNAL_ESSENCE  = "|cff1eff00|Hitem:16202::::::::70:::::::::|h[Lesser Eternal Essence]|h|r"
local GREATER_ETERNAL_ESSENCE = "|cff1eff00|Hitem:16203::::::::70:::::::::|h[Greater Eternal Essence]|h|r"
local LESSER_PLANAR_ESSENCE   = "|cff1eff00|Hitem:22447::::::::70:::::::::|h[Lesser Planar Essence]|h|r"
local GREATER_PLANAR_ESSENCE  = "|cff1eff00|Hitem:22446::::::::70:::::::::|h[Greater Planar Essence]|h|r"
local LESSER_COSMIC_ESSENCE   = "|cff1eff00|Hitem:34056::::::::70:::::::::|h[Lesser Cosmic Essence]|h|r"
local GREATER_COSMIC_ESSENCE  = "|cff1eff00|Hitem:34055::::::::70:::::::::|h[Greater Cosmic Essence]|h|r"

local SMALL_GLIMMERING_SHARD  = "|cff0070dd|Hitem:10978::::::::70:::::::::|h[Small Glimmering Shard]|h|r"
local LARGE_GLIMMERING_SHARD  = "|cff0070dd|Hitem:11084::::::::70:::::::::|h[Large Glimmering Shard]|h|r"
local SMALL_GLOWING_SHARD     = "|cff0070dd|Hitem:11138::::::::70:::::::::|h[Small Glowing Shard]|h|r"
local LARGE_GLOWING_SHARD     = "|cff0070dd|Hitem:11139::::::::70:::::::::|h[Large Glowing Shard]|h|r"
local SMALL_RADIANT_SHARD     = "|cff0070dd|Hitem:11177::::::::70:::::::::|h[Small Radiant Shard]|h|r"
local LARGE_RADIANT_SHARD     = "|cff0070dd|Hitem:11178::::::::70:::::::::|h[Large Radiant Shard]|h|r"
local SMALL_BRILLIANT_SHARD   = "|cff0070dd|Hitem:14343::::::::70:::::::::|h[Small Brilliant Shard]|h|r"
local LARGE_BRILLIANT_SHARD   = "|cff0070dd|Hitem:14344::::::::70:::::::::|h[Large Brilliant Shard]|h|r"
local SMALL_PRISMATIC_SHARD   = "|cff0070dd|Hitem:22448::::::::70:::::::::|h[Small Prismatic Shard]|h|r"
local LARGE_PRISMATIC_SHARD   = "|cff0070dd|Hitem:22449::::::::70:::::::::|h[Large Prismatic Shard]|h|r"
local SMALL_DREAM_SHARD       = "|cff0070dd|Hitem:34053::::::::70:::::::::|h[Small Dream Shard]|h|r"
local DREAM_SHARD             = "|cff0070dd|Hitem:34052::::::::70:::::::::|h[Dream Shard]|h|r"
local NEXUS_CRYSTAL           = "|cffa335ee|Hitem:20725::::::::70:::::::::|h[Nexus Crystal]|h|r"
local VOID_CRYSTAL            = "|cffa335ee|Hitem:22450::::::::70:::::::::|h[Void Crystal]|h|r"
local ABYSS_CRYSTAL           = "|cffa335ee|Hitem:34057::::::::70:::::::::|h[Abyss Crystal]|h|r"

-- Green Armor
local GREEN_ARMOR = {
    {ilvl=15,  results={{link=STRANGE_DUST,            percent=80, min=1, max=2},
                        {link=LESSER_MAGIC_ESSENCE,    percent=20, min=1, max=2}}},
    {ilvl=20,  results={{link=STRANGE_DUST,            percent=75, min=2, max=3},
                        {link=GREATER_MAGIC_ESSENCE,   percent=20, min=1, max=2},
                        {link=SMALL_GLIMMERING_SHARD,  percent=5,  min=1, max=1}}},
    {ilvl=25,  results={{link=STRANGE_DUST,            percent=75, min=4, max=6},
                        {link=LESSER_ASTRAL_ESSENCE,   percent=15, min=1, max=2},
                        {link=SMALL_GLIMMERING_SHARD,  percent=10, min=1, max=1}}},
    {ilvl=30,  results={{link=SOUL_DUST,               percent=75, min=1, max=2},
                        {link=GREATER_ASTRAL_ESSENCE,  percent=20, min=1, max=2},
                        {link=LARGE_GLIMMERING_SHARD,  percent=5,  min=1, max=1}}},
    {ilvl=35,  results={{link=SOUL_DUST,               percent=75, min=2, max=5},
                        {link=LESSER_MYSTIC_ESSENCE,   percent=20, min=1, max=2},
                        {link=SMALL_GLOWING_SHARD,     percent=5,  min=1, max=1}}},
    {ilvl=40,  results={{link=VISION_DUST,             percent=75, min=1, max=2},
                        {link=GREATER_MYSTIC_ESSENCE,  percent=20, min=1, max=2},
                        {link=LARGE_GLOWING_SHARD,     percent=5,  min=1, max=1}}},
    {ilvl=45,  results={{link=VISION_DUST,             percent=75, min=2, max=5},
                        {link=LESSER_NETHER_ESSENCE,   percent=20, min=1, max=2},
                        {link=SMALL_RADIANT_SHARD,     percent=5,  min=1, max=1}}},
    {ilvl=50,  results={{link=DREAM_DUST,              percent=75, min=1, max=2},
                        {link=GREATER_NETHER_ESSENCE,  percent=20, min=1, max=2},
                        {link=LARGE_RADIANT_SHARD,     percent=5,  min=1, max=1}}},
    {ilvl=55,  results={{link=DREAM_DUST,              percent=75, min=1, max=2},
                        {link=LESSER_ETERNAL_ESSENCE,  percent=20, min=1, max=2},
                        {link=SMALL_BRILLIANT_SHARD,   percent=5,  min=1, max=1}}},
    {ilvl=60,  results={{link=ILLUSION_DUST,           percent=75, min=1, max=2},
                        {link=GREATER_ETERNAL_ESSENCE, percent=20, min=1, max=2},
                        {link=LARGE_BRILLIANT_SHARD,   percent=5,  min=1, max=1}}},
    {ilvl=65,  results={{link=ILLUSION_DUST,           percent=75, min=2, max=5},
                        {link=GREATER_ETERNAL_ESSENCE, percent=20, min=2, max=3},
                        {link=LARGE_BRILLIANT_SHARD,   percent=5,  min=1, max=1}}},
    {ilvl=79,  results={{link=ARCANE_DUST,             percent=75, min=1, max=2},
                        {link=LESSER_PLANAR_ESSENCE,   percent=20, min=1, max=2},
                        {link=SMALL_PRISMATIC_SHARD,   percent=5,  min=1, max=1}}},
    {ilvl=99,  results={{link=ARCANE_DUST,             percent=75, min=2, max=3},
                        {link=LESSER_PLANAR_ESSENCE,   percent=20, min=2, max=3},
                        {link=SMALL_PRISMATIC_SHARD,   percent=5,  min=1, max=1}}},
    {ilvl=120, results={{link=ARCANE_DUST,             percent=75, min=2, max=5},
                        {link=GREATER_PLANAR_ESSENCE,  percent=20, min=1, max=2},
                        {link=LARGE_PRISMATIC_SHARD,   percent=5,  min=1, max=1}}},
    {ilvl=151, results={{link=INFINITE_DUST,           percent=75, min=1, max=3},
                        {link=LESSER_COSMIC_ESSENCE,   percent=22, min=1, max=2},
                        {link=SMALL_DREAM_SHARD,       percent=3,  min=1, max=1}}},
    {ilvl=200, results={{link=INFINITE_DUST,           percent=75, min=4, max=7},
                        {link=GREATER_COSMIC_ESSENCE,  percent=22, min=1, max=2},
                        {link=DREAM_SHARD,             percent=3,  min=1, max=1}}},
}

-- Green Weapon
local GREEN_WEAPON = {
    {ilvl=15,  results={{link=STRANGE_DUST,            percent=20, min=1, max=2},
                        {link=LESSER_MAGIC_ESSENCE,    percent=80, min=1, max=2}}},
    {ilvl=20,  results={{link=STRANGE_DUST,            percent=20, min=2, max=3},
                        {link=GREATER_MAGIC_ESSENCE,   percent=75, min=1, max=2},
                        {link=SMALL_GLIMMERING_SHARD,  percent=5,  min=1, max=1}}},
    {ilvl=25,  results={{link=STRANGE_DUST,            percent=15, min=4, max=6},
                        {link=LESSER_ASTRAL_ESSENCE,   percent=75, min=1, max=2},
                        {link=SMALL_GLIMMERING_SHARD,  percent=10, min=1, max=1}}},
    {ilvl=30,  results={{link=SOUL_DUST,               percent=20, min=1, max=2},
                        {link=GREATER_ASTRAL_ESSENCE,  percent=75, min=1, max=2},
                        {link=LARGE_GLIMMERING_SHARD,  percent=5,  min=1, max=1}}},
    {ilvl=35,  results={{link=SOUL_DUST,               percent=20, min=2, max=5},
                        {link=LESSER_MYSTIC_ESSENCE,   percent=75, min=1, max=2},
                        {link=SMALL_GLOWING_SHARD,     percent=5,  min=1, max=1}}},
    {ilvl=40,  results={{link=VISION_DUST,             percent=20, min=1, max=2},
                        {link=GREATER_MYSTIC_ESSENCE,  percent=75, min=1, max=2},
                        {link=LARGE_GLOWING_SHARD,     percent=5,  min=1, max=1}}},
    {ilvl=45,  results={{link=VISION_DUST,             percent=20, min=2, max=5},
                        {link=LESSER_NETHER_ESSENCE,   percent=75, min=1, max=2},
                        {link=SMALL_RADIANT_SHARD,     percent=5,  min=1, max=1}}},
    {ilvl=50,  results={{link=DREAM_DUST,              percent=20, min=1, max=2},
                        {link=GREATER_NETHER_ESSENCE,  percent=75, min=1, max=2},
                        {link=LARGE_RADIANT_SHARD,     percent=5,  min=1, max=1}}},
    {ilvl=55,  results={{link=DREAM_DUST,              percent=20, min=1, max=2},
                        {link=LESSER_ETERNAL_ESSENCE,  percent=75, min=1, max=2},
                        {link=SMALL_BRILLIANT_SHARD,   percent=5,  min=1, max=1}}},
    {ilvl=60,  results={{link=ILLUSION_DUST,           percent=20, min=1, max=2},
                        {link=GREATER_ETERNAL_ESSENCE, percent=75, min=1, max=2},
                        {link=LARGE_BRILLIANT_SHARD,   percent=5,  min=1, max=1}}},
    {ilvl=65,  results={{link=ILLUSION_DUST,           percent=20, min=2, max=5},
                        {link=GREATER_ETERNAL_ESSENCE, percent=75, min=2, max=3},
                        {link=LARGE_BRILLIANT_SHARD,   percent=5,  min=1, max=1}}},
    {ilvl=99,  results={{link=ARCANE_DUST,             percent=20, min=2, max=3},
                        {link=LESSER_PLANAR_ESSENCE,   percent=75, min=2, max=3},
                        {link=SMALL_PRISMATIC_SHARD,   percent=5,  min=1, max=1}}},
    {ilvl=120, results={{link=ARCANE_DUST,             percent=20, min=2, max=5},
                        {link=GREATER_PLANAR_ESSENCE,  percent=75, min=1, max=2},
                        {link=LARGE_PRISMATIC_SHARD,   percent=5,  min=1, max=1}}},
    {ilvl=151, results={{link=INFINITE_DUST,           percent=22, min=1, max=3},
                        {link=LESSER_COSMIC_ESSENCE,   percent=75, min=1, max=2},
                        {link=SMALL_DREAM_SHARD,       percent=3,  min=1, max=1}}},
    {ilvl=200, results={{link=INFINITE_DUST,           percent=22, min=4, max=7},
                        {link=GREATER_COSMIC_ESSENCE,  percent=75, min=1, max=2},
                        {link=DREAM_SHARD,             percent=3,  min=1, max=1}}},
}

-- Rares (armor or weapon use the same table).
local RARE = {
    {ilvl=25,  results={{link=SMALL_GLIMMERING_SHARD,   percent=100,  min=1, max=1}}},
    {ilvl=30,  results={{link=LARGE_GLIMMERING_SHARD,   percent=100,  min=1, max=1}}},
    {ilvl=35,  results={{link=SMALL_GLOWING_SHARD,      percent=100,  min=1, max=1}}},
    {ilvl=40,  results={{link=LARGE_GLOWING_SHARD,      percent=100,  min=1, max=1}}},
    {ilvl=45,  results={{link=SMALL_RADIANT_SHARD,      percent=100,  min=1, max=1}}},
    {ilvl=50,  results={{link=LARGE_RADIANT_SHARD,      percent=100,  min=1, max=1}}},
    {ilvl=55,  results={{link=SMALL_BRILLIANT_SHARD,    percent=100,  min=1, max=1}}},
    {ilvl=65,  results={{link=LARGE_BRILLIANT_SHARD,    percent=99.5, min=1, max=1},
                        {link=NEXUS_CRYSTAL,            percent=0.5,  min=1, max=1}}},
    {ilvl=99,  results={{link=SMALL_PRISMATIC_SHARD,    percent=99.5, min=1, max=1},
                        {link=NEXUS_CRYSTAL,            percent=0.5,  min=1, max=1}}},
    {ilvl=120, results={{link=LARGE_PRISMATIC_SHARD,    percent=99.5, min=1, max=1},
                        {link=VOID_CRYSTAL,             percent=0.5,  min=1, max=1}}},
    {ilvl=164, results={{link=SMALL_DREAM_SHARD,        percent=99.5, min=1, max=1},
                        {link=ABYSS_CRYSTAL,            percent=0.5,  min=1, max=1}}},
    {ilvl=280, results={{link=DREAM_SHARD,              percent=99.5, min=1, max=1},
                        {link=ABYSS_CRYSTAL,            percent=0.5,  min=1, max=1}}},
}

-- Epic armor.
--  Up to iLvl 70 we can definitely get large brilliant shards: https://tbc.wowhead.com/item=19434/band-of-dark-dominion#disenchanting
local EPIC_ARMOR = {
    {ilvl=45,  results={{link=SMALL_RADIANT_SHARD,      percent=100, min=2, max=4}}},
    {ilvl=50,  results={{link=LARGE_RADIANT_SHARD,      percent=100, min=2, max=4}}},
    {ilvl=55,  results={{link=SMALL_BRILLIANT_SHARD,    percent=100, min=2, max=4}}},
    {ilvl=60,  results={{link=NEXUS_CRYSTAL,            percent=100, min=1, max=1}}},
    {ilvl=88,  results={{link=NEXUS_CRYSTAL,            percent=100, min=1, max=2}}},
    {ilvl=100, results={{link=VOID_CRYSTAL,             percent=100, min=1, max=2}}},
    -- iLvl 101-104 is missing. (This is because there is no epic armor in the range 101-104).
    -- This is really for 105-164 according to the table
    {ilvl=164, results={{link=VOID_CRYSTAL,             percent=33,  min=1, max=1},
                        {link=VOID_CRYSTAL,             percent=67,  min=2, max=2}}},
    {ilvl=280, results={{link=ABYSS_CRYSTAL,            percent=100, min=1, max=1}}},
}

-- Epic weapons.
local EPIC_WEAPON = {
    {ilvl=45,  results={{link=SMALL_RADIANT_SHARD,      percent=100, min=2, max=4}}},
    {ilvl=50,  results={{link=LARGE_RADIANT_SHARD,      percent=100, min=2, max=4}}},
    {ilvl=55,  results={{link=SMALL_BRILLIANT_SHARD,    percent=100, min=2, max=4}}},
    {ilvl=60,  results={{link=NEXUS_CRYSTAL,            percent=100, min=1, max=1}}},
    {ilvl=75,  results={{link=NEXUS_CRYSTAL,            percent=100, min=1, max=2}}},
    {ilvl=80,  results={{link=NEXUS_CRYSTAL,            percent=33,  min=1, max=1},
                        {link=NEXUS_CRYSTAL,            percent=67,  min=2, max=2}}},
    {ilvl=88,  results={{link=NEXUS_CRYSTAL,            percent=100, min=1, max=2}}},
    {ilvl=100, results={{link=VOID_CRYSTAL,             percent=100, min=1, max=2}}},
    -- iLvl 101-104 is missing.
    -- This is really for 105-164 according to the table
    {ilvl=164, results={{link=VOID_CRYSTAL,             percent=33,  min=1, max=1},
                        {link=VOID_CRYSTAL,             percent=67,  min=2, max=2}}},
    {ilvl=280, results={{link=ABYSS_CRYSTAL,            percent=100, min=1, max=1}}},
}

local DE_TABLE = {
    [Enum.ItemClass.Armor] = {
        [Enum.ItemQuality.Good] = GREEN_ARMOR,
        [Enum.ItemQuality.Rare] = RARE,
        [Enum.ItemQuality.Epic] = EPIC_ARMOR,
    },
    [Enum.ItemClass.Weapon] = {
        [Enum.ItemQuality.Good] = GREEN_WEAPON,
        [Enum.ItemQuality.Rare] = RARE,
        [Enum.ItemQuality.Epic] = EPIC_WEAPON,
    },
}

function AuctipusGetDEInfo(itemID)
    local _, _, itemQuality, _, _, _, _, _, _, _, _, classID, _, _, _, _, _ = GetItemInfo(itemID)

    local classTable = DE_TABLE[classID]
    if classTable == nil then
        return nil, nil
    end

    local classQualityTable = classTable[itemQuality]
    if classQualityTable == nil then
        return nil, nil
    end

    _, _, ilvl = GetDetailedItemLevelInfo(itemID)
    for _, entry in ipairs(classQualityTable) do
        if ilvl <= entry.ilvl then
            return ilvl, entry
        end
    end

    return ilvl, nil
end
