# VoxelGen Modding Guide
## The Complete Guide to Modding with VoxelGen - The Ultimate Luanti Mapgen

### Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Understanding VoxelGen Architecture](#understanding-voxelgen-architecture)
4. [Biome System](#biome-system)
5. [Ore Vein System](#ore-vein-system)
6. [Terrain Features System](#terrain-features-system)
7. [Climate System](#climate-system)
8. [API Reference](#api-reference)
9. [Advanced Topics](#advanced-topics)
10. [Examples and Tutorials](#examples-and-tutorials)
11. [Best Practices](#best-practices)
12. [Troubleshooting](#troubleshooting)

---

## Introduction

VoxelGen is the ultimate Luanti (formerly Minetest) mapgen system that powers VoxelForge Reimagined. It provides a comprehensive API for creating custom biomes, ore veins, terrain features, and climate systems. This guide will teach you everything you need to know to create amazing mods that integrate seamlessly with VoxelGen.

### What Makes VoxelGen Special?

- **41 Realistic Biomes**: Advanced climate-based biome system
- **Zero Dependencies**: Works completely standalone with built-in fallback nodes
- **Comprehensive API**: Full access to terrain generation, biomes, ores, and features
- **Minecraft-Style Terrain**: Familiar terrain generation with enhanced features
- **Advanced Cave Systems**: Sophisticated underground generation
- **Performance Optimized**: Efficient generation with caching and smooth transitions

### Prerequisites

- Basic knowledge of Lua programming
- Understanding of Luanti mod structure
- Familiarity with `mod.conf` and `init.lua` files
- Basic understanding of noise functions and terrain generation concepts

---

## Getting Started

### Setting Up Your Development Environment

1. **Install VoxelForge Reimagined**
   ```bash
   # Clone the game to your Luanti games directory
   cd ~/.minetest/games/
   git clone <repository-url> voxelforge-reimagined
   ```

2. **Create Your Mod Directory**
   ```bash
   cd voxelforge-reimagined/mods/
   mkdir your_mod_name
   cd your_mod_name
   ```

3. **Create Basic Mod Structure**
   ```
   your_mod_name/
   ├── mod.conf
   ├── init.lua
   ├── textures/
   ├── sounds/
   └── examples/
   ```

### Basic mod.conf

```ini
name = your_mod_name
title = Your Mod Title
description = Your mod description
author = YourName
version = 1.0.0
depends = voxelgen
optional_depends = vlf_blocks, vlf_biomes
```

### Basic init.lua Template

```lua
-- init.lua - Your VoxelGen Mod
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

-- Ensure VoxelGen is available
if not voxelgen then
    minetest.log("error", "[" .. modname .. "] VoxelGen not found! This mod requires VoxelGen.")
    return
end

-- Wait for all mods to load before registering content
minetest.register_on_mods_loaded(function()
    minetest.log("action", "[" .. modname .. "] Initializing...")
    
    -- Your mod initialization code here
    
    minetest.log("action", "[" .. modname .. "] Loaded successfully!")
end)
```

---

## Understanding VoxelGen Architecture

### Core Components

VoxelGen is organized into several key modules:

1. **API Module** (`voxelgen.api`): Core terrain generation functions
2. **Biomes Module** (`voxelgen.biomes`): Biome registration and management
3. **Climate Module** (`voxelgen.climate`): Temperature and humidity systems
4. **Ore Veins Module** (`voxelgen.ore_veins`): Ore generation system
5. **Terrain Features Module** (`voxelgen.terrain_features`): Surface features
6. **Caves Module** (`voxelgen.caves`): Underground generation
7. **HUD Module** (`voxelgen.hud`): Debug and information display

### Noise System

VoxelGen uses multiple noise layers for terrain generation:

- **Continental Noise**: Large-scale landmass shapes
- **Erosion Noise**: Valley and mountain formation
- **Peaks/Valleys (PV) Noise**: Local height variation
- **Weirdness Noise**: Unusual terrain formations
- **Heat/Humidity Noise**: Climate determination
- **Terrain Character Noise**: 3D terrain variation

### Coordinate System

- **Sea Level**: Y = 0 (configurable via `voxelgen.api.SEA_LEVEL`)
- **Cave Range**: Y = -60 to Y = 50 (configurable)
- **World Height**: Y = -50 to Y = 290 (typical range)

---

## Biome System

### Understanding Biome Parameters

VoxelGen uses a sophisticated biome selection system based on multiple parameters:

```lua
-- Biome parameters structure
{
    temperature_levels = {0, 1, 2, 3, 4}, -- 0=frozen, 4=hot
    humidity_levels = {0, 1, 2, 3, 4},    -- 0=arid, 4=humid
    continentalness_names = {"deep_ocean", "ocean", "coast", "near_inland", "mid_inland", "far_inland"},
    erosion_levels = {0, 1, 2, 3, 4, 5, 6}, -- 0=canyons, 6=peaks
    pv_names = {"valleys", "low", "mid", "high", "peaks"}, -- Peak/Valley variation
    depth_min = 0,     -- Minimum depth below surface
    depth_max = 50,    -- Maximum depth below surface
    y_min = -50,       -- Absolute minimum Y
    y_max = 290        -- Absolute maximum Y
}
```

### Creating a Custom Biome

#### Step 1: Define Biome Parameters

```lua
-- Create a tropical beach biome
local tropical_beach_params = {
    temperature_levels = {3, 4}, -- Hot temperatures only
    humidity_levels = {2, 3, 4}, -- Medium to high humidity
    continentalness_names = {"coast"}, -- Only coastal areas
    erosion_levels = {4, 5, 6}, -- Flat to slightly elevated
    pv_names = {"low", "mid"}, -- Low to medium elevation
    depth_min = 0,
    depth_max = 10, -- Very shallow depth
    y_min = -5,     -- Just below sea level
    y_max = 15      -- Just above sea level
}
```

#### Step 2: Define Biome Nodes

```lua
local tropical_beach_nodes = {
    node_top = "vlf_blocks:sand",           -- Surface block
    node_filler = "vlf_blocks:sand",        -- Subsurface block
    node_stone = "vlf_blocks:stone",        -- Deep stone
    node_water_top = "vlf_blocks:water",    -- Water surface
    node_water = "vlf_blocks:water",        -- Water body
    node_river_water = "vlf_blocks:water"   -- River water
}
```

#### Step 3: Define Biome Properties

```lua
local tropical_beach_properties = {
    depth_top = 3,        -- Thickness of top layer
    depth_filler = 8,     -- Thickness of filler layer
    depth_water_top = 1,  -- Thickness of water top layer
    priority = 15,        -- Higher priority = preferred when overlapping
    node_dust = "vlf_blocks:sand" -- Dust particles (optional)
}
```

#### Step 4: Create and Register the Biome

```lua
-- Create the biome definition
local tropical_beach = voxelgen.create_biome_def(
    "your_mod:tropical_beach",
    tropical_beach_params,
    tropical_beach_nodes,
    tropical_beach_properties
)

-- Register the biome
if tropical_beach then
    local success = voxelgen.register_biome(tropical_beach)
    if success then
        minetest.log("action", "[YourMod] Tropical beach biome registered successfully!")
    else
        minetest.log("error", "[YourMod] Failed to register tropical beach biome!")
    end
else
    minetest.log("error", "[YourMod] Failed to create tropical beach biome definition!")
end
```

### Advanced Biome Features

#### Temperature and Humidity Mapping

```lua
-- Temperature levels:
-- 0: Frozen (< -0.5)
-- 1: Cold (-0.5 to -0.15)
-- 2: Temperate (-0.15 to 0.2)
-- 3: Warm (0.2 to 0.55)
-- 4: Hot (> 0.55)

-- Humidity levels:
-- 0: Arid (< -0.35)
-- 1: Dry (-0.35 to -0.1)
-- 2: Neutral (-0.1 to 0.1)
-- 3: Humid (0.1 to 0.3)
-- 4: Very Humid (> 0.3)
```

#### Biome Validation

```lua
-- Check if a biome is registered
if voxelgen.is_biome_registered("your_mod:tropical_beach") then
    minetest.log("action", "Biome exists!")
end

-- Get all registered biomes
local all_biomes = voxelgen.get_registered_biomes()
for name, biome in pairs(all_biomes) do
    minetest.log("action", "Found biome: " .. name)
end
```

---

## Ore Vein System

VoxelGen provides a sophisticated ore generation system with multiple vein types and advanced placement controls.

### Ore Vein Types

1. **BLOB**: Irregular blob-like deposits
2. **STRATUS**: Horizontal layered deposits
3. **VEIN**: Linear vein deposits (vertical, horizontal, diagonal)
4. **SCATTER**: Randomly scattered individual nodes
5. **CLUSTER**: Small clustered deposits

### Basic Ore Vein Registration

```lua
-- Register a simple blob-type ore vein
voxelgen.register_ore_vein("your_mod:copper_ore", {
    ore_node = "vlf_blocks:stone_with_copper",  -- The ore to place
    wherein_node = "vlf_blocks:stone",          -- What to replace
    vein_type = voxelgen.ore_veins.VEIN_TYPES.BLOB,
    
    -- Blob-specific parameters
    blob_threshold = 0.15,  -- Lower = more common
    
    -- Y range
    y_min = -200,
    y_max = 50,
    
    -- Noise parameters
    noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 80, y = 80, z = 80},
        seed = 12345,
        octaves = 3,
        persist = 0.6,
        lacunarity = 2.0,
        flags = "defaults"
    }
})
```

### Advanced Ore Vein Features

#### Biome-Specific Ores

```lua
voxelgen.register_ore_vein("your_mod:desert_gold", {
    ore_node = "vlf_blocks:stone_with_gold",
    wherein_node = "vlf_blocks:stone",
    vein_type = voxelgen.ore_veins.VEIN_TYPES.VEIN,
    
    -- Only spawn in desert biomes
    biomes = {"desert", "desert_hills", "your_mod:tropical_beach"},
    
    -- Vein-specific parameters
    vein_direction = "diagonal",
    vein_thickness = 2,
    
    y_min = -300,
    y_max = 0,
    
    noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 120, y = 120, z = 120},
        seed = 54321,
        octaves = 2,
        persist = 0.7,
        lacunarity = 2.0,
        flags = "defaults"
    }
})
```

#### Depth-Based Restrictions

```lua
voxelgen.register_ore_vein("your_mod:deep_diamond", {
    ore_node = "vlf_blocks:stone_with_diamond",
    wherein_node = "vlf_blocks:stone",
    vein_type = voxelgen.ore_veins.VEIN_TYPES.SCATTER,
    
    -- Depth restrictions (distance from surface)
    depth_min = 200,  -- At least 200 blocks below surface
    depth_max = 500,  -- At most 500 blocks below surface
    
    -- Scatter-specific parameters
    clust_scarcity = 30 * 30 * 30,  -- Very rare
    
    y_min = -1000,
    y_max = -200,
    
    noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 200, y = 200, z = 200},
        seed = 98765,
        octaves = 4,
        persist = 0.8,
        lacunarity = 2.0,
        flags = "defaults"
    }
})
```

### Ore Vein Management

```lua
-- Check if an ore vein is registered
if voxelgen.is_ore_vein_registered("your_mod:copper_ore") then
    minetest.log("action", "Copper ore vein exists!")
end

-- Get ore vein information
local copper_info = voxelgen.get_ore_vein("your_mod:copper_ore")
if copper_info then
    minetest.log("action", "Copper ore: " .. copper_info.ore_node)
end

-- Get all registered ore veins
local all_veins = voxelgen.get_registered_ore_veins()
for name, vein in pairs(all_veins) do
    minetest.log("action", "Found ore vein: " .. name)
end
```

---

## Terrain Features System

Terrain features allow you to add surface decorations, structures, and other elements to the world.

### Feature Types

1. **block**: Single block placement
2. **function**: Custom placement function
3. **schematic**: Structure from schematic data

### Basic Block Feature

```lua
-- Register a simple flower feature
voxelgen.register_terrain_feature("your_mod:red_flowers", {
    type = "block",
    node = "your_mod:red_flower",
    biomes = {"plains", "grassland"},
    probability = 0.08, -- 8% chance when conditions are met
    min_height = 1,
    max_height = 100,
    avoid_water = true,
    need_solid_ground = true,
    place_on = {"vlf_blocks:dirt_with_grass", "vlf_blocks:dirt"},
    spacing = 3, -- Minimum blocks between features
    noise = {
        offset = 0,
        scale = 1,
        spread = {x = 25, y = 25, z = 25},
        seed = 11111,
        octaves = 2,
        persist = 0.5,
        lacunarity = 2.0
    }
})
```

### Function-Based Features

```lua
-- Custom tree placement function
local function place_custom_tree(x, y, z, data, area, biome_name, feature_def)
    local trunk_id = minetest.get_content_id("vlf_blocks:wood")
    local leaves_id = minetest.get_content_id("vlf_blocks:leaves")
    
    -- Place trunk (5 blocks high)
    for trunk_y = y, y + 4 do
        if area:contains(x, trunk_y, z) then
            local vi = area:index(x, trunk_y, z)
            data[vi] = trunk_id
        end
    end
    
    -- Place leaves (3x3x2 crown)
    for crown_y = y + 3, y + 4 do
        for dx = -1, 1 do
            for dz = -1, 1 do
                local leaf_x = x + dx
                local leaf_z = z + dz
                if area:contains(leaf_x, crown_y, leaf_z) then
                    local vi = area:index(leaf_x, crown_y, leaf_z)
                    data[vi] = leaves_id
                end
            end
        end
    end
    
    return true -- Successfully placed
end

-- Register the tree feature
voxelgen.register_terrain_feature("your_mod:custom_tree", {
    type = "function",
    place_function = place_custom_tree,
    biomes = {"forest", "plains"},
    probability = 0.03,
    min_height = 1,
    max_height = 80,
    avoid_water = true,
    need_solid_ground = true,
    place_on = "vlf_blocks:dirt_with_grass",
    spacing = 12,
    noise = {
        offset = 0,
        scale = 1,
        spread = {x = 60, y = 60, z = 60},
        seed = 22222,
        octaves = 3,
        persist = 0.6,
        lacunarity = 2.0
    }
})
```

### Schematic Features

```lua
-- Define a small structure
local watchtower = {
    {x = 0, y = 0, z = 0, node = "vlf_blocks:stone"},
    {x = 1, y = 0, z = 0, node = "vlf_blocks:stone"},
    {x = 0, y = 0, z = 1, node = "vlf_blocks:stone"},
    {x = 1, y = 0, z = 1, node = "vlf_blocks:stone"},
    {x = 0, y = 1, z = 0, node = "vlf_blocks:stone"},
    {x = 1, y = 1, z = 0, node = "vlf_blocks:stone"},
    {x = 0, y = 1, z = 1, node = "vlf_blocks:stone"},
    {x = 1, y = 1, z = 1, node = "vlf_blocks:stone"},
    {x = 0, y = 2, z = 0, node = "vlf_blocks:wood"},
    {x = 1, y = 2, z = 1, node = "vlf_blocks:wood"},
}

-- Register the structure
voxelgen.register_terrain_feature("your_mod:watchtower", {
    type = "schematic",
    schematic = watchtower,
    biomes = {"*"}, -- All biomes
    probability = 0.002, -- Very rare
    min_height = 1,
    max_height = 50,
    avoid_water = true,
    need_solid_ground = true,
    place_on = {"vlf_blocks:stone", "vlf_blocks:dirt", "vlf_blocks:sand"},
    spacing = 50,
    noise = {
        offset = 0,
        scale = 1,
        spread = {x = 300, y = 300, z = 300},
        seed = 33333,
        octaves = 4,
        persist = 0.7,
        lacunarity = 2.0
    }
})
```

---

## Climate System

### Understanding Climate

VoxelGen's climate system determines biome placement based on:

- **Temperature**: Affected by latitude, altitude, and local variation
- **Humidity**: Affected by distance from water and local weather patterns
- **Climate Types**: Combinations of temperature and humidity

### Getting Climate Information

```lua
-- Get climate at a specific position
local climate = voxelgen.get_climate_at(x, z, y)
minetest.log("action", "Temperature: " .. climate.temperature)
minetest.log("action", "Humidity: " .. climate.humidity)
minetest.log("action", "Climate type: " .. climate.climate_type)

-- Get just temperature
local temp = voxelgen.climate.get_temperature(x, z, y, terrain_height)

-- Get just humidity
local humidity = voxelgen.climate.get_humidity(x, z, y, terrain_height)
```

### Climate-Based Features

```lua
-- Register a feature that only appears in cold climates
voxelgen.register_terrain_feature("your_mod:ice_crystal", {
    type = "block",
    node = "your_mod:ice_crystal",
    biomes = {"*"}, -- Check all biomes
    probability = 0.05,
    min_height = 1,
    max_height = 200,
    avoid_water = true,
    need_solid_ground = true,
    place_on = {"vlf_blocks:stone", "vlf_blocks:dirt"},
    spacing = 5,
    
    -- Custom placement check
    can_place = function(x, y, z, biome_name)
        local climate = voxelgen.get_climate_at(x, z, y)
        return climate.temperature < -0.3 -- Only in very cold areas
    end,
    
    noise = {
        offset = 0,
        scale = 1,
        spread = {x = 40, y = 40, z = 40},
        seed = 44444,
        octaves = 2,
        persist = 0.5,
        lacunarity = 2.0
    }
})
```

---

## API Reference

### Core API Functions

#### Terrain Information

```lua
-- Get terrain height at position
local height = voxelgen.get_terrain_height_at(x, z)

-- Get heightmap for an area
local heightmap = voxelgen.get_heightmap_area(minp, maxp)

-- Get biome at position
local biome = voxelgen.get_biome_at(x, y, z, terrain_height)
```

#### Biome Management

```lua
-- Create biome definition
local biome_def = voxelgen.create_biome_def(name, parameters, nodes, properties)

-- Register biome
local success = voxelgen.register_biome(biome_def)

-- Check if biome exists
local exists = voxelgen.is_biome_registered(biome_name)

-- Get all biomes
local biomes = voxelgen.get_registered_biomes()
```

#### Ore Vein Management

```lua
-- Register ore vein
local success = voxelgen.register_ore_vein(name, definition)

-- Check if ore vein exists
local exists = voxelgen.is_ore_vein_registered(vein_name)

-- Get ore vein info
local vein_info = voxelgen.get_ore_vein(name)

-- Get all ore veins
local veins = voxelgen.get_registered_ore_veins()
```

#### Terrain Features Management

```lua
-- Register terrain feature
local success = voxelgen.register_terrain_feature(name, definition)

-- Get all features
local features = voxelgen.get_registered_terrain_features()

-- Get feature statistics
local stats = voxelgen.get_terrain_feature_statistics()
```

### Configuration API

```lua
-- Configure cave system
voxelgen.configure("caves", "density.scale", 1.2)

-- Configure climate system
voxelgen.configure("climate", "temperature.offset", 0.1)
```

### Noise API

```lua
-- Access noise parameters
local noise_params = voxelgen.api.noise_params.continental

-- Get spline definitions
local splines = voxelgen.api.splines.continentalness

-- Constants
local sea_level = voxelgen.api.SEA_LEVEL
local min_cave_y = voxelgen.api.MIN_CAVE_Y
local max_cave_y = voxelgen.api.MAX_CAVE_Y
```

---

## Advanced Topics

### Custom Noise Functions

```lua
-- Create custom noise for your features
local function create_custom_noise(world_seed)
    local noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 100, y = 100, z = 100},
        seed = world_seed + 12345,
        octaves = 3,
        persist = 0.6,
        lacunarity = 2.0,
        flags = "defaults"
    }
    return minetest.get_perlin(noise_params)
end

-- Use in terrain feature
local custom_noise = create_custom_noise(12345)
local noise_value = custom_noise:get_2d({x = x, y = z})
```

### Biome Transitions

```lua
-- Create smooth biome transitions
local function create_transition_biome(base_biome, transition_biome, blend_factor)
    return {
        name = base_biome.name .. "_transition",
        parameters = base_biome.parameters,
        nodes = {
            node_top = blend_factor > 0.5 and base_biome.nodes.node_top or transition_biome.nodes.node_top,
            node_filler = base_biome.nodes.node_filler,
            node_stone = base_biome.nodes.node_stone
        },
        properties = base_biome.properties
    }
end
```

### Performance Optimization

```lua
-- Cache expensive calculations
local height_cache = {}
local function get_cached_height(x, z)
    local key = x .. "," .. z
    if not height_cache[key] then
        height_cache[key] = voxelgen.get_terrain_height_at(x, z)
    end
    return height_cache[key]
end

-- Clear cache periodically
minetest.register_globalstep(function(dtime)
    if math.random() < 0.01 then -- 1% chance per step
        height_cache = {}
    end
end)
```

### Integration with Other Mods

```lua
-- Check for mod compatibility
if minetest.get_modpath("farming") then
    -- Register crops that work with VoxelGen biomes
    voxelgen.register_terrain_feature("your_mod:wild_wheat", {
        type = "block",
        node = "farming:wheat_1",
        biomes = {"plains", "grassland"},
        probability = 0.02,
        -- ... other parameters
    })
end

-- Depend on specific mods
if minetest.get_modpath("vlf_blocks") then
    -- Use VLF blocks in your biomes
else
    -- Fallback to default nodes
    minetest.log("warning", "[YourMod] vlf_blocks not found, using fallback nodes")
end
```

---

## Examples and Tutorials

### Tutorial 1: Creating a Volcanic Biome

```lua
-- Step 1: Define the biome parameters
local volcanic_params = {
    temperature_levels = {4}, -- Very hot
    humidity_levels = {0, 1}, -- Dry
    continentalness_names = {"mid_inland", "far_inland"},
    erosion_levels = {0, 1, 2}, -- Mountainous
    pv_names = {"peaks", "high"},
    depth_min = 0,
    depth_max = 20,
    y_min = 50,
    y_max = 200
}

-- Step 2: Define volcanic nodes
local volcanic_nodes = {
    node_top = "vlf_blocks:stone", -- Volcanic rock
    node_filler = "vlf_blocks:stone",
    node_stone = "vlf_blocks:stone"
}

-- Step 3: Define properties
local volcanic_properties = {
    depth_top = 1,
    depth_filler = 5,
    priority = 20, -- High priority
    node_dust = "vlf_blocks:sand" -- Ash particles
}

-- Step 4: Create and register
local volcanic_biome = voxelgen.create_biome_def(
    "your_mod:volcanic",
    volcanic_params,
    volcanic_nodes,
    volcanic_properties
)

if volcanic_biome then
    voxelgen.register_biome(volcanic_biome)
end

-- Step 5: Add volcanic features
voxelgen.register_terrain_feature("your_mod:lava_pool", {
    type = "function",
    place_function = function(x, y, z, data, area, biome_name, feature_def)
        -- Create small lava pools
        local lava_id = minetest.get_content_id("vlf_blocks:lava")
        for dx = -1, 1 do
            for dz = -1, 1 do
                if area:contains(x + dx, y, z + dz) then
                    local vi = area:index(x + dx, y, z + dz)
                    data[vi] = lava_id
                end
            end
        end
        return true
    end,
    biomes = {"your_mod:volcanic"},
    probability = 0.01,
    min_height = 50,
    max_height = 200,
    avoid_water = true,
    need_solid_ground = true,
    place_on = "vlf_blocks:stone",
    spacing = 20,
    noise = {
        offset = 0,
        scale = 1,
        spread = {x = 80, y = 80, z = 80},
        seed = 55555,
        octaves = 2,
        persist = 0.7,
        lacunarity = 2.0
    }
})

-- Step 6: Add volcanic ores
voxelgen.register_ore_vein("your_mod:volcanic_gold", {
    ore_node = "vlf_blocks:stone_with_gold",
    wherein_node = "vlf_blocks:stone",
    vein_type = voxelgen.ore_veins.VEIN_TYPES.VEIN,
    biomes = {"your_mod:volcanic"},
    vein_direction = "vertical",
    vein_thickness = 3,
    y_min = 0,
    y_max = 200,
    noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 60, y = 60, z = 60},
        seed = 66666,
        octaves = 2,
        persist = 0.8,
        lacunarity = 2.0,
        flags = "defaults"
    }
})
```

### Tutorial 2: Creating a Mushroom Forest

```lua
-- Giant mushroom placement function
local function place_giant_mushroom(x, y, z, data, area, biome_name, feature_def)
    local stem_id = minetest.get_content_id("vlf_blocks:wood")
    local cap_id = minetest.get_content_id("vlf_blocks:leaves")
    
    -- Mushroom stem (8 blocks high)
    for stem_y = y, y + 7 do
        if area:contains(x, stem_y, z) then
            local vi = area:index(x, stem_y, z)
            data[vi] = stem_id
        end
    end
    
    -- Mushroom cap (5x5 at top)
    local cap_y = y + 8
    for dx = -2, 2 do
        for dz = -2, 2 do
            local cap_x = x + dx
            local cap_z = z + dz
            -- Skip corners for round shape
            if math.abs(dx) + math.abs(dz) <= 3 then
                if area:contains(cap_x, cap_y, cap_z) then
                    local vi = area:index(cap_x, cap_y, cap_z)
                    data[vi] = cap_id
                end
            end
        end
    end
    
    return true
end

-- Register mushroom forest biome
local mushroom_forest = voxelgen.create_biome_def(
    "your_mod:mushroom_forest",
    {
        temperature_levels = {1, 2}, -- Cool to temperate
        humidity_levels = {3, 4}, -- Very humid
        continentalness_names = {"near_inland", "mid_inland"},
        erosion_levels = {3, 4, 5}, -- Relatively flat
        pv_names = {"low", "mid"},
        depth_min = 0,
        depth_max = 30,
        y_min = 1,
        y_max = 80
    },
    {
        node_top = "vlf_blocks:dirt", -- Rich soil
        node_filler = "vlf_blocks:dirt",
        node_stone = "vlf_blocks:stone"
    },
    {
        depth_top = 2,
        depth_filler = 6,
        priority = 12
    }
)

voxelgen.register_biome(mushroom_forest)

-- Register giant mushrooms
voxelgen.register_terrain_feature("your_mod:giant_mushroom", {
    type = "function",
    place_function = place_giant_mushroom,
    biomes = {"your_mod:mushroom_forest"},
    probability = 0.15, -- Common in mushroom forests
    min_height = 1,
    max_height = 80,
    avoid_water = true,
    need_solid_ground = true,
    place_on = "vlf_blocks:dirt",
    spacing = 8,
    noise = {
        offset = 0,
        scale = 1,
        spread = {x = 30, y = 30, z = 30},
        seed = 77777,
        octaves = 2,
        persist = 0.6,
        lacunarity = 2.0
    }
})

-- Small mushrooms
voxelgen.register_terrain_feature("your_mod:small_mushroom", {
    type = "block",
    node = "vlf_blocks:leaves", -- Using leaves as mushroom
    biomes = {"your_mod:mushroom_forest"},
    probability = 0.3,
    min_height = 1,
    max_height = 80,
    avoid_water = true,
    need_solid_ground = true,
    place_on = "vlf_blocks:dirt",
    spacing = 2,
    noise = {
        offset = 0,
        scale = 1,
        spread = {x = 15, y = 15, z = 15},
        seed = 88888,
        octaves = 1,
        persist = 0.5,
        lacunarity = 2.0
    }
})
```

---

## Best Practices

### 1. Mod Organization

```lua
-- Organize your mod with clear structure
your_mod/
├── mod.conf
├── init.lua
├── biomes.lua      -- Biome definitions
├── ores.lua        -- Ore vein definitions
├── features.lua    -- Terrain features
├── nodes.lua       -- Custom nodes
├── crafting.lua    -- Recipes
├── textures/
└── sounds/
```

### 2. Error Handling

```lua
-- Always check if VoxelGen is available
if not voxelgen then
    minetest.log("error", "[YourMod] VoxelGen not found!")
    return
end

-- Validate biome creation
local biome_def = voxelgen.create_biome_def(name, params, nodes, props)
if not biome_def then
    minetest.log("error", "[YourMod] Failed to create biome: " .. name)
    return
end

-- Check registration success
local success = voxelgen.register_biome(biome_def)
if not success then
    minetest.log("error", "[YourMod] Failed to register biome: " .. name)
end
```

### 3. Performance Considerations

```lua
-- Use appropriate noise spreads
-- Smaller spreads = more detailed but slower
-- Larger spreads = less detailed but faster

-- Good for small features
spread = {x = 20, y = 20, z = 20}

-- Good for large features
spread = {x = 200, y = 200, z = 200}

-- Limit feature density
probability = 0.05 -- 5% is often enough

-- Use appropriate spacing
spacing = 10 -- Prevents overcrowding
```

### 4. Biome Balance

```lua
-- Don't make biomes too restrictive
temperature_levels = {2, 3} -- Good range
temperature_levels = {2}    -- Too restrictive

-- Use appropriate priorities
priority = 10 -- Standard biome
priority = 20 -- Important biome
priority = 5  -- Background biome

-- Consider biome transitions
-- Adjacent biomes should have overlapping parameters
```

### 5. Testing and Debugging

```lua
-- Add debug logging
minetest.log("action", "[YourMod] Registering biome: " .. name)

-- Use debug commands
minetest.register_chatcommand("your_mod_info", {
    description = "Show mod information",
    func = function(name)
        local stats = voxelgen.get_terrain_feature_statistics()
        return true, "Features: " .. stats.total_features
    end,
})

-- Test in different biomes
-- Use /teleport to visit different areas
-- Check generation at different Y levels
```

---

## Troubleshooting

### Common Issues

#### 1. Biome Not Appearing

**Problem**: Your biome doesn't generate in the world.

**Solutions**:
- Check parameter ranges aren't too restrictive
- Verify biome priority isn't too low
- Ensure temperature/humidity ranges are reasonable
- Check Y range includes areas above sea level

```lua
-- Too restrictive (bad)
temperature_levels = {3.5}
humidity_levels = {2.1}

-- Better range
temperature_levels = {3, 4}
humidity_levels = {2, 3}
```

#### 2. Features Not Placing

**Problem**: Terrain features don't appear.

**Solutions**:
- Check `place_on` node names are correct
- Verify biome names match registered biomes
- Adjust probability (might be too low)
- Check spacing isn't too large

```lua
-- Check node names
place_on = {"vlf_blocks:dirt_with_grass"} -- Correct
place_on = {"default:dirt_with_grass"}    -- Wrong mod prefix
```

#### 3. Ore Veins Not Generating

**Problem**: Ore veins don't appear underground.

**Solutions**:
- Check Y range includes underground areas
- Verify `wherein_node` exists
- Adjust noise parameters
- Check biome restrictions

```lua
-- Good Y range for underground ores
y_min = -200
y_max = 50

-- Bad Y range (too high)
y_min = 50
y_max = 100
```

#### 4. Performance Issues

**Problem**: World generation is slow.

**Solutions**:
- Reduce feature density
- Increase noise spread values
- Reduce octave count
- Optimize placement functions

```lua
-- Optimize placement functions
local function optimized_placement(x, y, z, data, area, biome_name, feature_def)
    -- Cache content IDs
    local node_id = feature_def.cached_node_id or minetest.get_content_id(feature_def.node)
    feature_def.cached_node_id = node_id
    
    -- Use area:contains() before area:index()
    if area:contains(x, y, z) then
        local vi = area:index(x, y, z)
        data[vi] = node_id
    end
    
    return true
end
```

### Debug Commands

```lua
-- Add these to your mod for debugging
minetest.register_chatcommand("biome_here", {
    description = "Show current biome",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        local pos = player:get_pos()
        local biome = voxelgen.get_biome_at(pos.x, pos.y, pos.z)
        return true, "Current biome: " .. (biome or "unknown")
    end,
})

minetest.register_chatcommand("climate_here", {
    description = "Show current climate",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        local pos = player:get_pos()
        local climate = voxelgen.get_climate_at(pos.x, pos.z, pos.y)
        return true, string.format("Temperature: %.2f, Humidity: %.2f, Type: %s",
            climate.temperature, climate.humidity, climate.climate_type)
    end,
})
```

### Logging Best Practices

```lua
-- Use appropriate log levels
minetest.log("action", "[YourMod] Normal operation")
minetest.log("warning", "[YourMod] Something unusual happened")
minetest.log("error", "[YourMod] Something failed")

-- Include context in error messages
minetest.log("error", "[YourMod] Failed to register biome '" .. name .. "': invalid parameters")

-- Log statistics
local stats = voxelgen.get_terrain_feature_statistics()
minetest.log("action", "[YourMod] Registered " .. stats.total_features .. " terrain features")
```

---

## Conclusion

VoxelGen provides a powerful and flexible system for creating amazing terrain, biomes, and features in Luanti. This guide has covered the essential concepts and provided practical examples to get you started.

### Next Steps

1. **Start Small**: Begin with simple biomes and features
2. **Experiment**: Try different parameter combinations
3. **Test Thoroughly**: Generate worlds and explore your creations
4. **Optimize**: Profile your code and optimize for performance
5. **Share**: Contribute your creations to the community

### Resources

- **VoxelGen Source**: Study the source code for advanced techniques
- **Example Mods**: Look at existing VoxelForge mods for inspiration
- **Community**: Join the VoxelForge community for support and ideas
- **Documentation**: Keep this guide handy for reference

### Contributing

If you create amazing biomes, features, or improvements to VoxelGen, consider contributing them back to the project. The VoxelForge community welcomes contributions that enhance the game for everyone.

Happy modding!

---

*This guide covers VoxelGen version 1.0.0. Check for updates and new features in future versions.*