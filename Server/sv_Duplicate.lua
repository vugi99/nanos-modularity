

APICache_AutoUpdate = false

local repo_owner = "nanos-world"
local repo_name = "api"
local repo_branch = "main"

local endpoint_API_Get_Last_Commit = "/repos/" .. repo_owner .. "/" .. repo_name .. "/commits/" .. repo_branch
local endpoint_API_Get_Files_On_Repo = "/repos/" .. repo_owner .. "/" .. repo_name .. "/git/trees/" .. repo_branch .. "?recursive=1"


local waiting_for_files_count = 0
local checking_last_commit = false

local function _LoadJSON_API_Files(tbl, into_tbl)
    for k, v in pairs(tbl) do
        if type(v) == "string" then
            into_tbl[k] = JSON.parse(v)
        elseif type(v) == "table" then
            into_tbl[k] = {}
            _LoadJSON_API_Files(v, into_tbl[k])
        end
    end
end

local function Api_Files_Loaded_Callback(files_tbl)
    Modularity.API_Files = {}
    _LoadJSON_API_Files(files_tbl, Modularity.API_Files)
    Console.Log("API_Files loaded")
    Modularity.CallEvent("API_Files_Loaded", Modularity.API_Files)
end

local function Start_Api_Files_Loading()
    local started = Modularity.LoadFilesInTableAsync(Modularity.cache_path .. "/api_cache", Api_Files_Loaded_Callback)
    if not started then
        Console.Warn("Cannot open api cache files")
    end
end


---🟦 `Server`
---
---Start Async HTTP requests to update the nanos api cache locally
---@return boolean success
function Modularity.UpdateAPICacheAsync()
    if not checking_last_commit then
        checking_last_commit = true
        Console.Log("Fetching last nanos api commit")
        HTTP.RequestAsync(URL_Github_API, endpoint_API_Get_Last_Commit, HTTPMethod.GET, "", "application/json", false, {}, function(status, data)
            if status == 200 then
                local nanos_api_last_commit = JSON.parse(data)
                local date
                if (nanos_api_last_commit.commit.author and nanos_api_last_commit.commit.author.date) then
                    date = nanos_api_last_commit.commit.author.date
                elseif (nanos_api_last_commit.commit.committer and nanos_api_last_commit.commit.committer.date) then
                    date = nanos_api_last_commit.commit.committer.date
                end

                if date then
                    local need_to_update = true
                    if not Modularity_Cache_File_Data_Tbl then
                        Modularity_Cache_File_Data_Tbl = {}
                        if File.Exists(Modularity.cache_data_path) then
                            local cache_data_file = File(Modularity.cache_data_path, false)
                            if cache_data_file:IsGood() then
                                cache_data = cache_data_file:Read(0)
                                cache_data_file:Close()

                                if cache_data ~= "" then
                                    Modularity_Cache_File_Data_Tbl = JSON.parse(cache_data)
                                end

                                if Modularity_Cache_File_Data_Tbl.api_commit_date then
                                    if Modularity_Cache_File_Data_Tbl.api_commit_date == date then
                                        need_to_update = false
                                    end
                                end
                            else
                                return error("Couldn't read '" .. Modularity.cache_data_path .. "'")
                            end
                        else
                            local split_data_path = Modularity.split_str(Modularity.cache_data_path, "/")
                            local cache_data_dir = table.concat(split_data_path, "/", 1, #split_data_path - 1)
                            if not File.Exists(cache_data_dir) then
                                local dir_created = File.CreateDirectory(cache_data_dir)
                                if not dir_created then
                                    return error("Could not create directory '" .. tostring(cache_data_dir) .. "'")
                                end
                            end
                        end
                    end

                    if need_to_update then
                        Modularity_Cache_File_Data_Tbl.api_commit_date = date
                        if (waiting_for_files_count == 0) then
                            Console.Log("Updating Nanos api cache")
                            HTTP.RequestAsync(URL_Github_API, endpoint_API_Get_Files_On_Repo, HTTPMethod.GET, "", "application/json", false, {}, function(status, data)
                                if (waiting_for_files_count == 0) then
                                    if status == 200 then
                                        local nanos_api_tree = JSON.parse(data)
                                        if nanos_api_tree then
                                            if nanos_api_tree.truncated then
                                                Console.Warn("Truncated api response for tree")
                                            end
                                            if nanos_api_tree.tree then
                                                for i, v in ipairs(nanos_api_tree.tree) do
                                                    if (v.type == "blob" and (type(v.path) == "string")) then
                                                        local split_dot_save_path = Modularity.split_str(v.path, ".")
                                                        if (split_dot_save_path[2] == "json") then
                                                            local splited_save_path = Modularity.split_str(v.path, "/")
                                                            local splited_count = Modularity.table_count(splited_save_path)

                                                            local directory_str = Modularity.cache_path .. "/api_cache"
                                                            if splited_count > 1 then
                                                                directory_str = directory_str .. "/"
                                                            end

                                                            local added_dir = ""
                                                            for i2 = 1, splited_count-1 do
                                                                if i2 < splited_count-1 then
                                                                    added_dir = added_dir .. splited_save_path[i2] .. "/"
                                                                else
                                                                    added_dir = added_dir .. splited_save_path[i2]
                                                                end
                                                            end

                                                            local pass = false
                                                            for k2, v2 in pairs(API_Needed_Paths_Prefix) do
                                                                if (string.sub(v.path, 1, v2) == k2) then
                                                                    pass = true
                                                                    break
                                                                end
                                                            end

                                                            if pass then -- Path is needed
                                                                directory_str = directory_str .. added_dir

                                                                if (not File.Exists(directory_str)) then
                                                                    --Console.Log("Creating " .. directory_str)
                                                                    local dir_created = File.CreateDirectory(directory_str)
                                                                    if not dir_created then
                                                                        return error("Could not create directory '" .. tostring(directory_str) .. "'")
                                                                    end
                                                                end

                                                                waiting_for_files_count = waiting_for_files_count + 1
                                                                HTTP.RequestAsync(URL_Github_Raw, "/" .. repo_owner .. "/" .. repo_name .. "/" .. repo_branch .. "/" .. v.path, HTTPMethod.GET, "", "application/json", false, {}, function(status_file, data_file)
                                                                    if status_file == 200 then
                                                                        local f_save_path = Modularity.cache_path .. "/api_cache/" .. v.path
                                                                        --Console.Log("Opening '" .. f_save_path .. "'")
                                                                        local save_file = File(f_save_path, true)
                                                                        if save_file then
                                                                            --Console.Log("Writing '" .. f_save_path .. "'")
                                                                            save_file:Write(data_file)
                                                                            --Console.Log("Closing '" .. f_save_path .. "'")
                                                                            save_file:Close()
                                                                            --Console.Log("Closed '" .. f_save_path .. "'")
                                                                        else
                                                                            Console.Error("Cannot Open file '" .. f_save_path .. "'")
                                                                        end
                                                                    else
                                                                        Console.Error("Got status " .. tostring(status_file) .. " when downloading file " .. v.path)
                                                                    end

                                                                    waiting_for_files_count = waiting_for_files_count - 1
                                                                    if waiting_for_files_count == 0 then
                                                                        Console.Log("Updated Nanos api cache")

                                                                        local cache_data_file = File(Modularity.cache_data_path, true)
                                                                        cache_data_file:Write(JSON.stringify(Modularity_Cache_File_Data_Tbl))
                                                                        cache_data_file:Close()

                                                                        Start_Api_Files_Loading()
                                                                    --else
                                                                        --Console.Log(tostring(waiting_for_files_count) .. " files remaining")
                                                                    end
                                                                end)
                                                            end
                                                        end
                                                    end
                                                end
                                            else
                                                Console.Error("Missing tree in api response")
                                            end
                                        end
                                    else
                                        Console.Error("Got status " .. tostring(status) .. " for github api tree request")
                                    end
                                end
                            end)
                        end
                    else
                        Console.Log("nanos api on disk up to date")
                        Start_Api_Files_Loading()
                    end

                else
                    Console.Error("Cannot fetch last commit date on nanos api")
                end
            end
            checking_last_commit = false
        end)

        return true
    end
    return false
end
if APICache_AutoUpdate then
    Modularity.UpdateAPICacheAsync()
else
    Start_Api_Files_Loading()
end