--
-- Fusion Reactor Unit SCADA Coordinator GUI
--

local ioctl           = require("coordinator.ioctl")

local style           = require("coordinator.ui.style")

local core            = require("graphics.core")

local Div             = require("graphics.elements.Div")
local Rectangle       = require("graphics.elements.Rectangle")
local TextBox         = require("graphics.elements.TextBox")

local NumericSpinbox  = require("graphics.elements.controls.NumericSpinbox")
local PushButton      = require("graphics.elements.controls.PushButton")

local DataIndicator   = require("graphics.elements.indicators.DataIndicator")
local HorizontalBar   = require("graphics.elements.indicators.HorizontalBar")
local PowerIndicator  = require("graphics.elements.indicators.PowerIndicator")
local RadIndicator    = require("graphics.elements.indicators.RadIndicator")
local StateIndicator  = require("graphics.elements.indicators.StateIndicator")

local ALIGN = core.ALIGN

local cpair = core.cpair
local border = core.border

local function states_fr(src, labels)
    local out = {}

    for i, state in ipairs(src) do
        out[i] = { color = state.color, text = labels[i] or state.text }
    end

    return out
end

local fusion_states_fr = states_fr(style.fusion.states, {
    "HORS LIGNE",
    "NON FORME",
    "PANNE RTU",
    "INACTIF",
    "ACTIF"
})

local reactor_states_fr = states_fr(style.reactor.states, {
    "PLC HORS LIGNE",
    "NON FORME",
    "PANNE PLC",
    "DESACTIVE",
    "ACTIF",
    "ARRET D URGENCE",
    "DESACTIVE FORCE"
})

-- create a fusion unit detail view
---@param parent Container parent
---@param id integer
local function init(parent, id)
    local s_hi_box = style.theme.highlight_box
    local s_field = style.theme.field_box
    local text_fg = style.theme.text_fg
    local lu_col = style.lu_colors
    local arrow_fg_bg = cpair(style.theme.label, s_hi_box.bkg)
    local dis_colors = style.dis_colors

    local db   = ioctl.get_db()
    local unit = db.units[id]

    local main = Div{parent=parent,y=1}

    if unit == nil then return main end

    local u_ps = unit.unit_ps
    local f_ps = unit.fusion_ps_tbl[1]

    TextBox{parent=main,text="Reacteur a Fusion Unite #" .. id,alignment=ALIGN.CENTER,fg_bg=style.theme.header}

    if f_ps == nil then
        TextBox{parent=main,x=2,y=4,text="Aucune telemetrie fusion n'est configuree pour cette unite.",fg_bg=text_fg}
        TextBox{parent=main,x=2,y=5,text="Revenez sur FISS ou configurez une liaison RTU fusion.",fg_bg=text_fg}
        return main
    end

    local status = Rectangle{parent=main,border=border(1,colors.gray,true),thin=true,width=78,height=4,x=2,y=3}
    local stat_line_1 = TextBox{parent=status,y=1,text="INCONNU",width=78,alignment=ALIGN.CENTER,fg_bg=style.bw_fg_bg}
    local stat_line_2 = TextBox{parent=status,y=2,text="en attente de donnees...",width=78,alignment=ALIGN.CENTER,fg_bg=style.gray_white}

    stat_line_1.register(u_ps, "U_StatusLine1", stat_line_1.set_value)
    stat_line_2.register(u_ps, "U_StatusLine2", stat_line_2.set_value)

    local fusion = Rectangle{parent=main,border=border(1,colors.gray,true),thin=true,width=38,height=16,x=2,y=8}

    local fus_state = StateIndicator{parent=fusion,x=2,y=1,states=fusion_states_fr,value=1,min_width=16}
    fus_state.register(f_ps, "computed_status", fus_state.update)

    local case_temp = DataIndicator{parent=fusion,x=2,y=3,lu_colors=lu_col,label="Temp. Cuve",unit=db.temp_label,format="%10.2f",value=0,commas=true,width=34,fg_bg=text_fg}
    local plasma_temp = DataIndicator{parent=fusion,x=2,y=4,lu_colors=lu_col,label="Temp. Plasma",unit=db.temp_label,format="%8.2f",value=0,commas=true,width=34,fg_bg=text_fg}
    local prod_rate = DataIndicator{parent=fusion,x=2,y=6,lu_colors=lu_col,label="Production",unit="mB/t",format="%11.0f",value=0,commas=true,width=34,fg_bg=text_fg}
    local passive_gen = PowerIndicator{parent=fusion,x=2,y=7,lu_colors=lu_col,label="Gen. Passive",unit=db.energy_label,format="%10.2f",value=0,rate=true,width=34,fg_bg=text_fg}
    local inj_rate = DataIndicator{parent=fusion,x=2,y=9,lu_colors=lu_col,label="Injection",unit="mB/t",format="%12.0f",value=0,width=34,fg_bg=text_fg}
    local env_loss = DataIndicator{parent=fusion,x=2,y=11,lu_colors=lu_col,label="Perte Env.",unit="",format="%11.8f",value=0,width=34,fg_bg=text_fg}
    local xfer_loss = DataIndicator{parent=fusion,x=2,y=12,lu_colors=lu_col,label="Perte Trans.",unit="",format="%10.6f",value=0,width=34,fg_bg=text_fg}

    case_temp.register(f_ps, "case_temp", function (t) case_temp.update(db.temp_convert(t)) end)
    plasma_temp.register(f_ps, "plasma_temp", function (t) plasma_temp.update(db.temp_convert(t)) end)
    prod_rate.register(f_ps, "prod_rate", prod_rate.update)
    passive_gen.register(f_ps, "passive_generation", function (val) passive_gen.update(db.energy_convert(val)) end)
    inj_rate.register(f_ps, "injection_rate", inj_rate.update)
    env_loss.register(f_ps, "env_loss", env_loss.update)
    xfer_loss.register(f_ps, "transfer_loss", xfer_loss.update)

    local tanks = Rectangle{parent=main,border=border(1,colors.gray,true),thin=true,width=39,height=16,x=41,y=8}

    local function update_amount(indicator)
        return function (x)
            indicator.update(type(x) == "table" and x.amount or 0)
        end
    end

    local function tank_row(y, text, fill_key, amount_key, color)
        TextBox{parent=tanks,x=2,y=y,text=text,width=9,fg_bg=text_fg}

        local fill = HorizontalBar{parent=tanks,x=11,y=y,show_percent=true,bar_fg_bg=cpair(color, colors.gray),height=1,width=14}
        local amount = DataIndicator{parent=tanks,x=26,y=y,lu_colors=lu_col,label="",unit="mB",format="%11.0f",value=0,commas=true,width=12,fg_bg=text_fg}

        fill.register(f_ps, fill_key, fill.update)
        amount.register(f_ps, amount_key, update_amount(amount))
    end

    tank_row(2, "Carb. DT", "dt_fuel_fill", "dt_fuel", colors.orange)
    tank_row(4, "Deuterium", "deuterium_fill", "deuterium", colors.cyan)
    tank_row(6, "Tritium", "tritium_fill", "tritium", colors.purple)
    tank_row(8, "Eau", "water_fill", "water", colors.blue)
    tank_row(10, "Vapeur", "steam_fill", "steam", colors.white)

    local summary = Rectangle{parent=main,border=border(1,colors.gray,true),thin=true,width=78,height=27,x=2,y=25}

    local rad = RadIndicator{parent=summary,x=2,y=2,label="Radiation Unite",format="%9.3f",lu_colors=lu_col,width=17,fg_bg=s_field}

    rad.register(u_ps, "radiation", rad.update)

    TextBox{parent=summary,x=22,y=2,text="Etat Fusion",width=16,fg_bg=text_fg}
    local fusion_state = StateIndicator{parent=summary,x=22,y=3,states=fusion_states_fr,value=1,min_width=16}
    fusion_state.register(f_ps, "computed_status", fusion_state.update)

    TextBox{parent=summary,x=22,y=6,text="Etat Fission",width=16,fg_bg=text_fg}
    local fission_state = StateIndicator{parent=summary,x=22,y=7,states=reactor_states_fr,value=1,min_width=16}
    fission_state.register(u_ps, "computed_status", fission_state.update)

    TextBox{parent=summary,x=2,y=9,text="Groupe Auto",width=11,fg_bg=style.label}
    local auto_mode = TextBox{parent=summary,x=2,y=10,text="Manuel",width=16,fg_bg=s_field}
    auto_mode.register(u_ps, "auto_group", function (value)
        if value == "Manual" then
            auto_mode.set_value("Manuel")
        else
            auto_mode.set_value(value)
        end
    end)

    TextBox{parent=summary,x=2,y=12,text="Commande Injection",width=17,fg_bg=style.label}

    local inj_control = Div{parent=summary,x=2,y=13,width=20,height=4,fg_bg=s_hi_box}
    local inj_cmd = NumericSpinbox{parent=inj_control,x=2,y=1,whole_num_precision=4,fractional_precision=0,min=0,arrow_fg_bg=arrow_fg_bg,arrow_disable=style.theme.disabled}
    TextBox{parent=inj_control,x=9,y=2,text="mB/t",fg_bg=style.theme.label_fg}

    local set_inj = function () unit.set_fusion_injection(inj_cmd.get_value()) end
    local set_inj_btn = PushButton{parent=inj_control,x=14,y=2,text="SET",min_width=5,fg_bg=cpair(colors.black, colors.yellow),active_fg_bg=style.wh_gray,dis_fg_bg=dis_colors,callback=set_inj}

    inj_cmd.register(f_ps, "injection_rate", function (rate)
        if type(rate) == "number" then inj_cmd.set_value(math.floor(rate + 0.5)) end
    end)
    inj_cmd.register(f_ps, "formed", function (formed) if formed then inj_cmd.enable() else inj_cmd.disable() end end)
    set_inj_btn.register(f_ps, "formed", function (formed) if formed then set_inj_btn.enable() else set_inj_btn.disable() end end)

    return main
end

return init
