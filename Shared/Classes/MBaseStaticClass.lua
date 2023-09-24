

function _Parent__index_function(self, key, real_self) -- To propagate first __index self over
    if type(self) ~= "table" then
        return
    end

    --print("_Parent __index", self, key)
    local r_v = rawget(self, key)
    if r_v ~= nil then
        return r_v
    end
    local s_v = rawget(self, "static_prototype")[key]
    if s_v ~= nil then
        return function(...)
            return s_v(real_self, ...)
        end
    end
    local p_class = rawget(self, "ParentClass")
    if p_class then
        return _Parent__index_function(p_class, key, real_self)
    end
end

function _Static__index_function(self, key, ...)
    --print("__index", self, key)
    local r_v = rawget(self, key)
    if r_v ~= nil then
        return r_v
    end
    local s_v = rawget(self, "static_prototype")[key]
    if s_v ~= nil then
        return function(...)
            return s_v(self, ...)
        end
    end
    local p_class = rawget(self, "ParentClass")
    --print("p_class", p_class, NanosTable.Dump(self))
    if p_class then
        --return p_class[key]
        return _Parent__index_function(p_class, key, self)
    end
end

local function _CreateClassWithDefaultFields(default_fields)
    default_fields = default_fields or {}
    local n_c = Modularity.DuplicateTable(default_fields)
    if default_fields._Special_Fields then
        if default_fields._Special_Fields.Default_Meta then
            setmetatable(n_c, default_fields._Special_Fields.Default_Meta)
        end
    end
    n_c.default_fields = default_fields
    return n_c
end

local MBaseStaticClass_Class_Meta = {}
function MBaseStaticClass_Class_Meta:__tostring()
    return tostring(self.__name) .. " Class"
end

MBaseStaticClass_Class_Meta.__index = _Static__index_function

local MBaseStaticClass_Default_Fields = {
    static_prototype = {},
    _Special_Fields = {
        Default_Meta = MBaseStaticClass_Class_Meta,
    },
}


local function InitializeBaseStaticClass(ParentClass, New_Class, cname)
    New_Class.ParentClass = ParentClass
    New_Class.__name = cname

    Modularity.AttachStaticEventSystem(New_Class, ParentClass)

    --print(New_Class, rawget(New_Class, "ParentClass"))

    -- Handled by class __index
    --[[local Static_Prototype_Meta = {}
    Static_Prototype_Meta.__index = self
    setmetatable(New_Class.static_prototype, Static_Prototype_Meta)]]--

    --self.CallEvent("ClassRegister", New_Class)
end


MBaseStaticClass = _CreateClassWithDefaultFields(MBaseStaticClass_Default_Fields)
Package.Export("MBaseStaticClass", MBaseStaticClass)


--MBaseStaticClass.__index = MBaseStaticClass
InitializeBaseStaticClass(nil, MBaseStaticClass, "MBaseStaticClass")

function MBaseStaticClass.static_prototype:GetParentClass()
    return self.ParentClass
end

function MBaseStaticClass.static_prototype:IsChildOf(o_class)
    local cur_parent = self.GetParentClass()
    while (cur_parent ~= nil) do
        if cur_parent == o_class then
            return true
        else
            cur_parent = cur_parent.GetParentClass()
        end
    end
    return false
end

function MBaseStaticClass.static_prototype:Super(key)
    return _Parent__index_function(self.GetParentClass(), key, self)
end


function MBaseStaticClass.static_prototype:Inherit(cname, added_default_fields, initialize_class_function)
    --print("MBaseStaticClass.Inherit self:", self)

    local default_fields = self.default_fields or {}
    local new_default_fields = Modularity.JoinTables(default_fields, added_default_fields)
    --print(cname, NanosTable.Dump(new_default_fields))

    local New_Class = _CreateClassWithDefaultFields(new_default_fields)
    Package.Export(cname, New_Class)

    InitializeBaseStaticClass(self, New_Class, cname)

    if initialize_class_function then
        initialize_class_function(self, New_Class, cname)
    end

    return New_Class
end