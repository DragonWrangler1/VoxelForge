local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

vlf_potions = {}

-- duration effects of redstone are a factor of 8/3
-- duration effects of glowstone are a time factor of 1/2
-- splash potion duration effects are reduced by a factor of 3/4

vlf_potions.II_FACTOR = 2
vlf_potions.PLUS_FACTOR = 8/3

vlf_potions.DURATION = 180
vlf_potions.DURATION_PLUS = vlf_potions.DURATION * vlf_potions.PLUS_FACTOR
vlf_potions.DURATION_2 = vlf_potions.DURATION / vlf_potions.II_FACTOR

vlf_potions.INV_FACTOR = 0.50
vlf_potions.SPLASH_FACTOR = 0.75
vlf_potions.LINGERING_FACTOR = 0.25

dofile(modpath .. "/functions.lua")
dofile(modpath .. "/commands.lua")
dofile(modpath .. "/splash.lua")
dofile(modpath .. "/lingering.lua")
dofile(modpath .. "/tipped_arrow.lua")
dofile(modpath .. "/potions.lua")

minetest.register_craftitem("vlf_potions:fermented_spider_eye", {
	description = S("Fermented Spider Eye"),
	_doc_items_longdesc = S("Try different combinations to create potions."),
	wield_image = "vlf_potions_spider_eye_fermented.png",
	inventory_image = "vlf_potions_spider_eye_fermented.png",
	groups = { brewitem = 1, },
})

minetest.register_craft({
	type = "shapeless",
	output = "vlf_potions:fermented_spider_eye",
	recipe = { "vlf_mushrooms:mushroom_brown", "vlf_core:sugar", "vlf_mobitems:spider_eye" },
})

minetest.register_craftitem("vlf_potions:glass_bottle", {
	description = S("Glass Bottle"),
	_tt_help = S("Liquid container"),
	_doc_items_longdesc = S("A glass bottle is used as a container for liquids and can be used to collect water directly."),
	_doc_items_usagehelp = S("To collect water, use it on a cauldron with water (which removes a level of water) or any water source (which removes no water)."),
	inventory_image = "vlf_potions_potion_bottle.png",
	wield_image = "vlf_potions_potion_bottle.png",
	groups = {brewitem=1, empty_bottle = 1},
	liquids_pointable = true,
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "node" then
			local node = minetest.get_node(pointed_thing.under)
			local def = minetest.registered_nodes[node.name]

			local rc = vlf_util.call_on_rightclick(itemstack, placer, pointed_thing)
			if rc then return rc end

			-- Try to fill glass bottle with water
			local get_water = false
			--local from_liquid_source = false
			local river_water = false
			if def and def.groups and def.groups.water and def.liquidtype == "source" then
				-- Water source
				get_water = true
				--from_liquid_source = true
				river_water = node.name == "vlfx_core:river_water_source"
			-- Or reduce water level of cauldron by 1
			elseif string.sub(node.name, 1, 14) == "vlf_cauldrons:" then
				local pname = placer:get_player_name()
				if minetest.is_protected(pointed_thing.under, pname) then
					minetest.record_protection_violation(pointed_thing.under, pname)
					return itemstack
				end
				if node.name == "vlf_cauldrons:cauldron_3" then
					get_water = true
					minetest.swap_node(pointed_thing.under, {name="vlf_cauldrons:cauldron_2"})
				elseif node.name == "vlf_cauldrons:cauldron_2" then
					get_water = true
					minetest.swap_node(pointed_thing.under, {name="vlf_cauldrons:cauldron_1"})
				elseif node.name == "vlf_cauldrons:cauldron_1" then
					get_water = true
					minetest.swap_node(pointed_thing.under, {name="vlf_cauldrons:cauldron"})
				elseif node.name == "vlf_cauldrons:cauldron_3r" then
					get_water = true
					river_water = true
					minetest.swap_node(pointed_thing.under, {name="vlf_cauldrons:cauldron_2r"})
				elseif node.name == "vlf_cauldrons:cauldron_2r" then
					get_water = true
					river_water = true
					minetest.swap_node(pointed_thing.under, {name="vlf_cauldrons:cauldron_1r"})
				elseif node.name == "vlf_cauldrons:cauldron_1r" then
					get_water = true
					river_water = true
					minetest.swap_node(pointed_thing.under, {name="vlf_cauldrons:cauldron"})
				end
			end
			if get_water then
				local water_bottle
				if river_water then
					water_bottle = ItemStack("vlf_potions:river_water")
				else
					water_bottle = ItemStack("vlf_potions:water")
				end
				-- Replace with water bottle, if possible, otherwise
				-- place the water potion at a place where's space
				local inv = placer:get_inventory()
				minetest.sound_play("vlf_potions_bottle_fill", {pos=pointed_thing.under, gain=0.5, max_hear_range=16}, true)
				if minetest.is_creative_enabled(placer:get_player_name()) then
					-- Don't replace empty bottle in creative for convenience reasons
					if not inv:contains_item("main", water_bottle) then
						inv:add_item("main", water_bottle)
					end
				elseif itemstack:get_count() == 1 then
					return water_bottle
				else
					if inv:room_for_item("main", water_bottle) then
						inv:add_item("main", water_bottle)
					else
						minetest.add_item(placer:get_pos(), water_bottle)
					end
					itemstack:take_item()
				end
			end
		end
		return itemstack
	end,
})

minetest.register_craft( {
	output = "vlf_potions:glass_bottle 3",
	recipe = {
		{ "vlf_core:glass", "", "vlf_core:glass" },
		{ "", "vlf_core:glass", "" }
	}
})

-- Template function for creating images of filled potions
-- - colorstring must be a ColorString of form “#RRGGBB”, e.g. “#0000FF” for blue.
-- - opacity is optional opacity from 0-255 (default: 127)
local function potion_image(colorstring, opacity)
	if not opacity then
		opacity = 127
	end
	return "vlf_potions_potion_overlay.png^[colorize:"..colorstring..":"..tostring(opacity).."^vlf_potions_potion_bottle.png"
end



-- Cauldron fill up rules:
-- Adding any water increases the water level by 1, preserving the current water type
local cauldron_levels = {
	-- start = { add water, add river water }
	{ "",    "_1",  "_1r" },
	{ "_1",  "_2",  "_2" },
	{ "_2",  "_3",  "_3" },
	{ "_1r", "_2r",  "_2r" },
	{ "_2r", "_3r", "_3r" },
}
local fill_cauldron = function(cauldron, water_type)
	local base = "vlf_cauldrons:cauldron"
	for i=1, #cauldron_levels do
		if cauldron == base .. cauldron_levels[i][1] then
			if water_type == "vlfx_core:river_water_source" then
				return base .. cauldron_levels[i][3]
			else
				return base .. cauldron_levels[i][2]
			end
		end
	end
end

-- function to set node and empty water bottle (used for cauldrons and mud)
local function set_node_empty_bottle(itemstack, placer, pointed_thing, newitemstring)
	local pname = placer:get_player_name()
	if minetest.is_protected(pointed_thing.under, pname) then
		minetest.record_protection_violation(pointed_thing.under, pname)
		return itemstack
	end

	-- set the node to `itemstring`
	minetest.set_node(pointed_thing.under, {name=newitemstring})

	-- play sound
	minetest.sound_play("vlf_potions_bottle_pour", {pos=pointed_thing.under, gain=0.5, max_hear_range=16}, true)

	if minetest.is_creative_enabled(placer:get_player_name()) then
		return itemstack
	else
		return "vlf_potions:glass_bottle"
	end
end

-- used for water bottles and river water bottles
local function dispense_water_bottle(stack, pos, droppos)
	local node = minetest.get_node(droppos)
	if node.name == "vlf_core:dirt" or node.name == "vlf_core:coarse_dirt" then
		-- convert dirt/coarse dirt to mud
		minetest.set_node(droppos, {name = "vlf_mud:mud"})
		minetest.sound_play("vlf_potions_bottle_pour", {pos=droppos, gain=0.5, max_hear_range=16}, true)
		return ItemStack("vlf_potions:glass_bottle")

	elseif node.name == "vlf_mud:mud" then
		-- dont dispense into mud
		return stack
	end
end

-- on_place function for `vlf_potions:water` and `vlf_potions:river_water`

local function water_bottle_on_place(itemstack, placer, pointed_thing)
	if pointed_thing.type == "node" then
		local node = minetest.get_node(pointed_thing.under)

		local rc = vlf_util.call_on_rightclick(itemstack, placer, pointed_thing)
		if rc then return rc end

		local cauldron = nil
		if itemstack:get_name() == "vlf_potions:water" then -- regular water
			cauldron = fill_cauldron(node.name, "vlf_core:water_source")
		elseif itemstack:get_name() == "vlf_potions:river_water" then -- river water
			cauldron = fill_cauldron(node.name, "vlfx_core:river_water_source")
		end


		if cauldron then
			set_node_empty_bottle(itemstack, placer, pointed_thing, cauldron)
		elseif node.name == "vlf_core:dirt" or node.name == "vlf_core:coarse_dirt" then
			set_node_empty_bottle(itemstack, placer, pointed_thing, "vlf_mud:mud")
		end
	end

	-- Drink the water by default
	return minetest.do_item_eat(0, "vlf_potions:glass_bottle", itemstack, placer, pointed_thing)
end

-- Itemstring of potions is “vlf_potions:<NBT Potion Tag>”

minetest.register_craftitem("vlf_potions:water", {
	description = S("Water Bottle"),
	_tt_help = S("No effect"),
	_doc_items_longdesc = S("Water bottles can be used to fill cauldrons. Drinking water has no effect."),
	_doc_items_usagehelp = S("Use the “Place” key to drink. Place this item on a cauldron to pour the water into the cauldron."),
	stack_max = 1,
	inventory_image = potion_image("#0022FF"),
	wield_image = potion_image("#0022FF"),
	groups = {brewitem=1, food=3, can_eat_when_full=1, water_bottle=1},
	on_place = water_bottle_on_place,
	_on_dispense = dispense_water_bottle,
	_dispense_into_walkable = true,
	on_secondary_use = minetest.item_eat(0, "vlf_potions:glass_bottle"),
})


minetest.register_craftitem("vlf_potions:river_water", {
	description = S("River Water Bottle"),
	_tt_help = S("No effect"),
	_doc_items_longdesc = S("River water bottles can be used to fill cauldrons. Drinking it has no effect."),
	_doc_items_usagehelp = S("Use the “Place” key to drink. Place this item on a cauldron to pour the river water into the cauldron."),

	stack_max = 1,
	inventory_image = potion_image("#0044FF"),
	wield_image = potion_image("#0044FF"),
	groups = {brewitem=1, food=3, can_eat_when_full=1, water_bottle=1},
	on_place = water_bottle_on_place,
	_on_dispense = dispense_water_bottle,
	_dispense_into_walkable = true,
	on_secondary_use = minetest.item_eat(0, "vlf_potions:glass_bottle"),

})

-- Hurt mobs
local function water_splash(obj, damage)
	if not obj then
		return
	end
	if not damage or (damage > 0 and damage < 1) then
		damage = 1
	end
	-- Damage mobs that are vulnerable to water
	local lua = obj:get_luaentity()
	if lua and lua.is_mob then
		obj:punch(obj, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {water_vulnerable=damage},
		}, nil)
	end
end

vlf_potions.register_splash("water", S("Splash Water Bottle"), "#0022FF", {
	tt=S("Extinguishes fire and hurts some mobs"),
	longdesc=S("A throwable water bottle that will shatter on impact, where it extinguishes nearby fire and hurts mobs that are vulnerable to water."),
	no_effect=true,
	potion_fun=water_splash,
	effect=1
})
vlf_potions.register_lingering("water", S("Lingering Water Bottle"), "#0022FF", {
	tt=S("Extinguishes fire and hurts some mobs"),
	longdesc=S("A throwable water bottle that will shatter on impact, where it creates a cloud of water vapor that lingers on the ground for a while. This cloud extinguishes fire and hurts mobs that are vulnerable to water."),
	no_effect=true,
	potion_fun=water_splash,
	effect=1
})

minetest.register_craftitem("vlf_potions:speckled_melon", {
	description = S("Glistering Melon"),
	_doc_items_longdesc = S("This shiny melon is full of tiny gold nuggets and would be nice in an item frame. It isn't edible and not useful for anything else."),
	groups = { brewitem = 1, },
	inventory_image = "vlf_potions_melon_speckled.png",
})

minetest.register_craft({
	output = "vlf_potions:speckled_melon",
	recipe = {
		{"vlf_core:gold_nugget", "vlf_core:gold_nugget", "vlf_core:gold_nugget"},
		{"vlf_core:gold_nugget", "vlf_farming:melon_item", "vlf_core:gold_nugget"},
		{"vlf_core:gold_nugget", "vlf_core:gold_nugget", "vlf_core:gold_nugget"},
	}
})


local water_table = {
	["vlf_nether:nether_wart_item"] = "vlf_potions:awkward",
	-- ["vlf_potions:fermented_spider_eye"] = "vlf_potions:weakness",
	["vlf_potions:speckled_melon"] = "vlf_potions:mundane",
	["vlf_core:sugar"] = "vlf_potions:mundane",
	["vlf_mobitems:magma_cream"] = "vlf_potions:mundane",
	["vlf_mobitems:blaze_powder"] = "vlf_potions:mundane",
	["mesecons:wire_00000000_off"] = "vlf_potions:mundane",
	["vlf_mobitems:ghast_tear"] = "vlf_potions:mundane",
	["vlf_mobitems:spider_eye"] = "vlf_potions:mundane",
	["vlf_mobitems:rabbit_foot"] = "vlf_potions:mundane",
	["vlf_nether:glowstone_dust"] = "vlf_potions:thick",
	["vlf_mobitems:gunpowder"] = "vlf_potions:water_splash"
}

local awkward_table = {
	["vlf_potions:speckled_melon"] = "vlf_potions:healing",
	["vlf_farming:carrot_item_gold"] = "vlf_potions:night_vision",
	["vlf_core:sugar"] = "vlf_potions:swiftness",
	["vlf_mobitems:magma_cream"] = "vlf_potions:fire_resistance",
	-- ["vlf_mobitems:blaze_powder"] = "vlf_potions:strength",
	["vlf_fishing:pufferfish_raw"] = "vlf_potions:water_breathing",
	["vlf_mobitems:ghast_tear"] = "vlf_potions:regeneration",
	["vlf_mobitems:spider_eye"] = "vlf_potions:poison",
	["vlf_mobitems:rabbit_foot"] = "vlf_potions:leaping",
}

local output_table = {
	["vlf_potions:river_water"] = water_table,
	["vlf_potions:water"] = water_table,
	["vlf_potions:awkward"] = awkward_table,
}

minetest.register_on_mods_loaded(function()
	for k, _ in pairs(table.merge(awkward_table, water_table)) do
		local def = minetest.registered_items[k]
		if def then
			minetest.override_item(k, {
				groups = table.merge(def.groups, {brewing_ingredient = 1})
			})
		end
	end
end)


local enhancement_table = {}
local extension_table = {}
local potions = {}

for i, potion in ipairs({"healing","harming","swiftness","slowness",
	 "leaping","poison","regeneration","invisibility","fire_resistance",
	 -- "weakness","strength",
	 "water_breathing","night_vision", "withering"}) do

	table.insert(potions, potion)

	if potion ~= "invisibility" and potion ~= "night_vision" and potion ~= "weakness" and potion ~= "water_breathing" and potion ~= "fire_resistance" then
		enhancement_table["vlf_potions:"..potion] = "vlf_potions:"..potion.."_2"
		enhancement_table["vlf_potions:"..potion.."_splash"] = "vlf_potions:"..potion.."_2_splash"
		table.insert(potions, potion.."_2")
	end

	if potion ~= "healing" and potion ~= "harming" then
		extension_table["vlf_potions:"..potion.."_splash"] = "vlf_potions:"..potion.."_plus_splash"
		extension_table["vlf_potions:"..potion] = "vlf_potions:"..potion.."_plus"
		table.insert(potions, potion.."_plus")
	end

end

for i, potion in ipairs({"awkward", "mundane", "thick", "water"}) do
	table.insert(potions, potion)
end


local inversion_table = {
	["vlf_potions:healing"] = "vlf_potions:harming",
	["vlf_potions:healing_2"] = "vlf_potions:harming_2",
	["vlf_potions:swiftness"] = "vlf_potions:slowness",
	["vlf_potions:swiftness_plus"] = "vlf_potions:slowness_plus",
	["vlf_potions:leaping"] = "vlf_potions:slowness",
	["vlf_potions:leaping_plus"] = "vlf_potions:slowness_plus",
	["vlf_potions:night_vision"] = "vlf_potions:invisibility",
	["vlf_potions:night_vision_plus"] = "vlf_potions:invisibility_plus",
	["vlf_potions:poison"] = "vlf_potions:harming",
	["vlf_potions:poison_2"] = "vlf_potions:harming_2",
	["vlf_potions:healing_splash"] = "vlf_potions:harming_splash",
	["vlf_potions:healing_2_splash"] = "vlf_potions:harming_2_splash",
	["vlf_potions:swiftness_splash"] = "vlf_potions:slowness_splash",
	["vlf_potions:swiftness_plus_splash"] = "vlf_potions:slowness_plus_splash",
	["vlf_potions:leaping_splash"] = "vlf_potions:slowness_splash",
	["vlf_potions:leaping_plus_splash"] = "vlf_potions:slowness_plus_splash",
	["vlf_potions:night_vision_splash"] = "vlf_potions:invisibility_splash",
	["vlf_potions:night_vision_plus_splash"] = "vlf_potions:invisibility_plus_splash",
	["vlf_potions:poison_splash"] = "vlf_potions:harming_splash",
	["vlf_potions:poison_2_splash"] = "vlf_potions:harming_2_splash",
}


local splash_table = {}
local lingering_table = {}

for i, potion in ipairs(potions) do
	splash_table["vlf_potions:"..potion] = "vlf_potions:"..potion.."_splash"
	lingering_table["vlf_potions:"..potion.."_splash"] = "vlf_potions:"..potion.."_lingering"
end


local mod_table = {
	["mesecons:wire_00000000_off"] = extension_table,
	["vlf_potions:fermented_spider_eye"] = inversion_table,
	["vlf_nether:glowstone_dust"] = enhancement_table,
	["vlf_mobitems:gunpowder"] = splash_table,
	["vlf_potions:dragon_breath"] = lingering_table,
}

-- Compare two ingredients for compatable alchemy
function vlf_potions.get_alchemy(ingr, pot)
	if output_table[pot] then

		local brew_table = output_table[pot]

		if brew_table[ingr] then
			return brew_table[ingr]
		end
	end

	if mod_table[ingr] then

		local brew_table = mod_table[ingr]

		if brew_table[pot] then
			return brew_table[pot]
		end

	end

	return false
end

vlf_mobs.effect_functions["poison"] = vlf_potions.poison_func
vlf_mobs.effect_functions["regeneration"] = vlf_potions.regeneration_func
vlf_mobs.effect_functions["invisibility"] = vlf_potions.invisiblility_func
vlf_mobs.effect_functions["fire_resistance"] = vlf_potions.fire_resistance_func
vlf_mobs.effect_functions["night_vision"] = vlf_potions.night_vision_func
vlf_mobs.effect_functions["water_breathing"] = vlf_potions.water_breathing_func
vlf_mobs.effect_functions["leaping"] = vlf_potions.leaping_func
vlf_mobs.effect_functions["swiftness"] = vlf_potions.swiftness_func
vlf_mobs.effect_functions["heal"] = vlf_potions.healing_func
vlf_mobs.effect_functions["bad_omen"] = vlf_potions.bad_omen_func
vlf_mobs.effect_functions["withering"] = vlf_potions.withering_func

-- give withering to players in a wither rose
local etime = 0
minetest.register_globalstep(function(dtime)
	etime = dtime + etime
	if etime < 0.5 then return end
	etime = 0
	for _,pl in pairs(minetest.get_connected_players()) do
		local npos = vector.offset(pl:get_pos(), 0, 0.2, 0)
		local n = minetest.get_node(npos)
		if n.name == "vlf_flowers:wither_rose" then vlf_potions.withering_func(pl, 1, 2) end
	end
end)

vlf_wip.register_wip_item("vlf_potions:night_vision")
vlf_wip.register_wip_item("vlf_potions:night_vision_plus")
vlf_wip.register_wip_item("vlf_potions:night_vision_splash")
vlf_wip.register_wip_item("vlf_potions:night_vision_plus_splash")
vlf_wip.register_wip_item("vlf_potions:night_vision_lingering")
vlf_wip.register_wip_item("vlf_potions:night_vision_plus_lingering")
vlf_wip.register_wip_item("vlf_potions:night_vision_arrow")
vlf_wip.register_wip_item("vlf_potions:night_vision_plus_arrow")
