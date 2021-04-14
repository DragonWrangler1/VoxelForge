function mcl_armor.play_equip_sound(stack, obj, pos, unequip)
	local def = stack:get_definition()
	local estr = "equip"
	if unequip then
		estr = "unequip"
	end
	local snd = def.sounds and def.sounds["_mcl_armor_" .. estr]
	if not snd then
		-- Fallback sound
		snd = { name = "mcl_armor_" .. estr .. "_generic" }
	end
	if snd then
		local dist = 8
		if pos then
			dist = 16
		end
		minetest.sound_play(snd, {object = obj, pos = pos, gain = 0.5, max_hear_distance = dist}, true)
	end
end

function mcl_armor.equip(itemstack, obj)
	local def = itemstack:get_definition()
	local element = mcl_armor.elements[def._mcl_armor_element or ""]
	local inv = mcl_util.get_inventory(obj)

	if element and inv then
		if inv:get_stack("armor", element.index):is_empty() then
			local equipping_item = itemstack:take_item()
			inv:set_stack("armor", element.index, equipping_item)
			if def._on_equip then
				def._on_equip(equipping_item)
			end
			mcl_armor.update(obj)
		end
	end

	return itemstack
end

function mcl_armor.equip_on_use(itemstack, player, pointed_thing)
	if not player or not player:is_player() then
		return itemstack
	end

	local new_stack = mcl_util.call_on_rightclick(itemstack, player, pointed_thing)
	if new_stack then
		return new_stack
	end

	return mcl_armor.equip(itemstack, player)
end

function mcl_armor.register_set(def)
	local modname = minetest.get_current_modname()
	local S = minetest.get_translator(modname)
	local descriptions = def.descriptions or {}
	local groups = def.groups or {}
	for name, element in pairs(mcl_armor.elements) do
		local itemname = element.name .. "_" .. def.name
		local itemstring = modname .. ":" .. itemname

		local groups = table.copy(groups)
		groups["armor_" .. name] = 1
		groups["combat_armor_" .. name] = 1
		groups.armor = 1
		groups.combat_armor = 1
		groups.mcl_armor_points = def.points[name]
		groups.mcl_armor_toughness = def.toughness
		groups.mcl_armor_uses = math.floor(def.durability * element.durability) + 1
		groups.enchantability = def.enchantability

		minetest.register_tool(itemstring, {
			description = S(def.description .. " " .. (descriptions[name] or element.description)),
			_doc_items_longdesc = mcl_armor.longdesc,
			_doc_items_usagehelp = mcl_armor.usage,
			inventory_image = modname .. "_inv_" .. itemname .. ".png",
			_repair_material = def.repair_material or def.craft_material,
			groups = groups,
			sounds = {
				_mcl_armor_equip = def.sound_equip or modname .. "_equip_" .. def.name,
				_mcl_armor_unequip = def.sound_unequip or modname .. "_unequip_" .. def.name,
			},
			on_place = mcl_armor.equip_on_use,
			on_secondary_use = mcl_armor.equip_on_use,
			_on_equip = def.on_equip,
			_on_unequip = def.on_unequip,
			_mcl_armor_element = name,
			_mcl_armor_texture = modname .. "_" .. itemname .. ".png",
			_mcl_armor_preview = modname .. "_" .. itemname .. "_preview.png",
		})

		if def.craft_material then
			minetest.register_craft({
				output = itemstring,
				recipe = element.craft(def.craft_material),
			})
		end

		if def.cook_material then
			minetest.register_craft({
				type = "cooking",
				output = def.cook_material,
				recipe = itemstring,
				cooktime = 10,
			})
		end
	end
end

mcl_armor.protection_enchantments = {
	flags = {},
	types = {},
	wildcard = {},
}

function mcl_armor.register_protection_enchantment(def)
	local prot_def = {id = def.id, factor = def.factor}
	if def.damage_flag then
		local tbl = mcl_armor.protection_enchantments.flags[def.damage_flag] or {}
		table.insert(tbl, prot_def)
		mcl_armor.protection_enchantments.flags = tbl
	elseif def.damage_type then
		local tbl = mcl_armor.protection_enchantments.types[def.damage_type] or {}
		table.insert(tbl, prot_def)
		mcl_armor.protection_enchantments.types = tbl
	else
		table.insert(mcl_armor.protection_enchantments.wildcard, prot_def)
	end
	mcl_enchanting.enchantments[def.id] = {
		name = def.name,
		max_level = def.max_level or 4,
		primary = def.primary or {combat_armor = true},
		secondary = {},
		disallow = {},
		incompatible = def.incompatible or {},
		weight = def.weight or 5,
		description = def.description,
		curse = false,
		on_enchant = function() end,
		requires_tool = false,
		treasure = def.treasure or false,
		power_range_table = def.power_range_table,
		inv_combat_tab = true,
		inv_tool_tab = false,
	}
end

function mcl_armor.get_armor_points(obj)
	local points = 0
	local inv = mcl_util.get_inventory(obj)
	if inv then
		for i = 2, 5 do
			local itemstack = inv:get_stack("armor", i)
			if not itemstack:is_empty() then
				points = points + minetest.get_item_group(itemstack:get_name(), "mcl_armor_points")
			end
		end
	end
	return points
end

-- Returns a change factor for a mob's view_range for the given object
-- or nil, if there's no change. Certain armors (like mob heads) can
-- affect the view range of mobs.
function mcl_armor.get_mob_view_range_factor(obj, mob)
	local inv = mcl_util.get_inventory(obj)
	local factor
	if inv then
		for i = 2, 5 do
			local itemstack = inv:get_stack("armor", i)
			if not itemstack:is_empty() then
				local def = itemstack:get_definition()
				if def._mcl_armor_mob_range_mob == mob then
					if not factor then
						factor = def._mcl_armor_mob_range_factor
					elseif factor == 0 then
						return 0
					else
						factor = factor * def._mcl_armor_mob_range_factor
					end
				end
			end
		end
	end
	return factor
end

function mcl_armor.update(obj)
	local info = {points = 0}

	local inv = mcl_util.get_inventory(obj)

	if inv then
		for i = 2, 5 do
			local itemstack = inv:get_stack("armor", i)

			local itemname = itemstack:get_name()
			if minetest.registered_aliases[itemname] then
				itemname = minetest.registered_aliases[itemname]
			end

			if not itemstack:is_empty() then
				local def = itemstack:get_definition()

				if def._mcl_armor_texture then
					info.texture = "(" .. def._mcl_armor_texture .. ")" .. (info.texture and "^" .. info.texture or "")
				end

				if obj:is_player() and def._mcl_armor_preview then
					info.preview = "(player.png^[opacity:0^" .. def._mcl_armor_preview .. ")" .. (info.preview and "^" .. info.preview or "" )
				end

				info.points = info.points + minetest.get_item_group(itemname, "mcl_armor_points")
			end
		end
	end

	info.texture = info.texture or "blank.png"

	if obj:is_player() then
		info.preview = info.preview or "blank.png"

		mcl_armor.update_player(obj, info)
	else
		local luaentity = obj:get_luaentity()

		if luaentity.update_armor then
			luaentity:update_armor(info)
		end
	end
end

