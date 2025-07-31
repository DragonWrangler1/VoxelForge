-- VLF Biomes - Comprehensive biome system with improved placement accuracy
-- Load the enhanced biome accuracy system
local modpath = minetest.get_modpath("vlf_biomes")
local biome_accuracy = dofile(modpath .. "/biome_accuracy.lua")

-- Register biomes after all mods have loaded and voxelgen is initialized
minetest.register_on_mods_loaded(function()
	-- Add a small delay to ensure voxelgen is fully initialized
	minetest.after(0.1, function()
		minetest.log("action", "[VLF Biomes] Registering comprehensive biome system...")

		-- Ensure voxelgen mapgen is initialized before registering biomes
		if not voxelgen.mapgen.initialized then
			minetest.log("action", "[VLF Biomes] Initializing voxelgen mapgen first...")
			local world_seed = minetest.get_mapgen_setting("seed")
			minetest.log("action", "[VLF Biomes] World seed: " .. tostring(world_seed))
			voxelgen.mapgen.init()
		end

		-- Verify climate system is initialized
		if not voxelgen.climate.initialized then
			minetest.log("warning", "[VLF Biomes] Climate system not initialized, biomes may not work properly")
			-- Try to initialize it manually
			local world_seed = minetest.get_mapgen_setting("seed")
			if world_seed then
				minetest.log("action", "[VLF Biomes] Attempting to initialize climate system with seed: " .. world_seed)
				voxelgen.climate.init(world_seed)
			end
		end

		-- OCEAN BIOMES

		-- Frozen Ocean
		local frozen_ocean = voxelgen.create_biome_def(
			"frozen_ocean",
			{
				temperature_levels = {0}, -- Frozen
				humidity_levels = {0, 1, 2, 3, 4}, -- All humidity levels
				continentalness_names = {"deep_ocean", "ocean"},
				erosion_levels = {1, 2, 3, 4, 5, 6},
				pv_names = {"valleys", "low", "mid", "high"},
				depth_min = 0,
				depth_max = 0,
				y_min = -50,
				y_max = 0,
				y_blend = 2
			},
			{
				node_top = "vlf_blocks:gravel",
				node_filler = "vlf_blocks:gravel",
				node_stone = "vlf_blocks:stone",
				node_water_top = "vlf_blocks:ice"
			},
			{
				depth_top = 1,
				depth_filler = 4,
				priority = 10,
			}
		)
		voxelgen.register_biome(frozen_ocean)

		-- Cold Ocean
		local cold_ocean = voxelgen.create_biome_def(
			"cold_ocean",
			{
				temperature_levels = {1}, -- Cold
				humidity_levels = {0, 1, 2, 3, 4},
				continentalness_names = {"deep_ocean", "ocean"},
				erosion_levels = {1, 2, 3, 4, 5, 6},
				pv_names = {"valleys", "low", "mid", "high"},
				depth_min = 0,
				depth_max = 0,
				y_min = -50,
				y_max = 0,
				y_blend = 2
			},
			{
				node_top = "vlf_blocks:gravel",
				node_filler = "vlf_blocks:gravel",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 4,
				priority = 10,
			}
		)
		voxelgen.register_biome(cold_ocean)

		-- Warm Ocean
		local warm_ocean = voxelgen.create_biome_def(
			"warm_ocean",
			{
				temperature_levels = {2, 3}, -- Temperate to Warm
				humidity_levels = {0, 1, 2, 3, 4},
				continentalness_names = {"deep_ocean", "ocean"},
				erosion_levels = {1, 2, 3, 4, 5, 6},
				pv_names = {"valleys", "low", "mid", "high"},
				depth_min = 0,
				depth_max = 0,
				y_min = -50,
				y_max = 0,
				y_blend = 2
			},
			{
				node_top = "vlf_blocks:sand",
				node_filler = "vlf_blocks:sand",
				node_stone = "vlf_blocks:sandstone"
			},
			{
				depth_top = 1,
				depth_filler = 4,
				priority = 10,
			}
		)
		voxelgen.register_biome(warm_ocean)

		-- Hot Ocean
		local hot_ocean = voxelgen.create_biome_def(
			"hot_ocean",
			{
				temperature_levels = {4}, -- Hot
				humidity_levels = {0, 1, 2, 3, 4},
				continentalness_names = {"deep_ocean", "ocean"},
				erosion_levels = {1, 2, 3, 4, 5, 6},
				pv_names = {"valleys", "low", "mid", "high"},
				depth_min = 0,
				depth_max = 0,
				y_min = -50,
				y_max = 0,
				y_blend = 2
			},
			{
				node_top = "vlf_blocks:sand",
				node_filler = "vlf_blocks:sand",
				node_stone = "vlf_blocks:sandstone"
			},
			{
				depth_top = 1,
				depth_filler = 4,
				priority = 10,
			}
		)
		voxelgen.register_biome(hot_ocean)

		-- COASTAL AND TRANSITION BIOMES

		-- Beach
		local beach = voxelgen.create_biome_def(
			"beach",
			{
				temperature_levels = {1, 2, 3, 4}, -- Cold to Hot (expanded for better transitions)
				humidity_levels = {0, 1, 2, 3, 4}, -- All humidity levels
				continentalness_names = {"coast"},
				erosion_levels = {4, 5, 6}, -- Flat areas
				pv_names = {"valleys", "low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = -5,
				y_max = 15,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:sand",
				node_filler = "vlf_blocks:sand",
				node_stone = "vlf_blocks:sandstone"
			},
			{
				depth_top = 2,
				depth_filler = 4,
				priority = 9,
			}
		)
		voxelgen.register_biome(beach)

		-- Stony Shore
		local stony_shore = voxelgen.create_biome_def(
			"stony_shore",
			{
				temperature_levels = {0, 1}, -- Frozen to Cold
				humidity_levels = {0, 1, 2, 3, 4},
				continentalness_names = {"coast"},
				erosion_levels = {1, 2, 3}, -- Rocky areas
				pv_names = {"valleys", "low", "mid", "high"},
				depth_min = 0,
				depth_max = 0,
				y_min = -5,
				y_max = 25,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:gravel",
				node_filler = "vlf_blocks:gravel",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 9,
			}
		)
		voxelgen.register_biome(stony_shore)

		-- GRASSLAND BIOMES

		-- Plains
		local plains = voxelgen.create_biome_def(
			"plains",
			{
				temperature_levels = {1, 2, 3}, -- Cold to Warm (expanded for better transitions)
				humidity_levels = {1, 2, 3}, -- Dry to Humid (expanded for better transitions)
				continentalness_names = {"near_inland", "mid_inland"},
				erosion_levels = {4, 5, 6}, -- Flat to hilly
				pv_names = {"valleys", "low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 120,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 5,
			}
		)
		voxelgen.register_biome(plains)

		-- Sunflower Plains
		local sunflower_plains = voxelgen.create_biome_def(
			"sunflower_plains",
			{
				temperature_levels = {2}, -- Temperate
				humidity_levels = {2, 3}, -- Neutral to Humid
				continentalness_names = {"near_inland", "mid_inland"},
				erosion_levels = {5, 6}, -- Very flat
				pv_names = {"low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 100,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 6,
			}
		)
		voxelgen.register_biome(sunflower_plains)

		-- Savanna
		local savanna = voxelgen.create_biome_def(
			"savanna",
			{
				temperature_levels = {2, 3}, -- Temperate to Warm (expanded for better transitions)
				humidity_levels = {1, 2}, -- Dry to Neutral
				continentalness_names = {"near_inland", "mid_inland"},
				erosion_levels = {3, 4, 5}, -- Hilly to flat
				pv_names = {"valleys", "low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 140,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 6,
			}
		)
		voxelgen.register_biome(savanna)

		-- Savanna Plateau
		local savanna_plateau = voxelgen.create_biome_def(
			"savanna_plateau",
			{
				temperature_levels = {3}, -- Warm
				humidity_levels = {1, 2}, -- Dry to Neutral
				continentalness_names = {"mid_inland", "far_inland"},
				erosion_levels = {1, 2, 3}, -- Mountainous to hilly
				pv_names = {"high", "peaks"},
				depth_min = 0,
				depth_max = 0,
				y_min = 80,
				y_max = 200,
				y_blend = 2
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 2,
				priority = 7,
			}
		)
		voxelgen.register_biome(savanna_plateau)

		-- FOREST BIOMES

		-- Forest
		local forest = voxelgen.create_biome_def(
			"forest",
			{
				temperature_levels = {1, 2, 3}, -- Cold to Warm (expanded for better transitions)
				humidity_levels = {2, 3, 4}, -- Neutral to Wet (expanded for better transitions)
				continentalness_names = {"near_inland", "mid_inland"},
				erosion_levels = {2, 3, 4}, -- Mountainous to hilly
				pv_names = {"valleys", "low", "mid", "high"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 150,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 6,
			}
		)
		voxelgen.register_biome(forest)

		-- Birch Forest
		local birch_forest = voxelgen.create_biome_def(
			"birch_forest",
			{
				temperature_levels = {2}, -- Temperate
				humidity_levels = {3}, -- Humid
				continentalness_names = {"near_inland", "mid_inland"},
				erosion_levels = {3, 4, 5}, -- Hilly to flat
				pv_names = {"low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 120,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 6,
			}
		)
		voxelgen.register_biome(birch_forest)

		-- Dark Forest
		local dark_forest = voxelgen.create_biome_def(
			"dark_forest",
			{
				temperature_levels = {2}, -- Temperate
				humidity_levels = {4}, -- Wet
				continentalness_names = {"mid_inland", "far_inland"},
				erosion_levels = {1, 2, 3}, -- Mountainous to hilly
				pv_names = {"valleys", "low"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 140,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:podzol",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 7,
			}
		)
		voxelgen.register_biome(dark_forest)

		-- Jungle
		local jungle = voxelgen.create_biome_def(
			"jungle",
			{
				temperature_levels = {3, 4}, -- Warm to Hot (expanded for better transitions)
				humidity_levels = {3, 4}, -- Humid to Wet (expanded for better transitions)
				continentalness_names = {"near_inland", "mid_inland"},
				erosion_levels = {2, 3, 4}, -- Mountainous to hilly
				pv_names = {"valleys", "low", "mid", "high"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 120,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 8,
			}
		)
		voxelgen.register_biome(jungle)

		-- Jungle Hills
		local jungle_hills = voxelgen.create_biome_def(
			"jungle_hills",
			{
				temperature_levels = {4}, -- Hot
				humidity_levels = {4}, -- Wet
				continentalness_names = {"mid_inland", "far_inland"},
				erosion_levels = {1, 2}, -- Very mountainous
				pv_names = {"high", "peaks"},
				depth_min = 0,
				depth_max = 0,
				y_min = 40,
				y_max = 200,
				y_blend = 2
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 2,
				priority = 8,
			}
		)
		voxelgen.register_biome(jungle_hills)

		-- TAIGA BIOMES

		-- Taiga
		local taiga = voxelgen.create_biome_def(
			"taiga",
			{
				temperature_levels = {0, 1, 2}, -- Frozen to Temperate (expanded for better transitions)
				humidity_levels = {2, 3}, -- Neutral to Humid
				continentalness_names = {"mid_inland", "far_inland"},
				erosion_levels = {2, 3, 4}, -- Mountainous to hilly
				pv_names = {"valleys", "low", "mid", "high"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 150,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:podzol",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 7,
			}
		)
		voxelgen.register_biome(taiga)

		-- Snowy Taiga
		local snowy_taiga = voxelgen.create_biome_def(
			"snowy_taiga",
			{
				temperature_levels = {0}, -- Frozen
				humidity_levels = {2, 3}, -- Neutral to Humid
				continentalness_names = {"mid_inland", "far_inland"},
				erosion_levels = {2, 3, 4}, -- Mountainous to hilly
				pv_names = {"valleys", "low", "mid", "high"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 150,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:snow_block",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone",
				node_dust = "vlf_blocks:snow"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 7,
			}
		)
		voxelgen.register_biome(snowy_taiga)

		-- Giant Tree Taiga
		local giant_tree_taiga = voxelgen.create_biome_def(
			"giant_tree_taiga",
			{
				temperature_levels = {1}, -- Cold
				humidity_levels = {3, 4}, -- Humid to Wet
				continentalness_names = {"far_inland"},
				erosion_levels = {1, 2, 3}, -- Mountainous to hilly
				pv_names = {"valleys", "low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 160,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:podzol",
				node_filler = "vlf_blocks:coarse_dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 8,
			}
		)
		voxelgen.register_biome(giant_tree_taiga)

		-- DESERT BIOMES

		-- Desert
		local desert = voxelgen.create_biome_def(
			"desert",
			{
				temperature_levels = {3, 4}, -- Warm to Hot (expanded for better transitions)
				humidity_levels = {0, 1}, -- Arid to Dry
				continentalness_names = {"near_inland", "mid_inland"},
				erosion_levels = {4, 5, 6}, -- Hilly to flat
				pv_names = {"valleys", "low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 100,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:sand",
				node_filler = "vlf_blocks:sand",
				node_stone = "vlf_blocks:sandstone"
			},
			{
				depth_top = 1,
				depth_filler = 4,
				priority = 7,
			}
		)
		voxelgen.register_biome(desert)

		-- Desert Hills
		local desert_hills = voxelgen.create_biome_def(
			"desert_hills",
			{
				temperature_levels = {4}, -- Hot
				humidity_levels = {0, 1}, -- Arid to Dry
				continentalness_names = {"mid_inland", "far_inland"},
				erosion_levels = {1, 2, 3}, -- Mountainous to hilly
				pv_names = {"high", "peaks"},
				depth_min = 0,
				depth_max = 0,
				y_min = 20,
				y_max = 180,
				y_blend = 2
			},
			{
				node_top = "vlf_blocks:sand",
				node_filler = "vlf_blocks:sandstone",
				node_stone = "vlf_blocks:sandstone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 7,
			}
		)
		voxelgen.register_biome(desert_hills)

		-- Badlands
		local badlands = voxelgen.create_biome_def(
			"badlands",
			{
				temperature_levels = {3, 4}, -- Warm to Hot
				humidity_levels = {0, 1}, -- Arid to Dry
				continentalness_names = {"mid_inland", "far_inland"},
				erosion_levels = {1, 2, 3}, -- Mountainous to hilly
				pv_names = {"valleys", "low", "mid", "high"},
				depth_min = 0,
				depth_max = 0,
				y_min = 20,
				y_max = 180,
				y_blend = 2
			},
			{
				node_top = "vlf_blocks:red_sand",
				node_filler = "vlf_blocks:red_sandstone",
				node_stone = "vlf_blocks:red_sandstone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 8,
			}
		)
		voxelgen.register_biome(badlands)

		-- Eroded Badlands
		local eroded_badlands = voxelgen.create_biome_def(
			"eroded_badlands",
			{
				temperature_levels = {3, 4}, -- Warm to Hot
				humidity_levels = {0}, -- Arid
				continentalness_names = {"far_inland"},
				erosion_levels = {0, 1}, -- Most mountainous
				pv_names = {"valleys", "low", "mid", "high", "peaks"},
				depth_min = 0,
				depth_max = 0,
				y_min = 40,
				y_max = 220,
				y_blend = 3
			},
			{
				node_top = "vlf_blocks:terracotta",
				node_filler = "vlf_blocks:red_terracotta",
				node_stone = "vlf_blocks:red_sandstone"
			},
			{
				depth_top = 1,
				depth_filler = 2,
				priority = 9,
			}
		)
		voxelgen.register_biome(eroded_badlands)

		-- MOUNTAIN BIOMES

		-- Mountains
		local mountains = voxelgen.create_biome_def(
			"mountains",
			{
				temperature_levels = {1, 2, 3}, -- Cold to Warm (expanded for better transitions)
				humidity_levels = {1, 2, 3}, -- Dry to Humid (expanded for better transitions)
				continentalness_names = {"near_inland", "mid_inland", "far_inland"},
				erosion_levels = {0, 1, 2}, -- Most mountainous
				pv_names = {"high", "peaks"},
				depth_min = 0,
				depth_max = 0,
				y_min = 100,
				y_max = 300,
				y_blend = 3
			},
			{
				node_top = "vlf_blocks:stone",
				node_filler = "vlf_blocks:stone",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 0,
				depth_filler = 1,
				priority = 8,
			}
		)
		voxelgen.register_biome(mountains)

		-- Snowy Mountains
		local snowy_mountains = voxelgen.create_biome_def(
			"snowy_mountains",
			{
				temperature_levels = {0}, -- Frozen
				humidity_levels = {1, 2, 3}, -- Dry to Humid
				continentalness_names = {"near_inland", "mid_inland", "far_inland"},
				erosion_levels = {0, 1, 2}, -- Most mountainous
				pv_names = {"high", "peaks"},
				depth_min = 0,
				depth_max = 0,
				y_min = 80,
				y_max = 300,
				y_blend = 3
			},
			{
				node_top = "vlf_blocks:snow_block",
				node_filler = "vlf_blocks:stone",
				node_stone = "vlf_blocks:stone",
				node_dust = "vlf_blocks:snow"
			},
			{
				depth_top = 1,
				depth_filler = 1,
				priority = 8,
			}
		)
		voxelgen.register_biome(snowy_mountains)

		-- Gravelly Mountains
		local gravelly_mountains = voxelgen.create_biome_def(
			"gravelly_mountains",
			{
				temperature_levels = {1, 2}, -- Cold to Temperate
				humidity_levels = {0, 1}, -- Arid to Dry
				continentalness_names = {"mid_inland", "far_inland"},
				erosion_levels = {0, 1}, -- Most mountainous
				pv_names = {"peaks"},
				depth_min = 0,
				depth_max = 0,
				y_min = 120,
				y_max = 300,
				y_blend = 3
			},
			{
				node_top = "vlf_blocks:gravel",
				node_filler = "vlf_blocks:gravel",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 2,
				depth_filler = 3,
				priority = 9,
			}
		)
		voxelgen.register_biome(gravelly_mountains)

		-- SPECIAL BIOMES

		-- Swampland
		local swampland = voxelgen.create_biome_def(
			"swampland",
			{
				temperature_levels = {2, 3}, -- Temperate to Warm
				humidity_levels = {3, 4}, -- Humid to Wet (expanded for better transitions)
				continentalness_names = {"coast", "near_inland"},
				erosion_levels = {5, 6}, -- Flat
				pv_names = {"valleys", "low"},
				depth_min = 0,
				depth_max = 0,
				y_min = -5,
				y_max = 25,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:clay",
				node_filler = "vlf_blocks:clay",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 4,
				priority = 9,
			}
		)
		voxelgen.register_biome(swampland)

		-- Mushroom Fields
		local mushroom_fields = voxelgen.create_biome_def(
			"mushroom_fields",
			{
				temperature_levels = {2}, -- Temperate
				humidity_levels = {3}, -- Humid
				continentalness_names = {"mushroom_fields"},
				erosion_levels = {3, 4, 5, 6}, -- Hilly to flat
				pv_names = {"valleys", "low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 100,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:mycelium",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 10,
			}
		)
		voxelgen.register_biome(mushroom_fields)

		-- Ice Spikes (rare frozen biome, should not border deserts)
		local ice_spikes = voxelgen.create_biome_def(
			"ice_spikes",
			{
				temperature_levels = {0}, -- Frozen only
				humidity_levels = {2, 3}, -- Neutral to Humid (avoid arid conditions that deserts use)
				continentalness_names = {"mid_inland", "far_inland"}, -- Expanded to avoid only far_inland
				erosion_levels = {4, 5, 6}, -- Flat
				pv_names = {"low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 80,
				y_blend = 2, -- Increased blend for smoother transitions
			},
			{
				node_top = "vlf_blocks:snow_block",
				node_filler = "vlf_blocks:snow_block",
				node_stone = "vlf_blocks:ice",
				node_dust = "vlf_blocks:snow"
			},
			{
				depth_top = 2,
				depth_filler = 4,
				priority = 7, -- Reduced priority to allow other biomes to take precedence
			}
		)
		voxelgen.register_biome(ice_spikes)

		-- Flower Forest
		local flower_forest = voxelgen.create_biome_def(
			"flower_forest",
			{
				temperature_levels = {2}, -- Temperate
				humidity_levels = {3}, -- Humid
				continentalness_names = {"near_inland"},
				erosion_levels = {4, 5}, -- Hilly to flat
				pv_names = {"low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 100,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 7,
			}
		)
		voxelgen.register_biome(flower_forest)

		-- TUNDRA BIOMES

		-- Snowy Tundra
		local snowy_tundra = voxelgen.create_biome_def(
			"snowy_tundra",
			{
				temperature_levels = {0, 1}, -- Frozen to Cold (expanded for better transitions)
				humidity_levels = {1, 2, 3}, -- Dry to Humid (expanded for better transitions)
				continentalness_names = {"near_inland", "mid_inland"},
				erosion_levels = {4, 5, 6}, -- Hilly to flat
				pv_names = {"valleys", "low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 100,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:snow_block",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone",
				node_dust = "vlf_blocks:snow"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 6,
			}
		)
		voxelgen.register_biome(snowy_tundra)

		-- TRANSITION BIOMES FOR REALISTIC BORDERS

		-- Steppe (transition between plains and desert)
		local steppe = voxelgen.create_biome_def(
			"steppe",
			{
				temperature_levels = {2, 3}, -- Temperate to Warm
				humidity_levels = {0, 1, 2}, -- Arid to Neutral (transition zone)
				continentalness_names = {"near_inland", "mid_inland"},
				erosion_levels = {4, 5, 6}, -- Flat to hilly
				pv_names = {"valleys", "low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 120,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 8, -- Higher priority for transition biome
			}
		)
		voxelgen.register_biome(steppe)

		-- Temperate Grassland (transition between forest and plains)
		local temperate_grassland = voxelgen.create_biome_def(
			"temperate_grassland",
			{
				temperature_levels = {1, 2}, -- Cold to Temperate
				humidity_levels = {2, 3}, -- Neutral to Humid
				continentalness_names = {"near_inland", "mid_inland"},
				erosion_levels = {3, 4, 5}, -- Hilly to flat
				pv_names = {"valleys", "low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 140,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 5,
			}
		)
		voxelgen.register_biome(temperate_grassland)

		-- Cold Desert (transition between tundra and desert at high altitudes)
		local cold_desert = voxelgen.create_biome_def(
			"cold_desert",
			{
				temperature_levels = {0, 1}, -- Frozen to Cold
				humidity_levels = {0, 1}, -- Arid to Dry
				continentalness_names = {"mid_inland", "far_inland"},
				erosion_levels = {2, 3, 4}, -- Mountainous to hilly
				pv_names = {"mid", "high"},
				depth_min = 0,
				depth_max = 0,
				y_min = 60,
				y_max = 180,
				y_blend = 2
			},
			{
				node_top = "vlf_blocks:gravel",
				node_filler = "vlf_blocks:gravel",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 7,
			}
		)
		voxelgen.register_biome(cold_desert)

		-- Montane Forest (transition between forest and mountains)
		local montane_forest = voxelgen.create_biome_def(
			"montane_forest",
			{
				temperature_levels = {1, 2}, -- Cold to Temperate
				humidity_levels = {2, 3}, -- Neutral to Humid
				continentalness_names = {"mid_inland", "far_inland"},
				erosion_levels = {1, 2, 3}, -- Mountainous to hilly
				pv_names = {"mid", "high"},
				depth_min = 0,
				depth_max = 0,
				y_min = 80,
				y_max = 200,
				y_blend = 2
			},
			{
				node_top = "vlf_blocks:podzol",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 2,
				priority = 7,
			}
		)
		voxelgen.register_biome(montane_forest)

		-- Tundra Steppe (transition between cold and warm dry areas)
		local tundra_steppe = voxelgen.create_biome_def(
			"tundra_steppe",
			{
				temperature_levels = {0, 1, 2}, -- Frozen to Temperate (wide range for transitions)
				humidity_levels = {0, 1}, -- Arid to Dry (matches desert humidity but different temperature)
				continentalness_names = {"mid_inland", "far_inland"},
				erosion_levels = {4, 5, 6}, -- Flat to hilly
				pv_names = {"valleys", "low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 120,
				y_blend = 2
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 8, -- High priority for transition biome
			}
		)
		voxelgen.register_biome(tundra_steppe)

		minetest.log("action", "[VLF Biomes] Successfully registered " ..
					"36+ comprehensive biomes with realistic transitions and improved placement accuracy")

		-- Register enhanced terrain features for the new biomes
		minetest.log("action", "[VLF Biomes] Registering enhanced terrain features...")

		-- Enhanced grass patches with biome-specific placement
		local grass_success = voxelgen.register_terrain_feature("vlf_biomes:enhanced_grass", {
			type = "block",
			node = "vlf_blocks:dirt_with_grass",
			biomes = {"plains", "forest", "birch_forest", "flower_forest", "sunflower_plains"},
			probability = 0.12,
			min_height = 1,
			max_height = 150,
			avoid_water = true,
			need_solid_ground = true,
			place_on = {"vlf_blocks:dirt", "vlf_blocks:stone"},
			spacing = 3,
			noise = {
				offset = 0.15,
				scale = 0.7,
				spread = {x = 35, y = 35, z = 35},
				seed = 12345,
				octaves = 3,
				persist = 0.6,
				lacunarity = 2.0
			}
		})

		-- Desert cacti and dead bushes
		local desert_vegetation = voxelgen.register_terrain_feature("vlf_biomes:desert_vegetation", {
			type = "function",
			biomes = {"desert", "desert_hills", "badlands"},
			probability = 0.08,
			min_height = 2,
			max_height = 150,
			avoid_water = true,
			need_solid_ground = true,
			place_on = {"vlf_blocks:sand", "vlf_blocks:red_sand"},
			spacing = 8,
			noise = {
				offset = 0.1,
				scale = 0.6,
				spread = {x = 60, y = 60, z = 60},
				seed = 23456,
				octaves = 2,
				persist = 0.5,
				lacunarity = 2.0
			},
			place_function = function(x, y, z, data, area, biome_name, feature_def)
				-- Simple desert vegetation placeholder
				local sand_id = minetest.get_content_id("vlf_blocks:sand")
				local red_sand_id = minetest.get_content_id("vlf_blocks:red_sand")

				if area:contains(x, y, z) then
					local vi = area:index(x, y, z)
					if biome_name == "badlands" then
						data[vi] = red_sand_id
					else
						data[vi] = sand_id
					end
					return true
				end
				return false
			end
		})

		-- Snow layers in cold biomes
		local snow_layers = voxelgen.register_terrain_feature("vlf_biomes:snow_layers", {
			type = "block",
			node = "vlf_blocks:snow",
			biomes = {"snowy_tundra", "snowy_taiga", "snowy_mountains", "ice_spikes"},
			probability = 0.25,
			min_height = 1,
			max_height = 300,
			avoid_water = true,
			need_solid_ground = true,
			place_on = {"vlf_blocks:snow_block", "vlf_blocks:dirt", "vlf_blocks:stone", "vlf_blocks:podzol"},
			spacing = 1,
			noise = {
				offset = 0.2,
				scale = 0.8,
				spread = {x = 25, y = 25, z = 25},
				seed = 34567,
				octaves = 2,
				persist = 0.4,
				lacunarity = 2.0
			}
		})

		-- Mountain stone formations
		local mountain_formations = voxelgen.register_terrain_feature("vlf_biomes:mountain_formations", {
			type = "function",
			biomes = {"mountains", "snowy_mountains", "gravelly_mountains"},
			probability = 0.15,
			min_height = 80,
			max_height = 300,
			avoid_water = true,
			need_solid_ground = true,
			place_on = {"vlf_blocks:stone", "vlf_blocks:gravel"},
			spacing = 12,
			noise = {
				offset = 0.0,
				scale = 0.7,
				spread = {x = 100, y = 100, z = 100},
				seed = 45678,
				octaves = 3,
				persist = 0.6,
				lacunarity = 2.0
			},
			place_function = function(x, y, z, data, area, biome_name, feature_def)
				local stone_id = minetest.get_content_id("vlf_blocks:stone")
				local granite_id = minetest.get_content_id("vlf_blocks:granite")
				local andesite_id = minetest.get_content_id("vlf_blocks:andesite")
				local diorite_id = minetest.get_content_id("vlf_blocks:diorite")

				-- Create small stone variety patches
				local stone_types = {stone_id, granite_id, andesite_id, diorite_id}
				local chosen_stone = stone_types[((x + z) % 4) + 1]

				local placed = false
				for dx = -1, 1 do
					for dz = -1, 1 do
						local px, pz = x + dx, z + dz
						if area:contains(px, y, pz) then
							local vi = area:index(px, y, pz)
							data[vi] = chosen_stone
							placed = true
						end
					end
				end

				return placed
			end
		})

		-- Swamp clay deposits
		local swamp_clay = voxelgen.register_terrain_feature("vlf_biomes:swamp_clay", {
			type = "block",
			node = "vlf_blocks:clay",
			biomes = {"swampland"},
			probability = 0.3,
			min_height = -5,
			max_height = 25,
			avoid_water = false,
			need_solid_ground = true,
			place_on = {"vlf_blocks:dirt", "vlf_blocks:clay"},
			spacing = 2,
			noise = {
				offset = 0.3,
				scale = 0.6,
				spread = {x = 20, y = 20, z = 20},
				seed = 56789,
				octaves = 2,
				persist = 0.5,
				lacunarity = 2.0
			}
		})

		-- Taiga ferns - scattered throughout taiga biomes
		minetest.log("error", "[VLF Biomes] Registering taiga ferns terrain feature...")

		local taiga_ferns = voxelgen.register_terrain_feature("vlf_biomes:taiga_ferns", {
			type = "function",
			biomes = {"taiga", "snowy_taiga", "giant_tree_taiga"},
			probability = 0.7,
			min_height = 2,
			max_height = 150,
			avoid_water = true,
			need_solid_ground = true,
			place_on = {"vlf_blocks:podzol", "vlf_blocks:dirt_with_grass", "vlf_blocks:coarse_dirt", "vlf_blocks:snow_block"},
			spacing = 3,
			noise = {
				offset = 0.2,
				scale = 0.4,
				spread = {x = 15, y = 15, z = 15},
				seed = 98765,
				octaves = 2,
				persist = 0.6,
				lacunarity = 2.0
			},
			place_function = function(x, y, z, data, area, biome_name, feature_def)
				-- Apply position-based randomization to avoid perfect grid patterns
				local world_seed = minetest.get_mapgen_setting("seed") or 0

				-- Create a position hash using world seed and coordinates
				local hash = (x * 73856093) + (z * 19349663) + (world_seed * 83492791)
				hash = hash % 2147483647  -- Keep within 32-bit signed integer range
				if hash < 0 then hash = hash + 2147483647 end

				-- Generate pseudo-random offsets based on the hash
				local rng_state = hash
				local function next_random()
					rng_state = (rng_state * 1103515245 + 12345) % 2147483647
					if rng_state < 0 then rng_state = rng_state + 2147483647 end
					return rng_state / 2147483647
				end

				-- Apply random offset within a 2-block radius
				local offset_x = math.floor((next_random() - 0.5) * 4)  -- -2 to +2
				local offset_z = math.floor((next_random() - 0.5) * 4)  -- -2 to +2

				-- Apply the offset to the position
				local actual_x = x + offset_x
				local actual_z = z + offset_z
				local actual_pos = {x = actual_x, y = y, z = actual_z}

				-- Check if the offset position is within the area bounds
				if not area:contains(actual_x, y + 1, actual_z) or not area:contains(actual_x, y, actual_z) then
					return false  -- Skip if out of bounds
				end

				minetest.log("error", "[VLF Biomes] Fern generation called at " .. minetest.pos_to_string(actual_pos) .. " (offset from " .. minetest.pos_to_string({x = x, y = y, z = z}) .. ") for biome: " .. (biome_name or "nil"))

				-- Check if fern nodes are registered
				if not minetest.registered_nodes["vlf_blocks:fern_small"] then
					minetest.log("error", "[VLF Biomes] Fern nodes not registered yet!")
					return false
				end

				-- Use mapgen data to check nodes instead of minetest.get_node() for reliability
				local pos_index = area:index(actual_x, y + 1, actual_z)
				local below_index = area:index(actual_x, y, actual_z)

				-- Get node IDs from mapgen data
				local node_at_id = data[pos_index]
				local node_below_id = data[below_index]

				-- Convert node IDs to names
				local node_at_name = minetest.get_name_from_content_id(node_at_id)
				local node_below_name = minetest.get_name_from_content_id(node_below_id)

				minetest.log("error", "[VLF Biomes] Node at pos: " .. node_at_name .. ", Node below: " .. node_below_name)

				-- Only place on suitable ground and in air
				if node_at_name ~= "air" then
					minetest.log("error", "[VLF Biomes] Position not air, skipping")
					return false
				end

				local suitable_ground = {
					["vlf_blocks:podzol"] = true,
					["vlf_blocks:dirt_with_grass"] = true,
					["vlf_blocks:coarse_dirt"] = true,
					["vlf_blocks:snow_block"] = true,
					["vlf_blocks:dirt"] = true  -- Add regular dirt as backup
				}

				if not suitable_ground[node_below_name] then
					minetest.log("error", "[VLF Biomes] Ground not suitable for fern: " .. node_below_name .. " at " .. minetest.pos_to_string(actual_pos))
					return false
				end

				-- Determine fern size based on biome and random chance
				local fern_type = "vlf_blocks:fern_small" -- Default
				local rand = math.floor(next_random() * 100) + 1  -- 1-100

				if biome_name == "giant_tree_taiga" then
					-- Giant tree taiga has larger ferns
					if rand <= 15 then
						fern_type = "vlf_blocks:fern_very_large"
					elseif rand <= 35 then
						fern_type = "vlf_blocks:fern_large"
					elseif rand <= 60 then
						fern_type = "vlf_blocks:fern_medium"
					else
						fern_type = "vlf_blocks:fern_small"
					end
				elseif biome_name == "taiga" then
					-- Regular taiga has medium-sized ferns
					if rand <= 20 then
						fern_type = "vlf_blocks:fern_large"
					elseif rand <= 40 then
						fern_type = "vlf_blocks:fern_medium"
					else
						fern_type = "vlf_blocks:fern_small"
					end
				else -- snowy_taiga
					-- Snowy taiga has mostly small ferns
					if rand <= 5 then
						fern_type = "vlf_blocks:fern_medium"
					else
						fern_type = "vlf_blocks:fern_small"
					end
				end

				-- Debug logging
				minetest.log("error", "[VLF Biomes] Placing fern " .. fern_type .. " at " .. minetest.pos_to_string(actual_pos) .. " in biome " .. biome_name)

				-- Place the fern in mapgen data with random rotation
				local fern_id = minetest.get_content_id(fern_type)
				data[pos_index] = fern_id

				-- Note: Timer will be started automatically when the node is constructed
				-- after mapgen completes, thanks to the on_construct callback in the node definition

				return true
			end
		})

		minetest.log("action", "[VLF Biomes] Taiga ferns registration result: " .. tostring(taiga_ferns))

		-- Log terrain feature registration results
		local features = {
			{"enhanced_grass", grass_success},
			{"desert_vegetation", desert_vegetation},
			{"snow_layers", snow_layers},
			{"mountain_formations", mountain_formations},
			{"swamp_clay", swamp_clay},
			{"taiga_ferns", taiga_ferns}
		}

		for _, feature_info in ipairs(features) do
			local name, success = feature_info[1], feature_info[2]
			if success then
				minetest.log("action", "[VLF Biomes] Successfully registered " .. name .. " terrain feature")
			else
				minetest.log("error", "[VLF Biomes] Failed to register " .. name .. " terrain feature")
			end
		end

		-- ADDITIONAL TEMPERATE BIOMES for better coverage

		-- Temperate Grassland (dry temperate areas)
		local temperate_grassland = voxelgen.create_biome_def(
			"temperate_grassland",
			{
				temperature_levels = {2}, -- Temperate
				humidity_levels = {1}, -- Dry
				continentalness_names = {"near_inland", "mid_inland"},
				erosion_levels = {4, 5, 6}, -- Flat to hilly
				pv_names = {"valleys", "low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 120,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 5,
			}
		)
		voxelgen.register_biome(temperate_grassland)

		-- Temperate Meadow (wet temperate areas)
		local temperate_meadow = voxelgen.create_biome_def(
			"temperate_meadow",
			{
				temperature_levels = {2}, -- Temperate
				humidity_levels = {4}, -- Wet
				continentalness_names = {"near_inland", "mid_inland"},
				erosion_levels = {4, 5, 6}, -- Flat to hilly
				pv_names = {"valleys", "low", "mid"},
				depth_min = 0,
				depth_max = 0,
				y_min = 2,
				y_max = 120,
				y_blend = 1
			},
			{
				node_top = "vlf_blocks:dirt_with_grass",
				node_filler = "vlf_blocks:dirt",
				node_stone = "vlf_blocks:stone"
			},
			{
				depth_top = 1,
				depth_filler = 3,
				priority = 5,
			}
		)
		voxelgen.register_biome(temperate_meadow)

		minetest.log("action", "[VLF Biomes] Registered fallback biome")

		minetest.log("action", "[VLF Biomes] Biome system initialization complete!")

		-- Initialize the enhanced biome accuracy system
		biome_accuracy.init()

	end) -- Close minetest.after
end) -- Close minetest.register_on_mods_loaded
