-- Ancient Hermitage - mini ancient city

--[[vlf_structures.register_structure("trial_chambers",{
	place_on = {"vlf_deepslate:deepslate","vlf_sculk:sculk"},
	fill_ratio = 0.01,
	flags = "all_floors",
	solid_ground = true,
	make_foundation = true,
	chunk_probability = 5, --high prob since placement underground is relatively unlikely
	y_max = vlf_vars.mg_overworld_min + 72,
	y_min = vlf_vars.mg_overworld_min + 12,
	biomes = { "DeepDark" },
	sidelen = 32,
	filenames = {
		vlf_structures.schempath.."/schems/entrance_1.mts",
	},

	loot = {
		["vlf_chests:chest_small" ] ={{
			stacks_min = 3,
			stacks_max = 3,
			items = {
				{ itemstring = "vlf_core:coal_lump", weight = 7, amount_min = 6, amount_max=15 },
				{ itemstring = "vlf_mobitems:bone", weight = 5, amount_min = 1, amount_max = 15 },
				{ itemstring = "vlf_blackstone:soul_torch", weight = 5, amount_min = 1, amount_max=15 },
				{ itemstring = "vlf_books:book", weight = 5, amount_min = 3, amount_max=10 },
				{ itemstring = "vlf_entity_effects:regeneration", weight = 5, amount_min = 1, amount_max=1 },
				{ itemstring = "vlf_books:book", weight = 5, func = function(stack, pr)vlf_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },

				--{ itemstring = "vlf_jukebox:disc_fragment", weight = 4, amount_min = 1, amount_max = 3 },

				{ itemstring = "vlf_amethyst:amethyst_shard", weight = 3, amount_min = 1, amount_max = 15 },
				{ itemstring = "vlf_lush_caves:glow_berry", weight = 3, amount_min = 1, amount_max = 15 },
				{ itemstring = "vlf_sculk:sculk", weight = 3, amount_min = 4, amount_max = 10 },
				--{ itemstring = "vlf_candles:candle", weight = 3, amount_min = 1, amount_max = 4 },
				{ itemstring = "vlf_experience:bottle", weight = 3, amount_min = 1, amount_max = 3 },
				--{ itemstring = "vlf_sculk:sensor", weight = 3, amount_min = 1, amount_max = 3 },
				--SWIFT SNEAK{ itemstring = "vlf_books:book", weight = 5, func = function(stack, pr)vlf_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },

				{ itemstring = "vlf_armor:leggings_iron", weight = 1, func = function(stack, pr)vlf_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "vlf_armor:ward", weight = 1 },
				-- { itemstring = "vlf_armor:silence", weight = 1 }, --TODO: Add silence armor trim

				{ itemstring = "vlf_sculk:catalyst", weight = 2, amount_min = 1, amount_max = 2 },
				{ itemstring = "vlf_compass:compass", weight = 2, amount_min = 1, amount_max = 1 },
				{ itemstring = "vlf_jukebox:record_1", weight = 2 },
				{ itemstring = "vlf_jukebox:record_4", weight = 2 },

				--{ itemstring = "vlf_mobitems:LEAD", weight = 2, amount_min = 1, amount_max = 1 },
				{ itemstring = "vlf_mobitems:nametag", weight = 2, amount_min = 1, amount_max = 3 },
				{ itemstring = "vlf_mobitems:saddle", weight = 2, amount_min = 1, amount_max = 1 },

				{ itemstring = "vlf_farming:hoe_diamond", weight = 2, amount_min = 1, amount_max = 1 },
				{ itemstring = "vlf_mobitems:diamond_horse_armor", weight = 2 },

				{ itemstring = "vlf_core:apple_gold_enchanted", weight = 1 },
				{ itemstring = "vlf_jukebox:record_8", weight = 2 },

			}},
		}
	}
})]]
