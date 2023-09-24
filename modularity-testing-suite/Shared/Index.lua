
lust = Package.Require("lust.lua")
if Client then
    lust.nocolor()
end


-- lust extension

lust.paths.have_n_fields = {
    test = function(v, x)
        if type(v) ~= 'table' then
            --print(debug.traceback())
            error('expected ' .. tostring(v) .. ' to be a table')
        end

        local c = 0
        for _, ___ in pairs(v) do c = c + 1 end

        return (c == x), 'expected ' .. tostring(v) .. ' to have ' .. tostring(x) .. " fields, got " .. tostring(c) .. " fields instead", 'expected ' .. tostring(v) .. ' to not have ' .. tostring(x) .. " fields"
    end
}

table.insert(lust.paths.to, 'have_n_fields')
table.insert(lust.paths.to_not, 'have_n_fields')









Package.Require("local_vars.lua")









envvar = true
local function testfunc()
    envvar = "d"
end

local function testfunc2(a)
    return a + 1
end

local function TestfuncCallsTree()
    testfunc()
    testfunc2(2)
    return testfunc2(1)
end

function table_count(t)
    local c = 0
    for _, __ in pairs(t) do c = c + 1 end
    return c
end


lust.describe("Lua Variables", function()
    lust.describe("debug", function()
        local _debug
        lust.it("table", function()
            lust.expect(debug).to.be.a("table")
            _debug = debug
        end)

        if _debug then
            lust.it("getregistry", function()
                lust.expect(debug.getregistry).to.be.a("function")

                local reg = debug.getregistry()

                lust.expect(reg).to.be.a("table")
            end)

            lust.it("gethook", function()
                lust.expect(debug.gethook).to.be.a("function")
            end)

            lust.it("sethook", function()
                lust.expect(debug.sethook).to.be.a("function")
            end)
        end
    end)

    lust.it("getmetatable", function()
        lust.expect(getmetatable).to.be.a("function")

        lust.expect(getmetatable(_ENV)).to.be.a("table")
    end)

    lust.it("setmetatable", function()
        lust.expect(setmetatable).to.be.a("function")

        local meta = {meta = true}
        local tbl = {}
        setmetatable(tbl, meta)

        lust.expect(getmetatable(tbl)).to.be(meta)
    end)

    lust.it("load", function()
        lust.expect(load).to.be.a("function")

        local function testcodeload()
            return load("a = 3")
        end
        lust.expect(testcodeload).to_not.fail()
    end)
end)

lust.describe("Nanos Variables", function()

    lust.describe("registry", function()
        local reg
        lust.it("getregistry", function()
            reg = debug.getregistry()

            lust.expect(reg).to.be.a("table")
        end)

        if reg then
            lust.it("environments", function()
                lust.expect(reg.environments).to.be.a("table")

                for k, v in pairs(reg.environments) do
                    lust.expect(k).to.be.a("table")
                    lust.expect(v).to.be.a("userdata")
                end
            end)

            lust.it("classes", function()
                lust.expect(reg.classes).to.be.a("table")

                for k, v in pairs(reg.classes) do
                    lust.expect(k).to.be.a("number")
                    lust.expect(v).to.be.a("table")

                    lust.expect(v.__name).to.be.a("string")

                    lust.expect(getmetatable(v)).to.exist()
                end
            end)

            lust.it("inherited_classes", function()
                lust.expect(reg.inherited_classes).to.be.a("table")
            end)

            lust.it("userdata", function()
                lust.expect(reg.userdata).to.be.a("table")

                for k, v in pairs(reg.userdata) do
                    lust.expect(k).to.be.a("userdata")
                    lust.expect(v).to.be.a("userdata")
                end
            end)

            lust.it("__function", function()
                for k, v in pairs(reg.classes) do
                    local meta = getmetatable(v)
                    if (meta and meta.__call) then
                        lust.expect(v.__function).to.be.a("table")
                    end
                end
            end)
        end
    end)

    lust.describe("_ENV or _G", function()
        lust.it("Events", function()
            lust.expect(Events).to.be.a("table")
            lust.expect(_G.Events).to.be.a("table")
        end)

        lust.it("Package", function()
            lust.expect(Package).to.be.a("table")

            lust.expect(Package.GetName).to.be.a("function")
        end)

        lust.it("File", function()
            lust.expect(File).to.be.a("table")
        end)

        lust.it("SideTableUnique", function()
            if Client then
                lust.expect(Server).to_not.exist()
            elseif Server then
                lust.expect(Client).to_not.exist()
            else
                error("Client and Server Missing")
            end
        end)

        lust.it("NanosTable", function()
            lust.expect(NanosTable).to.be.a("table")
            lust.expect(NanosTable.Dump).to.be.a("function")
        end)

        lust.it("Console", function()
            lust.expect(_G.Console).to.be.a("table")
            lust.expect(_G.Console.Log).to.be.a("function")
            lust.expect(_G.Console.Warn).to.be.a("function")
            lust.expect(_G.Console.Error).to.be.a("function")
        end)

        lust.it("Console_I", function()
            lust.expect(_G.Console_I).to.be.a("table")
            lust.expect(_G.Console_I.Log).to.be.a("function")
            lust.expect(_G.Console_I.Warn).to.be.a("function")
            lust.expect(_G.Console_I.Error).to.be.a("function")
        end)
    end)
end)

lust.describe("Console.lua", function()
    lust.it("Prefix", function()
        --[[local print_next = true
        local logentry_func = function(text, type)
            if print_next then
                print_next = false
                print("LogEntry", text, type)
            else
                print_next = true
            end
        end
        Console.Subscribe("LogEntry", logentry_func)]]--

        print("Should be package_name")

        Modularity.EnableDefaultPackageConsoleAlias(false)

        print("Should be nothing")

        Modularity.EnableDefaultPackageConsoleAlias(true)

        Modularity.RegisterPackageConsoleAlias(Package.GetName(), "MTS")

        print("Should be alias")
    end)

    lust.it("Remove Current Console Message", function()
        Modularity.Subscribe("AttemptConsoleLog", function(str, func_name)
            if func_name == "Error" then
                lust.expect(str).to.be("NOT GOOD")
                return false
            end
        end)

        Console.Error("NOT GOOD")

        Modularity.Unsubscribe("AttemptConsoleLog")

        Console.Error("GOOD")
    end)
end)


lust.describe("Sh_Funcs.lua", function()

    lust.it("split_strByChunk", function()
        local base_str = "AZERTYUIOPQSDFGHJKLMWXCVBN*%£>?./+,;:=&é'(§è!çà)-1234567890"
        local len = string.len(base_str)

        local str = ""
        for i = 1, 5 do
            str = str .. base_str
        end

        local ret = Modularity.split_strByChunk(str, len)

        lust.expect(ret).to.exist()
        lust.expect(ret).to.have_n_fields(5)
        for k, v in pairs(ret) do
            lust.expect(v).to.be(base_str)
        end
    end)

    lust.it("GetFunction_ENV_upvalue", function()
        local env, p_name = Modularity.GetFunction_ENV_upvalue(testfunc)
        --print(env)
        lust.expect(env).to.equal(_ENV)
        lust.expect(p_name).to.be(Package.GetName())
    end)

    lust.it("GetFunctionPackageName_info", function()
        local p_name = Modularity.GetFunctionPackageName_info(testfunc)
        lust.expect(p_name).to.be(Package.GetName())
    end)

    lust.it("ForceDump", function()
        local tbl = {
            a = 1,
            b = 2,
            c = 3,
            d = 4,
        }
        setmetatable(tbl, {
            __pairs = function(self)
                return function(t, k, v) end
            end
        })

        for k, v in pairs(tbl) do
            error("Shouldn't have pairs working")
        end

        local f_d = Modularity.ForceDump(tbl)
        lust.expect(f_d).to.equal(tbl)
    end)

    lust.it("GetAllEntities", function()
        local ents = Modularity.GetAllEntities()
        lust.expect(ents).to.exist()

        local packages_loaded
        if Server then
            packages_loaded = Server.GetPackages(true)
        else
            packages_loaded = Client.GetPackages()
        end
        local p_l_count = table_count(packages_loaded)
        --lust.expect(ents).to.have_n_fields(2*p_l_count) -- ??

        for k, v in pairs(ents) do
            lust.expect(k).to.be.a("userdata")
            lust.expect(v).to.be.a("userdata")
        end
    end)

    lust.it("CallsTreeFromNow", function()
        local treturned
        local function CTFNR(func, r)
            --print("CTFNR", r)
            if func == TestfuncCallsTree then
                treturned = r
            end
        end
        Modularity.Subscribe("CallsTreeFromNowReturn", CTFNR)


        Modularity.CallsTreeFromNow(TestfuncCallsTree, true)
        --Modularity.EnablePrintDebugInfo(true, false, false, "cr")
        TestfuncCallsTree()
        --Modularity.EnablePrintDebugInfo(false)

        Modularity.Unsubscribe("CallsTreeFromNowReturn", CTFNR)

        --print(NanosTable.Dump(treturned))

        lust.expect(treturned).to.exist()

        lust.expect(treturned.tailcalls).to.have_n_fields(1)
        lust.expect(treturned.tree).to.have_n_fields(2)
    end)

    lust.it("CallsTree", function()
        --print("HERE")
        local treturned = Modularity.CallsTree(TestfuncCallsTree, true)
        --print("after")

        lust.expect(treturned).to.exist()

        lust.expect(treturned.tailcalls).to.have_n_fields(1)
        lust.expect(treturned.tree).to.have_n_fields(2)
    end)

    lust.it("CompareTables", function()
        local ttbl1 = {
            gaz = "gaz",
            int = 23,
            f = testfunc,
            othertbl = {
                oo = "oo",
                oint = 24,
            },
        }

        local ttbl2 = {
            gaz = "gaz",
            int = 23,
            f = testfunc,
            othertbl = {
                oo = "oo",
                oint = 24,
            },
        }

        local ttbl3 = {
            added = true,
            gaz = "gaz",
            int = 23,
            f = testfunc,
            othertbl = {
                oo = "oo",
                oint = 24,
            },
        }

        local ttbl4 = {
            gaz = "gaz",
            int = 23,
            f = testfunc,
            othertbl = {
                oo = "",
                oint = 24,
            },
        }
        local ttbl5 = {
            gaz = "gaz",
            int = 23,
            f = testfunc,
            othertbl = {
                oo = "oo",
            },
        }

        lust.expect(Modularity.CompareTables(ttbl1, ttbl1)).to.be.truthy()
        lust.expect(Modularity.CompareTables(ttbl2, ttbl2)).to.be.truthy()
        lust.expect(Modularity.CompareTables(ttbl3, ttbl3)).to.be.truthy()
        lust.expect(Modularity.CompareTables(ttbl4, ttbl4)).to.be.truthy()
        lust.expect(Modularity.CompareTables(ttbl5, ttbl5)).to.be.truthy()

        lust.expect(Modularity.CompareTables(ttbl1, ttbl2)).to.be.truthy()
        lust.expect(Modularity.CompareTables(ttbl2, ttbl1)).to.be.truthy()
        lust.expect(Modularity.CompareTables(ttbl1, ttbl3)).to_not.be.truthy()
        lust.expect(Modularity.CompareTables(ttbl3, ttbl1)).to_not.be.truthy()
        lust.expect(Modularity.CompareTables(ttbl1, ttbl4)).to_not.be.truthy()
        lust.expect(Modularity.CompareTables(ttbl4, ttbl1)).to_not.be.truthy()
        lust.expect(Modularity.CompareTables(ttbl1, ttbl5)).to_not.be.truthy()
        lust.expect(Modularity.CompareTables(ttbl5, ttbl1)).to_not.be.truthy()

        lust.expect(Modularity.CompareTables(ttbl3, ttbl1, {added=true})).to.be.truthy()
        lust.expect(Modularity.CompareTables(ttbl1, ttbl3, {added=true})).to.be.truthy()

        local rectbl = {}
        rectbl.k = rectbl

        local otherrectbl = {}
        otherrectbl.k = otherrectbl

        lust.expect(Modularity.CompareTables(rectbl, otherrectbl)).to.be.truthy()

        local enc_tbl = {
            l = rectbl,
        }

        local otherenc = {
            l = otherrectbl,
        }

        lust.expect(Modularity.CompareTables(enc_tbl, otherenc)).to.be.truthy()

        local enc_enc = {
            l = enc_tbl,
        }

        lust.expect(Modularity.CompareTables(enc_enc, otherenc)).to_not.be.truthy()

        -- May break when tables have references between each other
    end)

    lust.it("GetCallingPackageName", function()
        local p_name = Modularity.GetCallingPackageName(2)

        lust.expect(p_name).to.be(Package.GetName())

        local _p_name = Modularity.GetCallingPackageName(3)

        lust.expect(_p_name).to.be("=[C]")
    end)

    lust.it("GetSide", function()
        if Server then
            lust.expect(Modularity.GetSide()).to.be("Server")
        else
            lust.expect(Modularity.GetSide()).to.be("Client")
        end
    end)

    lust.it("DumpKeys", function()
        local tbl = {
            a = 1,
            b = 2,
            c = 3,
            d = 4,
        }

        local keys = Modularity.DumpKeys(tbl)

        local ticked = {
        }

        lust.expect(keys).to.exist()

        local i_count = 0
        for i, v in ipairs(keys) do
            i_count = i_count + 1
            if ticked[v] then
                error("Double table key dump")
            else
                ticked[v] = true
            end
        end

        lust.expect(i_count).to.be(4)

        lust.expect(ticked).to.have_n_fields(4)
    end)

    lust.it("GetAddress", function()
        local tbl = {}
        local tbl2 = {}

        lust.expect(tbl).to_not.be(tbl2)

        local a1 = Modularity.GetAddress(tbl)
        local a2 = Modularity.GetAddress(tbl2)

        lust.expect(a1).to.be.a("string")
        lust.expect(a2).to.be.a("string")

        lust.expect(a1).to_not.be(a2)

        lust.expect(string.sub(a1, 1, 1)).to_not.be(" ")
        lust.expect(string.sub(a2, 1, 1)).to_not.be(" ")
    end)

    lust.it("IsTableEmpty", function()
        local tbl = {}

        local tbl_bool = {}
        tbl_bool[false] = 1

        local n_tbl = {
            a = 1,
            b = 2,
        }

        lust.expect(Modularity.IsTableEmpty(tbl)).to.be(true)
        lust.expect(Modularity.IsTableEmpty(tbl_bool)).to.be(false)
        lust.expect(Modularity.IsTableEmpty(tbl_bool)).to.be(false) -- Make sure that next doesn't cache last call ret index
        lust.expect(Modularity.IsTableEmpty(n_tbl)).to.be(false)
    end)
end)

lust.describe("Hooks.lua", function()
    local cur_hooks = {}
    lust.after(function(name)
        --print("after", name)
        for k, v in pairs(cur_hooks) do
            Modularity.UnHook(v.target, v.hook_func)
        end
        cur_hooks = {}
    end)

    lust.describe("UnHook", function()
        lust.it("UH_PreHook", function()
            local good = true

            local hf = Modularity.PreHook(testfunc, function()
                good = false
            end)
            Modularity.UnHook(testfunc, hf)

            testfunc()

            lust.expect(good).to.be.truthy()
        end)

        lust.it("UH_EndHook", function()
            local good = true

            local hf = Modularity.EndHook(testfunc, function()
                good = false
            end)
            Modularity.UnHook(testfunc, hf)

            testfunc()

            lust.expect(good).to.be.truthy()
        end)

        lust.it("UH_PreHookName", function()
            local good = true

            local hf = Modularity.PreHookName("testfunc", function()
                good = false
            end)
            Modularity.UnHook("testfunc", hf)

            testfunc()

            lust.expect(good).to.be.truthy()
        end)

        lust.it("UH_EndHookName", function()
            local good = true

            local hf = Modularity.EndHookName("testfunc", function()
                good = false
            end)
            Modularity.UnHook("testfunc", hf)

            testfunc()

            lust.expect(good).to.be.truthy()
        end)
    end)

    lust.describe("PreHook", function()
        lust.it("basic", function()
            local called
            local hf = Modularity.PreHook(testfunc, function()
                called = true
            end)
            lust.expect(hf).to.be.a("function")
            table.insert(cur_hooks, {target = testfunc, hook_func = hf})

            testfunc()

            lust.expect(called).to.be.truthy()
        end)

        lust.it("alter_args", function()
            local o, o2, o3
            local function checkargs(a, a2, a3)
                o = a
                o2 = a2
                o3 = a3
            end

            local hf = Modularity.PreHook(checkargs, function(a, a2, a3)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be("2")
                lust.expect(a3).to.be(3)
                return 11, "12", 13
            end, true)
            table.insert(cur_hooks, {target = checkargs, hook_func = hf})

            checkargs(1, "2", 3)

            lust.expect(o).to.be(11)
            lust.expect(o2).to.be("12")
            lust.expect(o3).to.be(13)
        end)

        lust.it("pass_call_level", function()
            local o
            local function chcall_level(a)
                o = a
            end

            local called
            local hf = Modularity.PreHook(chcall_level, function(level, a)
                called = true
                local info = debug.getinfo(level)

                lust.expect(info).to.be.a("table")

                lust.expect(info.source).to.be.a("string")

                local str_splut = Modularity.split_str(info.source, "/")
                lust.expect(str_splut[1]).to.be(Package.GetName())

                lust.expect(info.name).to.be("chcall_level")

                lust.expect(a).to.be(1)
            end, nil, true)
            table.insert(cur_hooks, {target = chcall_level, hook_func = hf})

            chcall_level(1)

            lust.expect(called).to.be.truthy()
            lust.expect(o).to.be(1)
        end)

        lust.it("pass_args_info", function()
            local o, o2, o3
            local function pai(a, a2, a3)
                o = a
                o2 = a2
                o3 = a3
            end

            local called
            local hf = Modularity.PreHook(pai, function(a, a2, a3)
                called = true

                --print(NanosTable.Dump(a), NanosTable.Dump(a2), NanosTable.Dump(a3))

                lust.expect(a).to.be.a("table")
                lust.expect(a2).to.be.a("table")
                lust.expect(a3).to.be.a("table")

                lust.expect(a.local_index).to.be(1)
                lust.expect(a2.local_index).to.be(2)
                lust.expect(a3.local_index).to.be(3)

                lust.expect(a.name).to.be("a")
                lust.expect(a2.name).to.be("a2")
                lust.expect(a3.name).to.be("a3")

                lust.expect(a.value).to.be(1)
                lust.expect(a2.value).to.be("2")
                lust.expect(a3.value).to.be(3)
            end, nil, nil, true)
            table.insert(cur_hooks, {target = pai, hook_func = hf})

            pai(1, "2", 3)

            lust.expect(called).to.be.truthy()
            lust.expect(o).to.be(1)
            lust.expect(o2).to.be("2")
            lust.expect(o3).to.be(3)
        end)

        lust.it("nil handling", function()
            local o, o2, o3
            local function checknil_offset(a, a2, a3)
                o = a
                o2 = a2
                o3 = a3
            end

            local hf = Modularity.PreHook(checknil_offset, function(a, a2, a3)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(nil)
                lust.expect(a3).to.be(3)
                return 11, "12", nil
            end, true)
            table.insert(cur_hooks, {target = checknil_offset, hook_func = hf})

            checknil_offset(1, nil, 3)

            lust.expect(o).to.be(11)
            lust.expect(o2).to.be("12")
            lust.expect(o3).to.be(nil)

            local hf2 = Modularity.PreHook(checknil_offset, function(a, a2, a3)
                lust.expect(a).to.be(11)
                lust.expect(a2).to.be("12")
                lust.expect(a3).to.be(nil)
                return nil, "12", nil
            end, true)
            table.insert(cur_hooks, {target = checknil_offset, hook_func = hf2})

            checknil_offset(1, nil, 3)

            lust.expect(o).to.be(nil)
            lust.expect(o2).to.be("12")
            lust.expect(o3).to.be(nil)
        end)

        lust.it("HookStack", function()
            local o
            local function H_HookStack_f(a)
                o = a
            end

            local hf = Modularity.PreHook(H_HookStack_f, function(a)
                lust.expect(a).to.be(1)
                return 11
            end, true)
            table.insert(cur_hooks, {target = H_HookStack_f, hook_func = hf})

            local called
            local hf2 = Modularity.PreHook(H_HookStack_f, function(a)
                called = true
                lust.expect(a).to.be(11)
            end)
            table.insert(cur_hooks, {target = H_HookStack_f, hook_func = hf2})

            H_HookStack_f(1)

            lust.expect(called).to.be.truthy()
            lust.expect(o).to.be(11)
        end)

        lust.it("all params set", function()
            local o, o2
            local function aps(a, a2)
                o = a
                o2 = a2
            end

            local called
            local hf = Modularity.PreHook(aps, function(level, a, a2)
                called = true
                local info = debug.getinfo(level)

                lust.expect(info).to.be.a("table")

                lust.expect(info.source).to.be.a("string")

                local str_splut = Modularity.split_str(info.source, "/")
                lust.expect(str_splut[1]).to.be(Package.GetName())

                lust.expect(info.name).to.be("aps")

                lust.expect(a).to.be.a("table")
                lust.expect(a2).to.be.a("table")

                lust.expect(a.local_index).to.be(1)
                lust.expect(a2.local_index).to.be(2)

                lust.expect(a.name).to.be("a")
                lust.expect(a2.name).to.be("a2")

                lust.expect(a.value).to.be(1)
                lust.expect(a2.value).to.be(2)

                return a.value + 10, a2.value + 10
            end, true, true, true, Package.GetName())
            table.insert(cur_hooks, {target = aps, hook_func = hf})

            aps(1, 2)

            lust.expect(called).to.be.truthy()
            lust.expect(o).to.be(11)
            lust.expect(o2).to.be(12)
        end)

        lust.it("varargs", function()
            local o, o2
            local function vtfunc(...)
                local tbl = {...}
                o = tbl[1]
                o2 = tbl[2]
            end

            local called
            local hf = Modularity.PreHook(vtfunc, function(a, a2, a3)
                called = true

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
                lust.expect(a3).to.be(nil)
                return a + 10, a2 + 10
            end, true)
            table.insert(cur_hooks, {target = vtfunc, hook_func = hf})

            vtfunc(1, 2)

            lust.expect(called).to.be.truthy()
            lust.expect(o).to.be(11)
            lust.expect(o2).to.be(12)
        end)
    end)

    lust.describe("EndHook", function()
        lust.it("basic", function()
            local called
            local hf = Modularity.EndHook(testfunc, function()
                called = true
            end)
            lust.expect(hf).to.be.a("function")
            table.insert(cur_hooks, {target = testfunc, hook_func = hf})

            testfunc()

            lust.expect(called).to.be.truthy()
        end)

        lust.it("args_passed", function()
            local function cfargs(a, a2)
                return a+10, a2+10
            end

            local called
            local hf = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called = true

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
                lust.expect(r).to.be(11)
                lust.expect(r2).to.be(12)
            end, Modularity.Enums.EndHookParams.CallAndReturnParams)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf})

            local called2
            local hf2 = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called2 = true

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
                lust.expect(r).to.be(nil)
                lust.expect(r2).to.be(nil)
            end, Modularity.Enums.EndHookParams.CallParams)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf2})

            local called3
            local hf3 = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called3 = true

                lust.expect(a).to.be(nil)
                lust.expect(a2).to.be(nil)
                lust.expect(r).to.be(nil)
                lust.expect(r2).to.be(nil)
            end, Modularity.Enums.EndHookParams.NoParams)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf3})

            local called4
            local hf4 = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called4 = true

                lust.expect(a).to.be(11)
                lust.expect(a2).to.be(12)
                lust.expect(r).to.be(nil)
                lust.expect(r2).to.be(nil)
            end, Modularity.Enums.EndHookParams.ReturnParams)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf4})

            local o, o2 = cfargs(1, 2)

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()
            lust.expect(called3).to.be.truthy()
            lust.expect(called4).to.be.truthy()

            lust.expect(o).to.be(11)
            lust.expect(o2).to.be(12)
        end)

        lust.it("alter_args", function()
            local function cfargs(a, a2)
                return a+10, a2+10
            end

            local called
            local hf = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called = true
                return a+10, a2+10, r+10, r2+10
            end, Modularity.Enums.EndHookParams.CallAndReturnParams, true)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf})

            local called2
            local hf2 = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called2 = true

                lust.expect(a).to.be(11)
                lust.expect(a2).to.be(12)
                lust.expect(r).to.be(21)
                lust.expect(r2).to.be(22)

                return a+10, a2+10, r+10, r2+10
            end, Modularity.Enums.EndHookParams.CallAndReturnParams)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf2})

            local o, o2 = cfargs(1, 2)

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()

            lust.expect(o).to.be(21)
            lust.expect(o2).to.be(22)
        end)

        lust.it("args_passed1+alter_args", function()
            local function cfargs(a, a2)
                return a+10, a2+10
            end

            local called
            local hf = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called = true
                return a+10, a2+10, 21, 22
            end, Modularity.Enums.EndHookParams.CallParams, true)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf})

            local called2
            local hf2 = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called2 = true

                lust.expect(a).to.be(11)
                lust.expect(a2).to.be(12)
                lust.expect(r).to.be(11)
                lust.expect(r2).to.be(12)

                return a+10, a2+10, r+10, r2+10
            end, Modularity.Enums.EndHookParams.CallAndReturnParams)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf2})

            local o, o2 = cfargs(1, 2)

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()

            lust.expect(o).to.be(11)
            lust.expect(o2).to.be(12)
        end)

        lust.it("args_passed2+alter_args", function()
            local function cfargs(a, a2)
                return a+10, a2+10
            end

            local called
            local hf = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called = true
                return 11, 12, 21, 22
            end, Modularity.Enums.EndHookParams.NoParams, true)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf})

            local called2
            local hf2 = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called2 = true

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
                lust.expect(r).to.be(11)
                lust.expect(r2).to.be(12)

                return a+10, a2+10, r+10, r2+10
            end, Modularity.Enums.EndHookParams.CallAndReturnParams)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf2})

            local o, o2 = cfargs(1, 2)

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()

            lust.expect(o).to.be(11)
            lust.expect(o2).to.be(12)
        end)

        lust.it("args_passed3+alter_args", function()
            local function cfargs(a, a2)
                return a+10, a2+10
            end

            local called
            local hf = Modularity.EndHook(cfargs, function(r, r2)
                called = true
                return r+10, r2+10, 5678, 2635
            end, Modularity.Enums.EndHookParams.ReturnParams, true)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf})

            local called2
            local hf2 = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called2 = true

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
                lust.expect(r).to.be(21)
                lust.expect(r2).to.be(22)

                return a+10, a2+10, r+10, r2+10
            end, Modularity.Enums.EndHookParams.CallAndReturnParams)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf2})

            local o, o2 = cfargs(1, 2)

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()

            lust.expect(o).to.be(21)
            lust.expect(o2).to.be(22)
        end)

        lust.it("pass_call_level", function()
            local o
            local function chcall_level(a)
                o = a
                return a + 10
            end

            local called
            local hf = Modularity.EndHook(chcall_level, function(level, a, r)
                called = true
                local info = debug.getinfo(level)

                lust.expect(info).to.be.a("table")

                lust.expect(info.source).to.be.a("string")

                local str_splut = Modularity.split_str(info.source, "/")
                lust.expect(str_splut[1]).to.be(Package.GetName())

                lust.expect(info.name).to.be("chcall_level")

                lust.expect(a).to.be(1)
                lust.expect(r).to.be(11)
            end, Modularity.Enums.EndHookParams.CallAndReturnParams, nil, true)
            table.insert(cur_hooks, {target = chcall_level, hook_func = hf})

            local r = chcall_level(1)

            lust.expect(called).to.be.truthy()
            lust.expect(o).to.be(1)
            lust.expect(r).to.be(11)
        end)

        lust.it("pass_args_info", function()
            local function cfargs(a, a2)
                return a+10, a2+10
            end

            local called
            local hf = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called = true

                lust.expect(a).to.be.a("table")
                lust.expect(a2).to.be.a("table")
                lust.expect(r).to.be.a("table")
                lust.expect(r2).to.be.a("table")

                lust.expect(a.name).to.be("a")
                lust.expect(a2.name).to.be("a2")

                lust.expect(a.value).to.be(1)
                lust.expect(a2.value).to.be(2)
                lust.expect(r.value).to.be(11)
                lust.expect(r2.value).to.be(12)

                lust.expect(a.arg_type).to.be("param")
                lust.expect(a2.arg_type).to.be("param")
                lust.expect(r.arg_type).to.be("return")
                lust.expect(r2.arg_type).to.be("return")

                lust.expect(a.local_index).to.be(1)
                lust.expect(a2.local_index).to.be(2)
                lust.expect(r.local_index).to.be(3)
                lust.expect(r2.local_index).to.be(4)
            end, Modularity.Enums.EndHookParams.CallAndReturnParams, false, false, true)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf})

            local o, o2 = cfargs(1, 2)

            lust.expect(called).to.be.truthy()
            lust.expect(o).to.be(11)
            lust.expect(o2).to.be(12)
        end)

        lust.it("nil handling", function()
            local function cfargs(a, a2, a3)
                return a, a2, a3
            end

            local called
            local hf = Modularity.EndHook(cfargs, function(a, a2, a3, r, r2, r3)
                called = true

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(nil)
                lust.expect(a3).to.be(3)

                lust.expect(r).to.be(1)
                lust.expect(r2).to.be(nil)
                lust.expect(r3).to.be(3)

                return nil, a2, a3, r, r2, nil
            end, Modularity.Enums.EndHookParams.CallAndReturnParams, true)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf})

            local called2
            local hf2 = Modularity.EndHook(cfargs, function(a, a2, a3, r, r2, r3)
                called2 = true

                lust.expect(a).to.be(nil)
                lust.expect(a2).to.be(nil)
                lust.expect(a3).to.be(3)

                lust.expect(r).to.be(1)
                lust.expect(r2).to.be(nil)
                lust.expect(r3).to.be(nil)
            end, Modularity.Enums.EndHookParams.CallAndReturnParams)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf2})

            local o, o2, o3 = cfargs(1, nil, 3)

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()

            lust.expect(o).to.be(1)
            lust.expect(o2).to.be(nil)
            lust.expect(o3).to.be(nil)
        end)

        lust.it("HookStack", function()
            local function cfargs(a, a2)
                return a+10, a2+10
            end

            local called
            local hf = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called = true
                return a+10, a2+10, r+10, r2+10
            end, Modularity.Enums.EndHookParams.CallAndReturnParams, true)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf})

            local called2
            local hf2 = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called2 = true

                lust.expect(a).to.be(11)
                lust.expect(a2).to.be(12)
                lust.expect(r).to.be(nil)
                lust.expect(r2).to.be(nil)

                return a+10, a2+10, -1, -2
            end, Modularity.Enums.EndHookParams.CallParams, true)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf2})

            local called3
            local hf3 = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called3 = true

                lust.expect(a).to.be(21)
                lust.expect(a2).to.be(22)
                lust.expect(r).to.be(nil)
                lust.expect(r2).to.be(nil)

                return a+10, a2+10, -1, -2
            end, Modularity.Enums.EndHookParams.ReturnParams, true)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf3})

            local called4
            local hf4 = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called4 = true

                lust.expect(a).to.be(nil)
                lust.expect(a2).to.be(nil)
                lust.expect(r).to.be(nil)
                lust.expect(r2).to.be(nil)

                return -1, -2, -3, -4
            end, Modularity.Enums.EndHookParams.NoParams, true)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf4})

            local called5
            local hf5 = Modularity.EndHook(cfargs, function(a, a2, r, r2)
                called5 = true

                lust.expect(a).to.be(21)
                lust.expect(a2).to.be(22)
                lust.expect(r).to.be(31)
                lust.expect(r2).to.be(32)

                return a+10, a2+10, r+10, r2+10
            end, Modularity.Enums.EndHookParams.CallAndReturnParams)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf5})

            local o, o2 = cfargs(1, 2)

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()
            lust.expect(called3).to.be.truthy()
            lust.expect(called4).to.be.truthy()
            lust.expect(called5).to.be.truthy()

            lust.expect(o).to.be(31)
            lust.expect(o2).to.be(32)
        end)

        lust.it("all params set", function()
            local function cfargs(a, a2)
                return a+10, a2+10
            end

            local called
            local hf = Modularity.EndHook(cfargs, function(level, r, r2)
                called = true

                local info = debug.getinfo(level)

                lust.expect(info).to.be.a("table")

                lust.expect(info.source).to.be.a("string")

                local str_splut = Modularity.split_str(info.source, "/")
                lust.expect(str_splut[1]).to.be(Package.GetName())

                lust.expect(info.name).to.be("cfargs")

                return r.value+10, r2.value+10
            end, Modularity.Enums.EndHookParams.ReturnParams, true, true, true)
            table.insert(cur_hooks, {target = cfargs, hook_func = hf})

            local o, o2 = cfargs(-20, -21)

            lust.expect(called).to.be.truthy()

            lust.expect(o).to.be(0)
            lust.expect(o2).to.be(-1)
        end)

        lust.it("varargs", function()
            local function vtfunc(...)
                local tbl = {...}

                return tbl[1] + 10, tbl[2] + 10
            end

            local called
            local hf = Modularity.EndHook(vtfunc, function(a, a2, r, r2, wut)
                called = true

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
                lust.expect(r).to.be(11)
                lust.expect(r2).to.be(12)

                lust.expect(wut).to.be(nil)
                return a + 10, a2 + 10, r + 10, r2 + 10
            end, Modularity.Enums.EndHookParams.CallAndReturnParams, true)
            table.insert(cur_hooks, {target = vtfunc, hook_func = hf})

            local called2
            local hf2 = Modularity.EndHook(vtfunc, function(a, a2, r, r2, wut)
                called2 = true

                lust.expect(a).to.be(11)
                lust.expect(a2).to.be(12)
                lust.expect(r).to.be(21)
                lust.expect(r2).to.be(22)

                lust.expect(wut).to.be(nil)
                return a + 10, a2 + 10, r + 10, r2 + 10
            end, Modularity.Enums.EndHookParams.CallAndReturnParams)
            table.insert(cur_hooks, {target = vtfunc, hook_func = hf2})

            local o, o2 = vtfunc(1, 2)

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()
            lust.expect(o).to.be(21)
            lust.expect(o2).to.be(22)
        end)

        lust.it("error", function()
            local function gonnaerror()
                --print("bef error")
                local _ = {}
                _[nil] = true
                print(_[nil])
            end

            local good = true
            local hf = Modularity.EndHook(gonnaerror, function(...)
                good = false

                local args = {...}
                print(NanosTable.Dump(args))

            end, Modularity.Enums.EndHookParams.CallAndReturnParams)
            table.insert(cur_hooks, {target = gonnaerror, hook_func = hf})

            lust.expect(gonnaerror).to.fail()

            --print("After error")
            lust.expect(good).to.be.truthy()
        end)
    end)

    lust.describe("PreHookName", function()
        lust.it("basic", function()
            local called

            local hf = Modularity.PreHookName("testfunc", function()
                called = true
            end)
            lust.expect(hf).to.be.a("function")
            table.insert(cur_hooks, {target = "testfunc", hook_func = hf})

            testfunc()

            lust.expect(called).to.be.truthy()
        end)

        lust.it("deny_other_p_name", function()
            local good = true

            local hf = Modularity.PreHookName("testfunc", function()
                good = false
            end, "unknown")
            table.insert(cur_hooks, {target = "testfunc", hook_func = hf})

            testfunc()

            lust.expect(good).to.be.truthy()
        end)
    end)

    lust.describe("EndHookName", function()
        lust.it("basic", function()
            local called

            local hf = Modularity.EndHookName("testfunc", function()
                called = true
            end)
            lust.expect(hf).to.be.a("function")
            table.insert(cur_hooks, {target = "testfunc", hook_func = hf})

            testfunc()

            lust.expect(called).to.be.truthy()
        end)

        lust.it("deny_other_p_name", function()
            local good = true

            local hf = Modularity.EndHookName("testfunc", function()
                good = false
            end, nil, "unknown")
            table.insert(cur_hooks, {target = "testfunc", hook_func = hf})

            testfunc()

            lust.expect(good).to.be.truthy()
        end)
    end)

    lust.describe("Mixed", function()
        lust.it("HookStack", function()
            local in_a, in_a2, va
            local function hs_func(a, a2, ...)
                in_a = a
                in_a2 = a2
                va = {...}
                return a + 10, a2 + 10, va[1] + 10
            end

            local called
            local hf = Modularity.PreHook(hs_func, function(a, a2, ...)
                called = true
                local args = {...}
                return a+10, a2, args[1] + 10
            end, true)
            table.insert(cur_hooks, {target = hs_func, hook_func = hf})

            local called2
            local hf2 = Modularity.EndHook(hs_func, function(a, a2, a3, a4, r, r2, r3, wut)
                called2 = true

                lust.expect(a).to.be(11)
                lust.expect(a2).to.be(2)
                lust.expect(a3).to.be(13)
                lust.expect(a4).to.be(nil)
                lust.expect(r).to.be(21)
                lust.expect(r2).to.be(12)
                lust.expect(r3).to.be(23)

                lust.expect(wut).to.be(nil)

                return a, a2, a3, a4, r+10, r2+10, r3
            end, Modularity.Enums.EndHookParams.CallAndReturnParams, true)
            table.insert(cur_hooks, {target = hs_func, hook_func = hf2})

            local o, o2, o3 = hs_func(1, 2, 3, 4)

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()

            lust.expect(in_a).to.be(11)
            lust.expect(in_a2).to.be(2)
            lust.expect(va).to.have_n_fields(1)
            lust.expect(va[1]).to.be(13)

            lust.expect(o).to.be(31)
            lust.expect(o2).to.be(22)
            lust.expect(o3).to.be(23)
        end)

        lust.it("Pure_Lua_Call_Return", function()
            local function pure_lua(a, a2, ...)
                return a+10, a2+10
            end

            local args

            local called
            local hf = Modularity.PreHook(pure_lua, function(...)
                called = true

                args = {...}

                lust.expect(args).to.have_n_fields(3)
                for i, v in pairs(args) do
                    lust.expect(v.arg_type).to.be("param")
                end
            end, false, false, true)
            table.insert(cur_hooks, {target = pure_lua, hook_func = hf})

            local called2
            local hf2 = Modularity.EndHook(pure_lua, function(...)
                called2 = true
                local eh_args = {...}

                local params_count = 0
                local ret_count = 0

                lust.expect(eh_args).to.have_n_fields(5)
                for i, v in pairs(eh_args) do
                    if v.arg_type == "param" then
                        lust.expect(v).to.equal(args[i])
                        params_count = params_count + 1
                    elseif v.arg_type == "return" then
                        ret_count = ret_count + 1
                    end
                end

                lust.expect(params_count).to.be(3)
                lust.expect(ret_count).to.be(2)
            end, Modularity.Enums.EndHookParams.CallAndReturnParams, false, false, true)
            table.insert(cur_hooks, {target = pure_lua, hook_func = hf2})

            local o, o2 = pure_lua(1, 2, 3)

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()

            lust.expect(o).to.be(11)
            lust.expect(o2).to.be(12)
        end)

        lust.it("Lua_C_Call_Return", function()
            local _a

            local called
            local hf = Modularity.PreHook(string.len, function(a, a2)
            --local hf = Modularity.PreHook(string.len, function(...)
                called = true

                --local args = {...}
                --print(NanosTable.Dump(args))

                --print(NanosTable.Dump(a2))

                lust.expect(a.value).to.be("somestr")
                lust.expect(a2).to.be(nil)

                _a = a
            end, false, false, true)
            table.insert(cur_hooks, {target = string.len, hook_func = hf})

            local called2
            local hf2 = Modularity.EndHook(string.len, function(a, r, ...)
                called2 = true

                local a_p = {...}

                --print(NanosTable.Dump(a), NanosTable.Dump(_a))

                lust.expect(a).to.equal(_a)
                lust.expect(r.value).to.be(7)

                lust.expect(a_p).to.equal({})
            end, Modularity.Enums.EndHookParams.CallAndReturnParams, false, false, true)
            table.insert(cur_hooks, {target = string.len, hook_func = hf2})

            local o = string.len("somestr")

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()

            lust.expect(o).to.be(7)
        end)

        lust.it("Nanos_C_Call_Return", function()
            --Nanos API has a different behavior, test failing on 1.57.1, issue #932

            local prop = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
            prop:SetValue("KEY", "VALUE", false)

            local _a, _a2

            local called
            local hf = Modularity.PreHook(prop.GetValue, function(a, a2, a3)
                called = true

                lust.expect(a.value).to.be(prop)
                lust.expect(a2.value).to.be("KEY")
                lust.expect(a3).to.be(nil)

                _a = a
                _a2 = a2
            end, false, false, true)
            table.insert(cur_hooks, {target = prop.GetValue, hook_func = hf})

            local called2
            local hf2 = Modularity.EndHook(prop.GetValue, function(a, a2, r, ...)
                called2 = true

                local a_p = {...}

                print(NanosTable.Dump(a))

                lust.expect(a).to.equal(_a)
                lust.expect(a2).to.equal(_a2)
                lust.expect(r.value).to.be("VALUE")

                lust.expect(a_p).to.equal({})
            end, Modularity.Enums.EndHookParams.CallAndReturnParams, false, false, true)
            table.insert(cur_hooks, {target = prop.GetValue, hook_func = hf2})

            local o = prop:GetValue("KEY")

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()

            lust.expect(o).to.be("VALUE")

            prop:Destroy()
        end)
    end)

    lust.it("GetHooksTables", function()
        local tables = Modularity.GetHooksTables()
        local fc = 4
        lust.expect(tables).to.have_n_fields(fc)
        for i, v in pairs(tables) do
            lust.expect(i).to.be.a("number")
            if i <= 0 then
                error("Negative index")
            end
            if i > fc then
                error("Index too high")
            end
            lust.expect(v).to.be.a("table")
        end
    end)

    lust.it("sethook", function()
        local called = 0
        local thookfunc = function(a)
            called = called + 1
            lust.expect(a).to.be(1)
        end

        local hook_call_count = 0
        debug.sethook(function(call_type)
            local info = debug.getinfo(2)
            lust.expect(info).to.be.a("table")
            if info.name == "thookfunc" then
                hook_call_count = hook_call_count + 1
                lust.expect(info.func).to.be(thookfunc)
                if called == 0 then
                    lust.expect(call_type).to.be("call")
                else
                    lust.expect(call_type).to.be("return")
                end
            end
        end, "cr")

        thookfunc(1)

        debug.sethook()

        thookfunc(1)

        lust.expect(called).to.be(2)
        lust.expect(hook_call_count).to.be(2)
    end)
end)

lust.describe("Envs.lua", function()
    testenvvar = "testenvvar original"

    --print(_ENV["testenvvar"])

    lust.it("IsENVValid", function()
        lust.expect(Modularity.IsENVValid(_ENV)).to.be.truthy()
    end)

    lust.it("RefreshRegistryEnvs", function()
        Modularity.RefreshRegistryEnvs()

        lust.expect(Modularity.Envs).to.be.a("table")

        lust.expect(Modularity.Envs[Package.GetName()]).to.be(_ENV)
    end)

    lust.it("GetENVValue", function()
        lust.expect(Modularity.GetENVValue(Package.GetName(), "testenvvar")).to.be(testenvvar)
    end)

    lust.it("SetENVValue", function()
        lust.expect(Modularity.SetENVValue(Package.GetName(), "testenvvar", "testenvvar modified")).to.be.truthy()

        lust.expect(Modularity.GetENVValue(Package.GetName(), "testenvvar")).to.be("testenvvar modified")
    end)
end)


lust.it("Test Class Init", function()
    MT_ID = 1

    MT_ALL = {}

    MT_ALL_KEYID = {}

    local MT_Class_Meta = {}

    function MT_Class_Meta.__call()
        local ins = setmetatable({}, MT_Class.prototype)

        local this_id = MT_ID
        MT_ID = MT_ID + 1
        ins.ID = this_id

        ins._MTCLASS_INSTANCE = true
        ins.Valid = true

        local l_count = Modularity.table_last_count(MT_ALL)
        MT_ALL[l_count + 1] = ins

        MT_ALL_KEYID[this_id] = l_count + 1

        ins:CallEvent("Spawn")

        return MT_ALL[l_count + 1]
    end

    MT_Class = {}
    MT_Class.__index = MT_Class
    MT_Class.prototype = {}
    MT_Class.prototype.__index = MT_Class.prototype
    setmetatable(MT_Class, MT_Class_Meta)

    Modularity.AttachStaticEventSystem(MT_Class)
    Modularity.AttachInstanceEventSystem(MT_Class.prototype, MT_Class)

    --Modularity.AddGlobalWatchArgsForClassLinks(classlink_id)

    --Modularity.SetNativeEventsClassLinkCompression(classlink_id, Modularity.Default_Configs.Compression.All)

    function MT_Class.prototype:IsValid(is_from_self)
        local valid = self.Valid
        if (not valid and is_from_self) then
            return error("This entity is not valid")
        end
        return valid
    end

    function MT_Class.prototype:GetID()
        if self:IsValid(true) then
            return self.ID
        end
    end

    function MT_Class.prototype:Destroy()
        if self:IsValid(true) then
            self.Value = false
            local all_index = MT_ALL_KEYID[self.ID]
            MT_ALL_KEYID[self.ID] = nil
            if all_index then
                MT_ALL[all_index] = nil
            end
            return true
        end
    end
end)

lust.describe("Events_System.lua", function()

    lust.describe("Static Events", function()
        local cur_events = {}
        lust.after(function()
            for k, v in pairs(cur_events) do
                Modularity.Unsubscribe(v.event_name, v.callback)
            end
            cur_events = {}
        end)

        lust.it("unsub", function()
            local good = true
            local ef = Modularity.Subscribe("UnsubTest", function()
                good = false
            end)
            lust.expect(ef).to.be.a("function")

            local ret = Modularity.Unsubscribe("UnsubTest", ef)
            lust.expect(ret).to.be.truthy()

            Modularity.CallEvent("UnsubTest")

            lust.expect(good).to.be.truthy()
        end)

        lust.it("basic", function()
            local called

            local ev_name = "BasicTest"
            local ef = Modularity.Subscribe(ev_name, function(a, a2)
                called = true

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
            end)
            table.insert(cur_events, {event_name = ev_name, callback = ef})

            Modularity.CallEvent(ev_name, 1, 2)

            lust.expect(called).to.be.truthy()
        end)

        lust.it("chain", function()
            local ev_name = "ChainTest"

            local called
            local ef = Modularity.Subscribe(ev_name, function(a, a2)
                called = true

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
            end)
            table.insert(cur_events, {event_name = ev_name, callback = ef})

            local called2
            local ef2 = Modularity.Subscribe(ev_name, function(a, a2)
                called2 = true

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
            end)
            table.insert(cur_events, {event_name = ev_name, callback = ef2})

            Modularity.CallEvent(ev_name, 1, 2)

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()
        end)

        lust.it("exactsame", function()
            local called = 0
            local ev_func = function(a, a2)
                called = called + 1

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
            end

            local ev_name = "ExactSame"

            for i = 1, 10 do
                local ef = Modularity.Subscribe(ev_name, ev_func)
                --table.insert(cur_events, {event_name = ev_name, callback = ef})
            end

            Modularity.CallEvent(ev_name, 1, 2)

            lust.expect(called).to.be(10)

            Modularity.Unsubscribe(ev_name, ev_func)

            Modularity.CallEvent(ev_name, 1, 2)
            lust.expect(called).to.be(10)
        end)

        lust.it("UnsubInside", function()
            local ev_name = "UnsubInside"

            local called = 0
            local ef
            ef = Modularity.Subscribe(ev_name, function(a, a2)
                called = called + 1

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)

                Modularity.Unsubscribe(ev_name, ef)
            end)

            Modularity.CallEvent(ev_name, 1, 2)

            lust.expect(called).to.be(1)
        end)

        lust.it("UnsubInsideDiff", function()
            local ev_name = "UnsubInsideDiff"
            local called = 0

            local f1, f2

            f1 = function()
                if called == 0 then
                    called = 1
                    Modularity.Unsubscribe(ev_name, f2)
                else
                    called = called + 1
                end
            end

            f2 = function()
                if called == 0 then
                    called = 1
                    Modularity.Unsubscribe(ev_name, f1)
                else
                    called = called + 1
                end

            end

            local ef = Modularity.Subscribe(ev_name, f1)
            table.insert(cur_events, {event_name = ev_name, callback = ef})

            local ef2 = Modularity.Subscribe(ev_name, f2)
            table.insert(cur_events, {event_name = ev_name, callback = ef2})

            Modularity.CallEvent(ev_name, 1, 2)

            lust.expect(called).to.be(1)
        end)

        lust.it("UnsubInsideExactSame", function()
            local ev_name = "UnsubInsideExactSame"

            local called = 0
            local ev_func
            ev_func = function(a, a2)
                called = called + 1

                Modularity.Unsubscribe(ev_name, ev_func)

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
            end

            for i = 1, 10 do
                local ef = Modularity.Subscribe(ev_name, ev_func)
                --table.insert(cur_events, {event_name = ev_name, callback = ef})
            end

            Modularity.CallEvent(ev_name, 1, 2)

            lust.expect(called).to.be(1)
        end)

        lust.it("CallEvent returns", function()
            local ev_name = "CE_returns"

            local called
            local ef = Modularity.Subscribe(ev_name, function(a, a2)
                called = true

                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)

                return a + 10, a2 + 10
            end)
            table.insert(cur_events, {event_name = ev_name, callback = ef})

            local ret = Modularity.CallEvent(ev_name, 1, 2)

            lust.expect(called).to.be.truthy()

            --print(NanosTable.Dump(ret))
            lust.expect(ret).to.have_n_fields(1)

            local fret = ret[ef]
            lust.expect(fret).to.be.a("table")

            lust.expect(fret).to.have_n_fields(1)

            local ret1 = fret[1]
            lust.expect(ret1).to.be.a("table")

            lust.expect(ret1[1]).to.be(11)
            lust.expect(ret1[2]).to.be(12)
            lust.expect(ret1.n).to.be(2)
        end)
    end)

    lust.describe("Instance Events", function()
        local cur_events = {}
        local cur_instances = {}
        lust.after(function()
            for k, v in pairs(cur_events) do
                if v.static then
                    Modularity.Unsubscribe(v.event_name, v.callback)
                elseif v.instance then
                    v.instance:Unsubscribe(v.event_name, v.callback)
                    --v.instance:Destroy()
                end
            end
            cur_events = {}

            for k, v in pairs(cur_instances) do
                v:Destroy()
            end
            cur_instances = {}
        end)

        lust.it("unsub", function()
            local ins = MT_Class()
            lust.expect(ins).to.be.a("table")
            table.insert(cur_instances, ins)

            local good = true
            local ef = ins:Subscribe("UnsubTest", function()
                good = false
            end)
            lust.expect(ef).to.be.a("function")

            local ret = ins:Unsubscribe("UnsubTest", ef)
            lust.expect(ret).to.be.truthy()

            ins:CallEvent("UnsubTest")

            lust.expect(good).to.be.truthy()
        end)

        lust.it("basic", function()
            local ins = MT_Class()
            table.insert(cur_instances, ins)

            local ev_name = "basic"

            local called
            local ef = ins:Subscribe(ev_name, function(_ins, a, a2)
                called = true

                lust.expect(_ins).to.be(ins)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
            end)
            table.insert(cur_events, {instance = ins, event_name = ev_name, callback = ef})

            ins:CallEvent(ev_name, 1, 2)

            lust.expect(called).to.be.truthy()
        end)

        lust.it("ins_and_static", function()
            local ins = MT_Class()
            table.insert(cur_instances, ins)

            local ev_name = "ins_and_static"

            local called
            local ef = ins:Subscribe(ev_name, function(_ins, a, a2)
                called = true

                lust.expect(_ins).to.be(ins)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
            end)
            table.insert(cur_events, {instance = ins, event_name = ev_name, callback = ef})

            local called2
            local ef2 = MT_Class.Subscribe(ev_name, function(_ins, a, a2)
                called2 = true

                lust.expect(_ins).to.be(ins)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
            end)
            table.insert(cur_events, {static = true, event_name = ev_name, callback = ef2})

            ins:CallEvent(ev_name, 1, 2)

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()
        end)

        lust.it("chain", function()
            local ins = MT_Class()
            table.insert(cur_instances, ins)

            local ev_name = "chain"

            local called = 0
            for i = 1, 10 do
                local ef = ins:Subscribe(ev_name, function(_ins, a, a2)
                    called = called + 1

                    lust.expect(_ins).to.be(ins)
                    lust.expect(a).to.be(1)
                    lust.expect(a2).to.be(2)
                end)
                table.insert(cur_events, {instance = ins, event_name = ev_name, callback = ef})
            end

            ins:CallEvent(ev_name, 1, 2)

            lust.expect(called).to.be(10)
        end)

        lust.it("exactsame", function()
            local ins = MT_Class()
            table.insert(cur_instances, ins)

            local ev_name = "exactsame"

            local called = 0

            local function exactsame_func(_ins, a, a2)
                called = called + 1

                lust.expect(_ins).to.be(ins)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
            end
            for i = 1, 10 do
                local ef = ins:Subscribe(ev_name, exactsame_func)
                --table.insert(cur_events, {instance = ins, event_name = ev_name, callback = ef})
            end

            ins:CallEvent(ev_name, 1, 2)

            lust.expect(called).to.be(10)

            ins:Unsubscribe(ev_name, exactsame_func)

            lust.expect(called).to.be(10)
        end)

        lust.it("UnsubInside", function()
            local ins = MT_Class()
            table.insert(cur_instances, ins)

            local ev_name = "UnsubInside"

            local called_ins = 0
            local ef
            ef = ins:Subscribe(ev_name, function(_ins, a, a2)
                called_ins = called_ins + 1

                lust.expect(_ins).to.be(ins)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)

                ins:Unsubscribe(ev_name, ef)
            end)
            --table.insert(cur_events, {instance = ins, event_name = ev_name, callback = ef})

            local called_static = 0
            local ef2
            ef2 = MT_Class.Subscribe(ev_name, function(_ins, a, a2)
                called_static = called_static + 1

                lust.expect(_ins).to.be(ins)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)

                if called_static == 2 then
                    MT_Class.Unsubscribe(ev_name, ef2)
                end
            end)

            ins:CallEvent(ev_name, 1, 2)

            lust.expect(called_ins).to.be(1)
            lust.expect(called_static).to.be(1)

            ins:CallEvent(ev_name, 1, 2)

            lust.expect(called_ins).to.be(1)
            lust.expect(called_static).to.be(2)

            ins:CallEvent(ev_name, 1, 2)

            lust.expect(called_ins).to.be(1)
            lust.expect(called_static).to.be(2)
        end)

        lust.it("CallEvent returns", function()
            local ins = MT_Class()
            table.insert(cur_instances, ins)

            local ev_name = "CE_returns"

            local called
            local ef = ins:Subscribe(ev_name, function(_ins, a, a2)
                called = true

                lust.expect(_ins).to.be(ins)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)

                return a + 10, a2 + 10
            end)
            table.insert(cur_events, {instance = ins, event_name = ev_name, callback = ef})

            local called2
            local ef2 = MT_Class.Subscribe(ev_name, function(_ins, a, a2)
                called2 = true

                lust.expect(_ins).to.be(ins)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)

                return a + 20, a2 + 20
            end)
            table.insert(cur_events, {static = true, event_name = ev_name, callback = ef2})

            local ret = ins:CallEvent(ev_name, 1, 2)

            lust.expect(called).to.be.truthy()
            lust.expect(called2).to.be.truthy()

            lust.expect(ret).to.be.a("table")
            --print(NanosTable.Dump(ret))
            lust.expect(ret).to.have_n_fields(2)
            lust.expect(ret[ef]).to.have_n_fields(1)
            lust.expect(ret[ef2]).to.have_n_fields(1)
            lust.expect(ret[ef][1]).to.equal({11, 12, n = 2})
            lust.expect(ret[ef2][1]).to.equal({21, 22, n = 2})
        end)
    end)
end)

lust.describe("Deprecated.lua", function()
    lust.it("basic", function()
        local test_table = {}
        local ret = Modularity.AttachDeprecatedSystem(test_table)
        lust.expect(ret).to.be.truthy()

        test_table.key = "something_not_deprecated"

        local ret2 = Modularity.AddClassDeprecatedKey(test_table, "dkey", test_table.key, "key")
        lust.expect(ret2).to.be.truthy()

        lust.expect(test_table.dkey).to.be("something_not_deprecated")

        lust.expect(test_table.key).to.be("something_not_deprecated")

        lust.expect(test_table.sgjezijgs).to.be(nil)
    end)

    lust.it("basic_on_real_class", function()
        local test_class = {}
        setmetatable(test_class, {
            __call = function(t, ...)
                return "__call"
            end
        })

        local ret = Modularity.AttachDeprecatedSystem(test_class)
        lust.expect(ret).to.be.truthy()

        test_class.key = "something_not_deprecated"

        local ret2 = Modularity.AddClassDeprecatedKey(test_class, "dkey", test_class.key, "key")
        lust.expect(ret2).to.be.truthy()

        lust.expect(test_class.dkey).to.be("something_not_deprecated")

        lust.expect(test_class.key).to.be("something_not_deprecated")

        lust.expect(test_class()).to.be("__call")

        lust.expect(test_class.sgjezijgs).to.be(nil)
    end)

    lust.it("class_with_table__index", function()
        local test_class = {}
        test_class.__index = test_class -- ? hmh
        setmetatable(test_class, {
            __call = function(t, ...)
                return "__call"
            end,
            --__index = test_class,
        })

        local ret = Modularity.AttachDeprecatedSystem(test_class)
        lust.expect(ret).to.be.truthy()

        test_class.key = "something_not_deprecated"

        local ret2 = Modularity.AddClassDeprecatedKey(test_class, "dkey", test_class.key, "key")
        lust.expect(ret2).to.be.truthy()

        lust.expect(test_class.dkey).to.be("something_not_deprecated")

        lust.expect(test_class.key).to.be("something_not_deprecated")

        lust.expect(test_class()).to.be("__call")

        lust.expect(test_class.sgjezijgs).to.be(nil)
    end)

    lust.it("class_with_function__index", function()
        local test_class = {}
        setmetatable(test_class, {
            __call = function(t, ...)
                return "__call"
            end,
            __index = function(t, k)
                if k == "somespecial" then
                    return "somespecial_value"
                end
                return rawget(t, k)
            end,
        })

        local ret = Modularity.AttachDeprecatedSystem(test_class)
        lust.expect(ret).to.be.truthy()

        test_class.key = "something_not_deprecated"

        local ret2 = Modularity.AddClassDeprecatedKey(test_class, "dkey", test_class.key, "key")
        lust.expect(ret2).to.be.truthy()

        lust.expect(test_class.dkey).to.be("something_not_deprecated")

        lust.expect(test_class.key).to.be("something_not_deprecated")

        lust.expect(test_class()).to.be("__call")

        lust.expect(test_class.somespecial).to.be("somespecial_value")

        lust.expect(test_class.sgjezijgs).to.be(nil)
    end)
end)

lust.describe("Funcs_Overwrites.lua", function()
    lust.it("OverwritePackageFunction", function()
        function functooverwrite(a, a2)
            return a, a2
        end
        local old_ref = functooverwrite

        local new_f
        function new_f(a, a2)
            local def_f = Modularity.GetOverwrittenDefaultFunction(new_f)
            lust.expect(def_f).to.be(old_ref)
            local o, o2 = def_f(a, a2)
            lust.expect(o).to.be(1)
            lust.expect(o2).to.be(2)
            return a + 10, a2 + 10
        end

        local old_given = Modularity.OverwritePackageFunction(Package.GetName(), "functooverwrite", new_f)

        lust.expect(old_ref).to.be(old_given)

        local o, o2 = functooverwrite(1, 2)
        lust.expect(o).to.be(11)
        lust.expect(o2).to.be(12)

        lust.expect(functooverwrite).to.be(new_f)
    end)

    lust.it("OverwriteEventFunction", function()

        local old_called
        local old_func = function()
            old_called = true
        end

        Events.Subscribe("OverwriteEventFunction", old_func)

        local new_called = 0
        local new_func = function()
            new_called = new_called + 1
        end

        Modularity.OverwriteEventFunction(old_func, new_func)

        Events.Call("OverwriteEventFunction")

        lust.expect(old_called).to.be(nil)
        lust.expect(new_called).to.be(1)

        Events.Unsubscribe("OverwriteEventFunction", old_func) -- Unsub with the old func

        Events.Call("OverwriteEventFunction")
        lust.expect(old_called).to.be(nil)
        lust.expect(new_called).to.be(1)
    end)

    lust.it("SetEntityClassFunction", function()
        local prop = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")

        local new_func
        function new_func(ent)
            if prop:IsValid() then -- if package reloaded the prop was destroyed
                lust.expect(ent).to.be(prop)
            end

            local def_f = Modularity.GetOverwrittenDefaultFunction(new_func)
            lust.expect(def_f).to.be.a("function")

            local ret = def_f(ent)
            if prop:IsValid() then
                lust.expect(ret).to.be.a("number")
            else
                return ret
            end

            return "overwritten"
        end

        Modularity.SetEntityClassFunction("Prop", "GetGrabMode", new_func)

        local ret = prop:GetGrabMode()
        lust.expect(ret).to.be("overwritten")

        prop:Destroy()
    end)
end)

lust.describe("Local_Variables.lua", function()
    lust.it("basic", function()

        local localvars = Modularity.GetFunctionUsedLocalVariables(testlocalvar)

        --print(NanosTable.Dump(localvars))

        lust.expect(localvars).to.have_n_fields(2)

        lust.expect(localvars[1].name).to.be("_ENV")
        lust.expect(localvars[1].index).to.be(1)
        lust.expect(localvars[1].value).to.be(_ENV)

        lust.expect(localvars[2].name).to.be("local_var")
        lust.expect(localvars[2].index).to.be(2)
        lust.expect(localvars[2].value).to.be("local_var original")

        Modularity.SetFunctionUsedLocalVariable(testlocalvar, localvars[2].index, "local_var modified")

        testlocalvar()
    end)
end)

lust.describe("MGroup.lua", function()
    local cur_instances = {}
    lust.after(function()
        for k, v in pairs(cur_instances) do
            v:Destroy()
            if v:IsA(MGroup) then
                v:DestroyGroup()
            end
        end
        cur_instances = {}
    end)

    lust.it("DestroyGroup", function()
        local g = MGroup()
        g:DestroyGroup()
        lust.expect(g.Valid).to_not.be.truthy()
        lust.expect(MGroup.GetPairs()).to.have_n_fields(0)
        lust.expect(MGroup.All_KEYID).to.have_n_fields(0)
        local getaddgelements = function()
            return g.AddGroupElements
        end
        lust.expect(getaddgelements).to.fail()

        lust.expect(getmetatable(g)).to.be(MGroup.destroyed_prototype)
    end)

    lust.it("DestroyIn", function()
        local g = MGroup()
        table.insert(cur_instances, g)

        for i = 1, 10 do
            g:AddGroupElements(Prop(Vector(), Rotator(), "nanos-world::SM_Cube"))
        end

        g:Destroy()
        lust.expect(g:GetGroupElementsPairs()).to.have_n_fields(0)
        lust.expect(g:GetGroupElementsAll()).to.have_n_fields(0)
    end)

    lust.it("basic", function()
        local g = MGroup()
        table.insert(cur_instances, g)

        local p
        for i = 1, 10 do
            p = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
            g:AddGroupElements(p)
        end

        lust.expect(g:GetGroupElementsPairs()).to.have_n_fields(10)
        lust.expect(g:GetGroupElementsAll()).to.have_n_fields(10)

        g:SetLocation(Vector(200, -200, 100))

        local ret = g:GetLocation()
        --print(NanosTable.Dump(ret))
        lust.expect(ret).to.have_n_fields(10)
        for i, v in ipairs(ret) do
            lust.expect(v[1]).to.be(Vector(200, -200, 100))
        end

        lust.expect(g:IsGroupValid()).to.be.truthy()

        lust.expect(g:GetGroupID()).to.be.a("number")

        lust.expect(g:GetGroupElementsCount()).to.be(10)

        lust.expect(g:GetGroupElementByIndex(10)).to.be(p)

        lust.expect(g:GetGroupLastElement()).to.be(p)

        lust.expect(g:GetGroupRandomElement()).to.be.a("userdata")

        lust.expect(g:IsA(MGroup)).to.be.truthy()
        lust.expect(g:IsA(Prop)).to_not.be.truthy()
    end)

    lust.it("create_varargs", function()
        local props = {}
        for i = 1, 10 do
            local p = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
            table.insert(props, p)
        end

        local g = MGroup(table.unpack(props))
        table.insert(cur_instances, g)

        lust.expect(g:GetGroupElementsPairs()).to.have_n_fields(10)
        lust.expect(g:GetGroupElementsAll()).to.have_n_fields(10)
        lust.expect(g:GetGroupElementsCount()).to.be(10)
    end)

    lust.it("create_table", function()
        local props = {}
        for i = 1, 10 do
            local p = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
            table.insert(props, p)
        end

        local g = MGroup(props, true)
        table.insert(cur_instances, g)

        lust.expect(g:GetGroupElementsPairs()).to.have_n_fields(10)
        lust.expect(g:GetGroupElementsAll()).to.have_n_fields(10)
        lust.expect(g:GetGroupElementsCount()).to.be(10)
    end)

    lust.it("add_remove_elements_varargs", function()
        local g = MGroup()
        table.insert(cur_instances, g)

        local props = {}
        local to_be_removed_props = {}
        for i = 1, 10 do
            local p = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
            table.insert(props, p)
            if math.random() >= 0.5 then
                table.insert(to_be_removed_props, p)
                table.insert(cur_instances, p)
            end
        end
        g:AddGroupElements(table.unpack(props))

        lust.expect(g:GetGroupElementsPairs()).to.have_n_fields(10)
        lust.expect(g:GetGroupElementsAll()).to.have_n_fields(10)
        lust.expect(g:GetGroupElementsCount()).to.be(10)

        g:RemoveGroupElements(table.unpack(to_be_removed_props))

        local exp_count = 10-table_count(to_be_removed_props)
        lust.expect(g:GetGroupElementsPairs()).to.have_n_fields(exp_count)
        lust.expect(g:GetGroupElementsAll()).to.have_n_fields(exp_count)
        lust.expect(g:GetGroupElementsCount()).to.be(exp_count)

        local ret = g:GetLocation()
        lust.expect(ret).to.have_n_fields(exp_count)
    end)

    lust.it("add_remove_elements_tables", function()
        local g = MGroup()
        table.insert(cur_instances, g)

        local props = {}
        local to_be_removed_props = {}
        for i = 1, 10 do
            local p = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
            table.insert(props, p)
            if math.random() >= 0.5 then
                table.insert(to_be_removed_props, p)
                table.insert(cur_instances, p)
            end
        end
        g:AddGroupElements(props, true)

        lust.expect(g:GetGroupElementsPairs()).to.have_n_fields(10)
        lust.expect(g:GetGroupElementsAll()).to.have_n_fields(10)
        lust.expect(g:GetGroupElementsCount()).to.be(10)

        g:RemoveGroupElements(to_be_removed_props, true)

        local exp_count = 10-table_count(to_be_removed_props)
        lust.expect(g:GetGroupElementsPairs()).to.have_n_fields(exp_count)
        lust.expect(g:GetGroupElementsAll()).to.have_n_fields(exp_count)
        lust.expect(g:GetGroupElementsCount()).to.be(exp_count)

        local ret = g:GetLocation()
        lust.expect(ret).to.have_n_fields(exp_count)
    end)

    lust.it("Auto Remove On Ent Destroy", function()
        local g = MGroup()
        table.insert(cur_instances, g)

        local props = {}
        local to_be_removed_props = {}
        for i = 1, 10 do
            local p = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
            table.insert(props, p)
            g:AddGroupElements(p)
            if math.random() >= 0.5 then
                table.insert(to_be_removed_props, p)
            end
        end

        local exp_count = 10-table_count(to_be_removed_props)

        for i, v in ipairs(to_be_removed_props) do
            v:Destroy()
        end
        to_be_removed_props = {}

        lust.expect(g:GetGroupElementsPairs()).to.have_n_fields(exp_count)
        lust.expect(g:GetGroupElementsAll()).to.have_n_fields(exp_count)
        lust.expect(g:GetGroupElementsCount()).to.be(exp_count)
    end)

    lust.it("Avoid duplicates", function()
        local p1 = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")

        local g = MGroup(p1, p1, p1)
        table.insert(cur_instances, g)

        local props = {}
        for i = 1, 10 do
            local p = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
            table.insert(props, p)
            g:AddGroupElements(p) -- Insert
        end
        g:AddGroupElements(props, true) -- Insert again

        lust.expect(g:GetGroupElementsPairs()).to.have_n_fields(11)
        lust.expect(g:GetGroupElementsAll()).to.have_n_fields(11)
        lust.expect(g:GetGroupElementsCount()).to.be(11)
    end)

    lust.it("EmptyGroupWithRandom", function()
        local g = MGroup()
        table.insert(cur_instances, g)

        for i = 1, 10 do
            local p = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
            table.insert(cur_instances, p)
            g:AddGroupElements(p)
        end

        lust.expect(g:GetGroupElementsPairs()).to.have_n_fields(10)
        lust.expect(g:GetGroupElementsAll()).to.have_n_fields(10)
        lust.expect(g:GetGroupElementsCount()).to.be(10)

        for i = 1, 10 do
            g:RemoveGroupElements(g:GetGroupRandomElement())
        end

        lust.expect(g:GetGroupElementsPairs()).to.have_n_fields(0)
        lust.expect(g:GetGroupElementsAll()).to.have_n_fields(0)
        lust.expect(g:GetGroupElementsCount()).to.be(0)
    end)

    lust.it("CallFunctionOnLoopWithElements", function()
        local g = MGroup()
        table.insert(cur_instances, g)

        local tick = {}
        for i = 1, 10 do
            local p = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
            g:AddGroupElements(p)
            tick[p] = 0
        end

        local cfolwe = function(a, a2, p)
            lust.expect(a).to.be(1)
            lust.expect(a2).to.be(2)

            lust.expect(tick[p]).to.be(0)

            tick[p] = tick[p] + 1

            return a+10
        end

        local ret = g:CallFunctionOnLoopWithElements(cfolwe, 1, 2, MGroup.PutHerePlaceholder)
        lust.expect(ret).to.have_n_fields(10)

        for k, v in pairs(ret) do
            lust.expect(v[1]).to.be(11)
        end

        for k, v in pairs(tick) do
            lust.expect(v).to.be(1)
        end
    end)

    lust.it("pass_group_of_props_into_event", function()
        local g = MGroup()
        table.insert(cur_instances, g)

        for i = 1, 10 do
            local p = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
            g:AddGroupElements(p)
        end

        Events.Subscribe("TestPassGroup", function(a, eg)
            lust.expect(a).to.be(1)

            lust.expect(getmetatable(eg)).to.exist()

            lust.expect(eg:GetGroupElementsCount()).to.be(10)

            eg:RemoveGroupElements(eg:GetGroupRandomElement())
        end)

        Events.Call("TestPassGroup", 1, g)

        lust.expect(g:GetGroupElementsCount()).to.be(10) -- Groups passed into events are lost
    end)

    lust.it("GroupsOfGroups", function()
        local g = MGroup()
        table.insert(cur_instances, g)

        local p_g = MGroup()
        --table.insert(cur_instances, p_g)
        for i = 1, 5 do
            p_g:AddGroupElements(Prop(Vector(), Rotator(), "nanos-world::SM_Cube"))
        end

        local sm_g = MGroup()
        --table.insert(cur_instances, sm_g)
        for i = 1, 3 do
            sm_g:AddGroupElements(StaticMesh(Vector(), Rotator(), "nanos-world::SM_Cube"))
        end

        local light_g = MGroup()
        --table.insert(cur_instances, light_g)
        for i = 1, 2 do
            light_g:AddGroupElements(Light(Vector(), Rotator()))
        end

        g:AddGroupElements(p_g, sm_g, light_g)

        lust.expect(g:GetGroupElementsCount()).to.be(3)


        local ret = g:CallFunctionOnLoopWithElements(MGroup.prototype.GetGroupRandomElement, MGroup.PutHerePlaceholder)
        lust.expect(ret).to.have_n_fields(3)

        for k, v in pairs(ret) do
            lust.expect(v.n).to.be(1)
            lust.expect(v[1]:IsValid()).to.be.truthy()
        end

        Events.Subscribe("TestPassGOfG", function(eg)
            lust.expect(getmetatable(eg)).to.exist()

            lust.expect(eg:GetGroupElementsCount()).to.be(3)

            --print(NanosTable.Dump(eg))

            for k, v in pairs(eg:GetGroupElementsPairs()) do
                lust.expect(eg.ElementsToIndexes[v]).to.exist()
                lust.expect(getmetatable(v)).to.exist()
            end
        end)
        print(NanosTable.Dump(g))
        Events.Call("TestPassGOfG", g)

        for k, v in pairs(g:GetGroupElementsAll()) do
            v:Destroy()
            v:DestroyGroup()
        end
    end)
end)

lust.describe("NativeEvents.lua", function()
    lust.describe("Other", function()
        lust.it("AwareOf", function()
            lust.expect(Modularity.AwareOf(Package.GetName())).to.be.truthy()
            lust.expect(Modularity.AwareOf("__dqfse_")).to_not.be.truthy()
        end)

        lust.it("GetALLEventsFunctions", function()
            local ret = Modularity.GetALLEventsFunctions()
            --print(NanosTable.Dump(ret))

            lust.expect(table_count(ret) > 0).to.be(true)

            local ret2 = Modularity.GetALLEventsFunctions(Package.GetName())
            --print(table_count(ret2))
            lust.expect(table_count(ret2) > 0).to.be(true)
        end)

        lust.it("GetNativeEventFunctionFromStoringTable", function()
            lust.expect(Modularity.PackagesNativeEventsSystemsSubscribes).to.exist()

            for k, v in pairs(Modularity.PackagesNativeEventsSystemsSubscribes) do
                lust.expect(Modularity.GetNativeEventFunctionFromStoringTable(v)).to.be(k)
            end
        end)
    end)

    lust.describe("Sub Spy", function()
        lust.it("static Sub, gkfn, NativeCall, Unsub", function()
            local ev_name = "TestSubSpyBasic"
            local called
            local ev_func = function(a, a2)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
                called = true

                return a+10, a2+10
            end
            Events.Subscribe(ev_name, ev_func)

            local ret = Modularity.GetKnownNativeEventsFunctions("Subscribe", "Events", Package.GetName(), ev_name, "INDEPENDENT_SUBS")
            --print(NanosTable.Dump(ret))
            lust.expect(ret).to.have_n_fields(1)
            lust.expect(ret[ev_func]).to.be(1)

            local retec = Modularity.NativeCallEvent("Subscribe", "Events", ev_name, Package.GetName(), "INDEPENDENT_SUBS", nil, 1, 2)
            local ff = retec[ev_func]
            lust.expect(ff).to.have_n_fields(1)
            lust.expect(ff[1][1]).to.be(11)
            lust.expect(ff[1][2]).to.be(12)
            lust.expect(ff[1].n).to.be(2)

            lust.expect(called).to.be.truthy()

            Events.Unsubscribe(ev_name, ev_func)

            local ret2 = Modularity.GetKnownNativeEventsFunctions("Subscribe", "Events", Package.GetName(), ev_name, "INDEPENDENT_SUBS")
            lust.expect(ret2).to.have_n_fields(0)

            local retec2 = Modularity.NativeCallEvent("Subscribe", "Events", ev_name, Package.GetName(), "INDEPENDENT_SUBS", nil, 1, 2)
            lust.expect(retec2).to.have_n_fields(0)
        end)

        lust.it("SubscribeRemote", function()
            local ev_name = "TestSubRemote"
            local called
            local ev_func = function(a, a2)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
                called = true

                return a+10, a2+10
            end
            Events.SubscribeRemote(ev_name, ev_func)

            local ret = Modularity.GetKnownNativeEventsFunctions("SubscribeRemote", "Events", Package.GetName(), ev_name, "INDEPENDENT_SUBS")
            --print(NanosTable.Dump(ret))
            lust.expect(ret).to.have_n_fields(1)
            lust.expect(ret[ev_func]).to.be(1)

            local retec = Modularity.NativeCallEvent("SubscribeRemote", "Events", ev_name, Package.GetName(), "INDEPENDENT_SUBS", nil, 1, 2)
            local ff = retec[ev_func]
            lust.expect(ff).to.have_n_fields(1)
            lust.expect(ff[1][1]).to.be(11)
            lust.expect(ff[1][2]).to.be(12)
            lust.expect(ff[1].n).to.be(2)

            lust.expect(called).to.be.truthy()

            Events.Unsubscribe(ev_name, ev_func)

            local ret2 = Modularity.GetKnownNativeEventsFunctions("SubscribeRemote", "Events", Package.GetName(), ev_name, "INDEPENDENT_SUBS")
            lust.expect(ret2).to.have_n_fields(0)

            local retec2 = Modularity.NativeCallEvent("SubscribeRemote", "Events", ev_name, Package.GetName(), "INDEPENDENT_SUBS", nil, 1, 2)
            lust.expect(retec2).to.have_n_fields(0)
        end)

        lust.it("MultiSameSub", function()
            local ev_name = "MultiSameSub"
            local called = 0
            local ev_func = function(a, a2)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
                called = called + 1

                return a+10, a2+10
            end
            Events.Subscribe(ev_name, ev_func)
            Events.Subscribe(ev_name, ev_func)

            local ret = Modularity.GetKnownNativeEventsFunctions("Subscribe", "Events", Package.GetName(), ev_name, "INDEPENDENT_SUBS")
            --print(NanosTable.Dump(ret))
            lust.expect(ret).to.have_n_fields(1)
            lust.expect(ret[ev_func]).to.be(2)

            local retec = Modularity.NativeCallEvent("Subscribe", "Events", ev_name, Package.GetName(), "INDEPENDENT_SUBS", nil, 1, 2)
            local ff = retec[ev_func]
            lust.expect(ff).to.have_n_fields(2)
            lust.expect(ff[1][1]).to.be(11)
            lust.expect(ff[1][2]).to.be(12)
            lust.expect(ff[2].n).to.be(2)
            lust.expect(ff[2][1]).to.be(11)
            lust.expect(ff[2][2]).to.be(12)
            lust.expect(ff[2].n).to.be(2)

            lust.expect(called).to.be(2)

            Events.Unsubscribe(ev_name, ev_func)

            local ret2 = Modularity.GetKnownNativeEventsFunctions("Subscribe", "Events", Package.GetName(), ev_name, "INDEPENDENT_SUBS")
            lust.expect(ret2).to.have_n_fields(0)

            local retec2 = Modularity.NativeCallEvent("Subscribe", "Events", ev_name, Package.GetName(), "INDEPENDENT_SUBS", nil, 1, 2)
            lust.expect(retec2).to.have_n_fields(0)
        end)

        lust.it("Attached Ev", function()
            local prop = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")

            local ev_name = "TestSubSpyBasic"
            local called
            local ev_func = function(a, a2) -- ent is not passed automatically
                --lust.expect(ent).to.be(prop)
                lust.expect(a).to.be(1)
                lust.expect(a2).to.be(2)
                called = true

                return a+10, a2+10
            end
            prop:Subscribe(ev_name, ev_func)

            local ret = Modularity.GetKnownNativeEventsFunctions("Subscribe", "Prop", Package.GetName(), ev_name, prop)
            --print(NanosTable.Dump(ret))
            lust.expect(ret).to.have_n_fields(1)
            lust.expect(ret[ev_func]).to.be(1)

            local retec = Modularity.NativeCallEvent("Subscribe", "Prop", ev_name, Package.GetName(), prop, nil, 1, 2)
            local ff = retec[ev_func]
            lust.expect(ff).to.have_n_fields(1)
            lust.expect(ff[1][1]).to.be(11)
            lust.expect(ff[1][2]).to.be(12)
            lust.expect(ff[1].n).to.be(2)

            lust.expect(called).to.be.truthy()

            prop:Destroy()

            local ret2 = Modularity.GetKnownNativeEventsFunctions("Subscribe", "Prop", Package.GetName(), ev_name, prop)
            lust.expect(ret2).to_not.exist() -- Doesn't return anything as ent got destroyed
        end)

        lust.it("Inherited", function()
            ESIP = Prop.Inherit("ESIP")
            ESIP_2 = ESIP.Inherit("ESIP_2")

            local rs = 0
            local called = 0
            Prop.Subscribe("Spawn", function(prop)
                called = called + 1
                lust.expect(called).to.be(1+rs)
                if rs == 0 then
                    lust.expect(prop:GetClass()).to.be(ESIP_2)
                else
                    lust.expect(prop).to.be("Hacked Spawn Call")
                end
            end)

            ESIP.Subscribe("Spawn", function(prop)
                called = called + 1
                lust.expect(called).to.be(2+rs)
                if rs == 0 then
                    lust.expect(prop:GetClass()).to.be(ESIP_2)
                else
                    lust.expect(prop).to.be("Hacked Spawn Call")
                end
            end)

            ESIP_2.Subscribe("Spawn", function(prop)
                called = called + 1
                lust.expect(called).to.be(3+rs)
                if rs == 0 then
                    lust.expect(prop:GetClass()).to.be(ESIP_2)
                else
                    lust.expect(prop).to.be("Hacked Spawn Call")
                end
            end)

            local i_p = ESIP_2(Vector(), Rotator(), "nanos-world::SM_Cube")

            lust.expect(called).to.be(3)
            rs = called

            Modularity.NativeCallEvent("Subscribe", "ESIP_2", "Spawn", Package.GetName(), nil, nil, "Hacked Spawn Call")

            i_p:Destroy()

            lust.expect(called).to.be(6)

            Prop.Unsubscribe("Spawn")
            ESIP.Unsubscribe("Spawn")
            ESIP_2.Unsubscribe("Spawn")

            Modularity.NativeCallEvent("Subscribe", "ESIP_2", "Spawn", Package.GetName(), nil, nil, "Hacked Spawn Call")

            local i_p2 = ESIP_2(Vector(), Rotator(), "nanos-world::SM_Cube")
            i_p2:Destroy()
        end)

        lust.it("Console.RegisterCommand Spy", function()
            local called = 0
            local function regc_func(text, hmh)
                called = called + 1
                lust.expect(text).to.be("1")
            end
            local desc = "testdesc"
            local parameters = { "text", "something" }

            Console.RegisterCommand("testregcspy", regc_func, desc, parameters)
            local kefndsd = Modularity.GetKnownNativeEventsFunctions("RegisterCommand", "Console_I", Package.GetName(), "testregcspy", "INDEPENDENT_SUBS")
            --print(NanosTable.Dump(kefndsd))

            local freg = kefndsd[regc_func]
            lust.expect(freg).to.exist()

            lust.expect(freg.info_params).to.equal({
                description = desc,
                parameters = parameters,
            })

            lust.expect(freg.n).to.be(1)

            Modularity.NativeCallEvent("RegisterCommand", "Console_I", "testregcspy", Package.GetName(), "INDEPENDENT_SUBS", nil, "1")

            lust.expect(called).to.be(1)

            -- API Design error
            --Console.RunCommand("tcrc_catcher text_value")
            --Console.RunCommand("tcrc_catcher",  "text_value")
        end)
    end)

    lust.describe("Classlink", function()
        local is_cc = 0
        local find_cc = 0
        local comp_cc = 0
        local classlink_id

        lust.it("Init", function()
            function IsMTFromTable(tbl)
                is_cc = is_cc + 1
                if (type(tbl) == "table" and tbl._MTCLASS_INSTANCE == true) then
                    if MT_ALL_KEYID[tbl.ID] then
                        return true
                    end
                end
            end

            function MTFromTable(tbl)
                find_cc = find_cc + 1
                --print(find_cc)
                return MT_ALL[MT_ALL_KEYID[tbl.ID]]
            end

            function MTCompress(tbl)
                comp_cc = comp_cc + 1
                return {
                    ID = tbl.ID,
                    _MTCLASS_INSTANCE = tbl._MTCLASS_INSTANCE,
                    Compressed = true,
                }
            end

            classlink_id = Modularity.RegisterClassLink(IsMTFromTable, MTFromTable, MTCompress)
        end)

        lust.it("ClasslinksReconstructEntities", function()
            local ent = MT_Class()

            local t_f_ent = {{ID = ent.ID, _MTCLASS_INSTANCE = true,}}
            local ret = {Modularity.ClasslinksReconstructEntities({classlink_id}, nil, t_f_ent[1])}
            lust.expect(ret).to.have_n_fields(1)

            lust.expect(is_cc).to.be(1)
            lust.expect(find_cc).to.be(1)

            lust.expect(ret[1]).to.be(ent)

            Modularity.ClasslinksReconstructEntities({classlink_id}, true, t_f_ent)

            lust.expect(is_cc).to.be(2)
            lust.expect(find_cc).to.be(2)

            lust.expect(t_f_ent[1]).to.be(ent)

            ent:Destroy()
        end)

        lust.it("ClasslinksCompressEntities", function()
            local ent = MT_Class()

            local t_ent = {ent}

            local ret = {Modularity.ClasslinksCompressEntities({classlink_id}, false, t_ent[1])}
            lust.expect(ret).to.have_n_fields(1)

            lust.expect(is_cc).to.be(3)
            lust.expect(find_cc).to.be(2)
            lust.expect(comp_cc).to.be(1)

            local f_ent = {
                ID = ent.ID,
                _MTCLASS_INSTANCE = ent._MTCLASS_INSTANCE,
                Compressed = true,
            }

            lust.expect(ret[1]).to.equal(f_ent)

            Modularity.ClasslinksCompressEntities({classlink_id}, true, t_ent)

            lust.expect(is_cc).to.be(4)
            lust.expect(find_cc).to.be(2)
            lust.expect(comp_cc).to.be(2)

            lust.expect(t_ent[1]).to.equal(f_ent)

            ent:Destroy()
        end)

        lust.it("WatchFunctionArgsForClassLinks", function()
            local ent = MT_Class()

            local called = 0
            local function twfafcl(_ent, a)
                called = called + 1
                lust.expect(_ent).to.be(ent)
                lust.expect(a).to.be(1)
            end
            Modularity.WatchFunctionArgsForClassLinks(twfafcl, classlink_id)

            Events.Subscribe("WatchFunctionArgsForClassLinks", twfafcl)

            Events.Call("WatchFunctionArgsForClassLinks", ent, 1)

            Events.Unsubscribe("WatchFunctionArgsForClassLinks", twfafcl)

            lust.expect(called).to.be(1)

            lust.expect(is_cc).to.be(6)
            lust.expect(find_cc).to.be(3)
            lust.expect(comp_cc).to.be(2)

            ent:Destroy()
        end)

        lust.it("AddGlobalWatchArgsForClassLinks", function()
            local ent = MT_Class()

            local called = 0
            local function agwafcl(_ent, a)
                called = called + 1
                lust.expect(_ent).to.be(ent)
                lust.expect(a).to.be(1)
            end

            local function agwafcl2(_ent, a)
                called = called + 1
                lust.expect(_ent).to.be(ent)
                lust.expect(a).to.be(1)
            end
            Events.Subscribe("AddGlobalWatchArgsForClassLinks_BEFORE", agwafcl)

            Modularity.AddGlobalWatchArgsForClassLinks(classlink_id)

            Events.Subscribe("AddGlobalWatchArgsForClassLinks", agwafcl2)

            Events.Call("AddGlobalWatchArgsForClassLinks_BEFORE", ent, 1)

            lust.expect(called).to.be(1)

            lust.expect(is_cc).to.be(8)
            lust.expect(find_cc).to.be(4)
            lust.expect(comp_cc).to.be(2)

            Events.Call("AddGlobalWatchArgsForClassLinks", ent, 1)

            lust.expect(called).to.be(2)

            lust.expect(is_cc).to.be(10)
            lust.expect(find_cc).to.be(5)
            lust.expect(comp_cc).to.be(2)

            Events.Unsubscribe("AddGlobalWatchArgsForClassLinks_BEFORE", agwafcl)
            Events.Unsubscribe("AddGlobalWatchArgsForClassLinks", agwafcl2)

            ent:Destroy()
        end)

        lust.it("SetNativeEventsClassLinkCompression", function()
            local ent = MT_Class()

            local called = 0
            local function sneclc(_ent, a)
                called = called + 1
                lust.expect(_ent).to.be(ent)
                lust.expect(a).to.be(1)
            end

            Modularity.SetNativeEventsClassLinkCompression(classlink_id, Modularity.Default_Configs.Compression.All)

            Events.Subscribe("SetNativeEventsClassLinkCompression", sneclc)

            Events.Call("SetNativeEventsClassLinkCompression", ent, 1)

            lust.expect(is_cc).to.be(14) -- 2 more for compression checks
            lust.expect(find_cc).to.be(6)
            lust.expect(comp_cc).to.be(3)

            Events.Unsubscribe("SetNativeEventsClassLinkCompression", sneclc)

            ent:Destroy()
        end)
    end)
end)

lust.describe("Instances_Storing.lua", function()
    lust.it("Data on direct entity", function()
        local p1 = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
        local p2 = ESIP(Vector(), Rotator(), "nanos-world::SM_Cube")
        local p3 = ESIP_2(Vector(), Rotator(), "nanos-world::SM_Cube")

        p1.dode = "dode1"
        p2.dode = "dode2"
        p3.dode = "dode3"

        lust.expect(p1.dode).to.be("dode1")
        lust.expect(p2.dode).to.be("dode2")
        lust.expect(p3.dode).to.be("dode3")

        p1:Destroy()
        p2:Destroy()
        p3:Destroy()

        lust.expect(Modularity.InstancesData[p1]).to.be(nil)
        lust.expect(Modularity.InstancesData[p2]).to.be(nil)
        lust.expect(Modularity.InstancesData[p3]).to.be(nil)
    end)

    lust.it("SetValue Watcher", function()
        local p1 = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
        local p2 = ESIP(Vector(), Rotator(), "nanos-world::SM_Cube")
        local p3 = ESIP_2(Vector(), Rotator(), "nanos-world::SM_Cube")

        p1:SetValue("Key", "Value", true)
        p2:SetValue("Key", "Value", false)
        p3:SetValue("Key", "Value", true)

        --print(NanosTable.Dump(Modularity.GetValuesKeys(p1)))
        local k1 = Modularity.GetValuesKeys(p1)
        local k2 = Modularity.GetValuesKeys(p2)
        local k3 = Modularity.GetValuesKeys(p3)

        lust.expect(k1).to.have_n_fields(1)
        lust.expect(k2).to.have_n_fields(1)
        lust.expect(k3).to.have_n_fields(1)

        lust.expect(k1["Key"].sync).to.be(true)
        lust.expect(k2["Key"].sync).to.be(false)
        lust.expect(k3["Key"].sync).to.be(true)

        p1:Destroy()
        p2:Destroy()
        p3:Destroy()

        lust.expect(Modularity.InstancesValuesKeys[p1]).to.be(nil)
        lust.expect(Modularity.InstancesValuesKeys[p2]).to.be(nil)
        lust.expect(Modularity.InstancesValuesKeys[p3]).to.be(nil)
    end)
end)