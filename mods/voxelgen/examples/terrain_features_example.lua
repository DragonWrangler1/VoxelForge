-- terrain_features_example.lua - Example terrain features for VoxelGen
-- This file demonstrates how to register terrain features and surface coverings

-- Example 1: Simple block feature (flowers)
-- Demonstrates the use of place_on field with multiple allowed blocks
if minetest.get_modpath("voxelgen") then
    -- Register a simple flower feature
    voxelgen.register_terrain_feature("example:red_flower", {
        type = "block",
        node = "vlf_blocks:grass", -- Using available node as example
        biomes = {"plains", "grassland"}, -- Only spawn in these biomes
        probability = 0.05, -- 5% chance when noise conditions are met
        min_height = 1,
        max_height = 100,
        avoid_water = true,
        need_solid_ground = true,
        place_on = {"vlf_blocks:dirt_with_grass", "vlf_blocks:dirt"}, -- Only place on grass or dirt
        spacing = 2, -- Minimum 2 blocks between features
        noise = {
            offset = 0,
            scale = 1,
            spread = {x = 30, y = 30, z = 30},
            seed = 12345,
            octaves = 2,
            persist = 0.5,
            lacunarity = 2.0
        }
    })
end

-- Example 2: Function-based feature (custom tree)
-- Demonstrates the use of place_on field with a single allowed block
if minetest.get_modpath("voxelgen") then
    -- Custom tree placement function
    local function place_custom_tree(x, y, z, data, area, biome_name, feature_def)
        local trunk_id = minetest.get_content_id("vlf_blocks:stone") -- Using stone as trunk example
        local leaves_id = minetest.get_content_id("vlf_blocks:dirt") -- Using dirt as leaves example
        
        -- Place trunk (3 blocks high)
        for trunk_y = y, y + 2 do
            if area:contains(x, trunk_y, z) then
                local vi = area:index(x, trunk_y, z)
                data[vi] = trunk_id
            end
        end
        
        -- Place leaves (simple 3x3 pattern at top)
        local leaves_y = y + 3
        for dx = -1, 1 do
            for dz = -1, 1 do
                local leaf_x = x + dx
                local leaf_z = z + dz
                if area:contains(leaf_x, leaves_y, leaf_z) then
                    local vi = area:index(leaf_x, leaves_y, leaf_z)
                    data[vi] = leaves_id
                end
            end
        end
        
        return true -- Successfully placed
    end
    
    -- Register the custom tree feature
    voxelgen.register_terrain_feature("example:custom_tree", {
        type = "function",
        place_function = place_custom_tree,
        biomes = {"plains", "forest"}, -- Spawn in plains and forest biomes
        probability = 0.02, -- 2% chance
        min_height = 1,
        max_height = 80,
        avoid_water = true,
        need_solid_ground = true,
        place_on = "vlf_blocks:dirt_with_grass", -- Only place on grass (single node example)
        spacing = 8, -- Trees need more space
        noise = {
            offset = 0,
            scale = 1,
            spread = {x = 80, y = 80, z = 80},
            seed = 54321,
            octaves = 3,
            persist = 0.6,
            lacunarity = 2.0
        }
    })
end

-- Example 3: Schematic-based feature (small structure)
-- Demonstrates the use of place_on field with multiple terrain types
if minetest.get_modpath("voxelgen") then
    -- Define a simple schematic as a table
    local small_structure = {
        {x = 0, y = 0, z = 0, node = "vlf_blocks:stone"},
        {x = 1, y = 0, z = 0, node = "vlf_blocks:stone"},
        {x = 0, y = 0, z = 1, node = "vlf_blocks:stone"},
        {x = 1, y = 0, z = 1, node = "vlf_blocks:stone"},
        {x = 0, y = 1, z = 0, node = "vlf_blocks:dirt"},
        {x = 1, y = 1, z = 1, node = "vlf_blocks:dirt"},
    }
    
    -- Register the schematic feature
    voxelgen.register_terrain_feature("example:small_structure", {
        type = "schematic",
        schematic = small_structure,
        biomes = {"*"}, -- Spawn in all biomes
        probability = 0.001, -- Very rare (0.1% chance)
        min_height = 1,
        max_height = 50,
        avoid_water = true,
        need_solid_ground = true,
        place_on = {"vlf_blocks:stone", "vlf_blocks:dirt", "vlf_blocks:sand"}, -- Can place on multiple block types
        spacing = 20, -- Structures need lots of space
        noise = {
            offset = 0,
            scale = 1,
            spread = {x = 200, y = 200, z = 200},
            seed = 98765,
            octaves = 4,
            persist = 0.7,
            lacunarity = 2.0
        }
    })
end

-- Example 4: Biome with surface covering (snow)
if minetest.get_modpath("voxelgen") then
    -- Create a snowy biome with surface covering
    local snowy_biome = voxelgen.create_biome_def(
        "example:snowy_plains",
        {
            temperature_levels = {0, 1}, -- Cold temperatures
            humidity_levels = {1, 2, 3}, -- Various humidity levels
            continentalness_names = {"near_inland", "mid_inland"},
            erosion_levels = {3, 4}, -- Flat areas
            pv_names = {"low", "mid"},
            depth_min = 0,
            depth_max = 50,
            y_min = 1,
            y_max = 100
        },
        {
            node_top = "vlf_blocks:dirt_with_grass",
            node_filler = "vlf_blocks:dirt",
            node_stone = "vlf_blocks:stone"
        },
        {
            depth_top = 1,
            depth_filler = 3,
            priority = 10,
            -- Node dust configuration
            node_dust = "vlf_blocks:sand" -- Using sand as dust example
        }
    )
    
    if snowy_biome then
        voxelgen.register_biome(snowy_biome)
    end
end

-- Example 5: Biome with surface replacement
if minetest.get_modpath("voxelgen") then
    -- Create a desert biome that replaces the top surface
    local desert_biome = voxelgen.create_biome_def(
        "example:hot_desert",
        {
            temperature_levels = {3, 4}, -- Hot temperatures
            humidity_levels = {0, 1}, -- Dry
            continentalness_names = {"near_inland", "mid_inland"},
            erosion_levels = {3, 4}, -- Flat areas
            pv_names = {"low", "mid"},
            depth_min = 0,
            depth_max = 50,
            y_min = 1,
            y_max = 100
        },
        {
            node_top = "vlf_blocks:sand",
            node_filler = "vlf_blocks:sand",
            node_stone = "vlf_blocks:stone"
        },
        {
            depth_top = 3,
            depth_filler = 5,
            priority = 8,
            -- Node dust configuration
            node_dust = "vlf_blocks:stone" -- Using stone as dust example
        }
    )
    
    if desert_biome then
        voxelgen.register_biome(desert_biome)
    end
end