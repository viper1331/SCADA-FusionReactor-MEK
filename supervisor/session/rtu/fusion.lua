local log          = require("scada-common.log")
local mqueue       = require("scada-common.mqueue")
local types        = require("scada-common.types")
local util         = require("scada-common.util")

local qtypes       = require("supervisor.session.rtu.qtypes")
local unit_session = require("supervisor.session.rtu.unit_session")

local fusion = {}

local RTU_UNIT_TYPE = types.RTU_UNIT_TYPE
local MODBUS_FCODE = types.MODBUS_FCODE
local FUS_RTU_S_DATA = qtypes.FUS_RTU_S_DATA

local TXN_TYPES = {
    FORMED = 1,
    BUILD = 2,
    STATE = 3,
    TANKS = 4,
    SET_INJ = 5
}

local TXN_TAGS = {
    "fusion.formed",
    "fusion.build",
    "fusion.state",
    "fusion.tanks",
    "fusion.set_inj"
}

local PERIODICS = {
    FORMED = 2000,
    BUILD = 1000,
    STATE = 500,
    TANKS = 1000
}

local WRITE_BUSY_WAIT = 1000

-- create a new fusion reactor rtu session runner
---@nodiscard
---@param session_id integer RTU gateway session ID
---@param unit_id integer RTU ID
---@param advert rtu_advertisement RTU advertisement table
---@param out_queue mqueue RTU message out queue
function fusion.new(session_id, unit_id, advert, out_queue)
    -- checks
    if advert.type ~= RTU_UNIT_TYPE.FUSION then
        log.error("attempt to instantiate fusion RTU for type " .. types.rtu_type_to_string(advert.type))
        return nil
    elseif not util.is_int(advert.index) then
        log.error("attempt to instantiate fusion RTU without index")
        return nil
    end

    local log_tag = util.c("session.rtu(", session_id, ").fusion(", advert.index, ")[@", unit_id, "]: ")

    local self = {
        session = unit_session.new(session_id, unit_id, advert, out_queue, log_tag, TXN_TAGS),
        has_build = false,
        injection_cmd = nil, ---@type integer|nil
        resend_injection = false,
        periodics = {
            next_formed_req = 0,
            next_build_req = 0,
            next_state_req = 0,
            next_tanks_req = 0
        },
        ---@class fusion_session_db
        db = {
            formed = false,
            build = {
                last_update = 0,
                length = 0,
                width = 0,
                height = 0,
                min_pos = types.new_zero_coordinate(),
                max_pos = types.new_zero_coordinate(),
                water_cap = 0,
                steam_cap = 0,
                deuterium_cap = 0,
                tritium_cap = 0,
                dt_fuel_cap = 0,
                ignition_temp_water = 0.0,
                ignition_temp_air = 0.0
            },
            state = {
                last_update = 0,
                case_temp = 0.0,
                plasma_temp = 0.0,
                prod_rate = 0,
                env_loss = 0.0,
                transfer_loss = 0.0,
                injection_rate = 0,
                ignited = false,
                passive_generation = 0
            },
            tanks = {
                last_update = 0,
                dt_fuel = types.new_empty_gas(),
                dt_fuel_need = 0,
                dt_fuel_fill = 0.0,
                deuterium = types.new_empty_gas(),
                deuterium_need = 0,
                deuterium_fill = 0.0,
                tritium = types.new_empty_gas(),
                tritium_need = 0,
                tritium_fill = 0.0,
                water = types.new_empty_gas(),
                water_need = 0,
                water_fill = 0.0,
                steam = types.new_empty_gas(),
                steam_need = 0,
                steam_fill = 0.0
            }
        }
    }

    ---@class fusion_session:unit_session
    local public = self.session.get()

    -- PRIVATE FUNCTIONS --

    -- query if the multiblock is formed
    ---@param time_now integer
    local function _request_formed(time_now)
        -- read discrete input 1 (start = 1, count = 1)
        if self.session.send_request(TXN_TYPES.FORMED, MODBUS_FCODE.READ_DISCRETE_INPUTS, { 1, 1 }) ~= false then
            self.periodics.next_formed_req = time_now + PERIODICS.FORMED
        end
    end

    -- query the build of the device
    ---@param time_now integer
    local function _request_build(time_now)
        -- read input registers 1 through 12 (start = 1, count = 12)
        if self.session.send_request(TXN_TYPES.BUILD, MODBUS_FCODE.READ_INPUT_REGS, { 1, 12 }) ~= false then
            self.periodics.next_build_req = time_now + PERIODICS.BUILD
        end
    end

    -- query the state of the device
    ---@param time_now integer
    local function _request_state(time_now)
        -- read input registers 13 through 20 (start = 13, count = 8)
        if self.session.send_request(TXN_TYPES.STATE, MODBUS_FCODE.READ_INPUT_REGS, { 13, 8 }) ~= false then
            self.periodics.next_state_req = time_now + PERIODICS.STATE
        end
    end

    -- query the tanks of the device
    ---@param time_now integer
    local function _request_tanks(time_now)
        -- read input registers 21 through 35 (start = 21, count = 15)
        if self.session.send_request(TXN_TYPES.TANKS, MODBUS_FCODE.READ_INPUT_REGS, { 21, 15 }) ~= false then
            self.periodics.next_tanks_req = time_now + PERIODICS.TANKS
        end
    end

    -- set the fusion reactor injection rate
    ---@param rate integer
    local function _set_injection_rate(rate)
        self.injection_cmd = rate

        -- write holding register 1 (injection rate)
        if self.session.send_request(TXN_TYPES.SET_INJ, MODBUS_FCODE.WRITE_SINGLE_HOLD_REG, { 1, rate }, WRITE_BUSY_WAIT) == false then
            self.resend_injection = true
        end
    end

    -- PUBLIC FUNCTIONS --

    -- handle an ADU
    ---@param adu modbus_adu
    function public.handle_adu(adu)
        local txn_type = self.session.try_resolve(adu)
        if txn_type == false then
            -- nothing to do
        elseif txn_type == TXN_TYPES.FORMED then
            -- formed response
            if adu.length == 1 then
                self.db.formed = adu.data[1]

                if not self.db.formed then self.has_build = false end
            else
                log.debug(log_tag .. "MODBUS transaction reply length mismatch (" .. TXN_TAGS[txn_type] .. ")")
            end
        elseif txn_type == TXN_TYPES.BUILD then
            -- build response
            if adu.length == 12 then
                self.db.build.last_update          = util.time_ms()
                self.db.build.length               = adu.data[1]
                self.db.build.width                = adu.data[2]
                self.db.build.height               = adu.data[3]
                self.db.build.min_pos              = adu.data[4]
                self.db.build.max_pos              = adu.data[5]
                self.db.build.water_cap            = adu.data[6]
                self.db.build.steam_cap            = adu.data[7]
                self.db.build.deuterium_cap        = adu.data[8]
                self.db.build.tritium_cap          = adu.data[9]
                self.db.build.dt_fuel_cap          = adu.data[10]
                self.db.build.ignition_temp_water  = adu.data[11]
                self.db.build.ignition_temp_air    = adu.data[12]
                self.has_build = true

                out_queue.push_data(unit_session.RTU_US_DATA.BUILD_CHANGED, { unit = advert.reactor, type = advert.type })
            else
                log.debug(log_tag .. "MODBUS transaction reply length mismatch (" .. TXN_TAGS[txn_type] .. ")")
            end
        elseif txn_type == TXN_TYPES.STATE then
            -- state response
            if adu.length == 8 then
                self.db.state.last_update       = util.time_ms()
                self.db.state.case_temp         = adu.data[1]
                self.db.state.plasma_temp       = adu.data[2]
                self.db.state.prod_rate         = adu.data[3]
                self.db.state.env_loss          = adu.data[4]
                self.db.state.transfer_loss     = adu.data[5]
                self.db.state.injection_rate    = adu.data[6]
                self.db.state.ignited           = adu.data[7]
                self.db.state.passive_generation = adu.data[8]

                if self.injection_cmd == nil then
                    self.injection_cmd = self.db.state.injection_rate
                end
            else
                log.debug(log_tag .. "MODBUS transaction reply length mismatch (" .. TXN_TAGS[txn_type] .. ")")
            end
        elseif txn_type == TXN_TYPES.TANKS then
            -- tanks response
            if adu.length == 15 then
                self.db.tanks.last_update      = util.time_ms()
                self.db.tanks.dt_fuel          = adu.data[1]
                self.db.tanks.dt_fuel_need     = adu.data[2]
                self.db.tanks.dt_fuel_fill     = adu.data[3]
                self.db.tanks.deuterium        = adu.data[4]
                self.db.tanks.deuterium_need   = adu.data[5]
                self.db.tanks.deuterium_fill   = adu.data[6]
                self.db.tanks.tritium          = adu.data[7]
                self.db.tanks.tritium_need     = adu.data[8]
                self.db.tanks.tritium_fill     = adu.data[9]
                self.db.tanks.water            = adu.data[10]
                self.db.tanks.water_need       = adu.data[11]
                self.db.tanks.water_fill       = adu.data[12]
                self.db.tanks.steam            = adu.data[13]
                self.db.tanks.steam_need       = adu.data[14]
                self.db.tanks.steam_fill       = adu.data[15]
            else
                log.debug(log_tag .. "MODBUS transaction reply length mismatch (" .. TXN_TAGS[txn_type] .. ")")
            end
        elseif txn_type == TXN_TYPES.SET_INJ then
            -- successful acknowledgement
        elseif txn_type == nil then
            log.error(log_tag .. "unknown transaction reply")
        else
            log.error(log_tag .. "unknown transaction type " .. txn_type)
        end
    end

    -- update this runner
    ---@param time_now integer milliseconds
    function public.update(time_now)
        -- check command queue
        while self.session.in_q.ready() do
            -- get a new message to process
            local msg = self.session.in_q.pop()

            if msg ~= nil then
                if msg.qtype == mqueue.TYPE.DATA then
                    -- instruction with body
                    local cmd = msg.message ---@type queue_data

                    if cmd.key == FUS_RTU_S_DATA.SET_INJ_RATE then
                        if type(cmd.val) == "number" then
                            local rate = math.floor(cmd.val + 0.5)
                            if rate < 0 then rate = 0 end
                            _set_injection_rate(rate)
                        else
                            log.debug(util.c(log_tag, "invalid fusion injection rate value type ", type(cmd.val)))
                        end
                    else
                        log.debug(util.c(log_tag, "unrecognized in-queue data ", cmd.key))
                    end
                elseif msg.qtype == mqueue.TYPE.COMMAND then
                    log.debug(util.c(log_tag, "unrecognized in-queue command ", msg.message))
                end
            end

            -- max 100ms spent processing queue
            if util.time() - time_now > 100 then
                log.warning(log_tag .. "exceeded 100ms queue process limit")
                break
            end
        end

        -- try to resend injection setpoint if needed
        if self.resend_injection and self.injection_cmd ~= nil then
            self.resend_injection = false
            _set_injection_rate(self.injection_cmd)
        end

        time_now = util.time()

        if self.periodics.next_formed_req <= time_now then _request_formed(time_now) end

        if self.db.formed then
            if not self.has_build and self.periodics.next_build_req <= time_now then _request_build(time_now) end
            if self.periodics.next_state_req <= time_now then _request_state(time_now) end
            if self.periodics.next_tanks_req <= time_now then _request_tanks(time_now) end
        end

        self.session.post_update()
    end

    -- invalidate build cache
    function public.invalidate_cache()
        self.periodics.next_formed_req = 0
        self.periodics.next_build_req = 0
        self.has_build = false
    end

    -- get the unit session database
    ---@nodiscard
    function public.get_db() return self.db end

    return public
end

return fusion
