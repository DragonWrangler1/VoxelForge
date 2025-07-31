local crafting_tables = {}

-- Function to check recipe and update crafted item display
local function check_and_update_recipe(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	-- Update grid display first
	update_grid_display(pos, inv)

	-- Remove existing crafted item display
	for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 2)) do
		local ent = obj:get_luaentity()
		if ent and ent.name == "interactive_crafting_table:crafted_item_display" then
			obj:remove()
		end
	end

	-- Check if there's a valid recipe
	local crafted_item = try_craft(inv)
	if not crafted_item:is_empty() then
		-- Display the crafted item on top of the table
		local display_pos = vector.add(pos, {x=0, y=1.2, z=0})
		-- Pass the full stack string as staticdata, entity will extract the item name
		local ent = minetest.add_entity(display_pos, "interactive_crafting_table:crafted_item_display", crafted_item:to_string())
		meta:set_string("crafted_item", crafted_item:to_string())
		meta:set_string("state", "ready_to_craft")
	else
		meta:set_string("crafted_item", "")
		if meta:get_string("state") ~= "idle" then
			meta:set_string("state", "editing")
		end
	end
end

minetest.register_node("interactive_crafting_table:crafting_table", {
	description = "Interactive Crafting Table",
	tiles = {"table_top.png", "table_bottom.png", "table_side.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 2, voxelforge_material = 1},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("grid", 9)
		meta:set_int("selected_slot", 0)
		meta:set_string("state", "idle")
		-- Initialize empty grid display
		update_grid_display(pos, inv)
	end,

	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local selected = meta:get_int("selected_slot")
		local state = meta:get_string("state")

		if state == "ready_to_craft" then
			-- Start crafting process
			meta:set_string("state", "crafting")
			meta:set_int("hits", 0)
			-- Don't spawn vertical entities - items remain flat on the table
			minetest.chat_send_player(clicker:get_player_name(), "Use the crafting hammer to complete the recipe!")
		elseif state ~= "crafting" then
			selected = (selected + 1) % 10
			meta:set_int("selected_slot", selected)
			if selected == 0 then
				minetest.chat_send_player(clicker:get_player_name(), "Selected slot: 0 (View only - no editing)")
			else
				minetest.chat_send_player(clicker:get_player_name(), "Selected slot: " .. selected)
			end
		end
	end,

on_punch = function(pos, node, puncher, pointed_thing)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local selected = meta:get_int("selected_slot")
	local state = meta:get_string("state")

	local wield = puncher:get_wielded_item()
	local slot_stack = inv:get_stack("grid", selected)

	if wield:get_name() == "interactive_crafting_table:hammer" and state == "crafting" then
		-- crafting hammer hit
		local hits = meta:get_int("hits") + 1
		meta:set_int("hits", hits)
		make_items_bounce(pos)
		if hits >= 5 then
			spawn_particles(pos)
			drop_crafted_item(pos, meta:get_string("crafted_item"))

			-- Clear the crafting grid
			local inv = meta:get_inventory()
			inv:set_list("grid", {})

			-- Remove crafted item display and grid displays
			for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 2)) do
				local ent = obj:get_luaentity()
				if ent and (ent.name == "interactive_crafting_table:crafted_item_display" or
						   ent.name == "interactive_crafting_table:grid_item_display") then
					obj:remove()
				end
			end

			meta:set_string("state", "idle")
			meta:set_int("hits", 0)
			meta:set_string("crafted_item", "")
		end

	elseif state ~= "crafting" and selected == 0 then
		-- Slot 0 is selected - allow normal digging using voxelforge_digging system
		-- Return false to let the global voxelforge_digging callback handle this
		return false

	elseif state ~= "crafting" and selected > 0 then
		if slot_stack:is_empty() and not wield:is_empty() then
			-- Place one item into slot
			local taken = wield:take_item(1)
			inv:set_stack("grid", selected, taken)
			puncher:set_wielded_item(wield)
			meta:set_string("state", "editing")
			-- Check for valid recipe and update display
			check_and_update_recipe(pos)

		elseif not slot_stack:is_empty() and wield:is_empty() then
			-- Take item from slot
			puncher:set_wielded_item(slot_stack)
			inv:set_stack("grid", selected, ItemStack(""))
			meta:set_string("state", "editing")
			-- Check for valid recipe and update display
			check_and_update_recipe(pos)

		elseif not slot_stack:is_empty() and not wield:is_empty() then
			-- Optional: swap, do nothing, or add to stack
			-- Here we do nothing for simplicity
			minetest.chat_send_player(puncher:get_player_name(), "Slot occupied.")
		end
	end
end,

	on_dig = function(pos, node, digger)
		local meta = minetest.get_meta(pos)
		if meta:get_string("state") == "idle" then
			-- Remove any displays
			for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 2)) do
				local ent = obj:get_luaentity()
				if ent and (ent.name == "interactive_crafting_table:crafted_item_display" or
						   ent.name == "interactive_crafting_table:grid_item_display") then
					obj:remove()
				end
			end
			minetest.node_dig(pos, node, digger)
		end
	end,
})
