


local function _ModularityTryLoadingFile_W_Convention(host_p_name, path, env)
    if File.Exists("Packages/" .. path) then
        local file = File("Packages/" .. path)
        if (file and file:IsGood()) then
            local f, error_message = load(file:Read(0), host_p_name .. "/../" .. path, "bt", env)
            --print("Loaded", path)
            if f then
                return f()
            else
                error("Error when loading " .. path .. " : " .. tostring(error_message))
            end
        end
    end
end


for k, v in pairs(debug.getregistry().classes) do
    if v.__name == "Package_S" then

        local def_require = v.__function.Require
        v.__function.Require = function(ent, path, ...)
            --print("Require Overwritten", path)
            -- If a package name is found within the first slash, we mark it as package_injection and force the source we want : (host_p_name/../injected_p_name/...)
            if type(path) == "string" then
                local host_p_name = Modularity.GetCallingPackageName(3)
                --print("host_p_name", host_p_name)
                if (host_p_name and host_p_name ~= "=[C]" and (not string.find(host_p_name, "INTERNAL"))) then
                    local env = Modularity.GetENVFromPName(host_p_name)
                    if env then
                        local split_slash = Modularity.split_str(path, "/")
                        if split_slash[2] then
                            local injected_p_name = split_slash[1]
                            if File.Exists("Packages/" .. injected_p_name) then
                                if injected_p_name ~= host_p_name then -- If it's the same then it's not package injection, just a weird Require
                                    local ret = _ModularityTryLoadingFile_W_Convention(host_p_name, path, env)
                                    if ret then
                                        return ret
                                    end
                                end
                            end
                        end

                        local info = debug.getinfo(2, "S")
                        if (info and info.source) then
                            local split_slash_calling = Modularity.split_str(info.source, "/")
                            if (split_slash_calling[4] and split_slash_calling[2] == "..") then -- Source convention detected
                                --[[
                                    We currently support 5 searchers, which are looked in the following order:
                                        Relative to current-file-path/
                                        Relative to current-package/Client/ or current-package/Server/ (depending on your side)
                                        Relative to current-package/Shared/
                                        Relative to current-package/
                                        Relative to Packages/
                                ]]--

                                local ret = _ModularityTryLoadingFile_W_Convention(host_p_name, table.concat(split_slash_calling, "/", 3, ((#split_slash_calling)-1)) .. "/" .. path, env)
                                if ret then
                                    return ret
                                end

                                ret = _ModularityTryLoadingFile_W_Convention(host_p_name, split_slash_calling[3] .. "/" .. Modularity.GetSide() .. "/" .. path, env)
                                if ret then
                                    return ret
                                end

                                ret = _ModularityTryLoadingFile_W_Convention(host_p_name, split_slash_calling[3] .. "/Shared/" .. path, env)
                                if ret then
                                    return ret
                                end

                                ret = _ModularityTryLoadingFile_W_Convention(host_p_name, split_slash_calling[3] .. "/" .. path, env)
                                if ret then
                                    return ret
                                end

                                -- Last case should be handled above
                                --[[ret = _ModularityTryLoadingFile_W_Convention(host_p_name, path, env)
                                if ret then
                                    return ret
                                end]]--
                            end
                        end
                    end
                end
            end
            return def_require(ent, path, ...)
        end
    end
end