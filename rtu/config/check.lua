local comms      = require("scada-common.comms")
local network    = require("scada-common.network")
local ppm        = require("scada-common.ppm")
local rsio       = require("scada-common.rsio")
local tcd        = require("scada-common.tcd")
local util       = require("scada-common.util")

local rtu        = require("rtu.rtu")

local redstone   = require("rtu.config.redstone")

local core       = require("graphics.core")

local Div        = require("graphics.elements.Div")
local ListBox    = require("graphics.elements.ListBox")
local TextBox    = require("graphics.elements.TextBox")

local PushButton = require("graphics.elements.controls.PushButton")

local tri = util.trinary

local cpair = core.cpair

local PROTOCOL = comms.PROTOCOL
local DEVICE_TYPE = comms.DEVICE_TYPE
local ESTABLISH_ACK = comms.ESTABLISH_ACK
local MGMT_TYPE = comms.MGMT_TYPE

local self = {
    checking_wl = true,
    wd_modem = nil,      ---@type Modem|nil
    wl_modem = nil,      ---@type Modem|nil

    nic = nil,           ---@type nic
    net_listen = false,

    self_check_pass = true,

    self_check_wireless = true,

    settings = nil,      ---@type rtu_config

    run_test_btn = nil,  ---@type PushButton
    sc_log = nil,        ---@type ListBox
    self_check_msg = nil ---@type function
}

-- report successful completion of the check
local function check_complete()
    TextBox{parent=self.sc_log,text="> tous les tests sont passes !",fg_bg=cpair(colors.blue,colors._INHERIT)}
    TextBox{parent=self.sc_log,text=""}
    local more = Div{parent=self.sc_log,height=3,fg_bg=cpair(colors.gray,colors._INHERIT)}
    TextBox{parent=more,text="si vous avez encore un probleme :"}
    TextBox{parent=more,text="- consultez le wiki sur GitHub"}
    TextBox{parent=more,text="- demandez de l aide sur GitHub Discussions ou Discord"}
end

-- send a management packet to the supervisor
---@param msg_type MGMT_TYPE
---@param msg table
local function send_sv(msg_type, msg)
    local frame, mgmt = comms.scada_frame(), comms.mgmt_container()

    mgmt.make(msg_type, msg)
    frame.make(comms.BROADCAST, util.time_ms() * 10, PROTOCOL.SCADA_MGMT, mgmt.raw_packet())

    self.nic.transmit(self.settings.SVR_Channel, self.settings.RTU_Channel, frame)
end

-- handle an establish message from the supervisor
---@param packet mgmt_packet
local function handle_packet(packet)
    local error_msg = nil

    if packet.scada_frame.local_channel() ~= self.settings.RTU_Channel then
        error_msg = "erreur : canal de reception inconnu"
    elseif packet.scada_frame.remote_channel() == self.settings.SVR_Channel and packet.scada_frame.protocol() == PROTOCOL.SCADA_MGMT then
        if packet.type == MGMT_TYPE.ESTABLISH then
            if packet.length == 1 then
                local est_ack = packet.data[1]

                if est_ack== ESTABLISH_ACK.ALLOW then
                    -- OK
                elseif est_ack == ESTABLISH_ACK.DENY then
                    error_msg = "erreur : connexion superviseur refusee"
                elseif est_ack == ESTABLISH_ACK.BAD_VERSION then
                    error_msg = "version de com passerelle RTU differente de la version superviseur ; assurez-vous que les deux appareils sont a jour (ccmsi update)"
                else
                    error_msg = "erreur : reponse invalide du superviseur"
                end
            else
                error_msg = "erreur : longueur de reponse invalide du superviseur"
            end
        else
            error_msg = "erreur : aucune reponse d etablissement du superviseur"
        end
    end

    self.net_listen = false

    if error_msg then
        self.self_check_msg(nil, false, error_msg)
    else
        self.self_check_msg(nil, true, "")
    end

    util.push_event("conn_test_complete", error_msg == nil)
end

-- handle supervisor connection failure
local function handle_timeout()
    self.net_listen = false
    util.push_event("conn_test_complete", false)
end


-- check if a value is an integer within a range (inclusive)
---@param x any
---@param min integer
---@param max integer
local function is_int_min_max(x, min, max) return util.is_int(x) and x >= min and x <= max end

-- execute the self-check
local function self_check()
    self.run_test_btn.disable()

    self.sc_log.remove_all()
    ppm.mount_all()

    self.self_check_pass = true

    local cfg = self.settings
    self.wd_modem = ppm.get_modem(cfg.WiredModem)
    self.wl_modem = ppm.get_wireless_modem()
    local valid_cfg = rtu.validate_config(cfg)

    if cfg.WiredModem then
        self.self_check_msg("> verifier modem de com filaire connecte...", self.wd_modem, "veuillez connecter le modem filaire de communication " .. cfg.WiredModem)
    end

    if cfg.WirelessModem then
        self.self_check_msg("> verifier modem sans fil/ender connecte...", self.wl_modem, "veuillez connecter un modem ender ou sans fil pour les communications sans fil")
    end

    self.self_check_msg("> verifier configuration passerelle...", valid_cfg, "ouvrez Configurer passerelle puis appliquez les parametres pour completer les reglages manquants ou reparer les reglages invalides")

    -- check redstone configurations

    local phys = {} ---@type rtu_rs_definition[][]
    local inputs = { [0] = {}, {}, {}, {}, {} }

    for i = 1, #cfg.Redstone do
        local entry = cfg.Redstone[i]
        local name = entry.relay or "local"

        if phys[name] == nil then phys[name] = {} end
        table.insert(phys[entry.relay or "local"], entry)
    end

    for name, entries in pairs(phys) do
        TextBox{parent=self.sc_log,text="> verification redstone @ "..name.."...",fg_bg=cpair(colors.blue,colors.white)}

        local ifaces = {}
        local bundled_sides = {}

        for i = 1, #entries do
            local entry = entries[i]
            local ident = entry.side .. tri(entry.color, ":" .. rsio.color_name(entry.color), "")

            local sc_dupe  = util.table_contains(ifaces, ident)
            local mixed = (bundled_sides[entry.side] and (entry.color == nil)) or (bundled_sides[entry.side] == false and (entry.color ~= nil))

            local mixed_msg = util.trinary(bundled_sides[entry.side], "des entrees groupees existent mais celle-ci ne l est pas", "des entrees non groupees existent mais celle-ci l est")

            self.self_check_msg("> verifier redstone " .. ident .. " unique...", not sc_dupe, "un seul port doit etre defini pour chaque combinaison cote/couleur")
            self.self_check_msg("> verifier redstone " .. ident .. " groupe...", not mixed, "ce cote a un melange invalide : " .. mixed_msg)
            self.self_check_msg("> verifier redstone " .. ident .. " valide...", redstone.validate(entry), "configuration invalide, veuillez reconfigurer cette entree redstone")

            if rsio.get_io_dir(entry.port) == rsio.IO_DIR.IN then
                local in_dupe = util.table_contains(inputs[entry.unit or 0], entry.port)
                self.self_check_msg("> verifier entree redstone " .. ident .. "...", not in_dupe, "vous ne pouvez pas avoir plusieurs fois la meme entree pour une unite donnee ou pour l installation ("..rsio.to_string(entry.port)..")")
            end

            bundled_sides[entry.side] = bundled_sides[entry.side] or entry.color ~= nil
            table.insert(ifaces, ident)
        end
    end

    -- check peripheral configurations
    for i = 1, #cfg.Peripherals do
        local entry = cfg.Peripherals[i]
        local valid = false

        if type(entry.name) == "string" then
            self.self_check_msg("> verifier " .. entry.name .. " connecte...", ppm.get_periph(entry.name), "veuillez connecter cet appareil via modem filaire ou contact direct, et verifier que la configuration correspond a son nom detecte")

            local p_type = ppm.get_type(entry.name)

            if p_type == "boilerValve" then
                valid = is_int_min_max(entry.index, 1, 2) and is_int_min_max(entry.unit, 1, 4)
            elseif p_type == "turbineValve" then
                valid = is_int_min_max(entry.index, 1, 3) and is_int_min_max(entry.unit, 1, 4)
            elseif p_type == "fusionReactorController" or p_type == "fusionReactorPort" then
                valid = is_int_min_max(entry.index, 1, 1) and is_int_min_max(entry.unit, 1, 4)
            elseif p_type == "solarNeutronActivator" then
                valid = is_int_min_max(entry.unit, 1, 4)
            elseif p_type == "dynamicValve" then
                valid = (entry.unit == nil and is_int_min_max(entry.index, 1, 4)) or is_int_min_max(entry.unit, 1, 4)
            elseif p_type == "environmentDetector" or p_type == "environment_detector"  then
                valid = (entry.unit == nil or is_int_min_max(entry.unit, 1, 4)) and util.is_int(entry.index)
            else
                valid = true

                if p_type ~= nil and not (p_type == "inductionPort" or p_type == "reinforcedInductionPort" or p_type == "spsPort" or p_type == "fusionReactorController" or p_type == "fusionReactorPort") then
                    self.self_check_msg("> verifier " .. entry.name .. " valide...", false, "type d appareil non reconnu")
                end
            end
        end

        if not valid then
            self.self_check_msg("> verifier " .. entry.name .. " valide...", false, "configuration invalide, veuillez reconfigurer cette entree peripherique")
        end
    end

    if valid_cfg then
        self.checking_wl = true

        if cfg.WirelessModem and self.wl_modem then
            self.self_check_msg("> verifier connexion superviseur sans fil...")

            -- init mac as needed
            if cfg.AuthKey and string.len(cfg.AuthKey) >= 8 then
                network.init_mac(cfg.AuthKey)
            else
                network.deinit_mac()
            end

            comms.set_trusted_range(cfg.TrustedRange)

            self.nic = network.nic(self.wl_modem)

            self.nic.closeAll()
            self.nic.open(cfg.RTU_Channel)

            self.net_listen = true

            send_sv(MGMT_TYPE.ESTABLISH, { comms.version, comms.CONN_TEST_FWV, DEVICE_TYPE.RTU, {} })

            tcd.dispatch_unique(8, handle_timeout)
        elseif cfg.WiredModem and self.wd_modem then
            -- skip to wired
            util.push_event("conn_test_complete", true)
        else
            self.self_check_msg("> aucun modem, test de connexion superviseur impossible", false)
        end
    else
        if self.self_check_pass then check_complete() end
        self.run_test_btn.enable()
    end
end

-- exit self check back home
---@param main_pane MultiPane
local function exit_self_check(main_pane)
    tcd.abort(handle_timeout)
    self.net_listen = false
    self.run_test_btn.enable()
    self.sc_log.remove_all()
    main_pane.set_value(1)
end

local check = {}

-- create the self-check view
---@param main_pane MultiPane
---@param settings_cfg rtu_config
---@param check_sys Div
---@param style { [string]: cpair }
function check.create(main_pane, settings_cfg, check_sys, style)
    local bw_fg_bg      = style.bw_fg_bg
    local g_lg_fg_bg    = style.g_lg_fg_bg
    local nav_fg_bg     = style.nav_fg_bg
    local btn_act_fg_bg = style.btn_act_fg_bg
    local btn_dis_fg_bg = style.btn_dis_fg_bg

    self.settings = settings_cfg

    local sc = Div{parent=check_sys,x=2,y=4,width=49}

    TextBox{parent=check_sys,y=2,text=" Auto-verification passerelle RTU",fg_bg=bw_fg_bg}

    self.sc_log = ListBox{parent=sc,y=1,height=12,width=49,scroll_height=1000,fg_bg=bw_fg_bg,nav_fg_bg=g_lg_fg_bg,nav_active=cpair(colors.black,colors.gray)}

    local last_check = { nil, nil }

    function self.self_check_msg(msg, success, fail_msg)
        if type(msg) == "string" then
            last_check[1] = Div{parent=self.sc_log,height=1}
            local e = TextBox{parent=last_check[1],text=msg,fg_bg=bw_fg_bg}
            last_check[2] = e.get_x()+string.len(msg)
        end

        if type(fail_msg) == "string" then
            TextBox{parent=last_check[1],x=last_check[2],y=1,text=tri(success,"OK","ECHEC"),fg_bg=tri(success,cpair(colors.green,colors._INHERIT),cpair(colors.red,colors._INHERIT))}

            if not success then
                local fail = Div{parent=self.sc_log,height=#util.strwrap(fail_msg, 46)}
                TextBox{parent=fail,x=3,text=fail_msg,fg_bg=cpair(colors.gray,colors.white)}
            end

            self.self_check_pass = self.self_check_pass and success
        end
    end

    PushButton{parent=sc,y=14,text="\x1b Retour",callback=function()exit_self_check(main_pane)end,fg_bg=nav_fg_bg,active_fg_bg=btn_act_fg_bg}
    self.run_test_btn = PushButton{parent=sc,x=40,y=14,min_width=10,text="Lancer test",callback=function()self_check()end,fg_bg=cpair(colors.black,colors.blue),active_fg_bg=btn_act_fg_bg,dis_fg_bg=btn_dis_fg_bg}
end

-- handle incoming modem messages
---@param side string
---@param sender integer
---@param reply_to integer
---@param message any
---@param distance integer
function check.receive_sv(side, sender, reply_to, message, distance)
    if self.nic ~= nil and self.net_listen then
        local frame = self.nic.receive(side, sender, reply_to, message, distance)

        if frame and frame.protocol() == PROTOCOL.SCADA_MGMT then
            local pkt = comms.mgmt_container().decode(frame)
            if pkt then
                tcd.abort(handle_timeout)
                handle_packet(pkt)
            end
        end
    end
end

-- handle completed connection tests
---@param pass boolean
function check.conn_test_callback(pass)
    local cfg = self.settings

    if self.checking_wl then
        if not pass then
            self.self_check_msg(nil, false, "assurez-vous que le superviseur est en marche, ecoute sur l interface sans fil, que les canaux sont corrects, que la portee de confiance est bien reglee (si activee), que la cle installation correspond (si definie), et que les appareils sont proches dans la meme dimension si vous utilisez des modems sans fil non ender")
        end

        if cfg.WiredModem and self.wd_modem then
            self.checking_wl = false
            self.self_check_msg("> verifier connexion superviseur filaire...")

            comms.set_trusted_range(0)

            self.nic = network.nic(self.wd_modem)

            self.nic.closeAll()
            self.nic.open(cfg.RTU_Channel)

            self.net_listen = true

            send_sv(MGMT_TYPE.ESTABLISH, { comms.version, comms.CONN_TEST_FWV, DEVICE_TYPE.RTU, {} })

            tcd.dispatch_unique(8, handle_timeout)
        else
            if self.self_check_pass then check_complete() end
            self.run_test_btn.enable()
        end
    else
        if not pass then
            self.self_check_msg(nil, false, "assurez-vous que le superviseur est en marche, ecoute sur l interface filaire, que le cable est intact et que les canaux sont corrects")
        end

        if self.self_check_pass then check_complete() end
        self.run_test_btn.enable()
    end
end

return check
