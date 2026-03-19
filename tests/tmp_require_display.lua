local ok, mod = pcall(require, 'io.display_backend')
print('require ok', ok, type(mod))
if not ok then print('err', mod) end
if ok then
  print('has detectCandidate', type(mod.detectCandidate))
end
