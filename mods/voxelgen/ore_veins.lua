-- ore_veins.lua - Ore vein generation system for VoxelGen
-- Supports different vein types: blobs, stratus, and actual veins

local ore_veins = {}

-- Dependencies
local api = nil -- Will be set during initialization

-- Logging helper
local function log(level, message)
    minetest.log(level, "[VoxelGen OreVeins] " .. message)
end

-- Ore vein registry
local registered_veins = {}

-- Vein types
ore_veins.VEIN_TYPES = {
    BLOB = "blob",           -- Irregular blob-like deposits
    STRATUS = "stratus",     -- Horizontal layered deposits
    VEIN = "vein",          -- Vertical/diagonal vein-like deposits
    SCATTER = "scatter",     -- Scattered individual nodes
    CLUSTER = "cluster"      -- Small clustered deposits
}

-- Default vein parameters
local DEFAULT_VEIN_PARAMS = {
    -- Common parameters
    ore_node = "default:stone_with_coal",
    wherein_node = "default:stone",
    clust_scarcity = 9 * 9 * 9,
    clust_num_ores = 8,
    clust_size = 3,
    y_min = -31000,
    y_max = 31000,
    
    -- Vein-specific parameters
    vein_type = ore_veins.VEIN_TYPES.BLOB,
    
    -- Blob parameters
    blob_threshold = 0.0,
    
    -- Stratus parameters
    stratus_thickness = 2,
    
    -- Vein parameters
    vein_thickness = 2,
    vein_direction = "vertical", -- "vertical", "horizontal", "diagonal"
    
    -- Biome restrictions
    biomes = nil, -- nil means all biomes
    
    -- Depth restrictions
    depth_min = nil,
    depth_max = nil,
    
    -- Noise parameters for vein generation
    noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 100, y = 100, z = 100},
        seed = 0,
        octaves = 3,
        persist = 0.6,
        lacunarity = 2.0,
        flags = "defaults"
    }
}

-- Initialize the ore vein system
function ore_veins.init(api_instance)
    api = api_instance
    log("action", "Ore vein system initialized")
end

-- Register a new ore vein
function ore_veins.register_vein(name, definition)
    if not name or type(name) ~= "string" then
        log("error", "Invalid vein name provided")
        return false
    end
    
    if not definition or type(definition) ~= "table" then
        log("error", "Invalid vein definition provided for " .. name)
        return false
    end
    
    -- Validate required parameters
    if not definition.ore_node then
        log("error", "Missing ore_node in vein definition for " .. name)
        return false
    end
    
    if not definition.wherein_node then
        log("error", "Missing wherein_node in vein definition for " .. name)
        return false
    end
    
    -- Merge with defaults
    local vein_def = {}
    for key, value in pairs(DEFAULT_VEIN_PARAMS) do
        vein_def[key] = definition[key] ~= nil and definition[key] or value
    end
    
    -- Set unique seed if not provided
    if vein_def.noise_params.seed == 0 then
        vein_def.noise_params.seed = minetest.hash_node_position({x = 0, y = 0, z = string.len(name)})
    end
    
    -- Validate vein type
    local valid_type = false
    for _, vtype in pairs(ore_veins.VEIN_TYPES) do
        if vein_def.vein_type == vtype then
            valid_type = true
            break
        end
    end
    
    if not valid_type then
        log("error", "Invalid vein_type '" .. tostring(vein_def.vein_type) .. "' for vein " .. name)
        return false
    end
    
    -- Store the vein definition
    registered_veins[name] = vein_def
    
    log("action", "Registered ore vein: " .. name .. " (type: " .. vein_def.vein_type .. ")")
    return true
end

-- Get all registered veins
function ore_veins.get_registered_veins()
    return registered_veins
end

-- Get a specific vein definition
function ore_veins.get_vein(name)
    return registered_veins[name]
end

-- Check if a position is within biome restrictions
local function check_biome_restrictions(vein_def, biome_name)
    if not vein_def.biomes then
        return true -- No restrictions
    end
    
    if type(vein_def.biomes) == "string" then
        return vein_def.biomes == biome_name
    elseif type(vein_def.biomes) == "table" then
        for _, allowed_biome in ipairs(vein_def.biomes) do
            if allowed_biome == biome_name then
                return true
            end
        end
    end
    
    return false
end

-- Check if a position is within depth restrictions
local function check_depth_restrictions(vein_def, depth)
    if vein_def.depth_min and depth < vein_def.depth_min then
        return false
    end
    if vein_def.depth_max and depth > vein_def.depth_max then
        return false
    end
    return true
end

-- Generate blob-type ore deposits
local function generate_blob_ore(data, area, minp, maxp, vein_def, noise_obj, biome_map, heightmap)
    local ore_id = minetest.get_content_id(vein_def.ore_node)
    local wherein_id = minetest.get_content_id(vein_def.wherein_node)
    
    for z = minp.z, maxp.z do
        for y = minp.y, maxp.y do
            for x = minp.x, maxp.x do
                local vi = area:index(x, y, z)
                
                -- Only replace the specified wherein node
                if data[vi] == wherein_id then
                    -- Check Y range
                    if y >= vein_def.y_min and y <= vein_def.y_max then
                        -- Get noise value
                        local noise_val = noise_obj:get_3d({x = x, y = y, z = z})
                        
                        -- Check if above threshold
                        if noise_val > vein_def.blob_threshold then
                            local place_ore = true
                            
                            -- Check biome restrictions if biome_map is available
                            if place_ore and biome_map then
                                local biome_idx = (z - minp.z) * (maxp.x - minp.x + 1) + (x - minp.x + 1)
                                local biome = biome_map[biome_idx]
                                if biome and not check_biome_restrictions(vein_def, biome.name) then
                                    place_ore = false
                                end
                            end
                            
                            -- Check depth restrictions if heightmap is available
                            if place_ore and heightmap then
                                local height_idx = (z - minp.z) * (maxp.x - minp.x + 1) + (x - minp.x + 1)
                                local terrain_height = heightmap[height_idx]
                                local depth = terrain_height - y
                                if not check_depth_restrictions(vein_def, depth) then
                                    place_ore = false
                                end
                            end
                            
                            if place_ore then
                                data[vi] = ore_id
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Generate stratus-type ore deposits
local function generate_stratus_ore(data, area, minp, maxp, vein_def, noise_obj, biome_map, heightmap)
    local ore_id = minetest.get_content_id(vein_def.ore_node)
    local wherein_id = minetest.get_content_id(vein_def.wherein_node)
    
    -- Generate horizontal layers
    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            -- Get base Y level from noise
            local base_noise = noise_obj:get_2d({x = x, y = z})
            local base_y = math.floor(minp.y + (maxp.y - minp.y) * (base_noise + 1) / 2)
            
            local place_stratus = true
            
            -- Check biome restrictions if biome_map is available
            if biome_map then
                local biome_idx = (z - minp.z) * (maxp.x - minp.x + 1) + (x - minp.x + 1)
                local biome = biome_map[biome_idx]
                if biome and not check_biome_restrictions(vein_def, biome.name) then
                    place_stratus = false
                end
            end
            
            -- Generate stratus layer
            if place_stratus then
                for layer_y = base_y, base_y + vein_def.stratus_thickness - 1 do
                    if layer_y >= minp.y and layer_y <= maxp.y and layer_y >= vein_def.y_min and layer_y <= vein_def.y_max then
                        local vi = area:index(x, layer_y, z)
                        
                        if data[vi] == wherein_id then
                            local place_layer = true
                            
                            -- Check depth restrictions if heightmap is available
                            if heightmap then
                                local height_idx = (z - minp.z) * (maxp.x - minp.x + 1) + (x - minp.x + 1)
                                local terrain_height = heightmap[height_idx]
                                local depth = terrain_height - layer_y
                                if not check_depth_restrictions(vein_def, depth) then
                                    place_layer = false
                                end
                            end
                            
                            if place_layer then
                                data[vi] = ore_id
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Generate vein-type ore deposits
local function generate_vein_ore(data, area, minp, maxp, vein_def, noise_obj, biome_map, heightmap)
    local ore_id = minetest.get_content_id(vein_def.ore_node)
    local wherein_id = minetest.get_content_id(vein_def.wherein_node)
    
    -- Generate veins based on direction
    if vein_def.vein_direction == "vertical" then
        -- Vertical veins
        for z = minp.z, maxp.z do
            for x = minp.x, maxp.x do
                local noise_val = noise_obj:get_2d({x = x, y = z})
                if noise_val > 0.3 then -- Threshold for vein generation
                    local place_vein = true
                    
                    -- Check biome restrictions
                    if biome_map then
                        local biome_idx = (z - minp.z) * (maxp.x - minp.x + 1) + (x - minp.x + 1)
                        local biome = biome_map[biome_idx]
                        if biome and not check_biome_restrictions(vein_def, biome.name) then
                            place_vein = false
                        end
                    end
                    
                    -- Generate vertical vein
                    if place_vein then
                        for y = minp.y, maxp.y do
                            if y >= vein_def.y_min and y <= vein_def.y_max then
                                -- Add some thickness to the vein
                                for dx = -math.floor(vein_def.vein_thickness/2), math.floor(vein_def.vein_thickness/2) do
                                    for dz = -math.floor(vein_def.vein_thickness/2), math.floor(vein_def.vein_thickness/2) do
                                        local vein_x = x + dx
                                        local vein_z = z + dz
                                        if vein_x >= minp.x and vein_x <= maxp.x and vein_z >= minp.z and vein_z <= maxp.z then
                                            local vi = area:index(vein_x, y, vein_z)
                                            if data[vi] == wherein_id then
                                                local place_thickness = true
                                                
                                                -- Check depth restrictions
                                                if heightmap then
                                                    local height_idx = (vein_z - minp.z) * (maxp.x - minp.x + 1) + (vein_x - minp.x + 1)
                                                    local terrain_height = heightmap[height_idx]
                                                    local depth = terrain_height - y
                                                    if not check_depth_restrictions(vein_def, depth) then
                                                        place_thickness = false
                                                    end
                                                end
                                                
                                                if place_thickness then
                                                    data[vi] = ore_id
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    elseif vein_def.vein_direction == "diagonal" then
        -- Diagonal veins (simplified implementation)
        for z = minp.z, maxp.z do
            for x = minp.x, maxp.x do
                local noise_val = noise_obj:get_2d({x = x, y = z})
                if noise_val > 0.3 then
                    local place_diag = true
                    
                    -- Check biome restrictions
                    if biome_map then
                        local biome_idx = (z - minp.z) * (maxp.x - minp.x + 1) + (x - minp.x + 1)
                        local biome = biome_map[biome_idx]
                        if biome and not check_biome_restrictions(vein_def, biome.name) then
                            place_diag = false
                        end
                    end
                    
                    -- Generate diagonal vein
                    if place_diag then
                        for y = minp.y, maxp.y do
                            if y >= vein_def.y_min and y <= vein_def.y_max then
                                -- Create diagonal pattern
                                local diag_x = x + math.floor((y - minp.y) * 0.5)
                                local diag_z = z + math.floor((y - minp.y) * 0.3)
                                
                                if diag_x >= minp.x and diag_x <= maxp.x and diag_z >= minp.z and diag_z <= maxp.z then
                                    local vi = area:index(diag_x, y, diag_z)
                                    if data[vi] == wherein_id then
                                        local place_diag_y = true
                                        
                                        -- Check depth restrictions
                                        if heightmap then
                                            local height_idx = (diag_z - minp.z) * (maxp.x - minp.x + 1) + (diag_x - minp.x + 1)
                                            local terrain_height = heightmap[height_idx]
                                            local depth = terrain_height - y
                                            if not check_depth_restrictions(vein_def, depth) then
                                                place_diag_y = false
                                            end
                                        end
                                        
                                        if place_diag_y then
                                            data[vi] = ore_id
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Generate scatter-type ore deposits
local function generate_scatter_ore(data, area, minp, maxp, vein_def, noise_obj, biome_map, heightmap)
    local ore_id = minetest.get_content_id(vein_def.ore_node)
    local wherein_id = minetest.get_content_id(vein_def.wherein_node)
    
    -- Use scarcity to determine placement probability
    local placement_chance = 1.0 / vein_def.clust_scarcity
    
    for z = minp.z, maxp.z do
        for y = minp.y, maxp.y do
            for x = minp.x, maxp.x do
                local vi = area:index(x, y, z)
                
                if data[vi] == wherein_id then
                    if y >= vein_def.y_min and y <= vein_def.y_max then
                        local noise_val = noise_obj:get_3d({x = x, y = y, z = z})
                        
                        -- Convert noise to probability
                        local probability = (noise_val + 1) / 2 * placement_chance
                        
                        if math.random() < probability then
                            local place_scatter = true
                            
                            -- Check biome restrictions
                            if biome_map then
                                local biome_idx = (z - minp.z) * (maxp.x - minp.x + 1) + (x - minp.x + 1)
                                local biome = biome_map[biome_idx]
                                if biome and not check_biome_restrictions(vein_def, biome.name) then
                                    place_scatter = false
                                end
                            end
                            
                            -- Check depth restrictions
                            if place_scatter and heightmap then
                                local height_idx = (z - minp.z) * (maxp.x - minp.x + 1) + (x - minp.x + 1)
                                local terrain_height = heightmap[height_idx]
                                local depth = terrain_height - y
                                if not check_depth_restrictions(vein_def, depth) then
                                    place_scatter = false
                                end
                            end
                            
                            if place_scatter then
                                data[vi] = ore_id
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Generate cluster-type ore deposits
local function generate_cluster_ore(data, area, minp, maxp, vein_def, noise_obj, biome_map, heightmap)
    local ore_id = minetest.get_content_id(vein_def.ore_node)
    local wherein_id = minetest.get_content_id(vein_def.wherein_node)
    
    -- Generate cluster centers
    local cluster_centers = {}
    local placement_chance = 1.0 / (vein_def.clust_scarcity * 0.1) -- More frequent than scatter
    
    for z = minp.z, maxp.z, 8 do -- Sample every 8 blocks for performance
        for y = minp.y, maxp.y, 8 do
            for x = minp.x, maxp.x, 8 do
                if y >= vein_def.y_min and y <= vein_def.y_max then
                    local noise_val = noise_obj:get_3d({x = x, y = y, z = z})
                    local probability = (noise_val + 1) / 2 * placement_chance
                    
                    if math.random() < probability then
                        local place_cluster_center = true
                        
                        -- Check biome restrictions
                        if biome_map then
                            local biome_idx = math.max(1, math.min((z - minp.z) * (maxp.x - minp.x + 1) + (x - minp.x + 1), #biome_map))
                            local biome = biome_map[biome_idx]
                            if biome and not check_biome_restrictions(vein_def, biome.name) then
                                place_cluster_center = false
                            end
                        end
                        
                        -- Check depth restrictions
                        if place_cluster_center and heightmap then
                            local height_idx = math.max(1, math.min((z - minp.z) * (maxp.x - minp.x + 1) + (x - minp.x + 1), #heightmap))
                            local terrain_height = heightmap[height_idx]
                            local depth = terrain_height - y
                            if not check_depth_restrictions(vein_def, depth) then
                                place_cluster_center = false
                            end
                        end
                        
                        if place_cluster_center then
                            table.insert(cluster_centers, {x = x, y = y, z = z})
                        end
                    end
                end
            end
        end
    end
    
    -- Generate clusters around centers
    for _, center in ipairs(cluster_centers) do
        local cluster_size = vein_def.clust_size
        local num_ores = vein_def.clust_num_ores
        
        for i = 1, num_ores do
            local dx = math.random(-cluster_size, cluster_size)
            local dy = math.random(-cluster_size, cluster_size)
            local dz = math.random(-cluster_size, cluster_size)
            
            local ore_x = center.x + dx
            local ore_y = center.y + dy
            local ore_z = center.z + dz
            
            if ore_x >= minp.x and ore_x <= maxp.x and 
               ore_y >= minp.y and ore_y <= maxp.y and 
               ore_z >= minp.z and ore_z <= maxp.z then
                local vi = area:index(ore_x, ore_y, ore_z)
                if data[vi] == wherein_id then
                    data[vi] = ore_id
                end
            end
        end
    end
end

-- Generate ore veins in a chunk
function ore_veins.generate_ores(data, area, minp, maxp, biome_map, heightmap, world_seed)
    if not api then
        log("error", "Ore vein system not initialized")
        return
    end
    
    -- Create noise objects for each vein type
    local noise_objects = {}
    
    for vein_name, vein_def in pairs(registered_veins) do
        -- Create noise object for this vein
        local noise_params = {}
        for k, v in pairs(vein_def.noise_params) do
            if type(v) == "table" then
                noise_params[k] = {}
                for k2, v2 in pairs(v) do
                    noise_params[k][k2] = v2
                end
            else
                noise_params[k] = v
            end
        end
        noise_params.seed = noise_params.seed + (world_seed or 0)
        
        noise_objects[vein_name] = minetest.get_perlin(noise_params)
        
        -- Generate ores based on vein type
        if vein_def.vein_type == ore_veins.VEIN_TYPES.BLOB then
            generate_blob_ore(data, area, minp, maxp, vein_def, noise_objects[vein_name], biome_map, heightmap)
        elseif vein_def.vein_type == ore_veins.VEIN_TYPES.STRATUS then
            generate_stratus_ore(data, area, minp, maxp, vein_def, noise_objects[vein_name], biome_map, heightmap)
        elseif vein_def.vein_type == ore_veins.VEIN_TYPES.VEIN then
            generate_vein_ore(data, area, minp, maxp, vein_def, noise_objects[vein_name], biome_map, heightmap)
        elseif vein_def.vein_type == ore_veins.VEIN_TYPES.SCATTER then
            generate_scatter_ore(data, area, minp, maxp, vein_def, noise_objects[vein_name], biome_map, heightmap)
        elseif vein_def.vein_type == ore_veins.VEIN_TYPES.CLUSTER then
            generate_cluster_ore(data, area, minp, maxp, vein_def, noise_objects[vein_name], biome_map, heightmap)
        end
    end
end

-- Register some default ore veins
function ore_veins.register_defaults()
    -- Coal veins (blob type)
    ore_veins.register_vein("coal_blob", {
        ore_node = "vlf_blocks:coal_ore",
        wherein_node = "vlf_blocks:stone",
        vein_type = ore_veins.VEIN_TYPES.BLOB,
        blob_threshold = 0.2,
        y_min = -200,
        y_max = 64,
        noise_params = {
            offset = 0,
            scale = 1,
            spread = {x = 80, y = 80, z = 80},
            seed = 1001,
            octaves = 3,
            persist = 0.6,
            lacunarity = 2.0,
            flags = "defaults"
        }
    })
    
    -- Iron veins (actual veins)
    ore_veins.register_vein("iron_vein", {
        ore_node = "default:stone_with_iron",
        wherein_node = "vlf_blocks:stone",
        vein_type = ore_veins.VEIN_TYPES.VEIN,
        vein_direction = "vertical",
        vein_thickness = 2,
        y_min = -300,
        y_max = 32,
        noise_params = {
            offset = 0,
            scale = 1,
            spread = {x = 120, y = 120, z = 120},
            seed = 1002,
            octaves = 2,
            persist = 0.7,
            lacunarity = 2.0,
            flags = "defaults"
        }
    })
    
    -- Copper stratus
    ore_veins.register_vein("copper_stratus", {
        ore_node = "default:stone_with_copper",
        wherein_node = "default:stone",
        vein_type = ore_veins.VEIN_TYPES.STRATUS,
        stratus_thickness = 3,
        y_min = -150,
        y_max = 16,
        noise_params = {
            offset = 0,
            scale = 1,
            spread = {x = 200, y = 200, z = 200},
            seed = 1003,
            octaves = 2,
            persist = 0.5,
            lacunarity = 2.0,
            flags = "defaults"
        }
    })
    
    -- Gold scatter
    ore_veins.register_vein("gold_scatter", {
        ore_node = "default:stone_with_gold",
        wherein_node = "default:stone",
        vein_type = ore_veins.VEIN_TYPES.SCATTER,
        clust_scarcity = 15 * 15 * 15,
        y_min = -500,
        y_max = -64,
        noise_params = {
            offset = 0,
            scale = 1,
            spread = {x = 100, y = 100, z = 100},
            seed = 1004,
            octaves = 3,
            persist = 0.6,
            lacunarity = 2.0,
            flags = "defaults"
        }
    })
    
    -- Diamond clusters
    ore_veins.register_vein("diamond_cluster", {
        ore_node = "default:stone_with_diamond",
        wherein_node = "default:stone",
        vein_type = ore_veins.VEIN_TYPES.CLUSTER,
        clust_scarcity = 20 * 20 * 20,
        clust_num_ores = 4,
        clust_size = 2,
        y_min = -1000,
        y_max = -200,
        noise_params = {
            offset = 0,
            scale = 1,
            spread = {x = 150, y = 150, z = 150},
            seed = 1005,
            octaves = 3,
            persist = 0.7,
            lacunarity = 2.0,
            flags = "defaults"
        }
    })
    
    log("action", "Default ore veins registered")
    return true
end

-- Get statistics about registered veins
function ore_veins.get_statistics()
    local stats = {
        total_veins = 0,
        by_type = {},
        y_range = {min = 31000, max = -31000}
    }
    
    for name, vein_def in pairs(registered_veins) do
        stats.total_veins = stats.total_veins + 1
        
        -- Count by type
        local vtype = vein_def.vein_type
        stats.by_type[vtype] = (stats.by_type[vtype] or 0) + 1
        
        -- Track Y range
        stats.y_range.min = math.min(stats.y_range.min, vein_def.y_min)
        stats.y_range.max = math.max(stats.y_range.max, vein_def.y_max)
    end
    
    return stats
end

return ore_veins
