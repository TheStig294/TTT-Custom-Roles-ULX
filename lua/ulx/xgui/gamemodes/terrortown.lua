--Terrortown settings module for ULX GUI
--Defines ttt cvar limits and ttt specific settings for the ttt gamemode.

local terrortown_settings = xlib.makepanel { parent = xgui.null }

xlib.makelabel { x = 5, y = 5, w = 600, wordwrap = true, label = "Trouble in Terrorist Town ULX Commands XGUI module Created by: Bender180", parent = terrortown_settings }
xlib.makelabel { x = 2, y = 345, w = 600, wordwrap = true, label = "The settings above DO NOT SAVE when the server changes maps, is restarted or crashes. They are for easy access only", parent = terrortown_settings }

xlib.makelabel { x = 5, y = 230, w = 160, wordwrap = true, label = "Note to sever owners: to restrict this panel allow or deny permission to xgui_gmsettings.", parent = terrortown_settings }
xlib.makelabel { x = 5, y = 275, w = 160, wordwrap = true, label = "All settings listed are explained here: http://ttt.badking.net/config- and-commands/convars", parent = terrortown_settings }
xlib.makelabel { x = 5, y = 330, w = 160, wordwrap = true, label = "Not all settings echo to chat.", parent = terrortown_settings }

terrortown_settings.panel = xlib.makepanel { x = 160, y = 25, w = 420, h = 318, parent = terrortown_settings }
terrortown_settings.catList = xlib.makelistview { x = 5, y = 25, w = 150, h = 200, parent = terrortown_settings }
terrortown_settings.catList:AddColumn("Terrorist Town Settings")
terrortown_settings.catList.Columns[1].DoClick = function() end

terrortown_settings.catList.OnRowSelected = function(self, lineid, line)
    local panel = xgui.modules.submodule[line:GetValue(2)].panel
    if panel ~= terrortown_settings.curPanel then
        panel:SetZPos(0)
        xlib.addToAnimQueue("pnlSlide", { panel = panel, startx = -435, starty = 0, endx = 0, endy = 0, setvisible = true })
        if terrortown_settings.curPanel then
            terrortown_settings.curPanel:SetZPos(-1)
            xlib.addToAnimQueue(terrortown_settings.curPanel.SetVisible, terrortown_settings.curPanel, false)
        end
        xlib.animQueue_start()
        terrortown_settings.curPanel = panel
    else
        xlib.addToAnimQueue("pnlSlide", { panel = panel, startx = 0, starty = 0, endx = -435, endy = 0, setvisible = false })
        self:ClearSelection()
        terrortown_settings.curPanel = nil
        xlib.animQueue_start()
    end
    if panel.onOpen then panel.onOpen() end --If the panel has it, call a function when it's opened
end

--Process modular settings
function terrortown_settings.processModules()
    terrortown_settings.catList:Clear()
    for i, module in ipairs(xgui.modules.submodule) do
        if module.mtype == "terrortown_settings" and (not module.access or LocalPlayer():query(module.access)) then
            local w, h = module.panel:GetSize()
            if w == h and h == 0 then module.panel:SetSize(275, 322) end

            if module.panel.scroll then --For DListLayouts
                module.panel.scroll.panel = module.panel
                module.panel = module.panel.scroll
            end
            module.panel:SetParent(terrortown_settings.panel)

            local line = terrortown_settings.catList:AddLine(module.name, i)
            if (module.panel == terrortown_settings.curPanel) then
                terrortown_settings.curPanel = nil
                terrortown_settings.catList:SelectItem(line)
            else
                module.panel:SetVisible(false)
            end
        end
    end
    terrortown_settings.catList:SortByColumn(1, false)
end
terrortown_settings.processModules()

xgui.hookEvent("onProcessModules", nil, terrortown_settings.processModules)
xgui.addModule("TTT", terrortown_settings, "vgui/ttt/ulx_ttt.png", "xgui_gmsettings")

local missing_cvars = {}

local function GetReplicatedConVar(name)
    return GetConVar("rep_" .. name)
end

local function GetReplicatedConVarDefault(name, default)
    local convar = GetReplicatedConVar(name)
    if not convar then
        missing_cvars[name] = true
        return default
    end
    return convar:GetDefault()
end

local function GetReplicatedConVarMin(name, min)
    local convar = GetReplicatedConVar(name)
    if not convar then
        missing_cvars[name] = true
        return min
    end
    return convar:GetMin()
end

local function GetReplicatedConVarMax(name, max)
    local convar = GetReplicatedConVar(name)
    if not convar then
        missing_cvars[name] = true
        return max
    end
    return convar:GetMax()
end

local function GetShopRoles()
    if not GetConVar("ttt_shop_for_all"):GetBool() then
        return SHOP_ROLES
    end

    local shop_roles = {}
    for role = 0, ROLE_MAX do
        shop_roles[role] = true
    end
    return shop_roles
end

local function GetCreditRoles()
    local shop_roles = GetShopRoles()
    -- Add any roles that have credits but don't have a shop to the full list
    local shopless_credit_roles = table.ToLookup(table.UnionedKeys(CAN_LOOT_CREDITS_ROLES, ROLE_STARTING_CREDITS))
    return table.ToLookup(table.UnionedKeys(shop_roles, shopless_credit_roles))
end

local function SortRolesByName(roles)
    table.sort(roles, function(a, b) return ROLE_STRINGS[a] < ROLE_STRINGS[b] end)
end

local function GetSortedTeamRoles(role_team, exclude)
    local roles = GetTeamRoles(role_team, exclude)
    SortRolesByName(roles)
    return roles
end

local function GetAllSortedRoles()
    local roles = {}
    for role = 0, ROLE_MAX do
        table.insert(roles, role)
    end
    SortRolesByName(roles)
    return roles
end

local function AddRoundStructureModule()
    local rspnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    --Preparation and Post-Round
    local rspapclp = vgui.Create("DCollapsibleCategory", rspnl)
    rspapclp:SetSize(390, 70)
    rspapclp:SetExpanded(1)
    rspapclp:SetLabel("Preparation and Post-Round")

    local rspaplst = vgui.Create("DPanelList", rspapclp)
    rspaplst:SetPos(5, 25)
    rspaplst:SetSize(390, 70)
    rspaplst:SetSpacing(5)

    local prept = xlib.makeslider { label = "ttt_preptime_seconds (def. 30)", min = 1, max = 120, repconvar = "rep_ttt_preptime_seconds", parent = rspaplst }
    rspaplst:AddItem(prept)

    local fprept = xlib.makeslider { label = "ttt_firstpreptime (def. 60)", min = 1, max = 120, repconvar = "rep_ttt_firstpreptime", parent = rspaplst }
    rspaplst:AddItem(fprept)

    local pstt = xlib.makeslider { label = "ttt_posttime_seconds (def. 30)", min = 1, max = 120, repconvar = "rep_ttt_posttime_seconds", parent = rspaplst }
    rspaplst:AddItem(pstt)

    --Round Length
    local rsrlclp = vgui.Create("DCollapsibleCategory", rspnl)
    rsrlclp:SetSize(390, 115)
    rsrlclp:SetExpanded(0)
    rsrlclp:SetLabel("Round Length")

    local rsrllst = vgui.Create("DPanelList", rsrlclp)
    rsrllst:SetPos(5, 25)
    rsrllst:SetSize(390, 115)
    rsrllst:SetSpacing(5)

    local hstmd = xlib.makecheckbox { label = "ttt_haste (def. 1)", repconvar = "rep_ttt_haste", parent = rsrllst }
    rsrllst:AddItem(hstmd)

    local hstsm = xlib.makeslider { label = "ttt_haste_starting_minutes (def. 5)", min = 1, max = 60, repconvar = "rep_ttt_haste_starting_minutes", parent = rsrllst }
    rsrllst:AddItem(hstsm)

    local hstmpd = xlib.makeslider { label = "ttt_haste_minutes_per_death (def. 0.5)", min = 0.1, max = 9, decimal = 2, repconvar = "rep_ttt_haste_minutes_per_death", parent = rsrllst }
    rsrllst:AddItem(hstmpd)

    local rtm = xlib.makeslider { label = "ttt_roundtime_minutes (def. 10)", min = 1, max = 60, repconvar = "rep_ttt_roundtime_minutes", parent = rsrllst }
    rsrllst:AddItem(rtm)

    local tlwd = xlib.makecheckbox { label = "ttt_roundtime_win_draw (def. 0)", repconvar = "rep_ttt_roundtime_win_draw", parent = rsrllst }
    rsrllst:AddItem(tlwd)

    --Map Switching and Voting
    local msavclp = vgui.Create("DCollapsibleCategory", rspnl)
    msavclp:SetSize(390, 50)
    msavclp:SetExpanded(0)
    msavclp:SetLabel("Map Switching and Voting")

    local msavlst = vgui.Create("DPanelList", msavclp)
    msavlst:SetPos(5, 25)
    msavlst:SetSize(390, 50)
    msavlst:SetSpacing(5)

    local rndl = xlib.makeslider { label = "ttt_round_limit (def. 6)", min = 1, max = 100, repconvar = "rep_ttt_round_limit", parent = msavlst }
    msavlst:AddItem(rndl)

    local rndtlm = xlib.makeslider { label = "ttt_time_limit_minutes (def. 75)", min = 1, max = 150, repconvar = "rep_ttt_time_limit_minutes", parent = msavlst }
    msavlst:AddItem(rndtlm)

    xgui.hookEvent("onProcessModules", nil, rspnl.processModules)
    xgui.addSubModule("Round Structure", rspnl, nil, "terrortown_settings")
end

local function AddTraitorAndDetectiveSettings(gppnl)
    local gptdcclp = vgui.Create("DCollapsibleCategory", gppnl)
    gptdcclp:SetSize(390, 150)
    gptdcclp:SetExpanded(1)
    gptdcclp:SetLabel("Traitor and Detective Settings")

    local gptdlst = vgui.Create("DPanelList", gptdcclp)
    gptdlst:SetPos(5, 25)
    gptdlst:SetSize(390, 150)
    gptdlst:SetSpacing(5)

    local tpercet = xlib.makeslider { label = "ttt_traitor_pct (def. 0.25)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_traitor_pct", parent = gptdlst }
    gptdlst:AddItem(tpercet)

    local tmax = xlib.makeslider { label = "ttt_traitor_max (def. 32)", min = 1, max = 80, repconvar = "rep_ttt_traitor_max", parent = gptdlst }
    gptdlst:AddItem(tmax)

    local dpercet = xlib.makeslider { label = "ttt_detective_pct (def. 0.13)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_detective_pct", parent = gptdlst }
    gptdlst:AddItem(dpercet)

    local dmax = xlib.makeslider { label = "ttt_detective_max (def. 32)", min = 1, max = 80, repconvar = "rep_ttt_detective_max", parent = gptdlst }
    gptdlst:AddItem(dmax)

    local dmp = xlib.makeslider { label = "ttt_detective_min_players (def. 10)", min = 1, max = 50, repconvar = "rep_ttt_detective_min_players", parent = gptdlst }
    gptdlst:AddItem(dmp)

    local dkm = xlib.makeslider { label = "ttt_detective_karma_min (def. 600)", min = 1, max = 1000, repconvar = "rep_ttt_detective_karma_min", parent = gptdlst }
    gptdlst:AddItem(dkm)
end

local function AddDefaultRoleSettings(lst, role_list)
    for _, r in pairs(role_list) do
        local role_string = ROLE_STRINGS_RAW[r]
        local enabled = xlib.makecheckbox { label = "ttt_" .. role_string .. "_enabled (def. 0)", repconvar = "rep_ttt_" .. role_string .. "_enabled", parent = lst }
        lst:AddItem(enabled)

        local spawn_weight = xlib.makeslider { label = "ttt_" .. role_string .. "_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_" .. role_string .. "_spawn_weight", parent = lst }
        lst:AddItem(spawn_weight)

        local min_players = xlib.makeslider { label = "ttt_" .. role_string .. "_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_" .. role_string .. "_min_players", parent = lst }
        lst:AddItem(min_players)
    end
end

local function AddSpecialistTraitorSettings(gppnl)
    local traitor_roles = table.ExcludedKeys(TRAITOR_ROLES, {ROLE_TRAITOR})
    SortRolesByName(traitor_roles)
    local sptraclp = vgui.Create("DCollapsibleCategory", gppnl)
    sptraclp:SetSize(390, 50 + (70 * #traitor_roles))
    sptraclp:SetExpanded(1)
    sptraclp:SetLabel("Specialist Traitor Settings")

    local sptralst = vgui.Create("DPanelList", sptraclp)
    sptralst:SetPos(5, 25)
    sptralst:SetSize(390, 50 + (70 * #traitor_roles))
    sptralst:SetSpacing(5)

    local stpercet = xlib.makeslider { label = "ttt_special_traitor_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_traitor_pct", parent = sptralst }
    sptralst:AddItem(stpercet)

    local stchance = xlib.makeslider { label = "ttt_special_traitor_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_traitor_chance", parent = sptralst }
    sptralst:AddItem(stchance)

    AddDefaultRoleSettings(sptralst, traitor_roles)
end

local function AddSpecialistDetectiveSettings(gppnl)
    local det_roles = table.ExcludedKeys(DETECTIVE_ROLES, {ROLE_DETECTIVE})
    SortRolesByName(det_roles)
    local spdetclp = vgui.Create("DCollapsibleCategory", gppnl)
    spdetclp:SetSize(390, 50 + (70 * #det_roles))
    spdetclp:SetExpanded(1)
    spdetclp:SetLabel("Specialist Detective Settings")

    local spdetlst = vgui.Create("DPanelList", spdetclp)
    spdetlst:SetPos(5, 25)
    spdetlst:SetSize(390, 50 + (70 * #det_roles))
    spdetlst:SetSpacing(5)

    local sdpercet = xlib.makeslider { label = "ttt_special_detective_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_detective_pct", parent = spdetlst }
    spdetlst:AddItem(sdpercet)

    local sdchance = xlib.makeslider { label = "ttt_special_detective_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_detective_chance", parent = spdetlst }
    spdetlst:AddItem(sdchance)

    AddDefaultRoleSettings(spdetlst, det_roles)
end

local function AddSpecialistInnocentSettings(gppnl)
    local inno_roles = table.ExcludedKeys(INNOCENT_ROLES, table.Add({ROLE_INNOCENT}, GetTeamRoles(DETECTIVE_ROLES)))
    SortRolesByName(inno_roles)
    local spinnclp = vgui.Create("DCollapsibleCategory", gppnl)
    spinnclp:SetSize(390, 50 + (70 * #inno_roles))
    spinnclp:SetExpanded(1)
    spinnclp:SetLabel("Specialist Innocent Settings")

    local spinnlst = vgui.Create("DPanelList", spinnclp)
    spinnlst:SetPos(5, 25)
    spinnlst:SetSize(390, 50 + (70 * #inno_roles))
    spinnlst:SetSpacing(5)

    local sipercet = xlib.makeslider { label = "ttt_special_innocent_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_innocent_pct", parent = spinnlst }
    spinnlst:AddItem(sipercet)

    local sichance = xlib.makeslider { label = "ttt_special_innocent_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_innocent_chance", parent = spinnlst }
    spinnlst:AddItem(sichance)

    AddDefaultRoleSettings(spinnlst, inno_roles)
end

local function AddIndependentRoleSettings(gppnl)
    local indep_roles = GetSortedTeamRoles(INDEPENDENT_ROLES)
    local jester_roles = GetSortedTeamRoles(JESTER_ROLES)
    local height = 245 + (70 * #indep_roles) + (70 * #jester_roles)
    local indclp = vgui.Create("DCollapsibleCategory", gppnl)
    indclp:SetSize(390, height)
    indclp:SetExpanded(1)
    indclp:SetLabel("Independent Role Settings")

    local indlst = vgui.Create("DPanelList", indclp)
    indlst:SetPos(5, 25)
    indlst:SetSize(390, height)
    indlst:SetSpacing(5)

    local indjeslbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Shared settings:", parent = indlst }
    indlst:AddItem(indjeslbl)

    local singlejind = xlib.makecheckbox { label = "ttt_single_jester_independent (def. 1)", repconvar = "rep_ttt_single_jester_independent", parent = indlst }
    indlst:AddItem(singlejind)

    local singlejindmp = xlib.makeslider { label = "ttt_single_jester_independent_max_players (def. 0)", min = 0, max = 32, repconvar = "rep_ttt_single_jester_independent_max_players", parent = indlst }
    indlst:AddItem(singlejindmp)

    local multjind = xlib.makecheckbox { label = "ttt_multiple_jesters_independents (def. 0)", repconvar = "rep_ttt_multiple_jesters_independents", parent = indlst }
    indlst:AddItem(multjind)

    local jindpct = xlib.makeslider { label = "ttt_jester_independent_pct (def. 0.13)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_jester_independent_pct", parent = indlst }
    indlst:AddItem(jindpct)

    local jindmax = xlib.makeslider { label = "ttt_jester_independent_max (def. 2)", min = 0, max = 16, repconvar = "rep_ttt_jester_independent_max", parent = indlst }
    indlst:AddItem(jindmax)

    local jindchance = xlib.makeslider { label = "ttt_jester_independent_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_jester_independent_chance", parent = indlst }
    indlst:AddItem(jindchance)

    local indlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Independent settings:", parent = indlst }
    indlst:AddItem(indlbl)

    local indchance = xlib.makeslider { label = "ttt_independent_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_independent_chance", parent = indlst }
    indlst:AddItem(indchance)

    AddDefaultRoleSettings(indlst, indep_roles)

    local jeslbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Jester settings:", parent = indlst }
    indlst:AddItem(jeslbl)

    local jeschance = xlib.makeslider { label = "ttt_jester_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_jester_chance", parent = indlst }
    indlst:AddItem(jeschance)

    AddDefaultRoleSettings(indlst, jester_roles)
end

local function AddMonsterSettings(gppnl)
    local monster_roles = GetSortedTeamRoles(MONSTER_ROLES)
    local monclp = vgui.Create("DCollapsibleCategory", gppnl)
    monclp:SetSize(390, 75 + (70 * #monster_roles))
    monclp:SetExpanded(1)
    monclp:SetLabel("Monster Settings")

    local monlst = vgui.Create("DPanelList", monclp)
    monlst:SetPos(5, 25)
    monlst:SetSize(390, 75 + (70 * #monster_roles))
    monlst:SetSpacing(5)

    local monmax = xlib.makeslider { label = "ttt_monster_max (def. 1)", min = 0, max = 80, repconvar = "rep_ttt_monster_max", parent = monlst }
    monlst:AddItem(monmax)

    local monpercet = xlib.makeslider { label = "ttt_monster_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_monster_pct", parent = monlst }
    monlst:AddItem(monpercet)

    local monchance = xlib.makeslider { label = "ttt_monster_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_monster_chance", parent = monlst }
    monlst:AddItem(monchance)

    AddDefaultRoleSettings(monlst, monster_roles)
end

local function AddRoleHealthSettings(gppnl)
    local rolehealthclp = vgui.Create("DCollapsibleCategory", gppnl)
    local height = (ROLE_MAX + 1) * 50
    rolehealthclp:SetSize(390, height)
    rolehealthclp:SetExpanded(1)
    rolehealthclp:SetLabel("Role Health Settings")

    local rolehealthlst = vgui.Create("DPanelList", rolehealthclp)
    rolehealthlst:SetPos(5, 25)
    rolehealthlst:SetSize(390, height)
    rolehealthlst:SetSpacing(5)

    for _, role in ipairs(GetAllSortedRoles()) do
        local rolestring = ROLE_STRINGS_RAW[role]
        local convar = "ttt_" .. rolestring .. "_starting_health"
        local default = GetReplicatedConVarDefault(convar, "100")
        local starthealth = xlib.makeslider { label = convar .. " (def. " .. default .. ")", min = -1, max = 200, repconvar = "rep_" .. convar, parent = rolehealthlst }
        rolehealthlst:AddItem(starthealth)

        -- Save the control so it can be updated later
        if missing_cvars[convar] then
            missing_cvars[convar] = starthealth
        end

        convar = "ttt_" .. rolestring .. "_max_health"
        default = GetReplicatedConVarDefault(convar, "100")
        local maxhealth = xlib.makeslider { label = convar .. " (def. " .. default .. ")", min = -1, max = 200, repconvar = "rep_" .. convar, parent = rolehealthlst }
        rolehealthlst:AddItem(maxhealth)

        -- Save the control so it can be updated later
        if missing_cvars[convar] then
            missing_cvars[convar] = maxhealth
        end
    end
end

local function GetRoleConVars(team_list)
    local role_cvars = {}
    local num_count, bool_count, text_count = 0, 0, 0
    for _, r in ipairs(team_list) do
        if ROLE_CONVARS[r] then
            local valid_convars = {}
            for _, cvar in ipairs(ROLE_CONVARS[r]) do
                if cvar.type == ROLE_CONVAR_TYPE_NUM then
                    num_count = num_count + 1
                    table.insert(valid_convars, cvar)
                elseif cvar.type == ROLE_CONVAR_TYPE_BOOL then
                    bool_count = bool_count + 1
                    table.insert(valid_convars, cvar)
                elseif cvar.type == ROLE_CONVAR_TYPE_TEXT then
                    text_count = text_count + 1
                    table.insert(valid_convars, cvar)
                else
                    ErrorNoHalt("WARNING: Role (" .. r .. ") tried to register a convar with an unknown type: " .. tostring(cvar.type))
                end
            end

            table.sort(valid_convars, function(a, b) return a.cvar < b.cvar end)
            role_cvars[r] = valid_convars
        end
    end
    return role_cvars, num_count, bool_count, text_count
end

local function AddRoleProperties(role, role_cvars, list)
    local rolestring = ROLE_STRINGS[role]
    local label = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = rolestring .. " settings:", parent = list }
    list:AddItem(label)

    for _, c in ipairs(role_cvars) do
        local name = c.cvar
        if c.type == ROLE_CONVAR_TYPE_TEXT then
            local textlabel = xlib.makelabel { label = name, parent = list }
            list:AddItem(textlabel)
            local textbox = xlib.maketextbox { repconvar = "rep_" .. name, enableinput = true, parent = list }
            list:AddItem(textbox)
        else
            local default = GetReplicatedConVarDefault(name, "0")
            local control
            if c.type == ROLE_CONVAR_TYPE_NUM then
                local min = GetReplicatedConVarMin(name, 0)
                local max = GetReplicatedConVarMax(name, 1)
                local decimal = c.decimal or 0

                control = xlib.makeslider { label = name .. " (def. " .. default .. ")", min = min, max = max, decimal = decimal, repconvar = "rep_" .. name, parent = list }
            elseif c.type == ROLE_CONVAR_TYPE_BOOL then
                control = xlib.makecheckbox { label = name .. " (def. " .. default .. ")", repconvar = "rep_" .. name, parent = list }
            end

            list:AddItem(control)

            -- Save the control so it can be updated later
            if missing_cvars[name] then
                missing_cvars[name] = control
            end
        end
    end
end

local function GetRoleConVarsHeight(role_cvars, num_count, bool_count, text_count)
    local roles_with_cvars = table.Count(role_cvars)
    -- Labels
    return (roles_with_cvars * 18) +
            -- Sliders
            (num_count * 25) +
            -- Checkboxes
            (bool_count * 20) +
            -- Textboxes
            (text_count * 43)
end

local function AddTraitorProperties(gppnl)
    local traitor_roles = GetSortedTeamRoles(TRAITOR_ROLES)
    local role_cvars, num_count, bool_count, text_count = GetRoleConVars(traitor_roles)
    local height = 38 + GetRoleConVarsHeight(role_cvars, num_count, bool_count, text_count)
    local trapropclp = vgui.Create("DCollapsibleCategory", gppnl)
    trapropclp:SetSize(390, height)
    trapropclp:SetExpanded(1)
    trapropclp:SetLabel("Traitor Properties")

    local traproplst = vgui.Create("DPanelList", trapropclp)
    traproplst:SetPos(5, 25)
    traproplst:SetSize(390, height)
    traproplst:SetSpacing(5)

    local tralbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Shared settings:", parent = traproplst }
    traproplst:AddItem(tralbl)

    local travis = xlib.makecheckbox { label = "ttt_traitors_vision_enabled (def. 0)", repconvar = "rep_ttt_traitors_vision_enabled", parent = traproplst }
    traproplst:AddItem(travis)

    for _, r in ipairs(traitor_roles) do
        if role_cvars[r] then
            AddRoleProperties(r, role_cvars[r], traproplst)
        end
    end
end

local function AddDetectiveProperties(gppnl)
    local detective_roles = GetSortedTeamRoles(DETECTIVE_ROLES)
    local role_cvars, num_count, bool_count, text_count = GetRoleConVars(detective_roles)
    local height = 168 + (#CORPSE_ICON_TYPES * 20) + GetRoleConVarsHeight(role_cvars, num_count, bool_count, text_count)
    local detpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    detpropclp:SetSize(390, height)
    detpropclp:SetExpanded(1)
    detpropclp:SetLabel("Detective Properties")

    local detproplst = vgui.Create("DPanelList", detpropclp)
    detproplst:SetPos(5, 25)
    detproplst:SetSize(390, height)
    detproplst:SetSpacing(5)

    local detlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Shared settings:", parent = detproplst }
    detproplst:AddItem(detlbl)

    local detsch = xlib.makecheckbox { label = "ttt_detectives_search_only (def. 1)", repconvar = "rep_ttt_detectives_search_only", parent = detproplst }
    detproplst:AddItem(detsch)

    for _, dataType in ipairs(CORPSE_ICON_TYPES) do
        local detschtype = xlib.makecheckbox { label = "ttt_detectives_search_only_" .. dataType .. " (def. 0)", repconvar = "rep_ttt_detectives_search_only_" .. dataType, parent = detproplst }
        detproplst:AddItem(detschtype)
    end

    local detdlo = xlib.makecheckbox { label = "ttt_detectives_disable_looting (def. 0)", repconvar = "rep_ttt_detectives_disable_looting", parent = detproplst }
    detproplst:AddItem(detdlo)

    local dethsm = xlib.makeslider { label = "ttt_detectives_hide_special_mode (def. 0)", min = 0, max = 2, repconvar = "rep_ttt_detectives_hide_special_mode", parent = detproplst }
    detproplst:AddItem(dethsm)

    local detge = xlib.makecheckbox { label = "ttt_detectives_glow_enabled (def. 0)", repconvar = "rep_ttt_detectives_glow_enabled", parent = detproplst }
    detproplst:AddItem(detge)

    local detsdal = xlib.makecheckbox { label = "ttt_special_detectives_armor_loadout (def. 1)", repconvar = "rep_ttt_special_detectives_armor_loadout", parent = detproplst }
    detproplst:AddItem(detsdal)

    local prsrch = xlib.makecheckbox { label = "ttt_all_search_postround (def. 1)", repconvar = "rep_ttt_all_search_postround", parent = detproplst }
    detproplst:AddItem(prsrch)

    local bnsrch = xlib.makecheckbox { label = "ttt_all_search_binoc (def. 0)", repconvar = "rep_ttt_all_search_binoc", parent = detproplst }
    detproplst:AddItem(bnsrch)

    for _, r in ipairs(detective_roles) do
        if role_cvars[r] then
            AddRoleProperties(r, role_cvars[r], detproplst)
        end
    end
end

local function AddInnocentProperties(gppnl)
    local innocent_roles = GetSortedTeamRoles(INNOCENT_ROLES, DETECTIVE_ROLES)
    local role_cvars, num_count, bool_count, text_count = GetRoleConVars(innocent_roles)
    local height = GetRoleConVarsHeight(role_cvars, num_count, bool_count, text_count)
    local innpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    innpropclp:SetSize(390, height)
    innpropclp:SetExpanded(1)
    innpropclp:SetLabel("Innocent Properties")

    local innproplst = vgui.Create("DPanelList", innpropclp)
    innproplst:SetPos(5, 25)
    innproplst:SetSize(390, height)
    innproplst:SetSpacing(5)

    for _, r in ipairs(innocent_roles) do
        if role_cvars[r] then
            AddRoleProperties(r, role_cvars[r], innproplst)
        end
    end
end

local function AddJesterRoleProperties(gppnl)
    local jester_roles = GetSortedTeamRoles(JESTER_ROLES)
    local role_cvars, num_count, bool_count, text_count = GetRoleConVars(jester_roles)
    local height = 78 + GetRoleConVarsHeight(role_cvars, num_count, bool_count, text_count)
    local jespropclp = vgui.Create("DCollapsibleCategory", gppnl)
    jespropclp:SetSize(390, height)
    jespropclp:SetExpanded(1)
    jespropclp:SetLabel("Jester Properties")

    local jesproplst = vgui.Create("DPanelList", jespropclp)
    jesproplst:SetPos(5, 25)
    jesproplst:SetSize(390, height)
    jesproplst:SetSpacing(5)

    local jeslbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Shared settings:", parent = jesproplst }
    jesproplst:AddItem(jeslbl)

    local jestester = xlib.makecheckbox { label = "ttt_jesters_trigger_traitor_testers (def. 1)", repconvar = "rep_ttt_jesters_trigger_traitor_testers", parent = jesproplst }
    jesproplst:AddItem(jestester)

    local jesvtt = xlib.makecheckbox { label = "ttt_jesters_visible_to_traitors (def. 1)", repconvar = "rep_ttt_jesters_visible_to_traitors", parent = jesproplst }
    jesproplst:AddItem(jesvtt)

    local jesvtm = xlib.makecheckbox { label = "ttt_jesters_visible_to_monsters (def. 1)", repconvar = "rep_ttt_jesters_visible_to_monsters", parent = jesproplst }
    jesproplst:AddItem(jesvtm)

    for _, r in ipairs(jester_roles) do
        if role_cvars[r] then
            AddRoleProperties(r, role_cvars[r], jesproplst)
        end
    end
end

local function AddIndependentRoleProperties(gppnl)
    local independent_roles = GetSortedTeamRoles(INDEPENDENT_ROLES)
    local role_cvars, num_count, bool_count, text_count = GetRoleConVars(independent_roles)
    local height = 38 + GetRoleConVarsHeight(role_cvars, num_count, bool_count, text_count)
    local indpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    indpropclp:SetSize(390, height)
    indpropclp:SetExpanded(1)
    indpropclp:SetLabel("Independent Properties")

    local indproplst = vgui.Create("DPanelList", indpropclp)
    indproplst:SetPos(5, 25)
    indproplst:SetSize(390, height)
    indproplst:SetSpacing(5)

    local indlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Shared settings:", parent = indproplst }
    indproplst:AddItem(indlbl)

    local indtes = xlib.makecheckbox { label = "ttt_independents_trigger_traitor_testers (def. 0)", repconvar = "rep_ttt_independents_trigger_traitor_testers", parent = indproplst }
    indproplst:AddItem(indtes)

    for _, r in ipairs(independent_roles) do
        if role_cvars[r] then
            AddRoleProperties(r, role_cvars[r], indproplst)
        end
    end
end

local function AddMonsterRoleProperties(gppnl)
    local monster_roles = GetSortedTeamRoles(MONSTER_ROLES)
    local role_cvars, num_count, bool_count, text_count = GetRoleConVars(monster_roles)
    local height = GetRoleConVarsHeight(role_cvars, num_count, bool_count, text_count)
    local monpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    monpropclp:SetSize(390, height)
    monpropclp:SetExpanded(1)
    monpropclp:SetLabel("Monsters Properties")

    local monproplst = vgui.Create("DPanelList", monpropclp)
    monproplst:SetPos(5, 25)
    monproplst:SetSize(390, height)
    monproplst:SetSpacing(5)

    for _, r in ipairs(monster_roles) do
        if role_cvars[r] then
            AddRoleProperties(r, role_cvars[r], monproplst)
        end
    end
end

local function AddCustomRoleProperties(gppnl)
    local crpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    crpropclp:SetSize(390, 310)
    crpropclp:SetExpanded(1)
    crpropclp:SetLabel("Other Custom Role Properties")

    local crproplst = vgui.Create("DPanelList", crpropclp)
    crproplst:SetPos(5, 25)
    crproplst:SetSize(390, 310)
    crproplst:SetSpacing(5)

    local depimppad = xlib.makecheckbox { label = "ttt_deputy_impersonator_promote_any_death (def. 0)", repconvar = "rep_ttt_deputy_impersonator_promote_any_death", parent = crproplst }
    crproplst:AddItem(depimppad)

    local depimpsp = xlib.makecheckbox { label = "ttt_deputy_impersonator_start_promoted (def. 0)", repconvar = "rep_ttt_deputy_impersonator_start_promoted", parent = crproplst }
    crproplst:AddItem(depimpsp)

    local singdepimp = xlib.makecheckbox { label = "ttt_single_deputy_impersonator (def. 0)", repconvar = "rep_ttt_single_deputy_impersonator", parent = crproplst }
    crproplst:AddItem(singdepimp)

    local singdepimpchance = xlib.makeslider { label = "ttt_single_deputy_impersonator_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_single_deputy_impersonator_chance", parent = crproplst }
    crproplst:AddItem(singdepimpchance)

    local singdocqua = xlib.makecheckbox { label = "ttt_single_doctor_quack (def. 0)", repconvar = "rep_ttt_single_doctor_quack", parent = crproplst }
    crproplst:AddItem(singdocqua)

    local singdocquachance = xlib.makeslider { label = "ttt_single_doctor_quackr_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_single_doctor_quack_chance", parent = crproplst }
    crproplst:AddItem(singdocquachance)

    local singmedhyp = xlib.makecheckbox { label = "ttt_single_paramedic_hypnotist (def. 0)", repconvar = "rep_ttt_single_paramedic_hypnotist", parent = crproplst }
    crproplst:AddItem(singmedhyp)

    local singmedhypchance = xlib.makeslider { label = "ttt_single_paramedic_hypnotist_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_single_paramedic_hypnotist_chance", parent = crproplst }
    crproplst:AddItem(singmedhypchance)

    local singphapar = xlib.makecheckbox { label = "ttt_single_phantom_parasite (def. 0)", repconvar = "rep_ttt_single_phantom_parasite", parent = crproplst }
    crproplst:AddItem(singphapar)

    local singphaparchance = xlib.makeslider { label = "ttt_single_phantom_parasite_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_single_phantom_parasite_chance", parent = crproplst }
    crproplst:AddItem(singphaparchance)

    local singdruclo = xlib.makecheckbox { label = "ttt_single_drunk_clown (def. 0)", repconvar = "rep_ttt_single_drunk_clown", parent = crproplst }
    crproplst:AddItem(singdruclo)

    local singdruclochance = xlib.makeslider { label = "ttt_single_drunk_clown_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_single_drunk_clown_chance", parent = crproplst }
    crproplst:AddItem(singdruclochance)

    local singjesswa = xlib.makecheckbox { label = "ttt_single_jester_swapper (def. 0)", repconvar = "rep_ttt_single_jester_swapper", parent = crproplst }
    crproplst:AddItem(singjesswa)

    local singjesswachance = xlib.makeslider { label = "ttt_single_jester_swapper_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_single_jester_swapper_chance", parent = crproplst }
    crproplst:AddItem(singjesswachance)
end

local function AddShopRandomizationSettings(lst, role_list)
    for _, r in pairs(role_list) do
        local rolestring = ROLE_STRINGS_RAW[r]
        local percent = xlib.makeslider { label = "ttt_" .. rolestring .. "_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_" .. rolestring .. "_shop_random_percent", parent = lst }
        lst:AddItem(percent)

        local enabled = xlib.makecheckbox { label = "ttt_" .. rolestring .. "_shop_random_enabled (def. 0)", repconvar = "rep_ttt_" .. rolestring .. "_shop_random_enabled", parent = lst }
        lst:AddItem(enabled)
    end
end

local function HasShopSync(role)
    return (TRAITOR_ROLES[role] and role ~= ROLE_TRAITOR) or (DETECTIVE_ROLES[role] and role ~= ROLE_DETECTIVE) or ROLE_HAS_SHOP_SYNC[role]
end

local function GetShopSyncCvars(role_list)
    local cvar_list = {}
    for _, r in pairs(role_list) do
        if HasShopSync(r) then
            table.insert(cvar_list, "ttt_" .. ROLE_STRINGS_RAW[r] .. "_shop_sync")
        end
    end
    return cvar_list
end

local function AddShopSyncSettings(lst, cvar_list)
    for _, c in pairs(cvar_list) do
        local default = GetReplicatedConVarDefault(c, "0")
        local sync = xlib.makecheckbox { label = c .. " (def. " .. default .. ")", repconvar = "rep_".. c, parent = lst }
        lst:AddItem(sync)

        -- Save the control so it can be updated later
        if missing_cvars[c] then
            missing_cvars[c] = sync
        end
    end
end

local function GetShopModeCvars(role_list)
    local cvar_list = {}
    for _, r in pairs(role_list) do
        -- Roles don't get both sync and mode
        if (INDEPENDENT_ROLES[r] or DELAYED_SHOP_ROLES[r] or ROLE_HAS_SHOP_MODE[r]) and not HasShopSync(r) then
            table.insert(cvar_list,  "ttt_" .. ROLE_STRINGS_RAW[r] .. "_shop_mode")
        end
    end
    return cvar_list
end

local function AddShopModeSettings(lst, cvar_list)
    for _, c in pairs(cvar_list) do
        local default = GetReplicatedConVarDefault(c, "0")
        local mode = xlib.makeslider { label = c .. " (def. " .. default .. ")", min = 0, max = 4, repconvar = "rep_".. c, parent = lst }
        lst:AddItem(mode)

        -- Save the control so it can be updated later
        if missing_cvars[c] then
            missing_cvars[c] = mode
        end
    end
end

local function GetShopActiveCvars(role_list)
    local cvar_list = {}
    for _, r in pairs(role_list) do
        if DELAYED_SHOP_ROLES[r] then
            table.insert(cvar_list,  "ttt_" .. ROLE_STRINGS_RAW[r] .. "_shop_active_only")
        end
    end
    return cvar_list
end

local function AddShopActiveSettings(lst, cvar_list)
    for _, c in pairs(cvar_list) do
        local default = GetReplicatedConVarDefault(c, "0")
        local active = xlib.makecheckbox { label = c .. " (def. " .. default .. ")", repconvar = "rep_".. c, parent = lst }
        lst:AddItem(active)

        -- Save the control so it can be updated later
        if missing_cvars[c] then
            missing_cvars[c] = active
        end
    end
end

local function GetShopDelayCvars(role_list)
    local cvar_list = {}
    for _, r in pairs(role_list) do
        if DELAYED_SHOP_ROLES[r] then
            table.insert(cvar_list,  "ttt_" .. ROLE_STRINGS_RAW[r] .. "_shop_delay")
        end
    end
    return cvar_list
end

local function AddShopDelaySettings(lst, cvar_list)
    for _, c in pairs(cvar_list) do
        local default = GetReplicatedConVarDefault(c, "0")
        local delay = xlib.makecheckbox { label = c .. " (def. " .. default .. ")", repconvar = "rep_".. c, parent = lst }
        lst:AddItem(delay)

        -- Save the control so it can be updated later
        if missing_cvars[c] then
            missing_cvars[c] = delay
        end
    end
end

local function AddRoleShop(gppnl)
    local shop_roles = GetShopRoles()
    local traitor_shops = table.IntersectedKeys(TRAITOR_ROLES, shop_roles)
    SortRolesByName(traitor_shops)
    local traitor_syncs = GetShopSyncCvars(traitor_shops)
    local traitor_modes = GetShopModeCvars(traitor_shops)
    local traitor_actives = GetShopActiveCvars(traitor_shops)
    local traitor_delays = GetShopDelayCvars(traitor_shops)
    local inno_shops = table.IntersectedKeys(INNOCENT_ROLES, shop_roles)
    SortRolesByName(inno_shops)
    local inno_syncs = GetShopSyncCvars(inno_shops)
    local inno_modes = GetShopModeCvars(inno_shops)
    local inno_actives = GetShopActiveCvars(inno_shops)
    local inno_delays = GetShopDelayCvars(inno_shops)
    local indep_shops = table.IntersectedKeys(INDEPENDENT_ROLES, shop_roles)
    SortRolesByName(indep_shops)
    local indep_syncs = GetShopSyncCvars(indep_shops)
    local indep_modes = GetShopModeCvars(indep_shops)
    local indep_actives = GetShopActiveCvars(indep_shops)
    local indep_delays = GetShopDelayCvars(indep_shops)
    local jester_shops = table.IntersectedKeys(JESTER_ROLES, shop_roles)
    SortRolesByName(jester_shops)
    local jester_syncs = GetShopSyncCvars(jester_shops)
    local jester_modes = GetShopModeCvars(jester_shops)
    local jester_actives = GetShopActiveCvars(jester_shops)
    local jester_delays = GetShopDelayCvars(jester_shops)
    local monster_shops = table.IntersectedKeys(MONSTER_ROLES, shop_roles)
    SortRolesByName(monster_shops)
    local monster_syncs = GetShopSyncCvars(monster_shops)
    local monster_modes = GetShopModeCvars(monster_shops)
    local monster_actives = GetShopActiveCvars(monster_shops)
    local monster_delays = GetShopDelayCvars(monster_shops)
    local height = 155 + (45 * #traitor_shops) + (20 * #traitor_syncs) + (25 * #traitor_modes) + (20 * #traitor_actives) + (20 * #traitor_delays) +
                        (45 * #inno_shops) + (20 * #inno_syncs) + (25 * #inno_modes) + (20 * #inno_actives) + (20 * #inno_delays) +
                        (45 * #indep_shops) + (20 * #indep_syncs) + (25 * #indep_modes) + (20 * #indep_actives) + (20 * #indep_delays) +
                        (45 * #jester_shops) + (20 * #jester_syncs) + (25 * #jester_modes) + (20 * #jester_actives) + (20 * #jester_delays) +
                        (45 * #monster_shops) + (20 * #monster_syncs) + (25 * #monster_modes) + (20 * #monster_actives) + (20 * #monster_delays)
    local rspnl = vgui.Create("DCollapsibleCategory", gppnl)
    rspnl:SetSize(390, height)
    rspnl:SetExpanded(0)
    rspnl:SetLabel("Role Shop")

    local rslst = vgui.Create("DPanelList", rspnl)
    rslst:SetPos(5, 25)
    rslst:SetSize(390, height)
    rslst:SetSpacing(5)

    local openButton = xlib.makebutton{w=150, label="Open Role Weapons Config", parent=rslst}
    openButton.DoClick=function()
        RunConsoleCommand("ttt_roleweapons")
    end

    local rsfa = xlib.makecheckbox { label = "ttt_shop_for_all (def. 0)", repconvar = "rep_ttt_shop_for_all", parent = rslst }
    rslst:AddItem(rsfa)

    local rsp = xlib.makeslider { label = "ttt_shop_random_percent (def. 50)", min = 0, max = 100, repconvar = "rep_ttt_shop_random_percent", parent = rslst }
    rslst:AddItem(rsp)

    local rspos = xlib.makecheckbox { label = "ttt_shop_random_position (def. 0)", repconvar = "rep_ttt_shop_random_position", parent = rslst }
    rslst:AddItem(rspos)

    local tralbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Traitors:", parent = rslst }
    rslst:AddItem(tralbl)

    AddShopRandomizationSettings(rslst, traitor_shops)
    AddShopSyncSettings(rslst, traitor_syncs)
    AddShopModeSettings(rslst, traitor_modes)
    AddShopActiveSettings(rslst, traitor_actives)
    AddShopDelaySettings(rslst, traitor_delays)

    local innlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Innocents:", parent = rslst }
    rslst:AddItem(innlbl)

    AddShopRandomizationSettings(rslst, inno_shops)
    AddShopSyncSettings(rslst, inno_syncs)
    AddShopModeSettings(rslst, inno_modes)
    AddShopActiveSettings(rslst, inno_actives)
    AddShopDelaySettings(rslst, inno_delays)

    local jeslbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Jesters:", parent = rslst }
    rslst:AddItem(jeslbl)

    AddShopRandomizationSettings(rslst, jester_shops)
    AddShopSyncSettings(rslst, jester_syncs)
    AddShopModeSettings(rslst, jester_modes)
    AddShopActiveSettings(rslst, jester_actives)
    AddShopDelaySettings(rslst, jester_delays)

    local indlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Independents:", parent = rslst }
    rslst:AddItem(indlbl)

    AddShopRandomizationSettings(rslst, indep_shops)
    AddShopSyncSettings(rslst, indep_syncs)
    AddShopModeSettings(rslst, indep_modes)
    AddShopActiveSettings(rslst, indep_actives)
    AddShopDelaySettings(rslst, indep_delays)

    local monlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Monsters:", parent = rslst }
    rslst:AddItem(monlbl)

    AddShopRandomizationSettings(rslst, monster_shops)
    AddShopSyncSettings(rslst, monster_syncs)
    AddShopModeSettings(rslst, monster_modes)
    AddShopActiveSettings(rslst, monster_actives)
    AddShopDelaySettings(rslst, monster_delays)
end

local function AddDna(gppnl)
    local gpdnaclp = vgui.Create("DCollapsibleCategory", gppnl)
    gpdnaclp:SetSize(390, 70)
    gpdnaclp:SetExpanded(0)
    gpdnaclp:SetLabel("DNA")

    local gpdnalst = vgui.Create("DPanelList", gpdnaclp)
    gpdnalst:SetPos(5, 25)
    gpdnalst:SetSize(390, 70)
    gpdnalst:SetSpacing(5)

    local dnarange = xlib.makeslider { label = "ttt_killer_dna_range (def. 550)", min = 100, max = 1000, repconvar = "rep_ttt_killer_dna_range", parent = gpdnalst }
    gpdnalst:AddItem(dnarange)

    local dnakbt = xlib.makeslider { label = "ttt_killer_dna_basetime (def. 100)", min = 10, max = 200, repconvar = "rep_ttt_killer_dna_basetime", parent = gpdnalst }
    gpdnalst:AddItem(dnakbt)

    local dnasid = xlib.makecheckbox { label = "ttt_dna_scan_on_dialog (def. 1)", repconvar = "rep_ttt_dna_scan_on_dialog", parent = gpdnalst }
    gpdnalst:AddItem(dnasid)
end

local function AddVoiceChat(gppnl)
    local gpvcbclp = vgui.Create("DCollapsibleCategory", gppnl)
    gpvcbclp:SetSize(390, 65)
    gpvcbclp:SetExpanded(0)
    gpvcbclp:SetLabel("Voice Chat Battery")

    local gpvcblst = vgui.Create("DPanelList", gpvcbclp)
    gpvcblst:SetPos(5, 25)
    gpvcblst:SetSize(390, 65)
    gpvcblst:SetSpacing(5)

    local gpevd = xlib.makecheckbox { label = "ttt_voice_drain (def. 0)", repconvar = "rep_ttt_voice_drain", parent = gpvcblst }
    gpvcblst:AddItem(gpevd)

    local gpvdn = xlib.makeslider { label = "ttt_voice_drain_normal (def. 0.2)", min = 0.1, max = 1, decimal = 1, repconvar = "rep_ttt_voice_drain_normal", parent = gpvcblst }
    gpvcblst:AddItem(gpvdn)

    local gpvda = xlib.makeslider { label = "ttt_voice_drain_admin (def. 0.05)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_voice_drain_admin", parent = gpvcblst }
    gpvcblst:AddItem(gpvda)

    local gpvdr = xlib.makeslider { label = "ttt_voice_drain_recharge (def. 0.05)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_voice_drain_recharge", parent = gpvcblst }
    gpvcblst:AddItem(gpvdr)
end

local function AddOtherGameplay(gppnl)
    --Other Gameplay Settings
    local gpogsclp = vgui.Create("DCollapsibleCategory", gppnl)
    gpogsclp:SetSize(390, 220)
    gpogsclp:SetExpanded(0)
    gpogsclp:SetLabel("Other Gameplay Settings")

    local gpogslst = vgui.Create("DPanelList", gpogsclp)
    gpogslst:SetPos(5, 25)
    gpogslst:SetSize(390, 220)
    gpogslst:SetSpacing(5)

    local gpminply = xlib.makeslider { label = "ttt_minimum_players (def. 2)", min = 1, max = 10, repconvar = "rep_ttt_minimum_players", parent = gpogslst }
    gpogslst:AddItem(gpminply)

    local gpprdm = xlib.makecheckbox { label = "ttt_postround_dm (def. 0)", repconvar = "rep_ttt_postround_dm", parent = gpogslst }
    gpogslst:AddItem(gpprdm)

    local gpds = xlib.makecheckbox { label = "ttt_dyingshot (def. 0)", repconvar = "rep_ttt_dyingshot", parent = gpogslst }
    gpogslst:AddItem(gpds)

    local gpnntdp = xlib.makecheckbox { label = "ttt_no_nade_throw_during_prep (def. 0)", repconvar = "rep_ttt_no_nade_throw_during_prep", parent = gpogslst }
    gpogslst:AddItem(gpnntdp)

    local gpwc = xlib.makecheckbox { label = "ttt_weapon_carrying (def. 1)", repconvar = "rep_ttt_weapon_carrying", parent = gpogslst }
    gpogslst:AddItem(gpwc)

    local gpwcr = xlib.makeslider { label = "ttt_weapon_carrying_range (def. 50)", min = 10, max = 100, repconvar = "rep_ttt_weapon_carrying_range", parent = gpogslst }
    gpogslst:AddItem(gpwcr)

    local gpttf = xlib.makecheckbox { label = "ttt_teleport_telefrags (def. 0)", repconvar = "rep_ttt_teleport_telefrags", parent = gpogslst }
    gpogslst:AddItem(gpttf)

    local gprdp = xlib.makecheckbox { label = "ttt_ragdoll_pinning (def. 1)", repconvar = "rep_ttt_ragdoll_pinning", parent = gpogslst }
    gpogslst:AddItem(gprdp)

    local gprdpi = xlib.makecheckbox { label = "ttt_ragdoll_pinning_innocents (def. 0)", repconvar = "rep_ttt_ragdoll_pinning_innocents", parent = gpogslst }
    gpogslst:AddItem(gprdpi)

    local gprdne = xlib.makecheckbox { label = "ttt_death_notifier_enabled (def. 1)", repconvar = "rep_ttt_death_notifier_enabled", parent = gpogslst }
    gpogslst:AddItem(gprdne)
end

local function AddGameplayModule()
    local gppnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    AddTraitorAndDetectiveSettings(gppnl)
    AddSpecialistTraitorSettings(gppnl)
    AddSpecialistDetectiveSettings(gppnl)
    AddSpecialistInnocentSettings(gppnl)
    AddIndependentRoleSettings(gppnl)
    AddMonsterSettings(gppnl)
    AddRoleHealthSettings(gppnl)
    AddTraitorProperties(gppnl)
    AddDetectiveProperties(gppnl)
    AddInnocentProperties(gppnl)
    AddJesterRoleProperties(gppnl)
    AddIndependentRoleProperties(gppnl)
    AddMonsterRoleProperties(gppnl)
    AddCustomRoleProperties(gppnl)
    AddRoleShop(gppnl)
    AddDna(gppnl)
    AddVoiceChat(gppnl)
    AddOtherGameplay(gppnl)

    xgui.hookEvent("onProcessModules", nil, gppnl.processModules)
    xgui.addSubModule("Gameplay", gppnl, nil, "terrortown_settings")
end

local function AddKarmaModule()
    local krmpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local krmclp = vgui.Create("DCollapsibleCategory", krmpnl)
    krmclp:SetSize(390, 440)
    krmclp:SetExpanded(1)
    krmclp:SetLabel("Karma")

    local krmlst = vgui.Create("DPanelList", krmclp)
    krmlst:SetPos(5, 25)
    krmlst:SetSize(390, 440)
    krmlst:SetSpacing(5)

    local krmekrm = xlib.makecheckbox { label = "ttt_karma", repconvar = "rep_ttt_karma", parent = krmlst }
    krmlst:AddItem(krmekrm)

    local krmeskrm = xlib.makecheckbox { label = "ttt_karma_strict", repconvar = "rep_ttt_karma_strict", parent = krmlst }
    krmlst:AddItem(krmeskrm)

    local krms = xlib.makeslider { label = "ttt_karma_starting (def. 1000)", min = 500, max = 2000, repconvar = "rep_ttt_karma_starting", parent = krmlst }
    krmlst:AddItem(krms)

    local krmmx = xlib.makeslider { label = "ttt_karma_max (def. 1000)", min = 500, max = 2000, repconvar = "rep_ttt_karma_max", parent = krmlst }
    krmlst:AddItem(krmmx)

    local krmr = xlib.makeslider { label = "ttt_karma_ratio (def. 0.001)", min = 0.001, max = 0.009, decimal = 3, repconvar = "rep_ttt_karma_ratio", parent = krmlst }
    krmlst:AddItem(krmr)

    local krmkp = xlib.makeslider { label = "ttt_karma_kill_penalty (def. 15)", min = 1, max = 30, repconvar = "rep_ttt_karma_kill_penalty", parent = krmlst }
    krmlst:AddItem(krmkp)

    local krmri = xlib.makeslider { label = "ttt_karma_round_increment (def. 5)", min = 1, max = 30, repconvar = "rep_ttt_karma_round_increment", parent = krmlst }
    krmlst:AddItem(krmri)

    local krmcb = xlib.makeslider { label = "ttt_karma_clean_bonus (def. 30)", min = 10, max = 100, repconvar = "rep_ttt_karma_clean_bonus", parent = krmlst }
    krmlst:AddItem(krmcb)

    local krmtdmgr = xlib.makeslider { label = "ttt_karma_traitordmg_ratio (def. 0.0003)", min = 0.0001, max = 0.001, decimal = 4, repconvar = "rep_ttt_karma_traitordmg_ratio", parent = krmlst }
    krmlst:AddItem(krmtdmgr)

    local krmtkb = xlib.makeslider { label = "ttt_karma_traitorkill_bonus (def. 40)", min = 10, max = 100, repconvar = "rep_ttt_karma_traitorkill_bonus", parent = krmlst }
    krmlst:AddItem(krmtkb)

    local krmjdmgr = xlib.makeslider { label = "ttt_karma_jesterdmg_ratio (def. 0.5)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_karma_jesterdmg_ratio", parent = krmlst }
    krmlst:AddItem(krmjdmgr)

    local krmjkp = xlib.makeslider { label = "ttt_karma_jesterkill_penalty (def. 50)", min = 10, max = 100, repconvar = "rep_ttt_karma_jesterkill_penalty", parent = krmlst }
    krmlst:AddItem(krmjkp)

    local krmlak = xlib.makecheckbox { label = "ttt_karma_low_autokick (def. 1)", repconvar = "rep_ttt_karma_low_autokick", parent = krmlst }
    krmlst:AddItem(krmlak)

    local krmla = xlib.makeslider { label = "ttt_karma_low_amount (def. 450)", min = 100, max = 1000, repconvar = "rep_ttt_karma_low_amount", parent = krmlst }
    krmlst:AddItem(krmla)

    local krmlab = xlib.makecheckbox { label = "ttt_karma_low_ban (def. 1)", repconvar = "rep_ttt_karma_low_ban", parent = krmlst }
    krmlst:AddItem(krmlab)

    local krmlbm = xlib.makeslider { label = "ttt_karma_low_ban_minutes (def. 60)", min = 10, max = 100, repconvar = "rep_ttt_karma_low_ban_minutes", parent = krmlst }
    krmlst:AddItem(krmlbm)

    local krmpre = xlib.makecheckbox { label = "ttt_karma_persist (def. 0)", repconvar = "rep_ttt_karma_persist", parent = krmlst }
    krmlst:AddItem(krmpre)

    local krmdbs = xlib.makecheckbox { label = "ttt_karma_debugspam (def. 0)", repconvar = "rep_ttt_karma_debugspam", parent = krmlst }
    krmlst:AddItem(krmdbs)

    local krmch = xlib.makeslider { label = "ttt_karma_clean_half (def. 0.25)", min = 0.01, max = 0.9, decimal = 2, repconvar = "rep_ttt_karma_clean_half", parent = krmlst }
    krmlst:AddItem(krmch)

    xgui.hookEvent("onProcessModules", nil, krmpnl.processModules)
    xgui.addSubModule("Karma", krmpnl, nil, "terrortown_settings")
end

local function AddMapModule()
    local mprpnl = xlib.makepanel { w = 415, h = 318, parent = xgui.null }

    local mprpp = vgui.Create("DCollapsibleCategory", mprpnl)
    mprpp:SetSize(390, 50)
    mprpp:SetExpanded(1)
    mprpp:SetLabel("Map-related")

    local mprlst = vgui.Create("DPanelList", mprpp)
    mprlst:SetPos(5, 25)
    mprlst:SetSize(390, 50)
    mprlst:SetSpacing(5)

    local mprwss = xlib.makecheckbox { label = "ttt_use_weapon_spawn_scripts (def. 1)", repconvar = "rep_ttt_use_weapon_spawn_scripts", parent = mprlst }
    mprlst:AddItem(mprwss)

    local mpwsc = xlib.makecheckbox { label = "ttt_weapon_spawn_count (def. 0)", repconvar = "rep_ttt_weapon_spawn_count", parent = mprlst }
    mprlst:AddItem(mpwsc)

    xgui.hookEvent("onProcessModules", nil, mprpnl.processModules)
    xgui.addSubModule("Map-related", mprpnl, nil, "terrortown_settings")
end

local function AddRoleCreditsSlider(role_shops, lst)
    for _, r in ipairs(role_shops) do
        local role_string = ROLE_STRINGS_RAW[r]
        local convar = "ttt_" .. role_string .. "_credits_starting"
        local default = GetReplicatedConVarDefault(convar, "0")
        local slider = xlib.makeslider { label = convar .. " (def. " .. default .. ")", min = 0, max = 10, repconvar = "rep_" .. convar, parent = lst }
        lst:AddItem(slider)

        -- Save the control so it can be updated later
        if missing_cvars[convar] then
            missing_cvars[convar] = slider
        end
    end
end

local function AddRoleCreditSection(pnl, label, role_list, excludes)
    local credit_roles = GetCreditRoles()
    local role_shops = table.IntersectedKeys(role_list, credit_roles, excludes)
    SortRolesByName(role_shops)
    local cat = vgui.Create("DCollapsibleCategory", pnl)
    cat:SetSize(390, #role_shops * 25)
    cat:SetExpanded(0)
    cat:SetLabel(label .. " Credits")

    local lst = vgui.Create("DPanelList", cat)
    lst:SetPos(5, 25)
    lst:SetSize(390, #role_shops * 25)
    lst:SetSpacing(5)

    AddRoleCreditsSlider(role_shops, lst)
end

local function AddEquipmentCreditsModule()
    local ecpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    --Traitor Credits
    local credit_roles =  GetCreditRoles()
    local traitor_shops = table.IntersectedKeys(TRAITOR_ROLES, credit_roles, {ROLE_TRAITOR})
    SortRolesByName(traitor_shops)
    local ectcclp = vgui.Create("DCollapsibleCategory", ecpnl)
    ectcclp:SetSize(390, 170 + (25 * #traitor_shops))
    ectcclp:SetExpanded(1)
    ectcclp:SetLabel("Traitor Credits")

    local ectclst = vgui.Create("DPanelList", ectcclp)
    ectclst:SetPos(5, 25)
    ectclst:SetSize(390, 170 + (25 * #traitor_shops))
    ectclst:SetSpacing(5)

    local ectcct = xlib.makeslider { label = "ttt_traitors_credits_timer (def. 0)", min = 0, max = 240, repconvar = "rep_ttt_traitors_credits_timer", parent = ectclst }
    ectclst:AddItem(ectcct)

    local ectccs = xlib.makeslider { label = "ttt_credits_starting (def. 2)", min = 0, max = 10, repconvar = "rep_ttt_credits_starting", parent = ectclst }
    ectclst:AddItem(ectccs)

    AddRoleCreditsSlider(traitor_shops, ectclst)

    local ectcab = xlib.makecheckbox { label = "ttt_credits_alonebonus (def. 1)", repconvar = "rep_ttt_credits_alonebonus", parent = ectclst }
    ectclst:AddItem(ectcab)

    local ectcap = xlib.makeslider { label = "ttt_credits_award_pct (def. 0.35)", min = 0.01, max = 0.9, decimal = 2, repconvar = "rep_ttt_credits_award_pct", parent = ectclst }
    ectclst:AddItem(ectcap)

    local ectcas = xlib.makeslider { label = "ttt_credits_award_size (def. 1)", min = 0, max = 5, repconvar = "rep_ttt_credits_award_size", parent = ectclst }
    ectclst:AddItem(ectcas)

    local ectcar = xlib.makeslider { label = "ttt_credits_award_repeat (def. 1)", min = 0, max = 5, repconvar = "rep_ttt_credits_award_repeat", parent = ectclst }
    ectclst:AddItem(ectcar)

    local ectcdk = xlib.makeslider { label = "ttt_credits_detectivekill (def. 1)", min = 0, max = 5, repconvar = "rep_ttt_credits_detectivekill", parent = ectclst }
    ectclst:AddItem(ectcdk)

    --Detective Credits
    local detective_shops = table.IntersectedKeys(DETECTIVE_ROLES, credit_roles, {ROLE_DETECTIVE})
    SortRolesByName(detective_shops)
    local ecdcclp = vgui.Create("DCollapsibleCategory", ecpnl)
    ecdcclp:SetSize(390, 100 + (25 * #detective_shops))
    ecdcclp:SetExpanded(0)
    ecdcclp:SetLabel("Detective Credits")

    local ecdclst = vgui.Create("DPanelList", ecdcclp)
    ecdclst:SetPos(5, 25)
    ecdclst:SetSize(390, 100 + (25 * #detective_shops))
    ecdclst:SetSpacing(5)

    local ecdcct = xlib.makeslider { label = "ttt_detectives_credits_timer (def. 0)", min = 0, max = 240, repconvar = "rep_ttt_detectives_credits_timer", parent = ecdclst }
    ecdclst:AddItem(ecdcct)

    local ecdccs = xlib.makeslider { label = "ttt_det_credits_starting (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_det_credits_starting", parent = ecdclst }
    ecdclst:AddItem(ecdccs)

    AddRoleCreditsSlider(detective_shops, ecdclst)

    local ecdctk = xlib.makeslider { label = "ttt_det_credits_traitorkill (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_det_credits_traitorkill", parent = ecdclst }
    ecdclst:AddItem(ecdctk)

    local ecdctd = xlib.makeslider { label = "ttt_det_credits_traitordead (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_det_credits_traitordead", parent = ecdclst }
    ecdclst:AddItem(ecdctd)

    AddRoleCreditSection(ecpnl, "Jester", JESTER_ROLES)
    AddRoleCreditSection(ecpnl, "Innocent", INNOCENT_ROLES, GetTeamRoles(DETECTIVE_ROLES))
    AddRoleCreditSection(ecpnl, "Independent", INDEPENDENT_ROLES)

    xgui.hookEvent("onProcessModules", nil, ecpnl.processModules)
    xgui.addSubModule("Equipment Credits", ecpnl, nil, "terrortown_settings")
end

local function AddPlayerMovementModule()
    local pmpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local pmspp = vgui.Create("DCollapsibleCategory", pmpnl)
    pmspp:SetSize(390, 120)
    pmspp:SetExpanded(1)
    pmspp:SetLabel("Sprint")

    local pmsplst = vgui.Create("DPanelList", pmspp)
    pmsplst:SetPos(5, 25)
    pmsplst:SetSize(390, 120)
    pmsplst:SetSpacing(5)

    local pmspe = xlib.makecheckbox { label = "ttt_sprint_enabled  (def. 1)", repconvar = "rep_ttt_sprint_enabled", parent = pmsplst }
    pmsplst:AddItem(pmspe)

    local pmspbr = xlib.makeslider { label = "ttt_sprint_bonus_rel (def. 0.4)", min = 0.1, max = 2, decimal = 1, repconvar = "rep_ttt_sprint_bonus_rel", parent = pmsplst }
    pmsplst:AddItem(pmspbr)

    local pmspri = xlib.makeslider { label = "ttt_sprint_regenerate_innocent (def. 0.08)", min = 0.01, max = 2, decimal = 2, repconvar = "rep_ttt_sprint_regenerate_innocent", parent = pmsplst }
    pmsplst:AddItem(pmspri)

    local pmsprt = xlib.makeslider { label = "ttt_sprint_regenerate_traitor (def. 0.12)", min = 0.01, max = 2, decimal = 2, repconvar = "rep_ttt_sprint_regenerate_traitor", parent = pmsplst }
    pmsplst:AddItem(pmsprt)

    local pmspc = xlib.makeslider { label = "ttt_sprint_consume (def. 0.2)", min = 0.1, max = 5, decimal = 1, repconvar = "rep_ttt_sprint_consume", parent = pmsplst }
    pmsplst:AddItem(pmspc)

    xgui.hookEvent("onProcessModules", nil, pmpnl.processModules)
    xgui.addSubModule("Player Movement", pmpnl, nil, "terrortown_settings")
end

local function AddPropPossessionModule()
    local pppnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local ppclp = vgui.Create("DCollapsibleCategory", pppnl)
    ppclp:SetSize(390, 120)
    ppclp:SetExpanded(1)
    ppclp:SetLabel("Prop Possession")

    local pplst = vgui.Create("DPanelList", ppclp)
    pplst:SetPos(5, 25)
    pplst:SetSize(390, 120)
    pplst:SetSpacing(5)

    local ppspc = xlib.makecheckbox { label = "ttt_spec_prop_control  (def. 1)", repconvar = "rep_ttt_spec_prop_control", parent = pplst }
    pplst:AddItem(ppspc)

    local ppspb = xlib.makeslider { label = "ttt_spec_prop_base (def. 8)", min = 0, max = 50, repconvar = "rep_ttt_spec_prop_base", parent = pplst }
    pplst:AddItem(ppspb)

    local ppspmp = xlib.makeslider { label = "ttt_spec_prop_maxpenalty (def. -6)", min = -50, max = 0, repconvar = "rep_ttt_spec_prop_maxpenalty", parent = pplst }
    pplst:AddItem(ppspmp)

    local ppspmb = xlib.makeslider { label = "ttt_spec_prop_maxbonus (def. 16)", min = 0, max = 50, repconvar = "rep_ttt_spec_prop_maxbonus", parent = pplst }
    pplst:AddItem(ppspmb)

    local ppspf = xlib.makeslider { label = "ttt_spec_prop_force (def. 110)", min = 50, max = 300, repconvar = "rep_ttt_spec_prop_force", parent = pplst }
    pplst:AddItem(ppspf)

    local ppprt = xlib.makeslider { label = "ttt_spec_prop_rechargetime (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_spec_prop_rechargetime", parent = pplst }
    pplst:AddItem(ppprt)

    xgui.hookEvent("onProcessModules", nil, pppnl.processModules)
    xgui.addSubModule("Prop Possession", pppnl, nil, "terrortown_settings")
end

local function AddAdminModule()
    -------------------- Admin-related Module--------------------
    local arpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local arclp = vgui.Create("DCollapsibleCategory", arpnl)
    arclp:SetSize(390, 120)
    arclp:SetExpanded(1)
    arclp:SetLabel("Admin-related")

    local arlst = vgui.Create("DPanelList", arclp)
    arlst:SetPos(5, 25)
    arlst:SetSize(390, 120)
    arlst:SetSpacing(5)

    local aril = xlib.makeslider { label = "ttt_idle_limit (def. 180)", min = 50, max = 300, repconvar = "rep_ttt_idle_limit", parent = arlst }
    arlst:AddItem(aril)

    local arnck = xlib.makecheckbox { label = "ttt_namechange_kick (def. 1)", repconvar = "rep_ttt_namechange_kick", parent = arlst }
    arlst:AddItem(arnck)

    local arncbt = xlib.makeslider { label = "ttt_namechange_bantime (def. 10)", min = 0, max = 60, repconvar = "rep_ttt_namechange_bantime", parent = arlst }
    arlst:AddItem(arncbt)

    xgui.hookEvent("onProcessModules", nil, arpnl.processModules)
    xgui.addSubModule("Admin-related", arpnl, nil, "terrortown_settings")
end

local function AddMiscModule()
    -------------------- Miscellaneous Module--------------------
    local miscpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local bempnl = vgui.Create("DCollapsibleCategory", miscpnl)
    bempnl:SetSize(390, 100)
    bempnl:SetExpanded(1)
    bempnl:SetLabel("Better Equipment Menu")

    local bemlst = vgui.Create("DPanelList", bempnl)
    bemlst:SetPos(5, 25)
    bemlst:SetSize(390, 100)
    bemlst:SetSpacing(5)

    local bemac = xlib.makecheckbox { label = "ttt_bem_allow_change (def. 1)", repconvar = "rep_ttt_bem_allow_change", parent = bemlst }
    bemlst:AddItem(bemac)

    local bemcol = xlib.makeslider { label = "ttt_bem_sv_cols (def. 4)", min = 1, max = 10, repconvar = "rep_ttt_bem_sv_cols", parent = bemlst }
    bemlst:AddItem(bemcol)

    local bemrow = xlib.makeslider { label = "ttt_bem_sv_rows (def. 5)", min = 1, max = 10, repconvar = "rep_ttt_bem_sv_rows", parent = bemlst }
    bemlst:AddItem(bemrow)

    local bemsize = xlib.makeslider { label = "ttt_bem_sv_size (def. 64)", min = 16, max = 128, repconvar = "rep_ttt_bem_sv_size", parent = bemlst }
    bemlst:AddItem(bemsize)

    local miscclp = vgui.Create("DCollapsibleCategory", miscpnl)
    miscclp:SetSize(390, 375)
    miscclp:SetExpanded(1)
    miscclp:SetLabel("Miscellaneous")

    local misclst = vgui.Create("DPanelList", miscclp)
    misclst:SetPos(5, 25)
    misclst:SetSize(390, 375)
    misclst:SetSpacing(5)

    local miscdh = xlib.makecheckbox { label = "ttt_detective_hats (def. 0)", repconvar = "rep_ttt_detective_hats", parent = misclst }
    misclst:AddItem(miscdh)

    local miscpcm = xlib.makeslider { label = "ttt_playercolor_mode (def. 1)", min = 0, max = 3, repconvar = "rep_ttt_playercolor_mode", parent = misclst }
    misclst:AddItem(miscpcm)

    local miscrc = xlib.makecheckbox { label = "ttt_ragdoll_collide (def. 0)", repconvar = "rep_ttt_ragdoll_collide", parent = misclst }
    misclst:AddItem(miscrc)

    local miscbs = xlib.makecheckbox { label = "ttt_bots_are_spectators (def. 0)", repconvar = "rep_ttt_bots_are_spectators", parent = misclst }
    misclst:AddItem(miscbs)

    local miscdpw = xlib.makecheckbox { label = "ttt_debug_preventwin (def. 0)", repconvar = "rep_ttt_debug_preventwin", parent = misclst }
    misclst:AddItem(miscdpw)

    local miscdlk = xlib.makecheckbox { label = "ttt_debug_logkills (def. 1)", repconvar = "rep_ttt_debug_logkills", parent = misclst }
    misclst:AddItem(miscdlk)

    local miscdlr = xlib.makecheckbox { label = "ttt_debug_logroles (def. 1)", repconvar = "rep_ttt_debug_logroles", parent = misclst }
    misclst:AddItem(miscdlr)

    local misclv = xlib.makecheckbox { label = "ttt_locational_voice (def. 0)", repconvar = "rep_ttt_locational_voice", parent = misclst }
    misclst:AddItem(misclv)

    local miscdj = xlib.makecheckbox { label = "ttt_allow_discomb_jump (def. 0)", repconvar = "rep_ttt_allow_discomb_jump", parent = misclst }
    misclst:AddItem(miscdj)

    local miscswi = xlib.makeslider { label = "ttt_spawn_wave_interval (def. 0)", min = 0, max = 30, repconvar = "rep_ttt_spawn_wave_interval", parent = misclst }
    misclst:AddItem(miscswi)

    local misccu = xlib.makecheckbox { label = "ttt_crowbar_unlocks (def. 1)", repconvar = "rep_ttt_crowbar_unlocks", parent = misclst }
    misclst:AddItem(misccu)

    local misccp = xlib.makeslider { label = "ttt_crowbar_pushforce (def. 395)", min = 0, max = 10000, repconvar = "rep_ttt_crowbar_pushforce", parent = misclst }
    misclst:AddItem(misccp)

    local miscsd = xlib.makecheckbox { label = "ttt_scoreboard_deaths (def. 0)", repconvar = "rep_ttt_scoreboard_deaths", parent = misclst }
    misclst:AddItem(miscsd)

    local miscss = xlib.makecheckbox { label = "ttt_scoreboard_score (def. 0)", repconvar = "rep_ttt_scoreboard_score", parent = misclst }
    misclst:AddItem(miscss)

    local miscrstlbl = xlib.makelabel { label = "ttt_round_summary_tabs (def. summary,hilite,events,scores)", parent = misclst }
    misclst:AddItem(miscrstlbl)
    local miscrsttb = xlib.maketextbox { repconvar = "rep_ttt_round_summary_tabs", enableinput = true, parent = misclst }
    misclst:AddItem(miscrsttb)

    local miscse = xlib.makecheckbox { label = "ttt_smokegrenade_extinguish (def. 1)", repconvar = "rep_ttt_smokegrenade_extinguish", parent = misclst }
    misclst:AddItem(miscse)

    local miscplc = xlib.makecheckbox { label = "ttt_player_set_color (def. 1)", repconvar = "rep_ttt_player_set_color", parent = misclst }
    misclst:AddItem(miscplc)

    --Disable Features
    local dfclp = vgui.Create("DCollapsibleCategory", miscpnl)
    dfclp:SetSize(390, 50)
    dfclp:SetExpanded(1)
    dfclp:SetLabel("Disable Features")

    local dflst = vgui.Create("DPanelList", dfclp)
    dflst:SetPos(5, 25)
    dflst:SetSize(390, 50)
    dflst:SetSpacing(5)

    local dfdh = xlib.makecheckbox { label = "ttt_disable_headshots (def. 0)", repconvar = "rep_ttt_disable_headshots", parent = dflst }
    dflst:AddItem(dfdh)

    local dfdmw = xlib.makecheckbox { label = "ttt_disable_mapwin (def. 0)", repconvar = "rep_ttt_disable_mapwin", parent = dflst }
    dflst:AddItem(dfdmw)

    xgui.hookEvent("onProcessModules", nil, miscpnl.processModules)
    xgui.addSubModule("Miscellaneous", miscpnl, nil, "terrortown_settings")
end

hook.Add("InitPostEntity", "CustomRolesLocalLoad", function()
    AddRoundStructureModule()
    AddGameplayModule()
    AddKarmaModule()
    AddMapModule()
    AddEquipmentCreditsModule()
    AddPlayerMovementModule()
    AddPropPossessionModule()
    AddAdminModule()
    AddMiscModule()

    -- Request missing cvar data, if we have any
    if table.Count(missing_cvars) > 0 then
        net.Receive("ULX_CRCVarRequest", function()
            local results = net.ReadTable()

            for cv, data in pairs(results) do
                -- Make sure each of these actually has the control reference
                local control = missing_cvars[cv]
                if control and type(control) ~= "boolean" then
                    -- Update whichever portions were sent back from the server
                    if data.d then
                        control:SetText(cv .. " (def. " .. data.d .. ")")
                    end

                    if data.m and control.SetMin then
                        control:SetMin(data.m)
                    end

                    if data.x and control.SetMax then
                        control:SetMax(data.x)
                    end

                    -- Make sure everything is the correct size now that we changed things
                    if control.Label then
                        control.Label:SizeToContents()
                    end
                    control:SizeToContents()
                end
            end
        end)

        -- Convert from a lookup table to an indexed table
        local net_table = {}
        for k, _ in pairs(missing_cvars) do
            table.insert(net_table, k)
        end

        net.Start("ULX_CRCVarRequest")
        net.WriteTable(net_table)
        net.SendToServer()
    end
end)