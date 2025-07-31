# Climate-First Biome Selection System

## Overview

The VoxelForge Reimagined map generator now uses a **Climate-First** approach for biome selection, where temperature and humidity are treated as **strict requirements** rather than just weighted factors.

## How It Works

### Previous System (Complex Multi-Factor)
The old system used a complex scoring algorithm that weighted all factors (temperature, humidity, continentalness, erosion, peaks/valleys, Y-level) equally, which could result in biomes being placed in climatically inappropriate locations if they scored well on terrain factors.

### New System (Climate-First)
The new system follows this strict hierarchy:

1. **STRICT CLIMATE FILTERING**: Find all biomes that match the exact temperature and humidity levels
2. **FUZZY CLIMATE FALLBACK**: If no exact matches, try adjacent temperature/humidity levels (±1)
3. **Y-RANGE FILTERING**: Among climate-matched biomes, filter by Y-level constraints
4. **TERRAIN OPTIMIZATION**: Find the best terrain match using weighted scoring:
   - Continentalness: weight 3.0
   - Erosion: weight 2.5
   - Peaks/Valleys: weight 2.0
   - Depth: weight 1.5
   - Y-level blend: weight 1.0
5. **PRIORITY FALLBACK**: If no terrain match, pick highest priority climate-matched biome
6. **LEGACY FALLBACK**: Only use the old complex system if climate matching completely fails

## Key Benefits

### 1. **Climate Consistency**
- Temperature and humidity are now **never compromised**
- Prevents desert biomes in humid areas or tundra biomes in hot areas
- Ensures realistic climate-based biome distribution

### 2. **Terrain Optimization Within Climate Constraints**
- Among climatically appropriate biomes, the system finds the best terrain match
- Optimizes for continentalness (ocean vs inland), erosion (mountains vs plains), etc.
- Maintains terrain realism while respecting climate

### 3. **Predictable Behavior**
- Clear hierarchy makes biome selection predictable and debuggable
- Selection method tracking shows exactly how each biome was chosen
- Easier to understand and modify biome placement rules

## Selection Methods

The system tracks how each biome was selected:

- `"climate_first_terrain_match"`: Perfect climate match with optimized terrain
- `"climate_first_priority_fallback"`: Climate match but no terrain optimization
- `"legacy_*"`: Fallback to old system (should be rare)

## Implementation Details

### New Functions Added

- `filter_biomes_by_strict_climate()`: Exact temperature/humidity matching
- `filter_biomes_by_fuzzy_climate()`: Adjacent level matching
- `find_best_terrain_match()`: Terrain optimization within climate constraints
- `calculate_terrain_match_score()`: Weighted terrain scoring
- `get_best_biome_legacy_fallback()`: Fallback to old system

### Modified Functions

- `get_best_biome()`: Completely rewritten to use climate-first approach
- Enhanced terrain matching with better adjacency detection

## Testing

The system has been tested with various scenarios:

1. **Perfect Matches**: Exact climate and terrain matches work perfectly
2. **Climate Priority**: When terrain doesn't match, climate is still respected
3. **Fuzzy Matching**: Adjacent climate levels work for smooth transitions
4. **Fallback Behavior**: System gracefully handles edge cases

## Configuration

The climate-first approach is now the default behavior. The old system is still available as a fallback but should rarely be used.

## Future Enhancements

Potential improvements:
- Configurable climate strictness levels
- Biome-specific climate tolerance ranges
- Enhanced spatial coherence for climate transitions
- Climate-aware neighbor compatibility rules

## Migration

Existing worlds will automatically use the new system. The change is backward compatible and should improve biome placement quality without breaking existing functionality.