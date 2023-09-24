

lust.it("Bind spy test", function()
    local called
    Input.Bind("Interact", InputEvent.Pressed, function(a)
        called = true
        lust.expect(a).to.be(1)
    end)

    Modularity.NativeCallEvent("Bind", "Input_S", "Interact", Package.GetName(), nil, {["2"] = InputEvent.Pressed}, 1)
    Modularity.NativeCallEvent("Bind", "Input_S", "Interact", Package.GetName(), nil, nil, 222222)
    Modularity.NativeCallEvent("Bind", "Input_S", "Interact", Package.GetName(), nil, {["2"] = InputEvent.Released}, 222222)

    Input.Unbind("Interact", InputEvent.Pressed)

    Modularity.NativeCallEvent("Bind", "Input_S", "Interact", Package.GetName(), nil, {["2"] = InputEvent.Pressed}, 222222)

    lust.expect(called).to.be.truthy()
end)


lust.it("Downloading_test Read Real Files", function()
    local w_file = File("download-test/windows10.png")
    lust.expect(w_file).to.exist()
    lust.expect(w_file:IsGood()).to.be.truthy()
    windows10 = w_file:Read(0)
    w_file:Close()

    local b_file = File("download-test/bruh.jpg")
    lust.expect(b_file).to.exist()
    lust.expect(b_file:IsGood()).to.be.truthy()
    bruh = b_file:Read(0)
    b_file:Close()

    local l_file = File("download-test/lzwtest.txt")
    lust.expect(l_file).to.exist()
    lust.expect(l_file:IsGood()).to.be.truthy()
    lzwtest = l_file:Read(0)
    l_file:Close()
end)

local function client_loaded_tests()
    local Init_Called = 0
    lust.it("Download AskServerFiles", function()
        lust.expect(windows10).to.exist()
        lust.expect(bruh).to.exist()
        lust.expect(lzwtest).to.exist()

        Modularity.Subscribe("ClientDownloadFile_Init", function()
            Init_Called = Init_Called + 1
        end)

        Modularity.DownloadServerFile("Packages/" .. Package.GetName() .. "/download-test/windows10.png", "received/nocompression/windows10.png", Modularity.Enums.DownloadServerFileCompressionSetting.NoCompression)
        Modularity.DownloadServerFile("Packages/" .. Package.GetName() .. "/download-test/bruh.jpg", "received/nocompression/bruh.jpg", Modularity.Enums.DownloadServerFileCompressionSetting.NoCompression)
        Modularity.DownloadServerFile("Packages/" .. Package.GetName() .. "/download-test/lzwtest.txt", "received/nocompression/lzwtest.txt", Modularity.Enums.DownloadServerFileCompressionSetting.NoCompression)

        Modularity.DownloadServerFile("Packages/" .. Package.GetName() .. "/download-test/lzwtest.txt", "received/lzw/lzwtest.txt", Modularity.Enums.DownloadServerFileCompressionSetting.LZWCompression)

        Modularity.DownloadServerFile("Packages/" .. Package.GetName() .. "/download-test/bruh.jpg", "received/base64/bruh.jpg", Modularity.Enums.DownloadServerFileCompressionSetting.Base64Compression, false)
        Modularity.DownloadServerFile("Packages/" .. Package.GetName() .. "/download-test/lzwtest.txt", "received/base64/lzwtest.txt", Modularity.Enums.DownloadServerFileCompressionSetting.Base64Compression, true)
    end)

    Timer.SetTimeout(function()
        lust.it("Check Init call count", function()
            lust.expect(Init_Called).to.be(6)
        end)
    end, 5000)

    Modularity.Subscribe("ClientDownloadFile_End_AttemptSave", function(final_str, path, save_path, compression, additional_compression_params)
        local bin = false
        lust.it("AttemptSave " .. save_path, function()
            local file_name = Modularity.split_str(save_path, "/")
            file_name = file_name[Modularity.table_count(file_name)]
            local file_name_and_ext = Modularity.split_str(file_name, ".")
            local file_var = file_name_and_ext[1]
            local file_ext = file_name_and_ext[2]
            --print(file_var)
            lust.expect(_ENV[file_var]).to.exist()

            --lust.expect(string.len(_ENV[file_var])).to.be(string.len(final_str))
            --lust.expect(binaryStringsAreEqual(_ENV[file_var], final_str)).to.be.truthy()
            if file_ext == "txt" then
                lust.expect(final_str).to.be(_ENV[file_var])

                Timer.SetTimeout(function()
                    lust.it("Check file not on disc " .. save_path, function()
                        lust.expect(File.Exists(save_path)).to_not.be.truthy()
                    end)
                end, 5000)
            else
                bin = true
            end
            --lust.expect(final_str).to.be(_ENV[file_var])
        end)

        return bin
    end)
end

if Client.GetLocalPlayer() then
    client_loaded_tests()
else
    Client.Subscribe("SpawnLocalPlayer", client_loaded_tests)
end
