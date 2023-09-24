
---🟨 `Shared`
---
---Splits a string with a separator
---@param str string to split
---@param sep? string one character (Default: ":")
---@return string[] splited
function Modularity.split_str(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

---🟨 `Shared`
---
---Splits a string into equals sized strings, except the last chunk in case it doesn't fit
---@param text string
---@param chunkSize integer
---@return string[] splited
function Modularity.split_strByChunk(text, chunkSize)
    local s = {}
    local _i = 1
    for i=1, #text, chunkSize do
        s[_i] = text:sub(i,i+chunkSize - 1)
        _i = _i + 1
    end
    return s
end

---🟨 `Shared`
---
---Gets the package name of the given _ENV
---@param env table _ENV
---@return string|nil package name
function Modularity.GetPackageNameFromENV(env)
    if (env.Package and env.Package.GetName and env.Package.GetCompatibilityVersion) then
        if env.Package_I then
            local compat = env.Package.GetCompatibilityVersion()
            --print("compat", compat)
            local compat_v_split = Modularity.split_str(compat, ".")
            if (compat == "" or not compat) then
                --print("GETPATH", env.Package.GetPath())
                return env.Package.GetPath()
            elseif ((tonumber(compat_v_split[1]) == 1 and tonumber(compat_v_split[2]) >= 49) or tonumber(compat_v_split[1]) > 1) then
                --print("GETNAME", env.Package.GetName())
                return env.Package.GetName()
            else
                --print("GETPATH", env.Package.GetPath())
                return env.Package.GetPath()
            end
        end
    else
        error("Something missing in this _ENV (Modularity.GetPackageNameFromENV)")
    end
end

---🟨 `Shared`
---
---Returns the string before the first slash (in order to get the package name from the debug info source)
---@param source string
---@return string|nil
function Modularity.GetStringBeforeFirstSlash(source)
    if source then
        local split_slashes = Modularity.split_str(source, "/")
        if (split_slashes and split_slashes[1]) then
            return split_slashes[1]
        end
    end
end

---🟨 `Shared`
---
---Tries to get the package _ENV and name using upvalue method
---@param func function
---@return table|nil _ENV
---@return string|nil package_name
function Modularity.GetFunction_ENV_upvalue(func)
    if (func and type(func) == "function") then
        local i = 1
        local name, value = debug.getupvalue(func, i) -- _ENV is at the first index in upvalues, when it is used in the func, well not for load() sometimes
        while (name ~= nil and name ~= "_ENV") do
            name, value = debug.getupvalue(func, i)
            i = i + 1
        end
        if name == "_ENV" then
            if (debug.getregistry().environments and debug.getregistry().environments[value]) then
                return value, Modularity.GetPackageNameFromENV(value)
            else
                Console.Error("_ENV found but not in environments in Modularity." .. debug.getinfo(1, "n").name)
            end
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

---🟨 `Shared`
---
---Tries to get the package name from function debug info
---@param func function|integer debug.getinfo first parameter
---@return string|nil package_name
function Modularity.GetFunctionPackageName_info(func)
    if (func and (type(func) == "function" or (type(func) == "number" and func % 1 == 0))) then
        local info = debug.getinfo(func, "S")
        if (info and info.source and type(info.source) == "string" and info.source ~= "") then
            return Modularity.GetStringBeforeFirstSlash(info.source)
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

---🟨 `Shared`
---
---Forces the copy of a table (Use that to print nanos classes tables), doesn't copy deeper tables.
---@param to_parse table
---@return table copied
function Modularity.ForceDump(to_parse)
    local copy_tbl = {}
    local k, v = next(to_parse)
    while k ~= nil do
        copy_tbl[k] = v
        k, v = next(to_parse, k)
    end
    return copy_tbl
end

---🟨 `Shared`
---
---Returns the real table containing all nanos instances (Even internal classes), do not loop on it to destroy stuff inside, make a copy beforehand <br>
---In Θ(1)
---@return table all_instances
function Modularity.GetAllEntities()
    return debug.getregistry().userdata
end

---🟨 `Shared`
---
---Tries to crash the server/game
function Modularity.Crash()
    for k, v in pairs(debug.getregistry().classes) do
        if v.__gc then
            v.__gc()
        end
    end
end

---🟨 `Shared`
---
---Returns the table number of fields
---@param tbl table
---@return integer|nil count
function Modularity.table_count(tbl)
    if (tbl and type(tbl) == "table") then
        local count = 0
        for k, v in pairs(tbl) do count = count + 1 end
        return count
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

---🟨 `Shared`
---
---Return the last valid integer index of the table
---@param tbl table
---@return integer|nil last_index
function Modularity.table_last_count(tbl)
    if (tbl and type(tbl) == "table") then
        local count = 0
        for i, v in ipairs(tbl) do count = count + 1 end
        return count
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end


CallsTreeCount = 0

function _ModularityLogEntryErrorWatcher(text, type)
    if type == LogType.Error then
        --[[for k, v in pairs(Modularity.CallsTreeInProgress) do
            if v then
                if v.func then
                    Modularity.UnHook(v.func, _EndHookCallsTree)
                end
            end
        end]]--
        Modularity.CallsTreeInProgress = {}
        Console.Unsubscribe("LogEntry", _ModularityLogEntryErrorWatcher)

        CallsTreeCount = 0

        Console.Warn("Error occured, cleaned CallsTreeInProgress")
    end
end

local function _ModularityEndLastCallsTree()
    if CallsTreeCount > 0 then
        local returned = Modularity.CallsTreeInProgress[CallsTreeCount]
        table.remove(Modularity.CallsTreeInProgress, CallsTreeCount)
        CallsTreeCount = CallsTreeCount - 1
        if CallsTreeCount <= 0 then
            Console.Unsubscribe("LogEntry", _ModularityLogEntryErrorWatcher)
        end
        return returned
    end
end

function _EndHookCallsTree()
    local returned = _ModularityEndLastCallsTree()
    --print("_EndHookCallsTree", returned)
    if returned then
        --Modularity.UnHook(returned.func, _EndHookCallsTree)
        Modularity.CallEvent("CallsTreeFromNowReturn", returned.func, returned.returned)
    end
end

---🟨 `Shared`
---
---Used to make a callsTree when the function call already started (should be used inside a PreHook of the targetted function) will call CallsTreeFromNowReturn event later
---@param func function
---@param show_args? boolean @(Default: nil)
---@param max_depth? integer @(Default: nil)
function Modularity.CallsTreeFromNow(func, show_args, max_depth)
    --print("CallsTreeCount", CallsTreeCount)
    CallsTreeCount = CallsTreeCount + 1
    Modularity.CallsTreeInProgress[CallsTreeCount] = {func=func, show_args=show_args,max_depth=max_depth, backfunc=_EndHookCallsTree, returned={
        tree = {},
        tailcalls = {},
    }}
    --Modularity.EndHook(func, _EndHookCallsTree, Modularity.Enums.EndHookParams.NoParams)
    if CallsTreeCount == 1 then
        Console.Subscribe("LogEntry", _ModularityLogEntryErrorWatcher)
    end
end

---🟨 `Shared`
---
---Makes a CallsTree, can be used to unwrap functions or to look at what really happens when something is called or to get some special functions references.
---@param func function
---@param show_args? boolean @(Default: nil)
---@param max_depth? any @(Default: nil)
---@param ... any additional_params
---@return table|nil CallsTree
function Modularity.CallsTree(func, show_args, max_depth, ...)
    CallsTreeCount = CallsTreeCount + 1
    Modularity.CallsTreeInProgress[CallsTreeCount] = {func=func, show_args=show_args, max_depth=max_depth, returned={
        tree = {},
        tailcalls = {},
    }}
    --Modularity.EnablePrintDebugInfo(true, true)
    if CallsTreeCount == 1 then
        Console.Subscribe("LogEntry", _ModularityLogEntryErrorWatcher)
    end
    func(...)
    --Modularity.EnablePrintDebugInfo(false)
    local returned = _ModularityEndLastCallsTree()
    if returned then
        return returned.returned
    end
end

local function _ModularityCompareTablesInternal(t1, t2, ignored_fields, seen, key, level)
    level = level or (-1)
    level = level + 1
    ignored_fields = ignored_fields or {}
    seen = seen or {
        left = {},
        right = {},
    }

    if (type(t1) ~= type(t2)) then
        return false
    end
    if t1 == t2 then
        return true
    end

    if seen.left[t1] then
        if seen.right[t2] then
            for i, v in pairs(seen.left[t1]) do
                if v ~= seen.right[t2][i] then
                    return false
                end
            end
            return true
        end
        return false
    elseif seen.right[t2] then
        return false
    end

    seen.left[t1] = {key, level}
    seen.right[t2] = {key, level}

    local count = 0
    for k, v in pairs(t1) do
        if not ignored_fields[k] then
            if type(v) ~= type(t2[k]) then
                return false
            end
            if (t2[k] ~= v and type(v) ~= "table") then
                return false
            elseif (type(v) == "table") then
                local ret = _ModularityCompareTablesInternal(v, t2[k], ignored_fields, seen, k, level)
                if not ret then
                    return false
                end
            end
            count = count + 1
        end
    end
    local count_t2 = 0
    for k, v in pairs(t2) do
        if not ignored_fields[k] then
            count_t2 = count_t2 + 1
        end
    end
    return count == count_t2
end

---🟨 `Shared`
---
---Compares 2 tables to check if they are equal by looking at all keys, do not look metatables and doesn't perform the comparing for keys that are tables
---@param t1 table
---@param t2 table
---@param ignored_fields? table<string, true> @(Default: {})
---@return boolean is_equal
function Modularity.CompareTables(t1, t2, ignored_fields)
    return _ModularityCompareTablesInternal(t1, t2, ignored_fields)
end

---🟨 `Shared`
---
---Gets which package name called this function
---@param level integer Usually 3
---@return string|nil package_name
function Modularity.GetCallingPackageName(level)
    local info = debug.getinfo(level, "S")
    if info then
        local p_name = Modularity.GetStringBeforeFirstSlash(info.source)
        if (p_name and (not (string.find(p_name, "INTERNAL")))) then
            return p_name
        end
    end
end

---🟨 `Shared`
---
---Gets the current side where the script is running
---@return string side so _ENV[side] is valid on your side
function Modularity.GetSide()
    if Server then
        return "Server"
    else
        return "Client"
    end
end

---🟨 `Shared`
---
---Dumps keys of the table in a list (Doesn't copy keys that are table)
---@param t table
---@return any[] keys
function Modularity.DumpKeys(t)
    local keys = {}
    local c = 0
    for k, v in pairs(t) do
        c = c + 1
        keys[c] = k
    end
    return keys
end

---🟨 `Shared`
---
---If the tostring of t shows an address, get that address as a string, can be used for custom visuals on a custom tostring, see MGroup for an example use case.
---@param t any
---@return string|nil address
function Modularity.GetAddress(t)
    local t_tostring = tostring(t)
    if t_tostring then
        local split_t_tostring = Modularity.split_str(t_tostring, ":")
        if split_t_tostring[2] then
            local address_start = 1
            for i = 1, string.len(split_t_tostring[2]) do
                if (string.sub(split_t_tostring[2], i, i) ~= " ") then
                    address_start = i
                    break
                end
            end
            return string.sub(split_t_tostring[2], address_start)
        end
    end
end

---🟨 `Shared`
---
---Returns whether the table is empty or not in Θ(1)
---@param t table
---@return boolean empty
function Modularity.IsTableEmpty(t)
    local k, _ = next(t)
    return k == nil
end



local StartedLoadingFiles = {}


local function _ExploreFolderLoadFilesIntoTable(new_files_tbl, folder, into_tbl, directory)
    --print("_ExploreFolderLoadFilesIntoTable", new_files_tbl, folder, into_tbl, directory)
    for k, v in pairs(new_files_tbl) do
        if not v.async_start then
            if Modularity.table_count(v.split_slashes) == 1 then -- File
                if string.sub(v.str, 1, 1) == "/" then
                    v.str = string.sub(v.str, 2)
                end
                local file = File(directory .. v.str, false)
                if (file and file:IsGood()) then
                    new_files_tbl[k].async_start = true
                    file:ReadAsync(0, function(file_content)
                        into_tbl[v.split_slashes[1]] = file_content
                        new_files_tbl[k] = nil
                        file:Close()

                        if Modularity.IsTableEmpty(new_files_tbl) then
                            for _, callback in ipairs(StartedLoadingFiles[directory].callbacks) do
                                callback(StartedLoadingFiles[directory].returned)
                            end
                            StartedLoadingFiles[directory] = nil
                        end
                    end)
                else
                    new_files_tbl[k] = nil
                end
            else
                local new_sub_folder = v.split_slashes[1]
                if not into_tbl[new_sub_folder] then
                    into_tbl[new_sub_folder] = {}

                    local new_full_folder = folder .. "/" .. new_sub_folder

                    local full_sub_from_directory = string.sub(new_full_folder, string.len(directory))
                    for k2, v2 in pairs(new_files_tbl) do
                        if not v2.async_start then
                            if (string.sub(v2.str, 1, string.len(full_sub_from_directory)) == full_sub_from_directory) then
                                table.remove(new_files_tbl[k2].split_slashes, 1)
                                --print(NanosTable.Dump(new_files_tbl[k2].split_slashes))
                            end
                        end
                    end
                    _ExploreFolderLoadFilesIntoTable(new_files_tbl, new_full_folder, into_tbl[new_sub_folder], directory)
                end
            end
        end
    end
end


-- UNTESTED
---🟨 `Shared`
---
---Loads all files in a directory and also sub directories, into a table respecting the files structure on the system. <br>
---Will call callback once finished with the table.
---@param directory string
---@param callback function
---@return boolean started
function Modularity.LoadFilesInTableAsync(directory, callback)

    if (type(directory) == "string" and type(callback) == "function") then
        local dir_str_len = string.len(directory)
        local last_dir_char = string.sub(directory, dir_str_len, dir_str_len)

        if last_dir_char ~= "/" then
            directory = directory .. "/"
            dir_str_len = dir_str_len + 1
        end

        if File.Exists(directory) then
            if not StartedLoadingFiles[directory] then
                StartedLoadingFiles[directory] = {
                    returned = {},
                    callbacks = {callback},
                }
                local files = File.GetFiles(directory)
                --print(NanosTable.Dump(files))

                local new_files_tbl = {}

                for k, v in pairs(files) do
                    new_files_tbl[k] = {
                        str = string.sub(v, dir_str_len),
                    }
                    new_files_tbl[k].split_slashes = Modularity.split_str(new_files_tbl[k].str, "/")
                end

                _ExploreFolderLoadFilesIntoTable(new_files_tbl, string.sub(directory, 1, dir_str_len-1), StartedLoadingFiles[directory].returned, directory)

            else
                table.insert(StartedLoadingFiles[directory].callbacks, callback)
            end

            return true
        end
    else
        error("Wrong arguments")
    end
    return false
end


-- UNTESTED
---🟨 `Shared`
---
---Creates a new table containing all keys from given tables. With higher priority for the last tables.
---@param ... table constructors
---@return table joined_keys_table
function Modularity.JoinTables(...)
    local new_tbl = {}
    local tbls = table.pack(...)
    for i = 1, tbls.n do
        if type(tbls[i]) == "table" then
            for k, v in pairs(tbls[i]) do
                new_tbl[k] = v
            end
        end
    end
    return new_tbl
end