

local function _Make_Class_Call()
    local INS_ID = 1 -- Need to recreate it again each time for different INS_ID
    return function(self)
        local ins = MBaseScopeEntityClass.default_fields._Special_Fields.Default_Meta.__call(self)

        local this_id = INS_ID
        INS_ID = INS_ID + 1
        ins.ID = INS_ID

        ins.Valid = true

        local l_count = Modularity.table_last_count(self.All_Instances)
        self.All_Instances[l_count + 1] = ins

        self.All_KEYID[this_id] = l_count + 1

        --ins:CallEvent("Spawn")

        return self.All_Instances[l_count + 1]
    end
end

local function _Make_Ent_Class_Modularity_Links(New_Class)
    local function IsParamANew_Class(tbl)
        if (type(tbl) == "table" and ins["_" .. tostring(New_Class.__name) .. "_CLASS_INSTANCE"] == true and tbl.ID and New_Class.All_KEYID[tbl.ID]) then
            return true
        end
    end

    local function New_ClassFromTable(tbl) -- TODO
        return New_Class.All_Instances[New_Class.All_KEYID[tbl.ID]]
    end

    New_Class.classlink_id = Modularity.RegisterClassLink(IsParamANew_Class, New_ClassFromTable)

    Modularity.AddGlobalWatchArgsForClassLinks(New_Class.classlink_id)
end


local MBaseEntityClass_Default_Fields = {
    destroyed_prototype = {},

    All_Instances = {},
    All_KEYID = {},

    _Special_Fields = Modularity.DuplicateTable(MBaseScopeEntityClass.default_fields._Special_Fields),
}
MBaseEntityClass_Default_Fields._Special_Fields.Default_Meta.__call = nil


local function Initialize_Entity_Class(ParentClass, New_Class, cname)
    local meta = getmetatable(New_Class)
    meta.__call = _Make_Class_Call()

    _Make_Ent_Class_Modularity_Links(New_Class)
end


MBaseEntityClass = MBaseScopeEntityClass.Inherit("MBaseEntityClass", MBaseEntityClass_Default_Fields, Initialize_Entity_Class)


function MBaseEntityClass.static_prototype:GetPairs()
    return self.All_Instances
end

function MBaseEntityClass.static_prototype:GetAll()
    local tbl = {}
    local c = 0
    for k, v in pairs(self.All_Instances) do
        c = c + 1
        tbl[c] = v
    end
    return tbl
end

function MBaseEntityClass.static_prototype:GetByIndex(index)
    if (index and type(index) == "number" and math.type(index) == "integer") then
        return self.All_Instances[index]
    else
        error("Wrong arguments")
    end
end

function MBaseEntityClass.static_prototype:GetCount()
    return Modularity.table_count(self.All_Instances)
end

function MBaseEntityClass.static_prototype:Inherit(cname, added_default_fields, initialize_class_function)
    local New_Class = MBaseEntityClass.Super("Inherit")(cname, Modularity.JoinTables(MBaseEntityClass_Default_Fields, added_default_fields), Initialize_Entity_Class)

    local New_Class_DPrototype_Meta = {
        __index = self.destroyed_prototype
    }
    setmetatable(New_Class.destroyed_prototype, New_Class_DPrototype_Meta)

    if initialize_class_function then
        initialize_class_function(self, New_Class, cname)
    end

    return New_Class
end



function MBaseEntityClass.instance_prototype:IsValid()
    return self.Valid
end

function MBaseEntityClass.instance_prototype:GetID()
    return self.ID
end

function MBaseEntityClass.instance_prototype:Destroy()
    self:CallEvent("Destroy")
    if self:GetClass().All_KEYID[self.ID] then
        self:GetClass().All_Instances[self:GetClass().All_KEYID[self.ID]] = nil
        self:GetClass().All_KEYID[self.ID] = nil
    end
    self.Valid = false
    self:Unsubscribe()
    setmetatable(self, self:GetClass().destroyed_prototype)
    return true
end


function MBaseEntityClass.destroyed_prototype:__tostring()
    local address = self.address or "?"
    return "Destroyed " .. tostring(self.__name) .. ": " .. address
end

function MBaseEntityClass.destroyed_prototype:__index(key)
    if (key == "Valid" or key == "address" or key == "Class") then
        return rawget(self, key)
    elseif (key == "IsValid" or key == "IsA" or key == "__name") then
        return self.Class.instance_prototype[key]
    elseif key == "__tostring" then
        return rawget(self.Class.destroyed_prototype, key)
    else
        return error("Trying to use a destroyed " .. tostring(self.__name))
    end
end

function MBaseEntityClass.destroyed_prototype:__newindex()
    return error("Trying to use a destroyed " .. tostring(self.__name))
end