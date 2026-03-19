-- core/plc/controller.lua
-- Couche Fusion-PLC autonome: arbitre local final des actions critiques.

local PlcState = require("core.plc.state")

local M = {}

function M.build(api)
  local state = assert(api.state, "state required")
  local hw = assert(api.hw, "hw required")
  local log = api.log or {}
  local logInfo = type(log.info) == "function" and log.info or function() end
  local logWarn = type(log.warn) == "function" and log.warn or function() end
  local logDebug = type(log.debug) == "function" and log.debug or function() end

  local runtimeRefresh = assert(api.runtimeRefresh, "runtimeRefresh required")
  local runtimeActions = assert(api.runtimeActions, "runtimeActions required")
  local runtimeAlerts = assert(api.runtimeAlerts, "runtimeAlerts required")

  local plc = {}
  local lastDeviceSignature = nil
  local lastReadiness = nil

  local function getStateSnapshot()
    return PlcState.build(state, hw, runtimeAlerts)
  end

  local function getDeviceSignature(snapshot)
    return table.concat({
      snapshot.devices.reactor.name or "none",
      snapshot.devices.logic.name or "none",
      snapshot.devices.laser.name or "none",
      tostring(snapshot.devices.laser.detectedCount or 0),
      snapshot.devices.induction.name or "none",
      snapshot.devices.readers.deuterium or "none",
      snapshot.devices.readers.tritium or "none",
      snapshot.devices.readers.inventory or "none",
      tostring(snapshot.devices.relays.detectedCount or 0),
    }, "|")
  end

  local function logTopology(snapshot)
    local signature = getDeviceSignature(snapshot)
    if signature == lastDeviceSignature then
      return
    end
    lastDeviceSignature = signature
    logInfo("Fusion-PLC critical devices refreshed", {
      reactor = snapshot.devices.reactor.name or "dynamic:none",
      logic = snapshot.devices.logic.name or "dynamic:none",
      laser = snapshot.devices.laser.name or "dynamic:none",
      lasers = tostring(snapshot.devices.laser.detectedCount or 0),
      readerD = snapshot.devices.readers.deuterium or "dynamic:none",
      readerT = snapshot.devices.readers.tritium or "dynamic:none",
      readerAux = snapshot.devices.readers.inventory or "dynamic:none",
      relays = tostring(snapshot.devices.relays.detectedCount or 0),
    })
  end

  local function logReadiness(snapshot)
    local ready = snapshot.readiness.localReady == true
    if lastReadiness == ready then
      return
    end
    lastReadiness = ready
    if ready then
      logInfo("Fusion-PLC local readiness validated", {
        phase = snapshot.reactor.phase,
      })
    else
      logWarn("Fusion-PLC local readiness blocked", {
        blockers = table.concat(snapshot.readiness.ignitionBlockers or {}, ", "),
      })
    end
  end

  function plc.refresh_devices()
    runtimeRefresh.refreshAll()
    local snapshot = getStateSnapshot()
    state.plcSnapshot = snapshot
    logTopology(snapshot)
    logReadiness(snapshot)
    return snapshot
  end

  function plc.get_state()
    state.plcSnapshot = getStateSnapshot()
    return state.plcSnapshot
  end

  function plc.get_status_summary()
    local snapshot = plc.get_state()
    return {
      role = snapshot.role,
      status = snapshot.summary.status,
      reactorPhase = snapshot.reactor.phase,
      safety = snapshot.safety.status,
      localReady = snapshot.readiness.localReady,
      blockers = snapshot.readiness.ignitionBlockers,
      warnings = snapshot.safety.warnings,
    }
  end

  function plc.self_check()
    local snapshot = plc.get_state()
    logInfo("Fusion-PLC self check", {
      ready = snapshot.readiness.localReady and "true" or "false",
      safety = snapshot.safety.status,
      phase = snapshot.reactor.phase,
    })
    return {
      ok = snapshot.devices.reactor.present and snapshot.devices.logic.present and snapshot.devices.laser.detectedCount > 0,
      summary = plc.get_status_summary(),
      state = snapshot,
    }
  end

  function plc.arm_start()
    local snapshot = plc.get_state()
    state.plcStartArmed = snapshot.readiness.localReady == true
    state.plcStartArmClock = os.clock()
    if state.plcStartArmed then
      logInfo("Fusion-PLC start armed", {
        phase = snapshot.reactor.phase,
      })
      return true, snapshot
    end

    logWarn("Fusion-PLC start arm refused", {
      blockers = table.concat(snapshot.readiness.ignitionBlockers or {}, ", "),
    })
    return false, snapshot
  end

  function plc.execute_start()
    local armed, snapshot = plc.arm_start()
    if not armed then
      state.lastAction = "Fusion-PLC start refused"
      return false, snapshot
    end

    logInfo("Fusion-PLC start request accepted", {
      phase = snapshot.reactor.phase,
    })
    local ok = runtimeActions.startReactorSequence()
    state.plcStartArmed = false
    return ok, plc.get_state()
  end

  plc.start = plc.execute_start

  function plc.stop(reason)
    logInfo("Fusion-PLC controlled stop requested", {
      reason = tostring(reason or "manual"),
    })
    runtimeActions.stopReactorSequence(reason or "PLC STOP")
    state.plcStartArmed = false
    return plc.get_state()
  end

  function plc.scram(reason)
    local why = tostring(reason or "PLC SCRAM")
    logWarn("Fusion-PLC SCRAM executed", {
      reason = why,
    })
    runtimeActions.hardStop(why)
    state.plcStartArmed = false
    return plc.get_state()
  end

  function plc.reset_faults()
    state.plcStartArmed = false
    state.ignitionSequencePending = false
    state.ignitionBlockers = runtimeAlerts.getIgnitionBlockers()
    state.safetyWarnings, state.plcSafetyCritical = runtimeAlerts.computeSafetyWarnings()
    logInfo("Fusion-PLC faults refreshed")
    return plc.get_state()
  end

  function plc.run_cycle()
    runtimeActions.fullAuto()
    state.plcSnapshot = getStateSnapshot()
    return state.plcSnapshot
  end

  logInfo("Fusion-PLC controller initialized", {
    role = tostring(state.runtimeRole or "plc"),
  })

  return plc
end

return M
