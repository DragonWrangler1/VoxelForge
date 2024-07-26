vlf_trials = {
	registered_vaults = {}
}
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
--local S = minetest.get_translator(modname)

dofile(modpath.."/api.lua")

vlf_trials.register_vault("vault",{
	key = "vlf_trials:trial_key",
	node_off = {
		tiles = { "vlf_trials_vault_top_off.png", "vlf_trials_vault_bottom.png",
			"vlf_trials_vault_side_off.png", "vlf_trials_vault_side_off.png",
			"vlf_trials_vault_side_off.png", "vlf_trials_vault_front_off.png",
		},
	},
	node_on = {
		tiles = { "vlf_trials_vault_top_on.png", "vlf_trials_vault_bottom.png",
			"vlf_trials_vault_side_on.png", "vlf_trials_vault_side_on.png",
			"vlf_trials_vault_side_on.png", "vlf_trials_vault_front_on.png",
		},
	},
	node_ejecting = {
		tiles = { "vlf_trials_vault_top_ejecting.png", "vlf_trials_vault_bottom.png",
			"vlf_trials_vault_side_ejecting.png", "vlf_trials_vault_side_ejecting.png",
			"vlf_trials_vault_side_ejecting.png", "vlf_trials_vault_front_ejecting.png",
		},
	},
	loot = {
		{
			stacks_min = 1,
			stacks_max = 1,
			items = {
				{ itemstring = "vlf_core:emerald", weight = 392, amount_min = 2, amount_max = 4 },
				{ itemstring = "vlf_bows:arrow", weight = 92, amount_min = 2, amount_max = 8 },
				--{ itemstring = "TODO:arrow_of_poision", weight = 92, amount_min = 2, amount_max = 8 },
				{ itemstring = "vlf_core:iron_ingot", weight = 69, amount_min = 1, amount_max = 4 },
				{ itemstring = "vlf_charges:wind_charge", weight = 69, amount_min = 1, amount_max = 3 },
				{ itemstring = "vlf_honey:honey_bottle", weight = 69, amount_min = 1, amount_max = 2 },
				--{ itemstring = "TODO:ominous_bottle", weight = 69, amount_min = 1, amount_max = 2 },
				{ itemstring = "vlf_shields:shield", weight = 300, amount_min = 1, amount_max = 1 },
				{ itemstring = "vlf_bows:bow", weight = 300, func = function(stack, pr) vlf_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "vlf_charges:wind_charge", weight = 23, amount_min = 4, amount_max = 12 },
				{ itemstring = "vlf_core:diamond", weight = 23, amount_min = 1, amount_max = 2 },
				{ itemstring = "vlf_farming:carrot_item_gold", weight = 200, amount_min = 1, amount_max = 2 },
				{ itemstring = "vlf_farming:carrot_item_gold", weight = 200, amount_min = 1, amount_max = 2 },
				{ itemstring = "vlf_books:book", weight = 1, func = function(stack, pr)	vlf_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "vlf_books:book", weight = 1, func = function(stack, pr)	vlf_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "vlf_bows:crossbow", weight = 200, func = function(stack, pr) vlf_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "vlf_tools:axe_iron", weight = 200, func = function(stack, pr) vlf_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "vlf_armor:chestplate_iron", weight = 200, func = function(stack, pr) vlf_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "vlf_tools:axe_diamond", weight = 100, func = function(stack, pr) vlf_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "vlf_armor:chestplate_diamond", weight = 100, func = function(stack, pr) vlf_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },

			}
		},
		{
			stacks_min = 1,
			stacks_max = 3,
			items = {
				{ itemstring = "vlf_core:emerald", weight = 4, amount_min = 2, amount_max = 4 },
				{ itemstring = "vlf_bows:arrow", weight = 4, amount_min = 2, amount_max = 8 },
				--{ itemstring = "TODO:arrow_of_poision", weight = 4, amount_min = 2, amount_max = 8 },
				{ itemstring = "vlf_core:iron_ingot", weight = 3, amount_min = 1, amount_max = 4 },
				{ itemstring = "vlf_charges:wind_charge", weight = 3, amount_min = 1, amount_max = 3 },
				{ itemstring = "vlf_honey:honey_bottle", weight = 3, amount_min = 1, amount_max = 2 },
				--{ itemstring = "TODO:ominous_bottle", weight = 2, amount_min = 1, amount_max = 2 },
				{ itemstring = "vlf_charges:wind_charge", weight = 1, amount_min = 4, amount_max = 12 },
				{ itemstring = "vlf_core:diamond", weight = 1, amount_min = 1, amount_max = 2 },
			},
		},
		{
			stacks_min = 1,
			stacks_max = 1,
			items = {
				{ itemstring = "vlf_core:apple_gold", weight = 4, amount_min = 1, amount_max = 2 },
				--{ itemstring = "TODO:vlf_armor:bolt", weight = 3, func = function(stack, pr) vlf_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "vlf_jukebox:record_8", weight = 2 },
				--{ itemstring = "TODO:vlf_banners:pattern_guster", weight = 2 },
				--{ itemstring = "TODO:trident", weight = 1 },
			}
		}
}
})
