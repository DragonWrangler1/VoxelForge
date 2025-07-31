-- climate.lua - Minecraft-style biome parameter system for VoxelGen
-- Provides temperature, humidity, continentalness, erosion, weirdness, and depth parameters

local climate = {}

-- Parameter level definitions (Minecraft-style)
climate.TEMPERATURE_LEVELS = {
	{min = -1.0, max = -0.45, level = 0}, -- Frozen
	{min = -0.45, max = -0.15, level = 1}, -- Cold
	{min = -0.15, max = 0.15, level = 2},   -- Temperate
	{min = 0.15, max = 0.45, level = 3},	-- Warm
	{min = 0.45, max = 1.0, level = 4}	 -- Hot (expanded range)
}

climate.HUMIDITY_LEVELS = {
	{min = -1.0, max = -0.35, level = 0}, -- Arid
	{min = -0.35, max = -0.1, level = 1}, -- Dry
	{min = -0.1, max = 0.1, level = 2},   -- Neutral
	{min = 0.1, max = 0.3, level = 3},	-- Humid
	{min = 0.3, max = 1.0, level = 4}	 -- Wet
}

climate.CONTINENTALNESS_LEVELS = {
	{min = -1.2, max = -1.05, name = "mushroom_fields"},
	{min = -1.05, max = -0.455, name = "deep_ocean"},
	{min = -0.455, max = -0.19, name = "ocean"},
	{min = -0.19, max = -0.11, name = "coast"},
	{min = -0.11, max = 0.03, name = "near_inland"},
	{min = 0.03, max = 0.3, name = "mid_inland"},
	{min = 0.3, max = 1.0, name = "far_inland"}
}

climate.EROSION_LEVELS = {
	{min = -1.0, max = -0.78, level = 0},   -- Most mountainous
	{min = -0.78, max = -0.375, level = 1},
	{min = -0.375, max = -0.2225, level = 2},
	{min = -0.2225, max = 0.05, level = 3},
	{min = 0.05, max = 0.45, level = 4},
	{min = 0.45, max = 0.55, level = 5},
	{min = 0.55, max = 1.0, level = 6}	  -- Most flat
}

climate.PV_LEVELS = {
	{min = -1.0, max = -0.85, name = "valleys"},
	{min = -0.85, max = -0.2, name = "low"},
	{min = -0.2, max = 0.2, name = "mid"},
	{min = 0.2, max = 0.7, name = "high"},
	{min = 0.7, max = 1.0, name = "peaks"}
}

-- Noise objects for parameter generation
climate.noise_objects = {}
climate.initialized = false

-- Initialize climate noise with world seed
function climate.init(world_seed)
	if climate.initialized then
		minetest.log("info", "[VoxelGen] Climate already initialized, skipping")
		return
	end

	minetest.log("info", "[VoxelGen] Initializing climate system with seed: " .. tostring(world_seed))
	climate.world_seed = world_seed

	-- Get reference to the API noise objects (shared with terrain generation)
	local api = voxelgen and voxelgen.api
	if not api then
		-- Fallback: load API directly
		local modpath = minetest.get_modpath("voxelgen")
		if modpath then
			api = dofile(modpath .. "/api.lua")
			minetest.log("info", "[VoxelGen] Loaded API directly for climate initialization")
		else
			minetest.log("error", "[VoxelGen] Cannot find VoxelGen mod path!")
			return
		end
	end

	-- Ensure API noise is initialized
	if not api.noise_objects or not api.noise_objects.continental then
		minetest.log("info", "[VoxelGen] Initializing API noise for climate system")
		api.init_noise(world_seed)
	end

	-- Verify API noise objects exist
	if not api.noise_objects.continental then
		minetest.log("error", "[VoxelGen] API continental noise not available!")
		return
	end

	-- Reference the existing terrain noises for climate parameters
	climate.noise_objects = {
		-- Use existing terrain noises
		continentalness = api.noise_objects.continental,
		erosion = api.noise_objects.erosion,
		peaks = api.noise_objects.peaks,

		-- Use existing climate noises (but normalize them to -1 to 1 range)
		temperature = api.noise_objects.heat,
		humidity = api.noise_objects.humidity,

		-- Add weirdness noise (new for biome variants)
		weirdness = minetest.get_perlin({
			offset = 0, scale = 1, spread = {x=400, y=400, z=400},
			seed = world_seed + 701, octaves = 6, persist = 0.5
		})
	}

	climate.initialized = true
	minetest.log("action", "[VoxelGen] Climate system initialized with shared terrain noises, seed: " .. world_seed)
end

-- Helper function to get parameter level from value and level table
function climate.get_parameter_level(value, level_table)
	for _, level_info in ipairs(level_table) do
		if value >= level_info.min and value <= level_info.max then
			return level_info.level or level_info.name, level_info
		end
	end
	-- Fallback to closest level
	if value < level_table[1].min then
		return level_table[1].level or level_table[1].name, level_table[1]
	else
		local last = level_table[#level_table]
		return last.level or last.name, last
	end
end

-- Advanced terrain classification using multiple noise layers
function climate.classify_terrain_advanced(x, z, terrain_height)
	if not climate.noise_objects.continentalness then
		return {type = "unknown", confidence = 0}
	end

	local continentalness = climate.noise_objects.continentalness:get_2d({x=x, y=z})
	local erosion = climate.noise_objects.erosion:get_2d({x=x, y=z})
	local peaks = climate.noise_objects.peaks:get_2d({x=x, y=z})
	local weirdness = climate.noise_objects.weirdness:get_2d({x=x, y=z})

	-- Calculate terrain type with confidence scores
	local terrain_scores = {
		deep_ocean = 0,
		ocean = 0,
		coast = 0,
		plains = 0,
		hills = 0,
		mountains = 0
	}

	-- Deep ocean: very negative continentalness + low terrain height
	if continentalness < -0.6 and terrain_height < -20 then
		terrain_scores.deep_ocean = 0.9 + math.min(0.1, (-continentalness - 0.6) * 0.5)
	end

	-- Ocean: negative continentalness + low terrain height
	if continentalness < -0.2 and terrain_height < 10 then
		terrain_scores.ocean = 0.7 + math.min(0.2, (-continentalness - 0.2) * 0.4)
	end

	-- Coast: near-zero continentalness + moderate terrain height
	if continentalness >= -0.3 and continentalness <= 0.1 and terrain_height >= -5 and terrain_height <= 30 then
		terrain_scores.coast = 0.8 - math.abs(continentalness + 0.1) * 2
	end

	-- Plains: positive continentalness + flat erosion + moderate height
	if continentalness > 0.0 and erosion > 0.2 and terrain_height > 20 and terrain_height < 120 then
		terrain_scores.plains = 0.6 + math.min(0.3, continentalness * 0.5) + math.min(0.1, erosion * 0.2)
	end

	-- Hills: moderate continentalness + moderate erosion + moderate peaks
	if continentalness > -0.1 and erosion > -0.2 and erosion < 0.4 and peaks > -0.2 and peaks < 0.4 then
		terrain_scores.hills = 0.5 + math.min(0.2, peaks * 0.5) + math.min(0.1, continentalness * 0.3)
	end

	-- Mountains: high peaks or low erosion + high terrain
	if (peaks > 0.3 or erosion < -0.3) and terrain_height > 80 then
		terrain_scores.mountains = 0.7 + math.min(0.2, peaks * 0.4) + math.min(0.1, (-erosion) * 0.2)
	end

	-- Find the terrain type with highest score
	local best_type = "plains"
	local best_score = 0
	for terrain_type, score in pairs(terrain_scores) do
		if score > best_score then
			best_score = score
			best_type = terrain_type
		end
	end

	return {
		type = best_type,
		confidence = best_score,
		scores = terrain_scores,
		raw_values = {
			continentalness = continentalness,
			erosion = erosion,
			peaks = peaks,
			terrain_height = terrain_height
		}
	}
end

-- Calculate PV (peaks and valleys) from weirdness
function climate.calculate_pv(weirdness)
	return 1 - math.abs((3 * math.abs(weirdness)) - 2)
end

-- Get all biome parameters for a position
function climate.get_biome_parameters(x, z, y, terrain_height)
	if not climate.noise_objects.temperature then
		minetest.log("warning", "[VoxelGen] Climate not initialized!")
		return {
			temperature = 0, temperature_level = 2,
			humidity = 0, humidity_level = 2,
			continentalness = 0, continentalness_name = "near_inland",
			erosion = 0, erosion_level = 3,
			weirdness = 0, pv = 0, pv_name = "mid",
			depth = math.max(0, (terrain_height - y) * 0.0078125)
		}
	end

	-- Get raw noise values and normalize them to -1.0 to 1.0 range
	local temperature_raw = climate.noise_objects.temperature:get_2d({x=x, y=z})
	local humidity_raw = climate.noise_objects.humidity:get_2d({x=x, y=z})
	local continentalness_raw = climate.noise_objects.continentalness:get_2d({x=x, y=z})
	local erosion_raw = climate.noise_objects.erosion:get_2d({x=x, y=z})
	local weirdness_raw = climate.noise_objects.weirdness:get_2d({x=x, y=z})

	-- Improve continentalness calculation to reduce edge cases
	-- Apply terrain height influence to continentalness (very low areas should be more oceanic)
	local continentalness_adjusted = continentalness_raw
	if terrain_height < -10 then -- Below sea level
		local depth_factor = math.min(0.4, (10 + terrain_height) * -0.025) -- Stronger oceanic bias
		continentalness_adjusted = continentalness_adjusted - depth_factor
	elseif terrain_height > 100 then -- High elevations should be more continental
		local height_factor = math.min(0.3, (terrain_height - 100) * 0.0015) -- Stronger continental bias
		continentalness_adjusted = continentalness_adjusted + height_factor
	end

	-- Apply erosion-based adjustments (low erosion = more mountainous = more continental)
	if erosion_raw < -0.2 then -- Mountainous areas
		local mountain_continental_boost = (-0.2 - erosion_raw) * 0.15
		continentalness_adjusted = continentalness_adjusted + mountain_continental_boost
	end

	-- Clamp adjusted continentalness
	continentalness_adjusted = math.max(-1.2, math.min(1.0, continentalness_adjusted))

	-- Temperature and humidity noise now generate values directly in -1 to 1 range
	-- No normalization needed, just clamp to ensure valid range
	local temperature_normalized = math.max(-1, math.min(1, temperature_raw))
	local humidity_normalized = math.max(-1, math.min(1, humidity_raw))

	-- continentalness_raw, erosion_raw are already in -1 to 1 range
	-- weirdness_raw is already in -1 to 1 range

	-- Simplified temperature calculation - just use the temperature noise directly
	local temperature = temperature_normalized

	-- Only apply minimal altitude effect for realism
	if terrain_height > 100 then
		local altitude_effect = -(terrain_height - 100) * 0.001 -- Very minimal cooling at high altitude
		temperature = temperature + altitude_effect
	end

	-- Clamp temperature to valid range
	temperature = math.max(-1.0, math.min(1.0, temperature))

	-- Simplified humidity calculation - just use the humidity noise directly with minimal continental effect
	local humidity = humidity_normalized

	-- Apply basic continentalness effect (inland areas are drier)
	if continentalness_adjusted > 0.2 then -- Only affect significantly inland areas
		local continental_effect = (continentalness_adjusted - 0.2) * 0.3 -- Moderate drying effect
		humidity = humidity - continental_effect
	end

	-- Clamp humidity to valid range
	humidity = math.max(-1.0, math.min(1.0, humidity))

	-- Calculate PV from weirdness
	local pv = climate.calculate_pv(weirdness_raw)

	-- Calculate depth parameter
	local depth = math.max(0, (terrain_height - y) * 0.0078125)

	-- Get parameter levels
	local temperature_level, temp_info = climate.get_parameter_level(temperature, climate.TEMPERATURE_LEVELS)
	local humidity_level, humid_info = climate.get_parameter_level(humidity, climate.HUMIDITY_LEVELS)
	local continentalness_name, cont_info = climate.get_parameter_level(continentalness_adjusted, climate.CONTINENTALNESS_LEVELS)
	local erosion_level, erosion_info = climate.get_parameter_level(erosion_raw, climate.EROSION_LEVELS)
	local pv_name, pv_info = climate.get_parameter_level(pv, climate.PV_LEVELS)

	-- Debug logging for temperature issues (only log occasionally to avoid spam)
	if math.random() < 0.001 then -- Log ~0.1% of calls
		minetest.log("info", "[VoxelGen Climate] Debug sample at (" .. x .. "," .. z .. "): " ..
			"temp_raw=" .. string.format("%.2f", temperature_raw) ..
			", temp_norm=" .. string.format("%.2f", temperature_normalized) ..
			", temp_final=" .. string.format("%.2f", temperature) ..
			", temp_level=" .. temperature_level)
	end

	return {
		-- Raw values
		temperature = temperature,
		humidity = humidity,
		continentalness = continentalness_adjusted, -- Use adjusted value
		erosion = erosion_raw,
		weirdness = weirdness_raw,
		pv = pv,
		depth = depth,

		-- Levels/categories
		temperature_level = temperature_level,
		humidity_level = humidity_level,
		continentalness_name = continentalness_name,
		erosion_level = erosion_level,
		pv_name = pv_name,

		-- Additional info
		temp_info = temp_info,
		humid_info = humid_info,
		cont_info = cont_info,
		erosion_info = erosion_info,
		pv_info = pv_info
	}
end

-- Backward compatibility functions that convert Minecraft-style parameters to traditional values

-- Get temperature at specific position and elevation (backward compatibility)
function climate.get_temperature(x, z, y, terrain_height)
	local params = climate.get_biome_parameters(x, z, y, terrain_height)

	-- Convert temperature parameter (-1.0 to 1.0) to Celsius-like values
	-- Level 0 (-1.0 to -0.45): -10°C to 5°C (frozen)
	-- Level 1 (-0.45 to -0.15): 5°C to 12°C (cold)
	-- Level 2 (-0.15 to 0.2): 12°C to 20°C (temperate)
	-- Level 3 (0.2 to 0.55): 20°C to 28°C (warm)
	-- Level 4 (0.55 to 1.0): 28°C to 40°C (hot)

	local temp_celsius = (params.temperature + 1) * 25 - 10 -- Maps -1..1 to -10..40
	return temp_celsius
end

-- Get humidity at specific position and elevation (backward compatibility)
function climate.get_humidity(x, z, y, terrain_height)
	local params = climate.get_biome_parameters(x, z, y, terrain_height)

	-- Convert humidity parameter (-1.0 to 1.0) to percentage values
	-- Level 0 (-1.0 to -0.35): 0% to 25% (arid)
	-- Level 1 (-0.35 to -0.1): 25% to 40% (dry)
	-- Level 2 (-0.1 to 0.1): 40% to 60% (neutral)
	-- Level 3 (0.1 to 0.3): 60% to 75% (humid)
	-- Level 4 (0.3 to 1.0): 75% to 100% (wet)

	local humidity_percent = (params.humidity + 1) * 50 -- Maps -1..1 to 0..100
	return math.max(0, math.min(100, humidity_percent))
end

-- Get climate classification at position
function climate.get_climate_type(x, z, y, terrain_height)
	local temp = climate.get_temperature(x, z, y, terrain_height)
	local humidity = climate.get_humidity(x, z, y, terrain_height)

	-- Simplified Köppen climate classification
	if temp < -3 then
		if humidity > 60 then
			return "polar_wet"
		else
			return "polar_dry"
		end
	elseif temp < 18 then
		if humidity > 70 then
			return "temperate_wet"
		elseif humidity > 40 then
			return "temperate_moderate"
		else
			return "temperate_dry"
		end
	else
		if humidity > 80 then
			return "tropical_wet"
		elseif humidity > 50 then
			return "tropical_moderate"
		else
			return "tropical_dry"
		end
	end
end

-- Generate climate maps for a chunk
function climate.generate_maps(minp, maxp, terrain_heightmap)
	local size_x = maxp.x - minp.x + 1
	local size_z = maxp.z - minp.z + 1

	local temperature_map = {}
	local humidity_map = {}
	local climate_map = {}

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local idx = (z - minp.z) * size_x + (x - minp.x + 1)
			local terrain_height = terrain_heightmap and terrain_heightmap[idx] or 0

			temperature_map[idx] = climate.get_temperature(x, z, terrain_height, terrain_height)
			humidity_map[idx] = climate.get_humidity(x, z, terrain_height, terrain_height)
			climate_map[idx] = climate.get_climate_type(x, z, terrain_height, terrain_height)
		end
	end

	return temperature_map, humidity_map, climate_map
end

-- Debug function to get climate info at position
function climate.get_debug_info(x, z, y)
	local terrain_height = y -- Simplified for debug
	local temp = climate.get_temperature(x, z, y, terrain_height)
	local humidity = climate.get_humidity(x, z, y, terrain_height)
	local climate_type = climate.get_climate_type(x, z, y, terrain_height)
	local params = climate.get_biome_parameters(x, z, y, terrain_height)

	return {
		-- Traditional values (backward compatibility)
		temperature = temp,
		humidity = humidity,
		climate_type = climate_type,

		-- Minecraft-style parameters
		parameters = params
	}
end

return climate