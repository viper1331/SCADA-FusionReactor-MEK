print("CONFIGURATION> RECHERCHE DU CONFIGURATEUR...")

for _, app in ipairs({ "reactor-plc", "rtu", "supervisor", "coordinator", "pocket" }) do
    if fs.exists(app .. "/configure.lua") then
        local _, _, launch = require(app .. ".configure").configure()
        if launch then shell.execute("/startup") end
        return
    end
end

print("CONFIGURATION> AUCUN CONFIGURATEUR TROUVE")
print("CONFIGURATION> SORTIE")
