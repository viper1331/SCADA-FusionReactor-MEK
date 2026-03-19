-- tests/plc_controller.lua
-- Verifie l'API minimale et l'etat exportable du Fusion-PLC.

local M = {}

function M.run(ctx)
  local fail = assert(ctx.fail, "ctx.fail requis")
  local ok = assert(ctx.ok, "ctx.ok requis")
  local toPath = assert(ctx.toPath, "ctx.toPath requis")

  local previousRequire = _G.require
  _G.require = function(name)
    local relPath = tostring(name or ""):gsub("%.", "/") .. ".lua"
    return dofile(toPath(relPath))
  end

  local loadOk, PlcController = pcall(dofile, toPath("core/plc/controller.lua"))
  _G.require = previousRequire
  if not loadOk or type(PlcController) ~= "table" or type(PlcController.build) ~= "function" then
    fail(120, "Impossible de charger core/plc/controller.lua")
    return
  end

  local state = {
    runtimeRole = "plc",
    tick = 12,
    status = "READY",
    alert = "INFO",
    lastAction = "None",
    ignitionSequencePending = false,
    ignitionChecklist = {},
    ignitionBlockers = {},
    safetyWarnings = {},
    reactorPresent = true,
    reactorFormed = true,
    ignition = false,
    plasmaTemp = 100,
    caseTemp = 90,
    injectionRate = 2,
    hohlraumPresent = true,
    hohlraumCount = 1,
    laserPresent = true,
    laserEnergy = 2500000000,
    laserPct = 100,
    laserDetectedCount = 1,
    laserChargeOn = false,
    laserLineOn = false,
    dOpen = true,
    tOpen = true,
    dtOpen = false,
  }

  local hw = {
    reactor = {},
    reactorName = "reactor_dynamic",
    logic = {},
    logicName = "logic_dynamic",
    laser = {},
    laserName = "laser_dynamic",
    induction = nil,
    inductionName = nil,
    relays = { relay_a = {} },
    readerRoles = {
      deuterium = { name = "reader_d" },
      tritium = { name = "reader_t" },
      inventory = { name = "reader_aux" },
      active = {},
      unknown = {},
    },
  }

  local refreshCalls = 0
  local startCalls = 0
  local stopCalls = 0
  local scramCalls = 0

  local alerts = {
    getLaserState = function()
      return {
        present = true,
        ready = true,
        charging = false,
        status = "READY",
        label = "LAS CHARGE READY",
        thresholdRaw = 2500000000,
      }
    end,
    computeSafetyWarnings = function()
      return {}, false
    end,
    getIgnitionBlockers = function()
      return {}
    end,
    canIgnite = function()
      return true
    end,
    getRuntimeFuelMode = function()
      return "D+T"
    end,
    reactorPhase = function()
      return "READY"
    end,
  }

  local plc = PlcController.build({
    state = state,
    hw = hw,
    runtimeRefresh = {
      refreshAll = function()
        refreshCalls = refreshCalls + 1
      end,
    },
    runtimeActions = {
      startReactorSequence = function()
        startCalls = startCalls + 1
        return true
      end,
      stopReactorSequence = function()
        stopCalls = stopCalls + 1
      end,
      hardStop = function()
        scramCalls = scramCalls + 1
      end,
      fullAuto = function() end,
    },
    runtimeAlerts = alerts,
    log = {},
  })

  local snapshot = plc.refresh_devices()
  if refreshCalls ~= 1 then
    fail(121, "refresh_devices doit appeler runtimeRefresh.refreshAll")
  else
    ok("refresh_devices appelle le refresh critique local")
  end

  if type(snapshot) ~= "table" or snapshot.role ~= "plc" or snapshot.reactor.phase ~= "READY" then
    fail(122, "Etat PLC exportable invalide")
  else
    ok("Etat PLC exportable coherent")
  end

  local armed = plc.arm_start()
  if armed ~= true then
    fail(123, "arm_start devrait accepter un depart valide")
  else
    ok("arm_start valide la readiness locale")
  end

  local started = plc.start()
  if started ~= true or startCalls ~= 1 then
    fail(124, "start doit passer par l'arbitre PLC puis lancer la sequence")
  else
    ok("start passe bien par la couche Fusion-PLC")
  end

  plc.stop("TEST")
  if stopCalls ~= 1 then
    fail(125, "stop doit appeler stopReactorSequence")
  else
    ok("stop route via la couche PLC")
  end

  plc.scram("TEST")
  if scramCalls ~= 1 then
    fail(126, "scram doit appeler hardStop")
  else
    ok("scram route via la couche PLC")
  end
end

return M
