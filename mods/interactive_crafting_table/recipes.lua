
local recipes = {
	{
		input = {"default:wood", "default:wood", "default:wood",
				 "", "", "",
				 "", "", ""},
		output = "default:chest"
	},
	{
		input = {"default:wood", "default:wood", "",
				 "default:wood", "default:wood", "",
				 "", "", ""},
		output = "default:wood 4"
	},
	{
		input = {"default:cobble", "default:cobble", "default:cobble",
				 "default:cobble", "", "default:cobble",
				 "default:cobble", "default:cobble", "default:cobble"},
		output = "default:furnace"
	},
	{
		input = {"default:stick", "", "",
				 "default:stick", "", "",
				 "default:wood", "", ""},
		output = "default:pick_wood"
	},
	{
		input = {"vlf_blocks:stick", "vlf_blocks:stick", "vlf_blocks:stick",
				 "vlf_blocks:stick", "vlf_blocks:stick", "vlf_blocks:stick",
				 "vlf_blocks:stick", "vlf_blocks:stick", "vlf_blocks:stick"},
		output = "vlf_blocks:stick_fence 3"
	}
}

function try_craft(inv)
	local grid = {}
	for i = 1, 9 do
		local stack = inv:get_stack("grid", i)
		grid[i] = stack:is_empty() and "" or stack:get_name()
	end

	for _, recipe in ipairs(recipes) do
		local match = true
		for i = 1, 9 do
			local recipe_item = recipe.input[i] or ""
			local grid_item = grid[i] or ""

			-- Both must be empty, or both must match exactly
			if recipe_item ~= grid_item then
				match = false
				break
			end
		end
		if match then
			return ItemStack(recipe.output)
		end
	end
	return ItemStack("")
end
