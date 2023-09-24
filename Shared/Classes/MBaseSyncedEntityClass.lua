

local function _Make_Synced_Call(New_Class)
    local meta = getmetatable(New_Class)
    local o_call = meta.__call

    function meta:__call()
        local ins = o_call(self)

        if self.default_fields then
            Modularity.DuplicateTableInto(self.default_fields, ins)
        end

        return ins
    end
end


local default_fields_MBaseEntity = MBaseEntityClass.default_fields
local New_Default_Fields = {
    instance_prototype = Modularity.DuplicateTable(default_fields_MBaseEntity.instance_prototype)
}
New_Default_Fields.instance_prototype.default_fields = {
    Stored = {
        Values = {},
        SyncedValues = {},
    },
}


MBaseSyncedEntityClass = MBaseEntityClass.Inherit("MBaseSyncedEntityClass", New_Default_Fields)

--print(NanosTable.Dump(MBaseSyncedEntityClass.default_fields))


_Make_Synced_Call(MBaseSyncedEntityClass)


