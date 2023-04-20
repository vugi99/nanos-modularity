
if not debug.getregistry().environments then
    Console.Error("Modularity : missing registry environments, some stuff won't work")
end

Package.Export("Modularity", {
    Enums = {},

    Envs = {},
    PreHooks = {},
    EndHooks = {},
    PreHooksName = {},
    EndHooksName = {},

    PackagesSubscribeFuncs = {},
    PackagesSubscribeRemoteFuncs = {},

    PackagesNotFullEvents = {},

    OverwrittenDefaultFunctions = {},
})

local function _Modularitysplit_str(str,sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    --print(str)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end


function _Modularity_GetPackageName(env)
    if (env.Package and env.Package.GetName and env.Package.GetCompatibilityVersion) then
        local compat = env.Package.GetCompatibilityVersion()
        local compat_v_split = _Modularitysplit_str(compat, ".")
        if (compat == "" or not compat) then
            --print("GETPATH")
            return env.Package.GetPath()
        elseif ((tonumber(compat_v_split[1]) == 1 and tonumber(compat_v_split[2]) >= 49) or tonumber(compat_v_split[1]) > 1) then
            --print("GETNAME")
            return env.Package.GetName()
        else
            --print("GETPATH")
            return env.Package.GetPath()
        end
    else
        error("Something missing in this _ENV (_Modularity_GetPackageName)")
    end
end

-- This is so funny that this works to know which packages loaded before while [].GetPackages returns unwanted stuff there
if debug.getregistry().environments then
    for k, v in pairs(debug.getregistry().environments) do
        if (k and k.Package and k.Package.GetName and k.Package.GetCompatibilityVersion) then
            Modularity.PackagesNotFullEvents[_Modularity_GetPackageName(k)] = true
        end
    end
end

function Modularity.AwareOfAllEvents(package_name)
    --print(NanosTable.Dump(Modularity.PackagesNotFullEvents))
    if (package_name and type(package_name) == "string") then
        local found
        if Server then
            for i, v in ipairs(Server.GetPackages(true)) do
                if v.name == package_name then
                    found = true
                    break
                end
            end
        else
            --print(NanosTable.Dump(Client.GetPackages()))
            for i, v in ipairs(Client.GetPackages()) do
                if v == package_name then
                    found = true
                    break
                end
            end
        end
        if not found then
            --print(package_name, "Not found")
            return false
        end
        return not Modularity.PackagesNotFullEvents[package_name]
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1).name)
    end
end

function Modularity.GetFunction_ENV_upvalue(func)
    if (func and type(func) == "function") then
        local i = 1
        local name, value = debug.getupvalue(func, i)
        while (name ~= nil and name ~= "_ENV") do
            name, value = debug.getupvalue(func, i)
            i = i + 1
        end
        if name == "_ENV" then
            if (debug.getregistry().environments and debug.getregistry().environments[value]) then
                return value, _Modularity_GetPackageName(value)
            end
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1).name)
    end
end

local function _ModularityProcessInfoSourceForPName(source)
    local split_slashes = _Modularitysplit_str(source, "/")
    if (split_slashes and split_slashes[1]) then
        return split_slashes[1]
    end
end

function Modularity.GetFunctionPackageName_info(func)
    if (func and (type(func) == "function" or (type(func) == "number" and func % 1 == 0))) then
        local info = debug.getinfo(func)
        if (info and info.source and type(info.source) == "string" and info.source ~= "") then
            return _ModularityProcessInfoSourceForPName(info.source)
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1).name)
    end
end

local function _ModularitySingleHookCall(alter_args, call_params, call_values, v, params_count)
    --print("_ModularitySingleHookCall", alter_args)
    local modified_params
    if not alter_args then
        v[1](table.unpack(call_values))
    else
        local new_call_values = {v[1](table.unpack(call_values))}
        local last_i = 1
        for i2, v2 in ipairs(new_call_values) do
            call_values[i2] = v2
            call_params[i2].value = v2
            last_i = i2 + 1
        end
        for i2 = last_i, params_count do
            call_values[i2] = v2
            call_params[i2].value = nil
        end
        modified_params = true
    end
    return modified_params
end

local function _ModularityHandleHookCalls(HookTbl, HookType, info, call_params, call_values)
    local params_count = #call_params
    local modified_params = false
    if HookType == "Ref" then
        if HookTbl[info.func] then
            --print(NanosTable.Dump(HookTbl[info.func]))
            for i, v in ipairs(HookTbl[info.func]) do
                local m_p = _ModularitySingleHookCall(v[2], call_params, call_values, v, params_count)
                modified_params = modified_params or m_p
            end
        end
    elseif HookType == "Name" then
        if HookTbl[info.name] then
            for i2, v in ipairs(HookTbl[info.name]) do
                if v[2] then
                    local p_name = Modularity.GetFunctionPackageName_info(info.func)
                    if p_name == v[2] then
                        local m_p = _ModularitySingleHookCall(v[3], call_params, call_values, v, params_count)
                        modified_params = modified_params or m_p
                    end
                else
                    local m_p = _ModularitySingleHookCall(v[3], call_params, call_values, v, params_count)
                    modified_params = modified_params or m_p
                end
            end
        end
    end
    if modified_params then
        for i, v in ipairs(call_params) do
            local name, value = debug.getlocal(3, v.local_index)
            if name == v.name then
                debug.setlocal(3, v.local_index, v.value)
            else
                Console.Error("Modularity : Name Check Failed when altering args")
            end
        end
    end
end

local function _Modularity_GetCallArguments_While(mult, call_params, call_values)
    local i = 1
    local name, value = "true", nil
    while name do
        name, value = debug.getlocal(3, mult*i)
        if name then
            table.insert(call_params, {name = name, value = value, local_index = mult*i})
            table.insert(call_values, value)
        end
        i = i + 1
    end
end

local function _Modularity_GetCallArguments_For(info, call_params, call_values)
    for i = 1, info.nparams do
        local name, value = debug.getlocal(3, i)
        table.insert(call_params, {name = name, value = value, local_index = i})
        table.insert(call_values, value)
    end
end

debug.sethook(function(call_type)
    -- TODO: Less checks before entering main logic for performance

    local info = debug.getinfo(2)

    if info then

        --[[if (_ModularityProcessInfoSourceForPName(info.source) ~= Package.GetName() and call_type ~= "return" and info.name ~= "for iterator" and info.name ~= "Log" and info.name ~= "tonumber" and info.name ~= "tostring" and info.source ~= "Lua Default Library" and not (string.find(info.source, "INTERNAL"))) then
            print(NanosTable.Dump(info))
        end]]--
        if (Modularity.PreHooks[info.func] or Modularity.EndHooks[info.func] or Modularity.PreHooksName[info.name] or Modularity.EndHooksName[info.name]) then
            local call_params = {}

            local call_values = {}

            if info.isvararg then
                if info.source == "=[C]" then
                    _Modularity_GetCallArguments_While(1, call_params, call_values) -- To catch some internal arguments from internal calls, needed for Subscribe / other game classes
                else
                    _Modularity_GetCallArguments_For(info, call_params, call_values)
                end
                _Modularity_GetCallArguments_While(-1, call_params, call_values)
            else
                _Modularity_GetCallArguments_For(info, call_params, call_values)
            end

            --print(NanosTable.Dump(call_params))
            if call_type ~= "return" then
                --[[if info.name == "Subscribe" then
                    print("Sub Call", NanosTable.Dump(call_values))
                end]]--
                _ModularityHandleHookCalls(Modularity.PreHooks, "Ref", info, call_params, call_values)
                _ModularityHandleHookCalls(Modularity.PreHooksName, "Name", info, call_params, call_values)
            else
                _ModularityHandleHookCalls(Modularity.EndHooks, "Ref", info, call_params, call_values)
                _ModularityHandleHookCalls(Modularity.EndHooksName, "Name", info, call_params, call_values)
            end
        end
    end

    --print("____________________")
end, "cr") -- Hook pre calls and return (right before return)
debug.sethook = function() end


function Modularity.RefreshRegistryEnvs()
    if debug.getregistry().environments then
        Modularity.Envs = {}
        for k, v in pairs(debug.getregistry().environments) do
            if k.Package_I then
                local p_i_s = tostring(k.Package_I)
                if not (string.sub(p_i_s, 1, 9) == "Destroyed") then -- Dang parenthesis were really needed here...
                    --print("Added")
                    Modularity.Envs[_Modularity_GetPackageName(k)] = k
                end
            else
                error("Modularity : _ENV doesn't contain Package_I")
            end
        end
    end
end
Modularity.RefreshRegistryEnvs()
Package.Subscribe("Load", function()
    Modularity.RefreshRegistryEnvs()
end)


local function _RefHook(tbl, func, called_func, alter_args)
    if (func and called_func and type(func) == "function" and type(called_func) == "function" and func ~= _ModularityHandleHookCalls and func ~= _ModularitySingleHookCall and func ~= called_func) then
        if not tbl[func] then
            tbl[func] = {}
        end
        table.insert(tbl[func], {called_func, alter_args})
        return true
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(2).name)
    end
end

function Modularity.PreHook(func, called_func, alter_args)
    return _RefHook(Modularity.PreHooks, func, called_func, alter_args)
end

function Modularity.EndHook(func, called_func)
    return _RefHook(Modularity.EndHooks, func, called_func)
end


local function _NameHook(tbl, func_name, called_func, package_name, alter_args)
    if (func_name and called_func and type(func_name) == "string" and type(called_func) == "function" and func_name ~= "_ModularityHandleHookCalls" and func_name ~= "_ModularitySingleHookCall") then
        if not tbl[func_name] then
            tbl[func_name] = {}
        end
        table.insert(tbl[func_name], {called_func, package_name, alter_args})
        return true
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(2).name)
    end
end

function Modularity.PreHookName(func_name, called_func, package_name, alter_args)
    return _NameHook(Modularity.PreHooksName, func_name, called_func, package_name, alter_args)
end

function Modularity.EndHookName(func_name, called_func, package_name)
    return _NameHook(Modularity.EndHooksName, func_name, called_func, package_name)
end


function Modularity.GetENVValue(package_name, variable_name)
    if (package_name and type(package_name) == "string" and variable_name and type(variable_name) == "string") then
        if Modularity.Envs[package_name] then
            return Modularity.Envs[package_name][variable_name]
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1).name)
    end
end

function Modularity.SetENVValue(package_name, variable_name, value)
    if (package_name and type(package_name) == "string" and variable_name and type(variable_name) == "string") then
        if Modularity.Envs[package_name] then
            Modularity.Envs[package_name][variable_name] = value
            return true
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1).name)
    end
end


function Modularity.GetOverwrittenDefaultFunction(func)
    if (func and type(func) == "function") then
        return Modularity.OverwrittenDefaultFunctions[func]
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1).name)
    end
end

-- TODO: Deep dive mode : replace all references of that function
function Modularity.OverwritePackageFunction(package_name, func_name, called_func) -- Can not work for all calls if the reference is stored somewhere else
    if (package_name and func_name and called_func and type(package_name) == "string" and type(func_name) == "string" and type(called_func) == "function") then
        Modularity.RefreshRegistryEnvs()
        --print("OverwritePackageFunction HERE")
        if Modularity.Envs[package_name] then
            --print("OverwritePackageFunction HERE2")
            if (Modularity.Envs[package_name][func_name] and type(Modularity.Envs[package_name][func_name]) == "function") then
                --local func = Modularity.Envs[package_name][func_name]
                --local function _ModularityPackageFWrapper(...)
                    --local args = {...}
                    --local tab_ret = {func(...)}
                    --return called_func(args, tab_ret)
                --end
                --print("OverwritePackageFunction")
                Modularity.OverwrittenDefaultFunctions[called_func] = Modularity.Envs[package_name][func_name]
                Modularity.Envs[package_name][func_name] = called_func
                return Modularity.OverwrittenDefaultFunctions[called_func]
            end
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1).name)
    end
end

function Modularity.OverwriteEventFunction(event_func, called_func)
    if (event_func and called_func and type(event_func) == "function" and type(called_func) == "function") then
        for k, v in pairs(debug.getregistry()) do
            if (type(v) == "function" and type(k) == "number") then
                if event_func == v then
                    --print("MATCH IN REG")
                    local info = debug.getinfo(v)
                    local split_spaces = _Modularitysplit_str(info.source, " ")
                    if (info.what == "Lua" and split_spaces[1] ~= "INTERNAL") then
                        local p_name = Modularity.GetFunctionPackageName_info(v)
                        if (p_name ~= Package.GetName()) then
                            Modularity.OverwrittenDefaultFunctions[called_func] = debug.getregistry()[k]
                            debug.getregistry()[k] = called_func
                            return Modularity.OverwrittenDefaultFunctions[called_func]
                        else
                            error("Don't overwrite a Modularity event function")
                        end
                    end
                end
            end
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1).name)
    end
end

function Modularity.OverwriteEntityClassFunction(classname, func_name, called_func)
    if (classname and func_name and called_func and type(classname) == "string" and type(func_name) == "string" and type(called_func) == "function") then
        for k, v in pairs(debug.getregistry().classes) do
            local meta = getmetatable(v)
            if (meta and meta.__call) then -- Does the class can be instanced
                if v.__name == classname then
                    if (v.__function and v.__function[func_name]) then
                        --print("Modularity.OverwriteEntityClassFunction")
                        Modularity.OverwrittenDefaultFunctions[called_func] = debug.getregistry().classes[k].__function[func_name]
                        debug.getregistry().classes[k].__function[func_name] = called_func
                        return Modularity.OverwrittenDefaultFunctions[called_func]
                    end
                end
            end
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1).name)
    end
end

function Modularity.GetALLEventsFunctions(package_name)
    local tbl = {}

    for k, v in pairs(debug.getregistry()) do
        if (type(v) == "function" and type(k) == "number") then
            local info = debug.getinfo(v)
            local split_spaces = _Modularitysplit_str(info.source, " ")
            if (info.what == "Lua" and split_spaces[1] ~= "INTERNAL") then
                local p_name = Modularity.GetFunctionPackageName_info(v)
                if (not package_name or p_name == package_name) then
                    tbl[k] = info
                end
            end
        end
    end

    return tbl
end

local function _ModularityRegisterNewSubscribe(classname, event_name, p_name, func, storing_tbl, ent)
    if (classname and event_name and func) then
        if (type(classname) == "string" and type(event_name) == "string" and type(func) == "function") then
            if not storing_tbl[classname] then
                storing_tbl[classname] = {}
            end
            if not storing_tbl[classname][p_name] then
                storing_tbl[classname][p_name] = {}
            end
            if not storing_tbl[classname][p_name][event_name] then
                storing_tbl[classname][p_name][event_name] = {}
            end
            if ent then
                if not storing_tbl[classname][p_name][event_name][ent] then
                    storing_tbl[classname][p_name][event_name][ent] = {}
                end
                storing_tbl[classname][p_name][event_name][ent][func] = true
                if ent.Subscribe then
                    ent:Subscribe("Destroy", function()
                        if (storing_tbl[classname] and storing_tbl[classname][p_name] and storing_tbl[classname][p_name][event_name]) then
                            if storing_tbl[classname][p_name][event_name][ent] then
                                storing_tbl[classname][p_name][event_name][ent] = nil
                                --print("_ModularityRegisterNewSubscribe CLEANUP DESTROY")
                            end
                        end
                    end)
                end
                --print("_ModularityRegisterNewSubscribe ent", classname, p_name, event_name, ent, func)
            else
                if not storing_tbl[classname][p_name][event_name]["INDEPENDENT_SUBS"] then
                    storing_tbl[classname][p_name][event_name]["INDEPENDENT_SUBS"] = {}
                end
                storing_tbl[classname][p_name][event_name]["INDEPENDENT_SUBS"][func] = true
                --print("_ModularityRegisterNewSubscribe independent", classname, p_name, event_name, func)
            end
        end
    end
end

local function _ModularityUnSubscribe(classname, event_name, p_name, func, _storing_tbls, ent)
    if (classname and event_name) then
        if (type(classname) == "string" and type(event_name) == "string") then
            for i, storing_tbl in ipairs(_storing_tbls) do
                if storing_tbl[classname] then
                    if storing_tbl[classname][p_name] then
                        if storing_tbl[classname][p_name][event_name] then
                            if ent then
                                if storing_tbl[classname][p_name][event_name][ent] then
                                    if func then
                                        storing_tbl[classname][p_name][event_name][ent][func] = nil
                                    else
                                        storing_tbl[classname][p_name][event_name][ent] = nil
                                    end
                                    --print("_ModularityUnSubscribe ent", classname, p_name, event_name, ent, func)
                                end
                            elseif storing_tbl[classname][p_name][event_name]["INDEPENDENT_SUBS"] then
                                if func then
                                    storing_tbl[classname][p_name][event_name]["INDEPENDENT_SUBS"][func] = nil
                                else
                                    storing_tbl[classname][p_name][event_name]["INDEPENDENT_SUBS"] = nil
                                end
                                --print("_ModularityUnSubscribe independent", classname, p_name, event_name, func)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function _ModularityMakeUOrSWrapper(register_func, classname, storing_tbl, WrapperType)
    return function(...)
        local tbl = {...} -- Contains 3 or 4 arguments, the last one is very internal stuff

        -- Using where the sub was called from to know the real package name (other func could come from another)
        local level = 6
        local info = debug.getinfo(level)
        --print(NanosTable.Dump(info))
        while (info ~= nil and (string.find(info.source, "INTERNAL") or info.source == "=[C]")) do
            --print(NanosTable.Dump(info))
            level = level + 1
            info = debug.getinfo(level + 1)
        end
        if (not info and tbl[3] and type(tbl[3]) == "function") then -- Package_S and other fake static classes handling
            local env, t_p_name = Modularity.GetFunction_ENV_upvalue(tbl[3])
            if env then
                info = {source = t_p_name}
            end
        end
        --print(NanosTable.Dump(tbl))
        --print(NanosTable.Dump(info))
        if (tbl[1] and info and not string.find(info.source, "INTERNAL")) then
            local p_name = _ModularityProcessInfoSourceForPName(info.source)
            --print("_ModularityMakeUOrSWrapper", classname, tbl[1], tbl[2], tbl[3], p_name)
            if (p_name and p_name ~= Package.GetName()) then -- Do not allow storing events subscribed in this package to avoid infinite loops
                --print(NanosTable.Dump(info))
                if type(tbl[1]) == "string" then
                    register_func(classname, tbl[1], p_name, tbl[2], storing_tbl)
                elseif (tbl[2] and type(tbl[2]) == "string") then
                    register_func(classname, tbl[2], p_name, tbl[3], storing_tbl, tbl[1])
                end
            end
        end

        --print(WrapperType, #tbl)

        --return default_tbl[classname](...)
    end
end

if debug.getregistry().classes then
    for k, v in pairs(debug.getregistry().classes) do

        local meta = getmetatable(v)
        --print(v.__name, NanosTable.Dump(meta))
        if (meta and meta.__call) then -- Does the class can be instanced
            -- Handling of entity:Subscribe / Package_S and other fake static classes

            --print("OV INSTANCE SUBS", v.__name)

            if v.__function.Subscribe then
                Modularity.PreHook(v.__function.Subscribe, _ModularityMakeUOrSWrapper(_ModularityRegisterNewSubscribe, v.__name, Modularity.PackagesSubscribeFuncs, "Instances"))
                --_MODULARITY_DEFAULT_SUBSCRIBES_INSTANCES[v.__name] = v.__function.Subscribe
                --v.__function.Subscribe = _ModularityMakeUOrSWrapper(_ModularityRegisterNewSubscribe, v.__name, _MODULARITY_DEFAULT_SUBSCRIBES_INSTANCES, Modularity.PackagesSubscribeFuncs, "Instances")
            end
            if v.__function.SubscribeRemote then
                Modularity.PreHook(v.__function.SubscribeRemote, _ModularityMakeUOrSWrapper(_ModularityRegisterNewSubscribe, v.__name, Modularity.PackagesSubscribeRemoteFuncs, "Instances"))
            end
            if v.__function.Unsubscribe then
                Modularity.PreHook(v.__function.Unsubscribe, _ModularityMakeUOrSWrapper(_ModularityUnSubscribe, v.__name, {Modularity.PackagesSubscribeFuncs, Modularity.PackagesSubscribeRemoteFuncs}, "Instances"))
            end
        end

        if _G[v.__name] then
            -- Handling of class.Subscribe

            --print("OV STATIC SUBS", v.__name)

            if _G[v.__name].Subscribe then
                Modularity.PreHook(_G[v.__name].Subscribe, _ModularityMakeUOrSWrapper(_ModularityRegisterNewSubscribe, v.__name, Modularity.PackagesSubscribeFuncs, "Static"))
                --_MODULARITY_DEFAULT_SUBSCRIBES[v.__name] = _G[v.__name].Subscribe
                --_G[v.__name].Subscribe = _ModularityMakeUOrSWrapper(_ModularityRegisterNewSubscribe, v.__name, _MODULARITY_DEFAULT_SUBSCRIBES, Modularity.PackagesSubscribeFuncs, "Static")
            end

            if _G[v.__name].SubscribeRemote then
                Modularity.PreHook(_G[v.__name].SubscribeRemote, _ModularityMakeUOrSWrapper(_ModularityRegisterNewSubscribe, v.__name, Modularity.PackagesSubscribeRemoteFuncs, "Static"))
            end

            if _G[v.__name].Unsubscribe then
                Modularity.PreHook(_G[v.__name].Unsubscribe, _ModularityMakeUOrSWrapper(_ModularityUnSubscribe, v.__name, {Modularity.PackagesSubscribeFuncs, Modularity.PackagesSubscribeRemoteFuncs}, "Static"))
            end
        end
    end
end

--print(Events.Subscribe)

local function _Modularity_CallEvent_WPackageName_WENT(storing_tbl, classname, event_name, p_name, ent, ...)
    for k, v in pairs(storing_tbl[classname][p_name][event_name][ent]) do
        if (k and v) then
            k(...)
        end
    end
end

local function _Modularity_CallEvent_WPackageName(storing_tbl, classname, event_name, p_name, ent, ...)
    if storing_tbl[classname][p_name] then
        if storing_tbl[classname][p_name][event_name] then
            if ent then
                _Modularity_CallEvent_WPackageName_WENT(storing_tbl, classname, event_name, p_name, ent, ...)
            else
                for k, v in pairs(storing_tbl[classname][p_name][event_name]) do
                    _Modularity_CallEvent_WPackageName_WENT(storing_tbl, classname, event_name, p_name, k, ...)
                end
            end
        end
    end
end

local function _Modularity_CallEvent_Internal(storing_tbl, classname, event_name, p_name, ent, ...)
    if (classname and event_name and type(classname) == "string" and type(event_name) == "string") then
        if storing_tbl then
            if storing_tbl[classname] then
                if p_name then
                    _Modularity_CallEvent_WPackageName(storing_tbl, classname, event_name, p_name, ent, ...)
                else
                    for k, v in pairs(storing_tbl[classname]) do
                        _Modularity_CallEvent_WPackageName(storing_tbl, classname, event_name, k, ent, ...)
                    end
                end
            end
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(2).name)
    end
end

function Modularity.CallEvent(classname, event_name, p_name, ent, ...)
    --print("Modularity.CallEvent", classname, event_name, p_name, ent)
    _Modularity_CallEvent_Internal(Modularity.PackagesSubscribeFuncs, classname, event_name, p_name, ent, ...)
end

function Modularity.CallRemoteEventLocally(classname, event_name, p_name, ent, ...)
    _Modularity_CallEvent_Internal(Modularity.PackagesSubscribeRemoteFuncs, classname, event_name, p_name, ent, ...)
end

local function _Modularity_RemoveEventsOfPackage_WStoring(p_name, storing_tbl)
    for k2, v2 in pairs(storing_tbl) do
        if v2[p_name] then
            storing_tbl[k2][p_name] = nil
        end
    end
end

function Modularity.RemoveEventsOfPackage(p_name)
    if (p_name and type(p_name) == "string") then
        _Modularity_RemoveEventsOfPackage_WStoring(p_name, Modularity.PackagesSubscribeFuncs)
        _Modularity_RemoveEventsOfPackage_WStoring(p_name, Modularity.PackagesSubscribeRemoteFuncs)
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1).name)
    end
end

local function _Modularity_GetKEF(storing_tbl, classname, p_name, event_name, ent)
    if (classname and p_name and event_name and type(classname) == "string" and type(p_name) == "string" and type(event_name) == "string") then
        if storing_tbl[classname] then
            if storing_tbl[classname][p_name] then
                if storing_tbl[classname][p_name][event_name] then
                    if ent then
                        return storing_tbl[classname][p_name][event_name][ent]
                    else
                        return storing_tbl[classname][p_name][event_name]
                    end
                end
            end
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(2).name)
    end
end

--storing_tbl[classname][p_name][event_name][ent][func]
function Modularity.GetKnownEventsFunctions(classname, p_name, event_name, ent)
    return _Modularity_GetKEF(Modularity.PackagesSubscribeFuncs, classname, p_name, event_name, ent)
end

function Modularity.GetKnownRemoteEventsFunctions(classname, p_name, event_name, ent)
    return _Modularity_GetKEF(Modularity.PackagesSubscribeRemoteFuncs, classname, p_name, event_name, ent)
end

print("Modularity " .. Package.GetVersion() .. " Loaded")

-- TODO: Search for local variables in packages, load inside _ENV ?


