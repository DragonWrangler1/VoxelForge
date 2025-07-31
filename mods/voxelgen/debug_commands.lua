-- Debug commands for terrain features and biome testing

-- Command to list all registered terrain features
minetest.register_chatcommand("list_terrain_features", {
    description = "List all registered terrain features",
    privs = {server = true},
    func = function(name)
        if not voxelgen or not voxelgen.terrain_features then
            return false, "VoxelGen terrain features not loaded"
        end
        
        local features = voxelgen.get_registered_terrain_features()
        local output = {"Registered terrain features:"}
        

        
        local count = 0
        for feature_name, feature_def in pairs(features) do
            count = count + 1
            table.insert(output, string.format("  %d. %s (type: %s, biomes: %s, prob: %.2f)", 
                count, feature_name, feature_def.type, 
                table.concat(feature_def.biomes, ","), feature_def.probability))
        end
        
        if count == 0 then
            table.insert(output, "  No terrain features registered")
        end
        
        return true, table.concat(output, "\n")
    end
})

-- Command to show terrain feature statistics
minetest.register_chatcommand("terrain_features_debug", {
    description = "Show terrain features debug information",
    privs = {server = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        local output = {}
        
        -- Show registered features
        if voxelgen and voxelgen.terrain_features then
            local features = voxelgen.get_registered_terrain_features()
            local stats = voxelgen.get_terrain_feature_statistics()
            
            table.insert(output, "=== Terrain Features Debug ===")
            table.insert(output, "Total registered features: " .. stats.total_features)
            table.insert(output, "Block features: " .. (stats.by_type.block or 0))
            table.insert(output, "Function features: " .. (stats.by_type["function"] or 0))
            table.insert(output, "Schematic features: " .. (stats.by_type.schematic or 0))
            table.insert(output, "")
            table.insert(output, "Registered features:")
            
            for feature_name, feature_def in pairs(features) do
                local biomes_str = table.concat(feature_def.biomes, ", ")
                table.insert(output, "- " .. feature_name .. " (type: " .. feature_def.type .. ", biomes: " .. biomes_str .. ", prob: " .. feature_def.probability .. ")")
            end
        else
            table.insert(output, "ERROR: Terrain features system not loaded!")
        end
        
        -- Show biome info at current position
        table.insert(output, "")
        table.insert(output, "=== Current Position Info ===")
        table.insert(output, "Position: " .. minetest.pos_to_string(pos))
        
        -- Try to get biome info if available
        if voxelgen and voxelgen.get_registered_biomes then
            local biomes = voxelgen.get_registered_biomes()
            table.insert(output, "Registered biomes: " .. table.concat(table.keys(biomes), ", "))
        end
        
        return true, table.concat(output, "\n")
    end
})

-- Command to manually place a test feature at current position
minetest.register_chatcommand("place_test_feature", {
    description = "Place a test stone block at current position",
    privs = {server = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        pos.y = pos.y + 1 -- Place above player
        
        -- Place a stone block
        minetest.set_node(pos, {name = "vlf_blocks:stone"})
        
        return true, "Placed test stone block at " .. minetest.pos_to_string(pos)
    end
})

-- Command to force regenerate a chunk (if possible)
minetest.register_chatcommand("regen_chunk", {
    description = "Force regenerate current chunk (WARNING: destructive)",
    privs = {server = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        local minp = {
            x = math.floor(pos.x / 16) * 16,
            y = math.floor(pos.y / 16) * 16,
            z = math.floor(pos.z / 16) * 16
        }
        local maxp = {
            x = minp.x + 15,
            y = minp.y + 15,
            z = minp.z + 15
        }
        
        -- This is a destructive operation - clear the area first
        for x = minp.x, maxp.x do
            for y = minp.y, maxp.y do
                for z = minp.z, maxp.z do
                    minetest.set_node({x=x, y=y, z=z}, {name = "air"})
                end
            end
        end
        
        return true, "Cleared chunk from " .. minetest.pos_to_string(minp) .. " to " .. minetest.pos_to_string(maxp) .. ". New terrain will generate when you move away and back."
    end
})

-- Command to debug climate values at current position
minetest.register_chatcommand("climate_debug", {
    description = "Show climate values at current position",
    privs = {server = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        local x, y, z = pos.x, pos.y, pos.z
        
        local output = {}
        table.insert(output, "=== Climate Debug at " .. minetest.pos_to_string(pos) .. " ===")
        
        -- Check if climate system is initialized
        if not voxelgen or not voxelgen.climate or not voxelgen.climate.initialized then
            table.insert(output, "ERROR: Climate system not initialized!")
            return true, table.concat(output, "\n")
        end
        
        -- Get raw noise values
        if voxelgen.climate.noise_objects.temperature and voxelgen.climate.noise_objects.humidity then
            local temp_raw = voxelgen.climate.noise_objects.temperature:get_2d({x=x, y=z})
            local humid_raw = voxelgen.climate.noise_objects.humidity:get_2d({x=x, y=z})
            
            table.insert(output, "Raw noise values:")
            table.insert(output, "  Temperature raw: " .. string.format("%.3f", temp_raw))
            table.insert(output, "  Humidity raw: " .. string.format("%.3f", humid_raw))
            
            -- Show normalized values (raw values should now be in -1 to 1 range directly)
            local temp_normalized = math.max(-1, math.min(1, temp_raw))
            local humid_normalized = math.max(-1, math.min(1, humid_raw))
            
            table.insert(output, "Normalized values (should be same as raw since noise generates -1 to 1):")
            table.insert(output, "  Temperature normalized: " .. string.format("%.3f", temp_normalized))
            table.insert(output, "  Humidity normalized: " .. string.format("%.3f", humid_normalized))
        end
        
        -- Get terrain height for full climate calculation
        local terrain_height = 64 -- Default, could be improved
        if voxelgen.api and voxelgen.api.get_terrain_height then
            terrain_height = voxelgen.api.get_terrain_height(x, z)
        end
        
        -- Get full biome parameters
        local params = voxelgen.climate.get_biome_parameters(x, z, y, terrain_height)
        
        table.insert(output, "")
        table.insert(output, "Final climate parameters:")
        table.insert(output, "  Temperature: " .. string.format("%.3f", params.temperature) .. " (level " .. params.temperature_level .. ")")
        table.insert(output, "  Humidity: " .. string.format("%.3f", params.humidity) .. " (level " .. params.humidity_level .. ")")
        table.insert(output, "  Continentalness: " .. string.format("%.3f", params.continentalness) .. " (" .. params.continentalness_name .. ")")
        table.insert(output, "  Erosion: " .. string.format("%.3f", params.erosion) .. " (level " .. params.erosion_level .. ")")
        table.insert(output, "  PV: " .. string.format("%.3f", params.pv) .. " (" .. params.pv_name .. ")")
        table.insert(output, "  Depth: " .. string.format("%.3f", params.depth))
        
        -- Show temperature level ranges for reference
        table.insert(output, "")
        table.insert(output, "Temperature level ranges:")
        table.insert(output, "  0 (Frozen): -1.0 to -0.45")
        table.insert(output, "  1 (Cold): -0.45 to -0.15")
        table.insert(output, "  2 (Temperate): -0.15 to 0.2")
        table.insert(output, "  3 (Warm): 0.2 to 0.55")
        table.insert(output, "  4 (Hot): 0.55 to 1.0")
        
        -- Get selected biome using both methods
        if voxelgen.biomes and voxelgen.biomes.get_biome_at then
            local temperature = voxelgen.climate.get_temperature(x, z, y, terrain_height)
            local humidity = voxelgen.climate.get_humidity(x, z, y, terrain_height)
            local terrain_class = voxelgen.api.classify_terrain(x, z, voxelgen.mapgen.world_seed or 12345)
            
            local biome = voxelgen.biomes.get_biome_at(temperature, humidity, terrain_height, terrain_class, x, z)
            if biome then
                table.insert(output, "")
                table.insert(output, "Selected biome: " .. biome.name)
                table.insert(output, "Legacy temp/humid: " .. string.format("%.1f", temperature) .. "°C / " .. string.format("%.1f", humidity) .. "%")
            end
        end
        
        -- Also show what the visualizer would show
        if voxelgen.get_biome_at then
            local viz_biome = voxelgen.get_biome_at(x, terrain_height, z, terrain_height)
            if viz_biome and viz_biome.name then
                table.insert(output, "Visualizer biome: " .. viz_biome.name)
            end
        end
        
        return true, table.concat(output, "\n")
    end
})

-- Debug command to test temperature calculation at specific coordinates
minetest.register_chatcommand("temp_test", {
    description = "Test temperature calculation at current position",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local pos = player:get_pos()
        local x, y, z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
        
        -- Initialize systems if needed
        if not voxelgen.mapgen.initialized then
            voxelgen.mapgen.init()
        end
        
        local output = {}
        table.insert(output, "Temperature Test at (" .. x .. ", " .. y .. ", " .. z .. ")")
        table.insert(output, "")
        
        -- Get terrain height
        local terrain_height = voxelgen.get_terrain_height_at(x, z)
        table.insert(output, "Terrain height: " .. string.format("%.1f", terrain_height))
        
        -- Test climate parameters
        if voxelgen.climate and voxelgen.climate.get_biome_parameters then
            local params = voxelgen.climate.get_biome_parameters(x, z, y, terrain_height)
            if params then
                table.insert(output, "")
                table.insert(output, "Raw climate values:")
                table.insert(output, "  Temperature: " .. string.format("%.3f", params.temperature) .. " (level " .. params.temperature_level .. ")")
                table.insert(output, "  Humidity: " .. string.format("%.3f", params.humidity) .. " (level " .. params.humidity_level .. ")")
                table.insert(output, "  Continentalness: " .. string.format("%.3f", params.continentalness) .. " (" .. params.continentalness_name .. ")")
                table.insert(output, "  Erosion: " .. string.format("%.3f", params.erosion) .. " (level " .. params.erosion_level .. ")")
                table.insert(output, "  PV: " .. string.format("%.3f", params.pv) .. " (" .. params.pv_name .. ")")
                
                -- Test biome selection
                if voxelgen.biomes and voxelgen.biomes.manager then
                    local best_biome = voxelgen.biomes.manager.get_best_biome(params)
                    if best_biome then
                        table.insert(output, "")
                        table.insert(output, "Selected biome: " .. best_biome.name)
                        table.insert(output, "Biome priority: " .. (best_biome.priority or "unknown"))
                        table.insert(output, "Biome temp levels: " .. table.concat(best_biome.temperature_levels or {}, ", "))
                    else
                        table.insert(output, "")
                        table.insert(output, "No biome selected!")
                    end
                end
            else
                table.insert(output, "Failed to get climate parameters")
            end
        else
            table.insert(output, "Climate system not available")
        end
        
        -- Test legacy temperature calculation
        local legacy_temp = voxelgen.climate.get_temperature(x, z, y, terrain_height)
        local legacy_humid = voxelgen.climate.get_humidity(x, z, y, terrain_height)
        table.insert(output, "")
        table.insert(output, "Legacy values:")
        table.insert(output, "  Temperature: " .. string.format("%.1f", legacy_temp) .. "°C")
        table.insert(output, "  Humidity: " .. string.format("%.1f", legacy_humid) .. "%")
        
        return true, table.concat(output, "\n")
    end
})

-- Debug command to force test desert biome selection
minetest.register_chatcommand("test_desert", {
    description = "Test if desert biome can be selected with hot parameters",
    func = function(name)
        local output = {}
        table.insert(output, "Desert Biome Selection Test")
        table.insert(output, "")
        
        -- Create ideal desert parameters
        local desert_params = {
            temperature_level = 4, -- Hot
            humidity_level = 0,    -- Arid
            continentalness_name = "mid_inland",
            erosion_level = 5,     -- Flat
            pv_name = "mid",
            depth = 0,
            y = 60,
            x = 0,
            z = 0
        }
        
        table.insert(output, "Testing with ideal desert parameters:")
        table.insert(output, "  Temperature level: " .. desert_params.temperature_level .. " (Hot)")
        table.insert(output, "  Humidity level: " .. desert_params.humidity_level .. " (Arid)")
        table.insert(output, "  Continentalness: " .. desert_params.continentalness_name)
        table.insert(output, "  Erosion level: " .. desert_params.erosion_level .. " (Flat)")
        table.insert(output, "")
        
        -- Test biome selection
        if voxelgen.biomes and voxelgen.biomes.manager then
            local best_biome = voxelgen.biomes.manager.get_best_biome(desert_params)
            if best_biome then
                table.insert(output, "Selected biome: " .. best_biome.name)
                table.insert(output, "Biome priority: " .. (best_biome.priority or "unknown"))
                table.insert(output, "Biome temp levels: " .. table.concat(best_biome.temperature_levels or {}, ", "))
                
                if best_biome.name == "desert" then
                    table.insert(output, "✓ SUCCESS: Desert biome selected correctly!")
                else
                    table.insert(output, "✗ ISSUE: Expected desert, got " .. best_biome.name)
                end
            else
                table.insert(output, "✗ CRITICAL: No biome selected at all!")
            end
        else
            table.insert(output, "✗ ERROR: Biome manager not available")
        end
        
        return true, table.concat(output, "\n")
    end
})

-- Command to analyze biome coverage and system health
minetest.register_chatcommand("biome_analysis", {
    description = "Analyze biome system coverage and health",
    privs = {server = true},
    func = function(name)
        local output = {}
        table.insert(output, "=== Biome System Analysis ===")
        table.insert(output, "")
        
        -- Check if biome system is available
        if not voxelgen or not voxelgen.biomes or not voxelgen.biomes.manager then
            table.insert(output, "ERROR: Biome system not available!")
            return true, table.concat(output, "\n")
        end
        
        -- Get biome statistics
        local stats = voxelgen.biomes.get_statistics()
        if not stats then
            table.insert(output, "ERROR: Could not get biome statistics!")
            return true, table.concat(output, "\n")
        end
        
        table.insert(output, "Total registered biomes: " .. stats.total_biomes)
        table.insert(output, "")
        
        -- Show coverage analysis
        if stats.manager and stats.manager.coverage_analysis then
            local analysis = stats.manager.coverage_analysis
            table.insert(output, "Coverage Analysis:")
            table.insert(output, "  Overall coverage score: " .. string.format("%.1f%%", analysis.coverage_score * 100))
            table.insert(output, "")
            
            -- Show gaps
            if #analysis.temperature_gaps > 0 then
                table.insert(output, "  Temperature gaps: " .. table.concat(analysis.temperature_gaps, ", "))
            else
                table.insert(output, "  Temperature coverage: ✓ Complete")
            end
            
            if #analysis.humidity_gaps > 0 then
                table.insert(output, "  Humidity gaps: " .. table.concat(analysis.humidity_gaps, ", "))
            else
                table.insert(output, "  Humidity coverage: ✓ Complete")
            end
            
            if #analysis.continentalness_gaps > 0 then
                table.insert(output, "  Continentalness gaps: " .. table.concat(analysis.continentalness_gaps, ", "))
            else
                table.insert(output, "  Continentalness coverage: ✓ Complete")
            end
            
            if #analysis.erosion_gaps > 0 then
                table.insert(output, "  Erosion gaps: " .. table.concat(analysis.erosion_gaps, ", "))
            else
                table.insert(output, "  Erosion coverage: ✓ Complete")
            end
            
            table.insert(output, "")
            
            -- Show recommendations
            if #analysis.recommendations > 0 then
                table.insert(output, "Recommendations:")
                for _, rec in ipairs(analysis.recommendations) do
                    table.insert(output, "  • " .. rec)
                end
            end
        end
        
        table.insert(output, "")
        
        -- Show parameter distribution
        if stats.manager then
            table.insert(output, "Parameter Distribution:")
            
            -- Temperature distribution
            table.insert(output, "  Temperature levels:")
            for level = 0, 4 do
                local count = stats.manager.by_temperature[level] or 0
                local level_name = ({"Frozen", "Cold", "Temperate", "Warm", "Hot"})[level + 1]
                table.insert(output, "    " .. level .. " (" .. level_name .. "): " .. count .. " biomes")
            end
            
            -- Humidity distribution
            table.insert(output, "  Humidity levels:")
            for level = 0, 4 do
                local count = stats.manager.by_humidity[level] or 0
                local level_name = ({"Arid", "Dry", "Neutral", "Humid", "Wet"})[level + 1]
                table.insert(output, "    " .. level .. " (" .. level_name .. "): " .. count .. " biomes")
            end
            
            -- Continentalness distribution
            table.insert(output, "  Continentalness types:")
            local cont_types = {"deep_ocean", "ocean", "coast", "near_inland", "mid_inland", "far_inland"}
            for _, cont_type in ipairs(cont_types) do
                local count = stats.manager.by_continentalness[cont_type] or 0
                table.insert(output, "    " .. cont_type .. ": " .. count .. " biomes")
            end
        end
        
        table.insert(output, "")
        
        -- Test biome selection with various parameters
        table.insert(output, "Biome Selection Tests:")
        
        local test_cases = {
            {name = "Temperate Plains", temp = 2, humid = 2, cont = "mid_inland", erosion = 5},
            {name = "Hot Desert", temp = 4, humid = 0, cont = "mid_inland", erosion = 5},
            {name = "Cold Tundra", temp = 0, humid = 1, cont = "far_inland", erosion = 4},
            {name = "Ocean", temp = 2, humid = 3, cont = "ocean", erosion = 6},
            {name = "Mountain", temp = 1, humid = 2, cont = "far_inland", erosion = 1}
        }
        
        for _, test in ipairs(test_cases) do
            local params = {
                temperature_level = test.temp,
                humidity_level = test.humid,
                continentalness_name = test.cont,
                erosion_level = test.erosion,
                pv_name = "mid",
                depth = 0,
                y = 64,
                x = 0,
                z = 0
            }
            
            local biome = voxelgen.biomes.manager.get_best_biome(params)
            if biome then
                table.insert(output, "  " .. test.name .. ": " .. biome.name .. 
                    (biome._selection_method and (" (" .. biome._selection_method .. ")") or ""))
            else
                table.insert(output, "  " .. test.name .. ": ✗ NO BIOME FOUND")
            end
        end
        
        return true, table.concat(output, "\n")
    end
})

-- Helper function to get table keys
if not table.keys then
    table.keys = function(t)
        local keys = {}
        for k, _ in pairs(t) do
            table.insert(keys, k)
        end
        return keys
    end
end