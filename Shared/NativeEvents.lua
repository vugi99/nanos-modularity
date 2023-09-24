

-- This is so funny that this works to know which packages loaded before while [].GetPackages returns unwanted stuff there
if debug.getregistry().environments then
    for k, v in pairs(debug.getregistry().environments) do
        --print("ENVS LOOP", k)
        if (k and k.Package and k.Package.GetName and k.Package.GetCompatibilityVersion) then
            --print("PackagesNotFullEvents Bef")
            local p_name = Modularity.GetPackageNameFromENV(k)
            --print("PackagesNotFullEvents", p_name)
            Modularity.PackagesNotFullEvents[p_name] = true
        end
    end
end

---🟨 `Shared`
---
---Is Modularity is aware of everything about a package
---@param package_name string
---@return boolean|nil has_loaded_before
function Modularity.AwareOf(package_name)
    --print(NanosTable.Dump(Modularity.PackagesNotFullEvents))
    if (package_name and type(package_name) == "string") then
        local found
        local loop_tbl
        if Server then
            loop_tbl = Server.GetPackages(true)
        else
            loop_tbl = Client.GetPackages()
        end
        for i, v in ipairs(loop_tbl) do
            if v.name == package_name then
                found = true
                break
            end
        end
        if not found then
            --print(package_name, "Not found")
            return false
        end
        return not Modularity.PackagesNotFullEvents[package_name]
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end
Modularity.AddClassDeprecatedKey(Modularity, "AwareOfAllEvents", Modularity.AwareOf, "AwareOf")

---🟨 `Shared`
---
---Returns debug infos about events subscribes found in the registry, all of them should be found there
---@param package_name string
---@return {[integer]: table} events_callbacks_info
function Modularity.GetALLEventsFunctions(package_name)
    local tbl = {}

    for k, v in pairs(debug.getregistry()) do
        if (type(v) == "function" and type(k) == "number") then
            local info = debug.getinfo(v)
            local split_spaces = Modularity.split_str(info.source, " ")
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

---🟨 `Shared`
---
---Gets the Storing table key given the storing_tbl found in Modularity.PackagesNativeEventsSystemsSubscribes
---@param storing_tbl table
---@return string|nil sub_func_name
function Modularity.GetNativeEventFunctionFromStoringTable(storing_tbl)
    for k, v in pairs(Modularity.PackagesNativeEventsSystemsSubscribes) do
        if v == storing_tbl then
            return k
        end
    end
end

local function _Mod_GoToTargetWithAdditionalParams(target, sub_func_name, additional_params)
    if not additional_params then
        return target
    else
        if Native_Events_Systems_Sub_Functions[sub_func_name] then
            if Native_Events_Systems_Sub_Functions[sub_func_name].ordered_uids then
                for i, v in ipairs(Native_Events_Systems_Sub_Functions[sub_func_name].ordered_uids) do
                    if additional_params[v] == nil then
                        additional_params[v] = Modularity.nil_placeholder
                    end
                    if not target[additional_params[v]] then
                        return
                    end
                    target = target[additional_params[v]]
                end
                return target
            end
        end
        return target
    end
end


local function _Modularity_HandleNewSubOnTarget(target, func, info_params)
    if not info_params then
        if target[func] then
            target[func] = target[func] + 1
        else
            target[func] = 1
        end
    else
        if target[func] then
            target[func].n = target[func].n + 1
            -- What do we do when info_params changed ?
            -- It should never change anyway, Console RegisterCommand should not be called twice like that...
        else
            target[func] = {
                n = 1,
                info_params = info_params,
            }
        end
    end
end

local function _ModularityRegisterNewSubscribe(classname, event_name, p_name, func, storing_tbl, ent, event_interface_conf, additional_params, info_params)
    --print("_ModularityRegisterNewSubscribe", classname, event_name, p_name, func, storing_tbl, ent, additional_params)
    if (classname and event_name and func) then
        if (type(classname) == "string" and type(event_name) == "string" and type(func) == "function") then
            local set_value = true
            if additional_params then
                set_value = additional_params
            end
            local target

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

                target = storing_tbl[classname][p_name][event_name][ent]
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
                target = storing_tbl[classname][p_name][event_name]["INDEPENDENT_SUBS"]
                --print("_ModularityRegisterNewSubscribe independent", classname, p_name, event_name, func)
            end

            if target then
                if not additional_params then
                    _Modularity_HandleNewSubOnTarget(target, func, info_params)
                else
                    for i, v in ipairs(event_interface_conf.ordered_uids) do
                        if additional_params[v] == nil then
                            additional_params[v] = Modularity.nil_placeholder
                        end
                        if not target[additional_params[v]] then
                            target[additional_params[v]] = {}
                        end
                        target = target[additional_params[v]]
                    end
                    _Modularity_HandleNewSubOnTarget(target, func, info_params)
                end

                Modularity.CallEvent("NativeSubscribeDiscovered", classname, event_name, p_name, func, ent, Modularity.GetNativeEventFunctionFromStoringTable(storing_tbl), additional_params)
            end
        end
    end
end


--[[local function _EventsCheckAdditionalParamsMatch(additional_params, target)
    if not additional_params then
        return true
    end

    if (target) then
        if (type(target) == "table") then
            for k, v in pairs(additional_params) do
                if (target[k] ~= v or target[k] == nil) then
                    return false
                end
            end
            return true
        end
    else
        return false
    end
end]]--
-- Older implementation...


local function _Modularity_Unsub_PathToTargetWithAdditionalParams_Finish(target_prev, l_key, func, event_interface_conf, additional_params)
    --print("_Modularity_Unsub_PathToTargetWithAdditionalParams_Finish", target_prev, l_key, func, event_interface_conf, additional_params)

    -- Lua tables and functions were against me.
    if additional_params then
        for i, v in ipairs(event_interface_conf.ordered_uids) do
            if additional_params[v] == nil then
                additional_params[v] = Modularity.nil_placeholder
            end
            if not target_prev[l_key][additional_params[v]] then
                return
            end
            target_prev = target_prev[l_key]
            l_key = additional_params[v]
        end
    end

    --print(NanosTable.Dump(target_prev[l_key]))

    if (not func) then
        --print("Niling")
        target_prev[l_key] = nil
        return true
    elseif target_prev[l_key][func] then
        --target_prev[l_key][func] = target_prev[l_key][func] - 1
        --if target_prev[l_key][func] <= 0 then
        target_prev[l_key][func] = nil
        --end
        return true
    end
end

local function _ModularityUnSubscribe(classname, event_name, p_name, func, storing_tbl, ent, event_interface_conf, additional_params, info_params)
    -- TODO: When Func is given so better check all packages to Unsub everywhere (Not yet cuz nanos doesn't do that)

    --print("_ModularityUnSubscribe", classname, event_name, p_name, func, storing_tbl, ent, NanosTable.Dump(additional_params))
    if (classname and event_name) then
        if (type(classname) == "string" and type(event_name) == "string") then
            --for i, storing_tbl in ipairs(_storing_tbls) do
                if storing_tbl[classname] then
                    if storing_tbl[classname][p_name] then
                        local unsubed

                        if storing_tbl[classname][p_name][event_name] then
                            if ent then
                                if storing_tbl[classname][p_name][event_name][ent] then
                                    unsubed = _Modularity_Unsub_PathToTargetWithAdditionalParams_Finish(storing_tbl[classname][p_name][event_name], ent, func, event_interface_conf, additional_params)
                                    --print("_ModularityUnSubscribe ent", classname, p_name, event_name, ent, func)
                                    --print(NanosTable.Dump(storing_tbl[classname][p_name][event_name][ent]))
                                end
                            elseif storing_tbl[classname][p_name][event_name]["INDEPENDENT_SUBS"] then
                                unsubed = _Modularity_Unsub_PathToTargetWithAdditionalParams_Finish(storing_tbl[classname][p_name][event_name], "INDEPENDENT_SUBS", func, event_interface_conf, additional_params)
                                --print("_ModularityUnSubscribe independent", classname, p_name, event_name, func)
                            end
                        end
                        if unsubed then
                            Modularity.CallEvent("NativeUnsubscribe", classname, event_name, p_name, func, ent, Modularity.GetNativeEventFunctionFromStoringTable(storing_tbl), additional_params)
                        end
                    end
                end
            --end
        end
    end
end

--[[local function _Old_GetParentPackage_Method()
    local level = 6
        local _origin_info = debug.getinfo(level)
        local info = debug.getinfo(level)

        local alt_p_name
        if (info and info.func) then
            local env, p_name = Modularity.GetFunction_ENV_upvalue(info.func)
            if Modularity.IsENVValid(env) then
                alt_p_name = p_name
            end
        end

        --print(NanosTable.Dump(info))
        while (info ~= nil and (string.find(info.source, "INTERNAL") or info.source == "=[C]")) do
            --print(NanosTable.Dump(info))
            level = level + 1
            info = debug.getinfo(level + 1)
        end
        if not info then
            --print(NanosTable.Dump(tbl))
            local args_len = #tbl
            if (args_len > 1 and type(tbl[args_len]) == "table" and type(tbl[args_len-1]) == "function") then -- Package_S and other fake static classes handling
                local env, t_p_name = Modularity.GetFunction_ENV_upvalue(tbl[args_len-1])
                if (env and t_p_name) then
                    info = {source = t_p_name}
                end
            end
        end
        --print(NanosTable.Dump(tbl))
        --print(NanosTable.Dump(info))

        if (tbl[1] and info and not string.find(info.source, "INTERNAL")) then
            local p_name = Modularity.GetStringBeforeFirstSlash(info.source)

            if p_name ~= alt_p_name then
                print("Base p_name method : ", p_name, "Alternate : ", alt_p_name)
                print(NanosTable.Dump(_origin_info), NanosTable.Dump(tbl))
            end

            --print("_ModularityMakeUOrSWrapper", classname, tbl[1], tbl[2], tbl[3], p_name)
            if (p_name and p_name ~= Package.GetName()) then -- Do not allow storing events subscribed in this package to avoid infinite loops
end]]--

local function _ModularityMakeUOrSWrapper(register_func, classname, storing_tbl, HookFuncLocType, event_interface_key, event_interface_conf)
    return function(level, ...)
        local tbl = table.pack(...) -- Contains 3 or 4 arguments, the last one is very internal stuff

        level = level+1 -- C Wrapped around it so need to look a level deeper for caller
        local info = debug.getinfo(level, "Sf")
        while (info and info.source == "=[C]") do -- Inherited calls
            level = level + 1
            info = debug.getinfo(level, "Sf")
        end

        if info then
            --print(NanosTable.Dump(info))
            --print(NanosTable.Dump(tbl))

            if ((tbl[1] ~= nil) and info) then
                local _indexes_offset = 0
                local ent

                local event_name_param_index = event_interface_conf.event_name_param_index
                local callback_param_index = event_interface_conf.callback_param_index

                if event_name_param_index then
                    if (type(tbl[event_name_param_index]) ~= "string") then
                        if (tbl[event_name_param_index+1] and type(tbl[event_name_param_index+1]) == "string") then
                            _indexes_offset = 1
                            ent = tbl[1]
                        else
                            return
                        end
                    end
                else
                    Console.Error("Missing event_name_param_index for _indexes_offset")
                    return
                end



                -- Having all those methods to get from where the function is from makes it complicated to use them in the right order and use the right fallbacks
                local p_name
                if info.source then
                    p_name = Modularity.GetStringBeforeFirstSlash(info.source)
                end

                if (((not p_name) or string.find(p_name, "INTERNAL")) and info.func) then
                    p_name = Modularity.GetFunctionPackageName_info(info.func)
                end

                if (((not p_name) or string.find(p_name, "INTERNAL")) and callback_param_index) then
                    if (type(tbl[callback_param_index+_indexes_offset]) == "function") then
                        p_name = Modularity.GetFunctionPackageName_info(tbl[callback_param_index+_indexes_offset])
                    end
                end

                if (((not p_name) or string.find(p_name, "INTERNAL")) and info.func) then
                    local env, _p_name = Modularity.GetFunction_ENV_upvalue(info.func)
                    if Modularity.IsENVValid(env) then
                        p_name = _p_name
                    end
                end

                --print(NanosTable.Dump(tbl))
                --print(NanosTable.Dump(info))

                --print(p_name, event_interface_key)

                if (p_name and (not string.find(p_name, "INTERNAL"))) then
                    --print("_ModularityMakeUOrSWrapper", classname, tbl[1], tbl[2], tbl[3], p_name)
                    if (p_name ~= Package.GetName()) then -- Do not allow storing events subscribed in this package to avoid infinite loops
                        --print(NanosTable.Dump(info))
                        --[[local cur_hook_func_info = debug.getinfo(1, "ft")
                        if cur_hook_func_info then
                            if (cur_hook_func_info.func and (not cur_hook_func_info.istailcall)) then
                                print("Hook func (Un)Subscribe", info.func, HookFuncLocType)
                            end
                        end]]--

                        --print(NanosTable.Dump(tbl))

                        local additional_params
                        if event_interface_conf.other_params_uids then
                            additional_params = {}
                            for k, v in pairs(event_interface_conf.other_params_uids) do
                                additional_params[k] = tbl[v+_indexes_offset]
                            end
                        end

                        local info_params
                        if event_interface_conf.info_params then
                            info_params = {}
                            for i, v in ipairs(event_interface_conf.info_params) do
                                info_params[v.name] = tbl[v.index+_indexes_offset]
                            end
                        end

                        if callback_param_index then
                            register_func(classname, tbl[event_name_param_index+_indexes_offset], p_name, tbl[callback_param_index+_indexes_offset], storing_tbl, ent, event_interface_conf, additional_params, info_params)
                        else
                            register_func(classname, tbl[event_name_param_index+_indexes_offset], p_name, nil, storing_tbl, ent, event_interface_conf, additional_params, info_params)
                        end
                    end
                end
            end
        else
            --Console.Error("Cannot find info outside of C calls for Events Sub Spy " .. classname .. ", " .. event_interface_key .. ", " .. HookFuncLocType)
        end
    end
end

local function NativeEventsSpyHandleNewClass(v)
    --print(v.__name)
    local count = 0
    local parents = {}
    if v.GetParentClass then
        local parent = v.GetParentClass()
        while parent do
            count = count + 1
            parents[count] = parent
            parent = parent.GetParentClass()
        end
    end

    --[[if v.__name == "Prop" then
        print(NanosTable.Dump(Modularity.ForceDump(v)))
    end]]--

    for k2, v2 in pairs(Native_Events_Systems_Sub_Functions) do
        if (v2.Class == "*" or v2.Class == v.__name or (count > 0 and v2.Class == parents[count].__name)) then
            local meta = getmetatable(v)
            --print(v.__name, NanosTable.Dump(meta))

            if ((meta and meta.__call and v2.OnInstance) or v2.StaticFunctionsInReg) then -- Does the class can be instanced
                -- Handling of entity:Subscribe / Package_S and other fake static classes

                --print("HOOK INSTANCE SUBS", v.__name)

                local functions_table = v.__function -- For inherited this table doesn't exist. The static class Subscribe is called again after another C call.

                if functions_table then
                    if functions_table[k2] then
                        --print("Hook Instance NativeEventSystem", v.__name, k2)
                        Modularity.PreHook(functions_table[k2], _ModularityMakeUOrSWrapper(_ModularityRegisterNewSubscribe, v.__name, Modularity.PackagesNativeEventsSystemsSubscribes[k2], "Instances", k2, v2), nil, true)
                    end
                    if v2.Unsub_Func then
                        --print("Hook Instance NativeEventSystem Unsub", v2.Unsub_Func, k2)
                        if functions_table[v2.Unsub_Func] then
                            Modularity.PreHook(functions_table[v2.Unsub_Func], _ModularityMakeUOrSWrapper(_ModularityUnSubscribe, v.__name, Modularity.PackagesNativeEventsSystemsSubscribes[k2], "Instances", v2.Unsub_Func, Native_Events_Systems_Unsub_Functions[v2.Unsub_Func]), nil, true)
                        end
                    end
                end
            end

            local static_name = v.__name

            if _G[static_name] then
                -- Handling of class.Subscribe

                --print("HOOK STATIC SUBS", static_name, k2)

                if _G[static_name][k2] then
                    --print("Hook Static NativeEventSystem", static_name, k2)
                    Modularity.PreHook(_G[static_name][k2], _ModularityMakeUOrSWrapper(_ModularityRegisterNewSubscribe, static_name, Modularity.PackagesNativeEventsSystemsSubscribes[k2], "Static", k2, v2), nil, true)
                end
                if v2.Unsub_Func then
                    if _G[static_name][v2.Unsub_Func] then
                        Modularity.PreHook(_G[static_name][v2.Unsub_Func], _ModularityMakeUOrSWrapper(_ModularityUnSubscribe, static_name, Modularity.PackagesNativeEventsSystemsSubscribes[k2], "Static", v2.Unsub_Func, Native_Events_Systems_Unsub_Functions[v2.Unsub_Func]), nil, true)
                    end
                end
            end
        end
    end
end


for k2, v2 in pairs(Native_Events_Systems_Sub_Functions) do
    Modularity.PackagesNativeEventsSystemsSubscribes[k2] = {}
end

if debug.getregistry().classes then
    for k, v in pairs(debug.getregistry().classes) do
        --print(k, v)
        NativeEventsSpyHandleNewClass(v)

        -- Handle inherited classes
        local static_name = v.__name
        if (_G[static_name]["Subscribe"] and _G[static_name]["Inherit"]) then
            _G[static_name]["Subscribe"]("ClassRegister", function(inh_class) -- Parent of all inherited classes so will get children calls too
                --Console.Warn(static_name .. ", ClassRegister, " .. tostring(inh_class))
                NativeEventsSpyHandleNewClass(inh_class)
            end)
        end
    end
else
    Console.Error("Native Events systems spy offline")
end

if debug.getregistry().inherited_classes then
    for k, v in pairs(debug.getregistry().inherited_classes) do
        NativeEventsSpyHandleNewClass(v)
    end
end

--print(Events.Subscribe)

local function _Modularity_CallEvent_WPackageName_WENT(storing_tbl, sub_func_name, classname, event_name, p_name, ent, returns, additional_params, ...)
    if storing_tbl[classname][p_name][event_name][ent] then
        local target = _Mod_GoToTargetWithAdditionalParams(storing_tbl[classname][p_name][event_name][ent], sub_func_name, additional_params)
        if target then
            for k, v in pairs(target) do
                if (k and v and type(k) == "function") then
                    --print(sub_func_name, classname, event_name, v)
                    if not returns[k] then
                        returns[k] = {}
                    end

                    local n
                    if type(v) == "number" then
                        n = v
                    elseif type(v) == "table" then -- support info_params structure
                        n = v.n
                    end
                    if n then
                        for i = 1, n do
                            table.insert(returns[k], table.pack(k(...)))
                        end
                    else
                        Console.Error("Modularity.NativeCallEvent : Cannot find the number of times this has to be called ?")
                    end
                end
            end
        end
    end
end

local function _Modularity_CallEvent_WPackageName(storing_tbl, sub_func_name, classname, event_name, p_name, ent, returns, additional_params, ...)
    if storing_tbl[classname][p_name] then
        if storing_tbl[classname][p_name][event_name] then
            if ent then
                _Modularity_CallEvent_WPackageName_WENT(storing_tbl, sub_func_name, classname, event_name, p_name, ent, returns, additional_params, ...)
            else
                for k, v in pairs(storing_tbl[classname][p_name][event_name]) do
                    _Modularity_CallEvent_WPackageName_WENT(storing_tbl, sub_func_name, classname, event_name, p_name, k, returns, additional_params, ...)
                end
            end
        end
    end
end

local function _Modularity_CallEvent_Internal(storing_tbl, sub_func_name, classname, event_name, p_name, ent, returns, additional_params, ...)
    if (classname and event_name and type(classname) == "string" and type(event_name) == "string") then
        if storing_tbl then
            if storing_tbl[classname] then
                if p_name then
                    _Modularity_CallEvent_WPackageName(storing_tbl, sub_func_name, classname, event_name, p_name, ent, returns, additional_params, ...)
                else
                    for k, v in pairs(storing_tbl[classname]) do
                        _Modularity_CallEvent_WPackageName(storing_tbl, sub_func_name, classname, event_name, k, ent, returns, additional_params, ...)
                    end
                end
            end
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(2, "n").name)
    end
end

---🟨 `Shared`
---
---Calls a native event, on a certain class. For instance calls use ent
---@param sub_func_name string usually Subscribe
---@param classname string
---@param event_name string
---@param p_name? string @(Default: nil)
---@param ent? any @(Default: nil)
---@param additional_params? any @(Default: nil)
---@param ... any event call params (Default: nil)
---@return {[function]: any[]} returns
function Modularity.NativeCallEvent(sub_func_name, classname, event_name, p_name, ent, additional_params, ...)
    --print("Modularity.CallEvent", classname, event_name, p_name, ent)
    if Modularity.PackagesNativeEventsSystemsSubscribes[sub_func_name] then
        local returns = {}

        local class = _G[classname]
        if (class and class.GetParentClass) then
            local parent = class.GetParentClass()
            if parent then
                returns = Modularity.NativeCallEvent(sub_func_name, parent.__name, event_name, p_name, ent, additional_params, ...)
            end
        end

        _Modularity_CallEvent_Internal(Modularity.PackagesNativeEventsSystemsSubscribes[sub_func_name], sub_func_name, classname, event_name, p_name, ent, returns, additional_params, ...)
        return returns
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

local function _Modularity_RemoveEventsOfPackage_WStoring(p_name, storing_tbl)
    for k2, v2 in pairs(storing_tbl) do
        if v2[p_name] then
            storing_tbl[k2][p_name] = nil
        end
    end
end

---🟨 `Shared`
---
---INTERNAL Cleans up Native Events Subscribes found for a package
---@param p_name string
function Modularity.RemoveEventsOfPackage(p_name)
    if (p_name and type(p_name) == "string") then
        for k, v in pairs(Modularity.PackagesNativeEventsSystemsSubscribes) do
            _Modularity_RemoveEventsOfPackage_WStoring(p_name, Modularity.PackagesNativeEventsSystemsSubscribes[k])
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

local function _Modularity_GetKEF(sub_func_name, storing_tbl, classname, p_name, event_name, ent, additional_params)
    if (classname and p_name and event_name and type(classname) == "string" and type(p_name) == "string" and type(event_name) == "string") then
        if storing_tbl[classname] then
            if storing_tbl[classname][p_name] then
                if storing_tbl[classname][p_name][event_name] then
                    if ent then
                        return _Mod_GoToTargetWithAdditionalParams(storing_tbl[classname][p_name][event_name][ent], sub_func_name, additional_params)
                    else
                        return _Mod_GoToTargetWithAdditionalParams(storing_tbl[classname][p_name][event_name], sub_func_name, additional_params)
                    end
                end
            end
        end
    else
        error("Wrong arguments on Modularity." .. tostring(debug.getinfo(2, "n").name))
    end
end

---🟨 `Shared`
---
---Gets a sub table from modularity native events spy big table. You should dump it to the console to see.
---@param sub_func_name string
---@param classname string
---@param p_name string
---@param event_name string
---@param ent? any
---@param additional_params? any
---@return table|nil sub_table
function Modularity.GetKnownNativeEventsFunctions(sub_func_name, classname, p_name, event_name, ent, additional_params)
    if Modularity.PackagesNativeEventsSystemsSubscribes[sub_func_name] then
        return _Modularity_GetKEF(sub_func_name, Modularity.PackagesNativeEventsSystemsSubscribes[sub_func_name], classname, p_name, event_name, ent, additional_params)
    else
        error("Cannot find subscribe function stored stuff on Modularity." .. debug.getinfo(1, "n").name)
    end
end







_Mod_LastCL_index = 0

---🟨 `Shared`
---
---Register a new classlink for a specific class to be able to pass custom classes through events and remote events (enable it with other methods) <br>
---The classlink is cleaned when the calling package unloads <br>
---The function calls are protected from errors
---@param is_of_class_func function
---@param find_entity_func? function
---@param compress_entity_func? function
---@return integer|nil classlink_id
function Modularity.RegisterClassLink(is_of_class_func, find_entity_func, compress_entity_func)
    if (is_of_class_func and find_entity_func and type(is_of_class_func) == "function" and type(find_entity_func) == "function") then
        --print("Modularity.RegisterClassLink", NanosTable.Dump(debug.getinfo(2)))

        local info = debug.getinfo(2, "S")
        if info then
            local p_name = Modularity.GetStringBeforeFirstSlash(info.source)
            if p_name then
                _Mod_LastCL_index = _Mod_LastCL_index + 1
                --Console.Warn("Modularity.RegisterClassLink, " .. tostring(is_of_class_func) .. ", " .. tostring(_Mod_LastCL_index))
                Modularity.ClassLinks[_Mod_LastCL_index] = {
                    is_of_class_func=is_of_class_func,
                    find_entity_func=find_entity_func,
                    compress_entity_func=compress_entity_func,
                    p_name=p_name,
                }
                return _Mod_LastCL_index
            else
                return error("Cannot retrieve calling package")
            end
        else
            return error("Cannot retrieve calling package")
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

---🟨 `Shared`
---
---Reconstruct entities looking for classes instances given classlinks_ids <br>
---If entities passed as varargs will return them as varargs, if they are passed in a table then nothing will be returned and the table will be modified directly
---@param classlinks integer[]
---@param tbl_pass boolean
---@param ... any to-be reconstructed entities
---@return ...|nil reconstructed_entities
---@overload fun(classlinks: integer[], tbl_pass: true, entities_to_reconstruct: {[integer]: any})
function Modularity.ClasslinksReconstructEntities(classlinks, tbl_pass, ...)
    if type(classlinks) == "table" then
        --print("Modularity.ClasslinksReconstructEntities")
        local to_be_recontructed = table.pack(...)
        if tbl_pass then
            if type(to_be_recontructed[1]) ~= "table" then
                return error("Expected table as 3rd argument")
            end
            to_be_recontructed = to_be_recontructed[1]
        end
        for i, v in pairs(to_be_recontructed) do
            if type(i) == "number" then
                for i2, v2 in ipairs(classlinks) do
                    if v2 then
                        if Modularity.ClassLinks[v2] then
                            local success, ret = pcall(Modularity.ClassLinks[v2].is_of_class_func, v)
                            if (success and ret) then
                                if Modularity.ClassLinks[v2].find_entity_func then
                                    local f_success, f_ret = pcall(Modularity.ClassLinks[v2].find_entity_func, v)
                                    if f_success then
                                        to_be_recontructed[i] = f_ret
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if not tbl_pass then
            return table.unpack(to_be_recontructed, 1, to_be_recontructed.n)
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end


---🟨 `Shared`
---
---Compress entities looking for classes instances given classlinks_ids <br>
---If entities passed as varargs will return them as varargs, if they are passed in a table then nothing will be returned and the table will be modified directly
---@param classlinks integer[]
---@param tbl_pass boolean
---@param ... any to-be compressed entities
---@return ...|nil compressed_entities
---@overload fun(classlinks: integer[], tbl_pass: true, entities_to_compress: {[integer]: any})
function Modularity.ClasslinksCompressEntities(classlinks, tbl_pass, ...)
    if type(classlinks) == "table" then
        local to_be_compressed = table.pack(...)
        if tbl_pass then
            if type(to_be_compressed[1]) ~= "table" then
                return error("Expected table as 3rd argument")
            end
            to_be_compressed = to_be_compressed[1]
        end
        for i, v in pairs(to_be_compressed) do
            if type(i) == "number" then
                for i2, v2 in ipairs(classlinks) do
                    --print("NativeEventsCallFunction", "c", i, v2)
                    if v2 then
                        if Modularity.ClassLinks[v2] then
                            --print("Compression Check With Func", v2, Modularity.ClassLinks[v2].is_of_class_func, NanosTable.Dump(v))
                            local success, ret = pcall(Modularity.ClassLinks[v2].is_of_class_func, v)
                            if (success and ret) then
                                --print("Compress Entity", v2, classname, call_func_name)
                                if Modularity.ClassLinks[v2].compress_entity_func then
                                    local c_success, c_ret = pcall(Modularity.ClassLinks[v2].compress_entity_func, v)
                                    if c_success then
                                        to_be_compressed[i] = c_ret
                                        break -- Classlink triggered, stop the loop
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if not tbl_pass then
            return table.unpack(to_be_compressed, 1, to_be_compressed.n)
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end


---🟨 `Shared`
---
---Look for a specific function args in a hook to reconstruct the arguments when it is called. (Should be used for a native events callback)
---@param func function
---@param ... integer classlink_ids
---@return boolean success
function Modularity.WatchFunctionArgsForClassLinks(func, ...)
    if (func and type(func) == "function") then
        local class_links = table.pack(...)
        for i2, v2 in ipairs(class_links) do
            if not Modularity.ClassLinks[v2] then
                error("Classlink doesn't exist on Modularity." .. debug.getinfo(1, "n").name)
            end
        end

        Modularity.PreHook(func, function(...)
            --[[local args = table.pack(...)
            for i, v in pairs(args) do
                if type(i) == "number" then
                    for i2, v2 in ipairs(class_links) do
                        if v2 then
                            if Modularity.ClassLinks[v2] then
                                local success, ret = pcall(Modularity.ClassLinks[v2].is_of_class_func, v)
                                if (success and ret) then
                                    local f_success, f_ret = pcall(Modularity.ClassLinks[v2].find_entity_func, v)
                                    if f_success then
                                        args[i] = f_ret
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return table.unpack(args, 1, args.n)]]--
            return Modularity.ClasslinksReconstructEntities(class_links, false, ...)
        end, true)

        return true
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end



local function _ModularityGlobalWatchClasslinksPrehook(func)
    --print("_ModularityGlobalWatchClasslinksPrehook", func)
    Modularity.PreHook(func, function(...)
        --[[local args = table.pack(...)
        for i, v in pairs(args) do
            if type(i) == "number" then
                for k2, v2 in pairs(Modularity.GlobalSubscribesClasslinks) do
                    if (k2 and v2) then
                        if Modularity.ClassLinks[k2] then
                            --print("Watch Args", k2)
                            local success, ret = pcall(Modularity.ClassLinks[k2].is_of_class_func, v)
                            if (success and ret) then
                                local f_success, f_ret = pcall(Modularity.ClassLinks[k2].find_entity_func, v)
                                if f_success then
                                    args[i] = f_ret
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        return table.unpack(args, 1, args.n)]]--
        return Modularity.ClasslinksReconstructEntities(Modularity.DumpKeys(Modularity.GlobalSubscribesClasslinks), false, ...)
    end, true)
end

local function _ModularityGWAFC_LookForEventsSubscribesFunctions(storing_tbl)
    if storing_tbl["Events"] then
        for p_name, v in pairs(storing_tbl["Events"]) do
            for event_name, v2 in pairs(v) do
                for ent, v3 in pairs(v2) do
                    for f, v4 in pairs(v3) do
                        if f then
                            --print(f)
                            _ModularityGlobalWatchClasslinksPrehook(f)
                        end
                    end
                end
            end
        end
    end
end


local _GWAFC_Activated = false

---🟨 `Shared`
---
---Watch for all native events callbacks to reconstruct arguments for the given classlink_ids
---@param ... integer classlink_ids
---@return boolean success
function Modularity.AddGlobalWatchArgsForClassLinks(...)
    local class_links = table.pack(...)
    for i2, v2 in ipairs(class_links) do
        if not Modularity.ClassLinks[v2] then
            error("Classlink doesn't exist on Modularity." .. debug.getinfo(1, "n").name)
        else
            Modularity.GlobalSubscribesClasslinks[v2] = true
        end
    end

    if not _GWAFC_Activated then
        _GWAFC_Activated = true

        for k, v in pairs(Modularity.PackagesNativeEventsSystemsSubscribes) do
            _ModularityGWAFC_LookForEventsSubscribesFunctions(Modularity.PackagesNativeEventsSystemsSubscribes[k])
        end

        Modularity.Subscribe("NativeSubscribeDiscovered", function(classname, event_name, p_name, func, ent)
            if (classname == "Events" and (not ent)) then
                --print("NativeSubscribeDiscovered", event_name, func)
                _ModularityGlobalWatchClasslinksPrehook(func)
            end
        end)
    end

    return true
end



local function _ModularityCompression_NewNativeEventsCallFunction(classname, call_func_name, event_name)
    if _G[classname] then
        if _G[classname][call_func_name] then
            local _PreHookCompression_HookFunc = function(...)
                local Compression_tbl = Modularity.NativeCallsCompression[classname]
                if Compression_tbl then
                    Compression_tbl = Compression_tbl[call_func_name]
                    if Compression_tbl then
                        Compression_tbl = Compression_tbl[event_name]
                        if Compression_tbl then
                            local tbl = table.pack(...)
                            --print("NativeEventsCallFunction", tbl[Compression_tbl.event_name_param_index], event_name)
                            if ((tbl[Compression_tbl.event_name_param_index] and (tbl[Compression_tbl.event_name_param_index] == event_name)) or event_name == "*") then
                                --print("NativeEventsCallFunction", "b")

                                --local count = Modularity.table_count(tbl)
                                local count = tbl.n
                                for i = Compression_tbl.params_starting_index, count do
                                    --[[for i2, v2 in ipairs(Compression_tbl.class_links) do
                                        --print("NativeEventsCallFunction", "c", i, v2)
                                        if v2 then
                                            if Modularity.ClassLinks[v2] then
                                                --print("Compression Check With Func", v2, Modularity.ClassLinks[v2].is_of_class_func, NanosTable.Dump(tbl[i]))
                                                local success, ret = pcall(Modularity.ClassLinks[v2].is_of_class_func, tbl[i])
                                                if (success and ret) then
                                                    --print("Compress Entity", v2, classname, call_func_name, tbl[Compression_tbl.event_name_param_index])
                                                    local c_success, c_ret = pcall(Modularity.ClassLinks[v2].compress_entity_func, tbl[i])
                                                    if c_success then
                                                        tbl[i] = c_ret
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                    end]]--
                                    tbl[i] = Modularity.ClasslinksCompressEntities(Compression_tbl.class_links, false, tbl[i])
                                end

                                --print("NativeEventsCallFunction", "d")

                                --print(NanosTable.Dump(tbl))

                                return table.unpack(tbl, 1, tbl.n)
                            end
                        end
                    end
                end

                return ...
            end
            Modularity.PreHook(_G[classname][call_func_name], _PreHookCompression_HookFunc, true)

            return _PreHookCompression_HookFunc
        end
    end
end

---🟨 `Shared`
---
---Enable compression for a classlink in native events <br>
---Doesn't support CallBlueprintEvent and Events calls on instances eg ins:CallRemote(...)
---@param class_link integer
---@param settings {[string]: {call_func_name: string, params_starting_index: integer, event_name_param_index: integer}[]} [string] is classname, see Modularity.Default_Configs.Compression
---@param event_name? string @(Default: "*")
---@return boolean success
function Modularity.SetNativeEventsClassLinkCompression(class_link, settings, event_name) 
    if (class_link and type(class_link) == "number" and settings and type(settings) == "table") then
        event_name = event_name or "*"

        if settings then
            for classname, v in pairs(settings) do
                if not Modularity.NativeCallsCompression[classname] then
                    Modularity.NativeCallsCompression[classname] = {}
                end

                for i2, v2 in ipairs(v) do
                    if not Modularity.NativeCallsCompression[classname][v2.call_func_name] then
                        Modularity.NativeCallsCompression[classname][v2.call_func_name] = {}
                    end

                    if not Modularity.NativeCallsCompression[classname][v2.call_func_name][event_name] then
                        Modularity.NativeCallsCompression[classname][v2.call_func_name][event_name] = {
                            params_starting_index = v2.params_starting_index,
                            event_name_param_index = v2.event_name_param_index,
                            class_links = {class_link},
                        }
                        local hook_func = _ModularityCompression_NewNativeEventsCallFunction(classname, v2.call_func_name, event_name)
                        if not hook_func then
                            Console.Warn("Couldn't hook call method : " .. tostring(v2.call_func_name) .. " on " .. tostring(classname))
                            Modularity.NativeCallsCompression[classname][v2.call_func_name][event_name] = nil
                        else
                            Modularity.NativeCallsCompression[classname][v2.call_func_name][event_name].hook_func = hook_func
                        end
                    else
                        table.insert(Modularity.NativeCallsCompression[classname][v2.call_func_name][event_name].class_links, class_link)
                    end
                end
            end
        end

        return true
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

--[[Modularity.Subscribe("NativeSubscribeDiscovered", function(...)
    print("NativeSubscribeDiscovered", ...)
end)

Modularity.Subscribe("NativeUnsubscribe", function(...)
    print("NativeUnsubscribe", ...)
end)]]--

-- TODO : Store count in local variable here
local native_calls_in_progress = {}

Modularity.Subscribe("CallsTreeFromNowReturn", function(func, returned)
    local count = Modularity.table_count(native_calls_in_progress)
    if count > 0 then
        if native_calls_in_progress[count] then
            if native_calls_in_progress[count].call_func == func then
                local nc = native_calls_in_progress[count]
                table.remove(native_calls_in_progress, count)
                for i, v in ipairs(returned.tree) do
                    --print("Discovered " .. nc.event_name .. " in " .. tostring(v.info.source))
                    if v.info.source then
                        local callback_func = v.info.func
                        local p_name = Modularity.GetStringBeforeFirstSlash(v.info.source)
                        if (p_name and (not string.find(p_name, "INTERNAL")) and callback_func) then
                            local storing_tbl = Modularity.PackagesNativeEventsSystemsSubscribes[Native_Events_Systems_Call_Functions[nc.call_func_name].SubFuncKey]
                            if storing_tbl then
                                if storing_tbl[nc.classname] then
                                    if storing_tbl[nc.classname][p_name] then
                                        if storing_tbl[nc.classname][p_name][nc.event_name] then
                                            if storing_tbl[nc.classname][p_name][nc.event_name][nc.ent] then
                                                if storing_tbl[nc.classname][p_name][nc.event_name][nc.ent][callback_func] then
                                                    --print("Call Native Event Already Discovered", nc.event_name, v.info.source)
                                                    return -- Already subscribed
                                                end
                                            end
                                        end
                                    end
                                end
                                _ModularityRegisterNewSubscribe(nc.classname, nc.event_name, p_name, callback_func, storing_tbl, nc.ent, nil, nil) -- No additional_params
                                --print("New Native Event Discovered in Call", nc.event_name, p_name)
                            end
                        end
                    end
                end
            end
        end
    end
end)

local function _ModularityMake_NativeEventsCallPreHook(classname, call_func_name, CallType, call_func)
    return function(...)
        local args = table.pack(...)

        local _indexes_offset = 0
        local ent = "INDEPENDENT_SUBS"

        local event_name
        if Native_Events_Systems_Call_Functions[call_func_name].event_name_param_index then
            if type(args[Native_Events_Systems_Call_Functions[call_func_name].event_name_param_index]) ~= "string" then
                if type(args[Native_Events_Systems_Call_Functions[call_func_name].event_name_param_index+1] == "string") then
                    _indexes_offset = 1
                    ent = args[1]
                end
            end
            event_name = args[Native_Events_Systems_Call_Functions[call_func_name].event_name_param_index+_indexes_offset]
        else
            Console.Error("Missing event_name_param_index in Native_Events_Systems_Call_Functions['" .. call_func_name .. "']")
            return
        end
        table.insert(native_calls_in_progress, {
            classname = classname,
            call_func_name = call_func_name,
            call_func = call_func,
            event_name = event_name,
            ent = ent,
        })
        Modularity.CallsTreeFromNow(call_func, nil, 1)
    end
end

if debug.getregistry().classes then
    for k, v in pairs(debug.getregistry().classes) do
        for k2, v2 in pairs(Native_Events_Systems_Call_Functions) do
            --print(v.__name)
            if (v2.Class == "*" or v2.Class == v.__name) then
                local meta = getmetatable(v)

                if (meta and meta.__call and v2.OnInstance) then
                    if (v.__function and v.__function[k2]) then
                        Modularity.PreHook(v.__function[k2], _ModularityMake_NativeEventsCallPreHook(v.__name, k2, "Instance", v.__function[k2]))
                    end
                end

                local static_name = v.__name

                if _G[static_name] then
                    if _G[static_name][k2] then
                        Modularity.PreHook(_G[static_name][k2], _ModularityMake_NativeEventsCallPreHook(static_name, k2, "Static", _G[static_name][k2]))
                    end
                end
            end
        end
    end
end

--[[ 
TODO : More Subs Guesses with calls
- Better ent guess with params passed into functions match self with the ent of the first call arg
- ^ Canvas Update
- CharacterSimple MoveComplete?, Possess/UnPossess
- Character AttemptEnterVehicle/EnterVehicle, Drop, AttemptReload/Reload, Fire, GaitModeChange, MoveComplete?, PickUp, Possess/UnPossess, PullUse, RagdollModeChange, ReleaseUse, GrabProp/UnGrapProp, StanceModeChange, SwimmingModeChange, ViewModeChange, WeaponAimModeChange
- Grenade Explode, Throw
- Melee Attack
- Player DimensionChange, Possess/UnPossess, (VOIP Call Remote Event from client before game to prepare to receive?, weird)
- Prop Grab/UnGrab
- Trigger BeginOverlap/EndOverlap on force check and calculate separately to decide if its Begin or End + Dimensions
- VehicleWater CharacterAttemptEnter/CharacterEnter, CharacterAttemptLeave/CharacterLeave
- VehicleWheeled CharacterAttemptEnter/CharacterEnter, CharacterAttemptLeave/CharacterLeave, Horn
- Weapon 

]]--