-- mods/clan/diplomacy.lua
clan = clan or {}

-- Temporary storage for pending diplomacy requests (until server restart)
clan.pending_diplomacy = clan.pending_diplomacy or {}

-- ==========================================
-- ALLIANCE SYSTEM
-- ==========================================

function clan.request_alliance(sender_clan_name, target_clan_name)
    if sender_clan_name == target_clan_name then
        return false, "You cannot ally with your own clan."
    end

    local sender_c = clan.get_data(sender_clan_name)
    local target_c = clan.get_data(target_clan_name)

    if not target_c then return false, "Target clan does not exist." end

    -- Check if already allies
    if table.contains(sender_c.allies, target_clan_name) then
        return false, "You are already allies."
    end

    local req_id = sender_clan_name .. "_ally_" .. target_clan_name
    clan.pending_diplomacy[req_id] = {
        type = "alliance",
        from = sender_clan_name,
        to = target_clan_name
    }

    core.chat_send_player(target_c.leader,
        core.colorize("#ffff00", "[DIPLOMACY] Clan " .. sender_clan_name .. " requests an ALLIANCE with you."))

    return true, "Alliance request sent to " .. target_clan_name
end

function clan.accept_alliance(req_id)
    local req = clan.pending_diplomacy[req_id]
    if not req or req.type ~= "alliance" then return false, "Invalid request." end

    local c1 = clan.get_data(req.from)
    local c2 = clan.get_data(req.to)

    if not c1 or not c2 then return false, "One of the clans no longer exists." end

    table.insert(c1.allies, c2.name)
    table.insert(c2.allies, c1.name)

    clan.save_data(c1.name, c1)
    clan.save_data(c2.name, c2)
    clan.pending_diplomacy[req_id] = nil

    core.chat_send_all(core.colorize("#00ffff", "[CLAN NEWS] " .. c1.name .. " and " .. c2.name .. " are now ALLIES!"))
    return true, "Alliance accepted!"
end

-- ==========================================
-- HOSTILITY (Enemies & Threats)
-- ==========================================

function clan.set_hostility(my_clan_name, target_clan_name, level) -- level = "enemy" or "threat"
    local c = clan.get_data(my_clan_name)
    if not c then return false, "Clan not found." end

    if level == "enemy" then
        if not table.contains(c.enemies, target_clan_name) then
            table.insert(c.enemies, target_clan_name)
        end
    elseif level == "threat" then
        if not table.contains(c.threats, target_clan_name) then
            table.insert(c.threats, target_clan_name)
        end
    else
        return false, "Invalid hostility level."
    end

    clan.save_data(my_clan_name, c)

    local msg = core.colorize("#ff4444", "[INTERNAL] " .. target_clan_name .. " marked as " .. level:upper() .. "!")
    for _, m in ipairs(c.members) do
        core.chat_send_player(m, msg)
    end

    return true, target_clan_name .. " marked as " .. level .. "."
end

-- ==========================================
-- WAR SYSTEM
-- ==========================================

function clan.declare_war(sender_clan_name, target_clan_name)
    if sender_clan_name == target_clan_name then
        return false, "Cannot declare war on yourself."
    end

    local target_c = clan.get_data(target_clan_name)
    if not target_c then return false, "Target clan does not exist." end

    local req_id = "war_" .. sender_clan_name .. "_" .. target_clan_name

    clan.pending_diplomacy[req_id] = {
        type = "war",
        from = sender_clan_name,
        to = target_clan_name
    }

    core.chat_send_player(target_c.leader,
        core.colorize("#ff0000", "[WAR] " .. sender_clan_name .. " has declared WAR on your clan!"))

    return true, "War declared against " .. target_clan_name
end

-- ==========================================
-- SURRENDER (Permanent penalty)
-- ==========================================

function clan.surrender(player_name)
    local c = clan.get_player_clan(player_name)
    if not c or c.leader ~= player_name then
        return false, "Only the clan leader can surrender."
    end

    -- Mark leader as banned from clans
    local banned_list = core.deserialize(storage:get_string("_clan_banned") or "{}") or {}
    banned_list[player_name] = true
    storage:set_string("_clan_banned", core.serialize(banned_list))

    -- Disband clan
    local list = clan.get_all_clans()
    for i, name in ipairs(list) do
        if name == c.name then
            table.remove(list, i)
            break
        end
    end
    storage:set_string("_clan_list", core.serialize(list))
    storage:set_string(c.name, "")

    core.chat_send_all(core.colorize("#ff0000", "[WAR] Clan " .. c.name .. " has surrendered! Leader " .. player_name .. " is now banned from clans."))

    return true, "Clan surrendered and disbanded."
end

-- ==========================================
-- HELPER: Check pending diplomacy
-- ==========================================

function clan.get_pending_requests(clan_name)
    local pending = {}
    for id, req in pairs(clan.pending_diplomacy) do
        if req.to == clan_name then
            table.insert(pending, {id = id, req = req})
        end
    end
    return pending
end-- ==========================================
-- WAR SYSTEM
-- ==========================================

function clan.declare_war(sender_clan_name, target_clan_name)
    if sender_clan_name == target_clan_name then
        return false, "Cannot declare war on yourself."
    end

    local target_c = clan.get_data(target_clan_name)
    if not target_c then return false, "Target clan does not exist." end

    local req_id = "war_" .. sender_clan_name .. "_" .. target_clan_name

    clan.pending_diplomacy[req_id] = {
        type = "war",
        from = sender_clan_name,
        to = target_clan_name
    }

    core.chat_send_player(target_c.leader,
        core.colorize("#ff0000", "[WAR] " .. sender_clan_name .. " has declared WAR on your clan!"))

    return true, "War declared against " .. target_clan_name
end

-- ==========================================
-- SURRENDER (Permanent penalty)
-- ==========================================

function clan.surrender(player_name)
    local c = clan.get_player_clan(player_name)
    if not c or c.leader ~= player_name then
        return false, "Only the clan leader can surrender."
    end

    -- Mark leader as banned from clans
    local banned_list = core.deserialize(storage:get_string("_clan_banned") or "{}") or {}
    banned_list[player_name] = true
    storage:set_string("_clan_banned", core.serialize(banned_list))

    -- Disband clan
    local list = clan.get_all_clans()
    for i, name in ipairs(list) do
        if name == c.name then
            table.remove(list, i)
            break
        end
    end
    storage:set_string("_clan_list", core.serialize(list))
    storage:set_string(c.name, "")

    core.chat_send_all(core.colorize("#ff0000", "[WAR] Clan " .. c.name .. " has surrendered! Leader " .. player_name .. " is now banned from clans."))

    return true, "Clan surrendered and disbanded."
end

-- ==========================================
-- HELPER: Check pending diplomacy
-- ==========================================

function clan.get_pending_requests(clan_name)
    local pending = {}
    for id, req in pairs(clan.pending_diplomacy) do
        if req.to == clan_name then
            table.insert(pending, {id = id, req = req})
        end
    end
    return pending
endend
