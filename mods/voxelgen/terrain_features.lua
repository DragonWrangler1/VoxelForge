-- terrain_features.lua - Terrain feature placement system for VoxelGen
-- Handles placement of decorative elements, structures, and surface coverings

local terrain_features = {}

-- Load dependencies
local api = dofile(minetest.get_modpath("voxelgen") .. "/api.lua")
local nodes = dofile(minetest.get_modpath("voxelgen") .. "/nodes.lua")

-- Feature registry
local registered_features = {}
local feature_noise_objects = {}
local world_seed = nil

-- Cross-chunk placement system
local deferred_features = {} -- Features waiting to be placed in future chunks
local chunk_size = 16 -- Standard Minetest chunk size

-- Logging helper
local function log(level, message)
	minetest.log(level, "[VoxelGen TerrainFeatures] " .. message)
end

-- Helper function to get chunk coordinates from world position
local function get_chunk_pos(x, z)
	return math.floor(x / chunk_size), math.floor(z / chunk_size)
end

-- Helper function to get chunk key for deferred features
local function get_chunk_key(chunk_x, chunk_z)
	return chunk_x .. "," .. chunk_z
end

-- Add a feature to the deferred placement queue
local function defer_feature_placement(chunk_x, chunk_z, feature_data)
	local chunk_key = get_chunk_key(chunk_x, chunk_z)
	if not deferred_features[chunk_key] then
		deferred_features[chunk_key] = {}
	end
	table.insert(deferred_features[chunk_key], feature_data)
	log("info", "Deferred feature placement to chunk " .. chunk_key .. ": " .. feature_data.feature_name)
end

-- Process deferred features for a chunk
local function process_deferred_features(data, area, minp, maxp, biome_map, heightmap)
	local chunk_x, chunk_z = get_chunk_pos(minp.x, minp.z)
	local chunk_key = get_chunk_key(chunk_x, chunk_z)

	local deferred_list = deferred_features[chunk_key]
	if not deferred_list then
		return 0 -- No deferred features for this chunk
	end

	local placed_count = 0
	for i, feature_data in ipairs(deferred_list) do
		local feature_def = registered_features[feature_data.feature_name]
		if feature_def then
			local x, y, z = feature_data.x, feature_data.y, feature_data.z

			-- Check if the position is within the current area
			if area:contains(x, y, z) then
				local placed = false

				if feature_def.type == "block" then
					placed = place_block_feature(feature_def, x, y, z, data, area)
				elseif feature_def.type == "function" then
					placed = place_function_feature(feature_def, x, y, z, data, area, feature_data.biome_name)
				elseif feature_def.type == "schematic" then
					placed = place_schematic_feature(feature_def, x, y, z, data, area)
				end

				if placed then
					placed_count = placed_count + 1
					log("info", "Placed deferred feature " .. feature_data.feature_name .. " at " .. x .. "," .. y .. "," .. z)
				end
			end
		end
	end

	-- Clear processed deferred features
	deferred_features[chunk_key] = nil

	return placed_count
end

-- Initialize the terrain features system
function terrain_features.init(seed)
	world_seed = seed
	log("info", "Initializing terrain features system with seed: " .. world_seed)

	-- Initialize noise objects for registered features (including those registered before init)
	for feature_name, feature_def in pairs(registered_features) do
		if feature_def.noise and not feature_noise_objects[feature_name] then
			local noise_params = {
				offset = feature_def.noise.offset or 0,
				scale = feature_def.noise.scale or 1,
				spread = feature_def.noise.spread or {x = 100, y = 100, z = 100},
				seed = (feature_def.noise.seed or 0) + world_seed,
				octaves = feature_def.noise.octaves or 3,
				persist = feature_def.noise.persist or 0.6,
				lacunarity = feature_def.noise.lacunarity or 2.0,
				flags = feature_def.noise.flags or "defaults"
			}

			feature_noise_objects[feature_name] = PerlinNoise(noise_params)
			log("info", "Initialized noise for feature: " .. feature_name)
		end
	end

	local feature_count = 0
	for _ in pairs(registered_features) do
		feature_count = feature_count + 1
	end
	log("info", "Terrain features system initialized with " .. feature_count .. " features")
end

-- Register a terrain feature
function terrain_features.register_feature(name, definition)
	if not name or not definition then
		log("error", "Invalid feature definition provided to register_feature")
		return false
	end

	log("info", "Registering terrain feature: " .. name)

	-- Validate required fields
	if not definition.type then
		log("error", "Feature '" .. name .. "' missing required 'type' field")
		return false
	end

	if not definition.biomes or #definition.biomes == 0 then
		log("error", "Feature '" .. name .. "' missing required 'biomes' field")
		return false
	end

	-- Validate feature type
	local valid_types = {"block", "function", "schematic"}
	local type_valid = false
	for _, valid_type in ipairs(valid_types) do
		if definition.type == valid_type then
			type_valid = true
			break
		end
	end

	if not type_valid then
		log("error", "Feature '" .. name .. "' has invalid type: " .. definition.type)
		return false
	end

	-- Type-specific validation
	if definition.type == "block" and not definition.node then
		log("error", "Block feature '" .. name .. "' missing required 'node' field")
		return false
	elseif definition.type == "function" and not definition.place_function then
		log("error", "Function feature '" .. name .. "' missing required 'place_function' field")
		return false
	elseif definition.type == "schematic" and not definition.schematic then
		log("error", "Schematic feature '" .. name .. "' missing required 'schematic' field")
		return false
	end

	-- Resolve node name to content ID for block features
	if definition.type == "block" then
		-- Check if the node exists first
		if not minetest.registered_nodes[definition.node] then
			log("error", "Block feature '" .. name .. "' has unknown node: " .. definition.node)
			return false
		end

		local node_id = minetest.get_content_id(definition.node)
		if not node_id or node_id == minetest.get_content_id("air") then
			log("error", "Block feature '" .. name .. "' has invalid node: " .. definition.node)
			return false
		end
		definition.node_id = node_id
		log("info", "Resolved node '" .. definition.node .. "' to content ID " .. node_id .. " for feature " .. name)
	end

	-- Set defaults
	definition.probability = definition.probability or 0.1
	definition.min_height = definition.min_height or -31000
	definition.max_height = definition.max_height or 31000
	definition.avoid_water = definition.avoid_water ~= false -- Default true
	definition.need_solid_ground = definition.need_solid_ground ~= false -- Default true
	definition.spacing = definition.spacing or 1 -- Minimum spacing between features

	-- Process place_on field if provided
	if definition.place_on then
		if type(definition.place_on) == "string" then
			-- Convert single node name to table
			definition.place_on = {definition.place_on}
		elseif type(definition.place_on) ~= "table" then
			log("error", "Feature '" .. name .. "' has invalid place_on field (must be string or table)")
			return false
		end

		-- Validate and resolve node names to content IDs
		definition.place_on_ids = {}
		for i, node_name in ipairs(definition.place_on) do
			if not minetest.registered_nodes[node_name] then
				log("error", "Feature '" .. name .. "' has unknown node in place_on: " .. node_name)
				return false
			end

			local node_id = minetest.get_content_id(node_name)
			if not node_id or node_id == minetest.get_content_id("air") then
				log("error", "Feature '" .. name .. "' has invalid node in place_on: " .. node_name)
				return false
			end

			definition.place_on_ids[node_id] = true
			log("info", "Added place_on node '" .. node_name .. "' (ID: " .. node_id .. ") for feature " .. name)
		end
	end

	-- Default noise parameters if not provided
	if not definition.noise then
		definition.noise = {
			offset = 0,
			scale = 1,
			spread = {x = 50, y = 50, z = 50},
			seed = 0,
			octaves = 3,
			persist = 0.6,
			lacunarity = 2.0,
			flags = "defaults"
		}
	end

	registered_features[name] = definition
	log("info", "Registered terrain feature: " .. name .. " (type: " .. definition.type .. ")")

	-- Create noise object immediately if we have a world seed
	if world_seed and definition.noise then
		local noise_params = {
			offset = definition.noise.offset or 0,
			scale = definition.noise.scale or 1,
			spread = definition.noise.spread or {x = 100, y = 100, z = 100},
			seed = (definition.noise.seed or 0) + world_seed,
			octaves = definition.noise.octaves or 3,
			persist = definition.noise.persist or 0.6,
			lacunarity = definition.noise.lacunarity or 2.0,
			flags = definition.noise.flags or "defaults"
		}

		feature_noise_objects[name] = PerlinNoise(noise_params)
		log("info", "Created noise object for feature: " .. name)
	else
		log("info", "Deferring noise object creation for feature: " .. name .. " (world_seed: " .. tostring(world_seed) .. ")")
	end

	return true
end

-- Get all registered features
function terrain_features.get_registered_features()
	return registered_features
end

-- Check if a feature can be placed in a biome
local function can_place_in_biome(feature_def, biome_name)
	for _, allowed_biome in ipairs(feature_def.biomes) do
		if allowed_biome == biome_name or allowed_biome == "*" then
			return true
		end
	end
	-- Debug: Log biome mismatch for debugging
	log("info", "Biome '" .. tostring(biome_name) .. "' not in allowed list: " .. table.concat(feature_def.biomes, ", "))
	return false
end

-- Check if position is suitable for feature placement
local function is_position_suitable(feature_def, x, y, z, data, area, biome_name, heightmap_idx, heightmap)
	-- Check biome compatibility
	if not can_place_in_biome(feature_def, biome_name) then
		return false
	end

	-- Check height limits
	if y < feature_def.min_height or y > feature_def.max_height then
		return false
	end

	-- Check if we need solid ground
	if feature_def.need_solid_ground then
		local ground_vi = area:index(x, y - 1, z)
		if not area:contains(x, y - 1, z) or data[ground_vi] == minetest.get_content_id("air") then
			return false
		end

		-- Check place_on restrictions if specified
		if feature_def.place_on_ids then
			local ground_node_id = data[ground_vi]
			local place_on_valid = feature_def.place_on_ids[ground_node_id]

			-- If not directly valid, check if this could be a biome surface
			if not place_on_valid then
				-- Additional check: if place_on includes top blocks, also check if this is a valid surface
				-- This handles cases where biomes have converted stone to dirt/grass but we want to place on grass
				local terrain_height = heightmap and heightmap[heightmap_idx] or y
				local expected_surface_y = math.floor(terrain_height)

				-- If we're placing on the expected surface level, be more lenient
				if y - 1 == expected_surface_y then
					-- Check if any of the place_on nodes are biome top nodes
					if biome_name then
						-- Get biome info to check if this could be a valid surface
						local biomes = voxelgen and voxelgen.biomes and voxelgen.biomes.get_registered_biomes()
						if biomes then
							for _, biome in pairs(biomes) do
								if biome.name == biome_name and biome.node_top and feature_def.place_on_ids[biome.node_top] then
									-- This biome's top node is in our place_on list, allow placement
									log("info", "Allowing placement on biome surface for feature at " .. x .. "," .. y .. "," .. z)
									place_on_valid = true
									break
								end
							end
						end
					end
				end
			end

			if not place_on_valid then
				return false
			end
		end
	end

	-- Check water avoidance
	if feature_def.avoid_water then
		local water_id = nodes.get_content_id("water_source")
		local current_vi = area:index(x, y, z)
		if area:contains(x, y, z) and data[current_vi] == water_id then
			return false
		end

		-- Also check if we're below water level
		local terrain_height = heightmap and heightmap[heightmap_idx] or y
		if y <= api.SEA_LEVEL and terrain_height <= api.SEA_LEVEL then
			return false
		end
	end

	return true
end

-- Place a single block feature
local function place_block_feature(feature_def, x, y, z, data, area)
	local node_id = feature_def.node_id -- Use pre-resolved content ID
	if not node_id or node_id == minetest.get_content_id("air") then
		log("warning", "Invalid node ID for block feature: " .. tostring(node_id))
		return false
	end

	local vi = area:index(x, y, z)
	if area:contains(x, y, z) then
		log("info", "Placing block with node_id " .. node_id .. " at " .. x .. "," .. y .. "," .. z .. " (vi=" .. vi .. ")")
		data[vi] = node_id
		return true
	else
		log("warning", "Position " .. x .. "," .. y .. "," .. z .. " not contained in area")
		return false
	end
end

-- Place a function-based feature
local function place_function_feature(feature_def, x, y, z, data, area, biome_name)
	if type(feature_def.place_function) == "function" then
		return feature_def.place_function(x, y, z, data, area, biome_name, feature_def)
	else
		log("warning", "place_function is not a valid function")
		return false
	end
end

-- Place a schematic feature
local function place_schematic_feature(feature_def, x, y, z, data, area)
	-- For now, we'll implement a simple schematic placement
	-- This could be expanded to support .mts files later
	if type(feature_def.schematic) == "table" then
		-- Simple table-based schematic
		for _, node_def in ipairs(feature_def.schematic) do
			local place_x = x + (node_def.x or 0)
			local place_y = y + (node_def.y or 0)
			local place_z = z + (node_def.z or 0)

			if area:contains(place_x, place_y, place_z) then
				-- Use pre-resolved content ID if available, otherwise resolve now
				local node_id = node_def.node_id or minetest.get_content_id(node_def.node)
				if node_id and node_id ~= minetest.get_content_id("air") then
					local vi = area:index(place_x, place_y, place_z)
					data[vi] = node_id
				end
			end
		end
		return true
	elseif type(feature_def.schematic) == "string" then
		-- TODO: Implement .mts file loading
		log("warning", "MTS schematic files not yet implemented: " .. feature_def.schematic)
		return false
	end

	return false
end

-- Generate terrain features for a chunk
function terrain_features.generate_features(data, area, minp, maxp, biome_map, heightmap, world_seed)
	if not world_seed then
		log("warning", "No world seed provided for feature generation")
		return
	end

	local size_x = maxp.x - minp.x + 1
	local features_placed = 0
	local total_features = 0

	-- First, process any deferred features for this chunk
	local deferred_placed = process_deferred_features(data, area, minp, maxp, biome_map, heightmap)
	features_placed = features_placed + deferred_placed
	if deferred_placed > 0 then
		log("info", "Placed " .. deferred_placed .. " deferred features in chunk " .. minetest.pos_to_string(minp))
	end
	for _ in pairs(registered_features) do
		total_features = total_features + 1
	end

	if total_features == 0 then
		log("warning", "No terrain features registered")
		return
	end

	log("info", "Generating " .. total_features .. " terrain features for chunk " .. minetest.pos_to_string(minp))

	-- Process each registered feature
	for feature_name, feature_def in pairs(registered_features) do
		local noise_obj = feature_noise_objects[feature_name]
		if not noise_obj then
			log("warning", "No noise object for feature: " .. feature_name .. ", creating one now...")
			-- Create noise object on-demand if missing
			if feature_def.noise and world_seed then
				local noise_params = {
					offset = feature_def.noise.offset or 0,
					scale = feature_def.noise.scale or 1,
					spread = feature_def.noise.spread or {x = 100, y = 100, z = 100},
					seed = (feature_def.noise.seed or 0) + world_seed,
					octaves = feature_def.noise.octaves or 3,
					persist = feature_def.noise.persist or 0.6,
					lacunarity = feature_def.noise.lacunarity or 2.0,
					flags = feature_def.noise.flags or "defaults"
				}

				feature_noise_objects[feature_name] = PerlinNoise(noise_params)
				noise_obj = feature_noise_objects[feature_name]
				log("info", "Created on-demand noise object for feature: " .. feature_name)
			else
				log("error", "Cannot create noise object for feature: " .. feature_name .. " (missing noise config or world_seed)")
			end
		end

		if noise_obj then
			-- Sample positions for this feature
			local spacing = math.max(1, feature_def.spacing) -- Ensure spacing is at least 1
			for z = minp.z, maxp.z, spacing do
				for x = minp.x, maxp.x, spacing do
					local idx = (z - minp.z) * size_x + (x - minp.x + 1)
					local biome = biome_map[idx]
					local biome_name = biome and biome.name or "unknown"

					-- Debug: Log biome names for the first few positions
					if x == minp.x and z == minp.z then
						log("info", "Feature " .. feature_name .. " checking biome: " .. biome_name .. " (allowed: " .. table.concat(feature_def.biomes, ", ") .. ")")
					end

					-- Additional debug: Log more details about feature placement attempts
					if x % 16 == 0 and z % 16 == 0 then -- Log every 16 blocks
						log("info", "Feature " .. feature_name .. " at " .. x .. "," .. z .. " - biome: " .. biome_name .. ", can_place: " .. tostring(can_place_in_biome(feature_def, biome_name)))
					end

					-- Get noise value for probability calculation
					local noise_val = noise_obj:get_2d({x = x, y = z})
					-- Convert noise from [-1,1] to [0,1] range
					local probability = (noise_val + 1) / 2

					-- Check if we should place this feature based on probability
					local should_place = probability <= feature_def.probability
					if not should_place then
						if x % 16 == 0 and z % 16 == 0 then
							log("info", "Feature " .. feature_name .. " at " .. x .. "," .. z .. " - probability check failed: " .. probability .. " > " .. feature_def.probability)
						end
					end

					if should_place then
						-- Find suitable placement height
						local terrain_height = heightmap[idx] or api.SEA_LEVEL
						local placement_y = math.floor(terrain_height) + 1 -- Place on surface

						-- Check if placement position is within current area, or defer to future chunk
						if placement_y >= area.MinEdge.y and placement_y <= area.MaxEdge.y and
						   x >= area.MinEdge.x and x <= area.MaxEdge.x and
						   z >= area.MinEdge.z and z <= area.MaxEdge.z then
							-- Position is within current VoxelManip area, place immediately
							-- Check if position is suitable
							if is_position_suitable(feature_def, x, placement_y, z, data, area, biome_name, idx, heightmap) then
								-- Place the feature based on its type
								local placed = false
								-- Attempt to place the feature

								if feature_def.type == "block" then
									placed = place_block_feature(feature_def, x, placement_y, z, data, area)
									if placed then
										log("info", "Successfully placed block feature " .. feature_name .. " at " .. x .. "," .. placement_y .. "," .. z)
									else
										log("warning", "Failed to place block feature " .. feature_name .. " at " .. x .. "," .. placement_y .. "," .. z)
									end
								elseif feature_def.type == "function" then
									placed = place_function_feature(feature_def, x, placement_y, z, data, area, biome_name)
									if placed then
										log("info", "Successfully placed function feature " .. feature_name .. " at " .. x .. "," .. placement_y .. "," .. z)
									else
										log("warning", "Failed to place function feature " .. feature_name .. " at " .. x .. "," .. placement_y .. "," .. z)
									end
								elseif feature_def.type == "schematic" then
									placed = place_schematic_feature(feature_def, x, placement_y, z, data, area)
									if placed then
										log("info", "Successfully placed schematic feature " .. feature_name .. " at " .. x .. "," .. placement_y .. "," .. z)
									else
										log("warning", "Failed to place schematic feature " .. feature_name .. " at " .. x .. "," .. placement_y .. "," .. z)
									end
								end

								if placed then
									features_placed = features_placed + 1
								end
							else
								if x % 16 == 0 and z % 16 == 0 then
									log("info", "Feature " .. feature_name .. " at " .. x .. "," .. placement_y .. "," .. z .. " - position not suitable")
								end
							end
						else
							-- Position extends beyond current area, defer to appropriate chunk
							local target_chunk_x, target_chunk_z = get_chunk_pos(x, z)
							local current_chunk_x, current_chunk_z = get_chunk_pos(minp.x, minp.z)

							-- Only defer if it's actually in a different chunk
							if target_chunk_x ~= current_chunk_x or target_chunk_z ~= current_chunk_z then
								local feature_data = {
									feature_name = feature_name,
									x = x,
									y = placement_y,
									z = z,
									biome_name = biome_name
								}
								defer_feature_placement(target_chunk_x, target_chunk_z, feature_data)
							end
						end
					end
				end
			end
		end
	end

	if features_placed > 0 then
		log("info", "Placed " .. features_placed .. " terrain features in chunk")
	end
end

-- Apply node dust based on biome configuration (placed on top of node_top blocks)
function terrain_features.apply_node_dust(data, area, minp, maxp, biome_map, heightmap)
	local size_x = maxp.x - minp.x + 1
	local dust_applied = 0
	local biomes_with_dust = 0

	-- Count biomes with node dust
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local idx = (z - minp.z) * size_x + (x - minp.x + 1)
			local biome = biome_map[idx]
			if biome and biome.node_dust then
				biomes_with_dust = biomes_with_dust + 1
				break
			end
		end
		if biomes_with_dust > 0 then break end
	end

	log("info", "Applying node dust for chunk " .. minetest.pos_to_string(minp) .. " to " .. minetest.pos_to_string(maxp) .. " - found " .. biomes_with_dust .. " biomes with dust config")

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local idx = (z - minp.z) * size_x + (x - minp.x + 1)
			local biome = biome_map[idx]

			if biome and biome.node_dust then
				local terrain_height = math.floor(heightmap[idx] or api.SEA_LEVEL)
				local surface_y = terrain_height

				-- Find the actual surface by looking for the topmost solid block (node_top)
				local air_id = minetest.get_content_id("air")
				local node_top_id = biome.node_top -- This should be the content ID of the top node

				for check_y = math.min(area.MaxEdge.y, terrain_height + 5), math.max(area.MinEdge.y, terrain_height - 5), -1 do
					if area:contains(x, check_y, z) then
						local check_vi = area:index(x, check_y, z)
						if data[check_vi] ~= air_id then
							surface_y = check_y
							break
						end
					end
				end

				local dust_node_id = biome.node_dust -- Already resolved to content ID during biome registration

				if dust_node_id and dust_node_id ~= minetest.get_content_id("air") then
					-- Node dust is always placed on top of the node_top block
					local place_y = surface_y + 1

					-- Check if placement position is within VoxelManip area bounds
					if place_y >= area.MinEdge.y and place_y <= area.MaxEdge.y then
						local place_vi = area:index(x, place_y, z)
						if area:contains(x, place_y, z) then
							-- Make sure there's air above the surface and the surface is node_top
							local surface_vi = area:index(x, surface_y, z)
							if data[place_vi] == air_id and area:contains(x, surface_y, z) and data[surface_vi] == node_top_id then
								data[place_vi] = dust_node_id
								dust_applied = dust_applied + 1
							end
						end
					end
				else
					log("warning", "Invalid node dust node ID: " .. tostring(dust_node_id))
				end
			end
		end
	end

	if dust_applied > 0 then
		log("info", "Applied " .. dust_applied .. " node dust blocks")
	end
end

-- Get statistics about registered features
function terrain_features.get_statistics()
	local stats = {
		total_features = 0,
		by_type = {
			block = 0,
			["function"] = 0,
			schematic = 0
		},
		by_biome = {}
	}

	for feature_name, feature_def in pairs(registered_features) do
		stats.total_features = stats.total_features + 1
		stats.by_type[feature_def.type] = (stats.by_type[feature_def.type] or 0) + 1

		for _, biome_name in ipairs(feature_def.biomes) do
			stats.by_biome[biome_name] = (stats.by_biome[biome_name] or 0) + 1
		end
	end

	return stats
end

return terrain_features