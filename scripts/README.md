# VoxelForge Reimagined - Development Scripts

This directory contains Python scripts for generating pixel art textures and setting up the game according to the development roadmap.

## Scripts

### `setup_phase1.py` - Complete Phase 1 Setup
The main script that sets up everything needed for Phase 1 of the roadmap.

**Usage:**
```bash
cd scripts
python setup_phase1.py
```

**What it does:**
- Installs required dependencies (Pillow)
- Generates all Phase 1 textures (blocks, items, tools, stations)
- Creates the VoxelForge Core mod structure
- Sets up basic nodes, items, tools, and crafting recipes
- Implements XP and leveling system

### `generate_textures.py` - Block and Item Textures
Generates pixel art textures for terrain blocks, tools, and materials.

**Usage:**
```bash
python generate_textures.py --phase 1
```

**Features:**
- 16x16 pixel art textures
- Material-based color palettes
- Procedural patterns for different block types
- Tool shapes with proper materials
- Ore lumps and ingots

### `generate_stations.py` - Crafting Station Textures
Generates textures for crafting tables, forges, and cooking stoves.

**Usage:**
```bash
python generate_stations.py
```

**Generated textures:**
- Crafting table (top and sides)
- Forge (main and front with fire)
- Cooking stove (top and front)

## Requirements

- Python 3.7+
- Pillow (PIL) library

Install requirements:
```bash
pip install -r requirements.txt
```

## Output Structure

```
textures/
├── blocks/          # Terrain block textures
├── items/           # Tool and item textures
└── stations/        # Crafting station textures

mods/
└── voxelforge_core/ # Generated mod
    ├── mod.conf
    ├── init.lua
    ├── textures/    # Copied textures
    ├── nodes/       # Node definitions
    ├── items/       # Item definitions
    ├── tools/       # Tool definitions
    └── crafting/    # Recipe definitions
```

## Phase 1 Features

The generated mod includes:

### Terrain Blocks
- Stone, Dirt, Wood, Planks
- Iron Ore, Copper Ore, Coal Ore

### Tools & Items
- Wooden, Stone, and Iron tool sets
- Raw ore lumps and smelted ingots

### Crafting Stations
- Crafting Table (enhanced crafting)
- Forge (future advanced crafting)
- Cooking Stove (future cooking system)

### Player Progression
- XP system with tool usage rewards
- Level progression (100 XP per level)
- Level-gated crafting recipes

## Next Steps

After running Phase 1 setup:

1. Start Minetest
2. Create a new world with VoxelForge Reimagined
3. Enable the "VoxelForge Core" mod
4. Test the progression system by mining and crafting
5. Reach Level 2 to complete the Phase 1 milestone

## Development Notes

- All textures are 16x16 pixels for Minetest compatibility
- Color palettes are designed for consistency
- XP rewards encourage tool usage and progression
- Mod structure supports easy expansion for future phases