local IoMonitor = dofile('io/monitor.lua')

local gpu = {
  getResolution = function() return 192, 108 end,
  fillRect = function() end,
  drawText = function() end,
  sync = function() end,
}

local hw = { monitor = gpu, monitorName = 'tm_gpu_any' }
local cfg = { displayOutput = 'both', monitorScale = 1.0 }
local palette = { bg = colors.black, text = colors.white }
local chosen = {
  name='tm_gpu_any', obj=gpu, backend='toms_gpu', touchEvent='tm_monitor_touch', w=16, h=8
}

print('term.redirect before', type(term.redirect))
local originalRedirect = term.redirect
local originalSetCursorBlink = term.setCursorBlink
term.redirect = function(target)
  print('redirect called', type(target), type(target and target.setTextScale))
  return target
end
term.setCursorBlink = function() end

local ok, err = xpcall(function()
  return IoMonitor.setupMonitor(term.current(), hw, cfg, palette, chosen, function() return 'tm_gpu' end, nil)
end, debug.traceback)
print('ok?', ok)
if not ok then print(err) end
print('hw.monitorBackend', tostring(hw.monitorBackend))
print('surface methods', type(hw.displaySurface), type(hw.displaySurface and hw.displaySurface.setBackgroundColor), type(hw.displaySurface and hw.displaySurface.clear))

term.redirect = originalRedirect
term.setCursorBlink = originalSetCursorBlink
