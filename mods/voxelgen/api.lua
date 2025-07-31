-- api.lua - VoxelGen API
-- Provides a clean interface for terrain generation, biome management, and climate systems
--
-- EXTERNAL MOD USAGE:
-- To register biomes from other mods, use:
--   voxelgen.api.register_biome(biome_def)
--   voxelgen.api.create_biome_def(name, parameters, nodes, properties)
--
-- To query biomes:
--   voxelgen.api.get_registered_biomes()
--   voxelgen.api.is_biome_registered(biome_name)
--   voxelgen.api.get_biome_at(x, y, z, terrain_height, world_seed)

local api = {}

-- Constants
api.SEA_LEVEL = 0
api.MIN_CAVE_Y = -60
api.MAX_CAVE_Y = 50

-- Spline definitions for terrain generation
-- Designed for height range from -50 to 290 with better low-level plains support
api.splines = {
	continentalness = {
		{-1.2, api.SEA_LEVEL + 15}, {-1.1, api.SEA_LEVEL + 7},
		{-1.0, api.SEA_LEVEL - 30}, {-0.8, api.SEA_LEVEL - 30}, {-0.5, api.SEA_LEVEL - 15},
		{-0.2, api.SEA_LEVEL - 5}, {0.0, api.SEA_LEVEL + 2}, {0.2, api.SEA_LEVEL + 8},
		{0.4, api.SEA_LEVEL + 12}, {0.7, api.SEA_LEVEL + 18}, {1.0, api.SEA_LEVEL + 25},
	},
	erosion = {
		{-1.0, 35}, {-0.6, 18}, {-0.2, 5}, {0.0, 0}, {0.3, -8}, {0.6, -18}, {1.0, -20},
	},
	peaks = {
		{-1.0, -35}, {-0.6, -20}, {-0.3, -8}, {-0.1, -3}, {0.0, 0},
		{0.1, 5}, {0.3, 15}, {0.5, 30}, {0.7, 50}, {1.0, 75},
	},
	jagged_mountains = {
		{-1.0, 0}, {-0.6, 0}, {-0.3, 0}, {-0.1, 0}, {0.0, 0}, {0.2, 0},
		{0.4, 0},
		{0.45, 0},
		{0.5, 12}, {0.52, 11},   -- dip
		{0.55, 25}, {0.57, 24},  -- dip
		{0.6, 38}, {0.62, 37},   -- dip
		{0.65, 50}, {0.67, 49},  -- dip
		{0.7, 60},
		{0.72, 60}, {0.74, 60}, {0.77, 60}, -- plateau
		{0.8, 78}, {0.82, 77},   -- dip
		{0.85, 96}, {0.87, 95},  -- dip
		{0.9, 115}, {0.92, 114}, -- dip
		{0.95, 135}, {0.97, 134},-- dip
		{1.0, 150},
	},
}

-- Noise parameter templates
api.noise_params = {
	continental = {
		offset = 0, scale = 1, spread = {x=2000, y=2000, z=2000},
		octaves = 2, persist = 0.5
	},
	peaks = {
		offset = 0, scale = 1, spread = {x=512, y=512, z=512},
		octaves = 6, persist = 0.6
	},
	erosion = {
		offset = 0, scale = 1, spread = {x=1024, y=1024, z=1024},
		octaves = 3, persist = 0.6
	},
	jagged_mountains = {
		offset = 0, scale = 1, spread = {x=3072, y=3072, z=3072},
		octaves = 5, persist = 0.75
	},
	mountain_ridges = {
		offset = 0, scale = 1, spread = {x=256, y=256, z=256},
		octaves = 3, persist = 0.7
	},
	small_scale = {
		offset = 0, scale = 1, spread = {x=64, y=64, z=64},
		octaves = 5, persist = 0.6
	},
	density = {
		offset = 0, scale = 1.5, spread = {x=80, y=48, z=80},
		octaves = 8, persist = 0.45
	},
	weirdness = {
		offset = 0, scale = 1, spread = {x=400, y=400, z=400},
		octaves = 6, persist = 0.5
	},

	-- Climate noise parameters - Balanced temperature and humidity regions
	-- Adjusted temperature offset to make hot biomes more common
	heat = {
		offset = 0.15, scale = 1, spread = {x=2800, y=2800, z=2800},
		octaves = 2, persist = 0.5
	},
	humidity = {
		offset = 0, scale = 1, spread = {x=2500, y=2500, z=2500},
		octaves = 2, persist = 0.5
	},
	-- Enhanced 3D terrain character noise for better variation
	terrain_character = {
		offset = 0, scale = 1.2, spread = {x=28, y=20, z=28},
		octaves = 5, persist = 0.35
	},

	-- River generation noise
	river_network = {
		offset = 0, scale = 1, spread = {x=3072, y=3072, z=3072},
		octaves = 3, persist = 0.4
	},
	river_width = {
		offset = 0, scale = 1, spread = {x=768, y=768, z=768},
		octaves = 2, persist = 0.4
	},
	canyon = {
		offset = 0, scale = 1, spread = {x=32, y=24, z=32},
		octaves = 3, persist = 0.5
	},

}

-- Noise objects (initialized on first use)
api.noise_objects = {}

-- Cache system for smooth transitions
api.cache = {
	noise_params_hash = nil,
	biomes_hash = nil,
	previous_noise_objects = {},
	previous_biomes = {},
	transition_active = false,
	transition_radius = 80, -- blocks
	chunk_generation_count = 0
}

-- Heightmap cache system for HUD access
api.heightmap_cache = {
	chunks = {}, -- [chunk_key] = {heightmap, minp, maxp, timestamp}
	max_cache_size = 50, -- Maximum number of cached chunks
	cache_timeout = 300, -- Cache timeout in seconds (5 minutes)
}

-- Generate hash for noise parameters to detect changes
function api.hash_noise_params()
	local hash_string = ""
	for name, params in pairs(api.noise_params) do
		hash_string = hash_string .. name .. ":"
		for k, v in pairs(params) do
			if type(v) == "table" then
				hash_string = hash_string .. k .. "(" .. v.x .. "," .. v.y .. "," .. v.z .. ")"
			else
				hash_string = hash_string .. k .. v
			end
		end
		hash_string = hash_string .. ";"
	end
	return minetest.sha1(hash_string)
end

-- Generate hash for biome definitions to detect changes
function api.hash_biomes()
	if not voxelgen or not voxelgen.biomes then
		return "no_biomes"
	end

	local biomes = voxelgen.biomes.get_registered_biomes()
	local hash_string = ""

	for name, biome in pairs(biomes) do
		hash_string = hash_string .. name .. ":"
		-- Hash key biome properties that affect terrain generation
		if biome.parameters then
			for k, v in pairs(biome.parameters) do
				hash_string = hash_string .. k .. tostring(v)
			end
		end
		hash_string = hash_string .. ";"
	end

	return minetest.sha1(hash_string)
end

-- Check if parameters have changed and setup transition if needed
function api.check_for_changes(world_seed)
	local current_noise_hash = api.hash_noise_params()
	local current_biomes_hash = api.hash_biomes()

	local noise_changed = api.cache.noise_params_hash and api.cache.noise_params_hash ~= current_noise_hash
	local biomes_changed = api.cache.biomes_hash and api.cache.biomes_hash ~= current_biomes_hash

	if noise_changed or biomes_changed then
		minetest.log("action", "[VoxelGen API] Detected changes - setting up smooth transition")

		-- Store previous noise objects for interpolation
		api.cache.previous_noise_objects = {}
		for name, noise_obj in pairs(api.noise_objects) do
			api.cache.previous_noise_objects[name] = noise_obj
		end

		-- Store previous biomes
		if voxelgen and voxelgen.biomes then
			api.cache.previous_biomes = voxelgen.biomes.get_registered_biomes()
		end

		-- Activate transition mode
		api.cache.transition_active = true
		api.cache.chunk_generation_count = 0

		minetest.log("action", "[VoxelGen API] Transition activated - will interpolate over " .. api.cache.transition_radius .. " blocks")
	end

	-- Update hashes
	api.cache.noise_params_hash = current_noise_hash
	api.cache.biomes_hash = current_biomes_hash
end

-- Calculate transition weight based on distance from transition start
function api.get_transition_weight(x, z)
	if not api.cache.transition_active then
		return 1.0 -- Use new values fully
	end

	-- Simple distance-based transition - could be enhanced with chunk-based logic
	local generation_progress = api.cache.chunk_generation_count / 10 -- Transition over ~10 chunks
	local distance_factor = math.min(1.0, generation_progress)

	-- Use fancy interpolation for smooth transition
	return api.fancy_interp(distance_factor, 0.0, 1.0, nil, x, z)
end

-- Get interpolated noise value between old and new
function api.get_interpolated_noise_2d(noise_name, pos, world_seed)
	local new_noise = api.noise_objects[noise_name]
	if not new_noise then
		return 0
	end

	local new_value = new_noise:get_2d(pos)

	if not api.cache.transition_active or not api.cache.previous_noise_objects[noise_name] then
		return new_value
	end

	local old_noise = api.cache.previous_noise_objects[noise_name]
	local old_value = old_noise:get_2d(pos)

	local weight = api.get_transition_weight(pos.x, pos.y)
	return api.lerp(old_value, new_value, weight)
end

-- Get interpolated 3D noise value
function api.get_interpolated_noise_3d(noise_name, pos, world_seed)
	local new_noise = api.noise_objects[noise_name]
	if not new_noise then
		return 0
	end

	local new_value = new_noise:get_3d(pos)

	if not api.cache.transition_active or not api.cache.previous_noise_objects[noise_name] then
		return new_value
	end

	local old_noise = api.cache.previous_noise_objects[noise_name]
	local old_value = old_noise:get_3d(pos)

	local weight = api.get_transition_weight(pos.x, pos.z)
	return api.lerp(old_value, new_value, weight)
end

-- Get interpolated biome at position (handles biome definition changes)
function api.get_interpolated_biome_at(x, y, z, terrain_height, world_seed)
	-- If no transition is active, use current biome system
	if not api.cache.transition_active then
		return api.get_biome_at(x, y, z, terrain_height, world_seed)
	end

	-- During transition, we need to blend between old and new biome selections
	-- This is more complex than noise interpolation since biomes are discrete
	local weight = api.get_transition_weight(x, z)

	-- Get current biome
	local current_biome = api.get_biome_at(x, y, z, terrain_height, world_seed)

	-- If weight is high enough (> 0.7), use new biome fully
	if weight > 0.7 then
		return current_biome
	end

	-- For transition zones, we could implement biome blending logic here
	-- For now, we'll use a simple threshold approach
	if weight > 0.3 then
		-- Use some randomness to create natural biome boundaries
		local hash = ((x * 73856093 + z * 19349663 + world_seed * 83492791) % 2147483647) / 2147483647
		if hash < weight then
			return current_biome
		end
	end

	-- For areas with low weight, try to maintain previous biome characteristics
	-- This is a simplified approach - in practice, you might want more sophisticated blending
	return current_biome
end

-- Enhanced biome registration that triggers change detection
function api.register_biome_with_transition(biome_def)
	local success = api.register_biome(biome_def)

	if success then
		-- Force a check for changes on next terrain generation
		api.cache.biomes_hash = nil
		minetest.log("action", "[VoxelGen API] Biome registered with transition support: " .. biome_def.name)
	end

	return success
end

-- Initialize noise objects with world seed
function api.init_noise(world_seed)
	-- Check for changes before initializing new noise objects
	api.check_for_changes(world_seed)

	for name, params in pairs(api.noise_params) do
		local seed_offset = {
			continental = 101, peaks = 103, erosion = 111, jagged_mountains = 117,
			mountain_ridges = 119, small_scale = 107, density = 9999, weirdness = 701,
			heat = 201, humidity = 203,
			terrain_character = 301, river_network = 401, river_width = 403, canyon = 405
		}

		local noise_params = {}
		for k, v in pairs(params) do
			noise_params[k] = v
		end
		noise_params.seed = world_seed + (seed_offset[name] or 0)
		api.noise_objects[name] = minetest.get_perlin(noise_params)
	end
end

-- Heightmap cache management functions
function api.get_chunk_key(minp, maxp)
	return string.format("%d,%d,%d,%d", minp.x, minp.z, maxp.x, maxp.z)
end

function api.cache_heightmap(minp, maxp, heightmap)
	local chunk_key = api.get_chunk_key(minp, maxp)
	local timestamp = minetest.get_us_time() / 1000000 -- Convert to seconds

	-- Clean old cache entries if cache is getting too large
	if api.count_cache_entries() >= api.heightmap_cache.max_cache_size then
		api.cleanup_heightmap_cache()
	end

	api.heightmap_cache.chunks[chunk_key] = {
		heightmap = heightmap,
		minp = {x = minp.x, y = minp.y, z = minp.z},
		maxp = {x = maxp.x, y = maxp.y, z = maxp.z},
		timestamp = timestamp
	}
end

function api.count_cache_entries()
	local count = 0
	for _ in pairs(api.heightmap_cache.chunks) do
		count = count + 1
	end
	return count
end

function api.cleanup_heightmap_cache()
	local current_time = minetest.get_us_time() / 1000000
	local entries_to_remove = {}

	-- Find expired entries
	for chunk_key, cache_entry in pairs(api.heightmap_cache.chunks) do
		if current_time - cache_entry.timestamp > api.heightmap_cache.cache_timeout then
			table.insert(entries_to_remove, chunk_key)
		end
	end

	-- Remove expired entries
	for _, chunk_key in ipairs(entries_to_remove) do
		api.heightmap_cache.chunks[chunk_key] = nil
	end

	-- If still too many entries, remove oldest ones
	if api.count_cache_entries() >= api.heightmap_cache.max_cache_size then
		local entries_by_time = {}
		for chunk_key, cache_entry in pairs(api.heightmap_cache.chunks) do
			table.insert(entries_by_time, {key = chunk_key, timestamp = cache_entry.timestamp})
		end

		-- Sort by timestamp (oldest first)
		table.sort(entries_by_time, function(a, b) return a.timestamp < b.timestamp end)

		-- Remove oldest entries until we're under the limit
		local entries_to_keep = math.floor(api.heightmap_cache.max_cache_size * 0.8) -- Keep 80% of max
		for i = 1, #entries_by_time - entries_to_keep do
			api.heightmap_cache.chunks[entries_by_time[i].key] = nil
		end
	end
end

function api.get_terrain_height_at(x, z)
	-- First, try to find the height in cached chunks
	for chunk_key, cache_entry in pairs(api.heightmap_cache.chunks) do
		local minp, maxp = cache_entry.minp, cache_entry.maxp

		-- Check if the point is within this cached chunk
		if x >= minp.x and x <= maxp.x and z >= minp.z and z <= maxp.z then
			local size_x = maxp.x - minp.x + 1
			local idx = (z - minp.z) * size_x + (x - minp.x + 1)

			if cache_entry.heightmap[idx] then
				return cache_entry.heightmap[idx]
			end
		end
	end

	-- If not found in cache, generate heightmap for a small area around the point
	local radius = 8 -- Generate 16x16 area around the point
	local minp = {x = x - radius, y = 0, z = z - radius}
	local maxp = {x = x + radius, y = 0, z = z + radius}

	local heightmap, jagged_mask = api.generate_heightmap(minp, maxp, voxelgen.mapgen and voxelgen.mapgen.world_seed or 12345)
	local size_x = maxp.x - minp.x + 1
	local size_z = maxp.z - minp.z + 1

	-- Apply erosion to match the final terrain
	--api.thermal_erosion_selective(heightmap, jagged_mask, size_x, size_z, 8, 2.5)
	--api.hydraulic_erosion(heightmap, size_x, size_z, 20)

	-- Rivers are now carved directly in generate_heightmap

	-- Cache the generated heightmap
	api.cache_heightmap(minp, maxp, heightmap)

	-- Return the height at the requested position
	local idx = (z - minp.z) * size_x + (x - minp.x + 1)
	return heightmap[idx] or 0
end

function api.get_heightmap_area(minp, maxp)
	-- Try to find overlapping cached chunks first
	local cached_heights = {}
	local missing_points = {}

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local found = false

			-- Check all cached chunks for this point
			for chunk_key, cache_entry in pairs(api.heightmap_cache.chunks) do
				local c_minp, c_maxp = cache_entry.minp, cache_entry.maxp

				if x >= c_minp.x and x <= c_maxp.x and z >= c_minp.z and z <= c_maxp.z then
					local size_x = c_maxp.x - c_minp.x + 1
					local idx = (z - c_minp.z) * size_x + (x - c_minp.x + 1)

					if cache_entry.heightmap[idx] then
						cached_heights[x .. "," .. z] = cache_entry.heightmap[idx]
						found = true
						break
					end
				end
			end

			if not found then
				table.insert(missing_points, {x = x, z = z})
			end
		end
	end

	-- If we have all points cached, return them
	if #missing_points == 0 then
		local result = {}
		local size_x = maxp.x - minp.x + 1

		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				local idx = (z - minp.z) * size_x + (x - minp.x + 1)
				result[idx] = cached_heights[x .. "," .. z]
			end
		end

		return result
	end

	-- Otherwise, generate the full heightmap and cache it
	local heightmap, jagged_mask = api.generate_heightmap(minp, maxp, voxelgen.mapgen and voxelgen.mapgen.world_seed or 12345)
	local size_x = maxp.x - minp.x + 1
	local size_z = maxp.z - minp.z + 1

	-- Apply erosion to match the final terrain
	api.thermal_erosion_selective(heightmap, jagged_mask, size_x, size_z, 8, 2.5)
	api.hydraulic_erosion(heightmap, size_x, size_z, 20)

	-- Rivers are now carved directly in generate_heightmap

	-- Cache the generated heightmap
	api.cache_heightmap(minp, maxp, heightmap)

	return heightmap
end

-- Interpolation functions
function api.smoothstep(t)
	return t * t * (3 - 2 * t)
end

function api.lerp(a, b, t)
	return a + (b - a) * t
end

function api.fancy_interp(t, low, high, seed, x, z)
	t = math.max(0, math.min(1, t))
	local smooth_t = api.smoothstep(t)

	local wobble = math.sin(t * 25 + math.sin(t * 9)) * 0.01

	if seed and x and z then
		local hash1 = ((x * 73856093 + z * 19349663 + seed * 83492791) % 2147483647) / 2147483647
		local hash2 = ((x * 19349663 + z * 83492791 + seed * 73856093) % 2147483647) / 2147483647
		local hash3 = ((x * 83492791 + z * 73856093 + seed * 19349663) % 2147483647) / 2147483647

		local rng1 = hash1 * 2.0 - 1.0
		local rng2 = hash2 * 2.0 - 1.0
		local rng3 = hash3 * 2.0 - 1.0

		local freq_adjust1 = math.sin(t * 15 + rng1 * 3.14159) * 0.025 * rng2
		local freq_adjust2 = math.sin(t * 35 + rng2 * 6.28318) * 0.015 * rng3
		local freq_adjust3 = math.sin(t * 8 + rng3 * 1.57079) * 0.035 * rng1

		local curve_warp = (rng1 * 0.08) * (t * (1 - t))

		wobble = wobble + freq_adjust1 + freq_adjust2 + freq_adjust3 + curve_warp

		if math.abs(rng1) > 0.85 and math.abs(rng2) > 0.75 then
			local dramatic_shift = rng3 * 0.12 * math.sin(t * 3.14159)
			wobble = wobble + dramatic_shift
		end
	end

	local interp = math.max(0, math.min(1, smooth_t + wobble))
	return api.lerp(low, high, interp)
end

function api.spline_map(v, points, seed, x, z)
	v = math.max(-1, math.min(1, v))
	for i = 1, #points - 1 do
		local p1 = points[i]
		local p2 = points[i + 1]
		if v >= p1[1] and v <= p2[1] then
			local t = (v - p1[1]) / (p2[1] - p1[1])
			return api.fancy_interp(t, p1[2], p2[2], seed, x, z)
		end
	end
	return points[#points][2]
end

-- Calculate peaks and valleys from weirdness
function api.calculate_peaks_valleys(weirdness)
	-- Formula: 1 - |(3|weirdness|) - 2|
	local abs_weirdness = math.abs(weirdness)
	local inner = (3 * abs_weirdness) - 2
	return 1 - math.abs(inner)
end

-- Calculate 3D density with height bias and base height
function api.calculate_density_with_bias(x, y, z, base_height, height_bias)
	if not api.noise_objects.density then
		return 0
	end

	-- Get raw 3D density using interpolated values
	local raw_density = api.get_interpolated_noise_3d("density", {x = x, y = y, z = z}, 0)

	-- Apply height bias (squeezing formula: x/x/x/24)
	local distance_from_base = y - base_height
	local squeeze_factor = (distance_from_base * distance_from_base * distance_from_base) / 24

	-- Apply the bias - positive bias squeezes more, negative bias squeezes less
	local biased_density = raw_density - (squeeze_factor * height_bias)

	return biased_density
end

-- Get subtle 3D terrain character noise for added variation
function api.get_terrain_character_3d(x, y, z)
	if not api.noise_objects.terrain_character then
		return 0
	end
	return api.get_interpolated_noise_3d("terrain_character", {x = x, y = y, z = z}, 0)
end

-- Get weirdness value at position (for biome variants)
function api.get_weirdness_at(x, z)
	if not api.noise_objects.weirdness then
		return 0
	end
	return api.get_interpolated_noise_2d("weirdness", {x=x, y=z}, 0)
end

-- Climate system
function api.get_heat_at(x, z, y)
	if not api.noise_objects.heat then
		return 50 -- Default heat
	end

	local base_heat = api.get_interpolated_noise_2d("heat", {x=x, y=z}, 0)

	-- Apply minimal elevation cooling (higher = cooler) only at very high elevations
	local elevation_factor = 0
	if y > 100 then
		elevation_factor = (y - 100) * 0.005 -- Very minimal cooling
	end
	local result = base_heat - elevation_factor

	-- Ensure temperature doesn't go too low - maintain some heat even at high elevations
	result = math.max(result, 25) -- Minimum temperature equivalent to -0.5 normalized

	return result
end

function api.get_humidity_at(x, z, y)
	if not api.noise_objects.humidity then
		return 50 -- Default humidity
	end

	local base_humidity = api.get_interpolated_noise_2d("humidity", {x=x, y=z}, 0)
	local humidity_blend = api.get_interpolated_noise_2d("humidity_blend", {x=x, y=z}, 0)

	-- Apply elevation effect (higher = drier, but with some variation)
	local elevation_factor = math.max(0, y - api.SEA_LEVEL) * 0.004 -- 0.4% per 100m

	return base_humidity + humidity_blend - elevation_factor
end

-- External biome registration API
-- This allows other mods to register biomes with VoxelGen
function api.register_biome(biome_def)
	-- Validate that the biomes module is available
	if not voxelgen or not voxelgen.biomes then
		minetest.log("error", "[VoxelGen API] VoxelGen biomes system not available. Make sure VoxelGen is properly loaded.")
		return false
	end

	-- Validate biome definition
	if not biome_def or not biome_def.name then
		minetest.log("error", "[VoxelGen API] Invalid biome definition: missing name")
		return false
	end

	-- Log the registration attempt
	minetest.log("action", "[VoxelGen API] External mod registering biome: " .. biome_def.name)

	-- Delegate to the new biomes module
	local success = voxelgen.biomes.register_biome(biome_def)

	if success then
		minetest.log("action", "[VoxelGen API] Successfully registered external biome: " .. biome_def.name)
	else
		minetest.log("error", "[VoxelGen API] Failed to register external biome: " .. biome_def.name)
	end

	return success
end

-- Helper functions for external mods to create biome definitions
function api.create_biome_def(name, parameters, nodes, properties)
	minetest.log("action", "[VoxelGen API] create_biome_def called with name: " .. tostring(name))

	if not voxelgen then
		minetest.log("error", "[VoxelGen API] voxelgen global not available")
		return nil
	end

	if not voxelgen.biomes then
		minetest.log("error", "[VoxelGen API] voxelgen.biomes not available")
		return nil
	end

	if not voxelgen.biomes.create_biome_def then
		minetest.log("error", "[VoxelGen API] voxelgen.biomes.create_biome_def function not available")
		return nil
	end

	-- Validate parameters
	if not name then
		minetest.log("error", "[VoxelGen API] name is nil")
		return nil
	end

	if type(name) ~= "string" then
		minetest.log("error", "[VoxelGen API] name must be string, got " .. type(name))
		return nil
	end

	minetest.log("action", "[VoxelGen API] Calling voxelgen.biomes.create_biome_def for: " .. name)

	local result = voxelgen.biomes.create_biome_def(name, parameters, nodes, properties)

	if result then
		minetest.log("action", "[VoxelGen API] Successfully created biome definition for: " .. name)
	else
		minetest.log("error", "[VoxelGen API] Failed to create biome definition for: " .. name)
	end

	return result
end



-- Get list of registered biomes (for external mods to query)
function api.get_registered_biomes()
	if not voxelgen or not voxelgen.biomes then
		return {}
	end

	return voxelgen.biomes.get_registered_biomes()
end

-- Check if a biome is registered
function api.is_biome_registered(biome_name)
	local biomes = api.get_registered_biomes()
	return biomes[biome_name] ~= nil
end

-- Terrain classification based on noise values
function api.classify_terrain(x, z, world_seed)
	if not api.noise_objects.continental then
		api.init_noise(world_seed)
	end

	local cont = api.get_interpolated_noise_2d("continental", {x=x, y=z}, world_seed)
	local peak = api.get_interpolated_noise_2d("peaks", {x=x, y=z}, world_seed)
	local erosion = api.get_interpolated_noise_2d("erosion", {x=x, y=z}, world_seed)
	local jagged = api.get_interpolated_noise_2d("jagged_mountains", {x=x, y=z}, world_seed)

	-- Get river information
	local river_info = api.get_river_info_at(x, z, world_seed)

	-- Calculate terrain characteristics
	local terrain_class = {
		continentalness = cont,
		peaks = peak,
		erosion = erosion,
		jagged = jagged,
		-- Derived classifications
		is_ocean = cont < -0.4,
		is_coastal = cont >= -0.4 and cont < 0.05,
		is_inland = cont >= 0.05,
		is_mountainous = peak > 0.4 or jagged > 0.5,
		is_highland = peak > 0.05 and peak <= 0.4,
		is_lowland = peak <= 0.05,
		is_eroded = erosion > 0.25,
		is_jagged = jagged > 0.7,
		is_plains = peak >= -0.15 and peak <= 0.15 and jagged <= 0.2 and cont >= 0.05,
		-- River information
		is_river = river_info.is_river,
		is_riverbank = river_info.is_riverbank,
		river_strength = river_info.strength,
		-- Elevation categories based on noise
		elevation_category = api.get_elevation_category(cont, peak, erosion, jagged)
	}

	return terrain_class
end

-- Get elevation category from noise values
function api.get_elevation_category(cont, peak, erosion, jagged)
	-- Ocean depths
	if cont < -0.6 then
		return "deep_ocean"
	elseif cont < -0.4 then
		return "ocean"
	elseif cont < -0.15 then
		return "shallow_ocean"
	end

	-- Coastal areas
	if cont < 0.05 then
		return "coastal"
	end

	-- Land elevation based on peaks, jagged mountains, and erosion
	local elevation_factor = peak + (jagged * 0.25)
	local erosion_modifier = math.max(0, erosion) * 0.3 -- Erosion lowers effective elevation
	local effective_elevation = elevation_factor - erosion_modifier

	if effective_elevation > 0.8 or jagged > 0.85 then
		return "high_peaks"
	elseif effective_elevation > 0.5 or jagged > 0.6 then
		return "mountains"
	elseif effective_elevation > 0.25 or (jagged > 0.3 and peak > 0.1) then
		return "hills"
	elseif effective_elevation > 0.05 then
		return "highlands"
	elseif effective_elevation > -0.1 then
		return "plains"
	elseif effective_elevation > -0.25 then
		return "lowlands"
	else
		return "valleys"
	end
end

-- Get biome at position based on climate and terrain classification
function api.get_biome_at(x, y, z, terrain_height, world_seed)
	-- Delegate to the main VoxelGen biome system
	if voxelgen and voxelgen.get_biome_at then
		return voxelgen.get_biome_at(x, y, z, terrain_height)
	end

	-- Fallback: return climate and terrain data
	local heat = api.get_heat_at(x, z, terrain_height or y)
	local humidity = api.get_humidity_at(x, z, terrain_height or y)
	local terrain_class = api.classify_terrain(x, z, world_seed)

	return {
		heat = heat,
		humidity = humidity,
		terrain = terrain_class,
		elevation_category = terrain_class.elevation_category
	}
end

-- Terrain generation
function api.generate_heightmap(minp, maxp, world_seed)
	if not api.noise_objects.continental then
		api.init_noise(world_seed)
	end

	-- Increment chunk generation counter for transition tracking
	if api.cache.transition_active then
		api.cache.chunk_generation_count = api.cache.chunk_generation_count + 1

		-- End transition after sufficient chunks have been generated
		if api.cache.chunk_generation_count > 15 then
			api.cache.transition_active = false
			api.cache.previous_noise_objects = {}
			api.cache.previous_biomes = {}
			minetest.log("action", "[VoxelGen API] Transition completed")
		end
	end

	local size_x = maxp.x - minp.x + 1
	local size_z = maxp.z - minp.z + 1
	local heightmap = {}
	local jagged_mask = {}

	-- Generate base heightmap using interpolated noise values
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local cont = api.get_interpolated_noise_2d("continental", {x=x, y=z}, world_seed)
			local peak = api.get_interpolated_noise_2d("peaks", {x=x, y=z}, world_seed)
			local erosion = api.get_interpolated_noise_2d("erosion", {x=x, y=z}, world_seed)
			local jagged = api.get_interpolated_noise_2d("jagged_mountains", {x=x, y=z}, world_seed)
			local ridge = api.get_interpolated_noise_2d("mountain_ridges", {x=x, y=z}, world_seed)
			local weirdness = api.get_interpolated_noise_2d("weirdness", {x=x, y=z}, world_seed)

			-- Calculate peaks and valleys from weirdness
			local peaks_valleys = api.calculate_peaks_valleys(weirdness)

			local small_h_scale = api.fancy_interp((1 - erosion) * 0.5, 1, 5, world_seed, x, z)
			local small_h = api.get_interpolated_noise_2d("small_scale", {x=x, y=z}, world_seed) * small_h_scale

			local h_cont = api.spline_map(cont, api.splines.continentalness, world_seed, x, z)
			local h_peak = api.spline_map(peak, api.splines.peaks, world_seed, x, z)
			local h_erosion = api.spline_map(erosion, api.splines.erosion, world_seed, x, z)
			local h_jagged = api.spline_map(jagged, api.splines.jagged_mountains, world_seed, x, z)

			-- Apply peaks and valleys effect
			local pv_effect = peaks_valleys * 15 -- Scale the effect

			-- Balanced erosion effects to prevent artifacts
			local erosion_lowering = math.max(0, erosion) * 18 -- Reduced from 22
			local erosion_flattening = math.abs(erosion) * 0.6 -- Reduced from 0.75

			-- Gentler erosion-based terrain smoothing
			local erosion_smoothing = math.min(0.6, math.abs(erosion) * 0.8)

			local jagged_influence = api.fancy_interp(math.max(0, (cont - 0.3) * 1.2 + (1 - math.abs(erosion)) * 0.4), 0, 1, world_seed, x, z)
			local ridge_factor = 1 - math.abs(ridge) * 0.4
			local ridge_navigability = api.fancy_interp(ridge_factor, 0.6, 1.2, world_seed, x, z)

			local jagged_contribution = h_jagged * jagged_influence * ridge_navigability * (1 - erosion_flattening)

			-- Apply erosion smoothing to small-scale noise for more natural terrain
			local smoothed_small_h = small_h * (1 - erosion_smoothing)

			local base_height = h_cont + h_peak + smoothed_small_h + h_erosion + jagged_contribution + pv_effect - erosion_lowering

			-- Enhanced plains detection - slightly bigger and more varied plains
			local is_plains = peak >= -0.2 and peak <= 0.2 and jagged <= 0.25 and cont >= 0.0
			local plains_factor = 0

			if is_plains then
				-- Calculate how "plains-like" this area is (0 = not plains, 1 = perfect plains)
				local peak_factor = 1 - (math.abs(peak) / 0.2)   -- Expanded range for more plains
				local jagged_factor = 1 - (jagged / 0.25)		-- Slightly more tolerance for jaggedness
				local cont_factor = math.min(1, math.max(0, (cont + 0.05) / 0.25))  -- Lowered threshold

				-- Add erosion factor - more eroded areas are more plains-like
				local erosion_factor = math.max(0, 1 - math.abs(erosion) * 0.8)

				plains_factor = peak_factor * jagged_factor * cont_factor * erosion_factor
				plains_factor = api.smoothstep(plains_factor)  -- Smooth the transition

				-- Boost plains factor in highly eroded areas
				if erosion > 0.3 then
					plains_factor = plains_factor * 1.2
				end
				plains_factor = math.min(1, plains_factor)
			end

			local final_height = base_height

			-- Enhanced plains flattening with better target calculation
			if plains_factor > 0 then
				-- Improved target height for plains with subtle variation
				local plains_target = h_cont + (smoothed_small_h * 0.25) + (h_erosion * 0.4)

				-- Add subtle height variation based on erosion patterns
				local height_variation = erosion * 2 * plains_factor
				plains_target = plains_target + height_variation

				final_height = api.lerp(base_height, plains_target, plains_factor)
			end

			-- Apply river carving directly to the height calculation
			local river_strength, river_width = api.get_river_factor(x, z, world_seed)

			-- Additional safety check: don't carve rivers in ocean areas
			local is_ocean = cont < -0.2

			if river_strength > 0 and not is_ocean then
				-- Calculate target river level (at or slightly below sea level)
				local river_depth = api.calculate_river_depth(x, z, river_strength, world_seed)
				local target_height = api.SEA_LEVEL - river_depth

				-- Only carve if the terrain is above the target river level
				if final_height > target_height then
					-- Get 3D canyon noise for organic edge variation
					local canyon_noise = api.get_interpolated_noise_3d("canyon",
						{x=x, y=final_height * 0.5, z=z}, world_seed)

					-- Get terrain character noise for additional subtle variation
					local terrain_char = api.get_interpolated_noise_3d("terrain_character",
						{x=x, y=final_height * 0.2, z=z}, world_seed)

					-- Combine 3D noise sources for moderate edge variation
					local edge_variation = (canyon_noise * 0.6 + terrain_char * 0.4) * 0.3

					-- Apply 3D noise variation to river boundaries (moderate effect)
					local boundary_modifier = 1.0 + edge_variation * 0.4  -- Can modify strength by ±40%
					local modified_strength = river_strength * boundary_modifier
					modified_strength = math.max(0, math.min(1, modified_strength))

					-- Additional 3D noise for subtle carving depth variation
					local depth_variation_3d = api.get_interpolated_noise_3d("canyon",
						{x=x, y=target_height, z=z}, world_seed + 100)
					local modified_target = target_height + (depth_variation_3d * 1.5)  -- Subtle height offset

					-- Use fancy interpolation for the carving factor with position-based variation
					local base_carve_factor = modified_strength * 0.6
					local carve_factor = api.fancy_interp(base_carve_factor, 0, 1, world_seed, x, z)

					-- Apply additional height-based variation for more natural river profiles
					local height_factor = (final_height - modified_target) / math.max(1, final_height - modified_target + 10)
					height_factor = api.smoothstep(height_factor)

					-- Combine all factors for final carving strength
					local final_carve_factor = carve_factor * height_factor

					-- Use fancy interpolation for the final height calculation with 3D-modified target
					final_height = api.fancy_interp(final_carve_factor, final_height, modified_target,
						world_seed + 1337, x, z)

					-- Add subtle 3D noise micro-variation to river carved areas
					local micro_variation = api.get_interpolated_noise_3d("canyon",
						{x=x, y=final_height + 2, z=z}, world_seed + 999)
					final_height = final_height + micro_variation * 0.2 * modified_strength
				end
			end

			local idx = (z - minp.z) * size_x + (x - minp.x + 1)
			heightmap[idx] = final_height
			jagged_mask[idx] = math.min(1, (h_jagged * jagged_influence) / 100)
		end
	end

	-- Apply subtle smoothing to reduce grid patterns from 3D noise
	for z = minp.z + 1, maxp.z - 1 do
		for x = minp.x + 1, maxp.x - 1 do
			local idx = (z - minp.z) * size_x + (x - minp.x + 1)
			local current_height = heightmap[idx]

			-- Get neighboring heights for smoothing
			local neighbors = {
				heightmap[((z-1) - minp.z) * size_x + ((x-1) - minp.x + 1)], -- NW
				heightmap[((z-1) - minp.z) * size_x + (x - minp.x + 1)],	 -- N
				heightmap[((z-1) - minp.z) * size_x + ((x+1) - minp.x + 1)], -- NE
				heightmap[(z - minp.z) * size_x + ((x-1) - minp.x + 1)],	 -- W
				heightmap[(z - minp.z) * size_x + ((x+1) - minp.x + 1)],	 -- E
				heightmap[((z+1) - minp.z) * size_x + ((x-1) - minp.x + 1)], -- SW
				heightmap[((z+1) - minp.z) * size_x + (x - minp.x + 1)],	 -- S
				heightmap[((z+1) - minp.z) * size_x + ((x+1) - minp.x + 1)]  -- SE
			}

			-- Calculate average of neighbors
			local neighbor_avg = 0
			for _, h in ipairs(neighbors) do
				neighbor_avg = neighbor_avg + h
			end
			neighbor_avg = neighbor_avg / #neighbors

			-- Gentle, consistent smoothing to avoid artifacts
			local smoothing_factor = 0.04 -- Fixed, gentle smoothing
			heightmap[idx] = current_height * (1 - smoothing_factor) + neighbor_avg * smoothing_factor
		end
	end

	return heightmap, jagged_mask
end

-- Erosion functions
function api.thermal_erosion_selective(heightmap, jagged_mask, size_x, size_z, iterations, talus_angle)
	for iter = 1, iterations do
		local changes = {}
		for z = 2, size_z-1 do
			for x = 2, size_x-1 do
				local idx = (z - 1) * size_x + x
				local h = heightmap[idx]
				local max_diff = 0
				local max_idx = nil

				-- Simple, stable erosion: find steepest neighbor only
				for dz = -1, 1 do
					for dx = -1, 1 do
						if dx ~= 0 or dz ~= 0 then
							local n_idx = (z + dz - 1) * size_x + (x + dx)
							local nh = heightmap[n_idx]
							local diff = h - nh
							if diff > max_diff then
								max_diff = diff
								max_idx = n_idx
							end
						end
					end
				end

				if max_diff > talus_angle then
					local jagged_factor = jagged_mask[idx] or 0
					local erosion_reduction = 1 - (jagged_factor * 0.7) -- Back to original value

					-- Conservative erosion: only transfer to steepest neighbor
					local transfer = (max_diff - talus_angle) / 2.5 * erosion_reduction -- Less aggressive
					changes[idx] = (changes[idx] or 0) - transfer
					changes[max_idx] = (changes[max_idx] or 0) + transfer
				end
			end
		end

		for i, change in pairs(changes) do
			heightmap[i] = heightmap[i] + change
		end
	end
end

function api.hydraulic_erosion(heightmap, size_x, size_z, iterations)
	local water = {}
	local sediment = {}

	for i = 1, size_x * size_z do
		water[i] = 0
		sediment[i] = 0
	end

	for iter = 1, iterations do
		-- Simple rainfall
		for i = 1, size_x * size_z do
			water[i] = water[i] + 0.01
		end

		local water_diff = {}
		local sediment_diff = {}

		for z = 2, size_z - 1 do
			for x = 2, size_x - 1 do
				local idx = (z - 1) * size_x + x
				local h = heightmap[idx] + water[idx]

				-- Find lowest neighbor (simple approach)
				local lowest_h = h
				local lowest_idx = nil
				for dz = -1, 1 do
					for dx = -1, 1 do
						if dx ~= 0 or dz ~= 0 then
							local n_idx = (z + dz - 1) * size_x + (x + dx)
							local nh = heightmap[n_idx] + water[n_idx]
							if nh < lowest_h then
								lowest_h = nh
								lowest_idx = n_idx
							end
						end
					end
				end

				if lowest_idx then
					local dh = h - lowest_h
					local flow = math.min(water[idx], dh * 0.4) -- Reduced flow rate
					water_diff = water_diff or {}
					sediment_diff = sediment_diff or {}
					water_diff[idx] = (water_diff[idx] or 0) - flow
					water_diff[lowest_idx] = (water_diff[lowest_idx] or 0) + flow

					-- Reduced sediment transport to prevent deep carving
					local sediment_flow = flow * dh * 0.05 -- Much reduced
					sediment_diff[idx] = (sediment_diff[idx] or 0) - sediment_flow
					sediment_diff[lowest_idx] = (sediment_diff[lowest_idx] or 0) + sediment_flow

					-- Much gentler terrain erosion
					heightmap[idx] = heightmap[idx] - sediment_flow * 0.02 -- Much reduced
				end
			end
		end

		for i = 1, size_x * size_z do
			water[i] = (water[i] + (water_diff and water_diff[i] or 0)) or water[i]
			sediment[i] = (sediment[i] + (sediment_diff and sediment_diff[i] or 0)) or sediment[i]
			if water[i] < 0 then water[i] = 0 end
			if sediment[i] < 0 then sediment[i] = 0 end

			-- Evaporation
			water[i] = water[i] * 0.99
		end
	end
end

-- River generation functions
function api.get_river_factor(x, z, world_seed)
	if not api.noise_objects.river_network or not api.noise_objects.river_width then
		return 0, 0
	end

	-- Get river network noise - this determines where rivers flow
	local river_noise = api.get_interpolated_noise_2d("river_network", {x=x, y=z}, world_seed)
	local width_noise = api.get_interpolated_noise_2d("river_width", {x=x, y=z}, world_seed)

	-- Rivers form where the noise is close to zero (ridges in the noise field become valleys)
	local river_distance = math.abs(river_noise)

	-- Enhanced river width calculation with terrain-based variation
	local erosion = api.get_interpolated_noise_2d("erosion", {x=x, y=z}, world_seed)
	local base_width = 10 + width_noise * 8 + erosion * 4  -- 2-22 blocks base width, wider in eroded areas

	-- Rivers only exist on land (continentalness > -0.2) and not in high mountains
	local cont = api.get_interpolated_noise_2d("continental", {x=x, y=z}, world_seed)
	local peak = api.get_interpolated_noise_2d("peaks", {x=x, y=z}, world_seed)

	-- No rivers in oceans or very high mountains, but allow in moderate elevations
	if cont < -0.2 or peak > 0.7 then
		return 0, 0
	end

	-- Enhanced river strength calculation with better falloff
	local river_strength = 0
	local influence_radius = base_width / 50  -- Adjusted for better scaling

	if river_distance < influence_radius then
		river_strength = 1 - (river_distance / influence_radius)

		-- Apply triple smoothstep for ultra-smooth transitions
		river_strength = api.smoothstep(api.smoothstep(api.smoothstep(river_strength)))

		-- Enhanced 3D noise variation for more organic river boundaries
		if api.noise_objects.terrain_character then
			local boundary_noise = api.get_interpolated_noise_3d("terrain_character",
				{x=x, y=0, z=z}, world_seed + 500)
			local depth_noise = api.get_interpolated_noise_3d("terrain_character",
				{x=x, y=10, z=z}, world_seed + 1000)

			-- Multi-layered boundary variation for more natural edges
			local boundary_variation = (boundary_noise * 0.12 + depth_noise * 0.08) * river_strength
			river_strength = math.max(0, math.min(1, river_strength + boundary_variation))
		end

		-- Terrain-based river strength modulation
		local terrain_factor = 1.0
		if erosion > 0.2 then
			terrain_factor = 1.2  -- Stronger rivers in eroded areas
		elseif peak > 0.3 then
			terrain_factor = 0.8  -- Weaker rivers in elevated areas
		end

		river_strength = river_strength * terrain_factor
	end

	return river_strength, base_width
end

function api.calculate_river_depth(x, z, river_strength, world_seed)
	if river_strength <= 0 then
		return 0
	end

	-- Rivers carve down to sea level or slightly below - made shallower and smoother
	local base_depth = 3 + river_strength * 5  -- 3-8 blocks deep (reduced from 5-13)

	-- Add 3D noise variation for more natural river bed profiles
	local depth_variation = api.get_interpolated_noise_2d("small_scale", {x=x, y=z}, world_seed) * 0.8

	-- Add subtle 3D canyon variation to river depth
	if api.noise_objects.canyon then
		local bed_character = api.get_interpolated_noise_3d("canyon",
			{x=x, y=api.SEA_LEVEL, z=z}, world_seed)
		depth_variation = depth_variation + bed_character * 0.3 * river_strength
	end

	return base_depth + depth_variation
end

-- Calculate the water level for rivers (ensures rivers have water)
function api.calculate_river_water_level(x, z, river_strength, world_seed)
	if river_strength <= 0 then
		return api.SEA_LEVEL
	end

	-- Safety check: don't lower water level in ocean areas
	local cont = api.get_interpolated_noise_2d("continental", {x=x, y=z}, world_seed)
	if cont < -0.2 then
		return api.SEA_LEVEL  -- Always use sea level in oceans
	end

	local river_depth = api.calculate_river_depth(x, z, river_strength, world_seed)
	-- Keep at least 2-3 blocks of water depth in rivers
	local water_level = api.SEA_LEVEL - math.max(0, river_depth - 3)

	return water_level
end

-- DEPRECATED: River carving is now integrated directly into generate_heightmap
--[[
function api.carve_rivers(heightmap, minp, maxp, world_seed)
	-- This function is no longer used - river carving is now built into generate_heightmap
	-- for better integration and performance
end
--]]

-- Check if a position is in a river
function api.is_river_at(x, z, world_seed)
	local river_strength, _ = api.get_river_factor(x, z, world_seed)
	return river_strength > 0.3  -- Threshold for considering it a river
end

-- Get river information at a position (for biome generation)
function api.get_river_info_at(x, z, world_seed)
	local river_strength, river_width = api.get_river_factor(x, z, world_seed)
	local is_river = river_strength > 0.3
	local is_riverbank = river_strength > 0.1 and river_strength <= 0.3

	return {
		is_river = is_river,
		is_riverbank = is_riverbank,
		strength = river_strength,
		width = river_width
	}
end

-- Utility functions for external mods to work with the transition system

-- Check if a transition is currently active
function api.is_transition_active()
	return api.cache.transition_active
end

-- Get current transition progress (0.0 to 1.0)
function api.get_transition_progress()
	if not api.cache.transition_active then
		return 1.0
	end
	return math.min(1.0, api.cache.chunk_generation_count / 15)
end

-- Force a transition check (useful when external mods change parameters)
function api.force_transition_check(world_seed)
	api.cache.noise_params_hash = nil
	api.cache.biomes_hash = nil
	api.check_for_changes(world_seed or 0)
end

-- Set transition parameters
function api.set_transition_params(radius, chunk_count)
	api.cache.transition_radius = radius or 80
	-- Update the chunk count threshold in the generate_heightmap function would need manual adjustment
	minetest.log("action", "[VoxelGen API] Transition parameters updated: radius=" .. api.cache.transition_radius)
end

-- Get transition status information
function api.get_transition_status()
	return {
		active = api.cache.transition_active,
		progress = api.get_transition_progress(),
		chunk_count = api.cache.chunk_generation_count,
		radius = api.cache.transition_radius
	}
end

-- Manual transition control (for advanced users)
function api.start_manual_transition()
	if not api.cache.transition_active then
		api.cache.transition_active = true
		api.cache.chunk_generation_count = 0
		minetest.log("action", "[VoxelGen API] Manual transition started")
		return true
	end
	return false
end

function api.end_manual_transition()
	if api.cache.transition_active then
		api.cache.transition_active = false
		api.cache.previous_noise_objects = {}
		api.cache.previous_biomes = {}
		api.cache.chunk_generation_count = 0
		minetest.log("action", "[VoxelGen API] Manual transition ended")
		return true
	end
	return false
end

return api
