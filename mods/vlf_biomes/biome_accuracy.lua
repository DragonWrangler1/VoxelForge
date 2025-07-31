-- VLF Biomes - Enhanced Biome Placement Accuracy System
-- This module improves biome placement accuracy by adding additional constraints and smoothing

local biome_accuracy = {}

-- Enhanced biome selection with multiple passes and smoothing
function biome_accuracy.get_enhanced_biome(x, z, y, terrain_height)
    if not voxelgen or not voxelgen.api then
        return nil
    end
    
    -- Get base climate parameters
    local climate_params = voxelgen.api.get_biome_parameters(x, z, y, terrain_height)
    if not climate_params then
        return nil
    end
    
    -- Apply enhanced accuracy filters
    climate_params = biome_accuracy.apply_accuracy_filters(climate_params, x, z, y, terrain_height)
    
    -- Get biome using enhanced parameters
    local biome = voxelgen.get_best_biome(climate_params)
    
    -- Apply post-selection smoothing
    if biome then
        biome = biome_accuracy.apply_biome_smoothing(biome, x, z, y, terrain_height)
    end
    
    return biome
end

-- Apply accuracy filters to improve parameter calculation
function biome_accuracy.apply_accuracy_filters(params, x, z, y, terrain_height)
    local enhanced_params = table.copy(params)
    
    -- Enhanced continentalness calculation
    enhanced_params = biome_accuracy.enhance_continentalness(enhanced_params, x, z, y, terrain_height)
    
    -- Enhanced temperature calculation with better altitude effects
    enhanced_params = biome_accuracy.enhance_temperature(enhanced_params, x, z, y, terrain_height)
    
    -- Enhanced humidity calculation with orographic effects
    enhanced_params = biome_accuracy.enhance_humidity(enhanced_params, x, z, y, terrain_height)
    
    -- Enhanced erosion calculation with terrain analysis
    enhanced_params = biome_accuracy.enhance_erosion(enhanced_params, x, z, y, terrain_height)
    
    return enhanced_params
end

-- Enhanced continentalness with better ocean/land detection
function biome_accuracy.enhance_continentalness(params, x, z, y, terrain_height)
    local enhanced = table.copy(params)
    
    -- Sample surrounding terrain heights for better ocean detection
    local sample_radius = 32
    local ocean_count = 0
    local land_count = 0
    local samples = 0
    
    for dx = -sample_radius, sample_radius, 16 do
        for dz = -sample_radius, sample_radius, 16 do
            local sample_x, sample_z = x + dx, z + dz
            local sample_height = voxelgen.api.get_terrain_height_at(sample_x, sample_z)
            
            if sample_height then
                samples = samples + 1
                if sample_height < 0 then
                    ocean_count = ocean_count + 1
                else
                    land_count = land_count + 1
                end
            end
        end
    end
    
    if samples > 0 then
        local ocean_ratio = ocean_count / samples
        local land_ratio = land_count / samples
        
        -- Adjust continentalness based on surrounding terrain
        local adjustment = 0
        if ocean_ratio > 0.7 then
            -- Strongly oceanic area
            adjustment = -0.3
        elseif ocean_ratio > 0.4 then
            -- Coastal area
            adjustment = -0.15
        elseif land_ratio > 0.8 then
            -- Strongly continental area
            adjustment = 0.2
        end
        
        enhanced.continentalness = enhanced.continentalness + adjustment
        enhanced.continentalness = math.max(-1.2, math.min(1.0, enhanced.continentalness))
        
        -- Recalculate continentalness name
        local continentalness_name = voxelgen.api.get_parameter_level(
            enhanced.continentalness, 
            voxelgen.api.CONTINENTALNESS_LEVELS
        )
        enhanced.continentalness_name = continentalness_name
    end
    
    return enhanced
end

-- Enhanced temperature with better altitude and latitude effects
function biome_accuracy.enhance_temperature(params, x, z, y, terrain_height)
    local enhanced = table.copy(params)
    
    -- More realistic altitude effect (6.5°C per 1000m)
    local altitude_effect = 0
    if terrain_height > 64 then
        altitude_effect = -(terrain_height - 64) * 0.0065 -- More realistic lapse rate
    end
    
    -- Enhanced latitude effect (creates temperature bands)
    local latitude_effect = math.sin(z * 0.00005) * 0.3 -- Stronger latitude bands
    
    -- Seasonal variation (optional - could be time-based)
    local seasonal_effect = math.sin(x * 0.0001) * 0.1 -- Subtle seasonal-like variation
    
    -- Continental climate effect (inland areas have more extreme temperatures)
    local continental_effect = 0
    if enhanced.continentalness > 0.2 then
        continental_effect = enhanced.continentalness * 0.15 -- More extreme temperatures inland
    end
    
    -- Apply all temperature effects
    enhanced.temperature = enhanced.temperature + altitude_effect + latitude_effect + seasonal_effect + continental_effect
    enhanced.temperature = math.max(-1.0, math.min(1.0, enhanced.temperature))
    
    -- Recalculate temperature level
    local temperature_level = voxelgen.api.get_parameter_level(
        enhanced.temperature,
        voxelgen.api.TEMPERATURE_LEVELS
    )
    enhanced.temperature_level = temperature_level
    
    return enhanced
end

-- Enhanced humidity with orographic effects
function biome_accuracy.enhance_humidity(params, x, z, y, terrain_height)
    local enhanced = table.copy(params)
    
    -- Orographic effect - mountains create rain shadows
    local orographic_effect = biome_accuracy.calculate_orographic_effect(x, z, terrain_height)
    
    -- Enhanced continental effect
    local continental_effect = 0
    if enhanced.continentalness > 0 then
        continental_effect = enhanced.continentalness * 0.5 -- Stronger drying effect inland
    else
        continental_effect = enhanced.continentalness * 0.3 -- Humidity boost near water
    end
    
    -- Temperature-humidity interaction
    local temp_humidity_effect = 0
    if enhanced.temperature > 0.5 then -- Hot areas
        temp_humidity_effect = (enhanced.temperature - 0.5) * 0.2 -- Can hold more moisture
    elseif enhanced.temperature < -0.5 then -- Cold areas
        temp_humidity_effect = (enhanced.temperature + 0.5) * 0.3 -- Less moisture capacity
    end
    
    -- Apply humidity effects
    enhanced.humidity = enhanced.humidity + orographic_effect - continental_effect + temp_humidity_effect
    enhanced.humidity = math.max(-1.0, math.min(1.0, enhanced.humidity))
    
    -- Recalculate humidity level
    local humidity_level = voxelgen.api.get_parameter_level(
        enhanced.humidity,
        voxelgen.api.HUMIDITY_LEVELS
    )
    enhanced.humidity_level = humidity_level
    
    return enhanced
end

-- Calculate orographic (mountain) effects on humidity
function biome_accuracy.calculate_orographic_effect(x, z, terrain_height)
    local effect = 0
    local sample_distance = 64
    
    -- Check terrain heights in prevailing wind direction (assume west to east)
    local upwind_height = voxelgen.api.get_terrain_height_at(x - sample_distance, z) or terrain_height
    local downwind_height = voxelgen.api.get_terrain_height_at(x + sample_distance, z) or terrain_height
    
    -- If we're on the leeward (downwind) side of mountains, reduce humidity
    if upwind_height > terrain_height + 50 then
        effect = -0.2 -- Rain shadow effect
    elseif terrain_height > upwind_height + 50 then
        effect = 0.15 -- Windward side gets more moisture
    end
    
    return effect
end

-- Enhanced erosion calculation with terrain analysis
function biome_accuracy.enhance_erosion(params, x, z, y, terrain_height)
    local enhanced = table.copy(params)
    
    -- Calculate local terrain roughness
    local roughness = biome_accuracy.calculate_terrain_roughness(x, z, terrain_height)
    
    -- Adjust erosion based on terrain roughness
    local roughness_adjustment = 0
    if roughness > 30 then
        -- Very rough terrain - more mountainous
        roughness_adjustment = -0.2
    elseif roughness < 10 then
        -- Very smooth terrain - more flat
        roughness_adjustment = 0.2
    end
    
    enhanced.erosion = enhanced.erosion + roughness_adjustment
    enhanced.erosion = math.max(-1.0, math.min(1.0, enhanced.erosion))
    
    -- Recalculate erosion level
    local erosion_level = voxelgen.api.get_parameter_level(
        enhanced.erosion,
        voxelgen.api.EROSION_LEVELS
    )
    enhanced.erosion_level = erosion_level
    
    return enhanced
end

-- Calculate terrain roughness in the local area
function biome_accuracy.calculate_terrain_roughness(x, z, center_height)
    local sample_radius = 32
    local height_differences = {}
    local sample_count = 0
    
    for dx = -sample_radius, sample_radius, 8 do
        for dz = -sample_radius, sample_radius, 8 do
            if dx ~= 0 or dz ~= 0 then -- Skip center point
                local sample_height = voxelgen.api.get_terrain_height_at(x + dx, z + dz)
                if sample_height then
                    table.insert(height_differences, math.abs(sample_height - center_height))
                    sample_count = sample_count + 1
                end
            end
        end
    end
    
    if sample_count == 0 then
        return 0
    end
    
    -- Calculate average height difference (roughness)
    local total_difference = 0
    for _, diff in ipairs(height_differences) do
        total_difference = total_difference + diff
    end
    
    return total_difference / sample_count
end

-- Apply biome smoothing to reduce harsh transitions
function biome_accuracy.apply_biome_smoothing(biome, x, z, y, terrain_height)
    if not biome then
        return biome
    end
    
    -- Sample surrounding biomes
    local sample_radius = 16
    local biome_counts = {}
    local total_samples = 0
    
    for dx = -sample_radius, sample_radius, 8 do
        for dz = -sample_radius, sample_radius, 8 do
            if dx ~= 0 or dz ~= 0 then -- Skip center point
                local sample_x, sample_z = x + dx, z + dz
                local sample_height = voxelgen.api.get_terrain_height_at(sample_x, sample_z)
                
                if sample_height then
                    local sample_params = voxelgen.api.get_biome_parameters(sample_x, sample_z, y, sample_height)
                    if sample_params then
                        local sample_biome = voxelgen.get_best_biome(sample_params)
                        if sample_biome then
                            biome_counts[sample_biome.name] = (biome_counts[sample_biome.name] or 0) + 1
                            total_samples = total_samples + 1
                        end
                    end
                end
            end
        end
    end
    
    -- If the current biome is very rare in the surrounding area, consider switching
    if total_samples > 0 then
        local current_biome_count = biome_counts[biome.name] or 0
        local current_biome_ratio = current_biome_count / total_samples
        
        -- If current biome is less than 20% of surrounding area, consider the most common biome
        if current_biome_ratio < 0.2 then
            local most_common_biome = nil
            local highest_count = 0
            
            for biome_name, count in pairs(biome_counts) do
                if count > highest_count then
                    highest_count = count
                    most_common_biome = biome_name
                end
            end
            
            -- Switch to most common biome if it's significantly more common
            if most_common_biome and highest_count / total_samples > 0.4 then
                local registry = voxelgen.get_biome_registry()
                if registry then
                    local all_biomes = registry.get_all_biomes()
                    if all_biomes[most_common_biome] then
                        return all_biomes[most_common_biome]
                    end
                end
            end
        end
    end
    
    return biome
end

-- Utility function to copy tables
function table.copy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == "table" then
            copy[k] = table.copy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Initialize the enhanced biome accuracy system
function biome_accuracy.init()
    minetest.log("action", "[VLF Biomes] Enhanced biome placement accuracy system initialized")
    
    -- Override the default biome selection if possible
    if voxelgen and voxelgen.api then
        -- Store original function
        biome_accuracy.original_get_biome = voxelgen.api.get_biome_at
        
        -- Override with enhanced version
        voxelgen.api.get_biome_at = function(x, y, z)
            local terrain_height = voxelgen.api.get_terrain_height_at(x, z)
            if terrain_height then
                return biome_accuracy.get_enhanced_biome(x, z, y, terrain_height)
            else
                -- Fallback to original function
                return biome_accuracy.original_get_biome(x, y, z)
            end
        end
        
        minetest.log("action", "[VLF Biomes] Enhanced biome selection system activated")
    else
        minetest.log("warning", "[VLF Biomes] VoxelGen API not available, enhanced accuracy disabled")
    end
end

return biome_accuracy