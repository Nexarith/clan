-- mods/clan/commands.lua

-- ==========================================
-- CLAN CHAT
-- ==========================================
function clan.chat(sender_name, message)
    local c = clan.get_player_clan(sender_name)
    if not c then
        return false, "You are not in a clan!"
    end

    local formatted_msg = core.colorize("#00ffff", "[Clan] " .. sender_name .. ": " .. message)

    for _, member_name in ipairs(c.members) do
        core.chat_send_player(member_name, formatted_msg)
    end

    return true
end

-- ==========================================
-- MAIN CLAN COMMAND (/c)
-- ==========================================
core.register_chatcommand("c", {
    params = "[create <name> | leave | chat <msg> | base | setbase]",
    description = "Clan management command - use /c to open UI",

    func = function(name, param)
        local player = core.get_player_by_name(name)
        if not player then
            return false, "Player not found."
        end

        -- Split command and arguments
        local cmd, target = param:match("^(%S+)%s*(.*)$")

        -- No parameters = Open UI
        if param == "" or not cmd then
            local c_data = clan.get_player_clan(name)
            if c_data then
                clan.ui.show_home(name)
            else
                clan.ui.show_no_clan(name)
            end
            return true
        end

        -- CREATE CLAN
        if cmd == "create" then
            if target == "" then
                return false, "Usage: /c create <clan_name>"
            end
            local success, msg = clan.create(name, target)
            return success, msg
        end

        -- LEAVE CLAN
        if cmd == "leave" then
            clan.ui.show_leave_confirm(name)
            return true
        end

        -- TELEPORT TO CLAN BASE
        if cmd == "base" then
            local success, msg = clan.teleport_to_base(name)
            return success, msg or "Teleported!"
        end

        -- SET CLAN BASE
        if cmd == "setbase" then
            local c = clan.get_player_clan(name)
            if c and (c.leader == name or table.contains(c.coleaders, name)) then
                c.home_pos = player:get_pos()
                clan.save_data(c.name, c)
                return true, "Clan base set to your current position!"
            else
                return false, "You don't have permission to set the clan base."
            end
        end

        -- CLAN CHAT
        if cmd == "chat" or cmd == "msg" then
            if target == "" then
                return false, "Usage: /c chat <message>"
            end
            return clan.chat(name, target)
        end

        return false, "Unknown subcommand. Use /c to open the clan menu."
    end,
})

-- ==========================================
-- QUICK CLAN CHAT COMMANDS
-- ==========================================
core.register_chatcommand("cc", {
    params = "<message>",
    description = "Send message to your clan members",
    func = function(name, param)
        if param == "" then
            return false, "Usage: /cc <message>"
        end
        return clan.chat(name, param)
    end,
})

core.register_chatcommand("cm", {
    params = "<message>",
    description = "Send message to your clan members",
    func = function(name, param)
        if param == "" then
            return false, "Usage: /cm <message>"
        end
        return clan.chat(name, param)
    end,
})

-- ==========================================
-- EXTRA COMMANDS (optional but useful)
-- ==========================================
core.register_chatcommand("clan", {
    description = "Alias for /c",
    func = function(name, param)
        return core.registered_chatcommands["c"].func(name, param)
    end,
})
