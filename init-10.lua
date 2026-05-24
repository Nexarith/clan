-- mods/clan/init.lua

local path = core.get_modpath("clan")

-- Load files in order (Logic first, then UI, then Commands)
dofile(path .. "/clan.lua")
dofile(path .. "/members.lua")
dofile(path .. "/diplomacy.lua")
dofile(path .. "/ui.lua")
dofile(path .. "/commands.lua")

core.log("action", "[MOD] Clan System Loaded Successfully")