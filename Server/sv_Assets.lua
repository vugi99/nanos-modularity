


HTTP_Request_Default_Asset_Pack = true


local default_asset_pack_endpoint = ""

local asset_packs = Assets.GetAssetPacks()

local asset_packs_has_to_load_c = Modularity.table_count(asset_packs)

local function _CheckAssetPackLoadEnd()
    if (asset_packs_has_to_load_c <= 0 and Modularity.AssetPacks._loaded == false) then
        Modularity.AssetPacks._loaded = true
        Modularity.CallEvent("AssetPacksLoaded")
    end
end


if not HTTP_Request_Default_Asset_Pack then
    asset_packs_has_to_load_c = asset_packs_has_to_load_c - 1
    _CheckAssetPackLoadEnd()
end

for i, v in pairs(asset_packs) do
    if (v.UnrealFolder ~= "NanosWorld") then
        if File.Exists("Assets/" .. v.Path .. "/Assets.toml") then
            Modularity.AssetPacks[v.Path] = Modularity.DuplicateTable(v)
            local file = File("Assets/" .. v.Path .. "/Assets.toml", false)
            if file:IsGood() then
                file:ReadAsync(0, function(file_content)
                    Modularity.AssetPacks[v.Path].Assets_toml = file_content
                    Modularity.AssetPacks[v.Path].Parsed_toml = TOML.parse(file_content)

                    --print("after_toml_parse", NanosTable.Dump(Modularity.DumpKeys(Modularity.AssetPacks[v.Path].Parsed_toml)))
                    file:Close()

                    asset_packs_has_to_load_c = asset_packs_has_to_load_c - 1
                    _CheckAssetPackLoadEnd()
                end)
            end
        end
    end
end

if HTTP_Request_Default_Asset_Pack then
    
end

local function _AssetsKeyFindAsset(splited_asset, v)
    if v[splited_asset[2]] then
        if type(v[splited_asset[2]]) == "string" then -- Behavior without meta data
            return v[splited_asset[2]]
        elseif type(v[splited_asset[2]]) == "table" then -- With meta data
            if type(v[splited_asset[2]].path) == "string" then
                return v[splited_asset[2]].path
            end
        end
    end
end

function Modularity.GetAssetReferencePath(asset, atype)
    atype = atype or "*"

    local splited_asset = Modularity.split_str(asset, ":")
    if (splited_asset[2] and (not splited_asset[3])) then
        if Modularity.AssetPacks[splited_asset[1]] then
            local asset_pack_p_toml = Modularity.AssetPacks[splited_asset[1]].Parsed_toml
            if asset_pack_p_toml then
                if asset_pack_p_toml.assets then
                    if atype == "*" then
                        for atypek, v in pairs(assets) do
                            local ret = _AssetsKeyFindAsset(splited_asset, v)
                            if (ret ~= nil) then
                                return ret
                            end
                        end
                    elseif assets[atype] then
                        return _AssetsKeyFindAsset(splited_asset, assets[atype])
                    else
                        error("asset type " .. tostring(atype) .. " not found in asset pack")
                    end
                else
                    error("No assets in parsed toml ?")
                end
            else
                error("Asset pack parsed toml not found")
            end
        else
            error("Asset pack data not initialized (Or not found)")
        end
    else
        error("Invalid asset")
    end
end