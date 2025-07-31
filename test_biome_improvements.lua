-- Test script for biome manager improvements
-- This script tests the new spatial coherence and enhanced closest match features

-- Mock minetest.log for testing
local minetest = {
    log = function(level, message)
        print("[" .. level .. "] " .. message)
    end
}

-- Load the biome manager
local biome_manager = dofile("mods/voxelgen/biome_manager.lua")

-- Mock biome registry for testing
local mock_registry = {
    DEFAULT_PRIORITY = 100,
    MIN_PRIORITY = 0,
    get_all_biomes = function()
        return {
            desert_plains = {
                name = "desert_plains",
                temperature_levels = {4}, -- Hot
                humidity_levels = {0}, -- Arid
                continentalness_names = {"mid_inland", "far_inland"},
                erosion_levels = {4, 5, 6}, -- Flat areas
                pv_names = {"low", "mid"},
                y_min = 0,
                y_max = 100,
                priority = 80
            },
            temperate_forest = {
                name = "temperate_forest",
                temperature_levels = {2}, -- Temperate
                humidity_levels = {2, 3}, -- Neutral to wet
                continentalness_names = {"near_inland", "mid_inland"},
                erosion_levels = {2, 3, 4}, -- Hills to flat
                pv_names = {"low", "mid", "high"},
                y_min = 0,
                y_max = 150,
                priority = 100
            },
            mountain_peaks = {
                name = "mountain_peaks",
                temperature_levels = {0, 1}, -- Cold
                humidity_levels = {1, 2}, -- Dry to neutral
                continentalness_names = {"near_inland", "mid_inland"},
                erosion_levels = {0, 1, 2}, -- Mountainous
                pv_names = {"peaks", "high"},
                y_min = 80,
                y_max = 200,
                priority = 90
            },
            grassland = {
                name = "grassland",
                temperature_levels = {2, 3}, -- Temperate to warm
                humidity_levels = {1, 2, 3}, -- Dry to wet
                continentalness_names = {"near_inland", "mid_inland"},
                erosion_levels = {3, 4, 5}, -- Hills to flat
                pv_names = {"low", "mid"},
                y_min = 0,
                y_max = 120,
                priority = 95
            }
        }
    end
}

-- Set up the biome manager
biome_manager.set_registry(mock_registry)

-- Test cases
local test_cases = {
    {
        name = "Mountain terrain - should prefer mountain biomes",
        parameters = {
            temperature_level = 1,
            humidity_level = 2,
            continentalness_name = "mid_inland",
            erosion_level = 1, -- Mountainous
            pv_name = "peaks",
            terrain_height = 150,
            depth = 0,
            y = 120,
            x = 100,
            z = 100
        }
    },
    {
        name = "Desert conditions in mountains - should avoid desert",
        parameters = {
            temperature_level = 4, -- Hot (desert-like)
            humidity_level = 0, -- Arid (desert-like)
            continentalness_name = "mid_inland",
            erosion_level = 1, -- Mountainous (not desert-like)
            pv_name = "peaks", -- Peaks (not desert-like)
            terrain_height = 140, -- High altitude (not desert-like)
            depth = 0,
            y = 120,
            x = 200,
            z = 200
        }
    },
    {
        name = "Flat temperate area - should prefer grassland/forest",
        parameters = {
            temperature_level = 2,
            humidity_level = 2,
            continentalness_name = "mid_inland",
            erosion_level = 4, -- Flat
            pv_name = "mid",
            terrain_height = 70,
            depth = 0,
            y = 70,
            x = 300,
            z = 300
        }
    },
    {
        name = "Hot flat area - should allow desert",
        parameters = {
            temperature_level = 4,
            humidity_level = 0,
            continentalness_name = "far_inland",
            erosion_level = 5, -- Very flat
            pv_name = "low",
            terrain_height = 60,
            depth = 0,
            y = 60,
            x = 400,
            z = 400
        }
    }
}

-- Run tests
print("=== Testing Biome Manager Improvements ===")
print()

for i, test_case in ipairs(test_cases) do
    print("Test " .. i .. ": " .. test_case.name)
    print("Parameters:")
    for key, value in pairs(test_case.parameters) do
        print("  " .. key .. ": " .. tostring(value))
    end
    
    local selected_biome = biome_manager.get_best_biome(test_case.parameters)
    
    if selected_biome then
        print("Selected biome: " .. selected_biome.name)
        if selected_biome._selection_method then
            print("Selection method: " .. selected_biome._selection_method)
        end
        if selected_biome._coherence_score then
            print("Coherence score: " .. string.format("%.2f", selected_biome._coherence_score))
        end
    else
        print("No biome selected!")
    end
    
    print()
end

print("=== Testing Enhanced Distance Calculation ===")
print()

-- Test the enhanced distance calculation
local test_biome = mock_registry.get_all_biomes().temperate_forest
local test_params = {
    temperature_level = 3, -- One level off from biome's requirement (2)
    humidity_level = 1, -- One level off from biome's requirement (2-3)
    continentalness_name = "far_inland", -- Different from biome's requirement
    erosion_level = 5, -- Different from biome's requirement
    pv_name = "valleys", -- Different from biome's requirement
    y = 200 -- Outside biome's Y range (0-150)
}

local distance = biome_manager.calculate_enhanced_biome_distance(test_biome, test_params)
print("Distance from temperate_forest to test parameters: " .. string.format("%.2f", distance))

print()
print("=== Testing Biome Compatibility ===")
print()

local biomes = mock_registry.get_all_biomes()
local desert = biomes.desert_plains
local forest = biomes.temperate_forest
local mountain = biomes.mountain_peaks
local grassland = biomes.grassland

print("Compatibility scores:")
print("Desert <-> Forest: " .. string.format("%.2f", biome_manager.get_biome_compatibility(desert, forest)))
print("Desert <-> Mountain: " .. string.format("%.2f", biome_manager.get_biome_compatibility(desert, mountain)))
print("Desert <-> Grassland: " .. string.format("%.2f", biome_manager.get_biome_compatibility(desert, grassland)))
print("Forest <-> Grassland: " .. string.format("%.2f", biome_manager.get_biome_compatibility(forest, grassland)))
print("Mountain <-> Forest: " .. string.format("%.2f", biome_manager.get_biome_compatibility(mountain, forest)))

print()
print("=== Test Complete ===")