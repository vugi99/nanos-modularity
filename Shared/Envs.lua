
---🟨 `Shared`
---
---Checks if an environment table is valid (fully loaded and not destroyed)
---@param env table
---@return boolean|nil is_valid
function Modularity.IsENVValid(env)
    if (env and env.Package_I) then
        local p_i_s = tostring(env.Package_I)
        -- TODO: Maybe check for the destroyed metatable instead ?
        if not (string.sub(p_i_s, 1, 9) == "Destroyed") then -- Dang parenthesis were really needed here...
            return true
        end
    end
end

---🟨 `Shared`
---
---Refresh the Modularity.Envs table with the new environments and removes the destroyed ones
function Modularity.RefreshRegistryEnvs()
    if debug.getregistry().environments then
        Modularity.Envs = {}
        for k, v in pairs(debug.getregistry().environments) do
            if Modularity.IsENVValid(k) then
                Modularity.Envs[Modularity.GetPackageNameFromENV(k)] = k
            else
                --error("_ENV doesn't contain Package_I")
            end
        end
    end
end
Modularity.RefreshRegistryEnvs()
Package.Subscribe("Load", function()
    Modularity.RefreshRegistryEnvs()
end)

---🟨 `Shared`
---
---Gets a value in a package environment
---@param package_name string
---@param variable_key any
---@return any value
function Modularity.GetENVValue(package_name, variable_key)
    if (package_name and type(package_name) == "string" and variable_key and type(variable_key) == "string") then
        if Modularity.Envs[package_name] then
            --print(Modularity.Envs[package_name][variable_name])
            --print(NanosTable.Dump(Modularity.Envs[package_name]))
            return Modularity.Envs[package_name][variable_key]
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

---🟨 `Shared`
---
---Sets a value in a package environment
---@param package_name string
---@param variable_key any
---@param value any
---@return boolean|nil success
function Modularity.SetENVValue(package_name, variable_key, value)
    if (package_name and type(package_name) == "string" and variable_key and type(variable_key) == "string") then
        if Modularity.Envs[package_name] then
            Modularity.Envs[package_name][variable_key] = value
            return true
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end


local function _Modularity_Cleanup_Package_Unload(p_name) -- Modularity own garbage collection ::
    --Console.Warn("Modularity Cleanup " .. p_name)
    Modularity.PackagesNotFullEvents[p_name] = nil
    Modularity.Envs[p_name] = nil

    for i, v in ipairs(Modularity.GetHooksTables()) do
        v[p_name] = nil
    end

    Modularity.RemoveEventsOfPackage(p_name)
    Modularity.DebugHooks[p_name] = nil
    for class, v in pairs(Modularity.AttachedEventSystems) do
        v[p_name] = nil
    end

    for i = 1, _Mod_LastCL_index do
        if Modularity.ClassLinks[i] then
            if Modularity.ClassLinks[i].p_name == p_name then
                Modularity.ClassLinks[i] = nil
                if Modularity.GlobalSubscribesClasslinks[i] then
                    Modularity.GlobalSubscribesClasslinks[i] = nil
                end

                for classname, v in pairs(Modularity.NativeCallsCompression) do
                    for call_func_name, v2 in pairs(v) do
                        for event_name, v3 in pairs(v2) do
                            local _wi = 1
                            while v3.class_links[_wi] do
                                if v3.class_links[_wi] == i then
                                    table.remove(v3.class_links, _wi)
                                    --print("Compression Removed Classlink")
                                else
                                    _wi = _wi + 1
                                end
                            end
                            if _wi == 1 then
                                Modularity.UnHook(_G[classname][call_func_name], v3.hook_func)
                                Modularity.NativeCallsCompression[classname][call_func_name][event_name] = nil
                            end
                        end
                    end
                end
            end
        end
    end

    _Modularity_ReBuildFunctionsThatAreHooked()

    Modularity.PackagesConsoleAliases[p_name] = nil
end


local function _Modularity_ENV_SubGlobalPackageUnload(k)
    if Modularity.IsENVValid(k) then
        local p_name = Modularity.GetPackageNameFromENV(k)
        if ((not Modularity.Packages_Unload_Callbacks[p_name]) and (p_name ~= Package.GetName())) then
            --print("Modularity.Packages_Unload_Callbacks[p_name] set", p_name)
            Modularity.Packages_Unload_Callbacks[p_name] = k.Package.Subscribe("Unload", function()
                Modularity.CallEvent("PackageUnload", p_name)
                Modularity.Packages_Unload_Callbacks[p_name] = nil
                _Modularity_Cleanup_Package_Unload(p_name)
            end)
        end
    end
end


Package.Subscribe("Load", function()
    for k, v in pairs(debug.getregistry().environments) do
        _Modularity_ENV_SubGlobalPackageUnload(k)
    end
end)




local _debug_envs_default_newindex = debug.getregistry().environments.__newindex
if (not _debug_envs_default_newindex) then
    _debug_envs_default_newindex = function(t, key, value)
        return rawset(t, key, value)
    end
end

local _debug_envs_meta = {
    __newindex = function(t, k, v, ...)
        --Console.Warn("__newindex", t, k, v)

        if (type(k) == "table" and v) then
            --print("Modularity NEW _ENV", k, v)
            Timer.SetTimeout(function()
                if Modularity.IsENVValid(k) then
                    local p_name = Modularity.GetPackageNameFromENV(k)
                    Modularity.Envs[p_name] = k
                    _Modularity_ENV_SubGlobalPackageUnload(k)
                    Modularity.CallEvent("PackageLoad", p_name)
                end
            end, 1)
        end
        return _debug_envs_default_newindex(t, k, v, ...)
    end,
}
setmetatable(debug.getregistry().environments, _debug_envs_meta)

--[[
Modularity.Subscribe("PackageLoad", function(p_name)
    Console.Warn("PackageLoad " .. p_name)
end)

Modularity.Subscribe("PackageUnload", function(p_name)
    Console.Warn("PackageUnload " .. p_name)
end)]]--

---🟨 `Shared`
---
---Gets the environment given the package name
---@param p_name string
---@return table|nil _ENV
function Modularity.GetENVFromPName(p_name)
    local env
    if Modularity.Envs[p_name] then
        if Modularity.IsENVValid(Modularity.Envs[p_name]) then
            env = Modularity.Envs[p_name]
        end
    end
    if not env then
        Modularity.RefreshRegistryEnvs()
        if Modularity.Envs[p_name] then
            if Modularity.IsENVValid(Modularity.Envs[p_name]) then
                env = Modularity.Envs[p_name]
            end
        end
    end
    return env
end