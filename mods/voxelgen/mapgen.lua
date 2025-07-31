-- mapgen.lua - Main mapgen coordination for VoxelGen
-- Orchestrates terrain generation, climate, and biomes
-- Cave generation is now handled by mapgen scripts

local mapgen = {}

-- Load API modules
local modpath = minetest.get_modpath("voxelgen") or minetest.get_modpath(minetest.get_current_modname and minetest.get_current_modname() or "voxelgen")
local api = dofile(modpath .. "/api.lua")
local climate = dofile(modpath .. "/climate.lua")
local nodes = dofile(modpath .. "/nodes.lua")
local ore_veins = dofile(modpath .. "/ore_veins.lua")
-- Use the shared terrain_features instance from voxelgen
local terrain_features = voxelgen.terrain_features
-- Use the biomes system from the main voxelgen global
local biomes = voxelgen.biomes
-- Note: caves are now handled by mapgen scripts, not loaded here

-- Mapgen state
mapgen.initialized = false
mapgen.world_seed = nil

-- Content IDs
local c_air, c_stone, c_water

-- Initialize the mapgen system
function mapgen.init()
    if mapgen.initialized then
        return
    end
    
    -- Get world seed
    mapgen.world_seed = minetest.get_mapgen_setting("seed")
    
    -- Initialize node system
    nodes.init()
    
    -- Initialize content IDs using node system
    c_air = minetest.get_content_id("air")
    c_stone = nodes.get_content_id("stone")
    c_water = nodes.get_content_id("water_source")
    
    -- Initialize subsystems
    api.init_noise(mapgen.world_seed)
    climate.init(mapgen.world_seed)
    ore_veins.init(api)
    terrain_features.init(mapgen.world_seed)
    -- Note: caves are now initialized in mapgen scripts
    
    mapgen.initialized = true
    minetest.log("action", "[VoxelGen] Mapgen system initialized with seed: " .. mapgen.world_seed)
end

-- Generate base terrain using the API
function mapgen.generate_terrain(minp, maxp, data, area)
    local heightmap, jagged_mask = api.generate_heightmap(minp, maxp, mapgen.world_seed)
    local size_x = maxp.x - minp.x + 1
    local size_z = maxp.z - minp.z + 1
    
    -- Balanced erosion to avoid grid artifacts
    api.thermal_erosion_selective(heightmap, jagged_mask, size_x, size_z, 6, 2.8)
    api.hydraulic_erosion(heightmap, size_x, size_z, 15)
    
    -- Rivers are now carved directly in generate_heightmap
    
    -- Generate base terrain with enhanced 3D density variation
    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            local idx = (z - minp.z) * size_x + (x - minp.x + 1)
            local terrain_height = math.floor(heightmap[idx])
            
            -- Check if this position is in a river for proper water placement
            local river_info = api.get_river_info_at(x, z, mapgen.world_seed)
            local is_in_river = river_info.is_river
            local river_water_level = api.SEA_LEVEL -- Default water level for rivers
            
            -- Check if we're in an ocean area (continentalness < -0.2)
            local cont = api.get_interpolated_noise_2d("continental", {x=x, y=z}, mapgen.world_seed)
            local is_ocean = cont < -0.2
            
            -- If in a river AND not in an ocean, calculate the appropriate river water level
            if is_in_river and not is_ocean then
                river_water_level = api.calculate_river_water_level(x, z, river_info.strength, mapgen.world_seed)
            else
                -- In oceans or non-river areas, use sea level
                is_in_river = false -- Override river detection in ocean areas
            end
            
            for y = minp.y, maxp.y do
                local vi = area:index(x, y, z)
                
                -- Enhanced 3D density noise for better terrain variation
                local density_val = api.noise_objects.density:get_3d({x = x, y = y, z = z})
                
                -- Add enhanced 3D terrain character noise for more natural variation
                local character_val = api.get_terrain_character_3d(x, y, z)
                
                -- Height-based density scaling for more realistic terrain
                local height_factor = math.max(0.3, 1 - (y - terrain_height) / 20)
                local density_scale = 2.8 * height_factor  -- Reduced and height-dependent
                local character_scale = 1.0 * height_factor  -- Reduced and height-dependent
                
                -- Combine density variations with improved scaling
                local local_terrain = terrain_height + density_val * density_scale + character_val * character_scale
                
                -- Prevent 1-block air gaps by ensuring continuity in terrain
                -- If this would create a gap (air surrounded by stone), fill it
                local should_be_stone = y <= local_terrain
                
                if not should_be_stone and y <= terrain_height + 2 then
                    -- Enhanced gap prevention with improved scaling
                    local below_y = y - 1
                    if below_y >= minp.y then
                        local below_density = api.noise_objects.density:get_3d({x = x, y = below_y, z = z})
                        local below_character = api.get_terrain_character_3d(x, below_y, z)
                        local below_height_factor = math.max(0.3, 1 - (below_y - terrain_height) / 20)
                        local below_terrain = terrain_height + below_density * (2.8 * below_height_factor) + below_character * (1.0 * below_height_factor)
                        
                        -- If the block below would be stone, fill this gap to prevent thin air layers
                        if below_y <= below_terrain then
                            should_be_stone = true
                        end
                    end
                end
                
                if should_be_stone then
                    data[vi] = c_stone
                else
                    -- Enhanced water placement logic - always ensure water at sea level or below
                    local water_level = api.SEA_LEVEL  -- Default to sea level
                    
                    if is_in_river then
                        -- In rivers, use the higher of river water level or sea level
                        water_level = math.max(river_water_level, api.SEA_LEVEL)
                    end
                    
                    -- Always place water at or below the determined water level
                    data[vi] = (y <= water_level) and c_water or c_air
                end
            end
        end
    end
    
    return heightmap
end

-- Generate climate maps
function mapgen.generate_climate(minp, maxp, heightmap)
    return climate.generate_maps(minp, maxp, heightmap)
end

-- Generate biome assignments
function mapgen.generate_biomes(minp, maxp, temperature_map, humidity_map, heightmap)
    return biomes.generate_biome_map(minp, maxp, temperature_map, humidity_map, heightmap, mapgen.world_seed)
end

-- Apply biome-specific terrain modifications
function mapgen.apply_biomes(data, area, minp, maxp, biome_map, heightmap)
    biomes.apply_terrain_nodes(data, area, minp, maxp, biome_map, heightmap)
end

-- Check if caves were generated (now handled by mapgen script)
function mapgen.check_caves_generated()
    -- Caves are now generated by the mapgen script
    -- We check the result via IPC
    local caves_generated = minetest.ipc_get("voxelgen:caves_generated")
    return caves_generated or false
end

-- Apply biomes to cave floors and exposed areas
function mapgen.apply_biomes_to_caves(data, area, minp, maxp, biome_map, heightmap)
    biomes.apply_to_cave_floors(data, area, minp, maxp, biome_map, heightmap)
end



-- Main mapgen function
function mapgen.generate_chunk(minp, maxp, blockseed)
    -- Initialize if needed
    if not mapgen.initialized then
        mapgen.init()
    end
    
    -- Get voxel manipulator
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()
    
    -- Step 1: Generate base terrain with enhanced 3D character
    local heightmap = mapgen.generate_terrain(minp, maxp, data, area)
    
    -- Cache the final heightmap for HUD access
    api.cache_heightmap(minp, maxp, heightmap)
    
    -- Step 2: Generate climate data
    local temperature_map, humidity_map, climate_map = mapgen.generate_climate(minp, maxp, heightmap)
    
    -- Step 3: Determine biomes based on climate and terrain
    local biome_map = mapgen.generate_biomes(minp, maxp, temperature_map, humidity_map, heightmap)
    

    
    -- Step 4: Apply biome-specific terrain modifications
    mapgen.apply_biomes(data, area, minp, maxp, biome_map, heightmap)
    
    -- Step 5: Generate ore veins
    ore_veins.generate_ores(data, area, minp, maxp, biome_map, heightmap, mapgen.world_seed)
    
    -- Step 6: Apply node dust (placed on top of node_top blocks)
    terrain_features.apply_node_dust(data, area, minp, maxp, biome_map, heightmap)
    
    -- Step 7: Generate terrain features (decorations, structures)
    terrain_features.generate_features(data, area, minp, maxp, biome_map, heightmap, mapgen.world_seed)
    
    -- Step 8: Write data to map (caves are generated by mapgen script)
    vm:set_data(data)
    vm:write_to_map()
    
    -- Step 9: Check if caves were generated by mapgen script and apply biomes to cave floors
    local caves_generated = mapgen.check_caves_generated()
    if caves_generated then
        -- Re-read the data after cave generation by mapgen script
        local updated_data = vm:get_data()
        mapgen.apply_biomes_to_caves(updated_data, area, minp, maxp, biome_map, heightmap)
        vm:set_data(updated_data)
    end
    
    -- Check if there are rivers in this chunk for liquid updates
    local has_rivers = false
    for z = minp.z, maxp.z, 8 do -- Sample every 8 blocks for performance
        for x = minp.x, maxp.x, 8 do
            local river_info = api.get_river_info_at(x, z, mapgen.world_seed)
            if river_info.is_river then
                has_rivers = true
                break
            end
        end
        if has_rivers then break end
    end
    
    -- Update liquids if caves were generated or rivers are present
    if caves_generated or has_rivers then
        vm:update_liquids()
    end
    
    vm:update_map()
end

-- Debug functions
function mapgen.get_debug_info(pos)
    if not mapgen.initialized then
        mapgen.init()
    end
    
    local x, y, z = pos.x, pos.y, pos.z
    
    -- Get terrain height (simplified)
    local heightmap, _ = api.generate_heightmap(
        {x = x, y = y, z = z}, 
        {x = x, y = y, z = z}, 
        mapgen.world_seed
    )
    local terrain_height = heightmap[1] or y
    
    -- Get climate info
    local climate_info = climate.get_debug_info(x, z, terrain_height)
    
    -- Get terrain classification
    local terrain_class = api.classify_terrain(x, z, mapgen.world_seed)
    
    -- Get biome info
    local selected_biome = biomes.get_biome_at(
        climate_info.temperature, 
        climate_info.humidity, 
        terrain_height,
        terrain_class,
        x, z
    )
    
    local biome_info = {
        selected_biome = selected_biome and selected_biome.name or "none",
        terrain_classification = terrain_class.elevation_category,
        continentalness = terrain_class.continentalness,
        peaks = terrain_class.peaks,
        erosion = terrain_class.erosion,
        jagged = terrain_class.jagged
    }
    
    -- Get cave info (caves are now handled by mapgen scripts)
    -- Cave debug info is no longer available in main environment
    local is_cheese_cave = false
    local cheese_density = 0
    
    -- Get valley info
    local valley_depression = api.get_terrain_depression_at(x, z, mapgen.world_seed)
    local valley_noise = api.noise_objects.terrain_depression and 
        api.noise_objects.terrain_depression:get_2d({x=x, y=z}) or 0
    local valley_spline = api.spline_map(valley_noise, api.splines.terrain_depression, mapgen.world_seed, x, z)
    
    return {
        position = pos,
        terrain_height = terrain_height,
        climate = climate_info,
        biome = biome_info,
        caves = {
            is_cheese_cave = is_cheese_cave,
            cheese_density = cheese_density
        },
        valleys = {
            depression = valley_depression,
            raw_noise = valley_noise,
            spline_value = valley_spline,
            is_active = valley_depression < -0.1
        }
    }
end

-- Chat command to check biome at position
minetest.register_chatcommand("voxelgen_biome", {
    description = "Get biome info at current position",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        local x, y, z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
        
        if not mapgen.initialized then
            mapgen.init()
        end
        
        -- Get terrain height
        local heightmap, _ = api.generate_heightmap(
            {x = x, y = y, z = z}, 
            {x = x, y = y, z = z}, 
            mapgen.world_seed
        )
        local terrain_height = heightmap[1] or y
        
        -- Get climate info
        local temperature = climate.get_temperature(x, z, y, terrain_height)
        local humidity = climate.get_humidity(x, z, y, terrain_height)
        
        -- Get terrain classification
        local terrain_class = api.classify_terrain(x, z, mapgen.world_seed)
        
        -- Get biome
        local selected_biome = biomes.get_biome_at(temperature, humidity, terrain_height, terrain_class, x, z)
        
        -- Get Minecraft-style parameters
        local params = climate.get_biome_parameters(x, z, y, terrain_height)
        
        local output = string.format(
            "Biome Info at (%d, %d, %d):\n" ..
            "=== Legacy Values ===\n" ..
            "Terrain Height: %.1f\n" ..
            "Temperature: %.1f°C\n" ..
            "Humidity: %.1f%%\n" ..
            "=== Minecraft-style Parameters ===\n" ..
            "Temperature: %.3f (Level %d)\n" ..
            "Humidity: %.3f (Level %d)\n" ..
            "Continentalness: %.3f (%s)\n" ..
            "Erosion: %.3f (Level %d)\n" ..
            "Weirdness: %.3f\n" ..
            "PV (Peaks/Valleys): %.3f (%s)\n" ..
            "Depth: %.4f\n" ..
            "=== Result ===\n" ..
            "Selected Biome: %s\n" ..
            "Registered Biomes: %d",
            x, y, z,
            terrain_height,
            temperature,
            humidity,
            params.temperature, params.temperature_level,
            params.humidity, params.humidity_level,
            params.continentalness, params.continentalness_name,
            params.erosion, params.erosion_level,
            params.weirdness,
            params.pv, params.pv_name,
            params.depth,
            selected_biome and selected_biome.name or "NONE",
            (function() local all_biomes = biomes.get_registered_biomes(); local count = 0; for _ in pairs(all_biomes) do count = count + 1 end; return count end)()
        )
        
        return true, output
    end,
})

-- Chat command to check river info at position
minetest.register_chatcommand("voxelgen_river", {
    description = "Get river info at current position",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        local x, y, z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
        
        if not mapgen.initialized then
            mapgen.init()
        end
        
        -- Get river information
        local river_info = api.get_river_info_at(x, z, mapgen.world_seed)
        local river_strength, river_width = api.get_river_factor(x, z, mapgen.world_seed)
        local river_depth = api.calculate_river_depth(x, z, river_strength, mapgen.world_seed)
        local river_water_level = api.calculate_river_water_level(x, z, river_strength, mapgen.world_seed)
        
        -- Get terrain height for comparison
        local heightmap, _ = api.generate_heightmap(
            {x = x, y = y, z = z}, 
            {x = x, y = y, z = z}, 
            mapgen.world_seed
        )
        local terrain_height = heightmap[1] or y
        
        local output = string.format(
            "River Info at (%d, %d, %d):\n" ..
            "=== River Status ===\n" ..
            "Is River: %s\n" ..
            "Is Riverbank: %s\n" ..
            "River Strength: %.3f\n" ..
            "River Width: %.1f blocks\n" ..
            "=== Water Levels ===\n" ..
            "Sea Level: %d\n" ..
            "River Depth: %.1f blocks\n" ..
            "River Water Level: %.1f\n" ..
            "Terrain Height: %.1f\n" ..
            "=== Analysis ===\n" ..
            "Should Have Water: %s\n" ..
            "Water Depth: %.1f blocks",
            x, y, z,
            river_info.is_river and "YES" or "NO",
            river_info.is_riverbank and "YES" or "NO",
            river_strength,
            river_width,
            api.SEA_LEVEL,
            river_depth,
            river_water_level,
            terrain_height,
            (river_info.is_river and terrain_height < river_water_level) and "YES" or "NO",
            math.max(0, river_water_level - terrain_height)
        )
        
        return true, output
    end,
})

-- Chat command to list registered biomes
minetest.register_chatcommand("voxelgen_biomes", {
    description = "List all registered biomes with search-friendly names",
    params = "[search_term]",
    func = function(name, param)
        local search_term = param and param:lower() or nil
        local output = "Registered Biomes:\n"
        local count = 0
        local matched_biomes = {}
        
        -- Collect and filter biomes
        local all_biomes = biomes.get_registered_biomes()
        for biome_name, biome in pairs(all_biomes) do
            if not search_term or biome_name:lower():find(search_term, 1, true) then
                table.insert(matched_biomes, {name = biome_name, def = biome})
            end
        end
        
        -- Sort alphabetically
        table.sort(matched_biomes, function(a, b) return a.name < b.name end)
        
        -- Format output
        for i, biome_data in ipairs(matched_biomes) do
            count = count + 1
            local biome_name = biome_data.name
            local biome = biome_data.def
            
            -- Modern biome format
            local temp_levels = biome.temperature_levels and 
                table.concat(biome.temperature_levels, ",") or "any"
            local humidity_levels = biome.humidity_levels and 
                table.concat(biome.humidity_levels, ",") or "any"
            local continentalness = biome.continentalness_names and 
                table.concat(biome.continentalness_names, ",") or "any"
            output = output .. string.format("%d. %s (TempLvl: %s, HumLvl: %s, Cont: %s)\n",
                count, biome_name, temp_levels, humidity_levels, continentalness)
        end
        
        if count == 0 then
            if search_term then
                output = string.format("No biomes found matching '%s'", search_term)
            else
                output = "No biomes registered!"
            end
        else
            if search_term then
                output = output .. string.format("\nFound %d biomes matching '%s'", count, search_term)
            else
                output = output .. string.format("\nTotal: %d biomes", count)
            end
            output = output .. "\n\nUse: /voxelgen_goto_biome <biome_name> [radius] [--fast]"
        end
        
        return true, output
    end,
})

-- Chat commands for debugging
minetest.register_chatcommand("voxelgen_debug", {
    description = "Get VoxelGen debug info at current position",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        local debug_info = mapgen.get_debug_info({
            x = math.floor(pos.x),
            y = math.floor(pos.y),
            z = math.floor(pos.z)
        })
        
        local output = string.format(
            "VoxelGen Debug Info:\n" ..
            "Position: (%d, %d, %d)\n" ..
            "Terrain Height: %.1f\n" ..
            "Temperature: %.1f°C (base: %.1f°C)\n" ..
            "Humidity: %.1f%% (base: %.1f%%)\n" ..
            "Climate Type: %s\n" ..
            "Water Distance: %.0f blocks\n" ..
            "Terrain Classification: %s\n" ..
            "Continentalness: %.3f\n" ..
            "Peaks: %.3f\n" ..
            "Erosion: %.3f\n" ..
            "Jagged: %.3f\n" ..
            "Valley Depression: %.2f blocks (%s)\n" ..
            "Valley Raw Noise: %.3f\n" ..
            "Valley Spline: %.2f\n" ..
            "Selected Biome: %s\n" ..
            "Is Cave: %s (density: %.3f)",
            debug_info.position.x, debug_info.position.y, debug_info.position.z,
            debug_info.terrain_height,
            debug_info.climate.temperature, debug_info.climate.base_temperature,
            debug_info.climate.humidity, debug_info.climate.base_humidity,
            debug_info.climate.climate_type,
            debug_info.climate.water_distance,
            debug_info.biome.terrain_classification,
            debug_info.biome.continentalness,
            debug_info.biome.peaks,
            debug_info.biome.erosion,
            debug_info.biome.jagged,
            debug_info.valleys.depression, debug_info.valleys.is_active and "ACTIVE" or "inactive",
            debug_info.valleys.raw_noise,
            debug_info.valleys.spline_value,
            debug_info.biome.selected_biome,
            tostring(debug_info.caves.is_cheese_cave), debug_info.caves.cheese_density
        )
        
        return true, output
    end,
})

minetest.register_chatcommand("voxelgen_config", {
    description = "Configure VoxelGen parameters",
    params = "<system> <parameter> <value>",
    func = function(name, param)
        local parts = param:split(" ")
        if #parts < 3 then
            return false, "Usage: /voxelgen_config <system> <parameter> <value>\n" ..
                         "Systems: caves\n" ..
                         "Cave parameters: cheese.rarity, cheese.threshold, tunnels.enabled"
        end
        
        local system = parts[1]
        local parameter = parts[2]
        local value = parts[3]
        
        if system == "caves" then
            local cave_type, param_name = parameter:match("([^.]+)%.([^.]+)")
            if cave_type and param_name then
                local numeric_value = tonumber(value)
                local bool_value = value == "true" and true or (value == "false" and false or nil)
                local final_value = numeric_value or bool_value or value
                
                if caves.set_config(cave_type, param_name, final_value) then
                    return true, string.format("Set %s.%s = %s", cave_type, param_name, tostring(final_value))
                else
                    return false, "Invalid parameter: " .. parameter
                end
            else
                return false, "Invalid parameter format. Use: cave_type.parameter"
            end
        else
            return false, "Unknown system: " .. system
        end
    end,
})



-- Command to find biomes in the area
minetest.register_chatcommand("voxelgen_find_biomes", {
    description = "Find biomes in a radius around current position",
    params = "[radius] [biome_name]",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        local x, y, z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
        
        if not mapgen.initialized then
            mapgen.init()
        end
        
        -- Parse parameters
        local parts = param:split(" ")
        local radius = tonumber(parts[1]) or 50
        local target_biome = parts[2]
        
        if radius > 200 then
            return false, "Radius too large (max 200)"
        end
        
        local biome_counts = {}
        local biome_positions = {}
        local total_checked = 0
        
        -- Sample points in a grid pattern
        local step = math.max(1, math.floor(radius / 20)) -- Adjust sampling density
        
        for dx = -radius, radius, step do
            for dz = -radius, radius, step do
                local check_x = x + dx
                local check_z = z + dz
                local distance = math.sqrt(dx*dx + dz*dz)
                
                if distance <= radius then
                    total_checked = total_checked + 1
                    
                    -- Get terrain height
                    local heightmap, _ = api.generate_heightmap(
                        {x = check_x, y = y, z = check_z}, 
                        {x = check_x, y = y, z = check_z}, 
                        mapgen.world_seed
                    )
                    local terrain_height = heightmap[1] or y
                    
                    -- Get climate info
                    local temperature = climate.get_temperature(check_x, check_z, terrain_height, terrain_height)
                    local humidity = climate.get_humidity(check_x, check_z, terrain_height, terrain_height)
                    
                    -- Get terrain classification
                    local terrain_class = api.classify_terrain(check_x, check_z, mapgen.world_seed)
                    
                    -- Get biome
                    local selected_biome = biomes.get_biome_at(temperature, humidity, terrain_height, terrain_class, check_x, check_z)
                    
                    if selected_biome then
                        local biome_name = selected_biome.name
                        biome_counts[biome_name] = (biome_counts[biome_name] or 0) + 1
                        
                        -- Store position for specific biome search
                        if not biome_positions[biome_name] then
                            biome_positions[biome_name] = {}
                        end
                        table.insert(biome_positions[biome_name], {
                            x = check_x, 
                            y = terrain_height, 
                            z = check_z, 
                            distance = distance
                        })
                    end
                end
            end
        end
        
        -- Format output
        local output = ""
        
        if target_biome then
            -- Search for specific biome
            if biome_positions[target_biome] then
                output = string.format("Found %d locations with biome '%s' within %d blocks:\n", 
                    #biome_positions[target_biome], target_biome, radius)
                
                -- Sort by distance and show closest 5
                table.sort(biome_positions[target_biome], function(a, b) return a.distance < b.distance end)
                
                for i = 1, math.min(5, #biome_positions[target_biome]) do
                    local p = biome_positions[target_biome][i]
                    output = output .. string.format("  %d. (%d, %d, %d) - %.1f blocks away\n", 
                        i, p.x, p.y, p.z, p.distance)
                end
                
                if #biome_positions[target_biome] > 5 then
                    output = output .. string.format("  ... and %d more locations\n", 
                        #biome_positions[target_biome] - 5)
                end
            else
                output = string.format("Biome '%s' not found within %d blocks\n", target_biome, radius)
            end
        else
            -- Show all biomes found
            output = string.format("Biomes found within %d blocks (sampled %d points):\n", radius, total_checked)
            
            if next(biome_counts) == nil then
                output = output .. "No biomes found! This indicates a problem with biome generation.\n"
            else
                -- Sort biomes by count
                local sorted_biomes = {}
                for biome_name, count in pairs(biome_counts) do
                    table.insert(sorted_biomes, {name = biome_name, count = count})
                end
                table.sort(sorted_biomes, function(a, b) return a.count > b.count end)
                
                for i, biome_data in ipairs(sorted_biomes) do
                    local percentage = math.floor(biome_data.count / total_checked * 100)
                    output = output .. string.format("  %s: %d locations (%d%%)\n", 
                        biome_data.name, biome_data.count, percentage)
                    
                    -- Show closest location for this biome
                    if biome_positions[biome_data.name] then
                        table.sort(biome_positions[biome_data.name], function(a, b) return a.distance < b.distance end)
                        local closest = biome_positions[biome_data.name][1]
                        output = output .. string.format("    Closest: (%d, %d, %d) - %.1f blocks\n", 
                            closest.x, closest.y, closest.z, closest.distance)
                    end
                end
            end
        end
        
        return true, output
    end,
})

-- Command to teleport to a specific biome (enhanced with seed-based optimization)
minetest.register_chatcommand("voxelgen_goto_biome", {
    description = "Teleport to the nearest instance of a biome using seed-based calculations",
    params = "<biome_name> [radius] [--fast]",
    privs = {teleport = true},
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local parts = param:split(" ")
        local target_biome = parts[1]
        local radius = tonumber(parts[2]) or 200
        local fast_mode = param:find("--fast") ~= nil
        
        if not target_biome or target_biome == "" then
            return false, "Usage: /voxelgen_goto_biome <biome_name> [radius] [--fast]\n" ..
                         "Use --fast for quicker but less precise search"
        end
        
        if radius > 1000 then
            return false, "Radius too large (max 1000)"
        end
        
        -- Check if biome exists
        local all_biomes = biomes.get_registered_biomes()
        if not all_biomes[target_biome] then
            local available = {}
            local external_biomes = {}
            local default_biomes = {}
            
            for biome_name, _ in pairs(all_biomes) do
                table.insert(available, biome_name)
                if biome_name:match(":") then
                    table.insert(external_biomes, biome_name)
                else
                    table.insert(default_biomes, biome_name)
                end
            end
            
            table.sort(available)
            table.sort(external_biomes)
            table.sort(default_biomes)
            
            local message = string.format("Biome '%s' not found.\n", target_biome)
            message = message .. string.format("Total biomes: %d (%d external, %d default)\n", 
                #available, #external_biomes, #default_biomes)
            
            if #external_biomes > 0 then
                message = message .. "External biomes: " .. table.concat(external_biomes, ", ") .. "\n"
            end
            
            if #default_biomes > 0 then
                message = message .. "Default biomes: " .. table.concat(default_biomes, ", ")
            end
            
            return false, message
        end
        
        local pos = player:get_pos()
        local start_x, start_z = math.floor(pos.x), math.floor(pos.z)
        
        if not mapgen.initialized then
            mapgen.init()
        end
        
        local closest_pos = nil
        local closest_distance = math.huge
        local checked_positions = 0
        local start_time = minetest.get_us_time()
        
        -- Get biome requirements for optimization
        local target_biome_def = all_biomes[target_biome]
        
        -- Intelligent search pattern: spiral outward from player position
        local function spiral_search()
            local step = fast_mode and 8 or 4
            local max_ring = math.ceil(radius / step)
            
            for ring = 0, max_ring do
                local ring_radius = ring * step
                if ring_radius > radius then break end
                
                if ring == 0 then
                    -- Check center position
                    local check_x, check_z = start_x, start_z
                    local distance = 0
                    
                    if distance < closest_distance then
                        local result = check_biome_at_position(check_x, check_z, target_biome, target_biome_def)
                        checked_positions = checked_positions + 1
                        
                        if result then
                            closest_pos = result
                            closest_distance = distance
                            if distance == 0 then return end -- Found at player position
                        end
                    end
                else
                    -- Check ring perimeter
                    local points_per_side = math.max(1, math.floor(ring_radius / step))
                    
                    for side = 0, 3 do
                        for i = 0, points_per_side do
                            local check_x, check_z
                            local t = i / math.max(1, points_per_side)
                            
                            if side == 0 then -- Top
                                check_x = start_x + math.floor((t * 2 - 1) * ring_radius)
                                check_z = start_z - ring_radius
                            elseif side == 1 then -- Right
                                check_x = start_x + ring_radius
                                check_z = start_z + math.floor((t * 2 - 1) * ring_radius)
                            elseif side == 2 then -- Bottom
                                check_x = start_x + math.floor((1 - t) * 2 - 1) * ring_radius
                                check_z = start_z + ring_radius
                            else -- Left
                                check_x = start_x - ring_radius
                                check_z = start_z + math.floor((1 - t) * 2 - 1) * ring_radius
                            end
                            
                            local dx, dz = check_x - start_x, check_z - start_z
                            local distance = math.sqrt(dx*dx + dz*dz)
                            
                            if distance <= radius and distance < closest_distance then
                                local result = check_biome_at_position(check_x, check_z, target_biome, target_biome_def)
                                checked_positions = checked_positions + 1
                                
                                if result then
                                    closest_pos = result
                                    closest_distance = distance
                                end
                            end
                        end
                    end
                end
                
                -- Early exit if we found something close enough
                if closest_pos and closest_distance < step * 2 then
                    break
                end
                
                -- Timeout protection
                if minetest.get_us_time() - start_time > 5000000 then -- 5 seconds
                    break
                end
            end
        end
        
        -- Function to check biome at a specific position
        function check_biome_at_position(check_x, check_z, target_name, biome_def)
            -- Pre-filter using noise values if possible (optimization)
            if biome_def.temperature_min and biome_def.temperature_max then
                local quick_temp = api.get_heat_at(check_x, check_z, 0) -- Rough temperature check
                if quick_temp < biome_def.temperature_min - 10 or quick_temp > biome_def.temperature_max + 10 then
                    return nil -- Skip detailed calculation
                end
            end
            
            -- Get terrain height using seed-based calculation
            local heightmap, _ = api.generate_heightmap(
                {x = check_x, y = 0, z = check_z}, 
                {x = check_x, y = 0, z = check_z}, 
                mapgen.world_seed
            )
            local terrain_height = heightmap[1] or 0
            
            -- Get climate info using seed-based calculations
            local temperature = climate.get_temperature(check_x, check_z, terrain_height, terrain_height)
            local humidity = climate.get_humidity(check_x, check_z, terrain_height, terrain_height)
            
            -- Get terrain classification using seed-based noise
            local terrain_class = api.classify_terrain(check_x, check_z, mapgen.world_seed)
            
            -- Get biome using the full biome selection system
            local selected_biome = biomes.get_biome_at(temperature, humidity, terrain_height, terrain_class, check_x, check_z)
            
            if selected_biome and selected_biome.name == target_name then
                -- Find a safe Y position (above terrain, below max height)
                local safe_y = math.max(terrain_height + 2, api.SEA_LEVEL + 1)
                safe_y = math.min(safe_y, 200) -- Don't teleport too high
                
                return {x = check_x, y = safe_y, z = check_z, terrain_height = terrain_height}
            end
            
            return nil
        end
        
        -- Perform the search
        spiral_search()
        
        local search_time = (minetest.get_us_time() - start_time) / 1000 -- Convert to milliseconds
        
        if closest_pos then
            player:set_pos(closest_pos)
            return true, string.format(
                "Teleported to %s biome at (%d, %d, %d)\n" ..
                "Distance: %.1f blocks | Terrain height: %.1f\n" ..
                "Search time: %.1fms | Positions checked: %d",
                target_biome, closest_pos.x, closest_pos.y, closest_pos.z,
                closest_distance, closest_pos.terrain_height,
                search_time, checked_positions
            )
        else
            return false, string.format(
                "Biome '%s' not found within %d blocks\n" ..
                "Search time: %.1fms | Positions checked: %d\n" ..
                "Try increasing the radius or use --fast for broader search",
                target_biome, radius, search_time, checked_positions
            )
        end
    end,
})

-- Command to manually register biomes (for debugging)
minetest.register_chatcommand("voxelgen_register_biomes", {
    description = "Manually trigger biome registration",
    privs = {server = true},
    func = function(name)
        local success = biomes.register_defaults()
        local stats = biomes.get_statistics()
        local count = stats.total_biomes
        
        if success then
            return true, string.format("Biome registration completed. %d biomes registered.", count)
        else
            return false, string.format("Biome registration failed. %d biomes registered.", count)
        end
    end,
})

-- Command to check available nodes
minetest.register_chatcommand("voxelgen_check_nodes", {
    description = "Check if required nodes are available",
    func = function(name)
        local required_nodes = {
            "default:stone", "default:dirt", "default:dirt_with_grass", 
            "default:sand", "default:water_source", "default:gravel",
            "default:snow", "default:ice", "default:sandstone", "default:clay"
        }
        
        local output = "Node availability check:\n"
        local missing_count = 0
        
        for _, node_name in ipairs(required_nodes) do
            local available = minetest.registered_nodes[node_name] ~= nil
            output = output .. string.format("  %s: %s\n", node_name, available and "✓" or "✗")
            if not available then
                missing_count = missing_count + 1
            end
        end
        
        output = output .. string.format("\nSummary: %d/%d nodes available", 
            #required_nodes - missing_count, #required_nodes)
        
        if missing_count > 0 then
            output = output .. "\nMissing nodes will prevent biome registration!"
        end
        
        return true, output
    end,
})

-- Chat command to test valley carving at current position
minetest.register_chatcommand("voxelgen_valley", {
    description = "Test valley carving at current position",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        local x, z = math.floor(pos.x), math.floor(pos.z)
        
        if not mapgen.initialized then
            mapgen.init()
        end
        
        -- Test valley carving function
        local valley_depression = api.get_terrain_depression_at(x, z, mapgen.world_seed)
        
        -- Get raw noise values for debugging
        local valley_noise = api.noise_objects.terrain_depression and 
            api.noise_objects.terrain_depression:get_2d({x=x, y=z}) or 0
        local valley_spline = api.spline_map(valley_noise, api.splines.terrain_depression, mapgen.world_seed, x, z)
        
        local width_noise = api.noise_objects.valley_width and 
            api.noise_objects.valley_width:get_2d({x=x, y=z}) or 0
        local direction_noise = api.noise_objects.valley_direction and 
            api.noise_objects.valley_direction:get_2d({x=x, y=z}) or 0
        
        local output = string.format(
            "Valley Carving Debug at (%d, %d):\n" ..
            "Valley Depression: %.2f blocks\n" ..
            "Raw Valley Noise: %.3f\n" ..
            "Valley Spline Value: %.2f\n" ..
            "Width Noise: %.3f\n" ..
            "Direction Noise: %.3f\n" ..
            "Valley Active: %s",
            x, z,
            valley_depression,
            valley_noise,
            valley_spline,
            width_noise,
            direction_noise,
            valley_depression < -0.1 and "YES" or "NO"
        )
        
        return true, output
    end,
})

-- Chat command for cave debugging
minetest.register_chatcommand("voxelgen_caves", {
    description = "Get cave info at current position",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        local x, y, z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
        
        if not mapgen.initialized then
            mapgen.init()
        end
        
        -- Get cave information (caves are now handled by mapgen scripts)
        -- Cave debug info is no longer available in main environment
        local is_cheese_cave = false
        local cheese_density = 0
        
        -- Create mock data for water connectivity test
        local mock_data = {}
        local mock_area = {
            contains = function(self, tx, ty, tz)
                return tx >= x - 16 and tx <= x + 16 and
                       ty >= y - 16 and ty <= y + 16 and
                       tz >= z - 16 and tz <= z + 16
            end,
            index = function(self, tx, ty, tz)
                return (tx - x + 16) * 33 * 33 + (ty - y + 16) * 33 + (tz - z + 16)
            end
        }
        
        -- Fill with stone and add water at sea level
        for i = 1, 33^3 do
            mock_data[i] = c_stone
        end
        for tz = z - 16, z + 16 do
            for tx = x - 16, x + 16 do
                if mock_area:contains(tx, 0, tz) then
                    local vi = mock_area:index(tx, 0, tz)
                    mock_data[vi] = c_water
                end
            end
        end
        
        -- Water access checking is no longer available (caves moved to mapgen scripts)
        local has_water_access = false
        
        local output = string.format(
            "Cave Info at (%d, %d, %d):\n" ..
            "Note: Cave generation moved to mapgen scripts\n" ..
            "Cave debug info no longer available in main environment\n" ..
            "Is Cheese Cave: %s\n" ..
            "Cheese Density: %.3f\n" ..
            "Below Sea Level: %s\n" ..
            "Has Water Access: %s\n" ..
            "Would Fill With: %s",
            x, y, z,
            is_cheese_cave and "YES" or "NO",
            cheese_density,
            y < api.SEA_LEVEL and "YES" or "NO",
            has_water_access and "YES" or "NO",
            (is_cheese_cave and y < api.SEA_LEVEL and has_water_access) and "WATER" or "AIR"
        )
        
        return true, output
    end,
})

-- Chat command for cave performance stats
minetest.register_chatcommand("voxelgen_cave_stats", {
    description = "Show cave generation performance statistics",
    func = function(name)
        -- Cave stats are no longer available (caves moved to mapgen scripts)
        local output = "Cave Generation Performance Stats:\n" ..
            "=================================\n" ..
            "Note: Cave generation moved to mapgen scripts\n" ..
            "Performance stats no longer available in main environment\n" ..
            "Cave generation is now handled by the mapgen environment"
        
        return true, output
    end,
})

-- Chat command to reset cave performance stats
minetest.register_chatcommand("voxelgen_cave_stats_reset", {
    description = "Reset cave generation performance statistics",
    func = function(name)
        -- Cave stats are no longer available (caves moved to mapgen scripts)
        return true, "Cave performance statistics are no longer available.\nCave generation moved to mapgen scripts."
    end,
})

-- Chat command to configure cave settings
minetest.register_chatcommand("voxelgen_cave_config", {
    description = "Configure cave generation settings",
    params = "<cave_type> <parameter> <value>",
    func = function(name, param)
        local parts = param:split(" ")
        if #parts ~= 3 then
            return false, "Usage: /voxelgen_cave_config <cave_type> <parameter> <value>\n" ..
                         "Example: /voxelgen_cave_config performance skip_step 1\n" ..
                         "Cave types: cheese, tunnels, performance"
        end
        
        local cave_type, parameter, value_str = parts[1], parts[2], parts[3]
        local value = tonumber(value_str)
        if not value then
            if value_str == "true" then
                value = true
            elseif value_str == "false" then
                value = false
            else
                return false, "Value must be a number, 'true', or 'false'"
            end
        end
        
        -- Cave configuration is no longer available (caves moved to mapgen scripts)
        return false, "Cave configuration is no longer available.\nCave generation moved to mapgen scripts.\nConfiguration must be done via IPC or mod settings."
    end,
})

-- Register the mapgen callback
minetest.register_on_generated(mapgen.generate_chunk)

return mapgen
