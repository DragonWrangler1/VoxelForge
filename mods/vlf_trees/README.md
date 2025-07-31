# VLF Trees API

A comprehensive tree registration system for VoxelForge that provides a complete set of tree-related blocks and progressive sapling growth.

## Features

### Complete Tree Sets
Each registered tree includes:
- **Logs** - The main wood block with directional placement
- **Stripped Logs** - Decorative variant of logs
- **Planks** - Crafted from logs for building
- **Leaves** - With sapling drops and leaf decay
- **Saplings** - With progressive growth stages
- **Fences** - Connecting fence blocks
- **Fence Gates** - Openable gates that connect to fences
- **Doors** - Two-block tall doors with open/close functionality
- **Trapdoors** - Single-block trapdoors with open/close functionality

### Progressive Sapling Growth
Saplings grow through multiple stages:
1. **Sapling** - Initial planted stage
2. **Young Sapling** - First growth stage
3. **Mature Sapling** - Second growth stage  
4. **Small Tree** - Third growth stage
5. **Tree** - Final stage that grows into full tree

### Growth Mechanics
- **ABM-based Growth** - Uses Minetest's ABM system for automatic growth
- **Light Requirements** - Saplings need light level 8+ to grow
- **Soil Requirements** - Must be planted on soil, dirt, or grass
- **Configurable Timing** - Each tree type has customizable growth rates
- **Bonemeal Support** - Compatible with bonemeal mods for faster growth

## API Usage

### Basic Tree Registration

```lua
vlf_trees.register_tree("tree_name", {
    description = "Tree Name",
    wood_description = "Tree Name Log",
    planks_description = "Tree Name Planks",
    leaves_description = "Tree Name Leaves", 
    sapling_description = "Tree Name Sapling",
    
    -- Growth properties
    growth_time = 300, -- Base growth time in seconds
    growth_chance = 10, -- 1 in X chance per ABM cycle
    sapling_rarity = 20, -- 1 in X chance to drop from leaves
})
```

### Advanced Tree Registration

```lua
vlf_trees.register_tree("custom_tree", {
    -- Basic properties
    description = "Custom Tree",
    wood_description = "Custom Log",
    planks_description = "Custom Planks",
    leaves_description = "Custom Leaves",
    sapling_description = "Custom Sapling",
    
    -- Custom textures (optional - will auto-generate if not provided)
    wood_texture = "custom_tree_log.png",
    planks_texture = "custom_tree_planks.png", 
    leaves_texture = "custom_tree_leaves.png",
    sapling_texture = "custom_tree_sapling.png",
    stripped_log_texture = "custom_tree_log_stripped.png",
    
    -- Growth properties
    growth_time = 600,
    growth_chance = 15,
    sapling_rarity = 25,
    
    -- Custom groups (optional)
    wood_groups = {choppy = 2, flammable = 3, wood = 1, custom_group = 1},
    planks_groups = {choppy = 3, flammable = 3, wood = 1, custom_group = 1},
    leaves_groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1},
    sapling_groups = {snappy = 3, flammable = 2, attached_node = 1, sapling = 1},
    
    -- Custom tree generation function
    tree_generator = function(pos, tree_name, tree_def)
        -- Your custom tree generation logic here
        -- Return true if successful, false if failed
        return vlf_trees.grow_tree(pos, tree_name) -- Fallback to default
    end,
})
```

### Utility Functions

```lua
-- Grow a tree at a specific position
vlf_trees.grow_tree(pos, "tree_name")

-- Register additional recipes for a tree
vlf_trees.register_tree_recipes("tree_name")

-- Access registered tree data
local tree_def = vlf_trees.registered_trees["tree_name"]
```

## Registered Trees

The mod comes with these pre-registered trees:

- **Oak** - Standard balanced tree (5min growth, 1/8 chance)
- **Spruce** - Slightly slower growth (6min growth, 1/10 chance)  
- **Birch** - Fast growing (4min growth, 1/6 chance)
- **Jungle** - Large, slow growing (8min growth, 1/15 chance, rare saplings)
- **Acacia** - Unique branching shape (7min growth, 1/12 chance)
- **Dark Oak** - Very slow, thick trunk (10min growth, 1/20 chance)

## Block Naming Convention

All blocks follow this naming pattern:
- `vlf_trees:tree_name_log` - Main log block
- `vlf_trees:tree_name_log_stripped` - Stripped log variant
- `vlf_trees:tree_name_planks` - Planks
- `vlf_trees:tree_name_leaves` - Leaves
- `vlf_trees:tree_name_sapling` - Base sapling
- `vlf_trees:tree_name_young_sapling` - Growth stage 2
- `vlf_trees:tree_name_mature_sapling` - Growth stage 3
- `vlf_trees:tree_name_small_tree` - Growth stage 4
- `vlf_trees:tree_name_fence` - Fence
- `vlf_trees:tree_name_fence_gate` - Fence gate
- `vlf_trees:tree_name_door` - Door (craftitem)
- `vlf_trees:tree_name_trapdoor` - Trapdoor

## Crafting Recipes

Each tree automatically gets these recipes:
- Log → 4 Planks
- Stripped Log → 4 Planks  
- 2 Planks (vertical) → 4 Sticks
- Planks + Sticks → 3 Fences
- Sticks + Planks → 1 Fence Gate
- 6 Planks → 1 Door
- 6 Planks → 2 Trapdoors

## Configuration

Growth can be configured per tree type:
- `growth_time` - Base time between growth stages (seconds)
- `growth_chance` - Probability of growth per ABM cycle (1 in X)
- `sapling_rarity` - Probability of sapling drop from leaves (1 in X)

## Dependencies

- `vlf_blocks` - Required for basic blocks and materials
- `vlf_bonemeal` - Optional for bonemeal acceleration

## Compatibility

The API is designed to be compatible with:
- Leaf decay mods
- Bonemeal/fertilizer mods  
- Tree farming mods
- Decoration/building mods

## Texture Requirements

If providing custom textures, use these naming conventions:
- `vlf_trees_tree_name_log.png` - Log texture
- `vlf_trees_tree_name_log_stripped.png` - Stripped log texture
- `vlf_trees_tree_name_planks.png` - Planks texture
- `vlf_trees_tree_name_leaves.png` - Leaves texture
- `vlf_trees_tree_name_sapling.png` - Sapling texture
- `vlf_trees_tree_name_door.png` - Door texture
- `vlf_trees_tree_name_trapdoor.png` - Trapdoor texture
- `vlf_trees_tree_name_fence.png` - Fence inventory image
- `vlf_trees_tree_name_door_item.png` - Door inventory image