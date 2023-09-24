
local function _Modularity_DuplicateTableLocal(tbl, seen, target_tbl)
    seen = seen or {}

    if seen[tbl] then
        return seen[tbl]
    end

    local copy = target_tbl or {}

    local meta = getmetatable(tbl)
    if (meta ~= nil) then
        setmetatable(copy, meta)
    end

    seen[tbl] = copy

    for k, v in pairs(tbl) do
        --print(k, v)
        local k_for_cp = k
        if type(k) == "table" then
            k_for_cp = _Modularity_DuplicateTableLocal(k, seen)
            copy[k] = nil
        end
        if type(v) == "table" then
            copy[k_for_cp] = _Modularity_DuplicateTableLocal(v, seen, copy[k_for_cp])
        else
            copy[k_for_cp] = v
        end
    end

    return copy
end

---🟨 `Shared`
---
---Duplicates a table, copies keys that are tables too, handles cyclic tables and sets the same metatables as the passed table
---@param tbl table
---@return table
function Modularity.DuplicateTable(tbl)
    return _Modularity_DuplicateTableLocal(tbl)
end

function Modularity.DuplicateTableInto(tbl, target_tbl)
    return _Modularity_DuplicateTableLocal(tbl, {}, target_tbl)
end









function Modularity.ApiHasAuthority(tbl, ent)
    if (type(tbl) == "table") then
        if tbl.authority then
            if tbl.authority == "both" then
                return true
            elseif tbl.authority == string.lower(Modularity.GetSide()) then
                return true
            elseif tbl.authority == "network-authority" then
                return true -- Hmh
            elseif tbl.authority == "authority" then
                if Modularity.GetSide() == "Server" then
                    return true
                elseif (ent and ent.HasAuthority and ent:HasAuthority()) then
                    return true
                end
            end
            return false
        else
            error("Missing authority field in table")
        end
    else
        error("Wrong arguments")
    end
end

local function _FindFunctionsWithNameInSubTable(class_api, sub_key, searched_name, searched_type)
    local ret_tbl = {}
    for _, v in ipairs(class_api.functions) do
        if type(v[sub_key]) == "table" then
            --print(sub_key, "found", v.name)
            for i2, v2 in ipairs(v[sub_key]) do
                if v2.name == searched_name then
                    if ((not searched_type) or searched_type == v2.type) then
                        table.insert(ret_tbl, {f_api = v, index = i2})
                        --ret_tbl[v.name] = v
                    end
                end
            end
        end
    end
    --print("_FindFunctionsWithNameInSubTable", sub_key, searched_name, searched_type, NanosTable.Dump(ret_tbl))
    return ret_tbl
end

local function _RemoveEntriesWithKeys(tbl, k, keys)
    local i = 1
    while tbl[i] do
        for _, v in ipairs(keys) do
            local v2
            if k == nil then
                v2 = tbl[i][v]
            else
                v2 = tbl[i][k][v]
            end
            if v2 then
                table.remove(tbl, i)
                i = i - 1
            end
        end
        i = i + 1
    end
end

local function CallAPI_function_WParams(ent, name, params)
    params = params or {n=0}
    if type(ent[name]) == "function" then
        return ent[name](ent, table.unpack(params, 1, params.n))
    else
        error(name .. " is not a valid function on the entity")
    end
end

local function _TryMatchFunctionName(class_api, f_name)
    local partial_match
    for i, v in ipairs(class_api.functions) do
        if type(v.name) == "string" then
            if v.name == f_name then
                return v
            elseif (string.lower(v.name) == string.lower(f_name)) then
                partial_match = v
            end
        end
    end
    return partial_match
end


local function _CheckToAddInheritance(class_api, cur_looked, seen)
    seen = seen or {}
    if not seen[cur_looked] then
        seen[cur_looked] = true
    else
        Console.Warn("Inheritance loop, from " .. tostring(class_api.name))
        return
    end

    if cur_looked.inheritance then
        for i, v in pairs(cur_looked.inheritance) do
            local found_api
            if type(Modularity.API_Files.Classes["Base" .. v .. ".json"]) == "table" then
                found_api = Modularity.API_Files.Classes["Base" .. v .. ".json"]
            elseif type(Modularity.API_Files.Classes[v .. ".json"]) == "table" then
                found_api = Modularity.API_Files.Classes[v .. ".json"]
            end

            if found_api then
                if found_api.functions then
                    local added_inh
                    for i2, v2 in ipairs(found_api.functions) do
                        if v2.name then
                            if not class_api._functions_key_names[v2.name] then
                                table.insert(class_api.functions, v2)
                                class_api._functions_key_names[v2.name] = v2
                                added_inh = true
                            elseif (not added_inh) then
                                Console.Warn("Method collision with inherited functions : " .. v2.name .. " on class " .. classname)
                            end
                        else
                            error("Function doesn't have name key in " .. tostring(found_api.name))
                        end
                    end
                end
                _CheckToAddInheritance(class_api, found_api, seen)
            else
                error("Cannot find (Base)" .. v .. ".json in API_Files for functions inheritance")
            end
        end
    end
end

local function _TryToCallFunction_FindArguments(class_api, ent, new_ent, f_name, f_type, seen)
    local target_ent
    if f_type == "Setter" then
        target_ent = new_ent
    elseif f_type == "Getter" then
        target_ent = ent
    end


    if f_name == nil then
        return
    end

    if not Modularity.ApiHasAuthority(class_api._functions_key_names[f_name], target_ent) then -- If we don't have authority on that one, don't call it
        return
    end


    seen = seen or {} -- Avoid _FindArguments recursion loop
    if seen[f_name] then
        return
    else
        seen[f_name] = true
    end
    local params = {n=0}

    local parameters_api = class_api._functions_key_names[f_name].parameters
    if parameters_api then
        for i, v in ipairs(parameters_api) do
            -- Try to match param with a return of another function
            local found_funcs = _FindFunctionsWithNameInSubTable(class_api, "return", v.name, v.type)
            for i2, v2 in ipairs(found_funcs) do
                local rets = {_TryToCallFunction_FindArguments(class_api, ent, new_ent, v2.f_api.name, "Getter", seen)}
                if rets then
                    params.n = params.n + 1
                    params[params.n] = rets[v2.index]
                    goto continue
                end
            end

            -- Try to find Get Or Is function if call is a Setter
            if f_type == "Setter" then
                if string.sub(f_name, 1, 3) == "Set" then
                    local f_name_wo_set = string.sub(f_name, 4)
                    local found_f_api = _TryMatchFunctionName(class_api, "Get" .. f_name_wo_set)
                    if not found_f_api then
                        found_f_api = _TryMatchFunctionName(class_api, "Is" .. f_name_wo_set)
                    end

                    if found_f_api then
                        local r_index
                        if found_f_api.returns then
                            for i2, v2 in ipairs(found_f_api.returns) do
                                if v2.type == v.type then
                                    r_index = i2
                                    break
                                end
                            end
                        end

                        if r_index then
                            local rets = {_TryToCallFunction_FindArguments(class_api, ent, new_ent, found_f_api.name, "Getter", seen)}
                            params.n = params.n + 1
                            params[params.n] = rets[r_index]
                            goto continue
                        end
                    end
                end
            end

            --return
            if true then return end
            ::continue::
        end
    end

    --print("Call", f_type, f_name, NanosTable.Dump(params))

    --local rets = table.pack(CallAPI_function_WParams(target_ent, f_name, params))
    --print(NanosTable.Dump(rets))
    --return table.unpack(rets, 1, rets.n)
    return CallAPI_function_WParams(target_ent, f_name, params)
end

function Modularity.DuplicateEntity(ent)
    local new_ent
    if type(ent) == "userdata" then
        if Modularity.API_Files then
            if ent.GetClass then
                local ent_class = ent:GetClass()
                if (ent_class) then
                    local classname = ent_class.__name
                    if type(classname) == "string" then
                        --print(classname)
                        if (Modularity.API_Files.Classes) then
                            if type(Modularity.API_Files.Classes[classname .. ".json"]) == "table" then
                                if (Modularity.API_Files.Classes[classname .. ".json"].authority == nil or Modularity.ApiHasAuthority(Modularity.API_Files.Classes[classname .. ".json"])) then
                                    local class_api = Modularity.DuplicateTable(Modularity.API_Files.Classes[classname .. ".json"])

                                    if class_api.functions then
                                        class_api._functions_key_names = {}

                                        for i, v in ipairs(class_api.functions) do
                                            if v.name then
                                                class_api._functions_key_names[v.name] = v
                                            else
                                                error("Function doesn't have name key")
                                            end
                                        end

                                        -- Put inherited function in the same table
                                        _CheckToAddInheritance(class_api, class_api)
                                    end


                                    -- Contructor
                                    if (class_api.constructors and class_api.constructors[1]) then
                                        if class_api.constructors[2] then
                                            Console.Warn("Found another constructor for " .. classname .. ", will choose the first one anyway")
                                        end

                                        local tbl_constructor_params = {n = 0}

                                        if class_api.constructors[1].parameters then
                                            for i, v in ipairs(class_api.constructors[1].parameters) do
                                                if v.name then
                                                    local getters = _FindFunctionsWithNameInSubTable(class_api, "return", v.name, v.type)
                                                    _RemoveEntriesWithKeys(getters, "f_api", {"parameters"}) -- Only direct getters without params for constructor

                                                    if getters[2] then
                                                        Console.Warn("Contructor, found another getter to get " .. v.name)
                                                    end

                                                    if (getters[1] and Modularity.ApiHasAuthority(getters[1].f_api, ent)) then -- Found getter
                                                        local getter_ret = {CallAPI_function_WParams(ent, getters[1].f_api.name)}
                                                        tbl_constructor_params.n = tbl_constructor_params.n + 1
                                                        tbl_constructor_params[tbl_constructor_params.n] = getter_ret[getters[1].index]
                                                    else
                                                        -- Try to match function name with a getter
                                                        local f_api = _TryMatchFunctionName(class_api, "Get" .. v.name)
                                                        if (type(f_api) == "table" and (not f_api.parameters) and Modularity.ApiHasAuthority(f_api, ent)) then -- Only direct getters without params for constructor 
                                                            -- Let's say it returns what we want as first return value

                                                            tbl_constructor_params.n = tbl_constructor_params.n + 1
                                                            tbl_constructor_params[tbl_constructor_params.n] = CallAPI_function_WParams(ent, f_api.name, params)

                                                        elseif type(v.default) == "string" then -- Use default value
                                                            local default_lua = "return " .. v.default
                                                            local loaded_default, error_message = load(default_lua, nil, "bt", _ENV) -- Maybe should set source ?
                                                            if type(loaded_default) == "function" then
                                                                Console.Warn("Using default value : "  .. tostring(v.default) .. " for param " .. v.name .. " (" .. tostring(i) .. ")")

                                                                tbl_constructor_params.n = tbl_constructor_params.n + 1
                                                                tbl_constructor_params[tbl_constructor_params.n] = loaded_default()
                                                            else
                                                                error("Cannot load default " .. default_lua .. " for constructor param " .. v.name .. " (" .. tostring(i) .. "), error : " .. tostring(error_message))
                                                            end
                                                        else
                                                            error("Cannot find constructor parameter " .. v.name .. " (" .. tostring(i) .. ")")
                                                        end
                                                    end
                                                else
                                                    error("Missing name for constructor param " .. tostring(i))
                                                end
                                            end
                                        end

                                        new_ent = ent_class(table.unpack(tbl_constructor_params, 1, tbl_constructor_params.n))
                                        if type(new_ent) == "userdata" then

                                            -- Setters
                                            if class_api.functions then
                                                for i, v in ipairs(class_api.functions) do
                                                    if v.name then
                                                        if v.parameters then
                                                            if string.sub(v.name, 1, 3) == "Set" then
                                                                _TryToCallFunction_FindArguments(class_api, ent, new_ent, v.name, "Setter")
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        else
                                            error("new_ent is invalid")
                                        end
                                    else
                                        error("Missing constructor on this class")
                                    end
                                else
                                    error("You don't have the authority on this entity to spawn it")
                                end


                            else
                                error("Cannot find " .. classname .. ".json in API_Files")
                            end
                        else
                            error("No Modularity.API_Files.Classes")
                        end
                    else
                        error("No classname on this ent_class")
                    end
                else
                    error("Entity class not valid")
                end
            else
                error("No GetClass function on this entity")
            end
        else
            error("API_Files are not loaded to duplicate native entities, wait for API_Files_Loaded event")
        end
    elseif type(ent) == "table" then

    end
    if new_ent ~= nil then
        Modularity.CallEvent("DuplicatedEntity", new_ent)
    end
    return new_ent
end


Modularity.Subscribe("API_Files_Loaded", function()
    local prop = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")

    local dprop = Modularity.DuplicateEntity(prop)

    prop:Destroy()

    if (dprop and dprop.IsValid) then
        if dprop:IsValid() then
            dprop:Destroy()
        end
    end

    local weap = Weapon(Vector(0, 0, 0), Rotator(), "nanos-world::SK_AK47")
    local dweap = Modularity.DuplicateEntity(weap)

    weap:Destroy()

    if (dweap and dweap.IsValid) then
        if dweap:IsValid() then
            dweap:Destroy()
        end
    end
end)