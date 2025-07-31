-- VoxelForge Digging Speed System
-- A simple system that adjusts digging speed based on tool strength vs material hardness

local voxelforge_digging = {}

-- Material hardness levels (higher = harder to dig)
voxelforge_digging.material_hardness = {
    -- Soft materials
    dirt = 1,
    grass = 1,
    sand = 1,
    gravel = 2,
    
    -- Wood materials
    wood = 3,
    planks = 3,
    leaves = 1,
    
    -- Stone materials
    stone = 5,
    cobble = 4,
    
    -- Ores (progressively harder)
    coal_ore = 6,
    copper_ore = 7,
    iron_ore = 8,
    
    -- Special hard materials
    obsidian = 12,
    bedrock = 999, -- Nearly unbreakable
}

-- Tool strength levels (higher = stronger)
voxelforge_digging.tool_strength = {
    -- Hand digging
    hand = 1,
    
    -- Wooden tools
    wooden_pickaxe = 2,
    wooden_axe = 2,
    wooden_shovel = 2,
    
    -- Stone tools
    stone_pickaxe = 4,
    stone_axe = 4,
    stone_shovel = 4,
    
    -- Iron tools
    iron_pickaxe = 7,
    iron_axe = 7,
    iron_shovel = 7,
    
    -- Diamond tools (if added later)
    diamond_pickaxe = 10,
    diamond_axe = 10,
    diamond_shovel = 10,
}

-- Tool effectiveness for different material types
-- This determines how well suited a tool is for a material type
voxelforge_digging.tool_effectiveness = {
    pickaxe = {
        stone = 1.0, ore = 1.0, 
        wood = 0.6, leaves = 0.4,
        dirt = 0.7, sand = 0.7, gravel = 0.8,
        default = 0.5
    },
    axe = {
        wood = 1.0, leaves = 1.0,
        stone = 0.4, ore = 0.3,
        dirt = 0.6, sand = 0.5, gravel = 0.5,
        default = 0.4
    },
    shovel = {
        dirt = 1.0, sand = 1.0, gravel = 1.0,
        stone = 0.3, ore = 0.2,
        wood = 0.5, leaves = 0.7,
        default = 0.4
    },
    hand = {
        dirt = 0.8, sand = 0.9, leaves = 0.9,
        wood = 0.2, stone = 0.1, ore = 0.05,
        gravel = 0.6,
        default = 0.3
    }
}

-- Get material hardness from node name
function voxelforge_digging.get_material_hardness(node_name)
    local node_def = minetest.registered_nodes[node_name]
    if not node_def then return 5 end -- Default hardness
    
    -- Check for specific material types in node name
    for material, hardness in pairs(voxelforge_digging.material_hardness) do
        if string.find(node_name, material) then
            return hardness
        end
    end
    
    -- Additional pattern matching for common block types
    if string.find(node_name, "grass") then return 1 end
    if string.find(node_name, "leaves") then return 1 end
    if string.find(node_name, "water") or string.find(node_name, "lava") then return 0 end
    if string.find(node_name, "air") then return 0 end
    
    return 5 -- Default hardness for unknown materials
end

-- Get tool strength from tool name
function voxelforge_digging.get_tool_strength(tool_name)
    if not tool_name or tool_name == "" then
        return voxelforge_digging.tool_strength.hand
    end
    
    -- Extract tool type from name
    for tool_type, strength in pairs(voxelforge_digging.tool_strength) do
        if string.find(tool_name, tool_type) then
            return strength
        end
    end
    
    return voxelforge_digging.tool_strength.hand
end

-- Get tool type from tool name
function voxelforge_digging.get_tool_type(tool_name)
    if string.find(tool_name, "pickaxe") then return "pickaxe" end
    if string.find(tool_name, "axe") then return "axe" end
    if string.find(tool_name, "shovel") then return "shovel" end
    return "hand"
end

-- Get material type from node name
function voxelforge_digging.get_material_type(node_name)
    if string.find(node_name, "stone") or string.find(node_name, "ore") or string.find(node_name, "cobble") then
        return "stone"
    elseif string.find(node_name, "wood") or string.find(node_name, "planks") then
        return "wood"
    elseif string.find(node_name, "leaves") then
        return "leaves"
    elseif string.find(node_name, "dirt") or string.find(node_name, "grass") then
        return "dirt"
    elseif string.find(node_name, "sand") then
        return "sand"
    elseif string.find(node_name, "gravel") then
        return "gravel"
    end
    return "default"
end

-- Calculate digging time based on tool strength vs material hardness
function voxelforge_digging.calculate_dig_time(tool_name, node_name)
    local tool_strength = voxelforge_digging.get_tool_strength(tool_name)
    local material_hardness = voxelforge_digging.get_material_hardness(node_name)
    local tool_type = voxelforge_digging.get_tool_type(tool_name)
    local material_type = voxelforge_digging.get_material_type(node_name)
    
    -- Get tool effectiveness multiplier
    local effectiveness = 1.0
    if voxelforge_digging.tool_effectiveness[tool_type] then
        effectiveness = voxelforge_digging.tool_effectiveness[tool_type][material_type] or 
                       voxelforge_digging.tool_effectiveness[tool_type].default
    end
    
    -- Base calculation: harder materials take longer, stronger tools are faster
    local base_time = material_hardness / (tool_strength * effectiveness)
    
    -- Apply scaling to make times reasonable (0.1-10 seconds typically)
    local dig_time = base_time * 0.8
    
    -- Minimum dig time of 0.1 seconds, maximum of 30 seconds
    dig_time = math.max(0.1, math.min(30.0, dig_time))
    
    return dig_time
end

-- Override node digging times for voxelforge materials
local function override_node_digging(node_name, node_def)
    if not node_def.groups or not node_def.groups.voxelforge_material then
        return -- Only affect voxelforge materials
    end
    
    -- Create new tool_capabilities that adjust dig times based on our system
    local new_tool_capabilities = {}
    
    -- For each possible tool type, calculate appropriate dig times
    local tool_types = {"", "wooden_pickaxe", "wooden_axe", "wooden_shovel", 
                       "stone_pickaxe", "stone_axe", "stone_shovel",
                       "iron_pickaxe", "iron_axe", "iron_shovel",
                       "diamond_pickaxe", "diamond_axe", "diamond_shovel"}
    
    for _, tool_name in ipairs(tool_types) do
        local dig_time = voxelforge_digging.calculate_dig_time(tool_name, node_name)
        
        -- Store this for use in tool definitions
        if not new_tool_capabilities[tool_name] then
            new_tool_capabilities[tool_name] = {}
        end
        new_tool_capabilities[tool_name][node_name] = dig_time
    end
    
    -- Override the node to use our calculated dig times
    minetest.override_item(node_name, {
        -- Remove default groups that control digging
        groups = node_def.groups,
        -- We'll handle digging speed through tool modifications instead
    })
end

-- Override tool digging capabilities
local function override_tool_capabilities()
    -- Get all registered tools
    for item_name, item_def in pairs(minetest.registered_tools) do
        if item_def.tool_capabilities then
            local tool_type = voxelforge_digging.get_tool_type(item_name)
            local tool_strength = voxelforge_digging.get_tool_strength(item_name)
            
            -- Create new groupcaps based on our digging system
            local new_groupcaps = {}
            
            -- For voxelforge materials, set appropriate dig times
            for node_name, node_def in pairs(minetest.registered_nodes) do
                if node_def.groups and node_def.groups.voxelforge_material then
                    local dig_time = voxelforge_digging.calculate_dig_time(item_name, node_name)
                    
                    -- Determine which group this node belongs to
                    local group_name = "voxelforge_material"
                    
                    if not new_groupcaps[group_name] then
                        new_groupcaps[group_name] = {
                            times = {},
                            uses = item_def.tool_capabilities.groupcaps and 
                                   item_def.tool_capabilities.groupcaps[group_name] and
                                   item_def.tool_capabilities.groupcaps[group_name].uses or 100,
                            maxlevel = 3
                        }
                    end
                    
                    -- Set dig time for this specific level/hardness
                    local hardness = voxelforge_digging.get_material_hardness(node_name)
                    local level = math.min(3, math.max(1, math.floor(hardness / 3) + 1))
                    new_groupcaps[group_name].times[level] = dig_time
                end
            end
            
            -- Keep existing groupcaps for non-voxelforge materials
            if item_def.tool_capabilities.groupcaps then
                for group, caps in pairs(item_def.tool_capabilities.groupcaps) do
                    if group ~= "voxelforge_material" then
                        new_groupcaps[group] = caps
                    end
                end
            end
            
            -- Override the tool with new capabilities
            minetest.override_item(item_name, {
                tool_capabilities = {
                    full_punch_interval = item_def.tool_capabilities.full_punch_interval,
                    max_drop_level = item_def.tool_capabilities.max_drop_level,
                    groupcaps = new_groupcaps,
                    damage_groups = item_def.tool_capabilities.damage_groups,
                }
            })
        end
    end
end

-- Apply our digging speed system when all mods are loaded
minetest.register_on_mods_loaded(function()
    -- First, override all voxelforge material nodes
    for node_name, node_def in pairs(minetest.registered_nodes) do
        override_node_digging(node_name, node_def)
    end
    
    -- Then, override all tool capabilities
    override_tool_capabilities()
end)

-- Ensure voxelforge materials have proper groups and levels
minetest.register_on_mods_loaded(function()
    for node_name, node_def in pairs(minetest.registered_nodes) do
        if node_def.groups and node_def.groups.voxelforge_material then
            local hardness = voxelforge_digging.get_material_hardness(node_name)
            local level = math.min(3, math.max(1, math.floor(hardness / 3) + 1))
            
            -- Ensure the node has the right group level
            local new_groups = {}
            for group, value in pairs(node_def.groups) do
                new_groups[group] = value
            end
            new_groups.voxelforge_material = level
            
            minetest.override_item(node_name, {
                groups = new_groups
            })
        end
    end
end)

-- Chat command to check digging information
minetest.register_chatcommand("diginfo", {
    description = "Get digging speed information about the node you're looking at",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        
        local pos = player:get_pos()
        local dir = player:get_look_dir()
        local end_pos = vector.add(pos, vector.multiply(dir, 5))
        local ray = minetest.raycast(pos, end_pos, false, false)
        
        for pointed_thing in ray do
            if pointed_thing.type == "node" then
                local node = minetest.get_node(pointed_thing.under)
                local hardness = voxelforge_digging.get_material_hardness(node.name)
                local wielded = player:get_wielded_item()
                local tool_name = wielded:get_name()
                local tool_strength = voxelforge_digging.get_tool_strength(tool_name)
                local dig_time = voxelforge_digging.calculate_dig_time(tool_name, node.name)
                
                local info = string.format(
                    "Node: %s\\nHardness: %d\\nTool: %s\\nTool Strength: %d\\nDig Time: %.1fs",
                    node.name, hardness, tool_name == "" and "hand" or tool_name, 
                    tool_strength, dig_time
                )
                
                return true, info
            end
        end
        
        return false, "No node found"
    end,
})

-- Export API functions for other mods
voxelforge_digging.get_material_hardness = voxelforge_digging.get_material_hardness
voxelforge_digging.get_tool_strength = voxelforge_digging.get_tool_strength
voxelforge_digging.calculate_dig_time = voxelforge_digging.calculate_dig_time

minetest.log("action", "[VoxelForge Digging] Simple digging speed system loaded")