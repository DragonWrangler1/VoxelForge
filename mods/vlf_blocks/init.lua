-- Natural Blocks
minetest.register_node("vlf_blocks:stone", {
	description = "Stone",
	tiles = {"vlf_blocks_stone.png"},
	is_ground_content = true,
	groups = {stone = 1, voxelforge_material = 1},
	drop = "vlf_blocks:cobble",
	--sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("vlf_blocks:dirt_with_grass", {
	description = "Dirt with Grass",
	tiles = {"vlf_blocks_grass.png", "vlf_blocks_dirt.png", "vlf_blocks_grass_side.png"},
	is_ground_content = true,
	groups = {soil = 1, voxelforge_material = 1},
	--sounds = default.node_sound_dirt_defaults({
		--footstep = {name = "default_grass_footstep", gain = 0.4},
   -- }),
})

minetest.register_node("vlf_blocks:dirt", {
	description = "Dirt",
	tiles = {"vlf_blocks_dirt.png"},
	is_ground_content = true,
	groups = {soil = 1, voxelforge_material = 1},
	--sounds = default.node_sound_dirt_defaults({
		--footstep = {name = "default_grass_footstep", gain = 0.4},
   -- }),
})

minetest.register_node("vlf_blocks:sand", {
	description = "Sand",
	tiles = {"vlf_blocks_sand.png"},
	is_ground_content = true,
	groups = {soil = 1, voxelforge_material = 1},
	--sounds = default.node_sound_dirt_defaults({
		--footstep = {name = "default_grass_footstep", gain = 0.4},
   -- }),
})

minetest.register_node("vlf_blocks:red_sand", {
	description = "Red Sand",
	tiles = {"vlf_blocks_red_sand.png"},
	is_ground_content = true,
	groups = {soil = 1, voxelforge_material = 1},
	--sounds = default.node_sound_dirt_defaults({
		--footstep = {name = "default_grass_footstep", gain = 0.4},
   -- }),
})

-- Flora
minetest.register_node("vlf_blocks:oak_leaves", {
	description = "Oak Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	tiles = {"vlf_blocks_oak_leaves.png"},
	paramtype = "light",
	groups = {leafdecay = 3, flammable = 2, voxelforge_material = 1},
	drop = {
		max_items = 1,
		items = {
			{items = {"vlf_blocks:sapling"}, rarity = 20},
			{items = {"vlf_blocks:oak_leaves"}}
		}
	},
	--sounds = default.node_sound_leaves_defaults(),
})

-- Liquids
minetest.register_node("vlf_blocks:water_source", {
	description = "Water Source",
	drawtype = "liquid",
	tiles = {
		{
			name = "vlf_blocks_water_source_animated.png",
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0}
		}
	},
	special_tiles = {
		{
			name = "vlf_blocks_water_source_animated.png",
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
			backface_culling = false
		}
	},
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	use_texture_alpha = true,
	liquidtype = "source",
	liquid_alternative_flowing = "vlf_blocks:water_flowing",
	liquid_alternative_source = "vlf_blocks:water_source",
	liquid_viscosity = 1,
	post_effect_color = {a = 103, r = 30, g = 60, b = 90},
	groups = {water = 3, liquid = 3, cools_lava = 1},
	--sounds = default.node_sound_water_defaults(),
})

minetest.register_node("vlf_blocks:water_flowing", {
	description = "Flowing Water",
	drawtype = "flowingliquid",
	tiles = {"vlf_blocks_water.png"},
	special_tiles = {
		{
			name = "vlf_blocks_water_flowing_animated.png",
			backface_culling = false,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.8}
		},
		{
			name = "vlf_blocks_water_flowing_animated.png",
			backface_culling = true,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.8}
		}
	},
	paramtype = "light",
	paramtype2 = "flowingliquid",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	use_texture_alpha = true,
	liquidtype = "flowing",
	liquid_alternative_flowing = "vlf_blocks:water_flowing",
	liquid_alternative_source = "vlf_blocks:water_source",
	liquid_viscosity = 1,
	post_effect_color = {a = 103, r = 30, g = 60, b = 90},
	groups = {water = 3, liquid = 3, not_in_creative_inventory = 1, cools_lava = 1},
	--sounds = default.node_sound_water_defaults(),
})

minetest.register_node("vlf_blocks:lava_source", {
	description = "Lava Source",
	drawtype = "liquid",
	tiles = {
		{
			name = "vlf_blocks_lava_source_animated.png",
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
		}
	},
	special_tiles = {
		{
			name = "vlf_blocks_lava_source_animated.png",
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3},
			backface_culling = false
		}
	},
	paramtype = "light",
	light_source = 14,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	liquidtype = "source",
	liquid_alternative_flowing = "vlf_blocks:lava_flowing",
	liquid_alternative_source = "vlf_blocks:lava_source",
	liquid_viscosity = 7,
	damage_per_second = 4,
	groups = {lava = 3, liquid = 2, hot = 3},
	--sounds = default.node_sound_lava_defaults(),
})

minetest.register_node("vlf_blocks:lava_flowing", {
	description = "Flowing Lava",
	drawtype = "flowingliquid",
	tiles = {"vlf_blocks_lava.png"},
	special_tiles = {
		{
			name = "vlf_blocks_lava_flowing_animated.png",
			backface_culling = false,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
		},
		{
			name = "vlf_blocks_lava_flowing_animated.png",
			backface_culling = true,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
		}
	},
	paramtype = "light",
	paramtype2 = "flowingliquid",
	light_source = 14,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	liquidtype = "flowing",
	liquid_alternative_flowing = "vlf_blocks:lava_flowing",
	liquid_alternative_source = "vlf_blocks:lava_source",
	liquid_viscosity = 7,
	damage_per_second = 4,
	groups = {lava = 3, liquid = 2, not_in_creative_inventory = 1, hot = 3},
	--sounds = default.node_sound_lava_defaults(),
})

-- Additional blocks needed for crafting
minetest.register_node("vlf_blocks:cobble", {
	description = "Cobblestone",
	tiles = {"vlf_blocks_cobble.png"},
	is_ground_content = true,
	groups = {stone = 2, voxelforge_material = 1},
	--sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("vlf_blocks:planks", {
	description = "Wooden Planks",
	tiles = {"vlf_blocks_planks.png"},
	is_ground_content = false,
	groups = {flammable = 3, wood = 1, voxelforge_material = 1},
	--sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("vlf_blocks:wood", {
	description = "Wood",
	tiles = {"vlf_blocks_wood.png"},
	is_ground_content = false,
	groups = {flammable = 3, wood = 1, voxelforge_material = 1},
	--sounds = default.node_sound_wood_defaults(),
})

-- Ore blocks
minetest.register_node("vlf_blocks:coal_ore", {
	description = "Coal Ore",
	tiles = {"vlf_blocks_coal_ore.png"},
	is_ground_content = true,
	groups = {stone = 1, voxelforge_material = 1},
	drop = "vlf_blocks:coal_lump",
	--sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("vlf_blocks:iron_ore", {
	description = "Iron Ore",
	tiles = {"voxelforge_iron_ore.png"},
	is_ground_content = true,
	groups = {stone = 1, voxelforge_material = 1},
	drop = "vlf_blocks:iron_lump",
	--sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("vlf_blocks:copper_ore", {
	description = "Copper Ore",
	tiles = {"voxelforge_copper_ore.png"},
	is_ground_content = true,
	groups = {stone = 1, voxelforge_material = 1},
	drop = "vlf_blocks:copper_lump",
	--sounds = default.node_sound_stone_defaults(),
})

-- Additional biome-specific blocks
minetest.register_node("vlf_blocks:snow", {
	description = "Snow",
	tiles = {"vlf_blocks_snow.png"},
	is_ground_content = true,
	groups = {crumbly = 3, falling_node = 1, voxelforge_material = 1},
	walkable = false,
	buildable_to = true,
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
	},
})

minetest.register_node("vlf_blocks:snow_block", {
	description = "Snow Block",
	tiles = {"vlf_blocks_snow.png"},
	is_ground_content = true,
	groups = {crumbly = 3, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:ice", {
	description = "Ice",
	tiles = {"vlf_blocks_ice.png"},
	is_ground_content = true,
	groups = {cracky = 3, slippery = 3, voxelforge_material = 1},
	paramtype = "light",
	use_texture_alpha = true,
})

minetest.register_node("vlf_blocks:sandstone", {
	description = "Sandstone",
	tiles = {"vlf_blocks_sandstone.png"},
	is_ground_content = true,
	groups = {stone = 1, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:red_sand", {
	description = "Red Sand",
	tiles = {"vlf_blocks_red_sand.png"},
	is_ground_content = true,
	groups = {soil = 1, falling_node = 1, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:red_sandstone", {
	description = "Red Sandstone",
	tiles = {"vlf_blocks_red_sandstone.png"},
	is_ground_content = true,
	groups = {stone = 1, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:gravel", {
	description = "Gravel",
	tiles = {"vlf_blocks_gravel.png"},
	is_ground_content = true,
	groups = {crumbly = 2, falling_node = 1, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:clay", {
	description = "Clay",
	tiles = {"vlf_blocks_clay.png"},
	is_ground_content = true,
	groups = {crumbly = 3, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:podzol", {
	description = "Podzol",
	tiles = {"vlf_blocks_podzol_top.png", "vlf_blocks_dirt.png", "vlf_blocks_podzol_side.png"},
	is_ground_content = true,
	groups = {soil = 1, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:coarse_dirt", {
	description = "Coarse Dirt",
	tiles = {"vlf_blocks_coarse_dirt.png"},
	is_ground_content = true,
	groups = {soil = 1, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:mycelium", {
	description = "Mycelium",
	tiles = {"vlf_blocks_mycelium_top.png", "vlf_blocks_dirt.png", "vlf_blocks_mycelium_side.png"},
	is_ground_content = true,
	groups = {soil = 1, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:granite", {
	description = "Granite",
	tiles = {"vlf_blocks_granite.png"},
	is_ground_content = true,
	groups = {stone = 1, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:andesite", {
	description = "Andesite",
	tiles = {"vlf_blocks_andesite.png"},
	is_ground_content = true,
	groups = {stone = 1, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:diorite", {
	description = "Diorite",
	tiles = {"vlf_blocks_diorite.png"},
	is_ground_content = true,
	groups = {stone = 1, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:terracotta", {
	description = "Terracotta",
	tiles = {"vlf_blocks_terracotta.png"},
	is_ground_content = true,
	groups = {cracky = 3, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:red_terracotta", {
	description = "Red Terracotta",
	tiles = {"vlf_blocks_red_terracotta.png"},
	is_ground_content = true,
	groups = {cracky = 3, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:orange_terracotta", {
	description = "Orange Terracotta",
	tiles = {"vlf_blocks_orange_terracotta.png"},
	is_ground_content = true,
	groups = {cracky = 3, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:yellow_terracotta", {
	description = "Yellow Terracotta",
	tiles = {"vlf_blocks_yellow_terracotta.png"},
	is_ground_content = true,
	groups = {cracky = 3, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:white_terracotta", {
	description = "White Terracotta",
	tiles = {"vlf_blocks_white_terracotta.png"},
	is_ground_content = true,
	groups = {cracky = 3, voxelforge_material = 1},
})

-- Tree variants
minetest.register_node("vlf_blocks:spruce_leaves", {
	description = "Spruce Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	tiles = {"vlf_blocks_spruce_leaves.png"},
	paramtype = "light",
	groups = {leafdecay = 3, flammable = 2, voxelforge_material = 1},
	drop = {
		max_items = 1,
		items = {
			{items = {"vlf_blocks:spruce_sapling"}, rarity = 20},
			{items = {"vlf_blocks:spruce_leaves"}}
		}
	},
})

minetest.register_node("vlf_blocks:birch_leaves", {
	description = "Birch Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	tiles = {"vlf_blocks_birch_leaves.png"},
	paramtype = "light",
	groups = {leafdecay = 3, flammable = 2, voxelforge_material = 1},
	drop = {
		max_items = 1,
		items = {
			{items = {"vlf_blocks:birch_sapling"}, rarity = 20},
			{items = {"vlf_blocks:birch_leaves"}}
		}
	},
})

minetest.register_node("vlf_blocks:jungle_leaves", {
	description = "Jungle Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	tiles = {"vlf_blocks_jungle_leaves.png"},
	paramtype = "light",
	groups = {leafdecay = 3, flammable = 2, voxelforge_material = 1},
	drop = {
		max_items = 1,
		items = {
			{items = {"vlf_blocks:jungle_sapling"}, rarity = 40},
			{items = {"vlf_blocks:jungle_leaves"}}
		}
	},
})

minetest.register_node("vlf_blocks:acacia_leaves", {
	description = "Acacia Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	tiles = {"vlf_blocks_acacia_leaves.png"},
	paramtype = "light",
	groups = {leafdecay = 3, flammable = 2, voxelforge_material = 1},
	drop = {
		max_items = 1,
		items = {
			{items = {"vlf_blocks:acacia_sapling"}, rarity = 20},
			{items = {"vlf_blocks:acacia_leaves"}}
		}
	},
})

minetest.register_node("vlf_blocks:spruce_wood", {
	description = "Spruce Wood",
	tiles = {"vlf_blocks_spruce_wood.png"},
	is_ground_content = false,
	groups = {flammable = 3, wood = 1, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:birch_wood", {
	description = "Birch Wood",
	tiles = {"vlf_blocks_birch_wood.png"},
	is_ground_content = false,
	groups = {flammable = 3, wood = 1, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:jungle_wood", {
	description = "Jungle Wood",
	tiles = {"vlf_blocks_jungle_wood.png"},
	is_ground_content = false,
	groups = {flammable = 3, wood = 1, voxelforge_material = 1},
})

minetest.register_node("vlf_blocks:acacia_wood", {
	description = "Acacia Wood",
	tiles = {"vlf_blocks_acacia_wood.png"},
	is_ground_content = false,
	groups = {flammable = 3, wood = 1, voxelforge_material = 1},
})

-- Craftitems
minetest.register_craftitem("vlf_blocks:stick", {
	description = "Stick",
	inventory_image = "vlf_blocks_stick.png",
	groups = {stick = 1, flammable = 2},
})

minetest.register_craftitem("vlf_blocks:coal_lump", {
	description = "Coal Lump",
	inventory_image = "voxelforge_coal_lump.png",
})

minetest.register_craftitem("vlf_blocks:iron_lump", {
	description = "Iron Lump",
	inventory_image = "voxelforge_iron_lump.png",
})

minetest.register_craftitem("vlf_blocks:copper_lump", {
	description = "Copper Lump",
	inventory_image = "voxelforge_copper_lump.png",
})

minetest.register_craftitem("vlf_blocks:iron_ingot", {
	description = "Iron Ingot",
	inventory_image = "voxelforge_iron_ingot.png",
})

minetest.register_craftitem("vlf_blocks:copper_ingot", {
	description = "Copper Ingot",
	inventory_image = "voxelforge_copper_ingot.png",
})

-- Stick Fence - a decorative block made entirely from sticks
minetest.register_node("vlf_blocks:stick_fence", {
	description = "Stick Fence",
	drawtype = "fencelike",
	tiles = {"vlf_blocks_stick.png"},
	inventory_image = "vlf_blocks_stick_fence.png",
	wield_image = "vlf_blocks_stick_fence.png",
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, fence = 1, voxelforge_material = 1},
	connects_to = {"group:fence", "group:wood", "group:tree"},
	selection_box = {
		type = "fixed",
		fixed = {-1/7, -1/2, -1/7, 1/7, 1/2, 1/7},
	},
})

-- Fern registration function
local function register_fern(size, description, scale_factor)
	local node_name = "vlf_blocks:fern_" .. size
	local texture_name = "vlf_blocks_fern_" .. size .. ".png"

	-- Calculate visual scale and selection box based on size
	local visual_scale = scale_factor or 1.0
	local box_height = math.min(0.5, 0.1 + (visual_scale * 0.4))
	local box_width = math.min(0.4, 0.1 + (visual_scale * 0.3))

	minetest.register_node(node_name, {
		description = description,
		drawtype = "plantlike",
		tiles = {texture_name},
		inventory_image = texture_name,
		wield_image = texture_name,
		paramtype = "light",
		--paramtype2 = "meshoptions",
		place_param2 = 4, -- Random rotation
		sunlight_propagates = true,
		walkable = false,
		buildable_to = true,
		floodable = true,
		visual_scale = visual_scale,
		selection_box = {
			type = "fixed",
			fixed = {-box_width, -0.5, -box_width, box_width, box_height, box_width},
		},
		groups = {
			snappy = 3,
			flora = 1,
			attached_node = 1,
			flammable = 1,
			fern = 1,
			voxelforge_material = 1
		},
		sounds = {
			dig = {name = "default_dig_snappy", gain = 0.4},
			dug = {name = "default_grass_footstep", gain = 0.7},
			place = {name = "default_place_node", gain = 1.0},
		},
		drop = {
			max_items = 2,
			items = {
				{items = {node_name}, rarity = 1},
				{items = {"vlf_blocks:fern_small"}, rarity = 8}, -- Chance to drop small fern for spreading
			}
		},
		-- Growth and spreading mechanics
		on_construct = function(pos)
			-- Set up growth timer
			local timer = minetest.get_node_timer(pos)
			timer:start(math.random(1200, 2400)) -- 20-40 minutes for growth check
		end,
		on_timer = function(pos, elapsed)
			local node = minetest.get_node(pos)
			local meta = minetest.get_meta(pos)

			-- Very slow growth chance (5%)
			if math.random(1, 20) == 1 then
				local current_size = size
				local next_size = nil

				if current_size == "small" then
					next_size = "medium"
				elseif current_size == "medium" then
					next_size = "large"
				elseif current_size == "large" then
					next_size = "very_large"
				end

				if next_size then
					minetest.set_node(pos, {name = "vlf_blocks:fern_" .. next_size, param2 = node.param2})
					local new_timer = minetest.get_node_timer(pos)
					new_timer:start(math.random(1800, 3600)) -- Longer timer for larger ferns
				end
			end

			-- Very slow spreading chance (2%)
			if math.random(1, 50) == 1 then
				local spread_positions = {}
				for dx = -2, 2 do
					for dz = -2, 2 do
						if dx ~= 0 or dz ~= 0 then
							local spread_pos = {x = pos.x + dx, y = pos.y, z = pos.z + dz}
							local spread_node = minetest.get_node(spread_pos)
							local below_node = minetest.get_node({x = spread_pos.x, y = spread_pos.y - 1, z = spread_pos.z})

							-- Check if position is suitable for fern growth
							if spread_node.name == "air" and
							   (below_node.name == "vlf_blocks:dirt_with_grass" or
								below_node.name == "vlf_blocks:dirt" or
								minetest.get_item_group(below_node.name, "soil") > 0) then
								table.insert(spread_positions, spread_pos)
							end
						end
					end
				end

				if #spread_positions > 0 then
					local spread_pos = spread_positions[math.random(1, #spread_positions)]
					minetest.set_node(spread_pos, {name = "vlf_blocks:fern_small", param2 = math.random(0, 3)})
					local spread_timer = minetest.get_node_timer(spread_pos)
					spread_timer:start(math.random(1200, 2400))
				end
			end

			-- Restart timer for next check
			return math.random(1200, 2400)
		end,
	})
end

-- Register different fern sizes
register_fern("small", "Small Fern", 1)
register_fern("medium", "Medium Fern", 2)
register_fern("large", "Large Fern", 2)
register_fern("very_large", "Very Large Fern", 2.5)

-- Test command for ferns (remove this later)
minetest.register_chatcommand("test_fern", {
	params = "<size>",
	description = "Place a test fern (small, medium, large, very_large)",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end

		local size = param or "small"
		local fern_name = "vlf_blocks:fern_" .. size

		if not minetest.registered_nodes[fern_name] then
			return false, "Fern type not found: " .. fern_name
		end

		local pos = player:get_pos()
		pos.y = pos.y + 1

		minetest.set_node(pos, {name = fern_name, param2 = math.random(0, 3)})

		return true, "Placed " .. fern_name .. " at " .. minetest.pos_to_string(pos)
	end,
})

-- Basic crafting recipes

minetest.register_craft({
	output = "vlf_blocks:stick 4",
	recipe = {
		{"vlf_blocks:planks"},
		{"vlf_blocks:planks"},
	}
})

minetest.register_on_joinplayer(function(player)
	player:hud_set_hotbar_itemcount(9)
	player:hud_set_hotbar_image("vlf_core_hud_bg.png")
	player:hud_set_hotbar_selected_image("vlf_core_hud_selected.png")
end)

minetest.register_on_joinplayer(function(player)
	-- Override default physics
	player:set_physics_override({
		speed = 1.1,		 -- Slightly faster movement
		jump = 1.1,		  -- Slightly higher jump
		gravity = 1.0,	   -- Normal gravity
		sneak = true,
		sneak_glitch = false,
	})
end)
