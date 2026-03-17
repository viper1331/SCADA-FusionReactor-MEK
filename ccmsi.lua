--[[
CC-MEK-SCADA Installer Utility

Copyright (c) 2023 - 2024 Mikayla Fischler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

local CCMSI_VERSION = "v1.21"

local install_dir = "/.install-cache"
local default_manifest_path = "https://raw.githubusercontent.com/viper1331/SCADA-FusionReactor-MEK/"
local default_repo_path = "https://raw.githubusercontent.com/viper1331/SCADA-FusionReactor-MEK/"
local manifest_path = default_manifest_path
local repo_path = default_repo_path
local install_manifest = manifest_path .. "main/install_manifest.json"
local use_local_files = false

---@diagnostic disable-next-line: undefined-global
local _is_pkt_env = pocket -- luacheck: ignore pocket

local _translate = function(msg) return tostring(msg) end
do
    local ok, i18n = pcall(require, "scada-common.i18n")
    if ok and type(i18n) == "table" and type(i18n.translate_console) == "function" then
        _translate = i18n.translate_console
    end
end

local function println(msg) print(_translate(tostring(msg))) end

-- stripped down & modified copy of log.dmesg
local function print(msg)
    msg = _translate(tostring(msg))

    local cur_x, cur_y = term.getCursorPos()
    local out_w, out_h = term.getSize()

    -- jump to next line if needed
    if cur_x == out_w then
        cur_x = 1
        if cur_y == out_h then
            term.scroll(1)
            term.setCursorPos(1, cur_y)
        else
            term.setCursorPos(1, cur_y + 1)
        end
    end

    -- wrap
    local lines, remaining, s_start, s_end, ln = {}, true, 1, out_w + 1 - cur_x, 1
    while remaining do
        local line = string.sub(msg, s_start, s_end)

        if line == "" then
            remaining = false
        else
            lines[ln] = line
            s_start = s_end + 1
            s_end = s_end + out_w
            ln = ln + 1
        end
    end

    -- print
    for i = 1, #lines do
        cur_x, cur_y = term.getCursorPos()
        if i > 1 and cur_x > 1 then
            if cur_y == out_h then
                term.scroll(1)
                term.setCursorPos(1, cur_y)
            else term.setCursorPos(1, cur_y + 1) end
        end
        term.write(lines[i])
    end
end

local opts = { ... }
local mode, app, target

local function red() term.setTextColor(colors.red) end
local function orange() term.setTextColor(colors.orange) end
local function yellow() term.setTextColor(colors.yellow) end
local function green() term.setTextColor(colors.green) end
local function cyan() term.setTextColor(colors.cyan) end
local function blue() term.setTextColor(colors.blue) end
local function white() term.setTextColor(colors.white) end
local function lgray() term.setTextColor(colors.lightGray) end

-- normalize URL paths
---@param path string
---@return string
local function with_trailing_slash(path)
    if path ~= "" and string.sub(path, -1) ~= "/" then
        return path .. "/"
    else
        return path
    end
end

-- load optional source override configuration
-- file: ccmsi_source.lua
-- returns table with:
--   manifest_path = "https://.../manifests/"
--   repo_path = "https://raw.githubusercontent.com/<owner>/<repo>/"
--   use_local_files = true|false
local function load_source_config()
    local local_override = nil ---@type boolean|nil

    if fs.exists("ccmsi_source.lua") and not fs.isDir("ccmsi_source.lua") then
        local ok, cfg = pcall(dofile, "ccmsi_source.lua")

        if ok and type(cfg) == "table" then
            if type(cfg.manifest_path) == "string" and cfg.manifest_path ~= "" then
                manifest_path = with_trailing_slash(cfg.manifest_path)
            end

            if type(cfg.repo_path) == "string" and cfg.repo_path ~= "" then
                repo_path = with_trailing_slash(cfg.repo_path)
            end

            if type(cfg.use_local_files) == "boolean" then
                local_override = cfg.use_local_files
            end
        else
            yellow();println("warning: failed to load ccmsi_source.lua, using built-in source");white()
        end
    end

    -- if running directly from a full repository checkout, prefer local source files
    local in_repo_checkout = fs.exists("build/imgen.py") and fs.exists("scada-common/util.lua") and fs.exists("graphics/core.lua")

    if local_override ~= nil then
        use_local_files = local_override
    else
        use_local_files = in_repo_checkout
    end
end

load_source_config()

-- get command line option in list
local function get_opt(opt, options)
    for _, v in pairs(options) do if opt == v then return v end end
    return nil
end

-- wait for any key to be pressed
---@diagnostic disable-next-line: undefined-field
local function any_key() os.pullEvent("key_up") end

-- ask the user yes or no
local function ask_y_n(question, default)
    print(question)
    if default == true then print(" (Y/n)? ") else print(" (y/N)? ") end
    local response = read();any_key()
    if response == "" then return default
    elseif response == "Y" or response == "y" then return true
    elseif response == "N" or response == "n" then return false
    else return nil end
end

-- print out a white + blue text message
local function pkg_message(message, package) white();print(message.." ");blue();println(package);white() end

-- indicate actions to be taken based on package differences for installs/updates
local function show_pkg_change(name, v)
    if v.v_local ~= nil then
        if v.v_local ~= v.v_remote then
            print("["..name.."] updating ");blue();print(v.v_local);white();print(" \xbb ");blue();println(v.v_remote);white()
        elseif mode == "install" then
            pkg_message("["..name.."] reinstalling", v.v_local)
        end
    else pkg_message("["..name.."] new install of", v.v_remote) end
    return v.v_local ~= v.v_remote
end

-- validate an installation manifest object
---@param manifest table|nil
---@return boolean ok, string? reason
local function validate_manifest(manifest)
    local function valid_list(v)
        return type(v) == "table" and #v > 0
    end

    local function has_dep(app_name)
        return type(manifest.depends[app_name]) == "table" and #manifest.depends[app_name] > 0
    end

    if type(manifest) ~= "table" then
        return false, "manifest is not a table"
    elseif type(manifest.versions) ~= "table" then
        return false, "manifest is missing versions"
    elseif type(manifest.files) ~= "table" then
        return false, "manifest is missing files"
    elseif type(manifest.depends) ~= "table" then
        return false, "manifest is missing depends"
    elseif type(manifest.sizes) ~= "table" then
        return false, "manifest is missing sizes"
    elseif type(manifest.versions.installer) ~= "string" then
        return false, "manifest is missing installer version"
    elseif not valid_list(manifest.files.system) then
        return false, "manifest has no system files"
    elseif not valid_list(manifest.files.common) then
        return false, "manifest has no common files"
    elseif not valid_list(manifest.files.graphics) then
        return false, "manifest has no graphics files"
    elseif not valid_list(manifest.files.lockbox) then
        return false, "manifest has no lockbox files"
    elseif not valid_list(manifest.files["reactor-plc"]) then
        return false, "manifest has no reactor-plc files"
    elseif not valid_list(manifest.files.rtu) then
        return false, "manifest has no rtu files"
    elseif not valid_list(manifest.files.supervisor) then
        return false, "manifest has no supervisor files"
    elseif not valid_list(manifest.files.coordinator) then
        return false, "manifest has no coordinator files"
    elseif not valid_list(manifest.files.pocket) then
        return false, "manifest has no pocket files"
    elseif not has_dep("reactor-plc") or not has_dep("rtu") or not has_dep("supervisor") or not has_dep("coordinator") or not has_dep("pocket") then
        return false, "manifest has missing dependency definitions"
    end

    return true, nil
end

-- recursively list files under a directory
---@param path string
---@return string[] files
local function list_files(path)
    local files = {}

    local function _walk(dir)
        if not fs.exists(dir) or not fs.isDir(dir) then return end

        local entries = fs.list(dir)
        for i = 1, #entries do
            local entry = entries[i]
            local full = dir .. "/" .. entry
            if fs.isDir(full) then
                _walk(full)
            else
                table.insert(files, full)
            end
        end
    end

    _walk(path)
    return files
end

-- get size of one file if it exists
---@param path string
---@return integer size
local function file_size(path)
    if fs.exists(path) and not fs.isDir(path) then
        return fs.getSize(path)
    end
    return 0
end

-- recursively get the total size of all files in a directory
---@param path string
---@return integer size
local function dir_size(path)
    local total = 0
    local files = list_files(path)

    for i = 1, #files do
        total = total + file_size(files[i])
    end

    return total
end

-- parse a version string from a Lua source file
---@param path string
---@param marker string
---@return string
local function parse_version(path, marker)
    if not fs.exists(path) or fs.isDir(path) then return "missing" end

    local handle = fs.open(path, "r")
    if handle == nil then return "missing" end

    local version = "unknown"

    while true do
        local line = handle.readLine()
        if line == nil then break end

        local _, e = string.find(line, marker, 1, true)
        if e ~= nil then
            local tail = string.sub(line, e + 1)
            local q = string.find(tail, "\"", 1, true)

            if q ~= nil then
                version = string.sub(tail, 1, q - 1)
            else
                version = tail
            end

            break
        end
    end

    handle.close()
    return version
end

-- build an installation manifest from local repository files
---@return table manifest
local function build_local_manifest()
    local system_files = {}

    local function add_system(path)
        if fs.exists(path) and not fs.isDir(path) then
            table.insert(system_files, path)
        end
    end

    add_system("initenv.lua")
    add_system("startup.lua")
    add_system("configure.lua")
    add_system("LICENSE")

    local manifest = {
        versions = {
            installer = parse_version("ccmsi.lua", "CCMSI_VERSION = \""),
            bootloader = parse_version("startup.lua", "BOOTLOADER_VERSION = \""),
            common = parse_version("scada-common/util.lua", ".version = \""),
            comms = parse_version("scada-common/comms.lua", ".version = \""),
            graphics = parse_version("graphics/core.lua", ".version = \""),
            lockbox = parse_version("lockbox/init.lua", ".version = \""),
            ["reactor-plc"] = parse_version("reactor-plc/startup.lua", "_VERSION = \""),
            rtu = parse_version("rtu/startup.lua", "_VERSION = \""),
            supervisor = parse_version("supervisor/startup.lua", "_VERSION = \""),
            coordinator = parse_version("coordinator/startup.lua", "_VERSION = \""),
            pocket = parse_version("pocket/startup.lua", "_VERSION = \"")
        },
        files = {
            system = system_files,
            common = list_files("scada-common"),
            graphics = list_files("graphics"),
            lockbox = list_files("lockbox"),
            ["reactor-plc"] = list_files("reactor-plc"),
            rtu = list_files("rtu"),
            supervisor = list_files("supervisor"),
            coordinator = list_files("coordinator"),
            pocket = list_files("pocket")
        },
        depends = {
            ["reactor-plc"] = { "system", "common", "graphics", "lockbox" },
            rtu = { "system", "common", "graphics", "lockbox" },
            supervisor = { "system", "common", "graphics", "lockbox" },
            coordinator = { "system", "common", "graphics", "lockbox" },
            pocket = { "system", "common", "graphics", "lockbox" }
        },
        sizes = {
            manifest = file_size("install_manifest.json"),
            system = file_size("initenv.lua") + file_size("startup.lua") + file_size("configure.lua") + file_size("LICENSE"),
            common = dir_size("scada-common"),
            graphics = dir_size("graphics"),
            lockbox = dir_size("lockbox"),
            ["reactor-plc"] = dir_size("reactor-plc"),
            rtu = dir_size("rtu"),
            supervisor = dir_size("supervisor"),
            coordinator = dir_size("coordinator"),
            pocket = dir_size("pocket")
        }
    }

    return manifest
end

-- read the local manifest file
local function read_local_manifest()
    local local_ok = false
    local local_manifest = {}
    local imfile = fs.open("install_manifest.json", "r")
    if imfile ~= nil then
        local ok, parsed = pcall(function () return textutils.unserializeJSON(imfile.readAll()) end)
        if ok and type(parsed) == "table" and type(parsed.versions) == "table" then
            local_ok = true
            local_manifest = parsed
        end
        imfile.close()
    end
    return local_ok, local_manifest
end

-- get the manifest from GitHub
local function get_remote_manifest()
    if use_local_files then
        local mf = fs.open("install_manifest.json", "r")

        if mf == nil then
            yellow();println("local install_manifest.json not found; generating manifest from local files");white()
            local gen_manifest = build_local_manifest()
            local valid, reason = validate_manifest(gen_manifest)
            if valid then return true, gen_manifest end
            red();println("generated local manifest invalid: " .. reason);white()
            return false, {}
        end

        local ok, manifest = pcall(function () return textutils.unserializeJSON(mf.readAll()) end)
        mf.close()

        if not ok then
            yellow();println("failed to parse local install_manifest.json; generating manifest from local files");white()
            local gen_manifest = build_local_manifest()
            local valid, reason = validate_manifest(gen_manifest)
            if valid then return true, gen_manifest end
            red();println("generated local manifest invalid: " .. reason);white()
            return false, {}
        end

        local valid, reason = validate_manifest(manifest)
        if not valid then
            yellow();println("invalid local installation manifest: " .. reason);white()
            yellow();println("generating manifest from local files instead");white()
            local gen_manifest = build_local_manifest()
            valid, reason = validate_manifest(gen_manifest)
            if valid then return true, gen_manifest end
            red();println("generated local manifest invalid: " .. reason);white()
            return false, {}
        end

        return true, manifest
    end

    local response, error = http.get(install_manifest)
    if response == nil then
        orange();println("Failed to get installation manifest from GitHub, cannot update or install.")
        red();println("HTTP error: "..error);white()
        return false, {}
    end

    local ok, manifest = pcall(function () return textutils.unserializeJSON(response.readAll()) end)
    if not ok then
        red();println("error parsing remote installation manifest");white()
        return false, {}
    end

    local valid, reason = validate_manifest(manifest)
    if not valid then
        red();println("invalid remote installation manifest: " .. reason);white()
        return false, {}
    end

    return ok, manifest
end

-- record the local installation manifest
local function write_install_manifest(manifest, deps)
    local versions = {}
    for key, value in pairs(manifest.versions) do
        local is_dep = false
        for _, dep in pairs(deps) do
            if (key == "bootloader" and dep == "system") or key == dep then
                is_dep = true;break
            end
        end
        if key == app or key == "comms" or is_dep then versions[key] = value end
    end

    -- compact payload: keep only selected package file lists needed for uninstall
    local compact = {
        versions = versions,
        files = {},
        depends = { [app] = {} },
        sizes = { manifest = 0 }
    }

    for _, dep in pairs(deps) do
        if dep ~= app then
            table.insert(compact.depends[app], dep)
        end

        if type(manifest.files) == "table" and type(manifest.files[dep]) == "table" then
            compact.files[dep] = manifest.files[dep]
        end
    end

    -- minimal payload fallback: versions only
    local minimal = { versions = versions }

    ---@param payload table
    ---@return boolean ok, string|nil err
    local function write_payload(payload)
        local data = textutils.serializeJSON(payload)
        local imfile = fs.open("install_manifest.json", "w")

        if imfile == nil then
            return false, "open failed"
        end

        local ok, err = pcall(function ()
            imfile.write(data)
            imfile.close()
        end)

        if not ok then
            pcall(function () imfile.close() end)
            return false, tostring(err)
        end

        return true, nil
    end

    local ok, err = write_payload(compact)
    if ok then return true, "compact" end

    ok, err = write_payload(minimal)
    if ok then return true, "minimal" end

    return false, err
end

-- try at most 3 times to download a file from the repository and write into w_path base directory
---@return 0|1|2|3 success 0: ok, 1: download fail, 2: file open fail, 3: out of space
local function http_get_file(file, w_path)
    -- ensure destination directory exists
    ---@param path string
    ---@return 0|2|3
    local function ensure_dir(path)
        if path == "" or fs.exists(path) then return 0 end

        local ok, err = pcall(function () fs.makeDir(path) end)
        if not ok then
            if string.find(tostring(err), "Out of space") ~= nil then
                red();println("[out of space]");lgray()
                return 3
            else
                return 2
            end
        end

        if fs.exists(path) then return 0 else return 2 end
    end

    if use_local_files then
        local dest_path = fs.combine(w_path, file)
        local source_abs = file

        if shell and type(shell.resolve) == "function" then
            source_abs = shell.resolve(file)
        end

        local src_norm = source_abs
        local dst_norm = dest_path
        if string.sub(src_norm, 1, 1) ~= "/" then src_norm = fs.combine("/", src_norm) end
        if string.sub(dst_norm, 1, 1) ~= "/" then dst_norm = fs.combine("/", dst_norm) end

        -- no-op if the source file already is the destination file
        if src_norm == dst_norm then
            return 0
        end

        local in_file = fs.open(file, "r")
        if in_file == nil then
            red();println("Local source file missing: "..file);lgray()
            return 1
        end

        local source_data = in_file.readAll()
        in_file.close()

        local dest_dir = fs.getDir(dest_path)
        local mk = ensure_dir(dest_dir)
        if mk ~= 0 then return mk end

        local out_file = fs.open(dest_path, "w")
        if out_file == nil then return 2 end

        local ok, msg = pcall(function () out_file.write(source_data) end)
        out_file.close()

        if not ok then
            if string.find(msg or "", "Out of space") ~= nil then
                red();println("[out of space]");lgray()
                return 3
            else
                return 2
            end
        end

        return 0
    end

    local dl, err
    for i = 1, 3 do
        dl, err = http.get(repo_path..file)
        if dl then
            if i > 1 then green();println("success!");lgray() end
            local dest_path = fs.combine(w_path, file)
            local dest_dir = fs.getDir(dest_path)
            local mk = ensure_dir(dest_dir)
            if mk ~= 0 then
                dl.close()
                return mk
            end

            local f = fs.open(dest_path, "w")
            if not f then return 2 end
            local ok, msg = pcall(function() f.write(dl.readAll()) end)
            f.close()
            dl.close()
            if not ok then
                if string.find(msg or "", "Out of space") ~= nil then
                    red();println("[out of space]");lgray()
                    return 3
                else return 2 end
            end
            break
        else
            red();println("HTTP Error: "..err)
            if i < 3 then
                lgray();print("> retrying...")
                ---@diagnostic disable-next-line: undefined-field
                os.sleep(i/3.0)
            else
                return 1
            end
        end
    end
    return 0
end

-- recursively build a tree out of the file manifest
local function gen_tree(manifest, log)
    local function _tree_add(tree, split)
        if #split > 1 then
            local name = table.remove(split, 1)
            if tree[name] == nil then tree[name] = {} end
            table.insert(tree[name], _tree_add(tree[name], split))
        else return split[1] end
        return nil
    end

    local list, tree = { log }, {}

    -- make a list of each and every file
    for _, files in pairs(manifest.files) do for i = 1, #files do table.insert(list, files[i]) end end

    for i = 1, #list do
        local split = {}
---@diagnostic disable-next-line: discard-returns
        string.gsub(list[i], "([^/]+)", function(c) split[#split + 1] = c end)
        if #split == 1 then table.insert(tree, list[i])
        else table.insert(tree, _tree_add(tree, split)) end
    end

    return tree
end

local function _in_array(val, array)
    for _, v in pairs(array) do if v == val then return true end end
    return false
end

local function _clean_dir(dir, tree)
    if tree == nil then tree = {} end
    local ls = fs.list(dir)
    for _, val in pairs(ls) do
        local path = dir.."/"..val
        if fs.isDir(path) then
            _clean_dir(path, tree[val])
            if #fs.list(path) == 0 then fs.delete(path);println("deleted "..path) end
        elseif (not _in_array(val, tree)) and (val ~= "config.lua" ) then ---@todo remove config.lua on full release
            fs.delete(path)
            println("deleted "..path)
        end
    end
end

-- go through app/common directories to delete unused files
local function clean(manifest)
    local log = nil
    if fs.exists(app..".settings") and settings.load(app..".settings") then
        log = settings.get("LogPath")
        if log:sub(1, 1) == "/" then log = log:sub(2) end
    end

    local tree = gen_tree(manifest, log)

    table.insert(tree, "install_manifest.json")
    table.insert(tree, "ccmsi.lua")

    local ls = fs.list("/")
    for _, val in pairs(ls) do
        if fs.isDriveRoot(val) then
            yellow();println("skipped mount '"..val.."'")
        elseif fs.isDir(val) then
            if tree[val] ~= nil then lgray();_clean_dir("/"..val, tree[val])
            else white(); if ask_y_n("delete the unused directory '"..val.."'") then lgray();_clean_dir("/"..val) end end
            if #fs.list(val) == 0 then fs.delete(val);lgray();println("deleted empty directory '"..val.."'") end
        elseif not _in_array(val, tree) and (string.find(val, ".settings") == nil) then
            white();if ask_y_n("delete the unused file '"..val.."'") then fs.delete(val);lgray();println("deleted "..val) end
        end
    end

    white()
end

-- get and validate command line options

if _is_pkt_env then println("- SCADA Installer "..CCMSI_VERSION.." -")
else println("-- CC Mekanism SCADA Installer "..CCMSI_VERSION.." --") end

if #opts == 0 or opts[1] == "help" then
    println("usage: ccmsi <mode> <app> <branch>")
    if _is_pkt_env then
    yellow();println("<mode>");lgray()
    println(" check - check latest")
    println(" install - fresh install")
    println(" update - update app")
    println(" uninstall - remove app")
    yellow();println("<app>");lgray()
    println(" reactor-plc")
    println(" rtu")
    println(" rtu-fusion")
    println(" supervisor")
    println(" coordinator")
    println(" pocket")
    println(" installer (update only)")
    yellow();println("<branch>");lgray();
    println(" main (default) | devel");white()
    lgray();println("optional source override: ccmsi_source.lua")
    else
    println("<mode>")
    lgray()
    println(" check       - check latest versions available")
    yellow()
    println("               ccmsi check <branch> for target")
    lgray()
    println(" install     - fresh install")
    println(" update      - update files")
    println(" uninstall   - delete files INCLUDING config/logs")
    white();println("<app>");lgray()
    println(" reactor-plc - reactor PLC firmware")
    println(" rtu         - RTU firmware")
    println(" rtu-fusion  - alias for RTU firmware (fusion setup)")
    println(" supervisor  - supervisor server application")
    println(" coordinator - coordinator application")
    println(" pocket      - pocket application")
    println(" installer   - ccmsi installer (update only)")
    white();println("<branch>")
    lgray();println(" main (default) | devel");white()
    lgray();println("optional source override: ccmsi_source.lua")
    end
    return
else

    mode = get_opt(opts[1], { "check", "install", "update", "uninstall" })
    if mode == nil then
        red();println("Unrecognized mode.");white()
        return
    end

    local next_opt = 3
    local apps = { "reactor-plc", "rtu", "supervisor", "coordinator", "pocket", "installer" }
    local app_inputs = { "reactor-plc", "rtu", "rtu-fusion", "supervisor", "coordinator", "pocket", "installer" }

    app = get_opt(opts[2], app_inputs)
    if app == "rtu-fusion" then
        app = "rtu"
    end
    if app == nil then
        for _, a in pairs(apps) do
            if fs.exists(a) and fs.isDir(a) then
                app = a
                next_opt = 2
                break
            end
        end
    end

    if app == nil and mode ~= "check" then
        red();println("Unrecognized application.");white()
        return
    elseif mode == "check" then
        next_opt = 2
    elseif app == "installer" and mode ~= "update" then
        red();println("Installer app only supports 'update' option.");white()
        return
    end

    -- determine target
    target = opts[next_opt]
    if (target ~= "main") and (target ~= "devel") then
        if (target and target ~= "") then yellow();println("Unknown target, defaulting to 'main'");white() end
        target = "main"
    end

    -- set paths
    if use_local_files then
        install_manifest = "install_manifest.json"
    else
        install_manifest = manifest_path .. target .. "/install_manifest.json"
        repo_path = repo_path .. target .. "/"
    end
end

-- run selected mode
if mode == "check" then
    local ok, manifest = get_remote_manifest()
    if not ok then return end

    local local_ok, local_manifest = read_local_manifest()
    if not local_ok then
        yellow();println("failed to load local installation information");white()
        local_manifest = { versions = { installer = CCMSI_VERSION } }
    else
        local_manifest.versions.installer = CCMSI_VERSION
    end

    -- list all versions
    for key, value in pairs(manifest.versions) do
        term.setTextColor(colors.purple)
        local tag = string.format("%-14s", "["..key.."]")
        if not _is_pkt_env then print(tag) end
        if key == "installer" or (local_ok and (local_manifest.versions[key] ~= nil)) then
            if _is_pkt_env then println(tag) end
            blue();print(local_manifest.versions[key])
            if value ~= local_manifest.versions[key] then
                white();print(" (")
                cyan();print(value);white();println(" available)")
            else green();println(" (up to date)") end
        elseif not _is_pkt_env then
            lgray();print("not installed");white();print(" (latest ")
            cyan();print(value);white();println(")")
        end
    end

    if manifest.versions.installer ~= local_manifest.versions.installer and not _is_pkt_env then
        yellow();println("\nA different version of the installer is available, it is recommended to update (use 'ccmsi update installer').");white()
    end
elseif mode == "install" or mode == "update" then
    local ok, r_manifest, l_manifest

    local update_installer = app == "installer"
    ok, r_manifest = get_remote_manifest()
    if not ok then return end

    local ver = {
        app = { v_local = nil, v_remote = nil, changed = false },
        boot = { v_local = nil, v_remote = nil, changed = false },
        comms = { v_local = nil, v_remote = nil, changed = false },
        common = { v_local = nil, v_remote = nil, changed = false },
        graphics = { v_local = nil, v_remote = nil, changed = false },
        lockbox = { v_local = nil, v_remote = nil, changed = false }
    }

    -- try to find local versions
    ok, l_manifest = read_local_manifest()
    if mode == "update" and not update_installer then
        if not ok then
            red();println("Failed to load local installation information, cannot update.");white()
            return
        else
            ver.boot.v_local = l_manifest.versions.bootloader
            ver.app.v_local = l_manifest.versions[app]
            ver.comms.v_local = l_manifest.versions.comms
            ver.common.v_local = l_manifest.versions.common
            ver.graphics.v_local = l_manifest.versions.graphics
            ver.lockbox.v_local = l_manifest.versions.lockbox

            if l_manifest.versions[app] == nil then
                red();println("Another application is already installed, please uninstall it before installing a new application.");white()
                return
            end
        end
    end

    if r_manifest.versions.installer ~= CCMSI_VERSION then
        if not update_installer then yellow();println("A different version of the installer is available, it is recommended to update to it.");white() end
        if update_installer or ask_y_n("Would you like to update now", true) then
            lgray();println("GET ccmsi.lua")

            local src_data, dl, err

            if use_local_files then
                local src = fs.open("ccmsi.lua", "r")
                if src == nil then
                    err = "local source file not found"
                else
                    src_data = src.readAll()
                    src.close()
                end
            else
                dl, err = http.get(repo_path.."ccmsi.lua")
            end

            if src_data == nil and dl == nil then
                red();println("Installer source error: "..err)
                println("Installer download failed.");white()
            else
                local handle = fs.open(debug.getinfo(1, "S").source:sub(2), "w") -- this file, regardless of name or location
                if src_data ~= nil then
                    handle.write(src_data)
                else
                    handle.write(dl.readAll())
                    dl.close()
                end
                handle.close()
                green();println("Installer updated successfully.");white()
            end

            return
        end
    elseif update_installer then
        green();println("Installer already up-to-date.");white()
        return
    end

    ver.boot.v_remote = r_manifest.versions.bootloader
    ver.app.v_remote = r_manifest.versions[app]
    ver.comms.v_remote = r_manifest.versions.comms
    ver.common.v_remote = r_manifest.versions.common
    ver.graphics.v_remote = r_manifest.versions.graphics
    ver.lockbox.v_remote = r_manifest.versions.lockbox

    green()
    if mode == "install" then print("Installing ") else print("Updating ") end
    println(app.." files...");white()

    ver.boot.changed = show_pkg_change("bootldr", ver.boot)
    ver.common.changed = show_pkg_change("common", ver.common)
    ver.comms.changed = show_pkg_change("comms", ver.comms)
    if ver.comms.changed and ver.comms.v_local ~= nil then
        print("[comms] ");yellow();println("other devices on the network will require an update");white()
    end
    ver.app.changed = show_pkg_change(app, ver.app)
    ver.graphics.changed = show_pkg_change("graphics", ver.graphics)
    ver.lockbox.changed = show_pkg_change("lockbox", ver.lockbox)

    -- start install/update

    local space_req = r_manifest.sizes.manifest
    local space_avail = fs.getFreeSpace("/")

    local file_list = r_manifest.files
    local size_list = r_manifest.sizes
    local deps = r_manifest.depends[app]

    table.insert(deps, app)

    -- helper function to check if a dependency is unchanged
    local function unchanged(dep)
        if dep == "system" then return not ver.boot.changed
        elseif dep == "graphics" then return not ver.graphics.changed
        elseif dep == "lockbox" then return not ver.lockbox.changed
        elseif dep == "common" then return not (ver.common.changed or ver.comms.changed)
        elseif dep == app then return not ver.app.changed
        else return true end
    end

    local any_change = false

    for _, dep in pairs(deps) do
        local size = size_list[dep]
        space_req = space_req + size
        any_change = any_change or not unchanged(dep)
    end

    if mode == "update" and not any_change then
        yellow();println("Nothing to do, everything is already up-to-date!");white()
        return
    end

    -- ask for confirmation
    if not ask_y_n("Continue", false) then return end

    -- local-source mode should install directly without using /.install-cache
    local single_file_mode = use_local_files or (space_avail < space_req)

    local success = true

    -- delete a file if the capitalization changes so that things work on Windows
    ---@param path string
    local function mitigate_case(path)
        local dir, file = fs.getDir(path), fs.getName(path)
        if not fs.isDir(dir) then return end
        for _, p in ipairs(fs.list(dir)) do
            if string.lower(p) == string.lower(file) then
                if p ~= file then fs.delete(path) end
                return
            end
        end
    end

    ---@param dl_stat 1|2|3 download status
    ---@param file string file name
    ---@param attempt integer recursive attempt #
    ---@param sf_install function installer function for recursion
    local function handle_dl_fail(dl_stat, file, attempt, sf_install)
        red()
        if dl_stat == 1 then
            println("failed to download "..file)
        elseif dl_stat > 1 then
            if dl_stat == 2 then println("filesystem error with "..file) else println("no space for "..file) end
            if attempt == 1 then
                orange();println("re-attempting operation...");white()
                sf_install(2)
            elseif attempt == 2 then
                yellow()
                if dl_stat == 2 then println("There was an error writing to a file.") else println("Insufficient space available.") end
                lgray()
                if dl_stat == 2 then
                    println("This may be due to insufficent space available or file permission issues. The installer can now attempt to delete files not used by the SCADA system.")
                else
                    println("The installer can now attempt to delete files not used by the SCADA system.")
                end
                white()
                if not ask_y_n("Continue", false) then
                    success = false
                    return
                end
                clean(r_manifest)
                sf_install(3)
            elseif attempt == 3 then
                yellow()
                if dl_stat == 2 then println("There again was an error writing to a file.") else println("Insufficient space available.") end
                lgray()
                if dl_stat == 2 then
                    println("This may be due to insufficent space available or file permission issues. Please delete any unused files you have on this computer then try again. Do not delete the "..app..".settings file unless you want to re-configure.")
                else
                    println("Please delete any unused files you have on this computer then try again. Do not delete the "..app..".settings file unless you want to re-configure.")
                end
                white()
                success = false
            end
        end
    end

    -- single file update routine: go through all files and replace one by one
    ---@param attempt integer recursive attempt #
    local function sf_install(attempt)
---@diagnostic disable-next-line: undefined-field
        if attempt > 1 then os.sleep(2.0) end

        local abort_attempt = false
        success = true

        for _, dep in pairs(deps) do
            if mode == "update" and unchanged(dep) then
                pkg_message("skipping install of unchanged package", dep)
            else
                pkg_message("installing package", dep)
                lgray()

                -- beginning on the second try, delete the directory before starting
                if attempt >= 2 then
                    if dep == "system" then
                    elseif dep == "common" then
                        if fs.exists("/scada-common") then
                            fs.delete("/scada-common")
                            println("deleted /scada-common")
                        end
                    else
                        if fs.exists("/"..dep) then
                            fs.delete("/"..dep)
                            println("deleted /"..dep)
                        end
                    end
                end

                local files = file_list[dep]
                for _, file in pairs(files) do
                    println("GET "..file)
                    mitigate_case(file)
                    local dl_stat = http_get_file(file, "/")
                    if dl_stat ~= 0 then
                        abort_attempt = true
---@diagnostic disable-next-line: param-type-mismatch
                        handle_dl_fail(dl_stat, file, attempt, sf_install)
                        break
                    end
                end
            end
            if abort_attempt or not success then break end
        end
    end

    -- handle update/install
    if single_file_mode then sf_install(1)
    else
        if fs.exists(install_dir) then fs.delete(install_dir) end
        local mk_ok, mk_err = pcall(function () fs.makeDir(install_dir) end)
        if (not mk_ok) or (not fs.exists(install_dir)) then
            red();println("failed to prepare install cache: " .. tostring(mk_err))
            success = false
        end

        -- download all dependencies
        for _, dep in pairs(deps) do
            if not success then break end
            if mode == "update" and unchanged(dep) then
                pkg_message("skipping download of unchanged package", dep)
            else
                pkg_message("downloading package", dep)
                lgray()

                local files = file_list[dep]
                for _, file in pairs(files) do
                    println("GET "..file)
                    local dl_stat = http_get_file(file, install_dir.."/")
                    success = dl_stat == 0
                    if dl_stat == 1 then
                        red();println("failed to download "..file)
                        break
                    elseif dl_stat == 2 then
                        red();println("filesystem error with "..file)
                        break
                    elseif dl_stat == 3 then
                        -- this shouldn't occur in this mode
                        red();println("no space for "..file)
                        break
                    end
                end
            end
            if not success then break end
        end

        -- copy in downloaded files (installation)
        if success then
            for _, dep in pairs(deps) do
                if mode == "update" and unchanged(dep) then
                    pkg_message("skipping install of unchanged package", dep)
                else
                    pkg_message("installing package", dep)
                    lgray()

                    local files = file_list[dep]
                    for _, file in pairs(files) do
                        local temp_file = install_dir.."/"..file
                        if fs.exists(file) then fs.delete(file) end
                        fs.move(temp_file, file)
                    end
                end
            end
        end

        fs.delete(install_dir)
    end

    if success then
        local m_ok, m_mode_or_err = write_install_manifest(r_manifest, deps)

        if not m_ok then
            yellow();println("warning: installation manifest not saved (" .. tostring(m_mode_or_err) .. ")");white()
            yellow();println("installation completed, but update/uninstall metadata may be incomplete");white()
        elseif m_mode_or_err == "minimal" then
            yellow();println("warning: saved minimal install manifest due to low disk space");white()
        end

        green()
        if mode == "install" then
            println("Installation completed successfully.")
        else println("Update completed successfully.") end
        white();println("Ready to clean up unused files, press any key to continue...")
        any_key();clean(r_manifest)
        white();println("Done.")
    else
        red()
        if single_file_mode then
            if mode == "install" then
                println("Installation failed, files may have been skipped.")
            else println("Update failed, files may have been skipped.") end
        else
            if mode == "install" then
                println("Installation failed.")
            else orange();println("Update failed, existing files unmodified.") end
        end
    end
elseif mode == "uninstall" then
    local ok, manifest = read_local_manifest()
    if not ok then
        red();println("Error parsing local installation manifest.");white()
        return
    end

    if manifest.versions[app] == nil then
        red();println("Error: '"..app.."' is not installed.")
        return
    end

    orange();println("Uninstalling all "..app.." files...")

    -- ask for confirmation
    if not ask_y_n("Continue", false) then return end

    -- delete unused files first
    if type(manifest.files) == "table" and type(manifest.depends) == "table" then
        clean(manifest)
    else
        yellow();println("local manifest has no file tree; skipping pre-clean step");white()
    end

    local file_list = manifest.files
    local dep_table = manifest.depends

    if type(file_list) ~= "table" or type(dep_table) ~= "table" or type(dep_table[app]) ~= "table" then
        yellow();println("using fallback uninstall file discovery");white()

        file_list = {
            system = {},
            common = list_files("scada-common"),
            graphics = list_files("graphics"),
            lockbox = list_files("lockbox"),
            [app] = list_files(app)
        }

        local static_system = { "initenv.lua", "startup.lua", "configure.lua", "LICENSE" }
        for i = 1, #static_system do
            if fs.exists(static_system[i]) then
                table.insert(file_list.system, static_system[i])
            end
        end

        dep_table = { [app] = { "system", "common", "graphics", "lockbox" } }
    end

    local deps = dep_table[app]

    table.insert(deps, app)

    -- delete all installed files
    lgray()
    for _, dep in pairs(deps) do
        local files = file_list[dep]
        for _, file in pairs(files) do
            if fs.exists(file) then fs.delete(file);println("deleted "..file) end
        end

        local folder = files[1]
        while true do
            local dir = fs.getDir(folder)
            if dir == "" or dir == ".." then break else folder = dir end
        end

        if fs.isDir(folder) then
            fs.delete(folder)
            println("deleted directory "..folder)
        end
    end

    -- delete log file
    local log_deleted = false
    local settings_file = app..".settings"

    if fs.exists(settings_file) and settings.load(settings_file) then
        local log = settings.get("LogPath")
        if log ~= nil then
            log_deleted = true
            if fs.exists(log) then
                fs.delete(log)
                println("deleted log file "..log)
            end
        end
    end

    if not log_deleted then
        red();println("Failed to delete log file (it may not exist).");lgray()
    end

    if fs.exists(settings_file) then
        fs.delete(settings_file);println("deleted "..settings_file)
    end

    fs.delete("install_manifest.json")
    println("deleted install_manifest.json")

    green();println("Done!")
end

white()
