
lust.describe("HTTP.lua", function()
    lust.it("RequestAsync list", function()
        lust.expect(_G.HTTP).to.be.a("table")
        lust.expect(_G.HTTP.RequestAsync).to.be.a("function")

        local called = 0
        local http_a_func = function(status, data)
            called = called + 1

            lust.it("RequestAsync Callback", function()
                lust.expect(status).to.be(200)
                lust.expect(string.len(data) > 0).to.be(true)

                if called == 3 then
                    lust.expect(Modularity.HTTPRequestAsyncList[http_a_func]).to_not.exist()
                end
            end)

            --print("http_a_func", status, data)
        end

        HTTP.RequestAsync("127.0.0.1:" .. tostring(Server.GetPort()), "/", HTTPMethod.GET, "", "application/json", false, {}, http_a_func)
        HTTP.RequestAsync("127.0.0.1:" .. tostring(Server.GetPort()), "/", HTTPMethod.GET, "", "application/json", false, {}, http_a_func)

        lust.expect(Modularity.HTTPRequestAsyncList[http_a_func]).to.be.a("table")
        lust.expect(Modularity.HTTPRequestAsyncList[http_a_func].pending_count).to.be(2)

        http_a_func(200, "a") -- Make sure that lua calls don't affect the list
        lust.expect(Modularity.HTTPRequestAsyncList[http_a_func].pending_count).to.be(2)

        lust.expect(called).to.be(1)
    end)
end)

Modularity.AddDownloadWhitelistedPrefix("Packages/" .. Package.GetName() .. "/download-test/")

lust.describe("Require.lua", function()
    lust.it("Injectfile.lua", function()
        local rets = {table.unpack(Package.Require("modularity-t-s-injection/Server/Injectfile.lua"))}
        lust.expect(rets).to.have_n_fields(4)

        lust.expect(rets[1]).to.be("Injectfile")
        lust.expect(rets[3]).to.be("Injectfile_2")

        lust.expect(Modularity.GetFunctionPackageName_info(rets[2])).to.be(Package.GetName())
        lust.expect(Modularity.GetFunctionPackageName_info(rets[4])).to.be(Package.GetName())

        lust.expect(debug.getinfo(rets[2], "S").source).to.be(Package.GetName() .. "/../modularity-t-s-injection/Server/Injectfile.lua")
        lust.expect(debug.getinfo(rets[4], "S").source).to.be(Package.GetName() .. "/../modularity-t-s-injection/Server/Injectfile_2.lua")
    end)
end)


lust.it("MTS-gm loaded", function()
    local found
    for k, v in pairs(Server.GetPackages(true)) do
        if v.name == "modularity-testing-suite-gm" then
            found = true
        end
    end
    lust.expect(found).to.be(true)
end)

if not Modularity.AwareOf("modularity-testing-suite-gm") then
    lust.it("MakeAware", function()
        local ret = Modularity.MakeAware()
        lust.expect(ret).to.be(true)
    end)
else
    lust.it("AwareOfGM", function()
        local ret = Modularity.MakeAware()
        lust.expect(ret).to.be(false)
    end)

    lust.describe("IsNowAware", function()
        lust.it("Event", function()
            local ret = Modularity.GetKnownNativeEventsFunctions("Subscribe", "Events", "modularity-testing-suite-gm", "TestGMEvent")
            lust.expect(ret).to.be.a("table")
            print(NanosTable.Dump(ret))
        end)
    end)
end