--- Puggy TBC Raid Data
local TBC = Puggy.Modules["TBC"]

TBC.RaidData = {
    ["Karazhan"] = {
        name = "Karazhan",
        shortName = "KZ",
        size = 10,
        bosses = {
            ["Attumen"] = { name = "Attumen the Huntsman" },
            ["Moroes"] = { name = "Moroes" },
            ["Maiden"] = { name = "Maiden of Virtue" },
            ["Opera"] = { name = "Opera Event" },
            ["Curator"] = { name = "The Curator" },
            ["Illhoof"] = { name = "Terestian Illhoof" },
            ["Aran"] = { name = "Shade of Aran" },
            ["Netherspite"] = { name = "Netherspite" },
            ["Malchezaar"] = { name = "Prince Malchezaar" },
            ["Nightbane"] = { name = "Nightbane" },
        },
        templates = {
            ["Standard"] = {
                name = "Standard Setup",
                description = "Standard 2 tank, 3 healer, 5 dps setup",
                constraints = {
                    { type = "CLASS_COUNT", class = "WARRIOR", min = 1 },
                    { type = "ROLE_COUNT", role = "HEALER", count = 3 },
                }
            }
        }
    },
    ["Gruul"] = {
        name = "Gruul's Lair",
        shortName = "Gruul",
        size = 25,
        bosses = {
            ["Maulgar"] = { name = "High King Maulgar" },
            ["Gruul"] = { name = "Gruul the Dragonkiller" },
        }
    }
}
