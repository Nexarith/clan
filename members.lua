-- mods/clan/members.lua
clan = clan or {}

-- ==========================================
-- PROMOTION / DEMOTION LOGIC
-- ==========================================

function clan.promote(player_name, target_name)
    local c = clan.get_player_clan(player_name)
    if not c then return false, "No clan found." end

    -- Only Leader or Co-Leader can promote
    local is_leader = (c.leader == player_name)
    local is_coleader = table.contains(c.coleaders, player_name)

    if not is_leader and not is_coleader then
        return false, "Insufficient permissions."
    end

    -- Member -> Elder
    if not table.contains(c.elders, target_name) and not table.contains(c.coleaders, target_name) and c.leader ~= target_name then
        table.insert(c.elders, target_name)
        clan.save_data(c.name, c)
        return true, target_name .. " promoted to Elder."
    end

    -- Elder -> Co-Leader (Leader only)
    if is_leader and table.contains(c.elders, target_name) then
        -- Remove from Elders, Add to Co-Leaders
        for i, v in ipairs(c.elders) do
            if v == target_name then table.remove(c.elders, i) break end
        end
        table.insert(c.coleaders, target_name)
        clan.save_data(c.name, c)
        return true, target_name .. " promoted to Co-Leader."
    end

    return false, "Cannot promote further."
end

-- ==========================================
-- KICK LOGIC
-- ==========================================

function clan.kick(player_name, target_name)
    local c = clan.get_player_clan(player_name)
    if not c or target_name == c.leader then return false end

    -- Logic: Leaders kick everyone, Co-Leaders kick Elders/Members, Elders kick Members
    -- Simplified check for this example:
    for i, m in ipairs(c.members) do
        if m == target_name then
            table.remove(c.members, i)
            clan.save_data(c.name, c)
            return true, target_name .. " has been kicked."
        end
    end
end

-- ==========================================
-- UPDATED LEAVE LOGIC (Leader Deletion)
-- ==========================================

function clan.leave(player_name)
    local c = clan.get_player_clan(player_name)
    if not c then return false, "You aren't in a clan." end

    -- Special case: Leader leaving
    if c.leader == player_name then
        if #c.members > 1 then
            return false, "You must transfer leadership before leaving a populated clan!"
        else
            -- Leader is alone, delete the clan
            local storage = core.get_mod_storage()
            local list = clan.get_all_clans()
            
            -- Remove from global list
            for i, name in ipairs(list) do
                if name == c.name then table.remove(list, i) break end
            end
            
            storage:set_string("_clan_list", core.serialize(list))
            storage:set_string(c.name, "") -- Delete data
            return true, "Clan disbanded."
        end
    end

    -- Standard member leaving
    for i, m in ipairs(c.members) do
        if m == player_name then
            table.remove(c.members, i)
            break
        end
    end

    clan.save_data(c.name, c)
    return true, "You left the clan."
end

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