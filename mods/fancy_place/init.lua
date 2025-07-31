-- Fancy Place Mod
-- Simple block placement system - shows ghost blocks next to blocks (not on top or below)
-- Right-click ghost blocks to place them

-- Simple configuration
fancy_place = {
	reach_distance = tonumber(minetest.settings:get("fancy_place_reach_distance")) or 4.5,
	ghost_blocks = {}, -- Store ghost block entities per player
	ghost_opacity = tonumber(minetest.settings:get("fancy_place_ghost_opacity")) or 128,
	ghost_glow = tonumber(minetest.settings:get("fancy_place_ghost_glow")) or 8,
	ghost_size = tonumber(minetest.settings:get("fancy_place_ghost_size")) or 1.02,
	allow_diagonal = minetest.settings:get_bool("fancy_place_allow_diagonal", true),
	play_sounds = minetest.settings:get_bool("fancy_place_play_sounds", true),
	update_interval = tonumber(minetest.settings:get("fancy_place_update_interval")) or 0.2,
	instant_updates = minetest.settings:get_bool("fancy_place_instant_updates", true),
	show_config = minetest.settings:get_bool("fancy_place_show_config", false),
}

-- Show configuration if requested
if fancy_place.show_config then
	minetest.log("action", "[Fancy Place] Configuration loaded:")
	minetest.log("action", "  Reach Distance: " .. fancy_place.reach_distance)
	minetest.log("action", "  Ghost Opacity: " .. fancy_place.ghost_opacity)
	minetest.log("action", "  Ghost Glow: " .. fancy_place.ghost_glow)
	minetest.log("action", "  Ghost Size: " .. fancy_place.ghost_size)
	minetest.log("action", "  Allow Diagonal: " .. tostring(fancy_place.allow_diagonal))
	minetest.log("action", "  Play Sounds: " .. tostring(fancy_place.play_sounds))
	minetest.log("action", "  Update Interval: " .. fancy_place.update_interval)
	minetest.log("action", "  Instant Updates: " .. tostring(fancy_place.instant_updates))
end

-- Utility functions
local function get_node_safe(pos)
	if not pos then return {name = "ignore"} end
	return minetest.get_node_or_nil(pos) or {name = "ignore"}
end

-- Apply opacity to texture name
local function apply_texture_opacity(texture_name, opacity)
	if not texture_name or texture_name == "" then
		return "default_stone.png^[opacity:" .. opacity
	end
	return texture_name .. "^[opacity:" .. opacity
end

local function is_buildable_to(pos)
	local node = get_node_safe(pos)
	local def = minetest.registered_nodes[node.name]
	return def and def.buildable_to
end

local function is_solid_node(pos)
	local node = get_node_safe(pos)
	local def = minetest.registered_nodes[node.name]
	return def and not def.buildable_to and def.walkable ~= false
end

-- Get horizontal adjacent positions (4 cardinal + optionally 4 diagonal, no top/bottom)
local function get_horizontal_adjacent_positions(pos)
	local positions = {
		-- Cardinal directions (always included)
		{x = pos.x + 1, y = pos.y, z = pos.z}, -- +X (east)
		{x = pos.x - 1, y = pos.y, z = pos.z}, -- -X (west)
		{x = pos.x, y = pos.y, z = pos.z + 1}, -- +Z (south)
		{x = pos.x, y = pos.y, z = pos.z - 1}, -- -Z (north)
	}

	-- Add diagonal directions if enabled
	if fancy_place.allow_diagonal then
		positions[#positions + 1] = {x = pos.x + 1, y = pos.y, z = pos.z + 1} -- +X +Z (southeast)
		positions[#positions + 1] = {x = pos.x + 1, y = pos.y, z = pos.z - 1} -- +X -Z (northeast)
		positions[#positions + 1] = {x = pos.x - 1, y = pos.y, z = pos.z + 1} -- -X +Z (southwest)
		positions[#positions + 1] = {x = pos.x - 1, y = pos.y, z = pos.z - 1} -- -X -Z (northwest)
	end

	return positions
end

-- Find placement position next to blocks (horizontal only)
local function find_horizontal_placement_pos(player, pointed_thing)
	local player_pos = player:get_pos()
	local eye_pos = vector.add(player_pos, {x = 0, y = 1.5, z = 0})
	local look_dir = player:get_look_dir()

	-- If we have a normal pointed_thing with a node, check if it's a horizontal placement
	if pointed_thing.type == "node" and pointed_thing.above and pointed_thing.under then
		local above_pos = pointed_thing.above
		local under_pos = pointed_thing.under

		-- If it's a top/bottom placement (different Y levels), don't allow it
		if above_pos.y ~= under_pos.y then
			return nil, nil
		end

		-- This is a horizontal placement (same Y level), allow it if buildable
		if is_buildable_to(above_pos) then
			return above_pos, under_pos
		end
	end

	-- Search for horizontal placement opportunities
	local step_size = 0.1
	local steps = math.floor(fancy_place.reach_distance / step_size)

	-- Cast a ray from player's eye position in look direction
	for i = 1, steps do
		local check_pos = vector.add(eye_pos, vector.multiply(look_dir, i * step_size))
		local rounded_pos = vector.round(check_pos)

		-- If this position is buildable, check for horizontally adjacent solid blocks
		if is_buildable_to(rounded_pos) then
			local adjacent_positions = get_horizontal_adjacent_positions(rounded_pos)

			for _, adj_pos in ipairs(adjacent_positions) do
				if is_solid_node(adj_pos) then
					-- Found a good horizontal placement position
					return rounded_pos, adj_pos
				end
			end
		end
	end

	return nil, nil
end

-- Remove ghost block for a player
local function remove_ghost_block(player_name)
	if fancy_place.ghost_blocks[player_name] then
		fancy_place.ghost_blocks[player_name]:remove()
		fancy_place.ghost_blocks[player_name] = nil
	end
end

-- Create ghost block entity
local function create_ghost_block(player_name, pos, node_name)
	remove_ghost_block(player_name)

	local player = minetest.get_player_by_name(player_name)
	if not player then return end

	-- Get the node definition to determine appearance
	local def = minetest.registered_nodes[node_name]
	if not def then return end

	-- Create a temporary entity for the ghost block
	local obj = minetest.add_entity(pos, "fancy_place:ghost_block")
	if obj then
		local ent = obj:get_luaentity()
		if ent then
			ent.node_name = node_name
			ent.player_name = player_name
			fancy_place.ghost_blocks[player_name] = obj

			-- Set visual properties with proper texture handling
			local textures = {}
			if def.tiles then
				-- Handle different tile configurations
				if #def.tiles == 1 then
					-- Single texture for all faces
					local tex_name = type(def.tiles[1]) == "string" and def.tiles[1] or (def.tiles[1].name or "default_stone.png")
					for i = 1, 6 do
						textures[i] = apply_texture_opacity(tex_name, fancy_place.ghost_opacity)
					end
				elseif #def.tiles == 2 then
					-- Top/bottom and sides
					local top_tex = type(def.tiles[1]) == "string" and def.tiles[1] or (def.tiles[1].name or "default_stone.png")
					local side_tex = type(def.tiles[2]) == "string" and def.tiles[2] or (def.tiles[2].name or "default_stone.png")
					textures[1] = apply_texture_opacity(top_tex, fancy_place.ghost_opacity)	-- +Y (top)
					textures[2] = apply_texture_opacity(top_tex, fancy_place.ghost_opacity)	-- -Y (bottom)
					textures[3] = apply_texture_opacity(side_tex, fancy_place.ghost_opacity)   -- +X (right)
					textures[4] = apply_texture_opacity(side_tex, fancy_place.ghost_opacity)   -- -X (left)
					textures[5] = apply_texture_opacity(side_tex, fancy_place.ghost_opacity)   -- +Z (front)
					textures[6] = apply_texture_opacity(side_tex, fancy_place.ghost_opacity)   -- -Z (back)
				elseif #def.tiles >= 6 then
					-- Full 6-sided textures
					for i = 1, 6 do
						local tile = def.tiles[i]
						local tex_name = type(tile) == "string" and tile or (tile.name or "default_stone.png")
						textures[i] = apply_texture_opacity(tex_name, fancy_place.ghost_opacity)
					end
				else
					-- Fallback for other cases
					for i = 1, 6 do
						local tile_index = math.min(i, #def.tiles)
						local tile = def.tiles[tile_index]
						local tex_name = type(tile) == "string" and tile or (tile.name or "default_stone.png")
						textures[i] = apply_texture_opacity(tex_name, fancy_place.ghost_opacity)
					end
				end
			else
				-- No tiles defined, use default
				for i = 1, 6 do
					textures[i] = apply_texture_opacity("default_stone.png", fancy_place.ghost_opacity)
				end
			end

			obj:set_properties({
				visual = "cube",
				visual_size = {x = fancy_place.ghost_size, y = fancy_place.ghost_size, z = fancy_place.ghost_size},
				textures = textures,
				physical = false,
				collide_with_objects = false,
				use_texture_alpha = true,
				glow = fancy_place.ghost_glow,
				selectionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			})
		end
	end
end

-- Ghost block entity definition
minetest.register_entity("fancy_place:ghost_block", {
	initial_properties = {
		visual = "cube",
		visual_size = {x = fancy_place.ghost_size, y = fancy_place.ghost_size, z = fancy_place.ghost_size},
		textures = {apply_texture_opacity("default_stone.png", fancy_place.ghost_opacity)},
		physical = false,
		collide_with_objects = false,
		use_texture_alpha = true,
		glow = fancy_place.ghost_glow,
		selectionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	},

	node_name = "",
	player_name = "",
	timer = 0,

	on_activate = function(self, staticdata)
		self.timer = 0
	end,

	on_step = function(self, dtime)
		self.timer = self.timer + dtime

		-- Only remove if player is gone (no timeout removal)
		if not minetest.get_player_by_name(self.player_name) then
			self.object:remove()
			return
		end
	end,

	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end

		local player_name = clicker:get_player_name()

		-- Only allow the owner to place the block
		if player_name ~= self.player_name then
			return
		end

		local wielded = clicker:get_wielded_item()
		local item_name = wielded:get_name()

		-- Check if the player is holding the correct block
		if item_name ~= self.node_name then
			return
		end

		local pos = self.object:get_pos()
		if not pos then return end

		-- Check protection
		if minetest.is_protected(pos, player_name) then
			minetest.record_protection_violation(pos, player_name)
			return
		end

		-- Check if we can still place the node
		if not is_buildable_to(pos) then
			return
		end

		-- Get node definition for callbacks and sounds
		local def = minetest.registered_nodes[item_name]
		if not def then return end

		-- Place the node
		minetest.set_node(pos, {name = item_name})

		-- Play sound
		if fancy_place.play_sounds and def.sounds and def.sounds.place then
			minetest.sound_play(def.sounds.place, {pos = pos, gain = 1.0})
		end

		-- Find an adjacent solid block for the after_place_node callback
		local adjacent_positions = get_horizontal_adjacent_positions(pos)
		local against_pos = nil
		for _, adj_pos in ipairs(adjacent_positions) do
			if is_solid_node(adj_pos) then
				against_pos = adj_pos
				break
			end
		end

		-- Run after_place_node callback if it exists
		if def.after_place_node and against_pos then
			def.after_place_node(pos, clicker, wielded, {
				type = "node",
				under = against_pos,
				above = pos
			})
		end

		-- Consume item
		if not minetest.settings:get_bool("creative_mode") and not minetest.check_player_privs(player_name, "creative") then
			wielded:take_item()
			clicker:set_wielded_item(wielded)
		end

		-- Remove the ghost block
		remove_ghost_block(player_name)
	end,
})

-- Helper function to perform raycast and get pointed_thing
local function get_player_pointed_thing(player)
	local eye_pos = vector.add(player:get_pos(), {x = 0, y = 1.5, z = 0})
	local look_dir = player:get_look_dir()
	local end_pos = vector.add(eye_pos, vector.multiply(look_dir, fancy_place.reach_distance))

	-- Perform raycast
	local raycast = minetest.raycast(eye_pos, end_pos, false, false)
	local pointed_thing = raycast:next()

	if pointed_thing then
		return pointed_thing
	else
		-- No intersection found, return air pointing
		return {type = "nothing"}
	end
end

-- Ghost block preview update
local function update_ghost_preview()
	for _, player in ipairs(minetest.get_connected_players()) do
		local player_name = player:get_player_name()
		local wielded = player:get_wielded_item()
		local item_name = wielded:get_name()

		-- Check if player is holding a placeable item
		if item_name ~= "" and minetest.registered_nodes[item_name] then
			-- Get actual pointed_thing from raycast
			local pointed_thing = get_player_pointed_thing(player)

			-- Try to find a horizontal placement position
			local place_pos, _ = find_horizontal_placement_pos(player, pointed_thing)

			if place_pos then
				-- Update or create ghost block
				local current_ghost = fancy_place.ghost_blocks[player_name]
				local needs_update = true

				if current_ghost then
					local current_pos = current_ghost:get_pos()
					if current_pos and vector.equals(current_pos, place_pos) then
						-- Check if the node type matches
						local ent = current_ghost:get_luaentity()
						if ent and ent.node_name == item_name then
							needs_update = false
						end
					end
				end

				if needs_update then
					create_ghost_block(player_name, place_pos, item_name)
				end
			else
				-- Only remove ghost block if no valid placement position found
				remove_ghost_block(player_name)
			end
		else
			-- Remove ghost block if not holding a placeable item
			remove_ghost_block(player_name)
		end
	end
end

-- Cleanup on player leave
minetest.register_on_leaveplayer(function(player)
	local player_name = player:get_player_name()
	remove_ghost_block(player_name)
end)

-- Initialize mod
minetest.register_on_mods_loaded(function()
	-- Start ghost block preview timer
	local timer = 0
	minetest.register_globalstep(function(dtime)
		timer = timer + dtime
		if timer >= fancy_place.update_interval then
			timer = 0
			update_ghost_preview()
		end
	end)

	minetest.log("action", "[fancy_place] Simple horizontal placement mod loaded successfully")
end)
