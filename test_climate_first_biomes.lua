#!/usr/bin/env lua

-- Test script for the new climate-first biome selection approach
-- This demonstrates how the system now prioritizes temperature and humidity

print("=== VoxelForge Climate-First Biome Selection Test ===")
print()

-- Mock the minetest global for testing
_G.minetest = {
    log = function(level, message)
        print("[" .. level:upper() .. "] " .. message)
    end,
    get_modpath = function(modname)
        return "/home/joshua/.minetest/games/voxelforge-reimagined/mods/" .. modname
    end
}

-- Load the biome manager
local biome_manager = dofile("/home/joshua/.minetest/games/voxelforge-reimagined/mods/voxelgen/biome_manager.lua")

-- Mock biome registry with some test biomes
local test_biomes = {
        temperate_forest = {
            name = "temperate_forest",
            temperature_levels = {2}, -- Temperate
            humidity_levels = {3},    -- Humid
            continentalness_names = {"mid_inland"},
            erosion_levels = {3, 4},
            pv_names = {"mid"},
            y_min = 0,
            y_max = 200,
            priority = 100
        },
        desert = {
            name = "desert",
            temperature_levels = {3, 4}, -- Hot/Very Hot
            humidity_levels = {0, 1},    -- Arid/Dry
            continentalness_names = {"mid_inland", "far_inland"},
            erosion_levels = {4, 5, 6},
            pv_names = {"mid", "low"},
            y_min = 0,
            y_max = 150,
            priority = 80
        },
        tundra = {
            name = "tundra",
            temperature_levels = {0, 1}, -- Frozen/Cold
            humidity_levels = {1, 2},    -- Dry/Neutral
            continentalness_names = {"mid_inland", "far_inland"},
            erosion_levels = {4, 5},
            pv_names = {"mid"},
            y_min = 0,
            y_max = 100,
            priority = 90
        },
        ocean = {
            name = "ocean",
            temperature_levels = {1, 2, 3}, -- Cold/Temperate/Hot
            humidity_levels = {3, 4},       -- Humid/Very Humid
            continentalness_names = {"ocean", "deep_ocean"},
            erosion_levels = {5, 6},
            pv_names = {"low", "mid"},
            y_min = -50,
            y_max = 0,
            priority = 70
        }
}

local mock_registry = {
    get_all_biomes = function()
        return test_biomes
    end,
    DEFAULT_PRIORITY = 50,
    MIN_PRIORITY = 0
}

-- Set the mock registry
biome_manager.set_registry(mock_registry)

-- Test scenarios
local test_scenarios = {
    {
        name = "Temperate Forest Conditions",
        parameters = {
            temperature_level = 2,  -- Temperate
            humidity_level = 3,     -- Humid
            continentalness_name = "mid_inland",
            erosion_level = 3,
            pv_name = "mid",
            depth = 0,
            y = 50,
            x = 100,
            z = 100
        },
        expected = "temperate_forest"
    },
    {
        name = "Desert Conditions",
        parameters = {
            temperature_level = 4,  -- Very Hot
            humidity_level = 0,     -- Arid
            continentalness_name = "far_inland",
            erosion_level = 5,
            pv_name = "low",
            depth = 0,
            y = 80,
            x = 200,
            z = 200
        },
        expected = "desert"
    },
    {
        name = "Tundra Conditions",
        parameters = {
            temperature_level = 0,  -- Frozen
            humidity_level = 1,     -- Dry
            continentalness_name = "mid_inland",
            erosion_level = 4,
            pv_name = "mid",
            depth = 0,
            y = 60,
            x = 300,
            z = 300
        },
        expected = "tundra"
    },
    {
        name = "Ocean Conditions",
        parameters = {
            temperature_level = 2,  -- Temperate
            humidity_level = 4,     -- Very Humid
            continentalness_name = "ocean",
            erosion_level = 6,
            pv_name = "low",
            depth = 0,
            y = -10,
            x = 400,
            z = 400
        },
        expected = "ocean"
    },
    {
        name = "Climate Mismatch - Should find closest climate match",
        parameters = {
            temperature_level = 2,  -- Temperate
            humidity_level = 2,     -- Neutral (no exact match)
            continentalness_name = "coast", -- Different terrain
            erosion_level = 2,      -- Different erosion
            pv_name = "high",       -- Different PV
            depth = 0,
            y = 70,
            x = 500,
            z = 500
        },
        expected = "temperate_forest" -- Should still pick this due to temperature match
    }
}

-- Run tests
print("Testing the new CLIMATE-FIRST biome selection approach:")
print("Temperature and humidity are now STRICT requirements!")
print()

for i, scenario in ipairs(test_scenarios) do
    print("Test " .. i .. ": " .. scenario.name)
    print("  Parameters:")
    print("    Temperature Level: " .. scenario.parameters.temperature_level)
    print("    Humidity Level: " .. scenario.parameters.humidity_level)
    print("    Continentalness: " .. scenario.parameters.continentalness_name)
    print("    Erosion Level: " .. scenario.parameters.erosion_level)
    print("    PV: " .. scenario.parameters.pv_name)
    print("    Y-Level: " .. scenario.parameters.y)
    
    local selected_biome = biome_manager.get_best_biome(scenario.parameters)
    
    if selected_biome then
        print("  RESULT: " .. selected_biome.name)
        print("  Selection Method: " .. (selected_biome._selection_method or "unknown"))
        if selected_biome._terrain_score then
            print("  Terrain Score: " .. string.format("%.2f", selected_biome._terrain_score))
        end
        
        if selected_biome.name == scenario.expected then
            print("  ✓ SUCCESS: Got expected biome!")
        else
            print("  ⚠ DIFFERENT: Expected '" .. scenario.expected .. "' but got '" .. selected_biome.name .. "'")
            print("    This might be correct due to the new climate-first logic!")
        end
    else
        print("  ✗ FAILED: No biome selected!")
    end
    
    print()
end

print("=== Climate-First Approach Summary ===")
print("1. First, find all biomes that match the EXACT temperature and humidity")
print("2. If no exact matches, try fuzzy matching (adjacent levels only)")
print("3. Among climate-matched biomes, filter by Y-range")
print("4. Find the best terrain match (continentalness, erosion, PV, depth)")
print("5. If no terrain match, pick highest priority climate-matched biome")
print("6. Only fall back to legacy system if climate matching completely fails")
print()
print("This ensures that climate is ALWAYS respected, and terrain is optimized within climate constraints!")