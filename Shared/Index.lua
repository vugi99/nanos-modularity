
--Console.Log("RAM Used : " .. tostring(collectgarbage("count")) .. "KB")


if not debug.getregistry().environments then
    Console.Error("Modularity : missing registry environments, some stuff won't work")
end


Modularity = {
    CompressionLibs = {},

    DataLibs = {},

    Enums = {
        ---@enum E_DownloadServerFileCompressionSetting
        DownloadServerFileCompressionSetting = {
            NoCompression = 1,
            LZWCompression = 2,
            DeflateCompression = 3,
            ZlibCompression = 4,
            Base64Compression = 5,
        },

        ---@enum E_EndHookParams
        EndHookParams = {
            NoParams = 1,
            CallParams = 2,
            ReturnParams = 3,
            CallAndReturnParams = 4,
        },
    },

    print_debug_info = {false, false},

    nil_placeholder = {}, -- Unique address for == comparison

    Default_Configs = {
        Compression = {},
    },

    Envs = {},
    PreHooks = {},
    EndHooks = {},
    PreHooksName = {},
    EndHooksName = {},

    Packages_Unload_Callbacks = {},

    PackagesNativeEventsSystemsSubscribes = {},

    PackagesNotFullEvents = {},

    OverwrittenDefaultFunctions = {},

    InstancesData = {},

    InstancesValuesKeys = {},

    AttachedEventSystems = {},

    ClassLinks = {},

    GlobalSubscribesClasslinks = {},

    NativeCallsCompression = {},

    DebugHooks = {},

    DownloadWhitelistedPrefixes = {},

    CallsTreeInProgress = {},

    PackagesConsoleAliases = {},

    AssetPacks = {
        _loaded = false,
    }
}
Package.Export("Modularity", Modularity)
if Server then
    Modularity.cache_path = "Packages/" .. Package.GetName() .. "/.modularity_cache"
else
    Modularity.cache_path = ".modularity_cache"
end
Modularity.cache_data_path = Modularity.cache_path .. "/" .. "mcache_data.json"









Package.Require("libs/lzw.lua")
Modularity.CompressionLibs.LZW = LZW

Package.Require("libs/LibDeflate.lua")
Modularity.CompressionLibs.LibDeflate = LibDeflate

Package.Require("libs/base64.lua")
Modularity.CompressionLibs.Base64 = base64

Package.Require("libs/toml.lua")
Modularity.DataLibs.TOML = TOML

Package.Require("Config.lua")
Package.Require("Deprecated.lua")
Package.Require("Sh_Funcs.lua")

Modularity.Enums.EndHookParams._count = Modularity.table_count(Modularity.Enums.EndHookParams)

Package.Require("Hooks.lua")
Package.Require("Events_System.lua")
Package.Require("NativeEvents.lua")
Package.Require("Envs.lua")
Package.Require("Funcs_Overwrites.lua")
Package.Require("Instances_Storing.lua")
Package.Require("Package_Injection.lua")
Package.Require("Local_Variables.lua")
Package.Require("Classes/MGroup.lua")
Package.Require("Duplicate.lua")
Package.Require("Console.lua")
Package.Require("Classes/MBaseStaticClass.lua")
Package.Require("Classes/MBaseScopeEntityClass.lua")
Package.Require("Classes/MBaseEntityClass.lua")
Package.Require("Classes/MBaseSyncedEntityClass.lua")



print("Modularity " .. Package.GetVersion() .. " Loaded")

--print(NanosTable.Dump(table.unpack({n=0}, 1, 0))) -- Returns nil, could lead to some issues