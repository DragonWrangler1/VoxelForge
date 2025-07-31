-- init.lua - VoxelGen main initialization
-- The ultimate Luanti Mapgen with API-based architecture

-- Export API for other mods first (before mapgen initialization)
voxelgen = {
    api = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/api.lua"),
    climate = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/climate.lua"),
    biomes = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/biomes_new.lua"),
    caves = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/caves.lua"), -- Still loaded for config access
    hud = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/hud.lua"),
    ore_veins = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/ore_veins.lua"),
    terrain_features = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/terrain_features.lua"),
}

-- Verify that modules loaded correctly
minetest.log("action", "[VoxelGen] Module loading verification:")
minetest.log("action", "[VoxelGen] - api: " .. tostring(voxelgen.api ~= nil))
minetest.log("action", "[VoxelGen] - climate: " .. tostring(voxelgen.climate ~= nil))
minetest.log("action", "[VoxelGen] - biomes: " .. tostring(voxelgen.biomes ~= nil))
minetest.log("action", "[VoxelGen] - caves: " .. tostring(voxelgen.caves ~= nil))
minetest.log("action", "[VoxelGen] - ore_veins: " .. tostring(voxelgen.ore_veins ~= nil))
minetest.log("action", "[VoxelGen] - terrain_features: " .. tostring(voxelgen.terrain_features ~= nil))
if voxelgen.biomes then
    minetest.log("action", "[VoxelGen] - biomes.create_biome_def: " .. tostring(voxelgen.biomes.create_biome_def ~= nil))
end

-- Initialize and register default biomes after all mods have loaded
minetest.register_on_mods_loaded(function()
    minetest.log("action", "[VoxelGen] Mods loaded callback triggered - initializing biome system...")
    
    -- Initialize the biome system
    local init_success = voxelgen.biomes.initialize()
    if not init_success then
        minetest.log("error", "[VoxelGen] Failed to initialize biome system!")
        return
    end
    
    -- Default biomes are now registered by vlf_biomes mod
    minetest.log("action", "[VoxelGen] Biome system initialized - biomes will be registered by vlf_biomes mod")
    
    -- Register default ore veins
    local ore_success = voxelgen.ore_veins.register_defaults()
    if ore_success then
        local ore_stats = voxelgen.ore_veins.get_statistics()
        minetest.log("action", "[VoxelGen] Default ore veins registered successfully!")
        minetest.log("action", "[VoxelGen] Total ore veins: " .. ore_stats.total_veins)
    else
        minetest.log("error", "[VoxelGen] Failed to register default ore veins!")
    end
    
    -- Log final biome registration status
    local final_stats = voxelgen.biomes.get_statistics()
    minetest.log("action", "[VoxelGen] Biome registration complete. Final count: " .. final_stats.total_biomes)
end)

-- Load the main mapgen system after biomes are registered
local mapgen = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/mapgen.lua")
voxelgen.mapgen = mapgen

-- Load debug commands for testing
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/debug_commands.lua")

-- Register mapgen scripts for cave generation
local modpath = minetest.get_modpath(minetest.get_current_modname())
minetest.register_mapgen_script(modpath .. "/mapgen_scripts/cave_generator.lua")

-- Set up IPC data sharing for mapgen environment
local function setup_ipc_data()
    -- Share API data
    minetest.ipc_set("voxelgen:api", {
        SEA_LEVEL = voxelgen.api.SEA_LEVEL,
        MIN_CAVE_Y = voxelgen.api.MIN_CAVE_Y,
        MAX_CAVE_Y = voxelgen.api.MAX_CAVE_Y,
        noise_params = voxelgen.api.noise_params
    })
    
    -- Share cave configuration
    if voxelgen.caves and voxelgen.caves.config then
        minetest.ipc_set("voxelgen:caves_config", voxelgen.caves.config)
    end
    
    -- Share world seed when mapgen initializes
    if voxelgen.mapgen and voxelgen.mapgen.world_seed then
        minetest.ipc_set("voxelgen:world_seed", voxelgen.mapgen.world_seed)
    end
end

-- Set up IPC data after mapgen initialization
minetest.register_on_mapgen_init(function(mgparams)
    -- Ensure mapgen is initialized
    if not voxelgen.mapgen.initialized then
        voxelgen.mapgen.init()
    end
    
    -- Set up IPC data sharing
    setup_ipc_data()
    
    minetest.log("action", "[VoxelGen] IPC data shared with mapgen environment")
end)

-- Log successful loading
minetest.log("action", "[VoxelGen] Loaded successfully - The ultimate Luanti Mapgen with mapgen scripts")

-- Main API functions for external mods
-- These provide a clean interface for other mods to interact with VoxelGen
function voxelgen.register_biome(biome_def)
    -- Validate input
    if not biome_def or not biome_def.name then
        minetest.log("error", "[VoxelGen] Invalid biome definition provided to register_biome")
        return false
    end
    
    minetest.log("action", "[VoxelGen] External biome registration request: " .. biome_def.name)
    
    -- Ensure biomes system is available
    if not voxelgen.biomes then
        minetest.log("error", "[VoxelGen] Biomes system not loaded")
        return false
    end
    
    local success = voxelgen.biomes.register_biome(biome_def)
    
    if success then
        minetest.log("action", "[VoxelGen] Successfully registered external biome: " .. biome_def.name)
        
        -- Log current biome count using new system
        local stats = voxelgen.biomes.get_statistics()
        minetest.log("action", "[VoxelGen] Total registered biomes: " .. stats.total_biomes)
    else
        minetest.log("error", "[VoxelGen] Failed to register external biome: " .. biome_def.name)
    end
    
    return success
end

function voxelgen.get_biome_at(x, y, z, terrain_height)
    local temperature = voxelgen.climate.get_temperature(x, z, y, terrain_height)
    local humidity = voxelgen.climate.get_humidity(x, z, y, terrain_height)
    local terrain_class = voxelgen.api.classify_terrain(x, z, voxelgen.mapgen.world_seed or 12345)
    return voxelgen.biomes.get_biome_at(temperature, humidity, terrain_height or y, terrain_class, x, z)
end

function voxelgen.get_climate_at(x, z, y)
    return {
        temperature = voxelgen.climate.get_temperature(x, z, y, y),
        humidity = voxelgen.climate.get_humidity(x, z, y, y),
        climate_type = voxelgen.climate.get_climate_type(x, z, y, y)
    }
end

function voxelgen.get_terrain_height_at(x, z)
    if not voxelgen.mapgen.initialized then
        voxelgen.mapgen.init()
    end
    
    -- Use the new cached API function that includes erosion and rivers
    return voxelgen.api.get_terrain_height_at(x, z)
end

function voxelgen.get_heightmap_area(minp, maxp)
    if not voxelgen.mapgen.initialized then
        voxelgen.mapgen.init()
    end
    
    -- Use the new cached API function that includes erosion and rivers
    return voxelgen.api.get_heightmap_area(minp, maxp)
end

-- Helper functions for external mods
function voxelgen.create_biome_def(name, parameters, nodes, properties)
    minetest.log("action", "[VoxelGen] voxelgen.create_biome_def called with name: " .. tostring(name))
    
    -- Validate input
    if not name then
        minetest.log("error", "[VoxelGen] name is nil")
        return nil
    end
    
    if type(name) ~= "string" then
        minetest.log("error", "[VoxelGen] name must be string, got " .. type(name))
        return nil
    end
    
    -- Ensure biomes system is available
    if not voxelgen.biomes then
        minetest.log("error", "[VoxelGen] voxelgen.biomes not loaded")
        return nil
    end
    
    if not voxelgen.biomes.create_biome_def then
        minetest.log("error", "[VoxelGen] voxelgen.biomes.create_biome_def function not available")
        return nil
    end
    
    minetest.log("action", "[VoxelGen] Calling voxelgen.biomes.create_biome_def for: " .. name)
    
    local result = voxelgen.biomes.create_biome_def(name, parameters, nodes, properties)
    
    if result then
        minetest.log("action", "[VoxelGen] Successfully created biome definition for: " .. name)
    else
        minetest.log("error", "[VoxelGen] Failed to create biome definition for: " .. name)
    end
    
    return result
end

function voxelgen.get_registered_biomes()
    return voxelgen.biomes.get_registered_biomes()
end

function voxelgen.is_biome_registered(biome_name)
    local biomes = voxelgen.get_registered_biomes()
    return biomes[biome_name] ~= nil
end

-- Ore vein API functions
function voxelgen.register_ore_vein(name, definition)
    -- Validate input
    if not name or not definition then
        minetest.log("error", "[VoxelGen] Invalid ore vein definition provided to register_ore_vein")
        return false
    end
    
    minetest.log("action", "[VoxelGen] External ore vein registration request: " .. name)
    
    -- Ensure ore vein system is available
    if not voxelgen.ore_veins then
        minetest.log("error", "[VoxelGen] Ore vein system not loaded")
        return false
    end
    
    local success = voxelgen.ore_veins.register_vein(name, definition)
    
    if success then
        minetest.log("action", "[VoxelGen] Successfully registered external ore vein: " .. name)
        
        -- Log current ore vein count
        local stats = voxelgen.ore_veins.get_statistics()
        minetest.log("action", "[VoxelGen] Total registered ore veins: " .. stats.total_veins)
    else
        minetest.log("error", "[VoxelGen] Failed to register external ore vein: " .. name)
    end
    
    return success
end

function voxelgen.get_registered_ore_veins()
    return voxelgen.ore_veins.get_registered_veins()
end

function voxelgen.get_ore_vein(name)
    return voxelgen.ore_veins.get_vein(name)
end

function voxelgen.is_ore_vein_registered(vein_name)
    local veins = voxelgen.get_registered_ore_veins()
    return veins[vein_name] ~= nil
end

-- Terrain features API functions
function voxelgen.register_terrain_feature(name, definition)
    -- Validate input
    if not name or not definition then
        minetest.log("error", "[VoxelGen] Invalid terrain feature definition provided to register_terrain_feature")
        return false
    end
    
    minetest.log("action", "[VoxelGen] External terrain feature registration request: " .. name)
    
    -- Ensure terrain features system is available
    if not voxelgen.terrain_features then
        minetest.log("error", "[VoxelGen] Terrain features system not loaded")
        return false
    end
    
    local success = voxelgen.terrain_features.register_feature(name, definition)
    
    if success then
        minetest.log("action", "[VoxelGen] Successfully registered external terrain feature: " .. name)
        
        -- Log current feature count
        local stats = voxelgen.terrain_features.get_statistics()
        minetest.log("action", "[VoxelGen] Total registered terrain features: " .. stats.total_features)
    else
        minetest.log("error", "[VoxelGen] Failed to register external terrain feature: " .. name)
    end
    
    return success
end

function voxelgen.get_registered_terrain_features()
    return voxelgen.terrain_features.get_registered_features()
end

function voxelgen.get_terrain_feature_statistics()
    return voxelgen.terrain_features.get_statistics()
end

-- Configuration API
function voxelgen.configure(system, parameter, value)
    if system == "caves" then
        return voxelgen.caves.set_config(parameter:match("([^.]+)"), parameter:match("%.([^.]+)"), value)
    elseif system == "climate" then
        -- Add climate configuration if needed
        return false
    elseif system == "terrain" then
        -- Add terrain configuration if needed
        return false
    end
    return false
end

-- Performance monitoring
local chunk_count = 0
local total_time = 0

local original_generate_chunk = voxelgen.mapgen.generate_chunk
voxelgen.mapgen.generate_chunk = function(minp, maxp, blockseed)
    local start_time = minetest.get_us_time()
    original_generate_chunk(minp, maxp, blockseed)
    local end_time = minetest.get_us_time()
    
    chunk_count = chunk_count + 1
    total_time = total_time + (end_time - start_time)
    
    -- Log performance every 100 chunks
    if chunk_count % 100 == 0 then
        local avg_time = total_time / chunk_count / 1000 -- Convert to milliseconds
        minetest.log("action", string.format("[VoxelGen] Generated %d chunks, avg time: %.2fms", chunk_count, avg_time))
    end
end

-- Performance monitoring command
minetest.register_chatcommand("voxelgen_perf", {
    description = "Show VoxelGen performance statistics",
    privs = {server = true},
    func = function(name)
        if chunk_count == 0 then
            return true, "No chunks generated yet"
        end
        
        local avg_time = total_time / chunk_count / 1000 -- Convert to milliseconds
        return true, string.format(
            "VoxelGen Performance:\n" ..
            "Chunks generated: %d\n" ..
            "Total time: %.2fs\n" ..
            "Average time per chunk: %.2fms",
            chunk_count, total_time / 1000000, avg_time
        )
    end,
})

-- Reset performance stats command
minetest.register_chatcommand("voxelgen_perf_reset", {
    description = "Reset VoxelGen performance statistics",
    privs = {server = true},
    func = function(name)
        chunk_count = 0
        total_time = 0
        return true, "Performance statistics reset"
    end,
})

-- Debug command to show biome registration status
minetest.register_chatcommand("voxelgen_status", {
    description = "Show VoxelGen system status",
    func = function(name)
        local stats = voxelgen.biomes.get_statistics()
        local all_biomes = voxelgen.biomes.get_registered_biomes()
        
        local external_biomes = {}
        local default_biomes = {}
        
        for biome_name, _ in pairs(all_biomes) do 
            if biome_name:match(":") then
                table.insert(external_biomes, biome_name)
            else
                table.insert(default_biomes, biome_name)
            end
        end
        
        local integrity_ok, issues = voxelgen.biomes.registry.validate_integrity()
        
        -- Get ore vein statistics
        local ore_stats = voxelgen.ore_veins.get_statistics()
        
        local status = string.format(
            "VoxelGen System Status:\n" ..
            "System initialized: %s\n" ..
            "Mapgen initialized: %s\n" ..
            "World seed: %s\n" ..
            "Total registered biomes: %d\n" ..
            "Default biomes: %d\n" ..
            "External biomes: %d\n" ..
            "Total registered ore veins: %d\n" ..
            "Registry integrity: %s",
            tostring(voxelgen.biomes ~= nil),
            tostring(voxelgen.mapgen and voxelgen.mapgen.initialized),
            tostring(voxelgen.mapgen and voxelgen.mapgen.world_seed or "not set"),
            stats.total_biomes,
            #default_biomes,
            #external_biomes,
            ore_stats.total_veins,
            tostring(integrity_ok)
        )
        
        if #external_biomes > 0 then
            status = status .. "\nExternal biomes: " .. table.concat(external_biomes, ", ")
        end
        
        if not integrity_ok and issues then
            status = status .. "\nIntegrity Issues:"
            for _, issue in ipairs(issues) do
                status = status .. "\n- " .. issue
            end
        end
        
        return true, status
    end,
})

-- Command to show Minecraft-style parameters at current location
minetest.register_chatcommand("voxelgen_params", {
    description = "Show Minecraft-style biome parameters at current location",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        local x, y, z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
        
        local params = voxelgen.climate.get_biome_parameters(x, z, y, y)
        
        local output = string.format(
            "Minecraft-style Parameters at (%d, %d, %d):\n" ..
            "Temperature: %.3f → Level %d (%s)\n" ..
            "Humidity: %.3f → Level %d (%s)\n" ..
            "Continentalness: %.3f → %s\n" ..
            "Erosion: %.3f → Level %d (%s)\n" ..
            "Weirdness: %.3f\n" ..
            "PV: %.3f → %s\n" ..
            "Depth: %.4f",
            x, y, z,
            params.temperature, params.temperature_level,
            params.temperature_level == 0 and "Frozen" or
            params.temperature_level == 1 and "Cold" or
            params.temperature_level == 2 and "Temperate" or
            params.temperature_level == 3 and "Warm" or "Hot",
            params.humidity, params.humidity_level,
            params.humidity_level == 0 and "Arid" or
            params.humidity_level == 1 and "Dry" or
            params.humidity_level == 2 and "Neutral" or
            params.humidity_level == 3 and "Humid" or "Wet",
            params.continentalness, params.continentalness_name,
            params.erosion, params.erosion_level,
            params.erosion_level <= 2 and "Mountainous" or
            params.erosion_level <= 4 and "Hilly" or "Flat",
            params.weirdness,
            params.pv, params.pv_name,
            params.depth
        )
        
        return true, output
    end,
})

-- Command to show ore vein information
minetest.register_chatcommand("voxelgen_ores", {
    description = "Show registered ore veins information",
    func = function(name)
        local ore_stats = voxelgen.ore_veins.get_statistics()
        local all_veins = voxelgen.ore_veins.get_registered_veins()
        
        local output = string.format(
            "VoxelGen Ore Veins:\n" ..
            "Total registered veins: %d\n" ..
            "Y range: %d to %d\n",
            ore_stats.total_veins,
            ore_stats.y_range.min,
            ore_stats.y_range.max
        )
        
        -- Show count by type
        output = output .. "By type:\n"
        for vtype, count in pairs(ore_stats.by_type) do
            output = output .. string.format("  %s: %d\n", vtype, count)
        end
        
        -- List all veins
        output = output .. "Registered veins:\n"
        for vein_name, vein_def in pairs(all_veins) do
            output = output .. string.format(
                "  %s (%s): %s in %s, Y:%d-%d\n",
                vein_name,
                vein_def.vein_type,
                vein_def.ore_node,
                vein_def.wherein_node,
                vein_def.y_min,
                vein_def.y_max
            )
        end
        
        return true, output
    end,
})

-- Helper function to get noise value at position
local function get_noise_value_at(noise_name, x, z, y, world_seed)
    if not voxelgen.api.noise_objects[noise_name] then
        return nil
    end
    
    local noise_obj = voxelgen.api.noise_objects[noise_name]
    local raw_value
    
    -- Check if it's a 3D noise
    if noise_name == "density" or noise_name == "terrain_character" then
        raw_value = noise_obj:get_3d({x = x, y = y or 0, z = z})
    else
        raw_value = noise_obj:get_2d({x = x, y = z})
    end
    
    -- Apply spline mapping if available
    if voxelgen.api.splines[noise_name] then
        return voxelgen.api.spline_map(raw_value, voxelgen.api.splines[noise_name], world_seed, x, z)
    end
    
    return raw_value
end

-- Command to find nearest location with specified noise value
minetest.register_chatcommand("voxelgen_find", {
    description = "Find nearest location with specified noise value. Usage: /voxelgen_find <noise_name> <target_value> [search_radius] [tolerance]",
    params = "<noise_name> <target_value> [search_radius] [tolerance]",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        -- Parse parameters
        local args = {}
        for arg in param:gmatch("%S+") do
            table.insert(args, arg)
        end
        
        if #args < 2 then
            return false, "Usage: /voxelgen_find <noise_name> <target_value> [search_radius] [tolerance]\n" ..
                         "Available noise types: continental, erosion, peaks, jagged_mountains, mountain_ridges, " ..
                         "small_scale, density, weirdness, heat, humidity, terrain_depression, valley_direction, valley_width, terrain_character"
        end
        
        local noise_name = args[1]
        local target_value = tonumber(args[2])
        local search_radius = tonumber(args[3]) or 1000
        local tolerance = tonumber(args[4]) or 0.1
        
        if not target_value then
            return false, "Target value must be a number"
        end
        
        -- Validate noise name
        local valid_noises = {
            "continental", "erosion", "peaks", "jagged_mountains", "mountain_ridges",
            "small_scale", "density", "weirdness", "heat", "humidity", 
            "terrain_depression", "valley_direction", "valley_width", "terrain_character"
        }
        
        local is_valid = false
        for _, valid_noise in ipairs(valid_noises) do
            if noise_name == valid_noise then
                is_valid = true
                break
            end
        end
        
        if not is_valid then
            return false, "Invalid noise name. Available: " .. table.concat(valid_noises, ", ")
        end
        
        -- Initialize noise if needed
        if not voxelgen.mapgen.initialized then
            voxelgen.mapgen.init()
        end
        
        local world_seed = voxelgen.mapgen.world_seed or 12345
        local player_pos = player:get_pos()
        local start_x, start_z = math.floor(player_pos.x), math.floor(player_pos.z)
        
        -- Search in expanding squares
        local best_pos = nil
        local best_distance = math.huge
        local best_value = nil
        
        local step_size = 16 -- Check every 16 blocks for performance
        local max_radius = math.min(search_radius, 2000) -- Cap at 2000 blocks
        
        minetest.chat_send_player(name, "Searching for " .. noise_name .. " ≈ " .. target_value .. " within " .. max_radius .. " blocks...")
        
        -- Spiral search pattern
        for radius = step_size, max_radius, step_size do
            local found_in_ring = false
            
            -- Check points in a ring at this radius
            local points_to_check = math.max(8, math.floor(radius / 4))
            
            for i = 0, points_to_check - 1 do
                local angle = (i / points_to_check) * 2 * math.pi
                local check_x = start_x + math.floor(radius * math.cos(angle))
                local check_z = start_z + math.floor(radius * math.sin(angle))
                
                local noise_value = get_noise_value_at(noise_name, check_x, check_z, player_pos.y, world_seed)
                
                if noise_value then
                    local diff = math.abs(noise_value - target_value)
                    local distance = math.sqrt((check_x - start_x)^2 + (check_z - start_z)^2)
                    
                    if diff <= tolerance and distance < best_distance then
                        best_pos = {x = check_x, z = check_z}
                        best_distance = distance
                        best_value = noise_value
                        found_in_ring = true
                    end
                end
            end
            
            -- If we found something in this ring and it's close enough, stop searching
            if found_in_ring and best_distance < radius * 1.5 then
                break
            end
        end
        
        if best_pos then
            local terrain_height = voxelgen.get_terrain_height_at(best_pos.x, best_pos.z)
            
            return true, string.format(
                "Found %s = %.3f (target: %.3f) at (%d, %d, %d)\n" ..
                "Distance: %.1f blocks\n" ..
                "Use: /tp %s %d %d %d",
                noise_name, best_value, target_value,
                best_pos.x, terrain_height + 5, best_pos.z,
                best_distance,
                name, best_pos.x, terrain_height + 5, best_pos.z
            )
        else
            return true, string.format(
                "No location found with %s ≈ %.3f within %d blocks (tolerance: %.3f)",
                noise_name, target_value, max_radius, tolerance
            )
        end
    end,
})

-- Noise visualization system
local noise_visualizer = {}



-- Enhanced biome color mapping for visualization with latest VLF biomes
local biome_colors = {
    -- Ocean biomes - Various blues
    ["frozen_ocean"] = "#1E3A8A",
    ["cold_ocean"] = "#0369A1",
    ["warm_ocean"] = "#06B6D4",
    ["hot_ocean"] = "#0891B2",
    ["ocean"] = "#2563EB",
    ["deep_ocean"] = "#1D4ED8",
    
    -- Coastal biomes
    ["beach"] = "#FDE68A",
    ["stony_shore"] = "#64748B",
    
    -- Grassland biomes - Greens
    ["plains"] = "#65A30D",
    ["sunflower_plains"] = "#EAB308",
    ["temperate_grassland"] = "#84CC16",
    ["temperate_meadow"] = "#A3E635",
    
    -- Forest biomes - Various greens
    ["forest"] = "#166534",
    ["birch_forest"] = "#84CC16",
    ["dark_forest"] = "#14532D",
    ["flower_forest"] = "#EC4899",
    ["montane_forest"] = "#065F46",
    
    -- Jungle biomes - Tropical greens
    ["jungle"] = "#15803D",
    ["jungle_hills"] = "#22C55E",
    
    -- Taiga biomes - Dark greens
    ["taiga"] = "#166534",
    ["snowy_taiga"] = "#065F46",
    ["giant_tree_taiga"] = "#052E16",
    
    -- Desert biomes - Yellows and oranges
    ["desert"] = "#F59E0B",
    ["desert_hills"] = "#D97706",
    ["badlands"] = "#EA580C",
    ["eroded_badlands"] = "#DC2626",
    
    -- Savanna biomes - Warm colors
    ["savanna"] = "#CA8A04",
    ["savanna_plateau"] = "#D97706",
    
    -- Mountain biomes - Grays and browns
    ["mountains"] = "#78716C",
    ["snowy_mountains"] = "#E2E8F0",
    ["gravelly_mountains"] = "#57534E",
    
    -- Cold biomes - Cool colors
    ["snowy_tundra"] = "#F8FAFC",
    ["ice_spikes"] = "#7DD3FC",
    
    -- Swamp biomes - Dark greens
    ["swampland"] = "#14532D",
    
    -- Special biomes
    ["mushroom_fields"] = "#A855F7",
    
    -- Additional VLF biomes
    ["steppe"] = "#FEF3C7",
    ["cold_desert"] = "#B4D4F1",
    ["tundra_steppe"] = "#F3F4F6",
    
    -- Default fallback colors
    ["unknown"] = "#6B7280",
    ["default"] = "#22C55E"
}

-- Y-height tinting configuration
local y_height_tinting = {
    enabled = false,  -- Can be toggled per player
    sea_level = 0,    -- Will be set to voxelgen.api.SEA_LEVEL
    -- Tinting ranges: {min_y, max_y, tint_color, intensity}
    ranges = {
        {-64, -20, "#000080", 0.3},   -- Deep underground - blue tint
        {-20, 0, "#004080", 0.2},     -- Underground - darker blue tint
        {0, 64, "#FFFFFF", 0.0},      -- Sea level to mid - no tint
        {64, 128, "#FFFF80", 0.1},    -- Mid elevation - slight yellow tint
        {128, 192, "#FFD080", 0.2},   -- High elevation - orange tint
        {192, 320, "#FFFFFF", 0.3}    -- Very high - white tint
    }
}

-- Generate terrain height at a specific position
local function get_terrain_height_at_pos(x, z, world_seed)
    if not voxelgen.mapgen.initialized then
        voxelgen.mapgen.init()
    end
    
    -- Use the same logic as generate_heightmap but for a single point
    local cont = voxelgen.api.get_interpolated_noise_2d("continental", {x=x, y=z}, world_seed)
    local peak = voxelgen.api.get_interpolated_noise_2d("peaks", {x=x, y=z}, world_seed)
    local erosion = voxelgen.api.get_interpolated_noise_2d("erosion", {x=x, y=z}, world_seed)
    local jagged = voxelgen.api.get_interpolated_noise_2d("jagged_mountains", {x=x, y=z}, world_seed)
    local ridge = voxelgen.api.get_interpolated_noise_2d("mountain_ridges", {x=x, y=z}, world_seed)
    local weirdness = voxelgen.api.get_interpolated_noise_2d("weirdness", {x=x, y=z}, world_seed)
    
    -- Calculate peaks and valleys from weirdness
    local peaks_valleys = voxelgen.api.calculate_peaks_valleys(weirdness)
    
    local small_h_scale = voxelgen.api.fancy_interp((1 - erosion) * 0.5, 1, 5, world_seed, x, z)
    local small_h = voxelgen.api.get_interpolated_noise_2d("small_scale", {x=x, y=z}, world_seed) * small_h_scale
    
    local h_cont = voxelgen.api.spline_map(cont, voxelgen.api.splines.continentalness, world_seed, x, z)
    local h_peak = voxelgen.api.spline_map(peak, voxelgen.api.splines.peaks, world_seed, x, z)
    local h_erosion = voxelgen.api.spline_map(erosion, voxelgen.api.splines.erosion, world_seed, x, z)
    local h_jagged = voxelgen.api.spline_map(jagged, voxelgen.api.splines.jagged_mountains, world_seed, x, z)
    
    -- Apply peaks and valleys effect
    local pv_effect = peaks_valleys * 15
    
    -- Erosion effects
    local erosion_lowering = math.max(0, erosion) * 20
    local erosion_flattening = math.abs(erosion) * 0.7
    
    local jagged_influence = voxelgen.api.fancy_interp(math.max(0, (cont - 0.3) * 1.2 + (1 - math.abs(erosion)) * 0.4), 0, 1, world_seed, x, z)
    local ridge_factor = 1 - math.abs(ridge) * 0.4
    local ridge_navigability = voxelgen.api.fancy_interp(ridge_factor, 0.6, 1.2, world_seed, x, z)
    
    local jagged_contribution = h_jagged * jagged_influence * ridge_navigability * (1 - erosion_flattening)
    local base_height = h_cont + h_peak + small_h + h_erosion + jagged_contribution + pv_effect - erosion_lowering

    -- Detect plains areas and flatten them
    local is_plains = peak >= -0.15 and peak <= 0.15 and jagged <= 0.2 and cont >= 0.05
    local plains_factor = 0
    
    if is_plains then
        local peak_factor = 1 - (math.abs(peak) / 0.15)
        local jagged_factor = 1 - (jagged / 0.2)
        local cont_factor = math.min(1, (cont - 0.05) / 0.2)
        
        plains_factor = peak_factor * jagged_factor * cont_factor
        plains_factor = voxelgen.api.smoothstep(plains_factor)
    end
    
    local final_height = base_height
    
    -- Apply plains flattening
    if plains_factor > 0 then
        local plains_target = h_cont + (small_h * 0.3)
        final_height = voxelgen.api.lerp(base_height, plains_target, plains_factor)
    end
    
    -- Apply river carving (this is what was missing!)
    local river_strength, river_width = voxelgen.api.get_river_factor(x, z, world_seed)
    if river_strength > 0 then
        local river_depth = voxelgen.api.calculate_river_depth(x, z, river_strength, world_seed)
        local target_height = voxelgen.api.SEA_LEVEL - river_depth
        
        -- Only carve if the terrain is above the target river level
        if final_height > target_height then
            -- Smooth transition based on river strength
            final_height = voxelgen.api.lerp(final_height, target_height, river_strength)
        end
    end
    
    return final_height
end

-- Get biome at position for visualization
local function get_biome_at_pos(x, z, world_seed)
    if not voxelgen.mapgen.initialized then
        voxelgen.mapgen.init()
    end
    
    -- Get terrain height for biome calculation
    local terrain_height = get_terrain_height_at_pos(x, z, world_seed)
    
    -- Get biome using VoxelGen's biome system
    local biome = voxelgen.get_biome_at(x, terrain_height, z, terrain_height)
    
    if biome and biome.name then
        return biome.name
    end
    
    -- Fallback: try to determine biome from climate parameters using the same logic as the biome system
    if voxelgen.climate and voxelgen.climate.get_biome_parameters then
        local parameters = voxelgen.climate.get_biome_parameters(x, z, terrain_height, terrain_height)
        
        if parameters then
            -- Use the biome manager to find the best biome (same as the actual biome selection)
            if voxelgen.biomes and voxelgen.biomes.manager then
                local best_biome = voxelgen.biomes.manager.get_best_biome(parameters)
                if best_biome and best_biome.name then
                    return best_biome.name
                end
            end
            
            -- Simple fallback based on temperature and humidity levels
            if parameters.temperature_level == 0 then -- Frozen
                if terrain_height <= voxelgen.api.SEA_LEVEL then
                    return "frozen_ocean"
                else
                    return "snowy_taiga"
                end
            elseif parameters.temperature_level == 1 then -- Cold
                return "taiga"
            elseif parameters.temperature_level == 2 then -- Temperate
                if parameters.humidity_level >= 3 then
                    return "forest"
                else
                    return "plains"
                end
            elseif parameters.temperature_level == 3 then -- Warm
                if parameters.humidity_level >= 3 then
                    return "jungle"
                else
                    return "savanna"
                end
            else -- Hot
                return "desert"
            end
        end
    end
    
    return "unknown"
end

-- Terrain data cache for faster lookups
local terrain_cache = {}
local terrain_cache_size = 0
local max_terrain_cache_size = 10000  -- Limit cache size

local function get_cached_terrain_data(x, z, world_seed)
    local key = string.format("%d_%d_%d", x, z, world_seed)
    local cached = terrain_cache[key]
    
    if cached then
        return cached.height, cached.biome_name
    end
    
    -- Generate new data
    local height = get_terrain_height_at_pos(x, z, world_seed)
    local biome_name = get_biome_at_pos(x, z, world_seed)
    
    -- Cache the result if we haven't exceeded the limit
    if terrain_cache_size < max_terrain_cache_size then
        terrain_cache[key] = {height = height, biome_name = biome_name}
        terrain_cache_size = terrain_cache_size + 1
    end
    
    return height, biome_name
end

local function clear_terrain_cache()
    terrain_cache = {}
    terrain_cache_size = 0
    minetest.log("action", "[VoxelGen Viz] Terrain cache cleared")
end

-- Convert biome to color for visualization
-- Helper function to blend two colors
local function blend_colors(base_color, tint_color, intensity)
    if intensity <= 0 then
        return base_color
    end
    
    -- Convert hex colors to RGB
    local function hex_to_rgb(hex)
        hex = hex:gsub("#", "")
        if #hex == 6 then
            return tonumber("0x" .. hex:sub(1,2)), tonumber("0x" .. hex:sub(3,4)), tonumber("0x" .. hex:sub(5,6))
        end
        return 255, 255, 255
    end
    
    -- Convert RGB to hex
    local function rgb_to_hex(r, g, b)
        return string.format("#%02X%02X%02X", 
                           math.floor(math.min(255, math.max(0, r))),
                           math.floor(math.min(255, math.max(0, g))),
                           math.floor(math.min(255, math.max(0, b))))
    end
    
    local base_r, base_g, base_b = hex_to_rgb(base_color)
    local tint_r, tint_g, tint_b = hex_to_rgb(tint_color)
    
    -- Blend colors using linear interpolation
    local blended_r = base_r * (1 - intensity) + tint_r * intensity
    local blended_g = base_g * (1 - intensity) + tint_g * intensity
    local blended_b = base_b * (1 - intensity) + tint_b * intensity
    
    return rgb_to_hex(blended_r, blended_g, blended_b)
end

-- Get Y-height tint for a given height
local function get_y_height_tint(height)
    for _, range in ipairs(y_height_tinting.ranges) do
        local min_y, max_y, tint_color, intensity = range[1], range[2], range[3], range[4]
        if height >= min_y and height < max_y then
            return tint_color, intensity
        end
    end
    return "#FFFFFF", 0  -- No tint
end

-- Enhanced biome_to_color function with optional Y-height tinting
local function biome_to_color(biome_name, height, enable_y_tinting)
    local base_color = biome_colors[biome_name] or biome_colors["default"]
    
    if enable_y_tinting and height then
        local tint_color, intensity = get_y_height_tint(height)
        return blend_colors(base_color, tint_color, intensity)
    end
    
    return base_color
end



-- Convert height to color for visualization
local function height_to_color(height, sea_level)
    if height <= sea_level then
        -- Below sea level - blue shades (darker = deeper)
        local depth = sea_level - height
        local intensity = math.min(1, depth / 50) -- Normalize depth to 0-1 over 50 blocks
        local blue_val = math.floor(255 * (0.2 + intensity * 0.8)) -- Range from light blue to dark blue
        return string.format("#0000%02X", blue_val)
    else
        -- Above sea level - grey shades (lighter = higher)
        local elevation = height - sea_level
        local intensity = math.min(1, elevation / 100) -- Normalize elevation to 0-1 over 100 blocks
        local grey_val = math.floor(255 * (0.3 + intensity * 0.7)) -- Range from dark grey to light grey
        return string.format("#%02X%02X%02X", grey_val, grey_val, grey_val)
    end
end

-- Store player visualization state with image caching
local player_viz_state = {}

-- Image cache for efficient partial redraws
local image_cache = {}

-- Cache management functions
local function get_cache_key(player_name, center_x, center_z, radius, step, view_mode, y_tinting)
    return string.format("%s_%d_%d_%d_%d_%s_%s", player_name, center_x, center_z, radius, step, view_mode, tostring(y_tinting or false))
end

local function clear_player_cache(player_name)
    for key, _ in pairs(image_cache) do
        if key:match("^" .. player_name .. "_") then
            image_cache[key] = nil
        end
    end
end

-- Calculate overlap between two rectangular regions
local function calculate_overlap(old_center_x, old_center_z, old_radius, new_center_x, new_center_z, new_radius)
    local old_min_x, old_max_x = old_center_x - old_radius, old_center_x + old_radius
    local old_min_z, old_max_z = old_center_z - old_radius, old_center_z + old_radius
    local new_min_x, new_max_x = new_center_x - new_radius, new_center_x + new_radius
    local new_min_z, new_max_z = new_center_z - new_radius, new_center_z + new_radius
    
    -- Calculate intersection
    local overlap_min_x = math.max(old_min_x, new_min_x)
    local overlap_max_x = math.min(old_max_x, new_max_x)
    local overlap_min_z = math.max(old_min_z, new_min_z)
    local overlap_max_z = math.min(old_max_z, new_max_z)
    
    -- Check if there's actual overlap
    if overlap_min_x >= overlap_max_x or overlap_min_z >= overlap_max_z then
        return nil -- No overlap
    end
    
    return {
        min_x = overlap_min_x,
        max_x = overlap_max_x,
        min_z = overlap_min_z,
        max_z = overlap_max_z
    }
end

-- Copy overlapping region from old cache to new map data
local function copy_cached_region(old_data, old_center_x, old_center_z, old_radius, old_step,
                                 new_data, new_center_x, new_center_z, new_radius, new_step, new_size)
    if old_step ~= new_step then
        return false -- Different resolution, can't reuse
    end
    
    local overlap = calculate_overlap(old_center_x, old_center_z, old_radius, new_center_x, new_center_z, new_radius)
    if not overlap then
        return false -- No overlap
    end
    
    local old_size = math.floor(old_radius * 2 / old_step) + 1
    local copied_pixels = 0
    
    -- Copy overlapping pixels
    for new_i = 1, new_size do
        for new_j = 1, new_size do
            local world_x = new_center_x - new_radius + (new_i - 1) * new_step
            local world_z = new_center_z - new_radius + (new_j - 1) * new_step
            
            -- Check if this world position is in the overlap region
            if world_x >= overlap.min_x and world_x <= overlap.max_x and
               world_z >= overlap.min_z and world_z <= overlap.max_z then
                
                -- Calculate corresponding position in old data
                local old_i = math.floor((world_x - (old_center_x - old_radius)) / old_step) + 1
                local old_j = math.floor((world_z - (old_center_z - old_radius)) / old_step) + 1
                
                -- Verify bounds
                if old_i >= 1 and old_i <= old_size and old_j >= 1 and old_j <= old_size and
                   old_data[old_i] and old_data[old_i][old_j] then
                    new_data[new_i][new_j] = old_data[old_i][old_j]
                    copied_pixels = copied_pixels + 1
                end
            end
        end
    end
    
    return copied_pixels > 0, copied_pixels
end

-- Generate noise visualization data with caching optimization
function noise_visualizer.generate_map(center_x, center_z, radius, step, view_mode, player_name, enable_y_tinting)
    if not voxelgen.mapgen.initialized then
        voxelgen.mapgen.init()
    end
    
    view_mode = view_mode or "height"  -- Default to height view
    player_name = player_name or "unknown"
    enable_y_tinting = enable_y_tinting or false
    
    -- Initialize Y-height tinting sea level
    if y_height_tinting.sea_level == 0 then
        y_height_tinting.sea_level = voxelgen.api.SEA_LEVEL
    end
    
    local world_seed = voxelgen.mapgen.world_seed
    local sea_level = voxelgen.api.SEA_LEVEL
    local size = math.floor(radius * 2 / step) + 1
    
    -- Limit the maximum size to prevent performance issues
    local max_display_size = 2000  -- Maximum grid size for formspec display
    
    if size > max_display_size then
        size = max_display_size
        -- Adjust step to fit the desired radius within the size limit
        step = math.ceil(radius * 2 / max_display_size)
    end
    
    -- Check for cached data to reuse
    local cache_key = get_cache_key(player_name, center_x, center_z, radius, step, view_mode, enable_y_tinting)
    local cached_entry = image_cache[cache_key]
    
    if cached_entry then
        minetest.log("action", string.format("[VoxelGen Viz] Using cached %dx%d %s map", size, size, view_mode))
        return cached_entry.map_data, size
    end
    
    -- Initialize map data
    local map_data = {}
    for i = 1, size do
        map_data[i] = {}
    end
    
    -- Try to find overlapping cached data to reuse
    local copied_pixels = 0
    local reused_cache = false
    
    for old_key, old_entry in pairs(image_cache) do
        if old_key:match("^" .. player_name .. "_") and old_entry.view_mode == view_mode then
            local success, pixels = copy_cached_region(
                old_entry.map_data, old_entry.center_x, old_entry.center_z, old_entry.radius, old_entry.step,
                map_data, center_x, center_z, radius, step, size
            )
            if success then
                copied_pixels = copied_pixels + pixels
                reused_cache = true
            end
        end
    end
    
    if reused_cache then
        minetest.log("action", string.format("[VoxelGen Viz] Reused %d pixels from cache for %s map", copied_pixels, view_mode))
    end
    
    -- Generate only the missing pixels with batch processing for better performance
    local total_points = size * size
    local processed = 0
    local generated = 0
    local last_progress = 0
    local batch_size = 100  -- Process in batches to reduce overhead
    
    minetest.log("action", string.format("[VoxelGen Viz] Generating %dx%d %s map (step: %d, radius: %d, cached: %d)", 
                                        size, size, view_mode, step, radius, copied_pixels))
    
    -- Pre-calculate positions and batch process
    local positions_to_generate = {}
    for i = 1, size do
        for j = 1, size do
            if not map_data[i][j] then
                local x = center_x - radius + (i - 1) * step
                local z = center_z - radius + (j - 1) * step
                table.insert(positions_to_generate, {i, j, x, z})
            end
        end
    end
    
    -- Process in batches for better performance
    for batch_start = 1, #positions_to_generate, batch_size do
        local batch_end = math.min(batch_start + batch_size - 1, #positions_to_generate)
        
        for idx = batch_start, batch_end do
            local pos_data = positions_to_generate[idx]
            local i, j, x, z = pos_data[1], pos_data[2], pos_data[3], pos_data[4]
            
            local height, biome_name = get_cached_terrain_data(x, z, world_seed)
            local color
            
            if view_mode == "biome" then
                -- Biome view: color based on biome type with optional Y-height tinting
                color = biome_to_color(biome_name, height, enable_y_tinting)
            else
                -- Height view: color based on terrain height
                -- Check if this is a river for special coloring
                local river_info = voxelgen.api.get_river_info_at(x, z, world_seed)
                
                if river_info.is_river then
                    -- Rivers get a distinct cyan/turquoise color
                    color = "#00CCCCFF"
                elseif river_info.is_riverbank then
                    -- Riverbanks get a darker cyan
                    color = "#008888FF"
                else
                    -- Normal terrain coloring
                    color = height_to_color(height, sea_level)
                end
                
                -- Apply Y-height tinting to height view as well if enabled
                if enable_y_tinting then
                    local tint_color, intensity = get_y_height_tint(height)
                    color = blend_colors(color, tint_color, intensity)
                end
            end
            
            map_data[i][j] = {
                height = height,
                biome = biome_name,
                color = color,
                x = x,
                z = z,
                is_river = river_info and river_info.is_river or false,
                is_riverbank = river_info and river_info.is_riverbank or false
            }
            
            generated = generated + 1
            processed = processed + 1
        end
        
        -- Log progress for large batches
        if #positions_to_generate > 1000 then
            local progress = math.floor((batch_end / #positions_to_generate) * 100)
            if progress % 20 == 0 then  -- Log every 20%
                minetest.log("action", string.format("[VoxelGen Viz] Progress: %d%% (%d/%d points)", 
                                                    progress, batch_end, #positions_to_generate))
            end
        end
    end
    
    -- Cache the result
    image_cache[cache_key] = {
        map_data = map_data,
        center_x = center_x,
        center_z = center_z,
        radius = radius,
        step = step,
        view_mode = view_mode,
        y_tinting = enable_y_tinting,
        timestamp = os.time()
    }
    
    -- Limit cache size (keep only the 5 most recent entries per player)
    local player_cache_keys = {}
    for key, entry in pairs(image_cache) do
        if key:match("^" .. player_name .. "_") then
            table.insert(player_cache_keys, {key = key, timestamp = entry.timestamp})
        end
    end
    
    if #player_cache_keys > 5 then
        table.sort(player_cache_keys, function(a, b) return a.timestamp > b.timestamp end)
        for i = 6, #player_cache_keys do
            image_cache[player_cache_keys[i].key] = nil
        end
    end
    
    minetest.log("action", string.format("[VoxelGen Viz] Map generation complete: %d total points, %d generated, %d cached", 
                                        total_points, generated, copied_pixels))
    
    return map_data, size
end

-- Helper function to convert hex color to RGB values
local function hex_to_rgb(hex)
    hex = hex:gsub("#", "")
    if #hex == 6 then
        return tonumber("0x" .. hex:sub(1,2)), tonumber("0x" .. hex:sub(3,4)), tonumber("0x" .. hex:sub(5,6)), 255
    elseif #hex == 8 then
        return tonumber("0x" .. hex:sub(1,2)), tonumber("0x" .. hex:sub(3,4)), tonumber("0x" .. hex:sub(5,6)), tonumber("0x" .. hex:sub(7,8))
    end
    return 255, 255, 255, 255  -- Default to white
end

-- Generate PNG texture from map data
local function generate_png_texture(map_data, size)
    local pixel_data = {}
    
    for j = 1, size do
        for i = 1, size do
            local data = map_data[i][j]
            local r, g, b, a = hex_to_rgb(data.color)
            table.insert(pixel_data, {r = r, g = g, b = b, a = a})
        end
    end
    
    -- Generate PNG and encode to base64
    local png_data = core.encode_png(size, size, pixel_data, 9)  -- Max compression
    local base64_data = core.encode_base64(png_data)
    
    return base64_data
end

-- Generate vertical biome legend as PNG
local function generate_biome_legend_png()
    -- Define VLF biomes in display order with their colors and display names
    local legend_biomes = {
        -- Ocean biomes
        {"Frozen Ocean", "frozen_ocean", "#1E3A8A"},
        {"Cold Ocean", "cold_ocean", "#0369A1"},
        {"Warm Ocean", "warm_ocean", "#06B6D4"},
        {"Hot Ocean", "hot_ocean", "#0891B2"},
        
        -- Coastal biomes
        {"Beach", "beach", "#FDE68A"},
        {"Stony Shore", "stony_shore", "#64748B"},
        
        -- Grassland biomes
        {"Plains", "plains", "#65A30D"},
        {"Sunflower Plains", "sunflower_plains", "#EAB308"},
        {"Temperate Grassland", "temperate_grassland", "#84CC16"},
        {"Temperate Meadow", "temperate_meadow", "#A3E635"},
        
        -- Forest biomes
        {"Forest", "forest", "#166534"},
        {"Birch Forest", "birch_forest", "#84CC16"},
        {"Dark Forest", "dark_forest", "#14532D"},
        {"Flower Forest", "flower_forest", "#EC4899"},
        {"Montane Forest", "montane_forest", "#065F46"},
        
        -- Jungle biomes
        {"Jungle", "jungle", "#15803D"},
        {"Jungle Hills", "jungle_hills", "#22C55E"},
        
        -- Taiga biomes
        {"Taiga", "taiga", "#166534"},
        {"Snowy Taiga", "snowy_taiga", "#065F46"},
        {"Giant Tree Taiga", "giant_tree_taiga", "#052E16"},
        
        -- Desert biomes
        {"Desert", "desert", "#F59E0B"},
        {"Desert Hills", "desert_hills", "#D97706"},
        {"Badlands", "badlands", "#EA580C"},
        {"Eroded Badlands", "eroded_badlands", "#DC2626"},
        
        -- Savanna biomes
        {"Savanna", "savanna", "#CA8A04"},
        {"Savanna Plateau", "savanna_plateau", "#D97706"},
        
        -- Mountain biomes
        {"Mountains", "mountains", "#78716C"},
        {"Snowy Mountains", "snowy_mountains", "#E2E8F0"},
        {"Gravelly Mountains", "gravelly_mountains", "#57534E"},
        
        -- Cold biomes
        {"Snowy Tundra", "snowy_tundra", "#F8FAFC"},
        {"Ice Spikes", "ice_spikes", "#7DD3FC"},
        
        -- Swamp biomes
        {"Swampland", "swampland", "#14532D"},
        
        -- Special biomes
        {"Mushroom Fields", "mushroom_fields", "#A855F7"},
        {"Steppe", "steppe", "#FEF3C7"},
        {"Cold Desert", "cold_desert", "#B4D4F1"},
        {"Tundra Steppe", "tundra_steppe", "#F3F4F6"}
    }
    
    -- Legend dimensions
    local legend_width = 200  -- Width in pixels
    local legend_height = #legend_biomes * 16  -- 16 pixels per biome entry
    local color_box_size = 12  -- Size of color squares
    local color_box_margin = 2  -- Margin around color boxes
    
    -- Create pixel data array for PNG generation
    local pixel_data = {}
    
    -- Helper function to convert hex color to RGB
    local function hex_to_rgb(hex)
        hex = hex:gsub("#", "")
        if #hex == 6 then
            return tonumber("0x" .. hex:sub(1,2)), tonumber("0x" .. hex:sub(3,4)), tonumber("0x" .. hex:sub(5,6))
        end
        return 255, 255, 255  -- Default to white
    end
    
    -- Initialize background (light gray)
    for y = 1, legend_height do
        for x = 1, legend_width do
            table.insert(pixel_data, {r = 248, g = 250, b = 252, a = 255})  -- Very light gray background
        end
    end
    
    -- Helper function to set pixel color
    local function set_pixel(x, y, r, g, b, a)
        if x >= 1 and x <= legend_width and y >= 1 and y <= legend_height then
            local index = (y - 1) * legend_width + x
            pixel_data[index] = {r = r, g = g, b = b, a = a or 255}
        end
    end
    
    -- Draw each biome entry
    for i, biome_info in ipairs(legend_biomes) do
        local display_name, biome_key, color_hex = biome_info[1], biome_info[2], biome_info[3]
        local y_offset = (i - 1) * 16 + 1  -- 1-based indexing
        local r, g, b = hex_to_rgb(color_hex)
        
        -- Draw color box (12x12 pixels with 2 pixel margin)
        for box_y = 0, color_box_size - 1 do
            for box_x = 0, color_box_size - 1 do
                set_pixel(color_box_margin + 1 + box_x, y_offset + color_box_margin + box_y, r, g, b, 255)
            end
        end
        
        -- Draw border around color box (black)
        for box_x = 0, color_box_size + 1 do
            set_pixel(color_box_margin + box_x, y_offset + color_box_margin - 1, 0, 0, 0, 255)  -- Top
            set_pixel(color_box_margin + box_x, y_offset + color_box_margin + color_box_size, 0, 0, 0, 255)  -- Bottom
        end
        for box_y = 0, color_box_size + 1 do
            set_pixel(color_box_margin, y_offset + color_box_margin - 1 + box_y, 0, 0, 0, 255)  -- Left
            set_pixel(color_box_margin + color_box_size + 1, y_offset + color_box_margin - 1 + box_y, 0, 0, 0, 255)  -- Right
        end
    end
    
    -- Generate PNG and encode to base64
    local png_data = core.encode_png(legend_width, legend_height, pixel_data, 9)  -- Max compression
    local base64_data = core.encode_base64(png_data)
    
    return base64_data, legend_biomes
end

-- Create formspec for noise visualization
function noise_visualizer.create_formspec(player_name, center_x, center_z, radius, step, view_mode, enable_y_tinting)
    view_mode = view_mode or "height"  -- Default to height view
    enable_y_tinting = enable_y_tinting or false
    local map_data, size = noise_visualizer.generate_map(center_x, center_z, radius, step, view_mode, player_name, enable_y_tinting)
    
    -- Get player position for display
    local player = minetest.get_player_by_name(player_name)
    local player_pos = player and player:get_pos() or {x = 0, z = 0}
    local player_x, player_z = math.floor(player_pos.x), math.floor(player_pos.z)
    
    -- Even larger UI sizing for better visibility
    local base_size = 24  -- Further increased base size
    local formspec_size = math.min(32, math.max(20, base_size))  -- Much larger range
    
    -- Generate PNG texture for the map
    local texture_data = generate_png_texture(map_data, size)
    local texture_string = "[png:" .. texture_data
    
    -- Create title and legend based on view mode
    local title, legend
    if view_mode == "biome" then
        title = string.format("Biome Visualization - Center: (%d, %d)", center_x, center_z)
        legend = "Enhanced biome colors with VLF biomes" .. (enable_y_tinting and " + Y-height tinting" or "")
    else
        title = string.format("Terrain Height Visualization - Center: (%d, %d)", center_x, center_z)
        legend = "Blue = Below Sea Level, Grey = Above Sea Level, Cyan = Rivers, Dark Cyan = Riverbanks" .. (enable_y_tinting and " + Y-height tinting" or "")
    end
    
    -- Generate biome legend PNG if in biome view
    local legend_texture, legend_biomes = "", {}
    if view_mode == "biome" then
        legend_texture, legend_biomes = generate_biome_legend_png()
    end
    
    -- Calculate layout for larger UI with legend
    local legend_width = view_mode == "biome" and 8 or 0  -- Space for legend
    local total_width = formspec_size + legend_width + 6  -- Map + legend + padding
    local total_height = formspec_size + 10  -- Increased height for larger UI
    
    local formspec = {
        "formspec_version[4]",
        string.format("size[%g,%g]", total_width, total_height),
        "bgcolor[#1F2937FF]",  -- Darker background for better contrast
        -- Main title
        string.format("label[0.5,0.5;%s]", title),
        string.format("label[0.5,1;Player: (%d, %d) | Radius: %d | Step: %d | Sea Level: %d]", player_x, player_z, radius, step, voxelgen.api.SEA_LEVEL),
        string.format("label[0.5,1.5;%s]", legend),
        -- View mode toggle buttons with better styling
        string.format("button[0.5,2.2;2.5,0.8;toggle_height;%s Height View]", view_mode == "height" and "●" or "○"),
        string.format("button[3.2,2.2;2.5,0.8;toggle_biome;%s Biome View]", view_mode == "biome" and "●" or "○"),
        string.format("button[6.0,2.2;2.5,0.8;toggle_y_tinting;%s Y-Height Tint]", enable_y_tinting and "●" or "○"),
        -- Main map display using PNG texture (clickable)
        string.format("image_button[2,3.5;%g,%g;%s;map_click;;false;false]", formspec_size, formspec_size, texture_string)
    }
    
    -- Add vertical biome legend if in biome view
    if view_mode == "biome" and legend_texture ~= "" then
        local legend_x = formspec_size + 3  -- Position legend to the right of the map
        local legend_y = 3.5  -- Align with map
        local legend_display_width = 6  -- Width in formspec units
        local legend_display_height = formspec_size * 0.8  -- Height proportional to map
        
        -- Add legend PNG image
        table.insert(formspec, string.format("image[%g,%g;%g,%g;[png:%s]", 
                                           legend_x, legend_y, legend_display_width, legend_display_height, legend_texture))
        
        -- Add legend title
        table.insert(formspec, string.format("label[%g,%g;Biome Legend:]", legend_x, legend_y - 0.5))
        
        -- Add text labels aligned with the PNG legend
        local legend_item_height = legend_display_height / #legend_biomes
        for i, biome_info in ipairs(legend_biomes) do
            local display_name = biome_info[1]
            local label_y = legend_y + (i - 0.5) * legend_item_height - 0.1  -- Center text with color box
            table.insert(formspec, string.format("label[%g,%g;%s]", legend_x + 1.5, label_y, display_name))
        end
    end
    
    -- Add player position marker if player is within the visible area
    local player_rel_x = player_x - (center_x - radius)
    local player_rel_z = player_z - (center_z - radius)
    
    if player_rel_x >= 0 and player_rel_x < radius * 2 and player_rel_z >= 0 and player_rel_z < radius * 2 then
        local player_grid_x = math.floor(player_rel_x / step) + 1
        local player_grid_z = math.floor(player_rel_z / step) + 1
        
        if player_grid_x >= 1 and player_grid_x <= size and player_grid_z >= 1 and player_grid_z <= size then
            -- Calculate marker position on the image
            local marker_x = 2 + (player_grid_x - 1) * (formspec_size / size)
            local marker_z = 3.5 + (player_grid_z - 1) * (formspec_size / size)
            
            -- Add a bright red cross marker for player position
            local marker_size = math.max(0.1, formspec_size / size * 2)  -- Scale with zoom
            table.insert(formspec, string.format(
                "box[%g,%g;%g,%g;#FF0000FF]",
                marker_x - marker_size/2, marker_z - marker_size/10, marker_size, marker_size/5
            ))
            table.insert(formspec, string.format(
                "box[%g,%g;%g,%g;#FF0000FF]",
                marker_x - marker_size/10, marker_z - marker_size/2, marker_size/5, marker_size
            ))
        end
    end
    

    
    -- Add scrolling controls with better positioning for larger UI
    local controls_y = formspec_size + 4.0
    table.insert(formspec, string.format("button[0.5,%g;2.5,0.8;scroll_up;↑ North]", controls_y))
    table.insert(formspec, string.format("button[3.2,%g;2.5,0.8;scroll_down;↓ South]", controls_y))
    table.insert(formspec, string.format("button[5.9,%g;2.5,0.8;scroll_left;← West]", controls_y))
    table.insert(formspec, string.format("button[8.6,%g;2.5,0.8;scroll_right;→ East]", controls_y))
    
    -- Add control buttons with improved spacing
    local buttons_y = controls_y + 1.0
    table.insert(formspec, string.format("button[0.5,%g;2.5,0.8;refresh;Refresh]", buttons_y))
    table.insert(formspec, string.format("button[3.2,%g;2.5,0.8;zoom_in;Zoom In]", buttons_y))
    table.insert(formspec, string.format("button[5.9,%g;2.5,0.8;zoom_out;Zoom Out]", buttons_y))
    table.insert(formspec, string.format("button[8.6,%g;2.5,0.8;close;Close]", buttons_y))
    
    -- Add preset zoom levels with improved layout for larger UI
    local presets_y = buttons_y + 1.0
    table.insert(formspec, string.format("button[0.5,%g;3.5,0.8;zoom_detail;Detail View (1:1)]", presets_y))
    table.insert(formspec, string.format("button[4.2,%g;3.5,0.8;zoom_world;World View (1:2)]", presets_y))
    table.insert(formspec, string.format("button[7.9,%g;3.5,0.8;zoom_local;Local View (1:2)]", presets_y))
    
    -- Add click information display and teleport functionality
    local info_y = presets_y + 1.0
    local state = player_viz_state[player_name]
    if state and state.clicked_pos then
        local clicked_x, clicked_z = state.clicked_pos.x, state.clicked_pos.z
        local clicked_height = state.clicked_pos.height or "Unknown"
        local clicked_biome = state.clicked_pos.biome or "Unknown"
        
        table.insert(formspec, string.format("label[0.5,%g;Clicked Position: (%d, %d) | Height: %s | Biome: %s]", 
                                           info_y, clicked_x, clicked_z, clicked_height, clicked_biome))
        table.insert(formspec, string.format("button[0.5,%g;3,0.8;teleport;Teleport to (%d, %d)]", 
                                           info_y + 0.5, clicked_x, clicked_z))
    else
        table.insert(formspec, string.format("label[0.5,%g;Click on the map to see position information and teleport]", info_y))
    end
    
    return table.concat(formspec, "")
end



-- Handle formspec input
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "voxelgen:noise_viz" then
        return
    end
    
    local player_name = player:get_player_name()
    local state = player_viz_state[player_name]
    
    if not state then
        return
    end
    
    -- Ensure view_mode and y_tinting are set (for backward compatibility)
    if not state.view_mode then
        state.view_mode = "height"
    end
    if state.enable_y_tinting == nil then
        state.enable_y_tinting = false
    end
    
    if fields.toggle_height then
        -- Switch to height view
        state.view_mode = "height"
        local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
        minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
    elseif fields.toggle_biome then
        -- Switch to biome view
        state.view_mode = "biome"
        local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
        minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
    elseif fields.toggle_y_tinting then
        -- Toggle Y-height tinting
        state.enable_y_tinting = not state.enable_y_tinting
        local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
        minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
    elseif fields.refresh then
        local pos = player:get_pos()
        state.center_x = math.floor(pos.x)
        state.center_z = math.floor(pos.z)
        local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
        minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
    elseif fields.scroll_up then
        -- Scroll north (negative Z direction)
        local scroll_distance = math.max(state.radius / 4, state.step * 10)
        state.center_z = state.center_z - scroll_distance
        local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
        minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
    elseif fields.scroll_down then
        -- Scroll south (positive Z direction)
        local scroll_distance = math.max(state.radius / 4, state.step * 10)
        state.center_z = state.center_z + scroll_distance
        local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
        minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
    elseif fields.scroll_left then
        -- Scroll west (negative X direction)
        local scroll_distance = math.max(state.radius / 4, state.step * 10)
        state.center_x = state.center_x - scroll_distance
        local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
        minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
    elseif fields.scroll_right then
        -- Scroll east (positive X direction)
        local scroll_distance = math.max(state.radius / 4, state.step * 10)
        state.center_x = state.center_x + scroll_distance
        local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
        minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
    elseif fields.zoom_in then
        -- Zoom in: reduce radius and step
        state.radius = math.max(50, state.radius / 2)
        state.step = math.max(1, state.step / 2)
        local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
        minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
    elseif fields.zoom_out then
        -- Zoom out: increase radius and step (max radius 1000)
        state.radius = math.min(1000, state.radius * 2)
        state.step = math.min(10, state.step * 2)
        local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
        minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
    elseif fields.zoom_detail then
        -- Detail view: High resolution 1:1 mapping
        state.radius = 250
        state.step = 1
        local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
        minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
    elseif fields.zoom_world then
        -- World view: Large area with lower resolution
        state.radius = 1000
        state.step = 2
        local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
        minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
    elseif fields.zoom_local then
        -- Local view: Medium area with good detail
        state.radius = 500
        state.step = 2
        local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
        minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
    elseif fields.map_click then
        -- Handle map click to show position information
        local click_x, click_y = fields.map_click:match("([%d%.%-]+):([%d%.%-]+)")
        if click_x and click_y then
            click_x, click_y = tonumber(click_x), tonumber(click_y)
            
            -- Convert formspec coordinates to world coordinates
            local formspec_size = math.min(32, math.max(20, 24))  -- Same as in create_formspec
            local size = math.floor(state.radius * 2 / state.step) + 1
            local max_display_size = 2000
            if size > max_display_size then
                size = max_display_size
            end
            
            -- Calculate world position from click coordinates
            local grid_x = math.floor((click_x / formspec_size) * size) + 1
            local grid_z = math.floor((click_y / formspec_size) * size) + 1
            
            if grid_x >= 1 and grid_x <= size and grid_z >= 1 and grid_z <= size then
                local world_x = state.center_x - state.radius + (grid_x - 1) * state.step
                local world_z = state.center_z - state.radius + (grid_z - 1) * state.step
                
                -- Get terrain information at clicked position
                local height = voxelgen.get_terrain_height_at(world_x, world_z)
                local biome_info = voxelgen.get_biome_at(world_x, height, world_z, height)
                local biome_name = biome_info and biome_info.name or "Unknown"
                
                -- Store clicked position information
                state.clicked_pos = {
                    x = world_x,
                    z = world_z,
                    height = height,
                    biome = biome_name
                }
                
                -- Refresh formspec to show clicked position info
                local formspec = noise_visualizer.create_formspec(player_name, state.center_x, state.center_z, state.radius, state.step, state.view_mode, state.enable_y_tinting)
                minetest.show_formspec(player_name, "voxelgen:noise_viz", formspec)
            end
        end
    elseif fields.teleport then
        -- Handle teleport to clicked position
        if state.clicked_pos then
            local teleport_x = state.clicked_pos.x
            local teleport_z = state.clicked_pos.z
            local teleport_y = state.clicked_pos.height + 2  -- Teleport 2 blocks above terrain
            
            player:set_pos({x = teleport_x, y = teleport_y, z = teleport_z})
            minetest.chat_send_player(player_name, string.format("Teleported to (%d, %d, %d)", teleport_x, teleport_y, teleport_z))
            
            -- Close the formspec after teleporting
            player_viz_state[player_name] = nil
            clear_player_cache(player_name)
        end
    elseif fields.close or fields.quit then
        player_viz_state[player_name] = nil
        -- Clear cache when closing to free memory
        clear_player_cache(player_name)
    end
end)

-- Clean up cache when players leave
minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    player_viz_state[player_name] = nil
    clear_player_cache(player_name)
    minetest.log("action", string.format("[VoxelGen Viz] Cleaned up cache for player %s", player_name))
end)

-- Chat command to open noise visualization
minetest.register_chatcommand("voxelgen_viz", {
    description = "Open terrain noise visualization formspec",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        local center_x = math.floor(pos.x)
        local center_z = math.floor(pos.z)
        local radius = 500  -- Default radius
        local step = 10     -- Default step (point per 10 blocks)
        
        -- Store player state
        player_viz_state[name] = {
            center_x = center_x,
            center_z = center_z,
            radius = radius,
            step = step,
            view_mode = "height",  -- Default to height view
            enable_y_tinting = false  -- Default Y-height tinting off
        }
        
        local formspec = noise_visualizer.create_formspec(name, center_x, center_z, radius, step, "height", false)
        minetest.show_formspec(name, "voxelgen:noise_viz", formspec)
        
        return true, "Opening terrain visualization..."
    end,
})

-- Debug command to show cache statistics
minetest.register_chatcommand("voxelgen_cache", {
    description = "Show VoxelGen visualizer cache statistics",
    privs = {server = true},
    func = function(name)
        local total_entries = 0
        local player_counts = {}
        local total_pixels = 0
        
        for key, entry in pairs(image_cache) do
            total_entries = total_entries + 1
            local player_name = key:match("^([^_]+)_")
            if player_name then
                player_counts[player_name] = (player_counts[player_name] or 0) + 1
            end
            
            -- Estimate pixel count
            if entry.map_data then
                local size = #entry.map_data
                total_pixels = total_pixels + (size * size)
            end
        end
        
        local result = {
            string.format("VoxelGen Visualizer Cache Statistics:"),
            string.format("Image cache entries: %d", total_entries),
            string.format("Estimated cached pixels: %d", total_pixels),
            string.format("Image cache memory estimate: %.2f MB", total_pixels * 32 / 1024 / 1024), -- Rough estimate
            "",
            string.format("Terrain cache entries: %d", terrain_cache_size),
            string.format("Terrain cache memory estimate: %.2f KB", terrain_cache_size * 64 / 1024), -- Rough estimate
            ""
        }
        
        if next(player_counts) then
            table.insert(result, "Per-player cache entries:")
            for player_name, count in pairs(player_counts) do
                table.insert(result, string.format("  %s: %d entries", player_name, count))
            end
        else
            table.insert(result, "No cached data found")
        end
        
        return true, table.concat(result, "\n")
    end,
})

-- Command to clear terrain cache
minetest.register_chatcommand("voxelgen_clear_cache", {
    description = "Clear VoxelGen terrain cache to free memory",
    privs = {server = true},
    func = function(name)
        clear_terrain_cache()
        return true, "VoxelGen terrain cache cleared successfully"
    end,
})
