-- mods/clan/diplomacy.lua
clan = clan or {}

-- Temporary table to store pending war/alliance requests until server restart
clan.pending_diplomacy = {} 

-- ==========================================
-- ALLIES (Step 4: Needs Confirmation)
-- ==========================================

function clan.request_alliance(sender_clan_name, target_clan_name)
    local target_c = clan.get_data(target_clan_name)
    if not target_c then return false, "Target clan does not exist." end

    -- Create a unique ID for this request
    local req_id = sender_clan_name .. "_to_" .. target_clan_name
    clan.pending_diplomacy[req_id] = {
        type = "alliance",
        from = sender_clan_name,
        to = target_clan_name
    }

    -- Notify the target leader (via Mail mod integration or Chat)
    core.chat_send_player(target_c.leader, 
        core.colorize("#ffff00", "[DIPLOMACY] Clan " .. sender_clan_name .. " requests an ALLIANCE. Check your Diplomacy menu."))
    
    return true, "Alliance request sent to " .. target_clan_name
end

function clan.accept_alliance(req_id)
    local req = clan.pending_diplomacy[req_id]
    if not req then return end

    local c1 = clan.get_data(req.from)
    local c2 = clan.get_data(req.to)

    table.insert(c1.allies, c2.name)
    table.insert(c2.allies, c1.name)

    clan.save_data(c1.name, c1)
    clan.save_data(c2.name, c2)
    clan.pending_diplomacy[req_id] = nil
    
    core.chat_send_all(core.colorize("#00ffff", "[CLAN NEWS] " .. c1.name .. " and " .. c2.name .. " are now ALLIES!"))
end

-- ==========================================
-- ENEMIES & THREATS (Step 4: Internal Only)
-- ==========================================

function clan.set_hostility(my_clan_name, target_clan_name, level)
    local c = clan.get_data(my_clan_name)
    if level == "enemy" then
        table.insert(c.enemies, target_clan_name)
    else
        table.insert(c.threats, target_clan_name)
    end
    
    clan.save_data(my_clan_name, c)

    -- Notify only YOUR clan members
    local msg = core.colorize("#ff4444", "[INTERNAL] " .. target_clan_name .. " is now marked as an " .. level:upper() .. "!")
    for _, m in ipairs(c.members) do
        core.chat_send_player(m, msg)
    end
end

-- ==========================================
-- WAR SYSTEM (Step 4: Confirmation & Surrender)
-- ==========================================

function clan.declare_war(sender_clan_name, target_clan_name)
    local target_c = clan.get_data(target_clan_name)
    local req_id = "war_" .. sender_clan_name .. "_" .. target_clan_name
    
    clan.pending_diplomacy[req_id] = {
        type = "war",
        from = sender_clan_name,
        to = target_clan_name
    }

    core.chat_send_player(target_c.leader, 
        core.colorize("#ff0000", "[WAR] " .. sender_clan_name .. " has declared WAR! Accept to begin the conflict."))
end

-- SURRENDER LOGIC (The Permanent Ban)
function clan.surrender(player_name)
    local c = clan.get_player_clan(player_name)
    if not c or c.leader ~= player_name then return false, "Only the leader can surrender." end

    -- Permanent Penalty: Mark player as banned from clans in ModStorage
    local storage = core.get_mod_storage()
    local banned_list = core.deserialize(storage:get_string("_clan_banned") or "{}") or {}
    banned_list[player_name] = true
    storage:set_string("_clan_banned", core.serialize(banned_list))

    -- Disband the clan immediately
    core.chat_send_all(core.colorize("#ff0000", "[WAR] " .. c.name .. " has surrendered! " .. player_name .. " is stripped of their rank forever."))
    
    -- Use the leave/disband logic from members.lua
    clan.leave(player_name) 
    return true
end

-- Check if player is banned (Use this in clan.create and clan.request_join)
function clan.is_banned(player_name)
    local storage = core.get_mod_storage()
    local banned_list = core.deserialize(storage:get_string("_clan_banned") or "{}") or {}
    return banned_list[player_name] == true
end