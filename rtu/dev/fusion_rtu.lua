local rtu = require("rtu.rtu")

local fusion_rtu = {}

-- create new fusion reactor device
---@nodiscard
---@param fusion_reactor FusionReactor|ppm_generic
---@return rtu_device interface, boolean faulted
function fusion_rtu.new(fusion_reactor)
    local unit = rtu.init_unit(fusion_reactor)

    -- discrete inputs --
    unit.connect_di("isFormed")

    -- coils --
    -- none

    -- input registers --
    -- multiblock properties
    unit.connect_input_reg("getLength")
    unit.connect_input_reg("getWidth")
    unit.connect_input_reg("getHeight")
    unit.connect_input_reg("getMinPos")
    unit.connect_input_reg("getMaxPos")
    -- build properties
    unit.connect_input_reg("getWaterCapacity")
    unit.connect_input_reg("getSteamCapacity")
    unit.connect_input_reg("getDeuteriumCapacity")
    unit.connect_input_reg("getTritiumCapacity")
    unit.connect_input_reg("getDTFuelCapacity")
    unit.connect_input_reg(function () return fusion_reactor.getIgnitionTemperature(true) end)
    unit.connect_input_reg(function () return fusion_reactor.getIgnitionTemperature(false) end)
    -- current state
    unit.connect_input_reg("getCaseTemperature")
    unit.connect_input_reg("getPlasmaTemperature")
    unit.connect_input_reg("getProductionRate")
    unit.connect_input_reg("getEnvironmentalLoss")
    unit.connect_input_reg("getTransferLoss")
    unit.connect_input_reg("getInjectionRate")
    unit.connect_input_reg("isIgnited")
    unit.connect_input_reg(function () return fusion_reactor.getPassiveGeneration(false) end)
    -- tanks
    unit.connect_input_reg("getDTFuel")
    unit.connect_input_reg("getDTFuelNeeded")
    unit.connect_input_reg("getDTFuelFilledPercentage")
    unit.connect_input_reg("getDeuterium")
    unit.connect_input_reg("getDeuteriumNeeded")
    unit.connect_input_reg("getDeuteriumFilledPercentage")
    unit.connect_input_reg("getTritium")
    unit.connect_input_reg("getTritiumNeeded")
    unit.connect_input_reg("getTritiumFilledPercentage")
    unit.connect_input_reg("getWater")
    unit.connect_input_reg("getWaterNeeded")
    unit.connect_input_reg("getWaterFilledPercentage")
    unit.connect_input_reg("getSteam")
    unit.connect_input_reg("getSteamNeeded")
    unit.connect_input_reg("getSteamFilledPercentage")

    -- holding registers --
    unit.connect_holding_reg("getInjectionRate", "setInjectionRate")

    return unit.interface(), false
end

return fusion_rtu
