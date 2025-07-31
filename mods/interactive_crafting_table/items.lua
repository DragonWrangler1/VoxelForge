
minetest.register_tool("interactive_crafting_table:hammer", {
	description = "Crafting Hammer",
	inventory_image = "hammer.png",
	tool_capabilities = {
		full_punch_interval = 0.5,
		max_drop_level=0,
		groupcaps={
			cracky = {times={[1]=3.00, [2]=1.60, [3]=0.40}, uses=30, maxlevel=1}
		},
		damage_groups = {fleshy=2},
	},
})
