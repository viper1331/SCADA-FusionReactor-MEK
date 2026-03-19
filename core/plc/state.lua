-- core/plc/state.lua
-- Construction d'un etat PLC clair, autonome et exportable.

local M = {}

local function copyList(values)
  local out = {}
  if type(values) ~= "table" then
    return out
  end

  for i = 1, #values do
    out[i] = values[i]
  end
  return out
end

function M.build(state, hw, runtimeAlerts)
  local laserState = runtimeAlerts.getLaserState()
  local safetyWarnings, safetyCritical = runtimeAlerts.computeSafetyWarnings()
  local ignitionBlockers = runtimeAlerts.getIgnitionBlockers()
  local readiness = runtimeAlerts.canIgnite()

  local relayCount = 0
  for _ in pairs(hw.relays or {}) do
    relayCount = relayCount + 1
  end

  return {
    role = tostring(state.runtimeRole or "plc"),
    cycle = tonumber(state.tick or 0) or 0,
    timestamp = os.epoch and os.epoch("utc") or nil,
    readiness = {
      localReady = readiness,
      ignitionBlocked = #ignitionBlockers > 0,
      ignitionSequencePending = state.ignitionSequencePending == true,
      ignitionBlockers = copyList(ignitionBlockers),
      checklist = copyList(state.ignitionChecklist),
    },
    reactor = {
      present = state.reactorPresent == true,
      formed = state.reactorFormed == true,
      ignition = state.ignition == true,
      phase = runtimeAlerts.reactorPhase(),
      plasmaTemp = tonumber(state.plasmaTemp or 0) or 0,
      caseTemp = tonumber(state.caseTemp or 0) or 0,
      injectionRate = tonumber(state.injectionRate or 0) or 0,
      hohlraumPresent = state.hohlraumPresent == true,
      hohlraumCount = tonumber(state.hohlraumCount or 0) or 0,
      fuelMode = runtimeAlerts.getRuntimeFuelMode(),
    },
    laser = {
      present = laserState.present == true,
      ready = laserState.ready == true,
      charging = laserState.charging == true,
      status = laserState.status,
      label = laserState.label,
      energyRaw = tonumber(state.laserEnergy or 0) or 0,
      pct = tonumber(state.laserPct or 0) or 0,
      detectedCount = tonumber(state.laserDetectedCount or 0) or 0,
      thresholdRaw = tonumber(laserState.thresholdRaw or 0) or 0,
    },
    safety = {
      status = safetyCritical and "CRITICAL" or (#safetyWarnings > 0 and "WARN" or "OK"),
      critical = safetyCritical == true,
      warnings = copyList(safetyWarnings),
    },
    devices = {
      reactor = { present = hw.reactor ~= nil, name = hw.reactorName },
      logic = { present = hw.logic ~= nil, name = hw.logicName },
      laser = { present = hw.laser ~= nil, name = hw.laserName, detectedCount = tonumber(state.laserDetectedCount or 0) or 0 },
      induction = { present = hw.induction ~= nil, name = hw.inductionName },
      readers = {
        deuterium = hw.readerRoles and hw.readerRoles.deuterium and hw.readerRoles.deuterium.name or nil,
        tritium = hw.readerRoles and hw.readerRoles.tritium and hw.readerRoles.tritium.name or nil,
        inventory = hw.readerRoles and hw.readerRoles.inventory and hw.readerRoles.inventory.name or nil,
      },
      relays = {
        detectedCount = relayCount,
      },
    },
    faults = copyList(ignitionBlockers),
    warnings = copyList(safetyWarnings),
    summary = {
      status = tostring(state.status or "UNKNOWN"),
      alert = tostring(state.alert or "INFO"),
      lastAction = tostring(state.lastAction or "None"),
    },
  }
end

return M
