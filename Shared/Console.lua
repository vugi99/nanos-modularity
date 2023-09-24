
local default_package_console_alias = true


local default_Console_I_funcs = {}

local function _ModularityMakeConsolePrehook(f_name)
    if (_G.Console_I and type(_G.Console_I[f_name]) == "function") then
        default_Console_I_funcs[f_name] = _G.Console_I[f_name]
    else
        Console.Error("Modularity : Missing Console_I " .. f_name)
    end
    if _G.Console[f_name] then
        local void_this_log_and_repair = function(...)
            _G.Console_I[f_name] = default_Console_I_funcs[f_name]
            return ...
        end

        Modularity.PreHook(_G.Console[f_name], function(level, str, ...)
            local info = debug.getinfo(level + 1, "S")
            if (info and info.source) then
                local p_name = Modularity.GetStringBeforeFirstSlash(info.source)
                local ret = Modularity.CallEvent("AttemptConsoleLog", str, f_name)
                local drop
                if ret then
                    for f, v in pairs(ret) do
                        for _, v2 in ipairs(v) do
                            if v2[1] == false then
                                drop = true
                                break
                            end
                        end
                        if drop then
                            break
                        end
                    end
                end
                if not drop then
                    if (p_name and p_name ~= "=[C]" and (not string.find(p_name, "INTERNAL"))) then
                        if (Modularity.PackagesConsoleAliases[p_name] ~= false and (Modularity.PackagesConsoleAliases[p_name] or default_package_console_alias)) then
                            local alias = p_name
                            if Modularity.PackagesConsoleAliases[p_name] ~= nil then
                                alias = Modularity.PackagesConsoleAliases[p_name]
                            end
                            if type(str) == "string" then
                                str = "[" .. alias .. "]: " .. str
                            end
                        end
                    end
                else
                    _G.Console_I[f_name] = void_this_log_and_repair
                end
            end
            return str, ...
        end, true, true)
    end
end

if (_G.Console) then
    _ModularityMakeConsolePrehook("Log")
    _ModularityMakeConsolePrehook("Warn")
    _ModularityMakeConsolePrehook("Error")
else
    Console.Error("Modularity : Missing Console or Console_I in _G")
end

---🟨 `Shared`
---
---Register a new package alias to for the prefix when logging in this package
---@param p_name string Package Name
---@param alias string|boolean put false to remove logging prefix
---@return boolean|nil success
function Modularity.RegisterPackageConsoleAlias(p_name, alias)
    if (p_name and type(p_name) == "string") then
        Modularity.PackagesConsoleAliases[p_name] = tostring(alias)
        return true
    end
end
Modularity.RegisterPackageConsoleAlias(Package.GetName(), "Modularity")

---🟨 `Shared`
---
---Will remove completely console logs prefix.
---
---You should only use that if you have a global logging system doing prefixes instead. <br>
---@see Modularity.RegisterPackageConsoleAlias to remove prefix for a specific package
---@param enable boolean|nil
---@return boolean success
function Modularity.EnableDefaultPackageConsoleAlias(enable)
    default_package_console_alias = enable
    return true
end