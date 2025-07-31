-- biomes_new.lua - New modular biome system for VoxelGen
-- This replaces the old biomes.lua with a clean, modular architecture
-- Uses the biome_registry and biome_manager for reliable operation

local biomes = {}

-- Load dependencies
local biome_registry = dofile(minetest.get_modpath("voxelgen") .. "/biome_registry.lua")
local biome_manager = dofile(minetest.get_modpath("voxelgen") .. "/biome_manager.lua")
local nodes = dofile(minetest.get_modpath("voxelgen") .. "/nodes.lua")
local api = dofile(minetest.get_modpath("voxelgen") .. "/api.lua")

-- Logging helper
local function log(level, message)
	minetest.log(level, "[VoxelGen Biomes] " .. message)
end

-- Initialize the biome system
function biomes.initialize()
	log("info", "Initializing new modular biome system")

	-- Initialize the node system first
	nodes.init()

	-- Initialize the registry
	local success = biome_registry.initialize()
	if not success then
		log("error", "Failed to initialize biome registry")
		return false
	end

	-- Set the registry in the manager
	biome_manager.set_registry(biome_registry)

	log("info", "Biome system initialized successfully")
	return true
end

-- Create a biome definition (public API)
function biomes.create_biome_def(name, parameters, nodes, properties)
	return biome_registry.create_biome_def(name, parameters, nodes, properties)
end

-- Register a biome (public API)
function biomes.register_biome(biome_def)
	return biome_registry.register_biome(biome_def)
end

-- Unregister a biome (public API)
function biomes.unregister_biome(biome_name)
	return biome_registry.unregister_biome(biome_name)
end

-- Get all registered biomes (public API)
function biomes.get_registered_biomes()
	return biome_registry.get_all_biomes()
end

-- Check if a biome is registered (public API)
function biomes.is_biome_registered(biome_name)
	return biome_registry.is_biome_registered(biome_name)
end

-- Get a specific biome (public API)
function biomes.get_biome(biome_name)
	return biome_registry.get_biome(biome_name)
end

-- Get the best biome for given conditions with perfect terrain-height coupling
function biomes.get_biome_at(temperature, humidity, height, terrain_class, x, z, actual_y)
	-- Check if we have the new climate system available
	if voxelgen and voxelgen.climate and voxelgen.climate.get_biome_parameters then
		-- PERFECT TERRAIN-HEIGHT COUPLING:
		-- Use terrain height as the primary reference for biome selection,
		-- but consider the actual Y-coordinate for depth-based adjustments
		local terrain_height = height or 64 -- Terrain surface height
		local y_coord = actual_y or terrain_height -- Actual Y-coordinate (defaults to terrain height)

		-- Calculate the relative position to terrain surface
		local depth_below_surface = math.max(0, terrain_height - y_coord)
		local height_above_surface = math.max(0, y_coord - terrain_height)

		-- Get climate parameters based on the terrain surface position
		local parameters = voxelgen.climate.get_biome_parameters(x, z, terrain_height, terrain_height)

		if parameters then
			-- ENHANCED Y-COORDINATE LOGIC:
			-- For biome Y-level matching, use a smart hybrid approach:
			-- 1. For surface and above-surface positions: use terrain height
			-- 2. For below-surface positions: use actual Y-coordinate with terrain context
			local biome_selection_y

			if y_coord >= terrain_height then
				-- At or above surface: use terrain height for biome selection
				biome_selection_y = terrain_height
			else
				-- Below surface: use actual Y-coordinate but with terrain-aware adjustments
				biome_selection_y = y_coord

				-- Apply terrain-height influence for better underground biome selection
				-- This ensures that deep ocean floors get ocean biomes, not mountain biomes
				if terrain_height <= 0 then
					-- Underwater terrain: bias towards ocean/underwater biomes
					biome_selection_y = math.min(biome_selection_y, 0)
				elseif terrain_height > 100 then
					-- High terrain: ensure underground areas still get appropriate biomes
					-- but don't force mountain biomes in deep caves under mountains
					local terrain_influence = math.max(0, 1 - (depth_below_surface / 50))
					biome_selection_y = biome_selection_y + (terrain_height - y_coord) * terrain_influence * 0.3
				end
			end

			-- Set the Y parameter for biome manager with perfect terrain coupling
			parameters.y = biome_selection_y

			-- Enhanced depth calculation that considers terrain relationship
			parameters.depth = depth_below_surface * 0.0078125

			-- Add terrain context information for better biome selection
			parameters.terrain_height = terrain_height
			parameters.actual_y = y_coord
			parameters.depth_below_surface = depth_below_surface
			parameters.height_above_surface = height_above_surface
			parameters.is_surface = (math.abs(y_coord - terrain_height) <= 1)
			parameters.is_underground = (depth_below_surface > 1)
			parameters.is_aerial = (height_above_surface > 1)

			-- Debug logging for biome selection issues (only log occasionally to avoid spam)
			if math.random() < 0.001 then -- Log ~0.1% of calls
				log("info", "Perfect terrain-biome coupling at (" .. x .. "," .. z .. "): " ..
					"terrain_h=" .. string.format("%.1f", terrain_height) ..
					", actual_y=" .. string.format("%.1f", y_coord) ..
					", biome_y=" .. string.format("%.1f", biome_selection_y) ..
					", depth=" .. string.format("%.1f", depth_below_surface) ..
					", temp_level=" .. parameters.temperature_level ..
					", cont=" .. parameters.continentalness_name)
			end

			-- Use the biome manager to find the best biome with perfect terrain coupling
			local best_biome = biome_manager.get_best_biome(parameters)

			if best_biome then
				-- Debug logging for biome selection results
				if math.random() < 0.001 then -- Log ~0.1% of calls
					log("info", "Perfect coupling selected: " .. best_biome.name ..
						" (terrain-aware Y=" .. string.format("%.1f", biome_selection_y) .. ")")
				end
				return best_biome
			end
		end
	end

	-- Fallback: Convert old-style parameters to new parameter structure with perfect terrain coupling
	local parameters = biomes.convert_legacy_parameters(temperature, humidity, height, terrain_class, x, z, actual_y)

	if not parameters then
		log("warning", "Could not convert legacy parameters for biome selection")
		return biomes.get_fallback_biome()
	end

	-- Use the improved biome manager to find the best biome
	local best_biome = biome_manager.get_best_biome(parameters)

	if not best_biome then
		log("warning", "Biome manager failed to find any biome - this should be very rare with improved matching")
		return biomes.get_fallback_biome()
	end

	return best_biome
end

-- Convert legacy parameters to new parameter structure with perfect terrain coupling
function biomes.convert_legacy_parameters(temperature, humidity, height, terrain_class, x, z, actual_y)
	if not temperature or not humidity then
		return nil
	end

	-- PERFECT TERRAIN-HEIGHT COUPLING for legacy parameters
	local terrain_height = height or 64
	local y_coord = actual_y or terrain_height

	-- Calculate terrain relationship
	local depth_below_surface = math.max(0, terrain_height - y_coord)
	local height_above_surface = math.max(0, y_coord - terrain_height)

	-- Apply the same perfect terrain coupling logic as the main function
	local biome_selection_y
	if y_coord >= terrain_height then
		-- At or above surface: use terrain height for biome selection
		biome_selection_y = terrain_height
	else
		-- Below surface: use actual Y-coordinate with terrain-aware adjustments
		biome_selection_y = y_coord

		-- Apply terrain-height influence for better underground biome selection
		if terrain_height <= 0 then
			-- Underwater terrain: bias towards ocean/underwater biomes
			biome_selection_y = math.min(biome_selection_y, 0)
		elseif terrain_height > 100 then
			-- High terrain: ensure underground areas still get appropriate biomes
			local terrain_influence = math.max(0, 1 - (depth_below_surface / 50))
			biome_selection_y = biome_selection_y + (terrain_height - y_coord) * terrain_influence * 0.3
		end
	end

	-- Convert temperature to level (0-4)
	local temperature_level = 2 -- Default to temperate
	if temperature < 25 then
		temperature_level = 0 -- Frozen
	elseif temperature < 40 then
		temperature_level = 1 -- Cold
	elseif temperature < 60 then
		temperature_level = 2 -- Temperate
	elseif temperature < 80 then
		temperature_level = 3 -- Warm
	else
		temperature_level = 4 -- Hot
	end

	-- Convert humidity to level (0-4)
	local humidity_level = 2 -- Default to neutral
	if humidity < 20 then
		humidity_level = 0 -- Arid
	elseif humidity < 40 then
		humidity_level = 1 -- Dry
	elseif humidity < 60 then
		humidity_level = 2 -- Neutral
	elseif humidity < 80 then
		humidity_level = 3 -- Humid
	else
		humidity_level = 4 -- Wet
	end

	-- Determine continentalness from terrain class
	local continentalness_name = "mid_inland" -- Default
	if terrain_class then
		if terrain_class.is_ocean then
			continentalness_name = terrain_class.continentalness < -0.5 and "deep_ocean" or "ocean"
		elseif terrain_class.is_coastal then
			continentalness_name = "coast"
		elseif terrain_class.is_inland then
			if terrain_class.continentalness > 0.3 then
				continentalness_name = "far_inland"
			elseif terrain_class.continentalness > 0.03 then
				continentalness_name = "mid_inland"
			else
				continentalness_name = "near_inland"
			end
		end
	end

	-- Determine erosion level from terrain class
	local erosion_level = 3 -- Default to hilly
	if terrain_class then
		if terrain_class.erosion then
			if terrain_class.erosion < -0.78 then
				erosion_level = 0 -- Most mountainous
			elseif terrain_class.erosion < -0.375 then
				erosion_level = 1
			elseif terrain_class.erosion < -0.2225 then
				erosion_level = 2
			elseif terrain_class.erosion < 0.05 then
				erosion_level = 3
			elseif terrain_class.erosion < 0.45 then
				erosion_level = 4
			elseif terrain_class.erosion < 0.55 then
				erosion_level = 5
			else
				erosion_level = 6 -- Most flat
			end
		end
	end

	-- Determine PV name from terrain class
	local pv_name = "mid" -- Default
	if terrain_class then
		if terrain_class.peaks then
			if terrain_class.peaks < -0.85 then
				pv_name = "valleys"
			elseif terrain_class.peaks < -0.2 then
				pv_name = "low"
			elseif terrain_class.peaks < 0.2 then
				pv_name = "mid"
			elseif terrain_class.peaks < 0.7 then
				pv_name = "high"
			else
				pv_name = "peaks"
			end
		end
	end

	return {
		temperature_level = temperature_level,
		humidity_level = humidity_level,
		continentalness_name = continentalness_name,
		erosion_level = erosion_level,
		pv_name = pv_name,
		depth = depth_below_surface * 0.0078125, -- Perfect terrain-aware depth
		y = biome_selection_y, -- Perfect terrain-coupled Y coordinate
		x = x or 0,
		z = z or 0,
		-- Add terrain context information
		terrain_height = terrain_height,
		actual_y = y_coord,
		depth_below_surface = depth_below_surface,
		height_above_surface = height_above_surface,
		is_surface = (math.abs(y_coord - terrain_height) <= 1),
		is_underground = (depth_below_surface > 1),
		is_aerial = (height_above_surface > 1)
	}
end

-- Get a fallback biome when no suitable biome is found (should rarely be needed with improved matching)
function biomes.get_fallback_biome()
	-- This function should rarely be called with the improved biome matching system
	log("warning", "Fallback biome system activated - this indicates a potential issue with biome coverage")

	local all_biomes = biome_registry.get_all_biomes()

	if not next(all_biomes) then
		-- No biomes registered - create a minimal emergency fallback
		log("error", "No biomes registered, creating emergency fallback")
		return biomes.create_emergency_fallback()
	end

	-- Use intelligent fallback selection based on biome priorities and coverage
	return biomes.select_intelligent_fallback(all_biomes)
end

-- Create an emergency fallback biome when no biomes are registered
function biomes.create_emergency_fallback()
	return {
		name = "emergency_fallback",
		node_top = nodes.get_content_id("dirt_with_grass"),
		node_filler = nodes.get_content_id("dirt"),
		node_stone = nodes.get_content_id("stone"),
		depth_top = 1,
		depth_filler = 3,
		priority = -1000,
		-- Make it match any parameters to ensure it's always selectable
		temperature_levels = {0, 1, 2, 3, 4},
		humidity_levels = {0, 1, 2, 3, 4},
		continentalness_names = {"deep_ocean", "ocean", "coast", "near_inland", "mid_inland", "far_inland"},
		erosion_levels = {0, 1, 2, 3, 4, 5, 6},
		pv_names = {"valleys", "low", "mid", "high", "peaks"},
		y_min = -31000,
		y_max = 31000
	}
end

-- Select an intelligent fallback from available biomes
function biomes.select_intelligent_fallback(all_biomes)
	-- Priority 1: Look for versatile biomes (those with broad parameter ranges)
	local versatile_biomes = {}
	for name, biome in pairs(all_biomes) do
		local versatility_score = biomes.calculate_biome_versatility(biome)
		if versatility_score > 0.6 then -- Highly versatile
			table.insert(versatile_biomes, {name = name, biome = biome, score = versatility_score})
		end
	end

	if #versatile_biomes > 0 then
		-- Sort by versatility score and priority
		table.sort(versatile_biomes, function(a, b)
			if a.score == b.score then
				return (a.biome.priority or 0) > (b.biome.priority or 0)
			end
			return a.score > b.score
		end)
		log("info", "Selected versatile fallback biome: " .. versatile_biomes[1].name)
		return versatile_biomes[1].biome
	end

	-- Priority 2: Look for temperate biomes (most common climate)
	for name, biome in pairs(all_biomes) do
		if biome.temperature_levels then
			for _, level in ipairs(biome.temperature_levels) do
				if level == 2 then -- Temperate
					log("info", "Selected temperate fallback biome: " .. name)
					return biome
				end
			end
		end
	end

	-- Priority 3: Look for biomes with neutral humidity
	for name, biome in pairs(all_biomes) do
		if biome.humidity_levels then
			for _, level in ipairs(biome.humidity_levels) do
				if level == 2 then -- Neutral humidity
					log("info", "Selected neutral humidity fallback biome: " .. name)
					return biome
				end
			end
		end
	end

	-- Priority 4: Return highest priority biome
	local highest_priority_biome = nil
	local highest_priority = -math.huge
	for name, biome in pairs(all_biomes) do
		local priority = biome.priority or 0
		if priority > highest_priority then
			highest_priority = priority
			highest_priority_biome = biome
		end
	end

	if highest_priority_biome then
		log("info", "Selected highest priority fallback biome: " .. highest_priority_biome.name)
		return highest_priority_biome
	end

	-- Priority 5: Return any biome (last resort)
	for name, biome in pairs(all_biomes) do
		log("info", "Selected arbitrary fallback biome: " .. name)
		return biome
	end

	-- This should never happen if all_biomes is not empty
	log("error", "Failed to select any fallback biome")
	return biomes.create_emergency_fallback()
end

-- Calculate how versatile a biome is (how many parameter combinations it can handle)
function biomes.calculate_biome_versatility(biome)
	local score = 0
	local max_score = 0

	-- Temperature range versatility
	max_score = max_score + 1
	if biome.temperature_levels then
		score = score + (#biome.temperature_levels / 5) -- 5 possible temperature levels
	end

	-- Humidity range versatility
	max_score = max_score + 1
	if biome.humidity_levels then
		score = score + (#biome.humidity_levels / 5) -- 5 possible humidity levels
	end

	-- Continentalness versatility
	max_score = max_score + 1
	if biome.continentalness_names then
		score = score + (#biome.continentalness_names / 6) -- 6 possible continentalness types
	end

	-- Erosion versatility
	max_score = max_score + 1
	if biome.erosion_levels then
		score = score + (#biome.erosion_levels / 7) -- 7 possible erosion levels
	end

	-- Y-range versatility
	max_score = max_score + 1
	local y_min = biome.y_min or -31000
	local y_max = biome.y_max or 31000
	local y_range = y_max - y_min
	score = score + math.min(1, y_range / 62000) -- Normalize to max possible range

	return max_score > 0 and (score / max_score) or 0
end

-- Register default biomes


-- Get biome statistics
function biomes.get_statistics()
	local registry_stats = biome_registry.get_statistics()
	local manager_stats = biome_manager.get_biome_statistics()

	return {
		registry = registry_stats,
		manager = manager_stats,
		total_biomes = registry_stats.total_biomes
	}
end



-- Expose the registry and manager for advanced usage
biomes.registry = biome_registry
biomes.manager = biome_manager

-- Backward compatibility aliases
biomes.registered = biome_registry.get_all_biomes

-- Generate biome map for a chunk (for mapgen compatibility)
function biomes.generate_biome_map(minp, maxp, temperature_map, humidity_map, heightmap, world_seed)
	local size_x = maxp.x - minp.x + 1
	local size_z = maxp.z - minp.z + 1
	local biome_map = {}
	local biomes_found = 0

	-- Load API for terrain classification
	local api = voxelgen and voxelgen.api or dofile(minetest.get_modpath("voxelgen") .. "/api.lua")

	-- Create extended heightmap with border sampling for smooth biome transitions
	local extended_heightmap = biomes.create_extended_heightmap(minp, maxp, heightmap, world_seed, api)

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local idx = (z - minp.z) * size_x + (x - minp.x + 1)

			local temperature = temperature_map[idx] or 15
			local humidity = humidity_map[idx] or 50
			local height = heightmap[idx] or 0

			-- Use smoothed height for biome selection near chunk borders
			local smoothed_height = biomes.get_smoothed_height_for_biome(x, z, minp, maxp, extended_heightmap, height)

			-- Get terrain classification based on noise values
			local terrain_class = api.classify_terrain(x, z, world_seed)

			local biome = biomes.get_biome_at(temperature, humidity, smoothed_height, terrain_class, x, z)
			biome_map[idx] = biome
			if biome then
				biomes_found = biomes_found + 1
			end
		end
	end

	-- Apply biome smoothing at chunk boundaries to prevent seams
	biome_map = biomes.smooth_biome_boundaries(biome_map, minp, maxp, extended_heightmap, world_seed, api)

	-- Debug logging
	local total_positions = size_x * size_z
	if biomes_found == 0 then
		minetest.log("warning", "[VoxelGen] No biomes found in chunk " .. minetest.pos_to_string(minp) .. " to " .. minetest.pos_to_string(maxp))
	else
		minetest.log("info", "[VoxelGen] Generated biome map: " .. biomes_found .. "/" .. total_positions .. " positions assigned biomes")
	end

	return biome_map
end

-- Create extended heightmap with border sampling for smooth biome transitions
function biomes.create_extended_heightmap(minp, maxp, heightmap, world_seed, api)
	local size_x = maxp.x - minp.x + 1
	local size_z = maxp.z - minp.z + 1
	local border_size = 3 -- Sample 3 blocks beyond chunk boundaries

	local extended_heightmap = {}

	-- Copy existing heightmap
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local idx = (z - minp.z) * size_x + (x - minp.x + 1)
			local ext_x = x - minp.x + border_size
			local ext_z = z - minp.z + border_size
			local ext_size_x = size_x + 2 * border_size
			local ext_idx = ext_z * ext_size_x + ext_x + 1
			extended_heightmap[ext_idx] = heightmap[idx]
		end
	end

	-- Sample border areas using API heightmap generation
	for z = minp.z - border_size, maxp.z + border_size do
		for x = minp.x - border_size, maxp.x + border_size do
			-- Skip positions already in the main heightmap
			if x < minp.x or x > maxp.x or z < minp.z or z > maxp.z then
				local ext_x = x - minp.x + border_size
				local ext_z = z - minp.z + border_size
				local ext_size_x = size_x + 2 * border_size
				local ext_idx = ext_z * ext_size_x + ext_x + 1

				-- Generate height for this border position
				local border_heightmap, _ = api.generate_heightmap(
					{x = x, y = minp.y, z = z},
					{x = x, y = maxp.y, z = z},
					world_seed
				)
				extended_heightmap[ext_idx] = border_heightmap[1] or 0
			end
		end
	end

	return {
		heightmap = extended_heightmap,
		minp = {x = minp.x - border_size, z = minp.z - border_size},
		maxp = {x = maxp.x + border_size, z = maxp.z + border_size},
		size_x = size_x + 2 * border_size,
		size_z = size_z + 2 * border_size,
		border_size = border_size
	}
end

-- Get smoothed height for biome selection, considering neighboring terrain
function biomes.get_smoothed_height_for_biome(x, z, minp, maxp, extended_heightmap, original_height)
	local border_distance = 2 -- Distance from chunk edge to apply smoothing

	-- Check if we're near a chunk boundary
	local near_x_border = (x - minp.x < border_distance) or (maxp.x - x < border_distance)
	local near_z_border = (z - minp.z < border_distance) or (maxp.z - z < border_distance)

	if not (near_x_border or near_z_border) then
		return original_height -- No smoothing needed for interior positions
	end

	-- Calculate smoothed height using extended heightmap
	local ext_x = x - extended_heightmap.minp.x
	local ext_z = z - extended_heightmap.minp.z
	local ext_idx = ext_z * extended_heightmap.size_x + ext_x + 1

	local center_height = extended_heightmap.heightmap[ext_idx] or original_height
	local total_height = center_height
	local sample_count = 1
	local smoothing_radius = 2

	-- Sample neighboring heights for smoothing
	for dz = -smoothing_radius, smoothing_radius do
		for dx = -smoothing_radius, smoothing_radius do
			if dx ~= 0 or dz ~= 0 then
				local sample_x = ext_x + dx
				local sample_z = ext_z + dz

				if sample_x >= 0 and sample_x < extended_heightmap.size_x and
				   sample_z >= 0 and sample_z < extended_heightmap.size_z then
					local sample_idx = sample_z * extended_heightmap.size_x + sample_x + 1
					local sample_height = extended_heightmap.heightmap[sample_idx]

					if sample_height then
						local distance = math.sqrt(dx * dx + dz * dz)
						local weight = 1.0 / (1.0 + distance)
						total_height = total_height + sample_height * weight
						sample_count = sample_count + weight
					end
				end
			end
		end
	end

	local smoothed_height = total_height / sample_count

	-- Blend between original and smoothed height based on distance from border
	local min_border_dist = math.min(
		x - minp.x, maxp.x - x,
		z - minp.z, maxp.z - z
	)
	local blend_factor = math.max(0, 1 - min_border_dist / border_distance)

	return original_height * (1 - blend_factor) + smoothed_height * blend_factor
end

-- Smooth biome boundaries to prevent seams at chunk edges
function biomes.smooth_biome_boundaries(biome_map, minp, maxp, extended_heightmap, world_seed, api)
	local size_x = maxp.x - minp.x + 1
	local size_z = maxp.z - minp.z + 1
	local smoothed_map = {}

	-- Copy original biome map
	for i, biome in pairs(biome_map) do
		smoothed_map[i] = biome
	end

	-- Apply smoothing near chunk boundaries
	local boundary_width = 2

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local idx = (z - minp.z) * size_x + (x - minp.x + 1)
			local current_biome = biome_map[idx]

			-- Check if we're near a boundary
			local near_boundary = (x - minp.x < boundary_width) or (maxp.x - x < boundary_width) or
								 (z - minp.z < boundary_width) or (maxp.z - z < boundary_width)

			if near_boundary and current_biome then
				-- Sample neighboring biomes and find consensus
				local neighbor_biomes = {}
				local biome_counts = {}

				for dz = -1, 1 do
					for dx = -1, 1 do
						local nx, nz = x + dx, z + dz
						if nx >= minp.x and nx <= maxp.x and nz >= minp.z and nz <= maxp.z then
							local n_idx = (nz - minp.z) * size_x + (nx - minp.x + 1)
							local neighbor_biome = biome_map[n_idx]

							if neighbor_biome then
								biome_counts[neighbor_biome.name] = (biome_counts[neighbor_biome.name] or 0) + 1
								neighbor_biomes[neighbor_biome.name] = neighbor_biome
							end
						end
					end
				end

				-- Find most common biome among neighbors
				local max_count = 0
				local consensus_biome = current_biome

				for biome_name, count in pairs(biome_counts) do
					if count > max_count then
						max_count = count
						consensus_biome = neighbor_biomes[biome_name]
					end
				end

				-- Apply consensus if it's significantly more common
				if max_count >= 5 and consensus_biome ~= current_biome then
					smoothed_map[idx] = consensus_biome
				end
			end
		end
	end

	return smoothed_map
end

-- Apply terrain nodes based on biome map (for mapgen compatibility)
function biomes.apply_terrain_nodes(data, area, minp, maxp, biome_map, heightmap)
	local size_x = maxp.x - minp.x + 1
	local biomes_applied = 0
	local total_positions = 0

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local idx = (z - minp.z) * size_x + (x - minp.x + 1)
			local biome = biome_map[idx]
			local terrain_height = math.floor(heightmap[idx] or 0)
			total_positions = total_positions + 1

			if biome then
				biomes_applied = biomes_applied + 1

				-- First pass: find the actual topmost stone block in this column
				local stone_id = nodes.get_content_id("stone")
				local actual_surface_y = nil

				for check_y = math.min(maxp.y, terrain_height + 10), math.max(minp.y, terrain_height - 20), -1 do
					if area:contains(x, check_y, z) then
						local check_vi = area:index(x, check_y, z)
						if data[check_vi] == stone_id then
							actual_surface_y = check_y
							break
						end
					end
				end

				-- If no stone found, skip this column
				if actual_surface_y then

				-- Debug surface detection for plains
				if biome.name == "plains" and (x % 16 == 0 and z % 16 == 0) then
					minetest.log("warning", string.format("[Plains Debug] Surface found at (%d,%d): surface_y=%d, terrain_height=%.1f",
						x, z, actual_surface_y, terrain_height))
				end

				-- Second pass: process all stone blocks in the column
				local depth_placed = 0

				for y = math.min(maxp.y, terrain_height + 10), math.max(minp.y, terrain_height - 20), -1 do
					if area:contains(x, y, z) then
						local vi = area:index(x, y, z)
						local current_node = data[vi]

						-- Only process stone blocks
						if current_node == stone_id then

						-- Determine what biome node to place based on depth from actual surface
						local target_node = nil
						local depth_from_surface = actual_surface_y - y
						local max_biome_depth = (biome.depth_top or 1) + (biome.depth_filler or 3) + (biome.depth_stone or 0)

						if depth_from_surface < (biome.depth_top or 1) then
							-- Surface/top layer - always place node_top regardless of water level
							target_node = biome.node_top
						elseif depth_from_surface < (biome.depth_top or 1) + (biome.depth_filler or 3) then
							-- Filler layer
							target_node = biome.node_filler
							depth_placed = depth_placed + 1
						elseif depth_from_surface < max_biome_depth and biome.node_stone and biome.node_stone ~= stone_id then
							-- Stone layer - only apply if biome stone is different from base stone and within depth limit
							target_node = biome.node_stone
						else
							-- Beyond biome influence - leave original stone
							target_node = nil
						end

						-- Apply the node if we determined one
						if target_node and target_node ~= current_node then
							data[vi] = target_node
						end

						-- Debug logging for plains biome issues
						if biome.name == "plains" and y == actual_surface_y and depth_from_surface == 0 then
							local target_name = target_node and minetest.get_name_from_content_id(target_node) or "nil"
							local current_name = minetest.get_name_from_content_id(current_node)
							minetest.log("warning", string.format("[Plains Debug] (%d,%d,%d): current=%s, target=%s, applied=%s, biome_node_top=%s",
								x, y, z, current_name, target_name, target_node and "yes" or "no",
								biome.node_top and minetest.get_name_from_content_id(biome.node_top) or "nil"))
						end

						end -- close if current_node == stone_id then
					end
				end

				end -- close if actual_surface_y then
			end
		end
	end

	minetest.log("info", "[VoxelGen] Applied terrain nodes: " .. biomes_applied .. "/" .. total_positions .. " positions processed")
end

-- Helper function to check if a position has sky view
local function has_sky_view(data, area, x, y, z, max_check_height)
	local c_air = minetest.get_content_id("air")
	local check_height = math.min(max_check_height, y + 50)
	for check_y = y + 1, check_height do
		if area:contains(x, check_y, z) then
			local check_vi = area:index(x, check_y, z)
			local node_id = data[check_vi]
			-- Ignore air and CONTENT_IGNORE blocks (unloaded areas)
			if node_id ~= c_air and node_id ~= minetest.CONTENT_IGNORE then
				return false -- Blocked by solid block
			end
		else
			-- Outside chunk bounds - assume clear sky above chunk
			return true
		end
	end
	return true -- Clear sky view
end

-- Apply biome materials to cave floors and exposed areas (for mapgen compatibility)
function biomes.apply_to_cave_floors(data, area, minp, maxp, biome_map, heightmap)
	local size_x = maxp.x - minp.x + 1
	local caves_processed = 0
	local c_air = minetest.get_content_id("air")
	local c_stone = minetest.get_content_id("vlf_blocks:stone")

	-- Find cave floors and exposed air areas with PERFECT TERRAIN-HEIGHT COUPLING
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local idx = (z - minp.z) * size_x + (x - minp.x + 1)
			local surface_biome = biome_map[idx] -- Surface biome for reference
			local terrain_height = math.floor(heightmap[idx] or 0)

			-- Scan for cave floors and exposed air
			for y = minp.y, maxp.y do
				if area:contains(x, y, z) then
					local vi = area:index(x, y, z)
					local current_node = data[vi]

					-- Check if this is exposed air in a cave
					if current_node == c_air then
						local is_cave_floor = false
						local floor_y = nil

						-- Look for the floor below this air space
						for check_y = y - 1, math.max(minp.y, y - 3), -1 do
							if area:contains(x, check_y, z) then
								local check_vi = area:index(x, check_y, z)
								local check_node = data[check_vi]

								if check_node == c_stone then
									is_cave_floor = true
									floor_y = check_y
									break
								elseif check_node ~= c_air then
									break
								end
							end
						end

						-- If we found a cave floor, apply PERFECT TERRAIN-HEIGHT COUPLING
						if is_cave_floor and floor_y then
							-- PERFECT COUPLING: Select biome based on the actual cave floor Y-coordinate
							-- instead of using the surface biome
							local cave_biome = nil

							-- Get terrain classification for this position
							local api = voxelgen and voxelgen.api or dofile(minetest.get_modpath("voxelgen") .. "/api.lua")
							local terrain_class = api.classify_terrain(x, z, voxelgen.mapgen.world_seed or 0)

							-- Use the climate system to get proper biome for this Y-level
							if voxelgen and voxelgen.climate and voxelgen.climate.get_biome_parameters then
								local parameters = voxelgen.climate.get_biome_parameters(x, z, floor_y, terrain_height)
								if parameters then
									-- Set the Y parameter to the actual cave floor Y-coordinate
									parameters.y = floor_y
									parameters.terrain_height = terrain_height
									parameters.actual_y = floor_y
									parameters.depth_below_surface = math.max(0, terrain_height - floor_y)
									parameters.is_underground = (terrain_height - floor_y) > 1

									-- Get the perfect terrain-coupled biome for this cave floor
									cave_biome = biome_manager.get_best_biome(parameters)
								end
							end

							-- Fallback to surface biome if perfect coupling fails
							if not cave_biome then
								cave_biome = surface_biome
							end

							if cave_biome then
								-- Calculate depth from surface
								local depth = math.max(0, (terrain_height - y) * 0.0078125)

								-- Check if this is an underground biome (depth > 0.05)
								local is_underground_biome = (cave_biome.depth_min or 0) > 0.05

								-- Apply biome integration only if:
								-- 1. It's NOT an underground biome, AND
								-- 2. There's unobstructed sky view for 50m, AND
								-- 3. Depth is no greater than 0.05
								local should_apply_biome = not is_underground_biome and
														 has_sky_view(data, area, x, y, z, maxp.y) and
														 depth <= 0.05

								if should_apply_biome then
									-- Apply PERFECT TERRAIN-COUPLED biome top material to the floor
									local floor_vi = area:index(x, floor_y, z)
									data[floor_vi] = cave_biome.node_top

									-- Apply PERFECT TERRAIN-COUPLED biome filler material 1-2 blocks below
									for depth_blocks = 1, math.min(2, cave_biome.depth_filler or 2) do
										local filler_y = floor_y - depth_blocks
										if area:contains(x, filler_y, z) then
											local filler_vi = area:index(x, filler_y, z)
											if data[filler_vi] == c_stone then
												data[filler_vi] = cave_biome.node_filler
											end
										end
									end

									-- Apply biome materials to surrounding blocks (1-2 blocks around)
									for dx = -1, 1 do
										for dz = -1, 1 do
											for dy = -1, 1 do
												if dx ~= 0 or dz ~= 0 or dy ~= 0 then
													local surround_x = x + dx
													local surround_y = floor_y + dy
													local surround_z = z + dz

													if area:contains(surround_x, surround_y, surround_z) then
														local surround_vi = area:index(surround_x, surround_y, surround_z)
														local surround_node = data[surround_vi]

														-- Only replace stone blocks near cave openings
														if surround_node == c_stone then
															-- Check if this block is adjacent to air (exposed)
															local is_exposed = false
															for edx = -1, 1 do
																for edz = -1, 1 do
																	for edy = -1, 1 do
																		if edx ~= 0 or edz ~= 0 or edy ~= 0 then
																			local exp_x = surround_x + edx
																			local exp_y = surround_y + edy
																			local exp_z = surround_z + edz

																			if area:contains(exp_x, exp_y, exp_z) then
																				local exp_vi = area:index(exp_x, exp_y, exp_z)
																				if data[exp_vi] == c_air then
																					is_exposed = true
																					break
																				end
																			end
																		end
																	end
																	if is_exposed then break end
																end
																if is_exposed then break end
															end

															-- Apply PERFECT TERRAIN-COUPLED biome material to exposed blocks
															if is_exposed then
																if dy == 0 then -- Same level as floor
																	data[surround_vi] = cave_biome.node_filler
																elseif dy == -1 then -- Below floor
																	data[surround_vi] = cave_biome.node_filler
																else -- Above floor
																	data[surround_vi] = cave_biome.node_top
																end
															end
														end
													end
												end
											end
										end
									end

									caves_processed = caves_processed + 1
								end
							end
						end
					end
				end
			end
		end
	end

	-- Debug logging
	if caves_processed > 0 then
		minetest.log("info", "[VoxelGen] Applied biomes to " .. caves_processed .. " cave floor areas in chunk")
	end
end

return biomes
