--
-- Unit Fusion Reactor View
--

local types          = require("scada-common.types")
local util           = require("scada-common.util")

local ioctl          = require("pocket.ioctl")

local style          = require("pocket.ui.style")

local core           = require("graphics.core")

local Div            = require("graphics.elements.Div")
local TextBox        = require("graphics.elements.TextBox")

local PushButton     = require("graphics.elements.controls.PushButton")

local DataIndicator  = require("graphics.elements.indicators.DataIndicator")
local IconIndicator  = require("graphics.elements.indicators.IconIndicator")
local PowerIndicator = require("graphics.elements.indicators.PowerIndicator")
local StateIndicator = require("graphics.elements.indicators.StateIndicator")
local VerticalBar    = require("graphics.elements.indicators.VerticalBar")

local ALIGN = core.ALIGN
local cpair = core.cpair

local label     = style.label
local lu_col    = style.label_unit_pair
local text_fg   = style.text_fg
local grn_ind_s = style.icon_states.grn_ind_s

-- create a fusion reactor view in the unit app
---@param app pocket_app
---@param u_page nav_tree_page
---@param panes Div[]
---@param fus_pane Div
---@param f_id integer fusion reactor ID
---@param ps psil
---@param update function
return function (app, u_page, panes, fus_pane, f_id, ps, update)
    local db = ioctl.get_db()

    local fus_div = Div{parent=fus_pane,x=2,width=fus_pane.get_width()-2}
    table.insert(panes, fus_div)

    local fus_page = app.new_page(u_page, #panes)
    fus_page.tasks = { update }

    TextBox{parent=fus_div,y=1,text="FUS #"..f_id,width=8}
    local status = StateIndicator{parent=fus_div,x=10,y=1,states=style.fusion.states,value=1,min_width=12}
    status.register(ps, "FusionStateStatus", status.update)

    local dtf  = VerticalBar{parent=fus_div,y=4,fg_bg=cpair(colors.orange,colors.gray),height=5,width=1}
    local deu  = VerticalBar{parent=fus_div,x=3,y=4,fg_bg=cpair(colors.cyan,colors.gray),height=5,width=1}
    local tri  = VerticalBar{parent=fus_div,x=5,y=4,fg_bg=cpair(colors.purple,colors.gray),height=5,width=1}
    local wat  = VerticalBar{parent=fus_div,x=19,y=4,fg_bg=cpair(colors.blue,colors.gray),height=5,width=1}
    local stm  = VerticalBar{parent=fus_div,x=21,y=4,fg_bg=cpair(colors.white,colors.gray),height=5,width=1}

    TextBox{parent=fus_div,text="F",y=3,width=1,fg_bg=label}
    TextBox{parent=fus_div,text="D",x=3,y=3,width=1,fg_bg=label}
    TextBox{parent=fus_div,text="T",x=5,y=3,width=1,fg_bg=label}
    TextBox{parent=fus_div,text="W",x=19,y=3,width=1,fg_bg=label}
    TextBox{parent=fus_div,text="S",x=21,y=3,width=1,fg_bg=label}

    dtf.register(ps, "dt_fuel_fill", dtf.update)
    deu.register(ps, "deuterium_fill", deu.update)
    tri.register(ps, "tritium_fill", tri.update)
    wat.register(ps, "water_fill", wat.update)
    stm.register(ps, "steam_fill", stm.update)

    TextBox{parent=fus_div,text="Case Temp",x=7,y=4,width=11,fg_bg=label}
    local t_prec = util.trinary(db.temp_label == types.TEMP_SCALE_UNITS[types.TEMP_SCALE.KELVIN], 11, 10)
    local case_t = DataIndicator{parent=fus_div,x=7,y=5,lu_colors=lu_col,label="",unit=db.temp_label,format="%"..t_prec..".2f",value=0,commas=true,width=11,fg_bg=text_fg}
    TextBox{parent=fus_div,text="Plasma Temp",x=7,y=6,width=11,fg_bg=label}
    local plasma_t = DataIndicator{parent=fus_div,x=7,y=7,lu_colors=lu_col,label="",unit=db.temp_label,format="%"..t_prec..".2f",value=0,commas=true,width=11,fg_bg=text_fg}

    case_t.register(ps, "case_temp", function (t) case_t.update(db.temp_convert(t)) end)
    plasma_t.register(ps, "plasma_temp", function (t) plasma_t.update(db.temp_convert(t)) end)

    local ignited = IconIndicator{parent=fus_div,y=10,label="Ignited",states=grn_ind_s}
    ignited.register(ps, "ignited", ignited.update)

    TextBox{parent=fus_div,text="Production",y=13,width=10,fg_bg=label}
    local prod_rate = DataIndicator{parent=fus_div,x=10,y=13,lu_colors=lu_col,label="",unit="mB/t",format="%12.0f",value=0,commas=true,width=12,fg_bg=text_fg}
    TextBox{parent=fus_div,text="Passive Gen",y=14,width=10,fg_bg=label}
    local passive_gen = PowerIndicator{parent=fus_div,x=10,y=14,lu_colors=lu_col,label="",unit=db.energy_label,format="%10.2f",value=0,rate=true,width=12,fg_bg=text_fg}
    TextBox{parent=fus_div,text="Injection",y=15,width=10,fg_bg=label}
    local inject_r = DataIndicator{parent=fus_div,x=10,y=15,lu_colors=lu_col,label="",unit="mB/t",format="%12.0f",value=0,width=12,fg_bg=text_fg}

    prod_rate.register(ps, "prod_rate", prod_rate.update)
    passive_gen.register(ps, "passive_generation", function (val) passive_gen.update(db.energy_convert(val)) end)
    inject_r.register(ps, "injection_rate", inject_r.update)

    local fus_ext_div = Div{parent=fus_pane,x=2,width=fus_pane.get_width()-2}
    table.insert(panes, fus_ext_div)

    local fus_ext_page = app.new_page(fus_page, #panes)
    fus_ext_page.tasks = { update }

    PushButton{parent=fus_div,x=9,y=18,text="MORE",min_width=6,fg_bg=cpair(colors.lightGray,colors.gray),active_fg_bg=cpair(colors.gray,colors.lightGray),callback=fus_ext_page.nav_to}
    PushButton{parent=fus_ext_div,x=9,y=18,text="BACK",min_width=6,fg_bg=cpair(colors.lightGray,colors.gray),active_fg_bg=cpair(colors.gray,colors.lightGray),callback=fus_page.nav_to}

    TextBox{parent=fus_ext_div,y=1,text="More Fusion Info",alignment=ALIGN.CENTER}

    local function update_amount(indicator)
        return function (x)
            indicator.update(type(x) == "table" and x.amount or 0)
        end
    end

    TextBox{parent=fus_ext_div,text="DT Fuel",y=3,width=8,fg_bg=label}
    local dtf_p = DataIndicator{parent=fus_ext_div,x=14,y=3,lu_colors=lu_col,label="",unit="%",format="%6.2f",value=0,width=8,fg_bg=text_fg}
    local dtf_a = DataIndicator{parent=fus_ext_div,y=4,lu_colors=lu_col,label="",unit="mB",format="%18.0f",value=0,commas=true,width=21,fg_bg=text_fg}
    dtf_p.register(ps, "dt_fuel_fill", function (x) dtf_p.update(x * 100) end)
    dtf_a.register(ps, "dt_fuel", update_amount(dtf_a))

    TextBox{parent=fus_ext_div,text="Deuterium",y=6,width=9,fg_bg=label}
    local deu_p = DataIndicator{parent=fus_ext_div,x=14,y=6,lu_colors=lu_col,label="",unit="%",format="%6.2f",value=0,width=8,fg_bg=text_fg}
    local deu_a = DataIndicator{parent=fus_ext_div,y=7,lu_colors=lu_col,label="",unit="mB",format="%18.0f",value=0,commas=true,width=21,fg_bg=text_fg}
    deu_p.register(ps, "deuterium_fill", function (x) deu_p.update(x * 100) end)
    deu_a.register(ps, "deuterium", update_amount(deu_a))

    TextBox{parent=fus_ext_div,text="Tritium",y=9,width=7,fg_bg=label}
    local tri_p = DataIndicator{parent=fus_ext_div,x=14,y=9,lu_colors=lu_col,label="",unit="%",format="%6.2f",value=0,width=8,fg_bg=text_fg}
    local tri_a = DataIndicator{parent=fus_ext_div,y=10,lu_colors=lu_col,label="",unit="mB",format="%18.0f",value=0,commas=true,width=21,fg_bg=text_fg}
    tri_p.register(ps, "tritium_fill", function (x) tri_p.update(x * 100) end)
    tri_a.register(ps, "tritium", update_amount(tri_a))

    TextBox{parent=fus_ext_div,text="Water",y=12,width=5,fg_bg=label}
    local wat_p = DataIndicator{parent=fus_ext_div,x=14,y=12,lu_colors=lu_col,label="",unit="%",format="%6.2f",value=0,width=8,fg_bg=text_fg}
    local wat_a = DataIndicator{parent=fus_ext_div,y=13,lu_colors=lu_col,label="",unit="mB",format="%18.0f",value=0,commas=true,width=21,fg_bg=text_fg}
    wat_p.register(ps, "water_fill", function (x) wat_p.update(x * 100) end)
    wat_a.register(ps, "water", update_amount(wat_a))

    TextBox{parent=fus_ext_div,text="Steam",y=15,width=5,fg_bg=label}
    local stm_p = DataIndicator{parent=fus_ext_div,x=14,y=15,lu_colors=lu_col,label="",unit="%",format="%6.2f",value=0,width=8,fg_bg=text_fg}
    local stm_a = DataIndicator{parent=fus_ext_div,y=16,lu_colors=lu_col,label="",unit="mB",format="%18.0f",value=0,commas=true,width=21,fg_bg=text_fg}
    stm_p.register(ps, "steam_fill", function (x) stm_p.update(x * 100) end)
    stm_a.register(ps, "steam", update_amount(stm_a))

    return fus_page.nav_to
end
