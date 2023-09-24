

---🟨 `Shared`
---
---Returns function used upvalues within it
---@param func function
---@return {name: string, value: any, index: integer}[] local_variables
function Modularity.GetFunctionUsedLocalVariables(func)
    if (type(func) == "function") then
        local localvars = {}
        local _up_i = 1
        local name, value = debug.getupvalue(func, _up_i)
        while name do
            localvars[_up_i] = {name=name, value=value, index=_up_i}
            _up_i = _up_i + 1
            name, value = debug.getupvalue(func, _up_i)
        end
        return localvars
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

---🟨 `Shared`
---
---Sets a function used local variable
---@param func function
---@param index integer
---@param value any
---@return boolean success
function Modularity.SetFunctionUsedLocalVariable(func, index, value)
    if (type(func) == "function" and type(index) == "number" and index%1 == 0) then
        local name, _ = debug.getupvalue(func, index)
        if name then
            debug.setupvalue(func, index, value)
            return true
        else
            error("Local variable doesn't exist at this index")
        end
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end