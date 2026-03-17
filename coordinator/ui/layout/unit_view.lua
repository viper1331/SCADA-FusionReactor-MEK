--
-- Reactor Unit SCADA Coordinator GUI
--

local ioctl              = require("coordinator.ioctl")

local unit_detail        = require("coordinator.ui.components.unit_detail")
local unit_detail_fusion = require("coordinator.ui.components.unit_detail_fusion")

local core               = require("graphics.core")

local Div                = require("graphics.elements.Div")
local MultiPane          = require("graphics.elements.MultiPane")

local PushButton         = require("graphics.elements.controls.PushButton")

local cpair = core.cpair

-- create a unit view
---@param main DisplayBox main displaybox
---@param id integer
local function init(main, id)
    local fission_pane = Div{parent=main}
    local fusion_pane = Div{parent=main}

    unit_detail(fission_pane, id)
    unit_detail_fusion(fusion_pane, id)

    local view_pane = MultiPane{parent=main,panes={fission_pane,fusion_pane}}

    local btn_fg_bg = cpair(colors.black, colors.lightGray)
    local btn_active = cpair(colors.white, colors.gray)
    local btn_dis = cpair(colors.white, colors.gray)

    local fission_btn = PushButton{parent=main,x=68,y=1,text="FISS",fg_bg=btn_fg_bg,active_fg_bg=btn_active,dis_fg_bg=btn_dis,callback=function() view_pane.set_value(1) end}
    local fusion_btn = PushButton{parent=main,x=73,y=1,text="FUS",fg_bg=btn_fg_bg,active_fg_bg=btn_active,dis_fg_bg=btn_dis,callback=function() view_pane.set_value(2) end}

    local unit = ioctl.get_db().units[id]

    if unit ~= nil then
        unit.unit_ps.subscribe("has_fusion", function (has_fusion)
            if has_fusion then
                fusion_btn.enable()
            else
                fusion_btn.disable()
                view_pane.set_value(1)
            end
        end)
    else
        fusion_btn.disable()
        fission_btn.disable()
    end
end

return init
