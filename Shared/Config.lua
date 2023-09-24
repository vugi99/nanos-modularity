

Downloading_File_Chunk_Bytes = 1000
Downloading_Max_Chunks_Sent_Per_Tick_Mult_Inv_ds = 5 -- (1/ds) * value






Native_Events_Systems_Unsub_Functions = {
    Unsubscribe = {
        event_name_param_index = 1,
        callback_param_index = 2,
    },
    Unbind = {
        event_name_param_index = 1,

        ordered_uids = {
            "2"
        },
        other_params_uids = {
            ["2"] = 2,
        },
    }
}

Native_Events_Systems_Sub_Functions = {
    Subscribe = {
        Class = "*",
        event_name_param_index = 1,
        callback_param_index = 2,

        OnInstance = true,
        Unsub_Func = "Unsubscribe",
    },
    SubscribeRemote = {
        Class = "*",
        event_name_param_index = 1,
        callback_param_index = 2,

        OnInstance = true,
        Unsub_Func = "Unsubscribe",
    },
    Bind = {
        Class = "Input_S",

        StaticFunctionsInReg = true,

        event_name_param_index = 1,
        callback_param_index = 3,

        other_params_uids = { -- Params required to identify a subscribe
            ["2"] = 2, -- UID : param_index
        },

        ordered_uids = {
            "2"
        },

        Unsub_Func = "Unbind",
    },
    RegisterCommand = {
        Class = "Console_I",
        event_name_param_index = 1,
        callback_param_index = 2,

        info_params = { -- Params giving additional info about the subscribe, but not required to 'identify' a subscribe
            {name = "description", index = 3},
            {name = "parameters", index = 4},
        }
    }
}


local _local_call_compression_config = {
    call_func_name = "Call",
    params_starting_index = 2,
    event_name_param_index = 1,
}

local _remote_compression_config = {
    call_func_name = "CallRemote",
    params_starting_index = 2,
    event_name_param_index = 1,
}

if Server then
    _remote_compression_config.params_starting_index = 3
end


Modularity.Default_Configs.Compression.AllLocal = {
    Events = {
        _local_call_compression_config,
    }
}
Modularity.Default_Configs.Compression.AllRemote = {
    Events = {
        _remote_compression_config,
    }
}

Modularity.Default_Configs.Compression.All = {
    Events = {
        _remote_compression_config,
        _local_call_compression_config,
    }
}

Native_Events_Systems_Call_Functions = {
    Call = {
        Class = "Events",
        SubFuncKey = "Subscribe",
        event_name_param_index = 1,

        OnInstance = false,
    },
}


API_Needed_Paths_Prefix = {
    Classes = 0,
}
for k, v in pairs(API_Needed_Paths_Prefix) do
    API_Needed_Paths_Prefix[k] = string.len(k)
end


URL_Github_API = "https://api.github.com"
URL_Github_Raw = "https://raw.githubusercontent.com"