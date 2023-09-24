

local local_var = "local_var original"

function testlocalvar()
    lust.expect(local_var).to.be("local_var modified")
end