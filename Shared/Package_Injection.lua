








function Modularity.InjectPackage(source_p_name, target_p_name)
    if (source_p_name and target_p_name and type(source_p_name) == "string" and type("target_p_name") == "string") then
        if Modularity.Envs[target_p_name] then
            if Modularity.IsENVValid(Modularity.Envs[target_p_name]) then
                Modularity.Envs[target_p_name].Package.Require(source_p_name .. "/Shared/Index.lua")
                return true
            end
        end
    else
        error("Wrong arguments on Modularity." .. tostring(debug.getinfo(1, "n").name))
    end
end