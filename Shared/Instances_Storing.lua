


-- Storing data on instances code (Inherited classes seems to work... Handled by the game itself i guess with default table values thing)
if debug.getregistry().classes then
    for k, v in pairs(debug.getregistry().classes) do
        local meta = getmetatable(v)
        if (meta and meta.__call) then -- Does the class can be instanced
            --print(v.__index)
            --print(v.__newindex)

            if _G[v.__name].Subscribe then
                _G[v.__name].Subscribe("Destroy", function(ent)
                    Modularity.InstancesData[ent] = nil
                end)
            end

            local default_index = v.__index
            if not default_index then
                default_index = function() end
            end
            v.__index = function(t, key, ...)
                --print("Instance __index", t, key)
                if (debug.getinfo(2, "S").what == "Lua" and Modularity.InstancesData[t] and Modularity.InstancesData[t][key] ~= nil) then -- Make sure that this call doesn't come from C before doing what we want
                    local def_index_ret = default_index(t, key, ...)
                    if def_index_ret == nil then
                        if Modularity.InstancesData[t] then
                            return Modularity.InstancesData[t][key]
                        end
                    else
                        return def_index_ret
                    end
                else
                    return default_index(t, key, ...)
                end
            end
            local default_newindex = v.__newindex
            if not default_newindex then
                default_newindex = function() end
            end
            v.__newindex = function(t, key, value, ...)
                --print("v.__newindex", v.__name, t, key, value)
                default_newindex(t, key, value, ...)
                if (key and type(key == "string")) then
                    if not Modularity.InstancesData[t] then
                        Modularity.InstancesData[t] = {}
                    end
                    Modularity.InstancesData[t][key] = value
                end
            end
        end
    end
end




-- SetValue watcher to return table with all stored values 
-- (Already supports inherited classes as it calls parent events/funcs which are already subscribed/hooked)

local function _Modularity_MakeSetValuePreHook(_ent)
    local offset = 1
    if _ent then
        offset = 0
    end

    return function(...)
        local args = {...}
        local ent = args[1]
        if _ent then
            ent = _ent
        end
        local key = args[1+offset]
        local value = args[2+offset]
        local synced = args[3+offset]

        --print("SetValue Hook", ent, key, value, synced)

        if Modularity.GetSide() == "Client" then
            synced = nil
        end
        if (ent and key and type(key) == "string") then
            --print("SetValue", ent, key, value, synced)
            if (not Modularity.InstancesValuesKeys[ent]) then
                Modularity.InstancesValuesKeys[ent] = {}
            end
            if value == nil then
                Modularity.InstancesValuesKeys[ent][key] = nil
            else
                Modularity.InstancesValuesKeys[ent][key] = {
                    sync = synced,
                }
            end
        end
    end
end

local function _ModularityMakeGetValueEndHook(_ent)
    local offset = 1
    if _ent then
        offset = 0
    end

    return function(...)
        local args = {...}
        local ent = args[1]
        if _ent then
            ent = _ent
        end
        local key = args[1+offset]
        local value = args[3+offset]
        local synced = "unknown"

        print(NanosTable.Dump(args))
        print("GetValue Hook", ent, key, value, synced)

        if (ent and key and type(key) == "string") then
            --print("SetValue", ent, key, value, synced)
            if (not Modularity.InstancesValuesKeys[ent]) then
                Modularity.InstancesValuesKeys[ent] = {}
            end
            if value == nil then
                Modularity.InstancesValuesKeys[ent][key] = nil
            elseif (not Modularity.InstancesValuesKeys[ent][key]) then
                --Console.Warn("Discovered new Value on " .. tostring(ent) .. ", key : " .. tostring(key) .. ", value : " .. tostring(value))
                Modularity.InstancesValuesKeys[ent][key] = {
                    sync = synced,
                }
            end
        end
    end
end


if debug.getregistry().classes then
    for k, v in pairs(debug.getregistry().classes) do

        if _G[v.__name] then
            if (v.__function and v.__function.Subscribe and v.__function.SetValue and v.__function.GetValue) then
                local meta = getmetatable(v)
                if (meta and meta.__call) then
                    if (_G[v.__name].Subscribe) then
                        --print(v.__name)

                        _G[v.__name].Subscribe("Destroy", function(ent)
                            Modularity.InstancesValuesKeys[ent] = nil
                        end)

                        Modularity.PreHook(v.__function.SetValue, _Modularity_MakeSetValuePreHook())
                        --Modularity.EndHook(v.__function.GetValue, _ModularityMakeGetValueEndHook(), Modularity.Enums.EndHookParams.CallAndReturnParams)

                        --[[_G[v.__name].Subscribe("ValueChange", function(ent, key, value)
                            if (not Modularity.InstancesValuesKeys[ent]) then
                                Modularity.InstancesValuesKeys[ent] = {}
                            end
                            if value == nil then
                                Modularity.InstancesValuesKeys[ent][key] = nil
                            else
                                Modularity.InstancesValuesKeys[ent][key] = true
                            end
                        end)]]--
                    end
                end
            elseif (_G[v.__name].SetValue and _G[v.__name].GetValue) then -- Server.SetValue
                --print("Static SetValue Hook, ", v.__name)
                Modularity.PreHook(_G[v.__name].SetValue, _Modularity_MakeSetValuePreHook(_G[v.__name]))
                --Modularity.EndHook(_G[v.__name].GetValue, _ModularityMakeGetValueEndHook(_G[v.__name]), Modularity.Enums.EndHookParams.CallAndReturnParams)
            end
        end
    end
end

---🟨 `Shared`
---
---Get Keys of stored values on a nanos entity (SetValue)
---@param ent any
---@return {[string]: {sync: boolean|nil}}|nil keys
function Modularity.GetValuesKeys(ent)
    if ent then
        return Modularity.InstancesValuesKeys[ent]
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end