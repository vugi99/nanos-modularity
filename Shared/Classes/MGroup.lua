

---@overload fun(...: any): MGroup_Instance
---@overload fun(ents: table, pass_table: true): MGroup_Instance
MGroup = {}
Package.Export("MGroup", MGroup)

MGroup.__index = MGroup
MGroup.__name = "MGroup"

---@class MGroup_Instance
MGroup.prototype = {}

function MGroup:__tostring()
    return "MGroup Class"
end

local MG_ID = 1

MGroup.All_Instances = {}

MGroup.All_KEYID = {}

MGroup.PutHerePlaceholder = {} -- Unique signature for comparison

local MGroup_Class_Meta = {}

local function _Make_ElementsToIndexes(Elements)
    local ElementsToIndexes = {}
    for k, v in pairs(Elements) do
        if not ElementsToIndexes[Elements[k]] then
            ElementsToIndexes[Elements[k]] = k
        else
            Elements[k] = nil -- Do not allow duplicated elements in groups
        end
    end
    return ElementsToIndexes
end

function MGroup_Class_Meta:__call(...)
    local _tbl = {}
    local address = Modularity.GetAddress(_tbl)
    local ins = setmetatable(_tbl, MGroup.prototype)

    local this_id = MG_ID
    MG_ID = MG_ID + 1
    ins.ID = this_id

    ins._MGROUP_CLASS_INSTANCE = true
    ins.Valid = true
    ins.Created_On_Side = Modularity.GetSide()

    local l_count = Modularity.table_last_count(MGroup.All_Instances)
    MGroup.All_Instances[l_count + 1] = ins

    MGroup.All_KEYID[this_id] = l_count + 1

    local args = {...}
    if args[2] == true then
        if type(args[1]) ~= "table" then
            return error("Expected table in first parameter")
        end
        ins.Elements = {}
        for k, v in pairs(args[1]) do
            ins.Elements[k] = v
        end
    else
        ins.Elements = {...}
    end

    ins.ElementsToIndexes = _Make_ElementsToIndexes(ins.Elements)

    ins.TempDestroyed = {}
    ins.CallingFunction = false
    ins.address = address

    ins:CallEvent("Spawn")

    return MGroup.All_Instances[l_count + 1]
end

function IsParamAMGroup(tbl)
    --print(NanosTable.Dump(tbl))
    if (type(tbl) == "table" and tbl._MGROUP_CLASS_INSTANCE == true) then
        return true
    end
end
--print("IsParamAMGroup", IsParamAMGroup)

function MGroupFromTable(tbl)
    -- Update group elements on this side then return the group on the current side ? Weird behavior tho...
    --print("MGroupFromTable")
    if tbl.Valid then
        -- Do we need to check if the Elements are valid ?
        if tbl.Elements then
            --print("Reconstructing", NanosTable.Dump(tbl.Elements))
            Modularity.ClasslinksReconstructEntities(Modularity.DumpKeys(Modularity.GlobalSubscribesClasslinks), true, tbl.Elements) -- Reconstruct elements in the group

            tbl.ElementsToIndexes = {}
            for k, v in pairs(tbl.Elements) do
                tbl.ElementsToIndexes[v] = k
            end
            --print("Reconstructed")
        end
        tbl.address = Modularity.GetAddress(tbl)
        return setmetatable(tbl, MGroup.prototype) -- We don't look at existing groups to avoid issues when the group is sent again from client and got updated. Groups should be used in context, they won't be modified in events.
    else
        tbl.address = Modularity.GetAddress(tbl)
        return setmetatable(tbl, MGroup.destroyed_prototype)
    end
end

function MGroupCompress(tbl)
    --print("MGroupCompress")
    if tbl.Valid then
        local elements = tbl.Elements
        local e_in = tbl.ElementsToIndexes

        if not Modularity.IsTableEmpty(tbl.TempDestroyed) then
            elements = Modularity.DuplicateTable(tbl.Elements)
            e_in = {}
            for k, v in pairs(tbl.TempDestroyed) do
                if tbl.ElementsToIndexes[v] then
                    elements[tbl.ElementsToIndexes[v]] = nil
                end
            end
            for k, v in pairs(elements) do
                e_in[v] = k
            end
        end

        return {
            ID = tbl.ID,
            Valid = tbl.Valid,
            _MGROUP_CLASS_INSTANCE = tbl._MGROUP_CLASS_INSTANCE,
            TempDestroyed = {},
            CallingFunction = false,
            Elements = elements,
            ElementsToIndexes = e_in,
            Created_On_Side = tbl.Created_On_Side,
        }
    else
        return {
            Valid = tbl.Valid,
            _MGROUP_CLASS_INSTANCE = tbl._MGROUP_CLASS_INSTANCE,
        }
    end
end

MGroup.classlink_id = Modularity.RegisterClassLink(IsParamAMGroup, MGroupFromTable, MGroupCompress)
--print("Registered classlink_id", MGroup.classlink_id)


setmetatable(MGroup, MGroup_Class_Meta)

Modularity.AttachStaticEventSystem(MGroup)
Modularity.AttachInstanceEventSystem(MGroup.prototype, MGroup)

Modularity.AddGlobalWatchArgsForClassLinks(MGroup.classlink_id)

Modularity.SetNativeEventsClassLinkCompression(MGroup.classlink_id, Modularity.Default_Configs.Compression.AllRemote)

---🟨 `Shared`
---
---Gets the real MGroup instances table
---@return {[integer]: MGroup_Instance}
function MGroup.GetPairs()
    return MGroup.All_Instances
end

---🟨 `Shared`
---
---Returns a copy of the MGroup entities table
---@return MGroup_Instance[]
function MGroup.GetAll()
    local tbl = {}
    local c = 0
    for k, v in pairs(MGroup.All_Instances) do
        c = c + 1
        tbl[c] = v
    end
    return tbl
end

---🟨 `Shared`
---
---Returns a MGroup given the index, that was created on this side
---@param index integer
---@return MGroup_Instance
function MGroup.GetByIndex(index)
    if (index and type(index) == "number" and math.type(index) == "integer") then
        return MGroup.All_Instances[index]
    else
        error("Wrong arguments on MGroup." .. debug.getinfo(1, "n").name)
    end
end

---🟨 `Shared`
---
---Returns the number of alive MGroups that were created on this side
---@return integer count
function MGroup.GetCount()
    return Modularity.table_count(MGroup.All_Instances)
end


---🟨 `Shared`
---
---Returns if this group instance is valid
---@param is_from_self boolean INTERNAL (Default: nil)
---@return boolean is_valid
function MGroup.prototype:IsGroupValid(is_from_self)
    local valid = self.Valid
    if (not valid and is_from_self) then
        return error("This MGroup is not valid")
    end
    return valid
end

---🟨 `Shared`
---
---Gets the group ID, not unique
---@return integer|nil ID
function MGroup.prototype:GetGroupID()
    if self:IsGroupValid(true) then
        return self.ID
    end
end

---🟨 `Shared`
---
---Destroys this group
---@return boolean|nil success
function MGroup.prototype:DestroyGroup()
    if self:IsGroupValid(true) then
        self:CallEvent("Destroy")
        if MGroup.All_KEYID[self.ID] then
            MGroup.All_Instances[MGroup.All_KEYID[self.ID]] = nil
            MGroup.All_KEYID[self.ID] = nil
        end
        self.Valid = false
        self:Unsubscribe()
        setmetatable(self, MGroup.destroyed_prototype)
        return true
    end
end

---🟨 `Shared`
---
---Gets the group elements real table, do not modify it directly
---@return {[integer]: any}|nil elements
function MGroup.prototype:GetGroupElementsPairs()
    if self:IsGroupValid(true) then
        return self.Elements
    end
end

---🟨 `Shared`
---
---Copies the group elements table
---@return any[]|nil elements
function MGroup.prototype:GetGroupElementsAll()
    if self:IsGroupValid(true) then
        local tbl = {}
        local c = 0
        for k, v in pairs(self.Elements) do
            c = c + 1
            tbl[c] = v
        end
        return tbl
    end
end

---🟨 `Shared`
---
---Gets the group elements count
---@return integer|nil count
function MGroup.prototype:GetGroupElementsCount()
    if self:IsGroupValid(true) then
        return Modularity.table_count(self.Elements)
    end
end


---🟨 `Shared`
---
---Add Group elements
---@param ... any elements to add
---@return boolean|nil success
---@overload fun(self: MGroup_Instance, elements_to_add: {[integer]: any}, pass_table: true)
function MGroup.prototype:AddGroupElements(...)
    if self:IsGroupValid(true) then
        local added_tbl = {...}
        if added_tbl[2] == true then
            if type(added_tbl[1]) ~= "table" then
                return error("Expected a table as the first argument")
            end
            added_tbl = added_tbl[1]
        end
        for k, v in pairs(added_tbl) do
            if not self.ElementsToIndexes[added_tbl[k]] then -- Do not add element if it's already in
                local l_count = Modularity.table_last_count(self.Elements)
                self.Elements[l_count+1] = added_tbl[k]
                self.ElementsToIndexes[added_tbl[k]] = l_count+1

                if (type(added_tbl[k].Subscribe) == "function") then
                    pcall(added_tbl[k].Subscribe, added_tbl[k], "Destroy", function(ent)
                        if self:IsGroupValid() then
                            if self.CallingFunction == true then
                                table.insert(self.TempDestroyed, ent)
                            else
                                self:RemoveGroupElements(ent)
                            end
                        end
                    end)
                end
            end
        end
        self:CallEvent("AddedElements", added_tbl)
        return true
    end
end

---🟨 `Shared`
---
---Removes group elements
---@param ... any elements to remove
---@return boolean|nil success
---@overload fun(self: MGroup_Instance, elements_to_remove: {[integer]: any}, pass_table: true)
function MGroup.prototype:RemoveGroupElements(...)
    if self:IsGroupValid(true) then
        local removed_tbl = {...}
        if removed_tbl[2] == true then
            if type(removed_tbl[1]) ~= "table" then
                return error("Expected a table as the first argument")
            end
            removed_tbl = removed_tbl[1]
        end
        --print("MGroup RemoveGroupElements", NanosTable.Dump(removed_tbl))
        for k, v in pairs(removed_tbl) do
            --print(k, removed_tbl[k])
            if self.ElementsToIndexes[removed_tbl[k]] then
                self.Elements[self.ElementsToIndexes[removed_tbl[k]]] = nil
                self.ElementsToIndexes[removed_tbl[k]] = nil
            end
        end
        self:CallEvent("RemovedElements", removed_tbl)
        return true
    end
end

function MGroup.prototype:__index(key)
    local v_on_prot = rawget(MGroup.prototype, key)

    if v_on_prot ~= nil then
        return v_on_prot
    else
        local v_on_ins = rawget(self, key)
        if v_on_ins ~= nil then
            return v_on_ins
        elseif rawget(self, "Valid") then
            return function(self, ...)
                if self:IsGroupValid(true) then
                    --print("Calling Func On MGroup Instance")
                    self.CallingFunction = true
                    local returns = {}
                    for k, v in pairs(self:GetGroupElementsPairs()) do
                        if (type(v[key]) == "function") then
                            returns[self.ElementsToIndexes[v]] = table.pack(v[key](v, ...))
                        end
                    end

                    self:_FinishedCallingFunction()
                    return returns
                end
            end
        end
    end
end

---🟨 `Shared`
---
---INTERNAL, used to remove elements waiting after calling a function on all elements or after the callfunconloop
function MGroup.prototype:_FinishedCallingFunction()
    self.CallingFunction = false
    self:RemoveGroupElements(self.TempDestroyed, true)
    self.TempDestroyed = {}
end

---🟨 `Shared`
---
---Calls a specific function on loop for each element
---@param f function
---@param ... any parameters, use MGroup.PutHerePlaceholder to put the element at this parameter
---@return {[integer]: any[]}|nil returns
function MGroup.prototype:CallFunctionOnLoopWithElements(f, ...)
    if self:IsGroupValid(true) then
        if (type(f) == "function") then
            local Element_Indexes = {}
            local c = 0

            local args = table.pack(...)
            for i = 1, args.n do
                if (args[i] and args[i] == MGroup.PutHerePlaceholder) then
                    c = c + 1
                    Element_Indexes[c] = i
                end
            end

            self.CallingFunction = true
            local returns = {}
            for k, v in pairs(self:GetGroupElementsPairs()) do
                for i2, v2 in ipairs(Element_Indexes) do
                    args[v2] = v
                end
                returns[self.ElementsToIndexes[v]] = table.pack(f(table.unpack(args, 1, args.n)))
            end

            self:_FinishedCallingFunction()
            return returns
        else
            return error("Missing function to call")
        end
    end
end

---🟨 `Shared`
---
---Get a Group element by its index in the Group elements table
---@param index integer
---@return any element
function MGroup.prototype:GetGroupElementByIndex(index)
    if self:IsGroupValid(true) then
        if (type(index) == "number" and math.type(index) == "integer") then
            return self.Elements[index]
        else
            return error("Passed index invalid")
        end
    end
end

---🟨 `Shared`
---
---Gets a random element in the group, nil if it doesn't have any element
---@return any element
function MGroup.prototype:GetGroupRandomElement()
    if self:IsGroupValid(true) then
        local elements_keys = {}
        local c = 0
        for k, v in pairs(self:GetGroupElementsPairs()) do
            c = c + 1
            elements_keys[c] = v
        end
        if c > 0 then
            return elements_keys[math.random(c)]
        end
    end
end

---🟨 `Shared`
---
---Gets the group element at the biggest index in the group, nil if no element
---@return any element
function MGroup.prototype:GetGroupLastElement()
    if self:IsGroupValid(true) then
        local max_index
        local elements = self:GetGroupElementsPairs()
        for k, v in pairs(elements) do
            if (type(k) == "number") then
                if ((not max_index) or k > max_index) then
                    max_index = k
                end
            end
        end
        if max_index then
            return elements[max_index]
        end
    end
end

---🟨 `Shared`
---
---Checks if this entity is a MGroup
---@param class table
---@return boolean IsA_MGroup
function MGroup.prototype:IsA(class)
    return class == MGroup
end

function MGroup.prototype:__tostring()
    local address = self.address or "?"
    return "MGroup Instance: " .. address
end

--[[function MGroup.prototype:__eq(other)
    if self and other then
        if (self.Valid == true and other.Valid == true) then
            return (self.ID == other.ID and self.Created_On_Side == other.Created_On_Side)
        end
    end
end]]--


MGroup.destroyed_prototype = {}

function MGroup.destroyed_prototype:__tostring()
    local address = self.address or "?"
    return "Destroyed MGroup Instance: " .. address
end

function MGroup.destroyed_prototype:__index(key)
    if (key == "Valid" or key == "address") then
        return rawget(self, key)
    elseif (key == "IsGroupValid" or key == "IsA") then
        return rawget(MGroup.prototype, key)
    elseif key == "__tostring" then
        return rawget(MGroup.destroyed_prototype, key)
    else
        return error("Trying to use a destroyed MGroup")
    end
end

function MGroup.destroyed_prototype:__newindex()
    return error("Trying to use a destroyed MGroup")
end