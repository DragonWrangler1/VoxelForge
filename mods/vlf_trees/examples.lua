-- VLF Trees API Examples
-- This file shows how to use the tree API for custom trees

-- Example 1: Simple custom tree
--[[
vlf_trees.register_tree("pine", {
    description = "Pine",
    wood_description = "Pine Log",
    planks_description = "Pine Planks",
    leaves_description = "Pine Needles",
    sapling_description = "Pine Sapling",
    
    -- Fast growing pine
    growth_time = 180, -- 3 minutes
    growth_chance = 5,  -- 1 in 5 chance
    sapling_rarity = 15, -- 1 in 15 from leaves
})
--]]

-- Example 2: Custom tree with unique properties
--[[
vlf_trees.register_tree("willow", {
    description = "Willow",
    wood_description = "Willow Log", 
    planks_description = "Willow Planks",
    leaves_description = "Willow Leaves",
    sapling_description = "Willow Sapling",
    
    -- Slow growing, droopy willow
    growth_time = 720, -- 12 minutes
    growth_chance = 25, -- 1 in 25 chance
    sapling_rarity = 35, -- Rare saplings
    
    -- Custom tree generator for droopy branches
    tree_generator = function(pos, tree_name, tree_def)
        local space_needed = 10
        for y = 1, space_needed do
            local check_pos = {x = pos.x, y = pos.y + y, z = pos.z}
            local node = minetest.get_node(check_pos)
            if node.name ~= "air" then
                return false
            end
        end
        
        local wood_name = "vlf_trees:" .. tree_name .. "_log"
        local leaves_name = "vlf_trees:" .. tree_name .. "_leaves"
        
        -- Generate trunk
        local trunk_height = math.random(5, 8)
        for y = 0, trunk_height do
            minetest.set_node({x = pos.x, y = pos.y + y, z = pos.z}, {name = wood_name})
        end
        
        -- Generate droopy branches
        local branch_y = pos.y + trunk_height - 2
        for angle = 0, 270, 90 do
            local rad = math.rad(angle)
            local dx = math.round(math.cos(rad) * 2)
            local dz = math.round(math.sin(rad) * 2)
            
            -- Create drooping branch
            for i = 1, 3 do
                local branch_pos = {
                    x = pos.x + dx * i,
                    y = branch_y - i + 1, -- Droop down
                    z = pos.z + dz * i
                }
                minetest.set_node(branch_pos, {name = wood_name})
                
                -- Add leaves hanging down
                for j = 1, math.random(2, 4) do
                    local leaf_pos = {
                        x = branch_pos.x,
                        y = branch_pos.y - j,
                        z = branch_pos.z
                    }
                    if minetest.get_node(leaf_pos).name == "air" then
                        minetest.set_node(leaf_pos, {name = leaves_name})
                    end
                end
            end
        end
        
        return true
    end,
})
--]]

-- Example 3: Fruit tree (requires additional fruit mod)
--[[
if minetest.get_modpath("vlf_fruits") then
    vlf_trees.register_tree("apple", {
        description = "Apple",
        wood_description = "Apple Log",
        planks_description = "Apple Planks", 
        leaves_description = "Apple Leaves",
        sapling_description = "Apple Sapling",
        
        growth_time = 400,
        growth_chance = 12,
        sapling_rarity = 30,
        
        -- Custom leaves that can grow apples
        leaves_groups = {
            snappy = 3, leafdecay = 3, flammable = 2, 
            leaves = 1, fruit_bearing = 1, voxelforge_material = 1
        },
    })
    
    -- Register apple fruit growing on apple leaves
    minetest.register_abm({
        label = "Apple fruit growth",
        nodenames = {"vlf_trees:apple_leaves"},
        interval = 300,
        chance = 20,
        action = function(pos, node)
            -- Check if there's space below for apple
            local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
            if minetest.get_node(below_pos).name == "air" then
                minetest.set_node(below_pos, {name = "vlf_fruits:apple_hanging"})
            end
        end
    })
end
--]]

-- Chat command for testing tree growth
minetest.register_chatcommand("grow_tree", {
    params = "<tree_name>",
    description = "Grow a tree at your position",
    privs = {server = true},
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local tree_name = param:trim()
        if tree_name == "" then
            return false, "Please specify a tree name"
        end
        
        if not vlf_trees.registered_trees[tree_name] then
            return false, "Tree type not found: " .. tree_name
        end
        
        local pos = player:get_pos()
        pos.y = pos.y + 1
        
        if vlf_trees.grow_tree(pos, tree_name) then
            return true, "Grew " .. tree_name .. " tree at " .. minetest.pos_to_string(pos)
        else
            return false, "Failed to grow tree (not enough space?)"
        end
    end,
})

-- Chat command for placing saplings
minetest.register_chatcommand("place_sapling", {
    params = "<tree_name> [stage]",
    description = "Place a sapling at your position",
    privs = {server = true},
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found"
        end
        
        local parts = param:split(" ")
        local tree_name = parts[1] or ""
        local stage = parts[2] or "sapling"
        
        if tree_name == "" then
            return false, "Please specify a tree name"
        end
        
        if not vlf_trees.registered_trees[tree_name] then
            return false, "Tree type not found: " .. tree_name
        end
        
        local sapling_name = "vlf_trees:" .. tree_name .. "_" .. stage
        if not minetest.registered_nodes[sapling_name] then
            return false, "Sapling stage not found: " .. stage
        end
        
        local pos = player:get_pos()
        pos.y = pos.y + 1
        
        minetest.set_node(pos, {name = sapling_name, param2 = math.random(0, 3)})
        
        return true, "Placed " .. sapling_name .. " at " .. minetest.pos_to_string(pos)
    end,
})

minetest.log("action", "[vlf_trees] Examples and test commands loaded")