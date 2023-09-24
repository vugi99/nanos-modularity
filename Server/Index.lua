

---🟦 `Server`
---
---Will reload all packages except Modularity to be aware of everything (eg: Events spy)
---@return boolean reloading Does packages are going to be reloaded
function Modularity.MakeAware()
    --print(Modularity.table_count(Modularity.PackagesNotFullEvents))
    if Modularity.table_count(Modularity.PackagesNotFullEvents) > 1 then
        Timer.SetTimeout(function()
            --Modularity.PackagesNotFullEvents = {[Package.GetName()] = true}
            --Events.BroadcastRemote("Modularity_UpdatePackagesNotFullEvents_Client", Modularity.PackagesNotFullEvents)
            for k, v in pairs(Server.GetPackages(true)) do
                if v.name ~= Package.GetName() then
                    Server.ReloadPackage(v.name)
                    --Modularity.RemoveEventsOfPackage(v.name)
                    --Events.BroadcastRemote("Modularity_RemoveEventsOfPackage", v.name)
                end
            end
            --print(NanosTable.Dump(Modularity.PackagesNotFullEvents))
        end, 1)
        return true
    else
        Console.Warn("Modularity already has the access to all events")
    end
    return false
end
Modularity.AddClassDeprecatedKey(Modularity, "AccessAllEvents", Modularity.MakeAware, "MakeAware")

Package.Require("Download.lua")
Package.Require("sv_Duplicate.lua")
Package.Require("HTTP.lua")
Package.Require("Require.lua")
Package.Require("sv_Assets.lua")
Package.Require("Classes/sv_MBaseSyncedEntity.lua")