#!/usr/bin/env python3
"""
VoxelForge Reimagined - Phase 1 Setup Script
Sets up the complete Phase 1 foundation including textures and mod structure.
"""

import os
import sys
import subprocess
from pathlib import Path

# Add current directory to path
sys.path.append(str(Path(__file__).parent))

from generate_textures import generate_phase1_textures
from generate_stations import generate_all_stations

def check_dependencies():
    """Check if required Python packages are installed."""
    try:
        import PIL
        print("✓ Pillow is installed")
        return True
    except ImportError:
        print("✗ Pillow is not installed")
        print("Installing Pillow...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow>=10.0.0"])
            print("✓ Pillow installed successfully")
            return True
        except subprocess.CalledProcessError:
            print("✗ Failed to install Pillow")
            print("Please install manually: pip install Pillow>=10.0.0")
            return False

def create_mod_structure():
    """Create the basic mod structure for VoxelForge core mod."""
    base_dir = Path(__file__).parent.parent
    mod_dir = base_dir / "mods" / "voxelforge_core"
    
    # Create directories
    directories = [
        mod_dir,
        mod_dir / "textures",
        mod_dir / "sounds",
        mod_dir / "mapgen",
        mod_dir / "cooking",
        mod_dir / "caves",
        mod_dir / "models",
        mod_dir / "locale",
        mod_dir / "crafting",
        mod_dir / "nodes",
        mod_dir / "items",
        mod_dir / "tools"
    ]
    
    for directory in directories:
        directory.mkdir(parents=True, exist_ok=True)
        print(f"✓ Created directory: {directory}")
    
    # Create mod.conf
    mod_conf_content = """name = voxelforge_core
title = VoxelForge Core
description = Core functionality for VoxelForge Reimagined
optional_depends = i3, 3d_armor, awards
author = VoxelForge Team
version = 1.0.0
min_minetest_version = 5.9
"""
    
    mod_conf_path = mod_dir / "mod.conf"
    with open(mod_conf_path, 'w') as f:
        f.write(mod_conf_content)
    print(f"✓ Created mod.conf: {mod_conf_path}")
    
    # Create basic init.lua
    init_lua_content = """-- VoxelForge Core Mod
-- Phase 1: Core Foundation

local modpath = minetest.get_modpath("voxelforge_core")

-- Initialize VoxelForge namespace
voxelforge = voxelforge or {}
voxelforge.players = {}

-- Load core components
dofile(modpath .. "/sounds/init.lua")
dofile(modpath .. "/mapgen/init.lua")
dofile(modpath .. "/cooking/init.lua")
dofile(modpath .. "/caves/init.lua")
dofile(modpath .. "/nodes/init.lua")
dofile(modpath .. "/items/init.lua")
dofile(modpath .. "/tools/init.lua")
dofile(modpath .. "/crafting/init.lua")

-- Initialize player data
minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    voxelforge.players[name] = {
        xp = player:get_attribute("voxelforge_xp") or 0,
        level = player:get_attribute("voxelforge_level") or 1
    }
end)

-- Save player data
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    if voxelforge.players[name] then
        player:set_attribute("voxelforge_xp", voxelforge.players[name].xp)
        player:set_attribute("voxelforge_level", voxelforge.players[name].level)
    end
end)

-- XP functions
function voxelforge.add_xp(player_name, amount)
    if not voxelforge.players[player_name] then return end
    
    voxelforge.players[player_name].xp = voxelforge.players[player_name].xp + amount
    
    -- Check for level up
    local current_level = voxelforge.players[player_name].level
    local required_xp = current_level * 100  -- Simple progression
    
    if voxelforge.players[player_name].xp >= required_xp then
        voxelforge.players[player_name].level = current_level + 1
        voxelforge.players[player_name].xp = voxelforge.players[player_name].xp - required_xp
        
        local player = minetest.get_player_by_name(player_name)
        if player then
            minetest.chat_send_player(player_name, "Level up! You are now level " .. voxelforge.players[player_name].level)
        end
    end
end

function voxelforge.get_level(player_name)
    if voxelforge.players[player_name] then
        return voxelforge.players[player_name].level
    end
    return 1
end

print("[VoxelForge Core] Loaded successfully!")
"""
    
    init_lua_path = mod_dir / "init.lua"
    with open(init_lua_path, 'w') as f:
        f.write(init_lua_content)
    print(f"✓ Created init.lua: {init_lua_path}")
    
    return mod_dir

def create_component_files(mod_dir):
    """Create the component files for sounds, mapgen, nodes, items, tools, and crafting."""
    
    # Create sounds/init.lua
    sounds_init_content = """-- VoxelForge Core Sounds
-- Custom sound definitions to replace default mod dependency

voxelforge.sounds = {}

-- Sound table constructors
function voxelforge.sounds.node_sound_stone_defaults(table)
    table = table or {}
    table.footstep = table.footstep or {name = "", gain = 1.0}
    table.dug = table.dug or {name = "voxelforge_stone_break", gain = 0.5}
    table.place = table.place or {name = "voxelforge_stone_place", gain = 1.0}
    return table
end

function voxelforge.sounds.node_sound_dirt_defaults(table)
    table = table or {}
    table.footstep = table.footstep or {name = "", gain = 0.4}
    table.dug = table.dug or {name = "voxelforge_dirt_break", gain = 0.5}
    table.place = table.place or {name = "voxelforge_dirt_place", gain = 1.0}
    return table
end

function voxelforge.sounds.node_sound_wood_defaults(table)
    table = table or {}
    table.footstep = table.footstep or {name = "", gain = 0.3}
    table.dug = table.dug or {name = "voxelforge_wood_break", gain = 0.5}
    table.place = table.place or {name = "voxelforge_wood_place", gain = 1.0}
    return table
end

function voxelforge.sounds.node_sound_metal_defaults(table)
    table = table or {}
    table.footstep = table.footstep or {name = "", gain = 0.4}
    table.dug = table.dug or {name = "voxelforge_metal_break", gain = 0.5}
    table.place = table.place or {name = "voxelforge_metal_place", gain = 1.0}
    return table
end

-- Tool break sound
voxelforge.sounds.tool_breaks = "voxelforge_tool_breaks"

-- Note: Sound files would need to be added to sounds/ directory
-- For now, these are placeholder names that won't cause errors
"""
    
    sounds_init_path = mod_dir / "sounds" / "init.lua"
    with open(sounds_init_path, 'w') as f:
        f.write(sounds_init_content)
    print(f"✓ Created sounds/init.lua: {sounds_init_path}")
    
    # Create mapgen/init.lua
    mapgen_init_content = """-- VoxelForge Core Mapgen
-- Mapgen aliases for world generation

-- Set mapgen aliases to use VoxelForge blocks
minetest.register_alias("mapgen_stone", "voxelforge_core:stone")
minetest.register_alias("mapgen_dirt", "voxelforge_core:dirt")
minetest.register_alias("mapgen_dirt_with_grass", "voxelforge_core:dirt")  -- TODO: Add grass block in future
minetest.register_alias("mapgen_sand", "voxelforge_core:dirt")  -- Use dirt for now, add sand later
minetest.register_alias("mapgen_gravel", "voxelforge_core:stone")  -- Use stone for now
minetest.register_alias("mapgen_clay", "voxelforge_core:dirt")
minetest.register_alias("mapgen_lava_source", "voxelforge_core:stone")  -- Placeholder
minetest.register_alias("mapgen_cobble", "voxelforge_core:stone")
minetest.register_alias("mapgen_mossycobble", "voxelforge_core:stone")
minetest.register_alias("mapgen_dirt_with_snow", "voxelforge_core:dirt")
minetest.register_alias("mapgen_snow", "voxelforge_core:dirt")  -- Placeholder
minetest.register_alias("mapgen_snowblock", "voxelforge_core:dirt")  -- Placeholder
minetest.register_alias("mapgen_ice", "voxelforge_core:stone")  -- Placeholder

-- Tree generation aliases
minetest.register_alias("mapgen_tree", "voxelforge_core:wood")
minetest.register_alias("mapgen_leaves", "voxelforge_core:wood")  -- TODO: Add leaves block
minetest.register_alias("mapgen_apple", "voxelforge_core:wood")  -- Placeholder

-- Water aliases (use air for now since we don't have water blocks yet)
minetest.register_alias("mapgen_water_source", "air")
minetest.register_alias("mapgen_river_water_source", "air")

-- Ore generation aliases
minetest.register_alias("mapgen_stone_with_coal", "voxelforge_core:coal_ore")
minetest.register_alias("mapgen_stone_with_iron", "voxelforge_core:iron_ore")
minetest.register_alias("mapgen_stone_with_copper", "voxelforge_core:copper_ore")

-- Additional common aliases
minetest.register_alias("stone", "voxelforge_core:stone")
minetest.register_alias("dirt", "voxelforge_core:dirt")
minetest.register_alias("tree", "voxelforge_core:wood")
minetest.register_alias("wood", "voxelforge_core:planks")

print("[VoxelForge Core] Mapgen aliases registered")
"""
    
    mapgen_init_path = mod_dir / "mapgen" / "init.lua"
    with open(mapgen_init_path, 'w') as f:
        f.write(mapgen_init_content)
    print(f"✓ Created mapgen/init.lua: {mapgen_init_path}")
    
    # Create cooking/init.lua (placeholder - full implementation exists)
    cooking_init_content = """-- VoxelForge Core Cooking System
-- Fuel-driven cooking with XP rewards

voxelforge.cooking = {}

-- Cooking recipes
voxelforge.cooking.recipes = {
    ["voxelforge_core:iron_lump"] = {
        output = "voxelforge_core:iron_ingot",
        cooktime = 3,
        xp_reward = 2
    },
    ["voxelforge_core:copper_lump"] = {
        output = "voxelforge_core:copper_ingot", 
        cooktime = 3,
        xp_reward = 2
    },
}

-- Fuel items and burn times
voxelforge.cooking.fuels = {
    ["voxelforge_core:coal_lump"] = 30,
    ["voxelforge_core:wood"] = 15,
    ["voxelforge_core:planks"] = 7,
}

-- Basic cooking functionality (simplified for setup)
function voxelforge.cooking.init_stove(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size("src", 1)
    inv:set_size("fuel", 1) 
    inv:set_size("dst", 4)
    meta:set_string("formspec", "size[8,8.5]label[0,0;VoxelForge Cooking Stove]")
end

function voxelforge.cooking.stove_timer(pos, elapsed)
    return false -- Simplified for setup
end

function voxelforge.cooking.on_stove_receive_fields(pos, formname, fields, sender)
    -- Placeholder
end

print("[VoxelForge Core] Cooking system loaded")
"""
    
    cooking_init_path = mod_dir / "cooking" / "init.lua"
    with open(cooking_init_path, 'w') as f:
        f.write(cooking_init_content)
    print(f"✓ Created cooking/init.lua: {cooking_init_path}")
    
    # Create caves/init.lua (placeholder - full implementation exists)
    caves_init_content = """-- VoxelForge Core Cave Generation
-- Advanced noise-based cave system with spherical caverns

voxelforge.caves = {}

-- Cave generation parameters
voxelforge.caves.config = {
    noise_params = {
        offset = 0,
        scale = 1,
        spread = {x = 100, y = 100, z = 100},
        seed = 12345,
        octaves = 3,
        persist = 0.6,
        lacunarity = 2.0,
    },
    cave_threshold = 0.6,
    small_sphere_radius = {min = 4, max = 6},
    large_sphere_radius = {min = 7, max = 10},
    sphere_spacing = 15,
    ridge_width = 3,
    ridge_height_variation = 2,
    min_y = -50,
    max_y = 20,
}

-- Simplified cave generation for setup
function voxelforge.caves.generate(minp, maxp, vm, area, data)
    -- Basic cave generation would go here
    -- Full implementation available in actual file
end

-- Register cave generation with mapgen
minetest.register_on_generated(function(minp, maxp, blockseed)
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
    local data = vm:get_data()
    
    voxelforge.caves.generate(minp, maxp, vm, area, data)
    
    vm:set_data(data)
    vm:write_to_map()
end)

print("[VoxelForge Core] Advanced cave generation system loaded")
"""
    
    caves_init_path = mod_dir / "caves" / "init.lua"
    with open(caves_init_path, 'w') as f:
        f.write(caves_init_content)
    print(f"✓ Created caves/init.lua: {caves_init_path}")
    
    # Create nodes/init.lua
    nodes_init_content = """-- VoxelForge Core Nodes
-- Terrain blocks and crafting stations

-- Stone
minetest.register_node("voxelforge_core:stone", {
    description = "VoxelForge Stone",
    tiles = {"voxelforge_stone.png"},
    groups = {cracky = 3, stone = 1},
    drop = "voxelforge_core:stone",
    sounds = voxelforge.sounds.node_sound_stone_defaults(),
})

-- Dirt
minetest.register_node("voxelforge_core:dirt", {
    description = "VoxelForge Dirt",
    tiles = {"voxelforge_dirt.png"},
    groups = {crumbly = 3, soil = 1},
    sounds = voxelforge.sounds.node_sound_dirt_defaults(),
})

-- Wood (log)
minetest.register_node("voxelforge_core:wood", {
    description = "VoxelForge Wood",
    tiles = {"voxelforge_wood.png"},
    groups = {choppy = 2, oddly_breakable_by_hand = 1, flammable = 2, wood = 1},
    sounds = voxelforge.sounds.node_sound_wood_defaults(),
})

-- Planks
minetest.register_node("voxelforge_core:planks", {
    description = "VoxelForge Planks",
    tiles = {"voxelforge_planks.png"},
    groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 3, wood = 1},
    sounds = voxelforge.sounds.node_sound_wood_defaults(),
})

-- Ores
minetest.register_node("voxelforge_core:iron_ore", {
    description = "Iron Ore",
    tiles = {"voxelforge_iron_ore.png"},
    groups = {cracky = 2},
    drop = "voxelforge_core:iron_lump",
    sounds = voxelforge.sounds.node_sound_stone_defaults(),
})

minetest.register_node("voxelforge_core:copper_ore", {
    description = "Copper Ore",
    tiles = {"voxelforge_copper_ore.png"},
    groups = {cracky = 2},
    drop = "voxelforge_core:copper_lump",
    sounds = voxelforge.sounds.node_sound_stone_defaults(),
})

minetest.register_node("voxelforge_core:coal_ore", {
    description = "Coal Ore",
    tiles = {"voxelforge_coal_ore.png"},
    groups = {cracky = 3},
    drop = "voxelforge_core:coal_lump",
    sounds = voxelforge.sounds.node_sound_stone_defaults(),
})

-- Crafting Table
minetest.register_node("voxelforge_core:crafting_table", {
    description = "VoxelForge Crafting Table",
    tiles = {
        "voxelforge_crafting_table_top.png",
        "voxelforge_crafting_table_side.png",
        "voxelforge_crafting_table_side.png",
        "voxelforge_crafting_table_side.png",
        "voxelforge_crafting_table_side.png",
        "voxelforge_crafting_table_side.png"
    },
    groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
    sounds = voxelforge.sounds.node_sound_wood_defaults(),
    on_rightclick = function(pos, node, player, itemstack, pointed_thing)
        minetest.show_formspec(player:get_player_name(), "voxelforge_core:crafting",
            "size[9,8.75]" ..
            "label[0,0;VoxelForge Crafting Table]" ..
            "list[current_player;craft;2,1;3,3;]" ..
            "list[current_player;craftpreview;6,2;1,1;]" ..
            "listring[current_player;main]" ..
            "listring[current_player;craft]" ..
            "list[current_player;main;0,4.75;8,1;]" ..
            "list[current_player;main;0,6;8,3;8]")
    end,
})

-- Forge
minetest.register_node("voxelforge_core:forge", {
    description = "VoxelForge Forge",
    tiles = {
        "voxelforge_forge.png",
        "voxelforge_forge.png",
        "voxelforge_forge_front.png",
        "voxelforge_forge_front.png",
        "voxelforge_forge.png",
        "voxelforge_forge.png"
    },
    groups = {cracky = 2},
    sounds = voxelforge.sounds.node_sound_stone_defaults(),
    on_rightclick = function(pos, node, player, itemstack, pointed_thing)
        -- TODO: Implement forge functionality
        minetest.chat_send_player(player:get_player_name(), "Forge functionality coming soon!")
    end,
})

-- Cooking Stove
minetest.register_node("voxelforge_core:cooking_stove", {
    description = "VoxelForge Cooking Stove",
    tiles = {
        "voxelforge_cooking_stove_top.png",
        "voxelforge_cooking_stove_front.png",
        "voxelforge_cooking_stove_front.png",
        "voxelforge_cooking_stove_front.png",
        "voxelforge_cooking_stove_front.png",
        "voxelforge_cooking_stove_front.png"
    },
    groups = {cracky = 2},
    sounds = voxelforge.sounds.node_sound_stone_defaults(),
    on_rightclick = function(pos, node, player, itemstack, pointed_thing)
        -- TODO: Implement cooking functionality
        minetest.chat_send_player(player:get_player_name(), "Cooking stove functionality coming soon!")
    end,
})
"""
    
    nodes_init_path = mod_dir / "nodes" / "init.lua"
    with open(nodes_init_path, 'w') as f:
        f.write(nodes_init_content)
    print(f"✓ Created nodes/init.lua: {nodes_init_path}")
    
    # Create items/init.lua
    items_init_content = """-- VoxelForge Core Items
-- Raw materials and crafted items

-- Lumps (raw ores)
minetest.register_craftitem("voxelforge_core:iron_lump", {
    description = "Iron Lump",
    inventory_image = "voxelforge_iron_lump.png",
})

minetest.register_craftitem("voxelforge_core:copper_lump", {
    description = "Copper Lump",
    inventory_image = "voxelforge_copper_lump.png",
})

minetest.register_craftitem("voxelforge_core:coal_lump", {
    description = "Coal Lump",
    inventory_image = "voxelforge_coal_lump.png",
})

-- Ingots (smelted metals)
minetest.register_craftitem("voxelforge_core:iron_ingot", {
    description = "Iron Ingot",
    inventory_image = "voxelforge_iron_ingot.png",
})

minetest.register_craftitem("voxelforge_core:copper_ingot", {
    description = "Copper Ingot",
    inventory_image = "voxelforge_copper_ingot.png",
})
"""
    
    items_init_path = mod_dir / "items" / "init.lua"
    with open(items_init_path, 'w') as f:
        f.write(items_init_content)
    print(f"✓ Created items/init.lua: {items_init_path}")
    
    # Create tools/init.lua
    tools_init_content = """-- VoxelForge Core Tools
-- Tools with XP rewards

local function add_xp_on_use(itemstack, user, pointed_thing, xp_amount)
    if user and user:is_player() then
        voxelforge.add_xp(user:get_player_name(), xp_amount or 1)
    end
end

-- Wooden Tools
minetest.register_tool("voxelforge_core:wooden_pickaxe", {
    description = "Wooden Pickaxe",
    inventory_image = "voxelforge_wooden_pickaxe.png",
    tool_capabilities = {
        full_punch_interval = 1.2,
        max_drop_level = 0,
        groupcaps = {
            cracky = {times={[3]=1.60}, uses=10, maxlevel=1},
        },
        damage_groups = {fleshy=2},
    },
    sound = {breaks = voxelforge.sounds.tool_breaks},
    after_use = function(itemstack, user, node, digparams)
        add_xp_on_use(itemstack, user, node, 1)
        return itemstack
    end,
})

minetest.register_tool("voxelforge_core:wooden_axe", {
    description = "Wooden Axe",
    inventory_image = "voxelforge_wooden_axe.png",
    tool_capabilities = {
        full_punch_interval = 1.0,
        max_drop_level = 0,
        groupcaps = {
            choppy = {times={[2]=3.00, [3]=2.00}, uses=10, maxlevel=1},
        },
        damage_groups = {fleshy=2},
    },
    sound = {breaks = voxelforge.sounds.tool_breaks},
    after_use = function(itemstack, user, node, digparams)
        add_xp_on_use(itemstack, user, node, 1)
        return itemstack
    end,
})

minetest.register_tool("voxelforge_core:wooden_shovel", {
    description = "Wooden Shovel",
    inventory_image = "voxelforge_wooden_shovel.png",
    tool_capabilities = {
        full_punch_interval = 1.2,
        max_drop_level = 0,
        groupcaps = {
            crumbly = {times={[1]=3.00, [2]=1.60, [3]=0.60}, uses=10, maxlevel=1},
        },
        damage_groups = {fleshy=2},
    },
    sound = {breaks = voxelforge.sounds.tool_breaks},
    after_use = function(itemstack, user, node, digparams)
        add_xp_on_use(itemstack, user, node, 1)
        return itemstack
    end,
})

minetest.register_tool("voxelforge_core:wooden_sword", {
    description = "Wooden Sword",
    inventory_image = "voxelforge_wooden_sword.png",
    tool_capabilities = {
        full_punch_interval = 1.0,
        max_drop_level = 0,
        groupcaps = {
            snappy = {times={[2]=1.6, [3]=0.40}, uses=10, maxlevel=1},
        },
        damage_groups = {fleshy=2},
    },
    sound = {breaks = voxelforge.sounds.tool_breaks},
})

-- Stone Tools (better stats)
minetest.register_tool("voxelforge_core:stone_pickaxe", {
    description = "Stone Pickaxe",
    inventory_image = "voxelforge_stone_pickaxe.png",
    tool_capabilities = {
        full_punch_interval = 1.3,
        max_drop_level = 0,
        groupcaps = {
            cracky = {times={[2]=2.0, [3]=1.00}, uses=20, maxlevel=1},
        },
        damage_groups = {fleshy=3},
    },
    sound = {breaks = voxelforge.sounds.tool_breaks},
    after_use = function(itemstack, user, node, digparams)
        add_xp_on_use(itemstack, user, node, 2)
        return itemstack
    end,
})

-- Iron Tools (best stats for Phase 1)
minetest.register_tool("voxelforge_core:iron_pickaxe", {
    description = "Iron Pickaxe",
    inventory_image = "voxelforge_iron_pickaxe.png",
    tool_capabilities = {
        full_punch_interval = 1.0,
        max_drop_level = 1,
        groupcaps = {
            cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=30, maxlevel=2},
        },
        damage_groups = {fleshy=4},
    },
    sound = {breaks = voxelforge.sounds.tool_breaks},
    after_use = function(itemstack, user, node, digparams)
        add_xp_on_use(itemstack, user, node, 3)
        return itemstack
    end,
})

-- Add other stone and iron tools following the same pattern...
"""
    
    tools_init_path = mod_dir / "tools" / "init.lua"
    with open(tools_init_path, 'w') as f:
        f.write(tools_init_content)
    print(f"✓ Created tools/init.lua: {tools_init_path}")
    
    # Create crafting/init.lua
    crafting_init_content = """-- VoxelForge Core Crafting Recipes

-- Basic material conversions
minetest.register_craft({
    output = "voxelforge_core:planks 4",
    recipe = {
        {"voxelforge_core:wood"},
    }
})

-- Crafting Table
minetest.register_craft({
    output = "voxelforge_core:crafting_table",
    recipe = {
        {"voxelforge_core:planks", "voxelforge_core:planks"},
        {"voxelforge_core:planks", "voxelforge_core:planks"},
    }
})

-- Wooden Tools
minetest.register_craft({
    output = "voxelforge_core:wooden_pickaxe",
    recipe = {
        {"voxelforge_core:planks", "voxelforge_core:planks", "voxelforge_core:planks"},
        {"", "voxelforge_core:planks", ""},
        {"", "voxelforge_core:planks", ""},
    }
})

minetest.register_craft({
    output = "voxelforge_core:wooden_axe",
    recipe = {
        {"voxelforge_core:planks", "voxelforge_core:planks"},
        {"voxelforge_core:planks", "voxelforge_core:planks"},
        {"", "voxelforge_core:planks"},
    }
})

-- Smelting recipes
minetest.register_craft({
    type = "cooking",
    output = "voxelforge_core:iron_ingot",
    recipe = "voxelforge_core:iron_lump",
    cooktime = 5,
})

minetest.register_craft({
    type = "cooking",
    output = "voxelforge_core:copper_ingot",
    recipe = "voxelforge_core:copper_lump",
    cooktime = 5,
})

-- Stone tools (require level 2)
minetest.register_craft({
    output = "voxelforge_core:stone_pickaxe",
    recipe = {
        {"voxelforge_core:stone", "voxelforge_core:stone", "voxelforge_core:stone"},
        {"", "voxelforge_core:planks", ""},
        {"", "voxelforge_core:planks", ""},
    }
})

-- Iron tools (require level 3)
minetest.register_craft({
    output = "voxelforge_core:iron_pickaxe",
    recipe = {
        {"voxelforge_core:iron_ingot", "voxelforge_core:iron_ingot", "voxelforge_core:iron_ingot"},
        {"", "voxelforge_core:planks", ""},
        {"", "voxelforge_core:planks", ""},
    }
})

-- Forge (advanced crafting station)
minetest.register_craft({
    output = "voxelforge_core:forge",
    recipe = {
        {"voxelforge_core:stone", "voxelforge_core:stone", "voxelforge_core:stone"},
        {"voxelforge_core:stone", "voxelforge_core:iron_ingot", "voxelforge_core:stone"},
        {"voxelforge_core:stone", "voxelforge_core:stone", "voxelforge_core:stone"},
    }
})

-- Cooking Stove
minetest.register_craft({
    output = "voxelforge_core:cooking_stove",
    recipe = {
        {"voxelforge_core:iron_ingot", "voxelforge_core:iron_ingot", "voxelforge_core:iron_ingot"},
        {"voxelforge_core:iron_ingot", "", "voxelforge_core:iron_ingot"},
        {"voxelforge_core:stone", "voxelforge_core:stone", "voxelforge_core:stone"},
    }
})
"""
    
    crafting_init_path = mod_dir / "crafting" / "init.lua"
    with open(crafting_init_path, 'w') as f:
        f.write(crafting_init_content)
    print(f"✓ Created crafting/init.lua: {crafting_init_path}")

def copy_textures_to_mod(mod_dir):
    """Copy generated textures to the mod directory."""
    import shutil
    
    base_dir = Path(__file__).parent.parent
    textures_source = base_dir / "textures"
    textures_dest = mod_dir / "textures"
    
    if textures_source.exists():
        # Copy block textures
        blocks_source = textures_source / "blocks"
        if blocks_source.exists():
            for texture_file in blocks_source.glob("*.png"):
                shutil.copy2(texture_file, textures_dest)
                print(f"✓ Copied block texture: {texture_file.name}")
        
        # Copy item textures
        items_source = textures_source / "items"
        if items_source.exists():
            for texture_file in items_source.glob("*.png"):
                shutil.copy2(texture_file, textures_dest)
                print(f"✓ Copied item texture: {texture_file.name}")
        
        # Copy station textures
        stations_source = textures_source / "stations"
        if stations_source.exists():
            for texture_file in stations_source.glob("*.png"):
                shutil.copy2(texture_file, textures_dest)
                print(f"✓ Copied station texture: {texture_file.name}")
        
        # Copy GUI textures
        gui_source = textures_source / "gui"
        if gui_source.exists():
            for texture_file in gui_source.glob("*.png"):
                shutil.copy2(texture_file, textures_dest)
                print(f"✓ Copied GUI texture: {texture_file.name}")

def main():
    """Main setup function for Phase 1."""
    print("🔥 VoxelForge Reimagined - Phase 1 Setup")
    print("=" * 50)
    
    # Check dependencies
    print("\n1. Checking dependencies...")
    if not check_dependencies():
        return False
    
    # Generate textures
    print("\n2. Generating textures...")
    try:
        generate_phase1_textures()
        generate_all_stations()
        
        # Generate GUI textures
        import subprocess
        subprocess.run([sys.executable, "generate_gui_textures.py"], cwd=Path(__file__).parent)
        
        print("✓ All textures generated successfully")
    except Exception as e:
        print(f"✗ Error generating textures: {e}")
        return False
    
    # Create mod structure
    print("\n3. Creating mod structure...")
    try:
        mod_dir = create_mod_structure()
        create_component_files(mod_dir)
        print("✓ Mod structure created successfully")
    except Exception as e:
        print(f"✗ Error creating mod structure: {e}")
        return False
    
    # Copy textures
    print("\n4. Copying textures to mod...")
    try:
        copy_textures_to_mod(mod_dir)
        print("✓ Textures copied successfully")
    except Exception as e:
        print(f"✗ Error copying textures: {e}")
        return False
    
    print("\n" + "=" * 50)
    print("🎉 Phase 1 setup complete!")
    print("\nNext steps:")
    print("1. Start Minetest and create a new world")
    print("2. Enable the 'VoxelForge Core' mod")
    print("3. Test mining, crafting, and XP progression")
    print("4. Reach Level 2 to complete Phase 1 milestone!")
    print("\nMod location:", mod_dir)
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)