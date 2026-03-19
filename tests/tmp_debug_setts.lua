local IoMonitor = dofile('io/monitor.lua')
local gpu = {
  getResolution=function() return 192,108 end,
  fillRect=function() end,
  drawText=function() end,
  sync=function() end,
  setTextScale=function(...) print('setTextScale CALLED', select('#', ...)) end,
}
local hw={monitor=gpu, monitorName='tm_gpu_any'}
local cfg={displayOutput='both', monitorScale=1.0}
local palette={bg=colors.black,text=colors.white}
local chosen={name='tm_gpu_any', obj=gpu, backend='toms_gpu', touchEvent='tm_monitor_touch', w=16,h=8}
local originalRedirect = term.redirect
term.redirect = function(target) print('redirect called') return target end
local ok, err = xpcall(function()
  return IoMonitor.setupMonitor(term.current(), hw, cfg, palette, chosen, function() return 'tm_gpu' end, nil)
end, debug.traceback)
print('ok', ok)
if not ok then print(err) end
term.redirect = originalRedirect
