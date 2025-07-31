# VLF Trees API Reference

## Core Functions

### `vlf_trees.register_tree(tree_name, tree_def)`

Registers a complete tree set with all associated blocks and items.

**Parameters:**
- `tree_name` (string): Unique identifier for the tree type
- `tree_def` (table): Tree definition table (see Tree Definition Structure)

**Returns:** None

**Example:**
```lua
vlf_trees.register_tree("oak", {
    description = "Oak",
    wood_description = "Oak Log",
    planks_description = "Oak Planks",
    leaves_description = "Oak Leaves",
    sapling_description = "Oak Sapling",
})
```

### `vlf_trees.grow_tree(pos, tree_name)`

Grows a tree at the specified position.

**Parameters:**
- `pos` (table): Position table {x, y, z}
- `tree_name` (string): Name of registered tree type

**Returns:** 
- `true` if tree was successfully grown
- `false` if growth failed (insufficient space, etc.)

**Example:**
```lua
local success = vlf_trees.grow_tree({x=0, y=0, z=0}, "oak")
```

### `vlf_trees.register_tree_recipes(tree_name)`

Registers standard crafting recipes for a tree type. Called automatically by `register_tree()`.

**Parameters:**
- `tree_name` (string): Name of registered tree type

**Returns:** None

## Tree Definition Structure

```lua
{
    -- Basic descriptions
    description = "Tree Name",
    wood_description = "Tree Name Log", 
    planks_description = "Tree Name Planks",
    leaves_description = "Tree Name Leaves",
    sapling_description = "Tree Name Sapling",
    
    -- Texture paths (optional - auto-generated if not provided)
    wood_texture = "texture_path.png",
    planks_texture = "texture_path.png",
    leaves_texture = "texture_path.png", 
    sapling_texture = "texture_path.png",
    stripped_log_texture = "texture_path.png",
    
    -- Growth properties
    growth_time = 300,        -- Base growth time in seconds
    growth_chance = 10,       -- 1 in X chance per ABM cycle
    sapling_rarity = 20,      -- 1 in X chance to drop from leaves
    
    -- Node groups (optional - uses defaults if not provided)
    wood_groups = {choppy = 2, flammable = 3, wood = 1, tree = 1},
    planks_groups = {choppy = 3, flammable = 3, wood = 1},
    leaves_groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1},
    sapling_groups = {snappy = 3, flammable = 2, attached_node = 1, sapling = 1},
    
    -- Sound definitions (optional)
    wood_sounds = sound_table,
    planks_sounds = sound_table,
    leaves_sounds = sound_table,
    sapling_sounds = sound_table,
    
    -- Custom tree generation (optional)
    tree_generator = function(pos, tree_name, tree_def)
        -- Custom generation logic
        -- Return true if successful, false if failed
    end,
    
    -- Custom schematic file (optional, alternative to tree_generator)
    tree_schematic = "path/to/schematic.mts",
}
```

## Global Variables

### `vlf_trees.registered_trees`

Table containing all registered tree definitions, indexed by tree name.

**Example:**
```lua
local oak_def = vlf_trees.registered_trees["oak"]
print(oak_def.description) -- "Oak"
```

### `vlf_trees.growth_stages`

Array of growth stage names for saplings:
```lua
{
    "sapling",
    "young_sapling", 
    "mature_sapling",
    "small_tree",
    "tree"
}
```

## Node Metadata

Sapling nodes include special metadata for growth tracking:

- `_vlf_trees_stage` (number): Current growth stage (1-5)
- `_vlf_trees_tree_name` (string): Tree type name
- `_vlf_trees_next_stage` (string): Next growth stage node name
- `_vlf_trees_bonemeal_speedup` (function): Bonemeal acceleration function

## ABM Configuration

The growth ABM runs with these parameters:
- **Label:** "VLF Trees sapling growth"
- **Nodenames:** {"group:sapling"}
- **Neighbors:** {"group:soil", "vlf_blocks:dirt", "vlf_blocks:dirt_with_grass"}
- **Interval:** 30 seconds
- **Chance:** 10 (base chance, modified by tree-specific settings)

## Block Naming Convention

All generated blocks follow this pattern:
- `vlf_trees:{tree_name}_log`
- `vlf_trees:{tree_name}_log_stripped`
- `vlf_trees:{tree_name}_planks`
- `vlf_trees:{tree_name}_leaves`
- `vlf_trees:{tree_name}_sapling`
- `vlf_trees:{tree_name}_young_sapling`
- `vlf_trees:{tree_name}_mature_sapling`
- `vlf_trees:{tree_name}_small_tree`
- `vlf_trees:{tree_name}_fence`
- `vlf_trees:{tree_name}_fence_gate`
- `vlf_trees:{tree_name}_fence_gate_open`
- `vlf_trees:{tree_name}_door` (craftitem)
- `vlf_trees:{tree_name}_door_b` (bottom closed)
- `vlf_trees:{tree_name}_door_t` (top closed)
- `vlf_trees:{tree_name}_door_b_open` (bottom open)
- `vlf_trees:{tree_name}_door_t_open` (top open)
- `vlf_trees:{tree_name}_trapdoor`
- `vlf_trees:{tree_name}_trapdoor_open`

## Integration Points

### Bonemeal Support

If `vlf_bonemeal` mod is detected, saplings automatically support bonemeal acceleration:

```lua
if minetest.get_modpath("vlf_bonemeal") then
    vlf_bonemeal.register_on_use(function(pos, node, player)
        local node_def = minetest.registered_nodes[node.name]
        if node_def and node_def._vlf_trees_bonemeal_speedup then
            return node_def._vlf_trees_bonemeal_speedup(pos)
        end
        return false
    end)
end
```

### Leaf Decay

Leaves automatically participate in leaf decay systems through the `leafdecay` group.

### Tree Farming

All saplings are in the `sapling` group for compatibility with farming mods.

## Error Handling

The API includes error checking for:
- Invalid tree names
- Missing tree definitions
- Insufficient space for tree growth
- Invalid growth stages
- Missing textures (falls back to auto-generated names)

## Performance Considerations

- ABM runs every 30 seconds with configurable chance
- Tree generation checks for space before placing blocks
- Growth stages prevent instant tree growth
- Bonemeal provides controlled acceleration without bypassing all stages