

local Sending_Files_Queue = {}
local Sending_Files_Handles = {}
local pending_handles_count = 0
local _handle_id = 0


local _mdown_found_plys_tick
local _mdown_chunks_sent_tick

local CompressionInfo = false




local function _ModularityFileDownloadStopped(handle)
    Sending_Files_Handles[handle] = nil
    local i = 1
    while Sending_Files_Queue[i] do
        if Sending_Files_Queue[i] == handle then
            table.remove(Sending_Files_Queue, i)
        else
            i = i + 1
        end
    end

    pending_handles_count = pending_handles_count - 1
    if pending_handles_count <= 0 then
        Server.Unsubscribe("Tick", _ModularityDownloadTick)
    end
end


local function _Modularity_SendChunkForEachPendingFile(Max_Chunks_This_Tick)
    _mdown_found_plys_tick = {}
    local i = 1
    while Sending_Files_Queue[i] do
        local k = Sending_Files_Queue[i]
        local v = Sending_Files_Handles[k]
        if _mdown_chunks_sent_tick >= Max_Chunks_This_Tick then
            break
        end
        if not _mdown_found_plys_tick[v.ply] then
            _mdown_found_plys_tick[v.ply] = true
            local new_perc = v.progress*100/v.packets
            if math.floor(new_perc) ~= v.last_perc_int then
                v.last_perc_int = math.floor(new_perc)
                --Console.Log("Sending (" .. k .. ")" .. " " .. tostring(v.progress*Downloading_File_Chunk_Bytes) .. " / " .. tostring(v.full_size) .. "B, " .. tostring(new_perc) .. "%")
            end
            Events.CallRemote("ModularitySendServerFile_Part", v.ply, k, v.data[v.progress+1])
            v.progress = v.progress + 1
            _mdown_chunks_sent_tick = _mdown_chunks_sent_tick + 1
            Modularity.CallEvent("ServerDownloadFile_Part", v.ply, Sending_Files_Handles[k])

            if v.progress >= v.packets then
                --print("Transfer (" .. tostring(k) .. ") Finished")
                Events.CallRemote("ModularitySendServerFile_End", v.ply, k, v.save_path, v.compression, v.additional_compression_params)
                Modularity.CallEvent("ServerDownloadFile_End", v.ply, Sending_Files_Handles[k])
                _ModularityFileDownloadStopped(k)
                i = i - 1
            end
        end
        i = i + 1
    end
end


local function _ModularityDownloadTick(ds)
    --print(ds)
    if pending_handles_count > 0 then
        _mdown_chunks_sent_tick = 0
        local Max_Chunks_This_Tick = math.ceil(Downloading_Max_Chunks_Sent_Per_Tick_Mult_Inv_ds * (1/ds))
        --print(Max_Chunks_This_Tick)
        while (_mdown_chunks_sent_tick < Max_Chunks_This_Tick and pending_handles_count > 0) do
            _Modularity_SendChunkForEachPendingFile(Max_Chunks_This_Tick)
        end
    end
end


---🟦 `Server`
---
---To start sending a server file to a player, path has to be whitelisted to download.
---@param ply Player 
---@param path string Relative to nanos server folder
---@param save_path string Relative to server .transient folder
---@param compression_setting? E_DownloadServerFileCompressionSetting @(Default: Modularity.Enums.DownloadServerFileCompressionSetting.NoCompression)
---@param additional_compression_params? any @(Default: nil)
---@return boolean|nil success
function Modularity.SendServerFile(ply, path, save_path, compression_setting, additional_compression_params)
    if (path and type(path) == "string" and save_path and type(save_path) == "string" and ply and ply:IsValid()) then
        compression_setting = compression_setting or Modularity.Enums.DownloadServerFileCompressionSetting.NoCompression

        --print("ModularityDownloadServerFile_Init", path, save_path, compression_setting)

        local is_whitelisted
        for k, v in pairs(Modularity.DownloadWhitelistedPrefixes) do
            --print(path, v, '"' .. tostring(string.sub(path, 1, v)) .. '"')
            if (string.sub(path, 1, v) == k) then
                --print(string.find(path, "..", v+1, true), string.find("Getting.. there", "..", 1, true))
                if (not string.find(path, "..", v+1, true)) then
                    is_whitelisted = true
                    break
                end
            end
        end

        if is_whitelisted then
            local file_to_send = io.open(path, "rb")
            if file_to_send then
                local to_send = {}
                local last_read
                local read
                local first = true
                local packets = 0
                while (read or first) do
                    if not first then
                        packets = packets + 1
                        to_send[packets] = read
                    else
                        first = false
                    end
                    last_read = read
                    read = file_to_send:read(Downloading_File_Chunk_Bytes)
                    --print(string.len(read))
                end
                local last_packet_bytes = 0
                if last_read then
                    last_packet_bytes = string.len(last_read)
                end
                file_to_send:close()

                local compression = Modularity.Enums.DownloadServerFileCompressionSetting.NoCompression

                if compression_setting ~= Modularity.Enums.DownloadServerFileCompressionSetting.NoCompression then
                    if type(additional_compression_params) == "table" then
                        if additional_compression_params.level == "server_compression_level" then
                            additional_compression_params.level = Server.GetCompressionLevel()
                        end
                    end

                    local whole_binary = table.concat(to_send)
                    local compressed
                    local start_time = os.clock()
                    if CompressionInfo then
                        Console.Log("Started Compression (" .. tostring(compression_setting) .. ")")
                    end

                    if compression_setting == Modularity.Enums.DownloadServerFileCompressionSetting.LZWCompression then
                        compressed, comp_error = LZW.compress(whole_binary)
                    elseif compression_setting == Modularity.Enums.DownloadServerFileCompressionSetting.DeflateCompression then
                        compressed = LibDeflate:CompressDeflate(whole_binary, additional_compression_params)
                    elseif compression_setting == Modularity.Enums.DownloadServerFileCompressionSetting.ZlibCompression then
                        compressed = LibDeflate:CompressZlib(whole_binary, additional_compression_params)
                    elseif compression_setting == Modularity.Enums.DownloadServerFileCompressionSetting.Base64Compression then
                        compressed = base64.encode(whole_binary, nil, additional_compression_params)
                    end
                    if compressed then

                        if CompressionInfo then
                            local whole_binary_bytes = string.len(whole_binary)
                            local compressed_bytes = string.len(compressed)
                            print("Compressed " .. path .. " with compression " .. tostring(compression_setting) .. ". Uncompressed : ", tostring(whole_binary_bytes) .. "B", "Compressed : ", tostring(compressed_bytes) .. "B", "Size Percentage : ", tostring(compressed_bytes*100/whole_binary_bytes) .. "%")
                            Console.Log("Took " .. tostring(os.clock()-start_time) .. "s")
                        end

                        to_send = Modularity.split_strByChunk(compressed, Downloading_File_Chunk_Bytes)
                        packets = #to_send
                        if packets > 0 then
                            last_packet_bytes = string.len(to_send[packets])
                        end
                        compression = compression_setting
                    else
                        --Console.Warn("Compression failed")
                    end
                end

                --print(Modularity.table_count(to_send))
                _handle_id = _handle_id + 1
                local cur_handle = _handle_id

                Sending_Files_Handles[cur_handle] = {
                    data = to_send,
                    ply = ply,
                    progress = 0,
                    packets = packets,
                    last_perc_int = -1,
                    path = path,
                    save_path = save_path,
                    full_size = (packets-1)*Downloading_File_Chunk_Bytes + last_packet_bytes,
                    compression = compression,
                    additional_compression_params = additional_compression_params,
                }
                table.insert(Sending_Files_Queue, cur_handle)
                pending_handles_count = pending_handles_count + 1
                --print("Starting to send", path, "to", ply, "handle :", cur_handle)
                Events.CallRemote("ModularitySendServerFile_Init", ply, cur_handle, path, packets)
                Modularity.CallEvent("ServerDownloadFile_Init", ply, Sending_Files_Handles[cur_handle])
                if pending_handles_count == 1 then
                    Server.Subscribe("Tick", _ModularityDownloadTick)
                end

                return true
            end
        else
            Console.Error(path .. " is not whitelisted for Downloading. Requested for player " .. tostring(ply:GetAccountName()) .. " (steamid:" .. tostring(ply:GetSteamID()) .. "). (May come from the Server itself)")
        end
    end
end
Events.SubscribeRemote("ModularityDownloadServerFile_Init", Modularity.SendServerFile)

Player.Subscribe("Destroy", function(ply)
    for k, v in pairs(Sending_Files_Handles) do
        if v.ply == ply then
            _ModularityFileDownloadStopped(k)
        end
    end
end)

---🟦 `Server`
---
---Whitelist a specific path to allow downloading
---@param prefix string can be "" or "../" to only allow files in upper folder, relative to server folder
---@return boolean|nil success
function Modularity.AddDownloadWhitelistedPrefix(prefix)
    if (prefix and type(prefix) == "string") then
        Modularity.DownloadWhitelistedPrefixes[prefix] = string.len(prefix)
        return true
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

---🟦 `Server`
---
---Unwhitelist a file path to block downloading, file that are already downloading won't be stopped.
---@param prefix string
---@return boolean|nil success
function Modularity.RemoveDownloadWhitelistedPrefix(prefix)
    if (prefix and type(prefix) == "string") then
        Modularity.DownloadWhitelistedPrefixes[prefix] = nil
        return true
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

