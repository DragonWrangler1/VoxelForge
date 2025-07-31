-- ore_vein_example.lua - Example of how to register custom ore veins with VoxelGen
-- This file demonstrates the different types of ore veins you can create

-- Example 1: Custom blob-type ore vein
-- This creates irregular blob-like deposits of a custom ore
voxelgen.register_ore_vein("custom_blob_ore", {
    ore_node = "default:stone_with_mese",  -- The ore node to place
    wherein_node = "default:stone",        -- The node to replace
    vein_type = voxelgen.ore_veins.VEIN_TYPES.BLOB,
    
    -- Blob-specific parameters
    blob_threshold = 0.1,  -- Lower threshold = more common
    
    -- Y range where this ore can spawn
    y_min = -500,
    y_max = -100,
    
    -- Biome restrictions (optional)
    biomes = {"desert", "savanna"},  -- Only spawn in these biomes
    
    -- Depth restrictions (optional)
    depth_min = 50,   -- At least 50 blocks below surface
    depth_max = 400,  -- At most 400 blocks below surface
    
    -- Noise parameters control the shape and distribution
    noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 60, y = 60, z = 60},  -- Smaller spread = more clustered
        seed = 2001,
        octaves = 3,
        persist = 0.6,
        lacunarity = 2.0,
        flags = "defaults"
    }
})

-- Example 2: Stratus-type ore vein
-- This creates horizontal layered deposits
voxelgen.register_ore_vein("custom_stratus_ore", {
    ore_node = "default:stone_with_tin",
    wherein_node = "default:stone",
    vein_type = voxelgen.ore_veins.VEIN_TYPES.STRATUS,
    
    -- Stratus-specific parameters
    stratus_thickness = 4,  -- How thick the layers are
    
    y_min = -200,
    y_max = 50,
    
    -- No biome restrictions - spawns everywhere
    
    noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 150, y = 150, z = 150},  -- Larger spread = more spread out layers
        seed = 2002,
        octaves = 2,
        persist = 0.5,
        lacunarity = 2.0,
        flags = "defaults"
    }
})

-- Example 3: Actual vein-type ore
-- This creates vertical or diagonal vein-like deposits
voxelgen.register_ore_vein("custom_vertical_vein", {
    ore_node = "default:stone_with_silver",  -- Assuming you have silver
    wherein_node = "default:stone",
    vein_type = voxelgen.ore_veins.VEIN_TYPES.VEIN,
    
    -- Vein-specific parameters
    vein_direction = "vertical",  -- "vertical", "horizontal", or "diagonal"
    vein_thickness = 3,           -- How thick the vein is
    
    y_min = -400,
    y_max = 0,
    
    -- Only spawn in cold biomes
    biomes = {"tundra", "taiga", "snowy_mountains"},
    
    noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 100, y = 100, z = 100},
        seed = 2003,
        octaves = 2,
        persist = 0.7,
        lacunarity = 2.0,
        flags = "defaults"
    }
})

-- Example 4: Diagonal vein
voxelgen.register_ore_vein("custom_diagonal_vein", {
    ore_node = "default:stone_with_copper",
    wherein_node = "default:stone",
    vein_type = voxelgen.ore_veins.VEIN_TYPES.VEIN,
    
    vein_direction = "diagonal",
    vein_thickness = 2,
    
    y_min = -300,
    y_max = 32,
    
    noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 80, y = 80, z = 80},
        seed = 2004,
        octaves = 3,
        persist = 0.6,
        lacunarity = 2.0,
        flags = "defaults"
    }
})

-- Example 5: Scatter-type ore
-- This creates randomly scattered individual ore nodes
voxelgen.register_ore_vein("custom_scatter_ore", {
    ore_node = "default:stone_with_diamond",
    wherein_node = "default:stone",
    vein_type = voxelgen.ore_veins.VEIN_TYPES.SCATTER,
    
    -- Scatter-specific parameters
    clust_scarcity = 25 * 25 * 25,  -- Higher = more rare
    
    y_min = -1000,
    y_max = -500,
    
    -- Very deep and rare
    depth_min = 500,
    
    noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 200, y = 200, z = 200},
        seed = 2005,
        octaves = 3,
        persist = 0.8,
        lacunarity = 2.0,
        flags = "defaults"
    }
})

-- Example 6: Cluster-type ore
-- This creates small clustered deposits
voxelgen.register_ore_vein("custom_cluster_ore", {
    ore_node = "default:stone_with_gold",
    wherein_node = "default:stone",
    vein_type = voxelgen.ore_veins.VEIN_TYPES.CLUSTER,
    
    -- Cluster-specific parameters
    clust_scarcity = 15 * 15 * 15,  -- How rare clusters are
    clust_num_ores = 6,             -- How many ore nodes per cluster
    clust_size = 3,                 -- How spread out the cluster is
    
    y_min = -800,
    y_max = -200,
    
    -- Only in mountain biomes
    biomes = {"mountains", "alpine"},
    
    noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 120, y = 120, z = 120},
        seed = 2006,
        octaves = 3,
        persist = 0.7,
        lacunarity = 2.0,
        flags = "defaults"
    }
})

-- Example 7: Biome-specific ore with complex restrictions
voxelgen.register_ore_vein("desert_special_ore", {
    ore_node = "default:sandstone",  -- Special desert ore
    wherein_node = "default:desert_stone",  -- Only replaces desert stone
    vein_type = voxelgen.ore_veins.VEIN_TYPES.BLOB,
    
    blob_threshold = 0.2,
    
    y_min = -100,
    y_max = 50,
    
    -- Only in desert biomes
    biomes = {"desert", "desert_ocean"},
    
    -- Only near surface
    depth_min = 10,
    depth_max = 100,
    
    noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 40, y = 40, z = 40},
        seed = 2007,
        octaves = 4,
        persist = 0.5,
        lacunarity = 2.0,
        flags = "defaults"
    }
})

-- Log that the example ores were registered
minetest.log("action", "[VoxelGen Example] Custom ore veins registered!")

-- You can also check if an ore vein is registered:
if voxelgen.is_ore_vein_registered("custom_blob_ore") then
    minetest.log("action", "[VoxelGen Example] Custom blob ore successfully registered")
end

-- Get information about a specific ore vein:
local blob_ore_info = voxelgen.get_ore_vein("custom_blob_ore")
if blob_ore_info then
    minetest.log("action", "[VoxelGen Example] Blob ore info: " .. 
                 blob_ore_info.ore_node .. " in " .. blob_ore_info.wherein_node)
end