-- cave_generator.lua - Cave generation for mapgen environment
-- This script handles cave generation using noise-based algorithms in the mapgen environment
-- Uses IPC to communicate with the main environment

local cave_gen = {}

-- Cave generation parameters (will be received via IPC)
local cave_config = {}
local noise_objects = {}
local world_seed = nil

-- Content IDs
local c_air, c_stone, c_water

-- Initialize content IDs
local function init_content_ids()
	c_air = core.get_content_id("air")
	c_stone = core.get_content_id("vlf_blocks:stone") or core.get_content_id("stone")
	c_water = core.get_content_id("vlf_blocks:water_source") or core.get_content_id("water_source")
end

-- Get shared data from IPC
local function get_shared_data()
	local api_data = core.ipc_get("voxelgen:api")
	local caves_config = core.ipc_get("voxelgen:caves_config")
	local seed = core.ipc_get("voxelgen:world_seed")

	if not seed then
		core.log("warning", "[VoxelGen Mapgen] Cave generator: World seed not available via IPC")
		return nil
	end

	return {
		api = api_data,
		caves_config = caves_config,
		world_seed = seed
	}
end

-- Initialize cave noise objects
local function init_cave_noise(seed, config)
	if not config then
		core.log("error", "[VoxelGen Mapgen] Cave generator: No cave config available")
		return false
	end

	noise_objects = {}

	-- Initialize cheese cave noise
	if config.cheese and config.cheese.enabled then
		noise_objects.cheese_main = core.get_perlin({
			offset = config.cheese.noise_params.main.offset,
			scale = config.cheese.noise_params.main.scale,
			spread = config.cheese.noise_params.main.spread,
			seed = seed + 12345,
			octaves = config.cheese.noise_params.main.octaves,
			persist = config.cheese.noise_params.main.persist,
			lacunarity = config.cheese.noise_params.main.lacunarity
		})

		noise_objects.cheese_layer = core.get_perlin({
			offset = config.cheese.noise_params.layer.offset,
			scale = config.cheese.noise_params.layer.scale,
			spread = config.cheese.noise_params.layer.spread,
			seed = seed + 54321,
			octaves = config.cheese.noise_params.layer.octaves,
			persist = config.cheese.noise_params.layer.persist,
			lacunarity = config.cheese.noise_params.layer.lacunarity
		})

		noise_objects.cheese_terrain = core.get_perlin({
			offset = config.cheese.noise_params.terrain.offset,
			scale = config.cheese.noise_params.terrain.scale,
			spread = config.cheese.noise_params.terrain.spread,
			seed = seed + 98765,
			octaves = config.cheese.noise_params.terrain.octaves,
			persist = config.cheese.noise_params.terrain.persist,
			lacunarity = config.cheese.noise_params.terrain.lacunarity
		})
	end

	-- Initialize tunnel cave noise
	if config.tunnels and config.tunnels.enabled then
		noise_objects.tunnel_connectivity = core.get_perlin({
			offset = config.tunnels.noise_params.connectivity.offset,
			scale = config.tunnels.noise_params.connectivity.scale,
			spread = config.tunnels.noise_params.connectivity.spread,
			seed = seed + 12345,
			octaves = config.tunnels.noise_params.connectivity.octaves,
			persist = config.tunnels.noise_params.connectivity.persist,
			lacunarity = config.tunnels.noise_params.connectivity.lacunarity
		})

		noise_objects.tunnel_surface = core.get_perlin({
			offset = config.tunnels.noise_params.surface.offset,
			scale = config.tunnels.noise_params.surface.scale,
			spread = config.tunnels.noise_params.surface.spread,
			seed = seed + 5678,
			octaves = config.tunnels.noise_params.surface.octaves,
			persist = config.tunnels.noise_params.surface.persist,
			lacunarity = config.tunnels.noise_params.surface.lacunarity
		})
	end

	return true
end

-- Utility functions
local function clamp(value, min_val, max_val)
	return math.max(min_val, math.min(max_val, value))
end

-- Cheese cave generation - fluid blending between Y layers with chunk boundary smoothing
local function get_cheese_cave_density(x, y, z, chunk_minp, chunk_maxp)
	if not noise_objects.cheese_main then
		return 1 -- No caves if not initialized
	end

	-- Use fractional Y coordinates for smoother blending between layers
	local y_offset = (cave_config.cheese and cave_config.cheese.y_offset) or 0.5 -- Add offset to break up layer alignment
	local smooth_y = y + y_offset

	-- Sample noise at multiple Y levels for smooth interpolation
	local y_floor = math.floor(smooth_y)
	local y_ceil = y_floor + 1
	local y_frac = smooth_y - y_floor

	-- Enhanced sampling for chunk boundary smoothing
	local sample_positions = {}
	local sample_weights = {}

	-- Base position
	table.insert(sample_positions, {x = x, y = y_floor, z = z})
	table.insert(sample_positions, {x = x, y = y_ceil, z = z})
	table.insert(sample_weights, 1.0)
	table.insert(sample_weights, 1.0)

	-- Add neighboring samples near chunk boundaries for smoother transitions
	if chunk_minp and chunk_maxp then
		local border_distance = 3
		local near_border = (x - chunk_minp.x < border_distance) or (chunk_maxp.x - x < border_distance) or
						   (z - chunk_minp.z < border_distance) or (chunk_maxp.z - z < border_distance)

		if near_border then
			-- Sample neighboring positions for smoother cave transitions
			local offsets = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}}
			for _, offset in ipairs(offsets) do
				local nx, nz = x + offset[1], z + offset[2]
				table.insert(sample_positions, {x = nx, y = y_floor, z = nz})
				table.insert(sample_positions, {x = nx, y = y_ceil, z = nz})
				table.insert(sample_weights, 0.3) -- Lower weight for neighboring samples
				table.insert(sample_weights, 0.3)
			end
		end
	end

	-- Calculate weighted average of all samples
	local total_cheese_val = 0
	local total_layer_val = 0
	local total_terrain_val = 0
	local total_weight = 0

	for i = 1, #sample_positions, 2 do
		local pos_floor = sample_positions[i]
		local pos_ceil = sample_positions[i + 1]
		local weight = sample_weights[i]

		-- Get noise values for both Y levels
		local cheese_val_floor = noise_objects.cheese_main:get_3d(pos_floor)
		local cheese_val_ceil = noise_objects.cheese_main:get_3d(pos_ceil)
		local layer_val_floor = noise_objects.cheese_layer:get_3d(pos_floor)
		local layer_val_ceil = noise_objects.cheese_layer:get_3d(pos_ceil)
		local terrain_val_floor = noise_objects.cheese_terrain:get_3d(pos_floor)
		local terrain_val_ceil = noise_objects.cheese_terrain:get_3d(pos_ceil)

		-- Smooth interpolation between Y levels using cubic interpolation for better blending
		local smooth_frac = y_frac * y_frac * (3.0 - 2.0 * y_frac) -- Smoothstep function

		local cheese_val = cheese_val_floor + (cheese_val_ceil - cheese_val_floor) * smooth_frac
		local layer_val = layer_val_floor + (layer_val_ceil - layer_val_floor) * smooth_frac
		local terrain_val = terrain_val_floor + (terrain_val_ceil - terrain_val_floor) * smooth_frac

		total_cheese_val = total_cheese_val + cheese_val * weight
		total_layer_val = total_layer_val + layer_val * weight
		total_terrain_val = total_terrain_val + terrain_val * weight
		total_weight = total_weight + weight
	end

	-- Normalize by total weight
	local cheese_val = total_cheese_val / total_weight
	local layer_val = total_layer_val / total_weight
	local terrain_val = total_terrain_val / total_weight

	-- Add additional Y-based variation to break up horizontal layers
	local blend_strength = (cave_config.cheese and cave_config.cheese.y_blend_strength) or 0.15
	local y_variation = (math.sin(y * 0.1) * 0.1 + math.cos(y * 0.07) * 0.05) * blend_strength

	-- Optimized calculations with Y variation for fluid blending
	local cave_scaled = 4.0 * layer_val * layer_val + y_variation
	local cheese_scaled = cheese_val * 0.6666666666666666
	local cheese_clamped = clamp(0.27 + cheese_scaled, -1.0, 1.0)
	local terrain_blend = clamp(1.5 - 0.64 * terrain_val, 0.0, 0.5)

	return clamp(cave_scaled + cheese_clamped + terrain_blend, -1.0, 1.0)
end

-- Optimized cheese cave check with chunk boundary smoothing
local function should_be_cheese_cave(x, y, z, skip_rarity_check, chunk_minp, chunk_maxp)
	-- Check Y bounds first (fastest check)
	if y < cave_config.cheese.min_y or y > cave_config.cheese.max_y then
		return false
	end

	-- Skip rarity check if already done in batch processing
	if not skip_rarity_check then
		local rarity_scale = 0.1
		local rarity_pos = {x = x * rarity_scale, y = y * rarity_scale, z = z * rarity_scale}
		local rarity_noise = (noise_objects.cheese_main:get_3d(rarity_pos) + 1) * 0.5
		if rarity_noise > cave_config.cheese.rarity then
			return false
		end
	end

	-- Get cave density with chunk boundary smoothing (most expensive operation)
	local density = get_cheese_cave_density(x, y, z, chunk_minp, chunk_maxp)

	return density < cave_config.cheese.threshold
end

-- Tunnel cave generation - optimized ellipsoid carving
local function carve_ellipsoid(data, area, x, y, z, width, height)
	local w_sq = width * width
	local h_sq = height * height

	-- Pre-calculate bounds to avoid unnecessary iterations
	local min_ox = math.max(-width, area.MinEdge.x - x)
	local max_ox = math.min(width, area.MaxEdge.x - x)
	local min_oy = math.max(-height, area.MinEdge.y - y)
	local max_oy = math.min(height, area.MaxEdge.y - y)
	local min_oz = math.max(-height, area.MinEdge.z - z)
	local max_oz = math.min(height, area.MaxEdge.z - z)

	for oz = min_oz, max_oz do
		local oz_sq = oz * oz
		for oy = min_oy, max_oy do
			local oy_sq = oy * oy
			for ox = min_ox, max_ox do
				local ox_sq = ox * ox
				local ellipsoid_val = (ox_sq + oz_sq) / w_sq + oy_sq / h_sq

				if ellipsoid_val <= 1.0 then
					local world_x = math.floor(x + ox)
					local world_y = math.floor(y + oy)
					local world_z = math.floor(z + oz)

					-- Direct bounds check is faster than area:contains
					if world_x >= area.MinEdge.x and world_x <= area.MaxEdge.x and
					   world_y >= area.MinEdge.y and world_y <= area.MaxEdge.y and
					   world_z >= area.MinEdge.z and world_z <= area.MaxEdge.z then
						local vi = area:index(world_x, world_y, world_z)
						data[vi] = c_air
					end
				end
			end
		end
	end
end

local function create_room(data, area, x, y, z, room_size, room_height_scale)
	local width = 1.5 + room_size
	local height = width * room_height_scale
	carve_ellipsoid(data, area, x, y, z, width, height)
end

local function get_variable_thickness()
	local val = math.random() * 2.0 + math.random()
	if math.random(10) == 1 then
		val = val * (math.random() * math.random() * 3.0 + 1.0)
	end
	return val
end

local function create_tunnel(data, area, x, y, z, horiz_radius, vert_radius, thickness, yaw, pitch, first_seg, length, y_scale, max_depth)
	max_depth = max_depth or 0
	if max_depth > 5 then return end

	local branch_point = math.random(math.floor(length / 4), math.floor(length * 3 / 4))
	local steep = math.random(6) == 1
	local yaw_variance = 0.0
	local pitch_variance = 0.0
	local pitch_arrest = steep and 0.92 or 0.7

	for i = first_seg, length do
		local w = 1.5 + math.sin(math.pi * ((i - 1) / length)) * thickness
		local h = w * y_scale

		local dh = math.cos(pitch)
		x = x + math.cos(yaw) * dh
		z = z + math.sin(yaw) * dh
		y = y + math.sin(pitch)

		pitch = pitch * pitch_arrest + pitch_variance * 0.1
		yaw = yaw + yaw_variance * 0.1

		pitch_variance = pitch_variance * 0.9
		yaw_variance = yaw_variance * 0.75

		pitch_variance = pitch_variance + ((math.random() - math.random()) * math.random() * 2.0)
		yaw_variance = yaw_variance + ((math.random() - math.random()) * math.random() * 4.0)

		if i - 1 == branch_point and thickness > 1.5 and max_depth < 3 then
			create_tunnel(data, area, x, y, z, horiz_radius, vert_radius,
				math.random() * 0.5 + 0.5, yaw - math.pi / 2, pitch / 3.0,
				i, length, 1.0, max_depth + 1)
			create_tunnel(data, area, x, y, z, horiz_radius, vert_radius,
				math.random() * 0.5 + 0.5, yaw + math.pi / 2, pitch / 3.0,
				i, length, 1.0, max_depth + 1)
			return
		end

		if math.random(4) ~= 1 then
			carve_ellipsoid(data, area, x, y, z, w * horiz_radius, h * vert_radius)
		end
	end
end

local function should_generate_tunnel_cave_at(region_x, region_z)
	if not noise_objects.tunnel_connectivity then
		return false
	end

	local noise_val = noise_objects.tunnel_connectivity:get_2d({
		x = region_x * cave_config.tunnels.region_size,
		y = region_z * cave_config.tunnels.region_size
	})
	return noise_val > 0.1
end

local function get_region_connection_points(region_x, region_z)
	if not noise_objects.tunnel_connectivity then
		return {}
	end

	local connections = {}
	local region_center_x = region_x * cave_config.tunnels.region_size
	local region_center_z = region_z * cave_config.tunnels.region_size

	local directions = {
		{dx = 1, dz = 0},   -- East
		{dx = 0, dz = 1},   -- South
		{dx = 1, dz = 1},   -- Southeast
		{dx = -1, dz = 1},  -- Southwest
	}

	for _, dir in ipairs(directions) do
		local neighbor_x = region_x + dir.dx
		local neighbor_z = region_z + dir.dz

		if should_generate_tunnel_cave_at(region_x, region_z) and
		   should_generate_tunnel_cave_at(neighbor_x, neighbor_z) then

			local connection_noise = noise_objects.tunnel_connectivity:get_2d({
				x = (region_center_x + neighbor_x * cave_config.tunnels.region_size) / 2,
				y = (region_center_z + neighbor_z * cave_config.tunnels.region_size) / 2
			})

			if connection_noise > -0.2 then
				local connection_point = {
					x = region_center_x + dir.dx * 32 + (connection_noise * 20),
					z = region_center_z + dir.dz * 32 + (connection_noise * 20),
					target_region_x = neighbor_x,
					target_region_z = neighbor_z
				}
				table.insert(connections, connection_point)
			end
		end
	end

	return connections
end

local function generate_tunnel_system(minp, maxp, data, area, region_x, region_z)
	local region_seed = region_x * 341873128712 + region_z * 132897987541 + world_seed
	math.randomseed(region_seed)

	local range_in_blocks = 16 * 25
	local max_caves = cave_config.tunnels.max_caves_per_region
	local cnt_segments = math.random(1, math.random(1, max_caves))

	local region_center_x = region_x * cave_config.tunnels.region_size
	local region_center_z = region_z * cave_config.tunnels.region_size

	local connections = get_region_connection_points(region_x, region_z)

	local cave_centers = {}
	for i = 1, cnt_segments do
		local center_x = region_center_x + math.random(-32, 32)
		local center_y = minp.y + math.random(0, maxp.y - minp.y)
		local center_z = region_center_z + math.random(-32, 32)

		table.insert(cave_centers, {x = center_x, y = center_y, z = center_z})

		local horiz_radius = 1.0
		local vert_radius = 1.0
		local cnt_tunnels = 2

		if math.random(100) <= 10 then
			local room_scale = 0.5 + math.random() * 1.5
			create_room(data, area, center_x, center_y, center_z, room_scale, 0.8)
		end

		for j = 1, cnt_tunnels do
			local yaw = math.random() * math.pi * 2
			local pitch = (math.random() - 0.5) * math.pi * 0.5
			local thickness = get_variable_thickness()
			local length = math.random(range_in_blocks / 4, range_in_blocks)

			create_tunnel(data, area, center_x, center_y, center_z, horiz_radius, vert_radius,
				thickness, yaw, pitch, 1, length, 1.0, 0)
		end
	end

	-- Generate connection tunnels
	for _, connection in ipairs(connections) do
		local start_center = cave_centers[math.random(#cave_centers)]
		if start_center then
			local yaw = math.atan2(connection.z - start_center.z, connection.x - start_center.x)
			local distance = math.sqrt((connection.x - start_center.x)^2 + (connection.z - start_center.z)^2)
			local length = math.min(distance / 2, range_in_blocks / 2)

			create_tunnel(data, area, start_center.x, start_center.y, start_center.z,
				1.0, 1.0, 1.5, yaw, 0, 1, length, 1.0, 0)
		end
	end
end

-- Water access checking using flood-fill
local function flood_fill_water_access(start_x, start_y, start_z, data, area, max_search_distance)
	local queue = {{x = start_x, y = start_y, z = start_z, dist = 0}}
	local queue_head = 1
	local queue_tail = 1
	local visited = {}
	local has_water_access = false
	local connected_positions = {}

	-- Helper function to create position key
	local function pos_key(x, y, z)
		return x .. "," .. y .. "," .. z
	end

	visited[pos_key(start_x, start_y, start_z)] = true

	-- Directions for 6-connected neighbors (no diagonals for performance)
	local directions = {
		{0, 1, 0}, {0, -1, 0}, {1, 0, 0}, {-1, 0, 0}, {0, 0, 1}, {0, 0, -1}
	}

	while queue_head <= queue_tail do
		local current = queue[queue_head]
		queue_head = queue_head + 1

		-- Stop searching if we've gone too far
		if current.dist >= max_search_distance then
			break
		end

		-- Add current position to connected positions if it's below sea level
		local sea_level = 0 -- Default sea level, could be retrieved from IPC
		if current.y <= sea_level then
			table.insert(connected_positions, {x = current.x, y = current.y, z = current.z})
		end

		-- Check if we've reached surface (y > sea level) or found existing water
		if current.y > sea_level then
			has_water_access = true
		end

		-- Check if current position contains water (existing water source)
		if area:contains(current.x, current.y, current.z) then
			local vi = area:index(current.x, current.y, current.z)
			if data[vi] == c_water then
				has_water_access = true
			end
		end

		-- Add neighbors to queue if they're air or water
		for _, dir in ipairs(directions) do
			local nx, ny, nz = current.x + dir[1], current.y + dir[2], current.z + dir[3]
			local key = pos_key(nx, ny, nz)

			if not visited[key] and area:contains(nx, ny, nz) then
				local vi = area:index(nx, ny, nz)
				local node = data[vi]

				-- Continue search through air or water, but stop at solid blocks
				if node == c_air or node == c_water then
					visited[key] = true
					queue_tail = queue_tail + 1
					queue[queue_tail] = {x = nx, y = ny, z = nz, dist = current.dist + 1}
				end
			end
		end
	end

	return has_water_access, connected_positions
end

-- Optimized batch water filling using flood-fill
local function batch_water_fill(cave_positions, data, area)
	if #cave_positions == 0 then
		return {}, {}
	end

	local water_filled_positions = {}
	local all_water_positions = {}
	local visited_global = {}

	-- Helper function to create position key
	local function pos_key(x, y, z)
		return x .. "," .. y .. "," .. z
	end

	-- Process each unvisited cave position
	for _, pos in ipairs(cave_positions) do
		local key = pos_key(pos.x, pos.y, pos.z)

		if not visited_global[key] then
			-- Use flood-fill to find the entire connected system and check water access
			local has_access, connected_positions = flood_fill_water_access(
				pos.x, pos.y, pos.z, data, area, 40
			)

			-- Mark all connected positions as visited
			for _, connected_pos in ipairs(connected_positions) do
				local connected_key = pos_key(connected_pos.x, connected_pos.y, connected_pos.z)
				visited_global[connected_key] = true

				-- If this system has water access, mark all positions for water filling
				if has_access then
					water_filled_positions[connected_key] = true
					table.insert(all_water_positions, connected_pos)
				end
			end
		end
	end

	return water_filled_positions, all_water_positions
end

-- Main cave generation function
function cave_gen.generate(minp, maxp, data, area)
	local shared = get_shared_data()
	if not shared then
		core.log("error", "[VoxelGen Mapgen] Cave generator: No shared data available")
		return false
	end

	-- Validate area object
	if not area or not area.index then
		core.log("error", "[VoxelGen Mapgen] Cave generator: Invalid area object")
		return false
	end

	-- Update global variables
	world_seed = shared.world_seed
	cave_config = shared.caves_config

	if not cave_config then
		core.log("error", "[VoxelGen Mapgen] Cave generator: No cave config available")
		return false
	end

	-- Initialize noise objects if needed
	if not noise_objects.cheese_main and not noise_objects.tunnel_connectivity then
		if not init_cave_noise(world_seed, cave_config) then
			return false
		end
	end

	local start_time = core.get_us_time()
	local changed = false
	local cave_positions = {}
	local stats = {
		cheese_caves_generated = 0,
		tunnel_caves_generated = 0,
		water_filled_positions = 0
	}

	-- Generate cheese caves with optimized approach
	if cave_config.cheese and cave_config.cheese.enabled and
	   maxp.y >= cave_config.cheese.min_y and minp.y <= cave_config.cheese.max_y then

		local y_min = math.max(minp.y, cave_config.cheese.min_y)
		local y_max = math.min(maxp.y, cave_config.cheese.max_y)

		-- Pre-calculate rarity noise for the entire chunk to avoid repeated calculations
		local rarity_scale = 0.1
		local chunk_rarity_cache = {}

		-- First pass: identify all cave positions and cache rarity values
		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				-- Calculate rarity once per column
				local rarity_pos = {x = x * rarity_scale, y = 0, z = z * rarity_scale}
				local rarity_noise = (noise_objects.cheese_main:get_3d(rarity_pos) + 1) * 0.5
				chunk_rarity_cache[x .. "," .. z] = rarity_noise

				-- Early exit if this column fails rarity check
				if rarity_noise <= cave_config.cheese.rarity then
					for y = y_min, y_max do
						local vi = area:index(x, y, z)
						local current_node = data[vi]

						if current_node ~= c_air then
							-- Use optimized cave check with rarity already verified and chunk boundary smoothing
							if should_be_cheese_cave(x, y, z, true, minp, maxp) then
								table.insert(cave_positions, {x = x, y = y, z = z, vi = vi})
								stats.cheese_caves_generated = stats.cheese_caves_generated + 1
							end
						end
					end
				end
			end
		end

		-- Second pass: create caves as air first
		for _, pos in ipairs(cave_positions) do
			data[pos.vi] = c_air
			changed = true
		end

		-- Third pass: flood-fill water into connected cave systems that have water access
		if #cave_positions > 0 then
			local water_filled_positions, all_water_positions = batch_water_fill(cave_positions, data, area)

			-- Apply water to original cave positions that should be filled
			local sea_level = 0 -- Default, could be retrieved from IPC
			for _, pos in ipairs(cave_positions) do
				if pos.y <= sea_level then
					local pos_key = pos.x .. "," .. pos.y .. "," .. pos.z
					if water_filled_positions[pos_key] then
						data[pos.vi] = c_water
						stats.water_filled_positions = stats.water_filled_positions + 1
					end
				end
			end

			-- Apply water to additional connected positions (like existing air pockets)
			for _, water_pos in ipairs(all_water_positions) do
				if area:contains(water_pos.x, water_pos.y, water_pos.z) then
					local vi = area:index(water_pos.x, water_pos.y, water_pos.z)
					-- Only fill if it's currently air (don't overwrite stone, etc.)
					if data[vi] == c_air then
						data[vi] = c_water
						stats.water_filled_positions = stats.water_filled_positions + 1
					end
				end
			end
		end
	end

	-- Generate tunnel caves
	if cave_config.tunnels and cave_config.tunnels.enabled and
	   maxp.y >= cave_config.tunnels.min_y and minp.y <= cave_config.tunnels.max_y then

		local region_x = math.floor(minp.x / cave_config.tunnels.region_size)
		local region_z = math.floor(minp.z / cave_config.tunnels.region_size)

		-- Store original data to detect tunnel cave changes
		local original_data = {}
		local y_min_tunnel = math.max(minp.y, cave_config.tunnels.min_y)
		local y_max_tunnel = math.min(maxp.y, cave_config.tunnels.max_y)

		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				for y = y_min_tunnel, y_max_tunnel do
					local vi = area:index(x, y, z)
					original_data[vi] = data[vi]
				end
			end
		end

		for rx = region_x - 1, region_x + 1 do
			for rz = region_z - 1, region_z + 1 do
				if should_generate_tunnel_cave_at(rx, rz) then
					generate_tunnel_system(minp, maxp, data, area, rx, rz)
					changed = true
				end
			end
		end

		-- Post-process tunnel caves for water filling
		if changed then
			local tunnel_cave_positions = {}

			-- Find all newly created tunnel cave positions
			for z = minp.z, maxp.z do
				for x = minp.x, maxp.x do
					for y = y_min_tunnel, y_max_tunnel do
						local vi = area:index(x, y, z)

						-- Check if this position was changed to air by tunnel generation
						if original_data[vi] and original_data[vi] ~= c_air and data[vi] == c_air then
							table.insert(tunnel_cave_positions, {x = x, y = y, z = z, vi = vi})
							stats.tunnel_caves_generated = stats.tunnel_caves_generated + 1
						end
					end
				end
			end

			-- Apply water filling to tunnel caves using flood-fill
			if #tunnel_cave_positions > 0 then
				local tunnel_water_filled, tunnel_all_water_positions = batch_water_fill(tunnel_cave_positions, data, area)

				-- Fill original tunnel positions
				local sea_level = 0 -- Default, could be retrieved from IPC
				for _, pos in ipairs(tunnel_cave_positions) do
					if pos.y <= sea_level then
						local pos_key = pos.x .. "," .. pos.y .. "," .. pos.z
						if tunnel_water_filled[pos_key] then
							data[pos.vi] = c_water
						end
					end
				end

				-- Fill additional connected air spaces
				for _, water_pos in ipairs(tunnel_all_water_positions) do
					if area:contains(water_pos.x, water_pos.y, water_pos.z) then
						local vi = area:index(water_pos.x, water_pos.y, water_pos.z)
						-- Only fill if it's currently air (don't overwrite stone, etc.)
						if data[vi] == c_air then
							data[vi] = c_water
						end
					end
				end
			end
		end
	end

	-- Performance logging
	local end_time = core.get_us_time()
	local generation_time = (end_time - start_time) / 1000 -- Convert to milliseconds

	if changed and (stats.cheese_caves_generated > 0 or stats.tunnel_caves_generated > 0) then
		core.log("action", string.format(
			"[VoxelGen Mapgen] Generated caves in chunk (%d,%d,%d) to (%d,%d,%d) in %.2fms: " ..
			"Cheese: %d, Tunnels: %d, Water-filled: %d",
			minp.x, minp.y, minp.z, maxp.x, maxp.y, maxp.z, generation_time,
			stats.cheese_caves_generated, stats.tunnel_caves_generated, stats.water_filled_positions
		))
	end

	return changed
end

-- Register the cave generation callback
core.register_on_generated(function(vmanip, minp, maxp, blockseed)
	-- Initialize content IDs if not done yet
	if not c_air then
		init_content_ids()
	end

	-- Get the emerged area and data from the voxel manipulator
	local emin, emax = vmanip:get_emerged_area()
	local area = VoxelArea(emin, emax)
	local data = vmanip:get_data()

	-- Validate that we have proper data
	if not area or not data then
		core.log("error", "[VoxelGen Mapgen] Cave generator: Failed to get voxel data")
		core.ipc_set("voxelgen:caves_generated", false)
		return
	end

	-- Generate caves
	local caves_generated = cave_gen.generate(minp, maxp, data, area)

	-- Set the data back if caves were generated
	if caves_generated then
		vmanip:set_data(data)
	end

	-- Store result in IPC for main environment to know if caves were generated
	core.ipc_set("voxelgen:caves_generated", caves_generated)
end)

core.log("action", "[VoxelGen Mapgen] Cave generator script loaded")
