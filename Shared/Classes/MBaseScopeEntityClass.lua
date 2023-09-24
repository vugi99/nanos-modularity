

local function _Scope_Class_Call(self)
    local _tbl = {}
    local address = Modularity.GetAddress(_tbl)
    local ins = setmetatable(_tbl, self.instance_prototype)

    ins["_" .. self.__name .. "_CLASS_INSTANCE"] = true

    ins.Class = self

    ins.address = address

    ins:CallEvent("Spawn")

    return ins
end

local function _Make_Scope_Class_Modularity_Links(New_Class, ParentClass)
    local function IsParamANew_Class(tbl)
        if (type(tbl) == "table" and ins["_" .. tostring(New_Class.__name) .. "_CLASS_INSTANCE"] == true) then
            return true
        end
    end

    local function New_ClassFromTable(tbl)
        return setmetatable(tbl, New_Class.instance_prototype)
    end

    Modularity.AttachInstanceEventSystem(New_Class.instance_prototype, New_Class, ParentClass)

    New_Class.classlink_id = Modularity.RegisterClassLink(IsParamANew_Class, New_ClassFromTable)

    Modularity.AddGlobalWatchArgsForClassLinks(New_Class.classlink_id)
end


local MBaseScopeEntityClass_Default_Fields = {
    instance_prototype = {},
}
MBaseScopeEntityClass_Default_Fields.instance_prototype.__index = MBaseScopeEntityClass_Default_Fields.instance_prototype
MBaseScopeEntityClass_Default_Fields._Special_Fields = Modularity.DuplicateTable(MBaseStaticClass.default_fields._Special_Fields)
MBaseScopeEntityClass_Default_Fields._Special_Fields.Default_Meta.__call = _Scope_Class_Call


local function Initialiaze_Scope_Entity(ParentClass, New_Class, cname)
    New_Class.instance_prototype.__name = cname .. " Instance"

    _Make_Scope_Class_Modularity_Links(New_Class, ParentClass)
end


MBaseScopeEntityClass = MBaseStaticClass.Inherit("MBaseScopeEntityClass", MBaseScopeEntityClass_Default_Fields, Initialiaze_Scope_Entity)



function MBaseScopeEntityClass.static_prototype:Inherit(cname, added_default_fields, initialize_class_function)
    local New_Class = MBaseScopeEntityClass.Super("Inherit")(cname, Modularity.JoinTables(MBaseScopeEntityClass_Default_Fields, added_default_fields), Initialiaze_Scope_Entity)

    local New_Class_Instance_Prototype_Meta = {
        __index = self.instance_prototype
    }
    setmetatable(New_Class.instance_prototype, New_Class_Instance_Prototype_Meta)

    if initialize_class_function then
        initialize_class_function(self, New_Class, cname)
    end

    return New_Class
end


function MBaseScopeEntityClass.instance_prototype:IsA(class)
    local cur_class = self:GetClass()
    while (cur_class ~= nil) do
        if cur_class == class then
            return true
        else
            cur_class = cur_class.GetParentClass()
        end
    end
    return false
end

function MBaseScopeEntityClass.instance_prototype:__tostring()
    local address = self.address or "?"
    return tostring(self.__name) .. ": " .. address
end

function MBaseScopeEntityClass.instance_prototype:GetClass()
    return self.Class
end

function MBaseScopeEntityClass.instance_prototype:Super(key)
    local p_class = self:GetClass().GetParentClass()
    if (p_class and p_class.instance_prototype) then
        return p_class.instance_prototype[key]
    end
end