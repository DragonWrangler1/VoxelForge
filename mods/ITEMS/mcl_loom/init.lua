local S = minetest.get_translator(minetest.get_current_modname())
local C = minetest.colorize
local F = minetest.formspec_escape

local dyerecipes = {}
local preview_item_prefix = "mcl_banners:banner_preview_"

for name,pattern in pairs(mcl_banners.patterns) do
	local dyes = 0
	for i=1,3 do for j = 1,3 do
		if pattern[i] and pattern[i][j] == "group:dye" then
			dyes = dyes + 1
			if table.indexof(dyerecipes,name) == -1 and pattern.type ~= "shapeless" then
				table.insert(dyerecipes,name) break
			end
		end
	end	end
end

local function drop_items(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local bstack = inv:get_stack("banner", 1)
	local dstack = inv:get_stack("dye", 1)
	if not bstack:is_empty() then
		minetest.add_item(pos, bstack)
	end
	if not dstack:is_empty() then
		minetest.add_item(pos, dstack)
	end
end

local function show_loom_formspec(pos)
	local patterns = {}
	local count = 0
	if pos then
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local color
		local def = minetest.registered_items[inv:get_stack("dye",1):get_name()]
		local pitem = inv:get_stack("pattern",1):get_name()
		local pdef = minetest.registered_items[pitem]
		if def and def.groups.dye and def._color then color = def._color end
		local x_len = 0.1
		local y_len = 0.1
		if not inv:is_empty("banner") then
			if color and pdef and pdef._pattern then
				local it = preview_item_prefix .. pdef._pattern .. "_" .. color
				local name = preview_item_prefix .. pdef._pattern .. "-" .. color
				table.insert(patterns,string.format("item_image_button[%f,%f;%f,%f;%s;%s;%s]",0.1,0.1,1,1, it, "item_button_"..name, ""))
			elseif dyerecipes and color then
				for k,v in pairs(dyerecipes) do
					if x_len > 5 then
						y_len = y_len + 1
						x_len = 0.1
					end
					local it = preview_item_prefix .. v .. "_" .. color
					local name = preview_item_prefix .. v .. "-" .. color
					table.insert(patterns,string.format("item_image_button[%f,%f;%f,%f;%s;%s;%s]",x_len,y_len,1,1, it, "item_button_"..name, ""))
					x_len = x_len + 1
					count = count + 1
				end
			end
		end
	end

	local formspec =
	"formspec_version[4]"..
	"size[11.75,10.425]"..
	"label[0.375,0.375;" .. F(C(mcl_formspec.label_color, S("Loom"))) .. "]"..

		--mcl_formspec.get_itemslot_bg_v4(3.5, 0.75, 1, 1),
		--"list[context;src;3.5,0.75;1,1;]",

	mcl_formspec.get_itemslot_bg_v4(0.5,1,1,1,0)..
	mcl_formspec.get_itemslot_bg_v4(0.5,1,1,1,0,"mcl_loom_itemslot_bg_banner.png")..
	"list[context;banner;0.5,1;1,1;]"..
	mcl_formspec.get_itemslot_bg_v4(1.75,1,1,1)..
	mcl_formspec.get_itemslot_bg_v4(1.75,1,1,1,0,"mcl_loom_itemslot_bg_dye.png")..
	"list[context;dye;1.75,1;1,1;]"..
	mcl_formspec.get_itemslot_bg_v4(0.5,2.25,1,1)..
	mcl_formspec.get_itemslot_bg_v4(0.5,2.25,1,1,0,"mcl_loom_itemslot_bg_pattern.png")..
	"list[context;pattern;0.5,2.25;1,1;]"..

	"box[3.275,0.75;5.2,3.5;"..mcl_colors.DARK_GRAY.."]"..
	"scroll_container[3.275,0.75;5.5,3.5;pattern_scroll;vertical;0.1]"..
	table.concat(patterns)..
	"scroll_container_end[]"..
	"scrollbaroptions[arrows=show;thumbsize=30;min=0;max="..(count + 5).."]"..
	"scrollbar[8.5,0.75;0.4,3.5;vertical;pattern_scroll;]"..

	mcl_formspec.get_itemslot_bg_v4(9.5,1.5,1,1)..
	"list[context;output;9.5,1.5;1,1;]"..

	"label[0.375,4.7;" .. F(C(mcl_formspec.label_color, S("Inventory"))) .. "]"..
	mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3)..
	"list[current_player;main;0.375,5.1;9,3;9]"..

	mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1)..
	"list[current_player;main;0.375,9.05;9,1;]"..

	"listring[context;output]"..
	"listring[current_player;main]"..
	"listring[context;banner]"..
	"listring[current_player;main]"..
	"listring[context;dye]"..
	"listring[current_player;main]"..
	"listring[context;pattern]"..
	"listring[current_player;main]"
	return formspec
end

local function update_slots(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", show_loom_formspec(pos))
end

local function create_banner(stack,pattern,color)
	local im = stack:get_meta()
	local layers = {}
	local old_layers = im:get_string("layers")
	if old_layers ~= "" then
		layers = minetest.deserialize(old_layers)
	end
	table.insert(layers,{
		pattern = pattern,
		color = "unicolor_"..mcl_dyes.colors[color].unicolor
	})
	im:set_string("description", mcl_banners.make_advanced_banner_description(stack:get_definition().description, layers))
	im:set_string("layers", minetest.serialize(layers))
	stack:set_count(1)
	return stack
end

local function allow_put(pos, listname, index, stack, player)
	local name = player:get_player_name()
	if minetest.is_protected(pos, name) then
		minetest.record_protection_violation(pos, name)
		return 0
	elseif listname == "output" then return 0
	elseif listname == "banner" and minetest.get_item_group(stack:get_name(),"banner") == 0 then return 0
	elseif listname == "dye" and minetest.get_item_group(stack:get_name(),"dye") == 0 then return 0
	elseif listname == "pattern" and minetest.get_item_group(stack:get_name(),"banner_pattern") == 0 then return 0
	else
		return stack:get_count()
	end
end

minetest.register_node("mcl_loom:loom", {
	description = S("Loom"),
	_tt_help = S("Used to create banner designs"),
	_doc_items_longdesc = S("This is the shepherd villager's work station. It is used to create banner designs."),
	tiles = {
		"loom_top.png", "loom_bottom.png",
		"loom_side.png", "loom_side.png",
		"loom_side.png", "loom_front.png"
	},
	paramtype2 = "facedir",
	groups = { axey = 2, handy = 1, deco_block = 1, material_wood = 1, flammable = 1 },
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_blast_resistance = 2.5,
	_mcl_hardness = 2.5,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("banner", 1)
		inv:set_size("dye", 1)
		inv:set_size("pattern", 1)
		inv:set_size("output", 1)
		local form = show_loom_formspec(pos)
		meta:set_string("formspec", form)
	end,
	on_destruct = drop_items,
	on_rightclick = function(pos, node, player, itemstack)
		if not player:get_player_control().sneak then
			update_slots(pos)
		end
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local sender_name = sender:get_player_name()
		if minetest.is_protected(pos, sender_name) then
			minetest.record_protection_violation(pos, sender_name)
			return
		end

		if fields then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			for k,v in pairs(fields) do
				if tostring(k) and k:find("^item_button_"..preview_item_prefix) and
				not inv:is_empty("banner") and not inv:is_empty("dye") and inv:is_empty("output") then
					local str = k:gsub("^item_button_","")
					str = str:gsub("^"..preview_item_prefix,"")
					str = str:split("-")
					local pattern = str[1]
					local cdef = minetest.registered_items[inv:get_stack("dye",1):get_name()]
					if not inv:is_empty("pattern") then
						local pdef = minetest.registered_items[inv:get_stack("pattern",1):get_name()]
						pattern = pdef._pattern
						local pattern = inv:get_stack("pattern",1)
						pattern:take_item()
						inv:set_stack("pattern", 1, pattern)
					elseif not mcl_dyes.colors[cdef._color] or table.indexof(dyerecipes,pattern) == -1 then
						pattern = nil
					end
					if pattern then
						local banner = inv:get_stack("banner",1)
						local dye = inv:get_stack("dye",1)
						dye:take_item()
						local cbanner = banner:take_item()
						inv:set_stack("dye", 1, dye)
						inv:set_stack("banner", 1, banner)
						inv:set_stack("output", 1, create_banner(cbanner,pattern,cdef._color))
					end
				end
			end
		end
		update_slots(pos)
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local inv = minetest.get_meta(pos):get_inventory()
		local stack = inv:get_stack(from_list,from_index)
		return allow_put(pos, to_list, to_index, stack, player)
	end,
	allow_metadata_inventory_put = allow_put,

	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		if from_list == "output" and to_list == "input" then
			local inv = meta:get_inventory()
			for i=1, inv:get_size("input") do
				if i ~= to_index then
					local istack = inv:get_stack("input", i)
					istack:set_count(math.max(0, istack:get_count() - count))
					inv:set_stack("input", i, istack)
				end
			end
		end
		update_slots(pos)
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		update_slots(pos)
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		update_slots(pos)
	end,
})


minetest.register_craft({
	output = "mcl_loom:loom",
	recipe = {
		{ "", "", "" },
		{ "mcl_mobitems:string", "mcl_mobitems:string", "" },
		{ "group:wood", "group:wood", "" },
	}
})
