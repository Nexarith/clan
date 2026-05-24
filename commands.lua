-- mods/clan/commands.lua

-- ==========================================
-- CLAN CHAT LOGIC
-- ==========================================
function clan.chat(sender_name, message)
    local c = clan.get_player_clan(sender_name)

    if not c then
        return false, "You are not in a clan!"
    end

    -- Format: [Clan] Shasha: yo defend base 💀
    local formatted_msg =
        core.colorize("#00ffff", "[Clan] " .. sender_name .. ": ") .. message

    for _, member_name in ipairs(c.members) do
        core.chat_send_player(member_name, formatted_msg)
    end

    return true
end


-- ==========================================
-- MAIN CLAN COMMAND (/c)
-- ==========================================
core.register_chatcommand("c", {
    params = "[create <name> / leave / chat / msg / base / setbase]",
    description = "Open Clan UI or use clan sub-commands",

    func = function(name, param)
        local player = core.get_player_by_name(name)

        if not player then
            return false, "Player not found."
        end

        -- Split command and argument
        local cmd, target = param:match("^(%S+)%s*(.*)$")

        -- ==========================================
        -- OPEN UI IF NO PARAMS
        -- ==========================================
        if param == "" then
            local c_data = clan.get_player_clan(name)

            if c_data then
                clan.ui.show_home(name)
            else
                clan.ui.show_no_clan(name)
            end

            return true
        end

        -- ==========================================
        -- CREATE CLAN
        -- ==========================================
        if cmd == "create" then
            if target == "" then
                return false, "Usage: /c create <name>"
            end

            local success, msg = clan.create(name, target)
            return success, msg
        end

        -- ==========================================
        -- LEAVE CLAN
        -- ==========================================
        if cmd == "leave" then
            clan.ui.show_leave_confirm(name)
            return true
        end

        -- ==========================================
        -- TELEPORT TO BASE
        -- ==========================================
        if cmd == "base" then
            clan.teleport_to_base(name)
            return true
        end

        -- ==========================================
        -- SET CLAN BASE
        -- ==========================================
        if cmd == "setbase" then
            local c = clan.get_player_clan(name)

            if c and (c.leader == name or table.contains(c.coleaders, name)) then
                c.home_pos = player:get_pos()

                clan.save_data(c.name, c)

                return true, "Clan base set to your current location!"
            else
                return false, "You don't have permission to set the base."
            end
        end

        -- ==========================================
        -- CLAN CHAT
        -- ==========================================
        if cmd == "chat" or cmd == "msg" then
            if target == "" then
                return false, "Usage: /c chat <message>"
            end

            return clan.chat(name, target)
        end

        return false, "Unknown clan command."
    end,
})


-- ==========================================
-- CLAN CHAT COMMAND (/cc)
-- ==========================================
core.register_chatcommand("cc", {
    params = "<message>",
    description = "Send a message to your clan members",

    func = function(name, param)
        if param == "" then
            return false, "Usage: /cc <message>"
        end

        return clan.chat(name, param)
    end,
})


-- ==========================================
-- CLAN CHAT ALIAS (/cm)
-- ==========================================
core.register_chatcommand("cm", {
    params = "<message>",
    description = "Send a message to your clan members",

    func = function(name, param)
        if param == "" then
            return false, "Usage: /cm <message>"
        end

        return clan.chat(name, param)
    end,
})