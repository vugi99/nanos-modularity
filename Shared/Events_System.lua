


local _Modularity_MakeEventSystem_Functions = {
    static = {
        Subscribe = function(class)
            return function(event_name, callback)
                --print("Subscribe", event_name, callback)
                if ((event_name and type(event_name) == "string" and callback and type(callback) == "function")) then
                    local info = debug.getinfo(2, "S")

                    if (info and info.source) then
                        local p_name = Modularity.GetStringBeforeFirstSlash(info.source)
                        if not Modularity.AttachedEventSystems[class][p_name] then
                            Modularity.AttachedEventSystems[class][p_name] = {}
                        end
                        if not Modularity.AttachedEventSystems[class][p_name][event_name] then
                            Modularity.AttachedEventSystems[class][p_name][event_name] = {}
                        end
                        --print(NanosTable.Dump(Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"]))
                        if not Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"] then
                            Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"] = {}
                        end
                        if Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"][callback] then
                            Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"][callback] = Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"][callback] + 1
                        else
                            --print("NewSubscribe", p_name, event_name, "INDEPENDENT_SUBS", callback)
                            Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"][callback] = 1
                        end
                        return callback
                    else
                        error("Cannot get calling package name")
                    end
                else
                    error("Wrong arguments on Modularity Static Class Subscribe")
                end
            end
        end,

        Unsubscribe = function(class)
            return function(event_name, callback)
                if (event_name and type(event_name) == "string") then
                    --print("Unsubscribe", event_name, callback)
                    if callback then
                        for p_name, v in pairs(Modularity.AttachedEventSystems[class]) do
                            if Modularity.AttachedEventSystems[class][p_name][event_name] then
                                if Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"] then
                                    if Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"][callback] then
                                        Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"][callback] = nil
                                    end
                                end
                            end
                        end
                        return true
                    else
                        for p_name, v in pairs(Modularity.AttachedEventSystems[class]) do
                            if Modularity.AttachedEventSystems[class][p_name][event_name] then
                                Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"] = nil
                            end
                        end
                        return true
                    end
                else
                    error("Wrong arguments on Modularity Static Class Unsubscribe")
                end
            end
        end,

        CallEvent = function(class)
            return function(event_name, ...)
                if (event_name and type(event_name) == "string") then
                    --print("CallEvent", event_name, ...)
                    local returns = {}
                    for p_name, v in pairs(Modularity.AttachedEventSystems[class]) do
                        if Modularity.AttachedEventSystems[class][p_name][event_name] then
                            --print(event_name, NanosTable.Dump(Modularity.AttachedEventSystems[class][event_name]))
                            if Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"] then
                                --print(NanosTable.Dump(Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"]))
                                for f, v2 in pairs(Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"]) do
                                    --print(f, v2)
                                    if (type(f) == "function" and type(v2) == "number") then
                                        if not returns[f] then
                                            returns[f] = {}
                                        end
                                        for _ = 1, v2 do
                                            --print("CALLING", f)
                                            if Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"][f] then -- For When it's unsubscribed inside the same subs
                                                table.insert(returns[f], table.pack(f(...)))
                                                --f(...)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    return returns
                else
                    error("Wrong arguments on Modularity Static Class CallEvent")
                end
            end
        end,
    },

    instance = {
        Subscribe = function(class)
            return function(ent, event_name, callback)
                if (ent and event_name and type(event_name) == "string" and callback and type(callback) == "function") then
                    local info = debug.getinfo(2, "S")

                    if (info and info.source) then
                        local p_name = Modularity.GetStringBeforeFirstSlash(info.source)
                        if not Modularity.AttachedEventSystems[class][p_name] then
                            Modularity.AttachedEventSystems[class][p_name] = {}
                        end
                        if not Modularity.AttachedEventSystems[class][p_name][event_name] then
                            Modularity.AttachedEventSystems[class][p_name][event_name] = {}
                        end
                        if not Modularity.AttachedEventSystems[class][p_name][event_name][ent] then
                            Modularity.AttachedEventSystems[class][p_name][event_name][ent] = {}
                        end
                        if Modularity.AttachedEventSystems[class][p_name][event_name][ent][callback] then
                            Modularity.AttachedEventSystems[class][p_name][event_name][ent][callback] = Modularity.AttachedEventSystems[class][p_name][event_name][ent][callback] + 1
                        else
                            Modularity.AttachedEventSystems[class][p_name][event_name][ent][callback] = 1
                        end
                        return callback
                    else
                        error("Cannot get calling package name")
                    end
                else
                    error("Wrong arguments on Modularity Instanced Class Subscribe")
                end
            end
        end,

        Unsubscribe = function(class)
            return function(ent, event_name, callback)
                if ent then
                    if not event_name then -- Handling of Unsubscribes on instances have to be handled by script by calling instance:Unsubscribe()
                        for p_name, _ in pairs(Modularity.AttachedEventSystems[class]) do
                            for ev_name, v in pairs(Modularity.AttachedEventSystems[class][p_name]) do
                                if v[ent] then
                                    Modularity.AttachedEventSystems[class][p_name][ev_name][ent] = nil
                                end
                            end
                        end
                        return true
                    end
                    if callback then
                        for p_name, _ in pairs(Modularity.AttachedEventSystems[class]) do
                            if Modularity.AttachedEventSystems[class][p_name][event_name] then
                                if Modularity.AttachedEventSystems[class][p_name][event_name][ent] then
                                    if Modularity.AttachedEventSystems[class][p_name][event_name][ent][callback] then
                                        Modularity.AttachedEventSystems[class][p_name][event_name][ent][callback] = nil
                                    end
                                end
                            end
                        end
                        return true
                    else
                        for p_name, _ in pairs(Modularity.AttachedEventSystems[class]) do
                            if Modularity.AttachedEventSystems[class][p_name][event_name] then
                                Modularity.AttachedEventSystems[class][p_name][event_name][ent] = nil
                            end
                        end
                        return true
                    end
                else
                    error("Wrong arguments on Modularity Instance Class Unsubscribe")
                end
            end
        end,

        CallEvent = function(class)
            return function(ent, event_name, ...)
                if (ent and event_name and type(event_name) == "string") then
                    local returns = {}
                    for p_name, _ in pairs(Modularity.AttachedEventSystems[class]) do
                        if Modularity.AttachedEventSystems[class][p_name][event_name] then
                            if Modularity.AttachedEventSystems[class][p_name][event_name][ent] then
                                for f, v2 in pairs(Modularity.AttachedEventSystems[class][p_name][event_name][ent]) do
                                    if (type(f) == "function" and type(v2) == "number") then
                                        if not returns[f] then
                                            returns[f] = {}
                                        end
                                        for _ = 1, v2 do
                                            if Modularity.AttachedEventSystems[class][p_name][event_name][ent][f] then -- For When it's unsubscribed inside the same subs
                                                table.insert(returns[f], table.pack(f(ent, ...)))
                                            end
                                        end
                                    end
                                end
                            end
                            if Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"] then
                                for f, v2 in pairs(Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"]) do
                                    if (type(f) == "function" and type(v2) == "number") then
                                        if not returns[f] then
                                            returns[f] = {}
                                        end
                                        for _ = 1, v2 do
                                            if Modularity.AttachedEventSystems[class][p_name][event_name]["INDEPENDENT_SUBS"][f] then -- For When it's unsubscribed inside the same subs
                                                table.insert(returns[f], table.pack(f(ent, ...)))
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    return returns
                else
                    error("Wrong arguments on Modularity Instance Class CallEvent")
                end
            end
        end,
    },
}


local function _Modularity_Attach_EventSystem_Internal(ES_Builder_Functions, class, static_class)
    if not Modularity.AttachedEventSystems[class] then
        Modularity.AttachedEventSystems[class] = {}
    end
    for k, v in pairs(ES_Builder_Functions) do
        if static_class then
            class[k] = v(static_class)
        else
            class[k] = v(class)
        end
    end
end

---🟨 `Shared`
---
---Attach a static event system
---@param class table
---@return boolean|nil success
function Modularity.AttachStaticEventSystem(class)
    if (class) then
        _Modularity_Attach_EventSystem_Internal(_Modularity_MakeEventSystem_Functions.static, class)
        return true
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

---🟨 `Shared`
---
---Attach an instance event system
---@param class table
---@param static_class table To link it in the events
---@return boolean|nil success
function Modularity.AttachInstanceEventSystem(class, static_class)
    if (class and static_class) then
        _Modularity_Attach_EventSystem_Internal(_Modularity_MakeEventSystem_Functions.instance, class, static_class)
        return true
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

Modularity.AttachStaticEventSystem(Modularity)