-- mods/clan/ui.lua

clan = clan or {}
clan.ui = {}

-- ==========================================
-- THEME & STYLING
-- ==========================================
local theme =
    "style_type[button,image_button;bgcolor=#2e004f;textcolor=#00ffff;border=false]" ..
    "style_type[label;textcolor=#00ffff]" ..
    "style_type[field,textarea,textlist,dropdown;bgcolor=#000000aa;textcolor=#ffffff]" ..
    "background9[0,0;0,0;clan_ui_bg.png;false;10]"

-- ==========================================
-- HEADER / NAVIGATION
-- ==========================================
local function get_nav_header(active_tab)
    return
        "size[12,10]" ..
        theme ..
        "tabheader[0,0;clan_tabs;Home,Members,Diplomacy,Search;" ..
        active_tab ..
        ";false;false]"
end

-- ==========================================
-- STEP 1: NO CLAN VIEW
-- ==========================================
function clan.ui.show_no_clan(player_name)
    local clans = clan.get_all_clans() or {}
    local clan_list = table.concat(clans, ",")

    local res =
        "size[12,10]" ..
        theme ..

        "label[4.5,0.5;⚔ CLAN MANAGEMENT]" ..

        -- CREATE
        "box[0.5,1.5;5,7;#00000055]" ..
        "label[1,2;CREATE A CLAN]" ..
        "label[1,2.5;Cost: 100 Jeans Coins]" ..
        "field[1,4.5;4,1;new_clan_name;Enter Clan Name:;]" ..
        "button[1,6;4,1;btn_create;Create Clan]" ..

        -- JOIN
        "box[6.5,1.5;5,7;#00000055]" ..
        "label[7,2;JOIN A CLAN]" ..
        "dropdown[7,4.5;4,1;join_selector;" ..
        clan_list ..
        ";1]" ..
        "button[7,6;4,1;btn_request_join;Send Join Request]"

    core.show_formspec(player_name, "clan:start", res)
end

-- ==========================================
-- STEP 2: HOME PAGE
-- ==========================================
function clan.ui.show_home(player_name)
    local c = clan.get_player_clan(player_name)

    if not c then
        return clan.ui.show_no_clan(player_name)
    end

    local res =
        get_nav_header(1) ..

        "label[0.5,1.2;CLAN: " .. c.name .. "]" ..
        "label[0.5,1.8;Level: " .. (c.level or 1) .. "]" ..
        "label[0.5,2.4;Members: " ..
        #c.members ..
        "/" ..
        (c.max_members or 10) ..
        "]" ..

        "label[0.5,3.0;Online: " ..
        (clan.get_online_count(c.name) or 0) ..
        "]" ..

        -- LEADERSHIP
        "label[6,1.2;LEADERSHIP]" ..
        "label[6,1.8;Leader: " .. (c.leader or "None") .. "]" ..
        "label[6,2.4;Co-Leaders: " ..
        table.concat(c.coleaders or {}, ", ") ..
        "]" ..

        "label[6,3.0;Elders: " ..
        table.concat(c.elders or {}, ", ") ..
        "]" ..

        -- ACTIONS
        "button[0.5,8.5;3,1;btn_set_base;Set Clan Base]" ..
        "button[4,8.5;3,1;btn_tp_home;Teleport Home]" ..

        "style[btn_leave_clan;textcolor=#ff4444]" ..
        "button[8.5,8.5;3,1;btn_leave_clan;LEAVE CLAN]"

    core.show_formspec(player_name, "clan:home", res)
end

-- ==========================================
-- STEP 3: MEMBERS PAGE
-- ==========================================
function clan.ui.show_members(player_name, sub_page)
    local c = clan.get_player_clan(player_name)

    if not c then
        return clan.ui.show_no_clan(player_name)
    end

    local res = get_nav_header(2)

    -- REQUESTS PAGE
    if sub_page == "requests" then
        local reqs = table.concat(c.pending_requests or {}, ",")

        res =
            res ..
            "label[0.5,1.5;PENDING JOIN REQUESTS]" ..
            "dropdown[0.5,2.5;5,1;req_selector;" ..
            reqs ..
            ";1]" ..

            "button[0.5,3.5;2,1;btn_accept_req;ACCEPT]" ..
            "button[3,3.5;2,1;btn_deny_req;DENY]" ..
            "button[0.5,8.5;3,1;btn_back_members;Back to List]"

    else
        local members = table.concat(c.members or {}, ",")

        res =
            res ..
            "label[0.5,1.5;MEMBER LIST]" ..

            "textlist[0.5,2.2;5,6;member_select;" ..
            members ..
            "]" ..

            "container[6,2.2]" ..

            "button[0,0;4,0.8;btn_promote;Promote]" ..
            "button[0,1;4,0.8;btn_demote;Demote]" ..
            "button[0,2;4,0.8;btn_kick;Kick]" ..

            "field[0.3,4;3.5,1;invite_name;Invite Player:;]" ..
            "button[0,4.5;4,0.8;btn_invite;Send Invite]" ..

            "button[0,6;4,0.8;btn_view_requests;Requests (" ..
            #(c.pending_requests or {}) ..
            ")]" ..

            "container_end[]"
    end

    core.show_formspec(player_name, "clan:members", res)
end

-- ==========================================
-- STEP 4: DIPLOMACY PAGE
-- ==========================================
function clan.ui.show_diplomacy(player_name, page)
    local c = clan.get_player_clan(player_name)

    if not c then
        return clan.ui.show_no_clan(player_name)
    end

    local res = get_nav_header(3)

    -- SUB NAV
    res =
        res ..
        "button[0.5,1.2;2.5,0.7;dip_allies;Allies]" ..
        "button[3.2,1.2;2.5,0.7;dip_enemies;Enemies]" ..
        "button[5.9,1.2;2.5,0.7;dip_threats;Threats]" ..
        "button[8.6,1.2;2.5,0.7;dip_wars;Wars]"

    -- ALLIES
    if page == "allies" then
        local allies = table.concat(c.allies or {}, ",")

        res =
            res ..
            "label[0.5,2.5;ALLIED CLANS]" ..

            "textlist[0.5,3;5,5;list_allies;" ..
            allies ..
            "]" ..

            "button[6,3;4,0.8;btn_disband_ally;Disband Alliance]" ..

            "field[6.3,5.5;4,1;ally_target;Request Ally:;]" ..
            "button[6,6.5;4,0.8;btn_req_ally;Send Request]"

    -- WARS
    elseif page == "wars" then
        res =
            res ..
            "label[0.5,2.5;ACTIVE WARS]" ..

            "textlist[0.5,3;5,5;list_wars;Clan War Logic...]" ..

            "button[6,3;4,0.8;btn_offer_peace;Offer Peace]" ..

            "style[btn_surrender;textcolor=#ff0000]" ..
            "button[6,5;4,0.8;btn_surrender;SURRENDER]" ..

            "label[6,6;Warning: Losing your clan leadership\npermanently if you surrender!]"
    end

    core.show_formspec(player_name, "clan:diplomacy", res)
end

-- ==========================================
-- STEP 5: SEARCH PAGE
-- ==========================================
function clan.ui.show_search(player_name)
    local clans = clan.get_all_clans() or {}

    local res =
        get_nav_header(4) ..

        "label[0.5,1.5;CLAN DIRECTORY]" ..

        "textlist[0.5,2.2;11,5;search_list;" ..
        table.concat(clans, ",") ..
        "]" ..

        "button[0.5,7.5;3,1;btn_view_clan;View Details]" ..

        "label[4,7.7;Select a clan to view Staff, Members, and Level.]"

    core.show_formspec(player_name, "clan:search", res)
end

-- ==========================================
-- LEAVE CONFIRMATION
-- ==========================================
function clan.ui.show_leave_confirm(player_name)
    local res =
        "size[6,4]" ..
        theme ..

        "label[1,1;Are you sure you want to leave?]" ..

        "button[0.5,2.5;2,1;btn_confirm_leave;YES]" ..
        "button[3.5,2.5;2,1;btn_cancel_leave;NO]"

    core.show_formspec(player_name, "clan:leave_confirm", res)
end

-- ==========================================
-- MAIN INPUT HANDLER
-- ==========================================
core.register_on_player_receive_fields(function(player, formname, fields)

    local name = player:get_player_name()

    if not formname:find("clan:") then
        return false
    end

    -- ======================================
    -- TAB SWITCHING
    -- ======================================
    if fields.clan_tabs then
        local tab = tonumber(fields.clan_tabs)

        if tab == 1 then
            clan.ui.show_home(name)

        elseif tab == 2 then
            clan.ui.show_members(name)

        elseif tab == 3 then
            clan.ui.show_diplomacy(name, "allies")

        elseif tab == 4 then
            clan.ui.show_search(name)
        end

        return true
    end

    -- ======================================
    -- MEMBERS NAVIGATION
    -- ======================================
    if fields.btn_view_requests then
        clan.ui.show_members(name, "requests")
        return true
    end

    if fields.btn_back_members then
        clan.ui.show_members(name)
        return true
    end

    -- ======================================
    -- DIPLOMACY NAVIGATION
    -- ======================================
    if fields.dip_allies then
        clan.ui.show_diplomacy(name, "allies")
        return true
    end

    if fields.dip_wars then
        clan.ui.show_diplomacy(name, "wars")
        return true
    end

    -- ======================================
    -- CREATE CLAN
    -- ======================================
    if fields.btn_create then
        local new_name = fields.new_clan_name

        if new_name and new_name ~= "" then
            local success, message = clan.create(name, new_name)

            if success then
                core.chat_send_player(
                    name,
                    core.colorize("#00ffff", message)
                )

                clan.ui.show_home(name)

            else
                core.chat_send_player(
                    name,
                    core.colorize("#ff4444", "Error: " .. message)
                )
            end
        else
            core.chat_send_player(
                name,
                core.colorize("#ff4444", "Please enter a clan name!")
            )
        end

        return true
    end

    -- ======================================
    -- JOIN REQUEST
    -- ======================================
    if fields.btn_request_join then
        local selected_clan = fields.join_selector

        if selected_clan and selected_clan ~= "" then
            local success, message =
                clan.request_join(name, selected_clan)

            if success then
                core.chat_send_player(
                    name,
                    core.colorize("#00ffff", message)
                )
            else
                core.chat_send_player(
                    name,
                    core.colorize("#ff4444", message)
                )
            end
        end

        return true
    end

    -- ======================================
    -- LEAVE CLAN
    -- ======================================
    if fields.btn_leave_clan then
        clan.ui.show_leave_confirm(name)
        return true
    end

    if fields.btn_cancel_leave then
        clan.ui.show_home(name)
        return true
    end

    if fields.btn_confirm_leave then
        clan.leave(name)
        clan.ui.show_no_clan(name)
        return true
    end

    return true
end)