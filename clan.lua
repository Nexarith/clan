-- mods/clan/clan.lua
clan = clan or {}

local storage = core.get_mod_storage()

-- ==========================================
-- DATA HANDLING (Storage)
-- ==========================================

function clan.get_data(clan_name)
    local raw = storage:get_string(clan_name)
    if raw == "" then
        return nil
    end

    return core.deserialize(raw)
end

function clan.save_data(clan_name, data)
    storage:set_string(clan_name, core.serialize(data))
end

function clan.get_all_clans()
    local list_raw = storage:get_string("_clan_list")

    if list_raw == "" then
        return {}
    end

    return core.deserialize(list_raw)
end

function clan.get_player_clan(player_name)
    local all = clan.get_all_clans()

    for _, name in ipairs(all) do
        local data = clan.get_data(name)

        if data then
            for _, member in ipairs(data.members) do
                if member == player_name then
                    return data
                end
            end
        end
    end

    return nil
end

-- ==========================================
-- HELPERS
-- ==========================================

function table.contains(t, val)
    for _, v in ipairs(t) do
        if v == val then
            return true
        end
    end

    return false
end

-- ==========================================
-- CLAN CREATION
-- ==========================================

function clan.create(player_name, clan_name)

    -- Check if clan already exists
    if clan.get_data(clan_name) then
        return false, "Clan name already exists!"
    end

    -- Check if player already in a clan
    if clan.get_player_clan(player_name) then
        return false, "You are already in a clan!"
    end

    -- Pay 100 Jeans Coins
    local success = jeans_economy.book(
        player_name,
        "!SERVER!",
        100,
        "Clan Creation Fee: " .. clan_name
    )

    if not success then
        return false, "You do not have 100 Jeans Coins!"
    end

    -- Create clan data
    local data = {
        name = clan_name,
        leader = player_name,
        coleaders = {},
        elders = {},
        members = {player_name},
        pending_requests = {},
        allies = {},
        enemies = {},
        threats = {},
        level = 0,
        max_members = 10,
        home_pos = nil,
    }

    -- Save clan
    clan.save_data(clan_name, data)

    -- Update global clan list
    local list = clan.get_all_clans()
    table.insert(list, clan_name)

    storage:set_string("_clan_list", core.serialize(list))

    return true, "Clan '" .. clan_name .. "' created for 100 Jeans Coins!"
end

-- ==========================================
-- UPGRADE LOGIC
-- ==========================================

function clan.upgrade_limit(player_name)
    local c = clan.get_player_clan(player_name)

    if not c then
        return false, "You are not in a clan."
    end

    -- Only leader or co-leaders
    if c.leader ~= player_name and not table.contains(c.coleaders, player_name) then
        return false, "Only staff can upgrade the clan."
    end

    -- Max cap
    if c.max_members >= 50 then
        return false, "Maximum limit (50) already reached!"
    end

    -- Pay upgrade fee
    local success = jeans_economy.book(
        player_name,
        "!SERVER!",
        100,
        "Clan Member Limit Upgrade"
    )

    if not success then
        return false, "You need 100 Jeans Coins to upgrade."
    end

    -- Upgrade
    c.max_members = c.max_members + 10

    clan.save_data(c.name, c)

    -- Check level-up
    clan.check_level_up(c.name)

    return true, "Limit upgraded to " .. c.max_members
end

-- ==========================================
-- LEAVE CLAN
-- ==========================================

function clan.leave(player_name)
    local c = clan.get_player_clan(player_name)

    if not c then
        return false, "You aren't in a clan."
    end

    -- Leaders cannot leave
    if c.leader == player_name then
        return false, "Leaders cannot leave! Transfer leadership first."
    end

    -- Remove member
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
-- LEVEL SYSTEM
-- ==========================================

function clan.check_level_up(clan_name)
    local c = clan.get_data(clan_name)

    if not c then
        return
    end

    if c.max_members >= 50 and c.level == 0 then
        c.level = 1

        clan.save_data(clan_name, c)

        core.chat_send_all(
            "The clan " .. clan_name .. " has reached Level 1!"
        )
    end
end

-- ==========================================
-- ONLINE MEMBER COUNT
-- ==========================================

function clan.get_online_count(clan_name)
    local c = clan.get_data(clan_name)

    if not c then
        return 0
    end

    local count = 0

    for _, m in ipairs(c.members) do
        if core.get_player_by_name(m) then
            count = count + 1
        end
    end

    return count
end