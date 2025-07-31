-- VoxelForge Core Mapgen
-- Mapgen aliases for world generation

-- Set mapgen aliases to use VoxelForge blocks
minetest.register_alias("mapgen_stone", "vlf_blocks:stone")
minetest.register_alias("mapgen_dirt", "vlf_blocks:dirt")
minetest.register_alias("mapgen_dirt_with_grass", "vlf_blocks:dirt_with_grass")

-- Water aliases (use air for now since we don't have water blocks yet)
minetest.register_alias("mapgen_water_source", "vlf_blocks:water_source")
minetest.register_alias("mapgen_river_water_source", "vlf_blocks:water_source")

-- Ore generation aliases
minetest.register_alias("mapgen_stone_with_coal", "vlf_blocks:coal_ore")
minetest.register_alias("mapgen_stone_with_iron", "vlf_blocks:iron_ore")
minetest.register_alias("mapgen_stone_with_copper", "vlf_blocks:copper_ore")

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
