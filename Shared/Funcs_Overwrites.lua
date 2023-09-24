
---🟨 `Shared`
---
---Get a function that was set/overwritten by Modularity Overwrite/Set functions
---@param func function
---@return any old_func
function Modularity.GetOverwrittenDefaultFunction(func)
    if (func and type(func) == "function") then
        return Modularity.OverwrittenDefaultFunctions[func]
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

---🟨 `Shared`
---
---Overwrites a global function in a package _ENV, 
---@param package_name string
---@param func_key any
---@param called_func any
---@return function|nil old_func
function Modularity.OverwritePackageFunction(package_name, func_key, called_func)
    if (package_name and func_key and called_func and type(package_name) == "string" and type(func_key) == "string" and type(called_func) == "function") then
        --Modularity.RefreshRegistryEnvs()
        --print("OverwritePackageFunction HERE")
        if Modularity.Envs[package_name] then
            --print("OverwritePackageFunction HERE2")
            if (Modularity.Envs[package_name][func_key] and type(Modularity.Envs[package_name][func_key]) == "function") then
                --local func = Modularity.Envs[package_name][func_key]
                --local function _ModularityPackageFWrapper(...)
                    --local args = {...}
                    --local tab_ret = {func(...)}
                    --return called_func(args, tab_ret)
                --end
                --print("OverwritePackageFunction")
                Modularity.OverwrittenDefaultFunctions[called_func] = Modularity.Envs[package_name][func_key]
                Modularity.Envs[package_name][func_key] = called_func
                return Modularity.OverwrittenDefaultFunctions[called_func]
            end
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

---🟨 `Shared`
---
---Overwrites a native event callback, the old one still has to be used to Unsubscribe
---@param event_func function
---@param called_func function
---@return function|nil old_func
function Modularity.OverwriteEventFunction(event_func, called_func)
    if (event_func and called_func and type(event_func) == "function" and type(called_func) == "function") then
        for k, v in pairs(debug.getregistry()) do
            if (type(v) == "function" and type(k) == "number") then
                if event_func == v then
                    --print("MATCH IN REG")
                    local info = debug.getinfo(v, "S")
                    local split_spaces = Modularity.split_str(info.source, " ")
                    if (info.what == "Lua" and split_spaces[1] ~= "INTERNAL") then
                        local p_name = Modularity.GetFunctionPackageName_info(event_func)

                        if (p_name ~= Package.GetName()) then
                            Modularity.OverwrittenDefaultFunctions[called_func] = debug.getregistry()[k]
                            debug.getregistry()[k] = called_func
                            return Modularity.OverwrittenDefaultFunctions[called_func]
                        else
                            error("Cannot overwrite Event function (Don't overwrite a Modularity event function ?)")
                        end
                    end
                end
            end
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

---🟨 `Shared`
---
---Sets a function on a nanos class or inherited class
---@param classname string
---@param func_name string
---@param called_func function
---@return function|nil old_func
function Modularity.SetEntityClassFunction(classname, func_name, called_func)
    if (classname and func_name and called_func and type(classname) == "string" and type(func_name) == "string" and type(called_func) == "function") then
        local v = _G[classname]
        if v then
            local meta = getmetatable(v)
            if (meta and meta.__call) then -- Does the class can be instanced
                local functions_table = v.__function
                if not functions_table then -- Handle Inherited Classes
                    if v.GetParentClass then
                        functions_table = v
                    end
                end
                if (functions_table) then
                    --print("Modularity.SetEntityClassFunction")
                    Modularity.OverwrittenDefaultFunctions[called_func] = functions_table[func_name]
                    functions_table[func_name] = called_func
                    return Modularity.OverwrittenDefaultFunctions[called_func]
                end
            end
        else
            error("Cannot find the class")
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end
Modularity.AddClassDeprecatedKey(Modularity, "OverwriteEntityClassFunction", Modularity.SetEntityClassFunction, "SetEntityClassFunction")