-- Tree Definitions
-- Register all the trees for VoxelForge

-- Oak Tree
vlf_trees.register_tree("oak", {
	description = "Oak",
	wood_description = "Oak Log",
	planks_description = "Oak Planks",
	leaves_description = "Oak Leaves",
	sapling_description = "Oak Sapling",

	-- Growth properties
	growth_time = 300, -- 5 minutes base
	growth_chance = 8, -- 1 in 8 chance per ABM cycle
	sapling_rarity = 20, -- 1 in 20 chance from leaves
})

-- Spruce Tree
vlf_trees.register_tree("spruce", {
	description = "Spruce",
	wood_description = "Spruce Log",
	planks_description = "Spruce Planks",
	leaves_description = "Spruce Leaves",
	sapling_description = "Spruce Sapling",

	-- Growth properties
	growth_time = 360, -- 6 minutes base
	growth_chance = 10, -- 1 in 10 chance per ABM cycle
	sapling_rarity = 20,
})

-- Birch Tree
vlf_trees.register_tree("birch", {
	description = "Birch",
	wood_description = "Birch Log",
	planks_description = "Birch Planks",
	leaves_description = "Birch Leaves",
	sapling_description = "Birch Sapling",

	-- Growth properties
	growth_time = 240, -- 4 minutes base (birch grows faster)
	growth_chance = 6, -- 1 in 6 chance per ABM cycle
	sapling_rarity = 20,
})

-- Jungle Tree
vlf_trees.register_tree("jungle", {
	description = "Jungle",
	wood_description = "Jungle Log",
	planks_description = "Jungle Planks",
	leaves_description = "Jungle Leaves",
	sapling_description = "Jungle Sapling",

	-- Growth properties
	growth_time = 480, -- 8 minutes base (jungle trees grow slower)
	growth_chance = 15, -- 1 in 15 chance per ABM cycle
	sapling_rarity = 40, -- Rarer sapling drops

	-- Custom tree generator for larger jungle trees
	tree_generator = function(pos, tree_name, tree_def)
		-- Check for more space (jungle trees are bigger)
		local space_needed = 12
		for y = 1, space_needed do
			local check_pos = {x = pos.x, y = pos.y + y, z = pos.z}
			local node = minetest.get_node(check_pos)
			if node.name ~= "air" then
				return false
			end
		end

		local wood_name = "vlf_trees:" .. tree_name .. "_log"
		local leaves_name = "vlf_trees:" .. tree_name .. "_leaves"

		-- Generate larger trunk
		local trunk_height = math.random(8, 12)
		for y = 0, trunk_height do
			minetest.set_node({x = pos.x, y = pos.y + y, z = pos.z}, {name = wood_name})
		end

		-- Generate larger leaves canopy
		local leaves_center = {x = pos.x, y = pos.y + trunk_height, z = pos.z}
		for dx = -3, 3 do
			for dy = -2, 3 do
				for dz = -3, 3 do
					local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
					if distance <= 3.5 and math.random() > 0.2 then
						local leaf_pos = {
							x = leaves_center.x + dx,
							y = leaves_center.y + dy,
							z = leaves_center.z + dz
						}
						local node = minetest.get_node(leaf_pos)
						if node.name == "air" then
							minetest.set_node(leaf_pos, {name = leaves_name})
						end
					end
				end
			end
		end

		return true
	end,
})

-- Acacia Tree
vlf_trees.register_tree("acacia", {
	description = "Acacia",
	wood_description = "Acacia Log",
	planks_description = "Acacia Planks",
	leaves_description = "Acacia Leaves",
	sapling_description = "Acacia Sapling",

	-- Growth properties
	growth_time = 420, -- 7 minutes base
	growth_chance = 12, -- 1 in 12 chance per ABM cycle
	sapling_rarity = 25,

	-- Custom tree generator for acacia's unique shape
	tree_generator = function(pos, tree_name, tree_def)
		local space_needed = 8
		for y = 1, space_needed do
			local check_pos = {x = pos.x, y = pos.y + y, z = pos.z}
			local node = minetest.get_node(check_pos)
			if node.name ~= "air" then
				return false
			end
		end

		local wood_name = "vlf_trees:" .. tree_name .. "_log"
		local leaves_name = "vlf_trees:" .. tree_name .. "_leaves"

		-- Generate shorter, branching trunk
		local trunk_height = math.random(4, 6)
		for y = 0, trunk_height do
			minetest.set_node({x = pos.x, y = pos.y + y, z = pos.z}, {name = wood_name})
		end

		-- Generate branches
		local branch_y = pos.y + trunk_height - 1
		local directions = {{1,0}, {-1,0}, {0,1}, {0,-1}}

		for _, dir in ipairs(directions) do
			if math.random() > 0.3 then -- 70% chance for each branch
				local branch_length = math.random(2, 4)
				for i = 1, branch_length do
					local branch_pos = {
						x = pos.x + dir[1] * i,
						y = branch_y + math.floor(i/2),
						z = pos.z + dir[2] * i
					}
					minetest.set_node(branch_pos, {name = wood_name})

					-- Add leaves around branch end
					if i >= branch_length - 1 then
						for dx = -1, 1 do
							for dy = -1, 1 do
								for dz = -1, 1 do
									if math.random() > 0.4 then
										local leaf_pos = {
											x = branch_pos.x + dx,
											y = branch_pos.y + dy,
											z = branch_pos.z + dz
										}
										local node = minetest.get_node(leaf_pos)
										if node.name == "air" then
											minetest.set_node(leaf_pos, {name = leaves_name})
										end
									end
								end
							end
						end
					end
				end
			end
		end

		-- Add top canopy
		local leaves_center = {x = pos.x, y = pos.y + trunk_height, z = pos.z}
		for dx = -2, 2 do
			for dy = 0, 2 do
				for dz = -2, 2 do
					local distance = math.sqrt(dx*dx + dz*dz)
					if distance <= 2 and math.random() > 0.3 then
						local leaf_pos = {
							x = leaves_center.x + dx,
							y = leaves_center.y + dy,
							z = leaves_center.z + dz
						}
						local node = minetest.get_node(leaf_pos)
						if node.name == "air" then
							minetest.set_node(leaf_pos, {name = leaves_name})
						end
					end
				end
			end
		end

		return true
	end,
})

-- Dark Oak Tree
vlf_trees.register_tree("dark_oak", {
	description = "Dark Oak",
	wood_description = "Dark Oak Log",
	planks_description = "Dark Oak Planks",
	leaves_description = "Dark Oak Leaves",
	sapling_description = "Dark Oak Sapling",

	-- Growth properties
	growth_time = 600, -- 10 minutes base (dark oak grows very slowly)
	growth_chance = 20, -- 1 in 20 chance per ABM cycle
	sapling_rarity = 30,

	-- Custom tree generator for dark oak's thick trunk
	tree_generator = function(pos, tree_name, tree_def)
		-- Dark oak needs 2x2 saplings to grow (simplified for now)
		local space_needed = 10
		for y = 1, space_needed do
			for dx = 0, 1 do
				for dz = 0, 1 do
					local check_pos = {x = pos.x + dx, y = pos.y + y, z = pos.z + dz}
					local node = minetest.get_node(check_pos)
					if node.name ~= "air" then
						return false
					end
				end
			end
		end

		local wood_name = "vlf_trees:" .. tree_name .. "_log"
		local leaves_name = "vlf_trees:" .. tree_name .. "_leaves"

		-- Generate thick 2x2 trunk
		local trunk_height = math.random(6, 9)
		for y = 0, trunk_height do
			for dx = 0, 1 do
				for dz = 0, 1 do
					minetest.set_node({x = pos.x + dx, y = pos.y + y, z = pos.z + dz}, {name = wood_name})
				end
			end
		end

		-- Generate large, dense canopy
		local leaves_center = {x = pos.x + 0.5, y = pos.y + trunk_height, z = pos.z + 0.5}
		for dx = -4, 4 do
			for dy = -1, 4 do
				for dz = -4, 4 do
					local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
					if distance <= 4 and math.random() > 0.1 then -- Very dense leaves
						local leaf_pos = {
							x = math.floor(leaves_center.x + dx),
							y = math.floor(leaves_center.y + dy),
							z = math.floor(leaves_center.z + dz)
						}
						local node = minetest.get_node(leaf_pos)
						if node.name == "air" then
							minetest.set_node(leaf_pos, {name = leaves_name})
						end
					end
				end
			end
		end

		return true
	end,
})

-- Pine Tree
vlf_trees.register_tree("pine", {
	description = "Pine",
	wood_description = "Pine Log",
	planks_description = "Pine Planks",
	leaves_description = "Pine Leaves",
	sapling_description = "Pine Sapling",

	-- Growth properties
	growth_time = 330, -- 5.5 minutes base
	growth_chance = 9, -- 1 in 9 chance per ABM cycle
	sapling_rarity = 20,

	-- Custom tree generator for tall, narrow pine trees
	tree_generator = function(pos, tree_name, tree_def)
		local space_needed = 15 -- Pine trees are tall
		for y = 1, space_needed do
			local check_pos = {x = pos.x, y = pos.y + y, z = pos.z}
			local node = minetest.get_node(check_pos)
			if node.name ~= "air" then
				return false
			end
		end

		local wood_name = "vlf_trees:" .. tree_name .. "_log"
		local leaves_name = "vlf_trees:" .. tree_name .. "_leaves"

		-- Generate tall, straight trunk
		local trunk_height = math.random(10, 14)
		for y = 0, trunk_height do
			minetest.set_node({x = pos.x, y = pos.y + y, z = pos.z}, {name = wood_name})
		end

		-- Generate conical leaves (pine tree shape)
		for layer = 0, 6 do
			local layer_y = pos.y + trunk_height - layer
			local radius = math.max(1, 4 - layer)

			for dx = -radius, radius do
				for dz = -radius, radius do
					local distance = math.sqrt(dx*dx + dz*dz)
					if distance <= radius and math.random() > 0.2 then
						local leaf_pos = {
							x = pos.x + dx,
							y = layer_y,
							z = pos.z + dz
						}
						local node = minetest.get_node(leaf_pos)
						if node.name == "air" then
							minetest.set_node(leaf_pos, {name = leaves_name})
						end
					end
				end
			end
		end

		return true
	end,
})

-- Sakura Tree
vlf_trees.register_tree("sakura", {
	description = "Sakura",
	wood_description = "Sakura Log",
	planks_description = "Sakura Planks",
	leaves_description = "Sakura Leaves",
	sapling_description = "Sakura Sapling",

	-- Growth properties
	growth_time = 270, -- 4.5 minutes base (sakura grows relatively fast)
	growth_chance = 7, -- 1 in 7 chance per ABM cycle
	sapling_rarity = 15, -- More common sapling drops

	-- Custom tree generator for elegant sakura trees
	tree_generator = function(pos, tree_name, tree_def)
		local space_needed = 9
		for y = 1, space_needed do
			local check_pos = {x = pos.x, y = pos.y + y, z = pos.z}
			local node = minetest.get_node(check_pos)
			if node.name ~= "air" then
				return false
			end
		end

		local wood_name = "vlf_trees:" .. tree_name .. "_log"
		local leaves_name = "vlf_trees:" .. tree_name .. "_leaves"

		-- Generate graceful trunk
		local trunk_height = math.random(5, 7)
		for y = 0, trunk_height do
			minetest.set_node({x = pos.x, y = pos.y + y, z = pos.z}, {name = wood_name})
		end

		-- Generate elegant, spreading canopy
		local leaves_center = {x = pos.x, y = pos.y + trunk_height, z = pos.z}
		for dx = -3, 3 do
			for dy = -1, 3 do
				for dz = -3, 3 do
					local distance = math.sqrt(dx*dx + dz*dz)
					-- Create a more organic, spreading shape
					local chance = 0.7 - (distance / 5) - (math.abs(dy) / 8)
					if distance <= 3.5 and math.random() < chance then
						local leaf_pos = {
							x = leaves_center.x + dx,
							y = leaves_center.y + dy,
							z = leaves_center.z + dz
						}
						local node = minetest.get_node(leaf_pos)
						if node.name == "air" then
							minetest.set_node(leaf_pos, {name = leaves_name})
						end
					end
				end
			end
		end

		return true
	end,
})

minetest.log("action", "[vlf_trees] All tree types registered successfully")