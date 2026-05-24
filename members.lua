-- mods/clan/members.lua
clan = clan or {}

-- ==========================================
-- PROMOTE / DEMOTION
-- ==========================================

function clan.promote(player_name, target_name)
    local c = clan.get_player_clan(player_name)
    if not c then return false, "You are not in a clan." end

    local is_leader = (c.leader == player_name)
    local is_coleader = table.contains(c.coleaders, player_name)

    if not is_leader and not is_coleader then
        return false, "Only Leader or Co-Leader can promote members."
    end

    -- Member → Elder
    if not table.contains(c.elders, target_name) and 
       not table.contains(c.coleaders, target_name) and 
       c.leader ~= target_name then
        
        table.insert(c.elders, target_name)
        clan.save_data(c.name, c)
        return true, target_name .. " has been promoted to Elder."
    end

    -- Elder → Co-Leader (Leader only)
    if is_leader and table.contains(c.elders, target_name) then
        for i, v in ipairs(c.elders) do
            if v == target_name then
                table.remove(c.elders, i)
                break
            end
        end
        table.insert(c.coleaders, target_name)
        clan.save_data(c.name, c)
        return true, target_name .. " has been promoted to Co-Leader."
    end

    return false, "Cannot promote this player further."
end

-- ==========================================
-- KICK MEMBER
-- ==========================================

function clan.kick(player_name, target_name)
    local c = clan.get_player_clan(player_name)
    if not c then return false, "You are not in a clan." end
    if target_name == c.leader then return false, "You cannot kick the leader." end

    -- Permission check
    local is_leader = (c.leader == player_name)
    local is_coleader = table.contains(c.coleaders, player_name)
    local is_elder = table.contains(c.elders, player_name)

    if not (is_leader or is_coleader or is_elder) then
        return false, "You don't have permission to kick members."
    end

    -- Remove from members
    for i, m in ipairs(c.members) do
        if m == target_name then
            table.remove(c.members, i)
            clan.save_data(c.name, c)
            core.chat_send_player(target_name, core.colorize("#ff0000", "You have been kicked from clan " .. c.name))
            return true, target_name .. " has been kicked from the clan."
        end
    end

    return false, "Player is not in your clan."
end

-- ==========================================
-- JOIN REQUESTS
-- ==========================================

function clan.request_join(player_name, clan_name)
    if clan.is_banned(player_name) then
        return false, "You are banned from joining clans."
    end

    local c = clan.get_data(clan_name)
    if not c then return false, "Clan does not exist." end

    if clan.get_player_clan(player_name) then
        return false, "You are already in a clan."
    end

    if #c.members >= c.max_members then
        return false, "Clan is full!"
    end

    -- Prevent duplicate requests
    if table.contains(c.pending_requests, player_name) then
        return false, "You already have a pending request."
    end

    table.insert(c.pending_requests, player_name)
    clan.save_data(clan_name, c)

    -- Notify clan staff
    local msg = core.colorize("#ffff00", "[CLAN] " .. player_name .. " has requested to join " .. clan_name)
    for _, m in ipairs(c.members) do
        if core.get_player_by_name(m) then
            core.chat_send_player(m, msg)
        end
    end

    return true, "Join request sent to " .. clan_name
end

function clan.accept_request(staff_name, applicant_name)
    local c = clan.get_player_clan(staff_name)
    if not c then return false, "You are not in a clan." end

    -- Permission: Leader, Co-Leader, or Elder
    local can_accept = (c.leader == staff_name) or
                       table.contains(c.coleaders, staff_name) or
                       table.contains(c.elders, staff_name)

    if not can_accept then
        return false, "Only staff (Elder+) can accept requests."
    end

    if not table.contains(c.pending_requests, applicant_name) then
        return false, "No pending request from this player."
    end

    -- Add to members
    table.insert(c.members, applicant_name)

    -- Remove from pending
    for i, v in ipairs(c.pending_requests) do
        if v == applicant_name then
            table.remove(c.pending_requests, i)
            break
        end
    end

    clan.save_data(c.name, c)

    core.chat_send_player(applicant_name, core.colorize("#00ff00", "✅ You have been accepted into clan " .. c.name))
    return true, applicant_name .. " has joined the clan."
end

-- ==========================================
-- DENY REQUEST (Helper)
-- ==========================================

function clan.deny_request(staff_name, applicant_name)
    local c = clan.get_player_clan(staff_name)
    if not c then return false end

    for i, v in ipairs(c.pending_requests) do
        if v == applicant_name then
            table.remove(c.pending_requests, i)
            clan.save_data(c.name, c)
            core.chat_send_player(applicant_name, core.colorize("#ff0000", "❌ Your join request to " .. c.name .. " was denied."))
            return true
        end
    end
    return false
endend

-- ==========================================
-- JOIN REQUESTS (Step 3)
-- ==========================================

function clan.request_join(player_name, clan_name)
    local c = clan.get_data(clan_name)
    if not c then return false, "Clan does not exist." end
    
    if #c.members >= c.max_members then
        return false, "Clan is full!"
    end

    table.insert(c.pending_requests, player_name)
    clan.save_data(clan_name, c)
    return true, "Request sent to " .. clan_name
end

function clan.accept_request(player_name, applicant_name)
    local c = clan.get_player_clan(player_name)
    -- Verify player is staff (Elder+)
    -- ...
    
    table.insert(c.members, applicant_name)
    -- Remove from pending
    for i, v in ipairs(c.pending_requests) do
        if v == applicant_name then table.remove(c.pending_requests, i) break end
    end
    
    clan.save_data(c.name, c)
    return true
end
