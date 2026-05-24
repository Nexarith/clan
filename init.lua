-- mods/clan/init.lua

local path = core.get_modpath("clan")

-- Load core files in correct order
dofile(path .. "/clan.lua")        -- Core data, creation, teleport, etc.
dofile(path .. "/members.lua")     -- Members, promote, kick, requests
dofile(path .. "/diplomacy.lua")   -- Alliances, enemies, war, surrender
dofile(path .. "/ui.lua")          -- Forms and UI handling
dofile(path .. "/commands.lua")    -- Chat commands

core.log("action", "[MOD] Clan System Loaded Successfully")

-- Print a welcome message to server console
core.log("action", "Clan system ready!")
