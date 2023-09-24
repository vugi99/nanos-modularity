

Modularity.HTTPRequestAsyncList = {}

local func_callback_param_index = 8

if _G.HTTP then
    if _G.HTTP.RequestAsync then
        Modularity.PreHook(_G.HTTP.RequestAsync, function(...)
            local args = table.pack(...)
            local callback = args[func_callback_param_index]
            if (callback and type(callback) == "function") then
                Modularity.CallEvent("HTTP_NewAsyncRequest", callback)
                if Modularity.HTTPRequestAsyncList[callback] then
                    Modularity.HTTPRequestAsyncList[callback].pending_count = Modularity.HTTPRequestAsyncList[callback].pending_count + 1
                else
                    Modularity.HTTPRequestAsyncList[callback] = {
                        pending_count = 1,
                        args = args,
                    }
                    local hook_func
                    hook_func = function(level, ...)
                        -- This is called from C if there's no info above this call
                        if debug.getinfo(level+1, "n") == nil then
                            if Modularity.HTTPRequestAsyncList[callback] then
                                Modularity.HTTPRequestAsyncList[callback].pending_count = Modularity.HTTPRequestAsyncList[callback].pending_count - 1
                                Modularity.CallEvent("HTTP_Response_Received", callback, ...)
                                if Modularity.HTTPRequestAsyncList[callback].pending_count <= 0 then
                                    Modularity.HTTPRequestAsyncList[callback] = nil
                                    Modularity.UnHook(callback, hook_func)
                                end
                            end
                        end
                    end
                    Modularity.PreHook(callback, hook_func, false, true)
                end
            end
        end)
    end
else
    Console.Error("Missing HTTP in _G")
end