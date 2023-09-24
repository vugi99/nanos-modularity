

---🟨 `Shared`
---
---Initialize Deprecated system on the table
---@param class table
---@return boolean|nil success
function Modularity.AttachDeprecatedSystem(class)
    if class then
        local meta = getmetatable(class)
        if not meta then
            setmetatable(class, {})
            meta = getmetatable(class)
        end
        if not meta then
            return error("Cannot set the metatable on the class")
        end
        class.__Deprecated = {}
        --print(meta.__index)
        local def_index = meta.__index or function(t, k)
            return rawget(t, k)
        end
        meta.__index = function(t, key)
            local v = def_index(t, key)
            --print(t, key, v)
            if v ~= nil then
                return v
            else
                local __Deprecated = def_index(t, "__Deprecated")
                if __Deprecated then
                    local dk = __Deprecated[key]
                    if dk ~= nil then
                        v = dk.value
                        if dk.new then
                            Console.Warn("Accessing Deprecated key : " .. tostring(key) .. ", please use " .. tostring(dk.new) .. " instead")
                        else
                            Console.Warn("Accessing Deprecated key : " .. tostring(key))
                        end
                        return dk.value
                    end
                end
            end
        end
        return true
    else
        error("Wrong arguments")
    end
end

---🟨 `Shared`
---
---Adding a deprecated key to a table that has the deprecated system initialized
---@param class table
---@param key string old key
---@param value any value to redirect to
---@param new_key? string to display in the Warn message @(Default: nil)
---@return boolean|nil success
function Modularity.AddClassDeprecatedKey(class, key, value, new_key)
    if (class and key and value ~= nil and type(key) == "string") then
        if class.__Deprecated then
            class.__Deprecated[key] = {
                value = value,
                new = new_key,
            }
            return true
        end
    else
        error("Wrong arguments")
    end
end


Modularity.AttachDeprecatedSystem(Modularity)