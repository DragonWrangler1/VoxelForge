-- hud.lua - VoxelGen HUD system for displaying noise values
-- Provides a toggleable HUD that shows all noise values at the player's position

local hud = {}

-- HUD state tracking
local hud_enabled = {}  -- per-player HUD state
local hud_ids = {}	  -- per-player HUD element IDs

-- Update interval (in seconds)
local UPDATE_INTERVAL = 0.5
local update_timer = 0

-- Initialize HUD for a player
local function init_player_hud(player_name)
	hud_enabled[player_name] = false
	hud_ids[player_name] = {}
end

-- Remove HUD for a player
local function remove_player_hud(player_name)
	local player = minetest.get_player_by_name(player_name)
	if player and hud_ids[player_name] then
		for _, hud_id in pairs(hud_ids[player_name]) do
			if hud_id then
				player:hud_remove(hud_id)
			end
		end
	end
	hud_enabled[player_name] = nil
	hud_ids[player_name] = nil
end

-- Create HUD elements for a player
local function create_hud_elements(player)
	local player_name = player:get_player_name()

	-- Remove existing HUD elements if any
	if hud_ids[player_name] then
		for _, hud_id in pairs(hud_ids[player_name]) do
			if hud_id then
				player:hud_remove(hud_id)
			end
		end
	end

	hud_ids[player_name] = {}

	-- Main HUD background
	hud_ids[player_name].background = player:hud_add({
		hud_elem_type = "text",
		position = {x = 0.02, y = 0.1},
		offset = {x = 0, y = 0},
		text = "",
		alignment = {x = 1, y = 1},
		scale = {x = 100, y = 100},
		number = 0x000000,
		size = {x = 1}
	})

	-- Main HUD text
	hud_ids[player_name].text = player:hud_add({
		hud_elem_type = "text",
		position = {x = 0.02, y = 0.1},
		offset = {x = 0, y = 0},
		text = "VoxelGen Noise Values",
		alignment = {x = 1, y = 1},
		scale = {x = 100, y = 100},
		number = 0xFFFFFF,
		size = {x = 1}
	})
end


-- Format a number for display
local function format_number(value, decimals)
	decimals = decimals or 3
	return string.format("%." .. decimals .. "f", value)
end

-- Get all noise values at a position
local function get_noise_values_at(x, y, z, world_seed)
	-- Check if voxelgen API is available
	if not voxelgen or not voxelgen.api then
		return nil
	end

	if not voxelgen.api.noise_objects or not world_seed then
		return nil
	end

	local values = {}

	-- Get raw noise values
	for name, noise_obj in pairs(voxelgen.api.noise_objects) do
		if name == "density" or name == "terrain_character" then
			-- 3D noise
			values[name .. "_raw"] = noise_obj:get_3d({x = x, y = y, z = z})
		else
			-- 2D noise
			values[name .. "_raw"] = noise_obj:get_2d({x = x, y = z})
		end
	end

	-- Get processed values through splines (only for splines that exist)
	if values.continental_raw and voxelgen.api.splines.continentalness then
		values.continentalness = voxelgen.api.spline_map(values.continental_raw, voxelgen.api.splines.continentalness, world_seed, x, z)
	end

	if values.erosion_raw and voxelgen.api.splines.erosion then
		values.erosion = voxelgen.api.spline_map(values.erosion_raw, voxelgen.api.splines.erosion, world_seed, x, z)
	end

	if values.peaks_raw and voxelgen.api.splines.peaks then
		values.peaks = voxelgen.api.spline_map(values.peaks_raw, voxelgen.api.splines.peaks, world_seed, x, z)
	end

	if values.jagged_mountains_raw and voxelgen.api.splines.jagged_mountains then
		values.jagged_mountains = voxelgen.api.spline_map(values.jagged_mountains_raw, voxelgen.api.splines.jagged_mountains, world_seed, x, z)
	end

	-- Get climate values (with error checking)
	if voxelgen.api.get_heat_at then
		values.heat = voxelgen.api.get_heat_at(x, z, y)
	end

	if voxelgen.api.get_humidity_at then
		values.humidity = voxelgen.api.get_humidity_at(x, z, y)
	end

	-- Calculate peaks and valleys (with error checking)
	if values.weirdness_raw and voxelgen.api.calculate_peaks_valleys then
		values.peaks_valleys = voxelgen.api.calculate_peaks_valleys(values.weirdness_raw)
	end

	return values
end

-- Update HUD for a player
local function update_player_hud(player)
	local player_name = player:get_player_name()

	if not hud_enabled[player_name] or not hud_ids[player_name] or not hud_ids[player_name].text then
		return
	end

	local pos = player:get_pos()
	local x, y, z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)

	-- Get world seed
	local world_seed = voxelgen.mapgen and voxelgen.mapgen.world_seed or 12345

	-- Get noise values
	local values = get_noise_values_at(x, y, z, world_seed)

	if not values then
		player:hud_change(hud_ids[player_name].text, "text", "VoxelGen Noise Values\n§cNoise system not initialized§r\n\nTry moving to a different area\nor wait for terrain generation.")
		return
	end

	-- Build HUD text
	local lines = {
		"§lVoxelGen Noise Values§r",
		"Position: " .. x .. ", " .. y .. ", " .. z,
		"",
		"§6Raw Noise Values:§r",
	}

	-- Add raw noise values that exist
	local raw_values_added = false
	if values.continental_raw then
		table.insert(lines, "Continental: " .. format_number(values.continental_raw))
		raw_values_added = true
	end
	if values.erosion_raw then
		table.insert(lines, "Erosion: " .. format_number(values.erosion_raw))
		raw_values_added = true
	end
	if values.peaks_raw then
		table.insert(lines, "Peaks: " .. format_number(values.peaks_raw))
		raw_values_added = true
	end
	if values.jagged_mountains_raw then
		table.insert(lines, "Jagged Mountains: " .. format_number(values.jagged_mountains_raw))
		raw_values_added = true
	end
	if values.mountain_ridges_raw then
		table.insert(lines, "Mountain Ridges: " .. format_number(values.mountain_ridges_raw))
		raw_values_added = true
	end
	if values.small_scale_raw then
		table.insert(lines, "Small Scale: " .. format_number(values.small_scale_raw))
		raw_values_added = true
	end
	if values.weirdness_raw then
		table.insert(lines, "Weirdness: " .. format_number(values.weirdness_raw))
		raw_values_added = true
	end

	-- Add additional noise types that might be available
	if values.heat_raw then
		table.insert(lines, "Heat (Raw): " .. format_number(values.heat_raw))
		raw_values_added = true
	end
	if values.humidity_raw then
		table.insert(lines, "Humidity (Raw): " .. format_number(values.humidity_raw))
		raw_values_added = true
	end
	if values.river_network_raw then
		table.insert(lines, "River Network: " .. format_number(values.river_network_raw))
		raw_values_added = true
	end
	if values.river_width_raw then
		table.insert(lines, "River Width: " .. format_number(values.river_width_raw))
		raw_values_added = true
	end
	if values.canyon_raw then
		table.insert(lines, "Canyon: " .. format_number(values.canyon_raw))
		raw_values_added = true
	end

	-- Add fallback message if no raw values were found
	if not raw_values_added then
		table.insert(lines, "§cNo noise values available§r")
		table.insert(lines, "Noise objects may not be initialized")
	end

	-- Add processed values section if any exist
	local has_processed = values.continentalness or values.erosion or values.peaks or values.jagged_mountains
	if has_processed then
		table.insert(lines, "")
		table.insert(lines, "§6Processed Values (Splined):§r")

		if values.continentalness then
			table.insert(lines, "Continentalness: " .. format_number(values.continentalness, 1) .. " blocks")
		end
		if values.erosion then
			table.insert(lines, "Erosion: " .. format_number(values.erosion, 1) .. " blocks")
		end
		if values.peaks then
			table.insert(lines, "Peaks: " .. format_number(values.peaks, 1) .. " blocks")
		end
		if values.jagged_mountains then
			table.insert(lines, "Jagged Mountains: " .. format_number(values.jagged_mountains, 1) .. " blocks")
		end
	end

	-- Add climate values if they exist
	if values.heat or values.humidity then
		table.insert(lines, "")
		table.insert(lines, "§6Climate Values:§r")

		if values.heat then
			table.insert(lines, "Heat: " .. format_number(values.heat, 1))
		end
		if values.humidity then
			table.insert(lines, "Humidity: " .. format_number(values.humidity, 1))
		end
	end

	-- Add calculated values if they exist
	if values.peaks_valleys then
		table.insert(lines, "")
		table.insert(lines, "§6Calculated Values:§r")
		table.insert(lines, "Peaks & Valleys: " .. format_number(values.peaks_valleys))
	end

	-- Add 3D noise values if they exist
	if values.density_raw or values.terrain_character_raw then
		table.insert(lines, "")
		table.insert(lines, "§6Density (3D):§r")

		if values.density_raw then
			table.insert(lines, "Raw Density: " .. format_number(values.density_raw))
		end
		if values.terrain_character_raw then
			table.insert(lines, "Terrain Character: " .. format_number(values.terrain_character_raw))
		end
	end

	-- Add debug information about available noise objects
	if voxelgen.api.noise_objects then
		local noise_count = 0
		for _ in pairs(voxelgen.api.noise_objects) do
			noise_count = noise_count + 1
		end

		if noise_count > 0 then
			table.insert(lines, "")
			table.insert(lines, "§8Debug: " .. noise_count .. " noise objects loaded§r")
		else
			table.insert(lines, "")
			table.insert(lines, "§cDebug: No noise objects loaded§r")
			table.insert(lines, "§8World seed: " .. (world_seed or "unknown") .. "§r")
		end
	end

	local hud_text = table.concat(lines, "\n")
	player:hud_change(hud_ids[player_name].text, "text", hud_text)
end

-- Ensure noise objects are initialized
local function ensure_noise_initialized()
	-- Check if voxelgen API is available
	if not voxelgen or not voxelgen.api then
		return false
	end

	if not voxelgen.api.noise_objects or not next(voxelgen.api.noise_objects) then
		-- Try to get world seed and initialize noise
		local world_seed = voxelgen.mapgen and voxelgen.mapgen.world_seed
		if not world_seed then
			-- Fallback to a default seed if mapgen isn't available
			world_seed = minetest.get_mapgen_setting("seed") or 12345
		end

		if voxelgen.api.init_noise then
			voxelgen.api.init_noise(world_seed)
			minetest.log("action", "[VoxelGen HUD] Initialized noise objects with seed: " .. world_seed)
			return true
		end
	end

	return voxelgen.api.noise_objects and next(voxelgen.api.noise_objects) ~= nil
end

-- Toggle HUD for a player
function hud.toggle_hud(player_name)
	local player = minetest.get_player_by_name(player_name)
	if not player then
		return false, "Player not found"
	end

	if not hud_enabled[player_name] then
		init_player_hud(player_name)
	end

	hud_enabled[player_name] = not hud_enabled[player_name]

	if hud_enabled[player_name] then
		-- Ensure noise is initialized when enabling HUD
		ensure_noise_initialized()

		create_hud_elements(player)
		update_player_hud(player)
		return true, "VoxelGen HUD enabled"
	else
		remove_player_hud(player_name)
		init_player_hud(player_name)
		return true, "VoxelGen HUD disabled"
	end
end

-- Player join/leave handlers
minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	init_player_hud(player_name)

end)

minetest.register_on_leaveplayer(function(player)
	local player_name = player:get_player_name()
	remove_player_hud(player_name)
end)

-- Global step for updating HUD
minetest.register_globalstep(function(dtime)
	update_timer = update_timer + dtime

	if update_timer >= UPDATE_INTERVAL then
		update_timer = 0

		-- Update HUD for all players with HUD enabled
		for player_name, enabled in pairs(hud_enabled) do
			if enabled then
				local player = minetest.get_player_by_name(player_name)
				if player then
					update_player_hud(player)
				end
			end
		end
	end
end)

-- Chat command to toggle HUD
minetest.register_chatcommand("voxelgen_hud", {
	description = "Toggle VoxelGen noise values HUD display",
	func = function(name)
		return hud.toggle_hud(name)
	end,
})

return hud
