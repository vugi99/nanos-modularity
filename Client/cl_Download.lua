

local Downloading_Handles = {}

---🟧 `Client`
---
---Sends a request to the server to download a file that is on the server, the file path has to be whitelisted.
---@param path string Relative to nanos server folder
---@param save_path string Relative to server .transient folder
---@param compression_setting? E_DownloadServerFileCompressionSetting @(Default: Modularity.Enums.DownloadServerFileCompressionSetting.NoCompression)
---@param additional_compression_params? any @(Default: nil)
function Modularity.DownloadServerFile(path, save_path, compression_setting, additional_compression_params)
    if (path and type(path) == "string" and save_path and type(save_path) == "string") then
        --print("Bef CallRemote", path, save_path, compression_setting)
        Events.CallRemote("ModularityDownloadServerFile_Init", path, save_path, compression_setting, additional_compression_params)
        --print("After CallRemote")
    else
        error("Wrong arguments on Modularity." .. debug.getinfo(1, "n").name)
    end
end

Events.SubscribeRemote("ModularitySendServerFile_Init", function(handle, path, packets)
    Downloading_Handles[handle] = {
        buffer = {},
        last_index = 1,
        path = path,
        packets = packets,
    }
    Modularity.CallEvent("ClientDownloadFile_Init", path, packets)
end)

Events.SubscribeRemote("ModularitySendServerFile_Part", function(handle, part)
    if Downloading_Handles[handle] then
        --print("ModularitySendServerFile_Part", handle, Downloading_Handles[handle].last_index)
        Downloading_Handles[handle].buffer[Downloading_Handles[handle].last_index] = part
        Downloading_Handles[handle].last_index = Downloading_Handles[handle].last_index + 1
        Modularity.CallEvent("ClientDownloadFile_Part", Downloading_Handles[handle].path, Downloading_Handles[handle].last_index-1, Downloading_Handles[handle].packets)
    end
end)

Events.SubscribeRemote("ModularitySendServerFile_End", function(handle, save_path, compression, additional_compression_params)
    --print("ModularitySendServerFile_End", handle, save_path)
    if Downloading_Handles[handle] then

        local final_str = table.concat(Downloading_Handles[handle].buffer)
        if compression ~= Modularity.Enums.DownloadServerFileCompressionSetting.NoCompression then
            local decompressed
            if compression == Modularity.Enums.DownloadServerFileCompressionSetting.LZWCompression then
                decompressed, error_str = LZW.decompress(final_str)
            elseif compression == Modularity.Enums.DownloadServerFileCompressionSetting.DeflateCompression then
                decompressed = LibDeflate:DecompressDeflate(final_str)
            elseif compression == Modularity.Enums.DownloadServerFileCompressionSetting.ZlibCompression then
                decompressed = LibDeflate:DecompressZlib(final_str)
            elseif compression == Modularity.Enums.DownloadServerFileCompressionSetting.Base64Compression then
                decompressed = base64.decode(final_str, nil, additional_compression_params)
            end
            if decompressed then
                final_str = decompressed
            else
                return error("Failed to decompress compressed data (Compression:" .. tostring(compression) .. ")")
            end
        end

        local ret = Modularity.CallEvent("ClientDownloadFile_End_AttemptSave", final_str, Downloading_Handles[handle].path, save_path, compression, additional_compression_params)
        if ret then
            for f, v in pairs(ret) do
                for _, v2 in ipairs(v) do
                    if v2[1] == false then
                        Downloading_Handles[handle] = nil
                        return
                    end
                end
            end
        end

        local splited_save_path = Modularity.split_str(save_path, "/")
        local splited_count = #splited_save_path
        if splited_count > 1 then
            local directory_str = ""
            for i = 1, splited_count-1 do
                if i < splited_count-1 then
                    directory_str = directory_str .. splited_save_path[i] .. "/"
                else
                    directory_str = directory_str .. splited_save_path[i]
                end
            end
            --print(File.Exists(directory_str))
            if (not File.Exists(directory_str)) then
                local dir_created = File.CreateDirectory(directory_str)
                if not dir_created then
                    return error("Could not create directory '" .. tostring(directory_str) .. "'")
                end
            end
        end

        local write_file = File(save_path, true)
        write_file:Write(final_str)
        write_file:Close()

        Modularity.CallEvent("ClientDownloadFile_End", Downloading_Handles[handle].path, save_path, compression, additional_compression_params)

        Downloading_Handles[handle] = nil
    end
end)