
local function table_count(tbl)
    local count = 0
    for k, v in pairs(tbl) do count = count + 1 end
    return count
end

function Modularity.AccessAllEvents()
    --print(table_count(Modularity.PackagesNotFullEvents))
    if table_count(Modularity.PackagesNotFullEvents) > 1 then
        Timer.SetTimeout(function()
            Modularity.PackagesNotFullEvents = {[Package.GetName()] = true}
            --Events.BroadcastRemote("Modularity_UpdatePackagesNotFullEvents_Client", Modularity.PackagesNotFullEvents)
            for k, v in pairs(Server.GetPackages(true)) do
                if v.name ~= Package.GetName() then
                    Server.ReloadPackage(v.name)
                    Modularity.RemoveEventsOfPackage(v.name)
                    --Events.BroadcastRemote("Modularity_RemoveEventsOfPackage", v.name)
                end
            end
            --print(NanosTable.Dump(Modularity.PackagesNotFullEvents))
        end, 1)
    else
        Console.Warn("Modularity already has the access to all events")
    end
end