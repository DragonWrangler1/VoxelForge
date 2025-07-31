-- Test script to verify savanna-taiga incompatibility
-- This script tests the biome compatibility system

-- Load the biome manager
local biome_manager = dofile("mods/voxelgen/biome_manager.lua")

-- Mock biome definitions for testing
local mock_savanna = {
    name = "savanna",
    temperature_levels = {2, 3},
    humidity_levels = {1, 2}
}

local mock_taiga = {
    name = "taiga", 
    temperature_levels = {0, 1, 2},
    humidity_levels = {2, 3}
}

local mock_plains = {
    name = "plains",
    temperature_levels = {1, 2, 3},
    humidity_levels = {1, 2, 3}
}

-- Test biome type classification
print("Testing biome type classification:")
print("Savanna type:", biome_manager.get_biome_type_from_name("savanna"))
print("Taiga type:", biome_manager.get_biome_type_from_name("taiga"))
print("Plains type:", biome_manager.get_biome_type_from_name("plains"))

-- Test compatibility scores
print("\nTesting compatibility scores:")
print("Savanna-Taiga compatibility:", biome_manager.get_biome_compatibility(mock_savanna, mock_taiga))
print("Savanna-Plains compatibility:", biome_manager.get_biome_compatibility(mock_savanna, mock_plains))
print("Taiga-Plains compatibility:", biome_manager.get_biome_compatibility(mock_taiga, mock_plains))

-- Test hard incompatibility detection
print("\nTesting hard incompatibility detection:")
local neighbor_context_with_taiga = {
    neighbor_biomes = {mock_taiga}
}

local neighbor_context_with_plains = {
    neighbor_biomes = {mock_plains}
}

print("Savanna has hard incompatible neighbors (taiga):", 
      biome_manager.has_hard_incompatible_neighbors(mock_savanna, neighbor_context_with_taiga))
print("Savanna has hard incompatible neighbors (plains):", 
      biome_manager.has_hard_incompatible_neighbors(mock_savanna, neighbor_context_with_plains))
print("Taiga has hard incompatible neighbors (savanna):", 
      biome_manager.has_hard_incompatible_neighbors(mock_taiga, {neighbor_biomes = {mock_savanna}}))

print("\nTest completed!")