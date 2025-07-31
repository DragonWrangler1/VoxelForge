-- VoxelForge Trees API
-- Comprehensive tree registration system with progressive growth

vlf_trees = {}

-- Tree registry to store all registered trees
vlf_trees.registered_trees = {}

-- Growth stages for saplings
vlf_trees.growth_stages = {
    "sapling",
    "young_sapling", 
    "mature_sapling",
    "small_tree",
    "tree"
}

-- Default tree properties
local default_tree_def = {
    -- Basic properties
    description = "Tree",
    wood_description = "Wood",
    planks_description = "Planks",
    leaves_description = "Leaves",
    sapling_description = "Sapling",
    
    -- Textures (will be auto-generated if not provided)
    wood_texture = nil,
    planks_texture = nil,
    leaves_texture = nil,
    sapling_texture = nil,
    
    -- Growth properties
    growth_time = 300, -- Base growth time in seconds (5 minutes)
    growth_chance = 10, -- 1 in X chance per ABM cycle
    sapling_rarity = 20, -- 1 in X chance to drop from leaves
    
    -- Tree generation
    tree_schematic = nil, -- Custom schematic file
    tree_generator = nil, -- Custom tree generation function
    
    -- Groups
    wood_groups = {choppy = 2, oddly_breakable_by_hand = 1, flammable = 3, wood = 1, tree = 1, voxelforge_material = 1},
    planks_groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3, wood = 1, voxelforge_material = 1},
    leaves_groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1, voxelforge_material = 1},
    sapling_groups = {snappy = 3, flammable = 2, attached_node = 1, sapling = 1, voxelforge_material = 1},
    
    -- Sounds (placeholder for now)
    wood_sounds = nil,
    planks_sounds = nil,
    leaves_sounds = nil,
    sapling_sounds = nil,
}

-- Helper function to merge tables
local function merge_tables(base, override)
    local result = {}
    for k, v in pairs(base) do
        result[k] = v
    end
    for k, v in pairs(override) do
        result[k] = v
    end
    return result
end

-- Generate default textures based on tree name
local function generate_default_textures(tree_name)
    return {
        wood_texture = "vlf_trees_" .. tree_name .. "_log.png",
        planks_texture = "vlf_trees_" .. tree_name .. "_planks.png", 
        leaves_texture = "vlf_trees_" .. tree_name .. "_leaves.png",
        sapling_texture = "vlf_trees_" .. tree_name .. "_sapling.png",
        stripped_log_texture = "vlf_trees_" .. tree_name .. "_log_stripped.png",
    }
end

-- Register a sapling with progressive growth stages
local function register_sapling_stages(tree_name, tree_def)
    local base_name = "vlf_trees:" .. tree_name
    
    -- Register each growth stage
    for i, stage in ipairs(vlf_trees.growth_stages) do
        local stage_name = base_name .. "_" .. stage
        local is_final_stage = (stage == "tree")
        
        if not is_final_stage then
            local visual_scale = 0.5 + (i * 0.2) -- Progressive size increase
            local description = tree_def.sapling_description
            
            if stage ~= "sapling" then
                description = description .. " (" .. stage:gsub("_", " "):gsub("^%l", string.upper) .. ")"
            end
            
            minetest.register_node(stage_name, {
                description = description,
                drawtype = "plantlike",
                tiles = {tree_def.sapling_texture},
                inventory_image = tree_def.sapling_texture,
                wield_image = tree_def.sapling_texture,
                paramtype = "light",
                paramtype2 = "meshoptions",
                place_param2 = 4,
                sunlight_propagates = true,
                walkable = false,
                buildable_to = true,
                visual_scale = visual_scale,
                selection_box = {
                    type = "fixed",
                    fixed = {-4/16, -0.5, -4/16, 4/16, visual_scale * 0.5 - 0.5, 4/16}
                },
                groups = merge_tables(tree_def.sapling_groups, {
                    not_in_creative_inventory = (stage ~= "sapling") and 1 or nil,
                    tree_sapling_stage = i
                }),
                sounds = tree_def.sapling_sounds,
                
                -- Growth metadata
                _vlf_trees_stage = i,
                _vlf_trees_tree_name = tree_name,
                _vlf_trees_next_stage = (i < #vlf_trees.growth_stages - 1) and (base_name .. "_" .. vlf_trees.growth_stages[i + 1]) or nil,
                
                -- Bonemeal support
                _vlf_trees_bonemeal_speedup = function(pos)
                    local node = minetest.get_node(pos)
                    local next_stage = minetest.registered_nodes[node.name]._vlf_trees_next_stage
                    if next_stage then
                        minetest.set_node(pos, {name = next_stage, param2 = node.param2})
                        return true
                    elseif i == #vlf_trees.growth_stages - 1 then
                        -- Final stage - grow into tree
                        vlf_trees.grow_tree(pos, tree_name)
                        return true
                    end
                    return false
                end,
            })
        end
    end
end

-- Tree generation function
function vlf_trees.grow_tree(pos, tree_name)
    local tree_def = vlf_trees.registered_trees[tree_name]
    if not tree_def then
        return false
    end
    
    -- Check if there's enough space
    local space_needed = 7 -- Default tree height
    for y = 1, space_needed do
        local check_pos = {x = pos.x, y = pos.y + y, z = pos.z}
        local node = minetest.get_node(check_pos)
        if node.name ~= "air" then
            return false -- Not enough space
        end
    end
    
    -- Use custom generator if provided
    if tree_def.tree_generator then
        return tree_def.tree_generator(pos, tree_name, tree_def)
    end
    
    -- Default simple tree generation
    local wood_name = "vlf_trees:" .. tree_name .. "_log"
    local leaves_name = "vlf_trees:" .. tree_name .. "_leaves"
    
    -- Generate trunk
    local trunk_height = math.random(4, 6)
    for y = 0, trunk_height do
        minetest.set_node({x = pos.x, y = pos.y + y, z = pos.z}, {name = wood_name})
    end
    
    -- Generate leaves (simple sphere)
    local leaves_center = {x = pos.x, y = pos.y + trunk_height, z = pos.z}
    for dx = -2, 2 do
        for dy = -1, 2 do
            for dz = -2, 2 do
                local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
                if distance <= 2.5 and math.random() > 0.3 then
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
end

-- Register fence
local function register_fence(tree_name, tree_def)
    local fence_name = "vlf_trees:" .. tree_name .. "_fence"
    
    minetest.register_node(fence_name, {
        description = tree_def.description .. " Fence",
        drawtype = "fencelike",
        tiles = {tree_def.planks_texture},
        inventory_image = "vlf_trees_" .. tree_name .. "_fence.png",
        wield_image = "vlf_trees_" .. tree_name .. "_fence.png",
        paramtype = "light",
        sunlight_propagates = true,
        is_ground_content = false,
        groups = merge_tables(tree_def.planks_groups, {fence = 1}),
        connects_to = {"group:fence", "group:wood", "group:tree"},
        selection_box = {
            type = "fixed",
            fixed = {-1/7, -1/2, -1/7, 1/7, 1/2, 1/7},
        },
        sounds = tree_def.planks_sounds,
    })
end

-- Register fence gate
local function register_fence_gate(tree_name, tree_def)
    local gate_name = "vlf_trees:" .. tree_name .. "_fence_gate"
    
    minetest.register_node(gate_name, {
        description = tree_def.description .. " Fence Gate",
        drawtype = "mesh",
        mesh = "vlf_trees_fence_gate_closed.obj",
        tiles = {tree_def.planks_texture},
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        is_ground_content = false,
        groups = merge_tables(tree_def.planks_groups, {fence_gate = 1}),
        sounds = tree_def.planks_sounds,
        
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            local state = meta:get_string("state")
            
            if state == "open" then
                minetest.swap_node(pos, {name = gate_name, param2 = node.param2})
                meta:set_string("state", "closed")
            else
                minetest.swap_node(pos, {name = gate_name .. "_open", param2 = node.param2})
                meta:set_string("state", "open")
            end
        end,
    })
    
    -- Open state
    minetest.register_node(gate_name .. "_open", {
        description = tree_def.description .. " Fence Gate (Open)",
        drawtype = "mesh", 
        mesh = "vlf_trees_fence_gate_open.obj",
        tiles = {tree_def.planks_texture},
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        is_ground_content = false,
        groups = merge_tables(tree_def.planks_groups, {fence_gate = 1, not_in_creative_inventory = 1}),
        sounds = tree_def.planks_sounds,
        drop = gate_name,
        
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            minetest.swap_node(pos, {name = gate_name, param2 = node.param2})
            meta:set_string("state", "closed")
        end,
    })
end

-- Register door
local function register_door(tree_name, tree_def)
    local door_name = "vlf_trees:" .. tree_name .. "_door"
    
    -- Bottom half (closed)
    minetest.register_node(door_name .. "_b", {
        description = tree_def.description .. " Door",
        drawtype = "mesh",
        mesh = "vlf_trees_door_b.obj",
        tiles = {"vlf_trees_" .. tree_name .. "_door.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        is_ground_content = false,
        groups = merge_tables(tree_def.planks_groups, {door = 1}),
        sounds = tree_def.planks_sounds,
        drop = door_name,
        
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            -- Open door logic
            local top_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
            minetest.swap_node(pos, {name = door_name .. "_b_open", param2 = node.param2})
            minetest.swap_node(top_pos, {name = door_name .. "_t_open", param2 = node.param2})
        end,
    })
    
    -- Top half (closed)
    minetest.register_node(door_name .. "_t", {
        description = tree_def.description .. " Door (Top)",
        drawtype = "mesh",
        mesh = "vlf_trees_door_t.obj", 
        tiles = {"vlf_trees_" .. tree_name .. "_door.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        is_ground_content = false,
        groups = merge_tables(tree_def.planks_groups, {door = 1, not_in_creative_inventory = 1}),
        sounds = tree_def.planks_sounds,
        drop = "",
    })
    
    -- Open states
    minetest.register_node(door_name .. "_b_open", {
        description = tree_def.description .. " Door (Open Bottom)",
        drawtype = "mesh",
        mesh = "vlf_trees_door_b_open.obj",
        tiles = {"vlf_trees_" .. tree_name .. "_door.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        is_ground_content = false,
        groups = merge_tables(tree_def.planks_groups, {door = 1, not_in_creative_inventory = 1}),
        sounds = tree_def.planks_sounds,
        drop = door_name,
        
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            -- Close door logic
            local top_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
            minetest.swap_node(pos, {name = door_name .. "_b", param2 = node.param2})
            minetest.swap_node(top_pos, {name = door_name .. "_t", param2 = node.param2})
        end,
    })
    
    minetest.register_node(door_name .. "_t_open", {
        description = tree_def.description .. " Door (Open Top)",
        drawtype = "mesh",
        mesh = "vlf_trees_door_t_open.obj",
        tiles = {"vlf_trees_" .. tree_name .. "_door.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        sunlight_propagates = true,
        is_ground_content = false,
        groups = merge_tables(tree_def.planks_groups, {door = 1, not_in_creative_inventory = 1}),
        sounds = tree_def.planks_sounds,
        drop = "",
    })
    
    -- Craftitem for inventory
    minetest.register_craftitem(door_name, {
        description = tree_def.description .. " Door",
        inventory_image = "vlf_trees_" .. tree_name .. "_door_item.png",
        
        on_place = function(itemstack, placer, pointed_thing)
            if pointed_thing.type ~= "node" then
                return itemstack
            end
            
            local pos = pointed_thing.above
            local pos_top = {x = pos.x, y = pos.y + 1, z = pos.z}
            
            -- Check if both positions are free
            if minetest.get_node(pos).name ~= "air" or minetest.get_node(pos_top).name ~= "air" then
                return itemstack
            end
            
            -- Place door
            local dir = minetest.dir_to_facedir(placer:get_look_dir())
            minetest.set_node(pos, {name = door_name .. "_b", param2 = dir})
            minetest.set_node(pos_top, {name = door_name .. "_t", param2 = dir})
            
            itemstack:take_item()
            return itemstack
        end,
    })
end

-- Register trapdoor
local function register_trapdoor(tree_name, tree_def)
    local trapdoor_name = "vlf_trees:" .. tree_name .. "_trapdoor"
    
    -- Closed state
    minetest.register_node(trapdoor_name, {
        description = tree_def.description .. " Trapdoor",
        drawtype = "nodebox",
        tiles = {"vlf_trees_" .. tree_name .. "_trapdoor.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        is_ground_content = false,
        groups = merge_tables(tree_def.planks_groups, {trapdoor = 1}),
        sounds = tree_def.planks_sounds,
        
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.375, 0.5}
        },
        
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            minetest.swap_node(pos, {name = trapdoor_name .. "_open", param2 = node.param2})
        end,
    })
    
    -- Open state
    minetest.register_node(trapdoor_name .. "_open", {
        description = tree_def.description .. " Trapdoor (Open)",
        drawtype = "nodebox",
        tiles = {"vlf_trees_" .. tree_name .. "_trapdoor.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        is_ground_content = false,
        groups = merge_tables(tree_def.planks_groups, {trapdoor = 1, not_in_creative_inventory = 1}),
        sounds = tree_def.planks_sounds,
        drop = trapdoor_name,
        
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, 0.375, 0.5, 0.5, 0.5}
        },
        
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            minetest.swap_node(pos, {name = trapdoor_name, param2 = node.param2})
        end,
    })
end

-- Main tree registration function
function vlf_trees.register_tree(tree_name, tree_def)
    -- Merge with defaults
    tree_def = merge_tables(default_tree_def, tree_def or {})
    
    -- Generate default textures if not provided
    local default_textures = generate_default_textures(tree_name)
    for k, v in pairs(default_textures) do
        if not tree_def[k] then
            tree_def[k] = v
        end
    end
    
    -- Store in registry
    vlf_trees.registered_trees[tree_name] = tree_def
    
    local base_name = "vlf_trees:" .. tree_name
    
    -- Register log
    minetest.register_node(base_name .. "_log", {
        description = tree_def.wood_description,
        tiles = {tree_def.wood_texture},
        paramtype2 = "facedir",
        is_ground_content = false,
        groups = tree_def.wood_groups,
        sounds = tree_def.wood_sounds,
        
        on_place = minetest.rotate_node,
    })
    
    -- Register stripped log
    minetest.register_node(base_name .. "_log_stripped", {
        description = "Stripped " .. tree_def.wood_description,
        tiles = {tree_def.stripped_log_texture},
        paramtype2 = "facedir", 
        is_ground_content = false,
        groups = tree_def.wood_groups,
        sounds = tree_def.wood_sounds,
        
        on_place = minetest.rotate_node,
    })
    
    -- Register planks
    minetest.register_node(base_name .. "_planks", {
        description = tree_def.planks_description,
        tiles = {tree_def.planks_texture},
        is_ground_content = false,
        groups = tree_def.planks_groups,
        sounds = tree_def.planks_sounds,
    })
    
    -- Register leaves
    minetest.register_node(base_name .. "_leaves", {
        description = tree_def.leaves_description,
        drawtype = "allfaces_optional",
        waving = 1,
        tiles = {tree_def.leaves_texture},
        paramtype = "light",
        groups = tree_def.leaves_groups,
        sounds = tree_def.leaves_sounds,
        
        drop = {
            max_items = 1,
            items = {
                {items = {base_name .. "_sapling"}, rarity = tree_def.sapling_rarity},
                {items = {base_name .. "_leaves"}}
            }
        },
    })
    
    -- Register sapling stages
    register_sapling_stages(tree_name, tree_def)
    
    -- Register fence
    register_fence(tree_name, tree_def)
    
    -- Register fence gate
    register_fence_gate(tree_name, tree_def)
    
    -- Register door
    register_door(tree_name, tree_def)
    
    -- Register trapdoor
    register_trapdoor(tree_name, tree_def)
    
    -- Register basic crafting recipes
    vlf_trees.register_tree_recipes(tree_name)
    
    minetest.log("action", "[vlf_trees] Registered tree: " .. tree_name)
end

-- Register crafting recipes for a tree
function vlf_trees.register_tree_recipes(tree_name)
    local base_name = "vlf_trees:" .. tree_name
    
    -- Log to planks
    minetest.register_craft({
        output = base_name .. "_planks 4",
        recipe = {{base_name .. "_log"}}
    })
    
    -- Stripped log to planks
    minetest.register_craft({
        output = base_name .. "_planks 4", 
        recipe = {{base_name .. "_log_stripped"}}
    })
    
    -- Planks to sticks
    minetest.register_craft({
        output = "vlf_blocks:stick 4",
        recipe = {
            {base_name .. "_planks"},
            {base_name .. "_planks"}
        }
    })
    
    -- Fence recipe
    minetest.register_craft({
        output = base_name .. "_fence 3",
        recipe = {
            {base_name .. "_planks", "vlf_blocks:stick", base_name .. "_planks"},
            {base_name .. "_planks", "vlf_blocks:stick", base_name .. "_planks"}
        }
    })
    
    -- Fence gate recipe
    minetest.register_craft({
        output = base_name .. "_fence_gate",
        recipe = {
            {"vlf_blocks:stick", base_name .. "_planks", "vlf_blocks:stick"},
            {"vlf_blocks:stick", base_name .. "_planks", "vlf_blocks:stick"}
        }
    })
    
    -- Door recipe
    minetest.register_craft({
        output = base_name .. "_door",
        recipe = {
            {base_name .. "_planks", base_name .. "_planks"},
            {base_name .. "_planks", base_name .. "_planks"},
            {base_name .. "_planks", base_name .. "_planks"}
        }
    })
    
    -- Trapdoor recipe
    minetest.register_craft({
        output = base_name .. "_trapdoor 2",
        recipe = {
            {base_name .. "_planks", base_name .. "_planks", base_name .. "_planks"},
            {base_name .. "_planks", base_name .. "_planks", base_name .. "_planks"}
        }
    })
end

-- ABM for sapling growth
minetest.register_abm({
    label = "VLF Trees sapling growth",
    nodenames = {"group:sapling"},
    neighbors = {"group:soil", "vlf_blocks:dirt", "vlf_blocks:dirt_with_grass"},
    interval = 30,
    chance = 10,
    action = function(pos, node, active_object_count, active_object_count_wider)
        local node_def = minetest.registered_nodes[node.name]
        if not node_def or not node_def._vlf_trees_tree_name then
            return
        end
        
        local tree_name = node_def._vlf_trees_tree_name
        local tree_def = vlf_trees.registered_trees[tree_name]
        if not tree_def then
            return
        end
        
        -- Check growth chance
        if math.random(1, tree_def.growth_chance) ~= 1 then
            return
        end
        
        -- Check light level
        local light_level = minetest.get_node_light(pos)
        if not light_level or light_level < 8 then
            return
        end
        
        -- Progress to next stage or grow tree
        local next_stage = node_def._vlf_trees_next_stage
        if next_stage then
            minetest.set_node(pos, {name = next_stage, param2 = node.param2})
        else
            -- Final stage - grow into tree
            vlf_trees.grow_tree(pos, tree_name)
        end
    end
})

-- Bonemeal API integration (if available)
if minetest.get_modpath("vlf_bonemeal") then
    vlf_bonemeal.register_on_use(function(pos, node, player)
        local node_def = minetest.registered_nodes[node.name]
        if node_def and node_def._vlf_trees_bonemeal_speedup then
            return node_def._vlf_trees_bonemeal_speedup(pos)
        end
        return false
    end)
end

-- Load tree definitions
dofile(minetest.get_modpath("vlf_trees") .. "/trees.lua")

-- Load examples and test commands
dofile(minetest.get_modpath("vlf_trees") .. "/examples.lua")

minetest.log("action", "[vlf_trees] Tree API loaded successfully")