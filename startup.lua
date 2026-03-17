local BOOTLOADER_VERSION = "1.2"

print("SCADA BOOTLOADER V" .. BOOTLOADER_VERSION)
print("DEMARRAGE> RECHERCHE DES APPLICATIONS...")

local exit_code

if fs.exists("reactor-plc/startup.lua") then
    print("DEMARRAGE> EXECUTION DU DEMARRAGE PLC REACTEUR")
    exit_code = shell.execute("reactor-plc/startup")
elseif fs.exists("rtu/startup.lua") then
    print("DEMARRAGE> EXECUTION DU DEMARRAGE RTU")
    exit_code = shell.execute("rtu/startup")
elseif fs.exists("supervisor/startup.lua") then
    print("DEMARRAGE> EXECUTION DU DEMARRAGE SUPERVISEUR")
    exit_code = shell.execute("supervisor/startup")
elseif fs.exists("coordinator/startup.lua") then
    print("DEMARRAGE> EXECUTION DU DEMARRAGE COORDINATEUR")
    exit_code = shell.execute("coordinator/startup")
elseif fs.exists("pocket/startup.lua") then
    print("DEMARRAGE> EXECUTION DU DEMARRAGE POCKET")
    exit_code = shell.execute("pocket/startup")
else
    print("DEMARRAGE> AUCUN DEMARRAGE SCADA TROUVE")
    print("DEMARRAGE> SORTIE")
    return false
end

if not exit_code then print("DEMARRAGE> L'APPLICATION A PLANTE") end

return exit_code
