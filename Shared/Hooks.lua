

local function _ModularitySingleHookCall(call_params, call_values, v, level, EORPV)
    --print("_ModularitySingleHookCall", v[2])
    local call_params_passed = call_params
    local call_values_passed = call_values

    if v[5] then -- EndHook args enum
        if v[5] < Modularity.Enums.EndHookParams._count then
            call_params_passed = EORPV.call_params[v[5]]
            call_values_passed = EORPV.call_values[v[5]]
        end
    end

    local modified_params
    local unpacked = call_values_passed
    if v[4] then
        unpacked = call_params_passed
    end
    if not v[2] then
        if not v[3] then
            v[1](table.unpack(unpacked, 1, unpacked.n))
        else
            v[1](level+1, table.unpack(unpacked, 1, unpacked.n))
        end
    else
        local new_call_values
        if not v[3] then
            new_call_values = table.pack(v[1](table.unpack(unpacked, 1, unpacked.n)))
        else
            new_call_values = table.pack(v[1](level+1, table.unpack(unpacked, 1, unpacked.n)))
        end

        local _i_offset = 0
        if call_params_passed.return_params_offset then
            _i_offset = call_params_passed.return_params_offset
        end
        for i = 1, call_values_passed.n do
            call_values[i+_i_offset] = new_call_values[i]
            call_params[i+_i_offset].value = new_call_values[i]
        end

        if v[5] then
            --[[for k2, v2 in pairs(Modularity.Enums.EndHookParams) do -- Not very ideal... I believe that it's _good enough_ performance wise even though it doesn't look good
                if EORPV.call_params[v2] then
                    local _i_offset_loop = 0
                    if EORPV.call_params[v2].return_params_offset then
                        _i_offset_loop = EORPV.call_params[v2].return_params_offset
                    end
                    for i3 = 1, EORPV.call_params[v2].n do
                        EORPV.call_params[v2][i3].value = call_values[i3+_i_offset_loop]
                        EORPV.call_values[v2][i3] = call_values[i3+_i_offset_loop]
                    end
                end
            end]]--

            for k2, v2 in pairs(EORPV.call_params) do
                if k2 ~= Modularity.Enums.EndHookParams.NoParams then
                    local _i_offset_loop = 0
                    if v2.return_params_offset then
                        _i_offset_loop = v2.return_params_offset
                    end
                    for i3 = 1, v2.n do
                        v2[i3].value = call_values[i3+_i_offset_loop]
                        EORPV.call_values[k2][i3] = call_values[i3+_i_offset_loop]
                    end
                end
            end
        end

        modified_params = true
    end
    return modified_params
end

local function _ModularityHandleHookCalls(HookTbl, HookType, info, call_params, call_values, level, enums_other_return_params_values)
    local modified_params = false

    --print("_ModularityHandleHookCalls", HookType)

    if HookType == "Ref" then
        for h_p_name, _ in pairs(HookTbl) do
            if HookTbl[h_p_name][info.func] then
                --print(NanosTable.Dump(HookTbl[h_p_name][info.func]))
                --[[if (info.name == "Subscribe" and (not enums_other_return_params_values) and info.source == "=[C]") then
                    print(NanosTable.Dump(HookTbl[h_p_name][info.func]))
                end]]--
                for i, v in ipairs(HookTbl[h_p_name][info.func]) do
                    local m_p = _ModularitySingleHookCall(call_params, call_values, v, level+1, enums_other_return_params_values)
                    modified_params = modified_params or m_p
                end
            end
        end
    elseif HookType == "Name" then
        for h_p_name, _ in pairs(HookTbl) do
            if HookTbl[h_p_name][info.name] then
                for i2, v in ipairs(HookTbl[h_p_name][info.name]) do
                    if v[6] then
                        local p_name = Modularity.GetFunctionPackageName_info(info.func)
                        if p_name then
                            if p_name == v[6] then
                                local m_p = _ModularitySingleHookCall(call_params, call_values, v, level+1, enums_other_return_params_values)
                                modified_params = modified_params or m_p
                            end
                        else
                            Console.Error("Cannot get package_name of function in _ModularityHandleHookCalls")
                        end
                    else
                        local m_p = _ModularitySingleHookCall(call_params, call_values, v, level+1, enums_other_return_params_values)
                        modified_params = modified_params or m_p
                    end
                end
            end
        end
    end
    if modified_params then
        for i, v in ipairs(call_params) do
            local name, value = debug.getlocal(level, v.local_index)
            if name == v.name then
                debug.setlocal(level, v.local_index, v.value)
            else
                Console.Error("Name Check Failed when altering args")
            end
        end
    end
end

local function _Modularity_GetCallArguments_While(mult, call_params, call_values, level)
    local i = 1
    local name, value = "true", nil
    while name do
        name, value = debug.getlocal(level, mult*i)
        if name then
            table.insert(call_params, {name = name, value = value, local_index = mult*i, arg_type = "param"})
            call_values[call_values.n+1] = value
            call_values.n = call_values.n + 1
        end
        i = i + 1
    end
end

local function _Modularity_GetCallArguments_For(info, call_params, call_values, level, call_type)
    local loop_end = info.nparams
    if (info.source == "=[C]" and loop_end == 0) then -- C calls don't have the right nparams [Important fix here, used for built-in lua functions and nanos api]
        if call_type ~= "return" then
            loop_end = info.ntransfer
        else
            loop_end = info.ftransfer-1
        end
    end
    for i = 1, loop_end do
        local name, value = debug.getlocal(level, i)
        table.insert(call_params, {name = name, value = value, local_index = i, arg_type = "param"})
        call_values[call_values.n+1] = value
        call_values.n = call_values.n + 1
    end
end

local function _Modularity_GetCallsArguments_Universal(info, level, call_params, call_values, call_type)
    --print(NanosTable.Dump(info))
    if info.isvararg then
        --[[if info.source == "=[C]" then
            _Modularity_GetCallArguments_While(1, call_params, call_values, level+1) -- To catch some internal arguments from internal calls, needed for Subscribe / other game classes
        else
            _Modularity_GetCallArguments_For(info, call_params, call_values, level+1, call_type)
        end]]--
        _Modularity_GetCallArguments_For(info, call_params, call_values, level+1, call_type)
        _Modularity_GetCallArguments_While(-1, call_params, call_values, level+1)
    else
        _Modularity_GetCallArguments_For(info, call_params, call_values, level+1, call_type)
    end
    return call_params, call_values
end

local function _Modularity_Init_CallArgs()
    local call_params = {}
    local call_values = {n = 0} -- Use table.pack format to handle nil parameters
    return call_params, call_values
end

local function _Modularity_AddReturnArguments(info, level, call_params, call_values)
    if (info.ftransfer and info.ntransfer) then
        --print("ftransfer", info.ftransfer, "ntransfer", info.ntransfer)

        --[[if info.ftransfer == 0 then
            local name, value = debug.getlocal(level, 1) -- Why the Hook function got there ??
            if name then
                if type(value) == "function" then
                    value()
                end
            end
        end]]--

        for i = info.ftransfer, info.ftransfer+info.ntransfer-1 do
            local name, value = debug.getlocal(level, i)
            table.insert(call_params, {name = name, value = value, local_index = i, arg_type = "return"})
            call_values[call_values.n+1] = value
            call_values.n = call_values.n + 1
        end
    end
end


function Modularity.EnablePrintDebugInfo(enable, full_stack, show_args, print_hook_type)
    if (type(enable) == "boolean" or type(enable) == "nil") then
        Modularity.print_debug_info = {enable, full_stack, show_args, print_hook_type}
        return true
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end


local cur_debughook_callback, cur_mask, cur_count = debug.gethook()


local _FunctionsThatAreHooked = {}

function _Modularity_ReBuildFunctionsThatAreHooked()
    _FunctionsThatAreHooked = {}

    for i, HookTbl in ipairs(Modularity.GetHooksTables()) do
        for p_name, v in pairs(HookTbl) do
            for f, _ in pairs(v) do
                _FunctionsThatAreHooked[f] = true
            end
        end
    end
end

-- TODO : Do not use table.insert for call_params
local alter_debug_funcs_with_levels_offset = 1
local ddgi = debug.getinfo
debug.sethook(function(call_type)

    local info = ddgi(2, "nf")

    alter_debug_funcs_with_levels_offset = 2
    for k, v in pairs(Modularity.DebugHooks) do
        if ((call_type ~= "return" and v.c) or (call_type == "return" and v.r)) then
            if v.count <= 0 then
                v.count = v.count_reset
                --Console.Log("REAL, " .. call_type .. ", " .. NanosTable.Dump(info))
                --Console.Log("Calling hook")
                v.callback(call_type)
            else
                v.count = v.count - 1
            end
        end
    end
    alter_debug_funcs_with_levels_offset = 1

    if info then

        if (Modularity.print_debug_info[1]) then
            info = ddgi(2, "nStufr")

            local args
            if Modularity.print_debug_info[3] then
                local call_params, call_values = _Modularity_Init_CallArgs()

                _Modularity_GetCallsArguments_Universal(info, 3, call_params, call_values, call_type)
                if call_type == "return" then
                    _Modularity_AddReturnArguments(info, 3, call_params, call_values)
                end

                args = call_params
            end
            if ((call_type ~= "return" and ((not Modularity.print_debug_info[4]) or string.find(Modularity.print_debug_info[4], "c"))) or (call_type == "return" and Modularity.print_debug_info[4] and string.find(Modularity.print_debug_info[4], "r"))) then
                if not Modularity.print_debug_info[2] then
                    if not args then
                        print(call_type, NanosTable.Dump(info))
                    else
                        print(call_type, "args : ", NanosTable.Dump(args), NanosTable.Dump(info))
                    end
                else
                    local level = 2
                    local full_stack_info = ddgi(level)
                    while full_stack_info do
                        if (level == 2 and args) then
                            print(call_type, "args : ", NanosTable.Dump(args), level, NanosTable.Dump(full_stack_info))
                        else
                            print(level, NanosTable.Dump(full_stack_info))
                        end
                        level = level + 1
                        full_stack_info = ddgi(level)
                    end
                end
            end
        end

        --if (Modularity.GetStringBeforeFirstSlash(info.source) ~= Package.GetName() and call_type ~= "return" and info.name ~= "select" and info.name ~= "for iterator" and info.name ~= "Log" and info.name ~= "tonumber" and info.name ~= "tostring" and info.source ~= "Lua Default Library") then
            --print(NanosTable.Dump(info))
        --end

        if (_FunctionsThatAreHooked[info.func] or _FunctionsThatAreHooked[info.name]) then
            info = ddgi(2, "nStufr")

            --print(NanosTable.Dump(info))

            local call_params, call_values = _Modularity_Init_CallArgs()

            _Modularity_GetCallsArguments_Universal(info, 3, call_params, call_values, call_type)
            if call_type == "return" then
                _Modularity_AddReturnArguments(info, 3, call_params, call_values)
            end

            --print("INTERNAL", NanosTable.Dump(call_params))
            if call_type ~= "return" then

                _ModularityHandleHookCalls(Modularity.PreHooks, "Ref", info, call_params, call_values, 3)
                _ModularityHandleHookCalls(Modularity.PreHooksName, "Name", info, call_params, call_values, 3)
            else
                local EORPV = {
                    call_params = {},
                    call_values = {},
                }
                for k, v in pairs(Modularity.Enums.EndHookParams) do
                    if v == Modularity.Enums.EndHookParams.NoParams then
                        EORPV.call_params[v] = {n=0}
                        EORPV.call_values[v] = {n=0}
                    elseif v == Modularity.Enums.EndHookParams.CallParams then
                        EORPV.call_params[v] = {n=0}
                        EORPV.call_values[v] = {n=0}
                        for i2, v2 in ipairs(call_params) do
                            if v2.arg_type == "param" then
                                EORPV.call_params[v].n = EORPV.call_params[v].n + 1
                                EORPV.call_params[v][EORPV.call_params[v].n] = v2

                                EORPV.call_values[v].n = EORPV.call_values[v].n + 1
                                EORPV.call_values[v][EORPV.call_values[v].n] = v2.value
                            end
                        end
                    elseif v == Modularity.Enums.EndHookParams.ReturnParams then
                        EORPV.call_params[v] = {n=0}
                        EORPV.call_values[v] = {n=0}
                        for i2, v2 in ipairs(call_params) do
                            if v2.arg_type == "return" then
                                if not EORPV.call_params[v].return_params_offset then
                                    EORPV.call_params[v].return_params_offset = i2-1
                                end

                                EORPV.call_params[v].n = EORPV.call_params[v].n + 1
                                EORPV.call_params[v][EORPV.call_params[v].n] = v2

                                EORPV.call_values[v].n = EORPV.call_values[v].n + 1
                                EORPV.call_values[v][EORPV.call_values[v].n] = v2.value
                            end
                        end
                    end
                end

                --print(NanosTable.Dump(info))
                --print(NanosTable.Dump(call_params))
                --print(debug.getlocal(2, 1))

                _ModularityHandleHookCalls(Modularity.EndHooks, "Ref", info, call_params, call_values, 3, EORPV)
                _ModularityHandleHookCalls(Modularity.EndHooksName, "Name", info, call_params, call_values, 3, EORPV)
            end
        end

        -- CallsTree
        if call_type ~= "return" then
            local i = CallsTreeCount
            while (i > 0 and Modularity.CallsTreeInProgress[i]) do
                v = Modularity.CallsTreeInProgress[i]
                --print(NanosTable.Dump(info))

                local parent_infos = {}
                local search_level = 2
                info = ddgi(search_level)
                local CTIP_info = ddgi(search_level)
                local stopped
                while (CTIP_info and (not v.max_depth or search_level-2 <= v.max_depth)) do
                    --print("go br", search_level)
                    if (CTIP_info.func == v.func) then
                        stopped = "func"
                        break
                    elseif (Modularity.CompareTables(CTIP_info, v.parent_call_info) and search_level > 2) then
                        stopped = "parent"
                        break
                    end
                    parent_infos[search_level-1] = CTIP_info
                    search_level = search_level + 1
                    CTIP_info = ddgi(search_level)
                end
                if stopped then -- Still inside the function call
                    local searching_returned = v.returned.tree
                    if stopped == "parent" then
                        searching_returned = v.returned.tailcalls
                    end
                    local p_infos_count = search_level-2
                    for i2 = p_infos_count, 2, -1 do -- First element is the current call so don't look at it as parent
                        for i3, v3 in ipairs(searching_returned) do
                            --if v3.info == parent_infos[i2] then
                            if Modularity.CompareTables(v3.info, parent_infos[i2], {currentline=true,ntransfer=true,ftransfer=true}) then
                                searching_returned = searching_returned[i3].child_calls
                                break
                            end
                        end
                    end
                    --print("Insert", p_infos_count)
                    if p_infos_count > 0 then
                        if v.show_args then
                            local call_params, call_values = _Modularity_Init_CallArgs()
                            _Modularity_GetCallsArguments_Universal(info, 3, call_params, call_values, call_type)
                            table.insert(searching_returned, {info=info, child_calls={}, args=call_params})
                        else
                            table.insert(searching_returned, {info=info, child_calls={}})
                        end
                    else
                        --print("The direct call to the function.", NanosTable.Dump(ddgi(search_level+1)))
                        v.parent_call_info = ddgi(search_level+1) -- To catch tailcalls
                    end
                elseif v.parent_call_info then
                    --print("Out")
                    if v.backfunc then
                        v.backfunc()
                    end
                end
                i = i - 1
            end
        else
            -- Check if the function is returning (Breaks if we do multiple callstrees on a recursive function ?)
            local i = CallsTreeCount
            while (i > 0 and Modularity.CallsTreeInProgress[i]) do
                local v = Modularity.CallsTreeInProgress[i]
                if v.backfunc then
                    if info.func == v.func then
                        v.backfunc()
                    end

                    -- With tailcalls we need to look when the last tailcall at the root of the tailcalls table returns, that means the parent call returns too
                    local tc_count = #v.returned.tailcalls
                    if tc_count > 0 then
                        local ltc_f = v.returned.tailcalls[tc_count].info.func
                        if (ltc_f and ltc_f == info.func) then
                            --print("tailcall return")
                            v.backfunc()
                        end
                    end
                end

                i = i - 1 -- Yeah i've put this in the if and got infinite loop, pyramid are still stonks
            end
        end
    end

    --Console.Log("____________________")
end, "cr")

debug.getinfo = function(level, ...)
    if type(level) == "number" then
        return ddgi(level + alter_debug_funcs_with_levels_offset, ...)
    else
        return ddgi(level, ...)
    end
end

local default_debug_getlocal = debug.getlocal
debug.getlocal = function(level, ...)
    if type(level) == "number" then
        return default_debug_getlocal(level + alter_debug_funcs_with_levels_offset, ...)
    else
        return default_debug_getlocal(level, ...)
    end
end

local _main_thread = coroutine.running()
local default_sethook = debug.sethook
debug.sethook = function(callback, mask, count, from_prev, ...)
    if (callback == nil) then
        if not from_prev then
            local info = debug.getinfo(2, "S")
            --print("No callback sethook", NanosTable.Dump(info))
            Modularity.DebugHooks[Modularity.GetStringBeforeFirstSlash(info.source)] = nil
        end
    elseif (type(callback) == "function" and type(mask) == "string") then
        local info = debug.getinfo(2, "S")
        --print("sethook", NanosTable.Dump(info))
        if string.find(mask, "l") then
            Console.Warn("Cannot provide lines debug hook")
        else
            local c = string.find(mask, "c")
            local r = string.find(mask, "r")
            if (c or r) then
                if not count then
                    count = 0
                end
                local ccur_count = 0
                if r then
                   ccur_count = 1 -- To avoid return from this function from being called in tha hook
                end
                Modularity.DebugHooks[Modularity.GetStringBeforeFirstSlash(info.source)] = {
                    c = c,
                    r = r,
                    callback = callback,
                    count_reset = count,
                    count = ccur_count,
                }
            end
        end
    elseif (type(callback) == "thread" and callback ~= _main_thread) then
        return default_sethook(callback, mask, count, from_prev, ...)
    end
end
debug.sethook(cur_debughook_callback, cur_mask, cur_count, true)


local function _HookFuncPName(forced_host_package_name)
    local p_name = forced_host_package_name
    if not p_name then
        p_name = Modularity.GetCallingPackageName(4)
    end
    p_name = p_name or "unknown"
    return p_name
end

local function _RefHook(p_name, tbl, func, called_func, alter_args, pass_call_level, pass_args_info, args_passed)
    if (func and called_func and type(func) == "function" and type(called_func) == "function" and func ~= called_func) then
        if not tbl[p_name] then
            tbl[p_name] = {}
        end
        if not tbl[p_name][func] then
            tbl[p_name][func] = {}
        end
        --print("_RefHook", p_name)
        table.insert(tbl[p_name][func], {called_func, alter_args, pass_call_level, pass_args_info, args_passed})
        _FunctionsThatAreHooked[func] = true
        return called_func
    else
        error("Wrong arguments on RefHook")
    end
end

---🟨 `Shared`
---
---Registers a new PreHook that will call called_func right before func is called outside of hooks or coroutine
---@param func function
---@param called_func function Also passes parameters about the lua call inside
---@param alter_args? boolean|nil Does return values of the called_func will affect variables passed values (only values do not return more or call_level if it is passed)
---@param pass_call_level? boolean|nil Pass the call level to getinfo about the current lua call as first param to called_func
---@param pass_args_info? boolean|nil Pass parameters as tables with more information about them
---@param forced_host_package_name? string|nil If automatic package name guess fails or if you want to associate the hook with a package
---@return function called_func
function Modularity.PreHook(func, called_func, alter_args, pass_call_level, pass_args_info, forced_host_package_name)
    return _RefHook(_HookFuncPName(forced_host_package_name), Modularity.PreHooks, func, called_func, alter_args, pass_call_level, pass_args_info)
end

---🟨 `Shared`
---
---Registers a new EndHook that will call called_func when func is returning outside of hooks or coroutine
---@param func function
---@param called_func function Also passes parameters about the lua call inside
---@param args_passed E_EndHookParams Which arguments from the stack are passed. If alter_args is used, only return stuff passed in the same order to affect them
---@param alter_args? boolean|nil Does return values of the called_func will affect variables passed values (only values do not return more or call_level if it is passed)
---@param pass_call_level? boolean|nil Pass the call level to getinfo about the current lua call as first param to called_func
---@param pass_args_info? boolean|nil Pass parameters as tables with more information about them
---@param forced_host_package_name? string|nil If automatic package name guess fails or if you want to associate the hook with a package
---@return function called_func
function Modularity.EndHook(func, called_func, args_passed, alter_args, pass_call_level, pass_args_info, forced_host_package_name)
    args_passed = args_passed or Modularity.Enums.EndHookParams.CallAndReturnParams
    return _RefHook(_HookFuncPName(forced_host_package_name), Modularity.EndHooks, func, called_func, alter_args, pass_call_level, pass_args_info, args_passed)
end

local function _NameHook(p_name, tbl, func_name, called_func, package_name, alter_args, pass_call_level, pass_args_info, args_passed)
    if (func_name and called_func and type(func_name) == "string" and type(called_func) == "function") then
        if not tbl[p_name] then
            tbl[p_name] = {}
        end
        if not tbl[p_name][func_name] then
            tbl[p_name][func_name] = {}
        end
        table.insert(tbl[p_name][func_name], {called_func, alter_args, pass_call_level, pass_args_info, args_passed, package_name})
        _FunctionsThatAreHooked[func_name] = true
        return called_func
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(2, "n").name)
    end
end

---🟨 `Shared`
---
---Registers a new PreHook that will call called_func right before func is called outside of hooks or coroutine
---@param func_name function
---@param called_func function Also passes parameters about the lua call inside
---@param alter_args? boolean|nil Does return values of the called_func will affect variables passed values (only values do not return more or call_level if it is passed)
---@param pass_call_level? boolean|nil Pass the call level to getinfo about the current lua call as first param to called_func
---@param pass_args_info? boolean|nil Pass parameters as tables with more information about them
---@param forced_host_package_name? string|nil If automatic package name guess fails or if you want to associate the hook with a package
---@return function called_func
function Modularity.PreHookName(func_name, called_func, package_name, alter_args, pass_call_level, pass_args_info, forced_host_package_name)
    return _NameHook(_HookFuncPName(forced_host_package_name), Modularity.PreHooksName, func_name, called_func, package_name, alter_args, pass_call_level, pass_args_info)
end

---🟨 `Shared`
---
---Registers a new EndHook that will call called_func when func is returning outside of hooks or coroutine
---@param func_name function
---@param called_func function Also passes parameters about the lua call inside
---@param args_passed E_EndHookParams Which arguments from the stack are passed. If alter_args is used, only return stuff passed in the same order to affect them
---@param alter_args? boolean|nil Does return values of the called_func will affect variables passed values (only values do not return more or call_level if it is passed)
---@param pass_call_level? boolean|nil Pass the call level to getinfo about the current lua call as first param to called_func
---@param pass_args_info? boolean|nil Pass parameters as tables with more information about them
---@param forced_host_package_name? string|nil If automatic package name guess fails or if you want to associate the hook with a package
---@return function called_func
function Modularity.EndHookName(func_name, called_func, args_passed, package_name, alter_args, pass_call_level, pass_args_info, forced_host_package_name)
    args_passed = args_passed or Modularity.Enums.EndHookParams.CallAndReturnParams
    return _NameHook(_HookFuncPName(forced_host_package_name), Modularity.EndHooksName, func_name, called_func, package_name, alter_args, pass_call_level, pass_args_info, args_passed)
end


local function _ModularityUnHookWithHookTables(HookTables, func_or_func_name, called_func)
    for i, v in ipairs(HookTables) do
        for h_p_name, _ in pairs(v) do
            if v[h_p_name][func_or_func_name] then
                local i2 = 1
                while v[h_p_name][func_or_func_name][i2] do
                    v2 = v[h_p_name][func_or_func_name][i2]
                    if (v2 and v2[1] == called_func) then
                        table.remove(v[h_p_name][func_or_func_name], i2)
                    else
                        i2 = i2 + 1
                    end
                end
                if i2 == 1 then
                    v[h_p_name][func_or_func_name] = nil
                end
            end
        end
    end
    return true
end

---🟨 `Shared`
---
---Removes a hook
---@param func_or_func_name function|string
---@param called_func function
---@return boolean success
function Modularity.UnHook(func_or_func_name, called_func)
    if (func_or_func_name and called_func and type(called_func) == "function") then
        if type(func_or_func_name) == "function" then
            return _ModularityUnHookWithHookTables({Modularity.PreHooks, Modularity.EndHooks}, func_or_func_name, called_func)
        elseif type(func_or_func_name) == "string" then
            return _ModularityUnHookWithHookTables({Modularity.PreHooksName, Modularity.EndHooksName}, func_or_func_name, called_func)
        else
            error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

---🟨 `Shared`
---
---Returns a table containing all Hooks tables
---@return table[] HookTables
function Modularity.GetHooksTables()
    return {Modularity.PreHooks, Modularity.EndHooks, Modularity.PreHooksName, Modularity.EndHooksName}
end