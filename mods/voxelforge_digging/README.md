# VoxelForge Digging Speed System

This mod implements a simple digging speed system where the relationship between tool strength and material hardness determines how fast blocks can be dug.

## How It Works

This system adjusts digging speeds based on tool effectiveness against different materials, while leaving all other game mechanics (tool durability, drops, etc.) to the default Minetest systems.

### Material Hardness
Each block has a hardness value that determines how difficult it is to break:

- **Soft Materials (1-2)**: Dirt, grass, sand, gravel
- **Wood Materials (3)**: Wood, planks, leaves  
- **Stone Materials (4-5)**: Stone, cobblestone
- **Ore Materials (6-8)**: Coal ore, copper ore, iron ore
- **Very Hard Materials (12+)**: Obsidian, bedrock

### Tool Strength
Each tool has a strength value that determines its digging power:

- **Hand (1)**: Very weak, only good for soft materials
- **Wooden Tools (2)**: Basic tools for early game
- **Stone Tools (4)**: Decent mid-tier tools
- **Iron Tools (7)**: Strong tools for most materials
- **Diamond Tools (10)**: Powerful end-game tools

### Digging Speed Calculation

**Digging Speed**: Calculated as `material_hardness / (tool_strength * effectiveness)`
- Stronger tools dig faster
- Harder materials take longer
- Right tool for the job matters significantly

### Tool Effectiveness

Different tools have different effectiveness against different materials:

- **Pickaxes**: 
  - Stone/Ore: 100% effectiveness (best choice)
  - Wood: 60% effectiveness  
  - Dirt/Sand: 70-80% effectiveness
  - Other: 50% effectiveness

- **Axes**: 
  - Wood/Leaves: 100% effectiveness (best choice)
  - Stone/Ore: 30-40% effectiveness
  - Dirt/Sand: 50-60% effectiveness
  - Other: 40% effectiveness

- **Shovels**: 
  - Dirt/Sand/Gravel: 100% effectiveness (best choice)
  - Stone/Ore: 20-30% effectiveness
  - Wood: 50% effectiveness
  - Other: 40% effectiveness

- **Hand**: 
  - Soft materials: 80-90% effectiveness
  - Hard materials: 5-20% effectiveness

## API Functions

The mod provides several API functions for other mods:

```lua
-- Get material hardness
local hardness = voxelforge_digging.get_material_hardness(node_name)

-- Get tool strength
local strength = voxelforge_digging.get_tool_strength(tool_name)

-- Calculate dig time
local time = voxelforge_digging.calculate_dig_time(tool_name, node_name)
```

## Chat Commands

- `/diginfo` - Get information about the block you're looking at, including:
  - Material hardness
  - Your current tool strength
  - Estimated dig time

## Examples

### Scenario 1: Iron Pickaxe vs Stone
- Stone hardness: 5
- Iron pickaxe strength: 7
- Effectiveness: 100% (pickaxe on stone)
- Result: Fast digging (5 / (7 * 1.0) = ~0.7 seconds)

### Scenario 2: Wooden Axe vs Iron Ore
- Iron ore hardness: 8
- Wooden axe strength: 2
- Effectiveness: 30% (axe on ore)
- Result: Very slow digging (8 / (2 * 0.3) = ~13 seconds)

### Scenario 3: Iron Shovel vs Dirt
- Dirt hardness: 1
- Iron shovel strength: 7
- Effectiveness: 100% (shovel on dirt)
- Result: Very fast digging (1 / (7 * 1.0) = ~0.1 seconds)

## Configuration

The hardness and strength values can be modified in the `init.lua` file:
- `voxelforge_digging.material_hardness` - Block hardness values
- `voxelforge_digging.tool_strength` - Tool strength values
- `voxelforge_digging.tool_effectiveness` - Tool effectiveness multipliers

## Integration

This mod automatically works with any blocks that have the `voxelforge_material` group. It adjusts only the digging speed - all other mechanics like tool durability, drops, and crafting remain unchanged from the default Minetest behavior.

The system encourages:
- Using the right tool for the job (faster digging)
- Progressing through tool tiers (access to harder materials)
- Strategic tool selection based on the task