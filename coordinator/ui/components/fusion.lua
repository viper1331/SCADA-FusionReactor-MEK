local ioctl          = require("coordinator.ioctl")

local style          = require("coordinator.ui.style")

local core           = require("graphics.core")

local Rectangle      = require("graphics.elements.Rectangle")

local DataIndicator  = require("graphics.elements.indicators.DataIndicator")
local PowerIndicator = require("graphics.elements.indicators.PowerIndicator")
local StateIndicator = require("graphics.elements.indicators.StateIndicator")

local border = core.border

-- create new fusion reactor view
---@param root Container parent
---@param x integer top left x
---@param y integer top left y
---@param ps psil ps interface
local function new_view(root, x, y, ps)
    local text_fg = style.theme.text_fg
    local lu_col = style.lu_colors

    local db = ioctl.get_db()

    local fusion = Rectangle{parent=root,border=border(1,colors.gray,true),width=54,height=7,x=x,y=y}

    local status = StateIndicator{parent=fusion,x=2,y=1,states=style.fusion.states,value=1,min_width=16}

    local case_temp = DataIndicator{parent=fusion,x=2,y=3,lu_colors=lu_col,label="Case:",unit=db.temp_label,format="%10.2f",value=0,commas=true,width=25,fg_bg=text_fg}
    local plasma_temp = DataIndicator{parent=fusion,x=2,y=4,lu_colors=lu_col,label="Plasma:",unit=db.temp_label,format="%8.2f",value=0,commas=true,width=25,fg_bg=text_fg}

    local prod_rate = DataIndicator{parent=fusion,x=28,y=3,lu_colors=lu_col,label="Prod:",unit="mB/t",format="%11.0f",value=0,commas=true,width=25,fg_bg=text_fg}
    local passive_gen = PowerIndicator{parent=fusion,x=28,y=4,lu_colors=lu_col,label="Power:",unit=db.energy_label,format="%9.2f",value=0,rate=true,width=25,fg_bg=text_fg}
    local inject_rate = DataIndicator{parent=fusion,x=28,y=5,lu_colors=lu_col,label="Inject:",unit="mB/t",format="%9.0f",value=0,width=25,fg_bg=text_fg}

    status.register(ps, "computed_status", status.update)
    case_temp.register(ps, "case_temp", function (t) case_temp.update(db.temp_convert(t)) end)
    plasma_temp.register(ps, "plasma_temp", function (t) plasma_temp.update(db.temp_convert(t)) end)
    prod_rate.register(ps, "prod_rate", prod_rate.update)
    passive_gen.register(ps, "passive_generation", function (val) passive_gen.update(db.energy_convert(val)) end)
    inject_rate.register(ps, "injection_rate", inject_rate.update)
end

return new_view
