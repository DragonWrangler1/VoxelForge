-- biome_manager.lua - Biome selection and matching system
-- Handles the logic for selecting the best biome based on environmental parameters
-- Completely decoupled from the registry for maximum modularity

local biome_manager = {}

-- Dependencies - will be set by the biomes system
local biome_registry = nil

-- Logging helper
local function log(level, message)
    minetest.log(level, "[VoxelGen BiomeManager] " .. message)
end

-- Parameter matching functions with fuzzy logic for realistic transitions
local function matches_temperature_levels(biome, temperature_level)
    if not biome.temperature_levels or not temperature_level then return true end
    
    for _, level in ipairs(biome.temperature_levels) do
        if level == temperature_level then
            return true
        end
    end
    return false
end

local function matches_humidity_levels(biome, humidity_level)
    if not biome.humidity_levels or not humidity_level then return true end
    
    for _, level in ipairs(biome.humidity_levels) do
        if level == humidity_level then
            return true
        end
    end
    return false
end

-- Fuzzy temperature matching - returns a score (0-1) based on how close the temperature is
local function calculate_temperature_score(biome, temperature_level, raw_temperature)
    if not biome.temperature_levels or not temperature_level then return 1.0 end
    
    -- Check for exact match first
    for _, level in ipairs(biome.temperature_levels) do
        if level == temperature_level then
            return 1.0 -- Perfect match
        end
    end
    
    -- Calculate fuzzy match based on adjacent temperature levels
    local best_score = 0.0
    for _, level in ipairs(biome.temperature_levels) do
        local distance = math.abs(level - temperature_level)
        if distance == 1 then
            -- Adjacent temperature level - give partial score
            best_score = math.max(best_score, 0.6)
        elseif distance == 2 then
            -- Two levels away - give smaller score
            best_score = math.max(best_score, 0.3)
        end
    end
    
    return best_score
end

-- Fuzzy humidity matching - returns a score (0-1) based on how close the humidity is
local function calculate_humidity_score(biome, humidity_level, raw_humidity)
    if not biome.humidity_levels or not humidity_level then return 1.0 end
    
    -- Check for exact match first
    for _, level in ipairs(biome.humidity_levels) do
        if level == humidity_level then
            return 1.0 -- Perfect match
        end
    end
    
    -- Calculate fuzzy match based on adjacent humidity levels
    local best_score = 0.0
    for _, level in ipairs(biome.humidity_levels) do
        local distance = math.abs(level - humidity_level)
        if distance == 1 then
            -- Adjacent humidity level - give partial score
            best_score = math.max(best_score, 0.6)
        elseif distance == 2 then
            -- Two levels away - give smaller score
            best_score = math.max(best_score, 0.3)
        end
    end
    
    return best_score
end

local function matches_continentalness_names(biome, continentalness_name)
    if not biome.continentalness_names or not continentalness_name then return true end
    
    for _, name in ipairs(biome.continentalness_names) do
        if name == continentalness_name then
            return true
        end
    end
    return false
end

local function matches_erosion_levels(biome, erosion_level)
    if not biome.erosion_levels or not erosion_level then return true end
    
    for _, level in ipairs(biome.erosion_levels) do
        if level == erosion_level then
            return true
        end
    end
    return false
end

local function matches_pv_names(biome, pv_name)
    if not biome.pv_names or not pv_name then return true end
    
    for _, name in ipairs(biome.pv_names) do
        if name == pv_name then
            return true
        end
    end
    return false
end

local function matches_depth_range(biome, depth)
    if not depth then return true end -- If depth is nil, assume it matches
    local depth_min = biome.depth_min or 0
    local depth_max = biome.depth_max or 1000
    return depth >= depth_min and depth <= depth_max
end

local function matches_y_range(biome, y)
    if not y then return true end -- If y is nil, assume it matches
    local y_min = biome.y_min or -31000
    local y_max = biome.y_max or 31000
    return y >= y_min and y <= y_max
end

-- Check if Y is within blending range (for smooth transitions)
local function matches_y_range_with_blend(biome, y)
    if not y then return true end -- If y is nil, assume it matches
    local y_min = biome.y_min or -31000
    local y_max = biome.y_max or 31000
    local y_blend = biome.y_blend or 0
    
    -- Extend the range by the blend amount
    local blend_y_min = y_min - y_blend
    local blend_y_max = y_max + y_blend
    
    return y >= blend_y_min and y <= blend_y_max
end

-- Calculate Y-range blend factor (0.0 = outside blend range, 1.0 = fully inside range)
local function calculate_y_blend_factor(biome, y)
    if not y then return 1.0 end
    
    local y_min = biome.y_min or -31000
    local y_max = biome.y_max or 31000
    local y_blend = biome.y_blend or 0
    
    -- If no blending, use strict boundaries
    if y_blend <= 0 then
        return matches_y_range(biome, y) and 1.0 or 0.0
    end
    
    -- If fully within core range, return full strength
    if y >= y_min and y <= y_max then
        return 1.0
    end
    
    -- Calculate blend factor for transition zones
    if y < y_min then
        local distance_from_min = y_min - y
        if distance_from_min <= y_blend then
            return 1.0 - (distance_from_min / y_blend)
        else
            return 0.0
        end
    elseif y > y_max then
        local distance_from_max = y - y_max
        if distance_from_max <= y_blend then
            return 1.0 - (distance_from_max / y_blend)
        else
            return 0.0
        end
    end
    
    return 0.0
end

-- Calculate biome match score (0-1, higher is better) with fuzzy matching for realistic transitions
local function calculate_match_score(biome, parameters)
    local score = 0
    local max_score = 0
    
    -- Temperature matching with fuzzy logic (weight: 20)
    max_score = max_score + 20
    local temp_score = calculate_temperature_score(biome, parameters.temperature_level, parameters.temperature)
    score = score + (20 * temp_score)
    
    -- Humidity matching with fuzzy logic (weight: 20)
    max_score = max_score + 20
    local humidity_score = calculate_humidity_score(biome, parameters.humidity_level, parameters.humidity)
    score = score + (20 * humidity_score)
    
    -- Continentalness matching (weight: 15)
    max_score = max_score + 15
    if matches_continentalness_names(biome, parameters.continentalness_name) then
        score = score + 15
    end
    
    -- Erosion matching (weight: 15)
    max_score = max_score + 15
    if matches_erosion_levels(biome, parameters.erosion_level) then
        score = score + 15
    end
    
    -- PV matching (weight: 10)
    max_score = max_score + 10
    if matches_pv_names(biome, parameters.pv_name) then
        score = score + 10
    end
    
    -- Depth matching (weight: 10)
    max_score = max_score + 10
    if matches_depth_range(biome, parameters.depth) then
        score = score + 10
    end
    
    -- Y-level matching with blending (weight: 10)
    max_score = max_score + 10
    local y_blend_factor = calculate_y_blend_factor(biome, parameters.y)
    score = score + (10 * y_blend_factor)
    
    -- Return normalized score (0-1)
    return max_score > 0 and (score / max_score) or 0
end

-- Set the biome registry instance (called by biomes system)
function biome_manager.set_registry(registry)
    biome_registry = registry
end

-- Find the best matching biome for given parameters with CLIMATE-FIRST approach
function biome_manager.get_best_biome(parameters)
    if not biome_registry then
        log("error", "Biome registry not set - call set_registry() first")
        return nil
    end
    
    if not parameters then
        log("error", "No parameters provided for biome selection")
        return nil
    end
    
    -- Get all registered biomes
    local all_biomes = biome_registry.get_all_biomes()
    
    if not next(all_biomes) then
        log("warning", "No biomes registered for selection")
        return nil
    end
    
    -- CLIMATE-FIRST APPROACH: Temperature and humidity are STRICT requirements
    -- Step 1: Filter by exact temperature and humidity match first
    local climate_matched_biomes = biome_manager.filter_biomes_by_strict_climate(all_biomes, parameters)
    
    if not next(climate_matched_biomes) then
        -- No exact climate matches, try fuzzy climate matching (adjacent levels only)
        climate_matched_biomes = biome_manager.filter_biomes_by_fuzzy_climate(all_biomes, parameters)
        
        if not next(climate_matched_biomes) then
            log("warning", "No biomes match temperature=" .. (parameters.temperature_level or "nil") .. 
                " and humidity=" .. (parameters.humidity_level or "nil") .. " (even with fuzzy matching)")
            -- Fall back to old system as last resort
            return biome_manager.get_best_biome_legacy_fallback(all_biomes, parameters)
        end
    end
    
    -- Step 2: Among climate-matched biomes, filter by Y-range
    local y_filtered_biomes = biome_manager.filter_biomes_by_y_range_with_blend(climate_matched_biomes, parameters.y)
    
    if not next(y_filtered_biomes) then
        log("warning", "No climate-matched biomes available for Y-level " .. (parameters.y or "nil"))
        -- Try with relaxed Y-range
        y_filtered_biomes = biome_manager.filter_biomes_by_relaxed_y_range(climate_matched_biomes, parameters.y, 20)
        
        if not next(y_filtered_biomes) then
            -- Use all climate-matched biomes regardless of Y-range as last resort
            y_filtered_biomes = climate_matched_biomes
        end
    end
    
    -- Step 3: Among climate+Y matched biomes, find the best terrain match
    local best_biome = biome_manager.find_best_terrain_match(y_filtered_biomes, parameters)
    
    if best_biome then
        best_biome._selection_method = "climate_first_terrain_match"
        
        -- Debug logging for biome selection (only log occasionally to avoid spam)
        if math.random() < 0.001 then -- Log ~0.1% of calls
            log("info", "Climate-first selection: " .. best_biome.name .. 
                " (temp=" .. (parameters.temperature_level or "nil") .. 
                ", humid=" .. (parameters.humidity_level or "nil") .. 
                ", terrain_score=" .. string.format("%.2f", best_biome._terrain_score or 0) .. ")")
        end
        
        return best_biome
    end
    
    -- Step 4: If no terrain match found, just pick the highest priority climate-matched biome
    best_biome = biome_manager.find_highest_priority_biome_in_candidates(y_filtered_biomes)
    
    if best_biome then
        best_biome._selection_method = "climate_first_priority_fallback"
        
        if math.random() < 0.001 then
            log("info", "Climate-first priority fallback: " .. best_biome.name)
        end
        
        return best_biome
    end
    
    -- Final fallback: use legacy system
    log("warning", "Climate-first approach failed, falling back to legacy system")
    return biome_manager.get_best_biome_legacy_fallback(all_biomes, parameters)
end

-- Strict Y-range biome matching with blending support
function biome_manager.find_biome_with_flexible_matching(all_biomes, parameters)
    -- STRICT ENFORCEMENT: Only consider biomes within their Y-range (including blend zones)
    local candidates = biome_manager.filter_biomes_by_y_range_with_blend(all_biomes, parameters.y)
    
    if not next(candidates) then
        -- No biomes available for this Y-level - this is intentional strict behavior
        log("warning", "No biomes available for Y-level " .. (parameters.y or "nil") .. " - strict Y-range enforcement active")
        return nil
    end
    
    -- Pass 1: Full parameter matching within Y-range
    local best_biome = biome_manager.find_best_match_in_candidates(candidates, parameters, "strict_y_full_match")
    if best_biome and biome_manager.calculate_flexible_score(best_biome, parameters) > 0.7 then
        best_biome._selection_method = "strict_y_full_match"
        return best_biome
    end
    
    -- Pass 1.5: Fuzzy climate matching for realistic transitions
    local fuzzy_biome = biome_manager.find_best_fuzzy_match(candidates, parameters)
    if fuzzy_biome then
        fuzzy_biome._selection_method = "fuzzy_climate_match"
        return fuzzy_biome
    end
    
    -- Pass 2: Climate-priority matching (but still within Y-range)
    local climate_candidates = biome_manager.filter_candidates_by_climate_compatibility(candidates, parameters)
    if next(climate_candidates) then
        best_biome = biome_manager.find_best_match_in_candidates(climate_candidates, parameters, "strict_y_climate")
        if best_biome then
            best_biome._selection_method = "strict_y_climate"
            return best_biome
        end
    end
    
    -- Pass 3: Terrain-type matching (but still within Y-range)
    local terrain_candidates = biome_manager.filter_candidates_by_terrain_type(candidates, parameters)
    if next(terrain_candidates) then
        best_biome = biome_manager.find_best_match_in_candidates(terrain_candidates, parameters, "strict_y_terrain")
        if best_biome then
            best_biome._selection_method = "strict_y_terrain"
            return best_biome
        end
    end
    
    -- Pass 4: Temperature-only matching (but still within Y-range)
    local temp_candidates = biome_manager.filter_candidates_by_temperature(candidates, parameters)
    if next(temp_candidates) then
        best_biome = biome_manager.find_best_match_in_candidates(temp_candidates, parameters, "strict_y_temperature")
        if best_biome then
            best_biome._selection_method = "strict_y_temperature"
            return best_biome
        end
    end
    
    -- Pass 5: Highest priority biome within Y-range (last resort, but still Y-constrained)
    best_biome = biome_manager.find_highest_priority_biome_in_candidates(candidates)
    if best_biome then
        best_biome._selection_method = "strict_y_priority_fallback"
        return best_biome
    end
    
    return nil
end

-- Filter biomes by exact Y-range
function biome_manager.filter_biomes_by_y_range(biomes, y)
    local filtered = {}
    for name, biome in pairs(biomes) do
        if matches_y_range(biome, y) then
            filtered[name] = biome
        end
    end
    return filtered
end

-- Filter biomes by Y-range with blending (NEW - for strict enforcement)
function biome_manager.filter_biomes_by_y_range_with_blend(biomes, y)
    local filtered = {}
    for name, biome in pairs(biomes) do
        if matches_y_range_with_blend(biome, y) then
            filtered[name] = biome
        end
    end
    return filtered
end

-- Filter biomes by relaxed Y-range (expand range by tolerance)
function biome_manager.filter_biomes_by_relaxed_y_range(biomes, y, tolerance)
    local filtered = {}
    for name, biome in pairs(biomes) do
        local y_min = (biome.y_min or -31000) - tolerance
        local y_max = (biome.y_max or 31000) + tolerance
        if y >= y_min and y <= y_max then
            filtered[name] = biome
        end
    end
    return filtered
end

-- Filter biomes by STRICT climate match (exact temperature and humidity levels only)
function biome_manager.filter_biomes_by_strict_climate(biomes, parameters)
    local filtered = {}
    for name, biome in pairs(biomes) do
        local temp_match = matches_temperature_levels(biome, parameters.temperature_level)
        local humid_match = matches_humidity_levels(biome, parameters.humidity_level)
        
        if temp_match and humid_match then
            filtered[name] = biome
        end
    end
    return filtered
end

-- Filter biomes by FUZZY climate match (allows adjacent temperature/humidity levels)
function biome_manager.filter_biomes_by_fuzzy_climate(biomes, parameters)
    local filtered = {}
    for name, biome in pairs(biomes) do
        local temp_match = matches_temperature_levels(biome, parameters.temperature_level) or
                          biome_manager.matches_adjacent_temperature(biome, parameters.temperature_level)
        local humid_match = matches_humidity_levels(biome, parameters.humidity_level) or
                           biome_manager.matches_adjacent_humidity(biome, parameters.humidity_level)
        
        if temp_match and humid_match then
            filtered[name] = biome
        end
    end
    return filtered
end

-- Filter biomes by climate compatibility (temperature + humidity) - LEGACY VERSION
function biome_manager.filter_biomes_by_climate_compatibility(biomes, parameters)
    local filtered = {}
    for name, biome in pairs(biomes) do
        local temp_match = matches_temperature_levels(biome, parameters.temperature_level) or
                          biome_manager.matches_adjacent_temperature(biome, parameters.temperature_level)
        local humid_match = matches_humidity_levels(biome, parameters.humidity_level) or
                           biome_manager.matches_adjacent_humidity(biome, parameters.humidity_level)
        
        if temp_match and humid_match then
            filtered[name] = biome
        end
    end
    return filtered
end

-- Filter biomes by terrain type (continentalness + erosion)
function biome_manager.filter_biomes_by_terrain_type(biomes, parameters)
    local filtered = {}
    for name, biome in pairs(biomes) do
        local cont_match = matches_continentalness_names(biome, parameters.continentalness_name) or
                          biome_manager.matches_similar_continentalness(biome, parameters.continentalness_name)
        local erosion_match = matches_erosion_levels(biome, parameters.erosion_level) or
                             biome_manager.matches_adjacent_erosion(biome, parameters.erosion_level)
        
        if cont_match and erosion_match then
            filtered[name] = biome
        end
    end
    return filtered
end

-- Filter biomes by temperature only
function biome_manager.filter_biomes_by_temperature(biomes, parameters)
    local filtered = {}
    for name, biome in pairs(biomes) do
        if matches_temperature_levels(biome, parameters.temperature_level) or
           biome_manager.matches_adjacent_temperature(biome, parameters.temperature_level) then
            filtered[name] = biome
        end
    end
    return filtered
end

-- Find highest priority biome
function biome_manager.find_highest_priority_biome(biomes)
    local best_biome = nil
    local highest_priority = biome_registry.MIN_PRIORITY - 1
    
    for name, biome in pairs(biomes) do
        local priority = biome.priority or biome_registry.DEFAULT_PRIORITY
        if priority > highest_priority then
            highest_priority = priority
            best_biome = biome
        end
    end
    
    return best_biome
end

-- Find highest priority biome within a set of candidates (NEW)
function biome_manager.find_highest_priority_biome_in_candidates(candidates)
    return biome_manager.find_highest_priority_biome(candidates)
end

-- Filter candidates by climate compatibility (NEW - works on pre-filtered candidates)
function biome_manager.filter_candidates_by_climate_compatibility(candidates, parameters)
    local filtered = {}
    for name, biome in pairs(candidates) do
        local temp_match = matches_temperature_levels(biome, parameters.temperature_level) or
                          biome_manager.matches_adjacent_temperature(biome, parameters.temperature_level)
        local humid_match = matches_humidity_levels(biome, parameters.humidity_level) or
                           biome_manager.matches_adjacent_humidity(biome, parameters.humidity_level)
        
        if temp_match and humid_match then
            filtered[name] = biome
        end
    end
    return filtered
end

-- Filter candidates by terrain type (NEW - works on pre-filtered candidates)
function biome_manager.filter_candidates_by_terrain_type(candidates, parameters)
    local filtered = {}
    for name, biome in pairs(candidates) do
        local cont_match = matches_continentalness_names(biome, parameters.continentalness_name) or
                          biome_manager.matches_similar_continentalness(biome, parameters.continentalness_name)
        local erosion_match = matches_erosion_levels(biome, parameters.erosion_level) or
                             biome_manager.matches_adjacent_erosion(biome, parameters.erosion_level)
        
        if cont_match and erosion_match then
            filtered[name] = biome
        end
    end
    return filtered
end

-- Filter candidates by temperature (NEW - works on pre-filtered candidates)
function biome_manager.filter_candidates_by_temperature(candidates, parameters)
    local filtered = {}
    for name, biome in pairs(candidates) do
        if matches_temperature_levels(biome, parameters.temperature_level) or
           biome_manager.matches_adjacent_temperature(biome, parameters.temperature_level) then
            filtered[name] = biome
        end
    end
    return filtered
end

-- Find best match within a set of candidates
function biome_manager.find_best_match_in_candidates(candidates, parameters, method)
    local best_biome = nil
    local best_score = -1
    local best_priority = biome_registry.MIN_PRIORITY - 1
    
    for name, biome in pairs(candidates) do
        local score = biome_manager.calculate_flexible_score(biome, parameters)
        local priority = biome.priority or biome_registry.DEFAULT_PRIORITY
        
        -- Prefer higher scores, then higher priority
        local is_better = false
        if score > best_score then
            is_better = true
        elseif score == best_score and priority > best_priority then
            is_better = true
        end
        
        if is_better then
            best_biome = biome
            best_score = score
            best_priority = priority
        end
    end
    
    return best_biome
end

-- Calculate flexible matching score with partial credit
function biome_manager.calculate_flexible_score(biome, parameters)
    local score = 0
    local max_score = 0
    
    -- Temperature matching with adjacent level support (weight: 25)
    max_score = max_score + 25
    if matches_temperature_levels(biome, parameters.temperature_level) then
        score = score + 25
    elseif biome_manager.matches_adjacent_temperature(biome, parameters.temperature_level) then
        score = score + 15 -- Partial credit for adjacent levels
    end
    
    -- Humidity matching with adjacent level support (weight: 25)
    max_score = max_score + 25
    if matches_humidity_levels(biome, parameters.humidity_level) then
        score = score + 25
    elseif biome_manager.matches_adjacent_humidity(biome, parameters.humidity_level) then
        score = score + 15 -- Partial credit for adjacent levels
    end
    
    -- Continentalness matching with similarity support (weight: 20)
    max_score = max_score + 20
    if matches_continentalness_names(biome, parameters.continentalness_name) then
        score = score + 20
    elseif biome_manager.matches_similar_continentalness(biome, parameters.continentalness_name) then
        score = score + 10 -- Partial credit for similar types
    end
    
    -- Erosion matching with adjacent level support (weight: 15)
    max_score = max_score + 15
    if matches_erosion_levels(biome, parameters.erosion_level) then
        score = score + 15
    elseif biome_manager.matches_adjacent_erosion(biome, parameters.erosion_level) then
        score = score + 8 -- Partial credit for adjacent levels
    end
    
    -- PV matching (weight: 10)
    max_score = max_score + 10
    if matches_pv_names(biome, parameters.pv_name) then
        score = score + 10
    end
    
    -- Y-level matching with tolerance (weight: 5)
    max_score = max_score + 5
    if matches_y_range(biome, parameters.y) then
        score = score + 5
    elseif biome_manager.matches_relaxed_y_range(biome, parameters.y, 50) then
        score = score + 2 -- Partial credit for nearby Y levels
    end
    
    -- Return normalized score (0-1)
    return max_score > 0 and (score / max_score) or 0
end

-- Check if biome matches adjacent temperature levels
function biome_manager.matches_adjacent_temperature(biome, temperature_level)
    if not biome.temperature_levels or not temperature_level then return false end
    
    local adjacent_levels = {
        [temperature_level - 1] = true,
        [temperature_level + 1] = true
    }
    
    for _, level in ipairs(biome.temperature_levels) do
        if adjacent_levels[level] then
            return true
        end
    end
    return false
end

-- Check if biome matches adjacent humidity levels
function biome_manager.matches_adjacent_humidity(biome, humidity_level)
    if not biome.humidity_levels or not humidity_level then return false end
    
    local adjacent_levels = {
        [humidity_level - 1] = true,
        [humidity_level + 1] = true
    }
    
    for _, level in ipairs(biome.humidity_levels) do
        if adjacent_levels[level] then
            return true
        end
    end
    return false
end

-- Check if biome matches similar continentalness types
function biome_manager.matches_similar_continentalness(biome, continentalness_name)
    if not biome.continentalness_names or not continentalness_name then return false end
    
    -- Define similarity groups
    local similarity_groups = {
        ocean = {"deep_ocean", "ocean"},
        coastal = {"coast", "near_inland"},
        inland = {"near_inland", "mid_inland", "far_inland"}
    }
    
    -- Find which group the target belongs to
    local target_group = nil
    for group_name, group_members in pairs(similarity_groups) do
        for _, member in ipairs(group_members) do
            if member == continentalness_name then
                target_group = group_members
                break
            end
        end
        if target_group then break end
    end
    
    if not target_group then return false end
    
    -- Check if biome has any continentalness from the same group
    for _, biome_cont in ipairs(biome.continentalness_names) do
        for _, group_member in ipairs(target_group) do
            if biome_cont == group_member then
                return true
            end
        end
    end
    
    return false
end

-- Check if biome matches adjacent erosion levels
function biome_manager.matches_adjacent_erosion(biome, erosion_level)
    if not biome.erosion_levels or not erosion_level then return false end
    
    local adjacent_levels = {
        [erosion_level - 1] = true,
        [erosion_level + 1] = true
    }
    
    for _, level in ipairs(biome.erosion_levels) do
        if adjacent_levels[level] then
            return true
        end
    end
    return false
end

-- Check if biome matches relaxed Y range
function biome_manager.matches_relaxed_y_range(biome, y, tolerance)
    if not y then return true end
    local y_min = (biome.y_min or -31000) - tolerance
    local y_max = (biome.y_max or 31000) + tolerance
    return y >= y_min and y <= y_max
end

-- Get all biomes that match the given parameters (with scores)
function biome_manager.get_matching_biomes(parameters, min_score)
    if not biome_registry then
        log("error", "Biome registry not set - call set_registry() first")
        return {}
    end
    
    min_score = min_score or 0.5 -- Default minimum score
    
    local all_biomes = biome_registry.get_all_biomes()
    local matching_biomes = {}
    
    -- Only consider biomes that match the Y-range
    for name, biome in pairs(all_biomes) do
        if matches_y_range(biome, parameters.y) then
            local score = calculate_match_score(biome, parameters)
            
            if score >= min_score then
                table.insert(matching_biomes, {
                    name = name,
                    biome = biome,
                    score = score,
                    priority = biome.priority or biome_registry.DEFAULT_PRIORITY
                })
            end
        end
    end
    
    -- Sort by score (descending), then by priority (descending)
    table.sort(matching_biomes, function(a, b)
        if a.score == b.score then
            return a.priority > b.priority
        end
        return a.score > b.score
    end)
    
    return matching_biomes
end

-- COMPREHENSIVE NOISE-BASED VALIDATION SYSTEM
-- Uses all available noise values to ensure optimal biome placement accuracy
function biome_manager.apply_comprehensive_noise_validation(biomes, parameters)
    local validated_biomes = {}
    
    -- Extract all noise parameters for validation
    local temp_level = parameters.temperature_level or 2
    local humid_level = parameters.humidity_level or 2
    local cont_name = parameters.continentalness_name or "mid_inland"
    local erosion_level = parameters.erosion_level or 3
    local pv_name = parameters.pv_name or "mid"
    local terrain_height = parameters.terrain_height or 64
    local y = parameters.y or 64
    
    -- Raw noise values for advanced validation
    local temperature = parameters.temperature or 0
    local humidity = parameters.humidity or 0
    local continentalness = parameters.continentalness or 0
    local erosion = parameters.erosion or 0
    local weirdness = parameters.weirdness or 0
    
    for name, biome in pairs(biomes) do
        local validation_score = 0
        local max_validation_score = 0
        local validation_passed = true
        local rejection_reasons = {}
        
        -- CRITICAL VALIDATION 1: Prevent desert biomes in mountainous terrain
        -- This is the primary issue to solve
        if biome_manager.is_desert_biome(biome) then
            max_validation_score = max_validation_score + 100
            
            -- Desert biomes should NOT appear in mountainous areas
            if erosion_level <= 2 then -- Mountainous erosion (0-2)
                table.insert(rejection_reasons, "desert_in_mountains")
                validation_passed = false
            elseif terrain_height > 120 then -- High terrain
                table.insert(rejection_reasons, "desert_at_high_altitude")
                validation_passed = false
            elseif pv_name == "peaks" then -- Peak areas
                table.insert(rejection_reasons, "desert_on_peaks")
                validation_passed = false
            else
                validation_score = validation_score + 100 -- Desert in appropriate terrain
            end
        else
            validation_score = validation_score + 100 -- Non-desert biomes pass this check
            max_validation_score = max_validation_score + 100
        end
        
        -- CRITICAL VALIDATION 2: Mountain biomes should only appear in mountainous terrain
        if biome_manager.is_mountain_biome(biome) then
            max_validation_score = max_validation_score + 100
            
            -- Mountain biomes should appear in mountainous areas
            if erosion_level <= 2 or terrain_height > 100 or pv_name == "peaks" or pv_name == "high" then
                validation_score = validation_score + 100 -- Mountain in appropriate terrain
            else
                table.insert(rejection_reasons, "mountain_in_flat_terrain")
                validation_passed = false
            end
        else
            validation_score = validation_score + 100 -- Non-mountain biomes pass this check
            max_validation_score = max_validation_score + 100
        end
        
        -- CRITICAL VALIDATION 3: Ocean biomes should only appear in oceanic areas
        if biome_manager.is_ocean_biome(biome) then
            max_validation_score = max_validation_score + 100
            
            if cont_name == "deep_ocean" or cont_name == "ocean" or terrain_height <= 0 then
                validation_score = validation_score + 100 -- Ocean in appropriate area
            else
                table.insert(rejection_reasons, "ocean_on_land")
                validation_passed = false
            end
        else
            validation_score = validation_score + 100 -- Non-ocean biomes pass this check
            max_validation_score = max_validation_score + 100
        end
        
        -- ADVANCED VALIDATION 4: Temperature-terrain consistency
        max_validation_score = max_validation_score + 50
        if biome_manager.validate_temperature_terrain_consistency(biome, temp_level, terrain_height, erosion_level) then
            validation_score = validation_score + 50
        else
            table.insert(rejection_reasons, "temperature_terrain_mismatch")
        end
        
        -- ADVANCED VALIDATION 5: Humidity-continentalness consistency
        max_validation_score = max_validation_score + 50
        if biome_manager.validate_humidity_continentalness_consistency(biome, humid_level, cont_name, continentalness) then
            validation_score = validation_score + 50
        else
            table.insert(rejection_reasons, "humidity_continentalness_mismatch")
        end
        
        -- ADVANCED VALIDATION 6: Erosion-PV consistency
        max_validation_score = max_validation_score + 50
        if biome_manager.validate_erosion_pv_consistency(biome, erosion_level, pv_name, erosion, weirdness) then
            validation_score = validation_score + 50
        else
            table.insert(rejection_reasons, "erosion_pv_mismatch")
        end
        
        -- Calculate final validation score
        local final_score = max_validation_score > 0 and (validation_score / max_validation_score) or 0
        
        -- Only include biomes that pass critical validations and have good scores
        if validation_passed and final_score >= 0.7 then
            validated_biomes[name] = biome
            biome._validation_score = final_score
            biome._validation_reasons = rejection_reasons
        else
            -- Debug logging for rejected biomes (occasionally)
            if math.random() < 0.01 then -- Log 1% of rejections
                log("info", "Biome " .. name .. " rejected: score=" .. string.format("%.2f", final_score) .. 
                    ", reasons=" .. table.concat(rejection_reasons, ","))
            end
        end
    end
    
    return validated_biomes
end

-- Helper function to identify desert biomes
function biome_manager.is_desert_biome(biome)
    if not biome.name then return false end
    local name_lower = string.lower(biome.name)
    
    -- Check for desert-like names
    if string.find(name_lower, "desert") or 
       string.find(name_lower, "arid") or
       string.find(name_lower, "badlands") or
       string.find(name_lower, "mesa") then
        return true
    end
    
    -- Check for desert-like humidity requirements (very dry)
    if biome.humidity_levels then
        local has_dry_only = true
        for _, level in ipairs(biome.humidity_levels) do
            if level > 1 then -- Not arid (0) or dry (1)
                has_dry_only = false
                break
            end
        end
        if has_dry_only then return true end
    end
    
    return false
end

-- Helper function to identify mountain biomes
function biome_manager.is_mountain_biome(biome)
    if not biome.name then return false end
    local name_lower = string.lower(biome.name)
    
    -- Check for mountain-like names
    if string.find(name_lower, "mountain") or
       string.find(name_lower, "peak") or
       string.find(name_lower, "alpine") or
       string.find(name_lower, "highland") or
       string.find(name_lower, "cliff") then
        return true
    end
    
    -- Check for mountain-like erosion requirements (low erosion = mountainous)
    if biome.erosion_levels then
        local has_mountain_erosion = false
        for _, level in ipairs(biome.erosion_levels) do
            if level <= 2 then -- Mountainous erosion levels
                has_mountain_erosion = true
                break
            end
        end
        if has_mountain_erosion and biome.y_min and biome.y_min > 80 then
            return true
        end
    end
    
    return false
end

-- Helper function to identify ocean biomes
function biome_manager.is_ocean_biome(biome)
    if not biome.name then return false end
    local name_lower = string.lower(biome.name)
    
    -- Check for ocean-like names
    if string.find(name_lower, "ocean") or
       string.find(name_lower, "sea") or
       string.find(name_lower, "deep") then
        return true
    end
    
    -- Check for ocean-like continentalness requirements
    if biome.continentalness_names then
        for _, cont_name in ipairs(biome.continentalness_names) do
            if cont_name == "deep_ocean" or cont_name == "ocean" then
                return true
            end
        end
    end
    
    return false
end

-- Validate temperature-terrain consistency
function biome_manager.validate_temperature_terrain_consistency(biome, temp_level, terrain_height, erosion_level)
    -- Cold biomes should not appear in low, flat areas (unless they're specifically cold plains)
    if biome.temperature_levels then
        local has_cold_temp = false
        for _, level in ipairs(biome.temperature_levels) do
            if level <= 1 then -- Frozen (0) or Cold (1)
                has_cold_temp = true
                break
            end
        end
        
        if has_cold_temp then
            -- Cold biomes are more appropriate at high elevations or in specific cold regions
            if terrain_height < 50 and erosion_level > 4 and not biome_manager.is_cold_plains_biome(biome) then
                return false -- Cold biome in warm, low, flat area
            end
        end
    end
    
    -- Hot biomes should not appear at very high elevations
    if biome.temperature_levels then
        local has_hot_temp = false
        for _, level in ipairs(biome.temperature_levels) do
            if level >= 4 then -- Hot (4)
                has_hot_temp = true
                break
            end
        end
        
        if has_hot_temp and terrain_height > 150 then
            return false -- Hot biome at very high elevation
        end
    end
    
    return true
end

-- Validate humidity-continentalness consistency
function biome_manager.validate_humidity_continentalness_consistency(biome, humid_level, cont_name, continentalness)
    -- Very dry biomes should not appear in oceanic areas
    if biome.humidity_levels then
        local has_arid = false
        for _, level in ipairs(biome.humidity_levels) do
            if level == 0 then -- Arid
                has_arid = true
                break
            end
        end
        
        if has_arid and (cont_name == "ocean" or cont_name == "deep_ocean" or continentalness < -0.3) then
            return false -- Arid biome near water
        end
    end
    
    -- Very wet biomes should not appear in far inland areas
    if biome.humidity_levels then
        local has_wet = false
        for _, level in ipairs(biome.humidity_levels) do
            if level >= 4 then -- Wet
                has_wet = true
                break
            end
        end
        
        if has_wet and cont_name == "far_inland" and continentalness > 0.5 then
            return false -- Wet biome in very inland area
        end
    end
    
    return true
end

-- Validate erosion-PV consistency
function biome_manager.validate_erosion_pv_consistency(biome, erosion_level, pv_name, erosion, weirdness)
    -- Flat biomes should not appear in peak areas
    if biome.erosion_levels then
        local has_flat_erosion = false
        for _, level in ipairs(biome.erosion_levels) do
            if level >= 5 then -- Very flat erosion
                has_flat_erosion = true
                break
            end
        end
        
        if has_flat_erosion and (pv_name == "peaks" or pv_name == "high") then
            return false -- Flat biome in peak area
        end
    end
    
    -- Valley biomes should not appear on peaks
    if biome.pv_names then
        local has_valley = false
        for _, name in ipairs(biome.pv_names) do
            if name == "valleys" then
                has_valley = true
                break
            end
        end
        
        if has_valley and pv_name == "peaks" then
            return false -- Valley biome on peaks
        end
    end
    
    return true
end

-- Helper to identify cold plains biomes (allowed to be cold in flat areas)
function biome_manager.is_cold_plains_biome(biome)
    if not biome.name then return false end
    local name_lower = string.lower(biome.name)
    
    return (string.find(name_lower, "tundra") or 
            string.find(name_lower, "taiga") or
            string.find(name_lower, "cold") and string.find(name_lower, "plain"))
end

-- Get biomes suitable for a specific terrain type
function biome_manager.get_biomes_for_terrain(terrain_class)
    if not biome_registry then
        log("error", "Biome registry not set - call set_registry() first")
        return {}
    end
    
    local suitable_biomes = {}
    local all_biomes = biome_registry.get_all_biomes()
    
    for name, biome in pairs(all_biomes) do
        local is_suitable = true
        
        -- Check continentalness compatibility
        if terrain_class.is_ocean and biome.continentalness_names then
            local has_ocean = false
            for _, cont_name in ipairs(biome.continentalness_names) do
                if cont_name == "deep_ocean" or cont_name == "ocean" then
                    has_ocean = true
                    break
                end
            end
            if not has_ocean then
                is_suitable = false
            end
        end
        
        -- Check erosion compatibility
        if terrain_class.is_mountainous and biome.erosion_levels then
            local has_mountain_erosion = false
            for _, erosion_level in ipairs(biome.erosion_levels) do
                if erosion_level <= 2 then -- Mountainous erosion levels
                    has_mountain_erosion = true
                    break
                end
            end
            if not has_mountain_erosion then
                is_suitable = false
            end
        end
        
        if is_suitable then
            suitable_biomes[name] = biome
        end
    end
    
    return suitable_biomes
end

-- Validate biome parameters structure
function biome_manager.validate_parameters(parameters)
    if not parameters then
        return false, "Parameters table is nil"
    end
    
    if type(parameters) ~= "table" then
        return false, "Parameters must be a table"
    end
    
    -- Check required fields
    local required_fields = {
        "temperature_level", "humidity_level", "continentalness_name",
        "erosion_level", "pv_name", "depth", "y"
    }
    
    for _, field in ipairs(required_fields) do
        if parameters[field] == nil then
            return false, "Missing required parameter: " .. field
        end
    end
    
    -- Validate field types and ranges
    if type(parameters.temperature_level) ~= "number" or 
       parameters.temperature_level < 0 or parameters.temperature_level > 4 then
        return false, "temperature_level must be a number between 0 and 4"
    end
    
    if type(parameters.humidity_level) ~= "number" or 
       parameters.humidity_level < 0 or parameters.humidity_level > 4 then
        return false, "humidity_level must be a number between 0 and 4"
    end
    
    if type(parameters.continentalness_name) ~= "string" then
        return false, "continentalness_name must be a string"
    end
    
    if type(parameters.erosion_level) ~= "number" or 
       parameters.erosion_level < 0 or parameters.erosion_level > 6 then
        return false, "erosion_level must be a number between 0 and 6"
    end
    
    if type(parameters.pv_name) ~= "string" then
        return false, "pv_name must be a string"
    end
    
    if type(parameters.depth) ~= "number" then
        return false, "depth must be a number"
    end
    
    if type(parameters.y) ~= "number" then
        return false, "y must be a number"
    end
    
    return true, "Valid parameters"
end

-- Create default parameters for testing
function biome_manager.create_default_parameters(x, y, z)
    return {
        temperature_level = 2, -- Temperate
        humidity_level = 2,    -- Neutral
        continentalness_name = "mid_inland",
        erosion_level = 3,     -- Hilly
        pv_name = "mid",       -- Mid peaks/valleys
        depth = 0,             -- Surface
        y = y or 0,            -- Sea level
        x = x or 0,            -- For reference
        z = z or 0             -- For reference
    }
end

-- Get biome statistics
function biome_manager.get_biome_statistics()
    if not biome_registry then
        return {
            total_biomes = 0,
            by_temperature = {},
            by_humidity = {},
            by_continentalness = {},
            by_erosion = {},
            by_pv = {},
            priority_range = {min = 0, max = 0},
            coverage_analysis = {}
        }
    end
    
    local all_biomes = biome_registry.get_all_biomes()
    local stats = {
        total_biomes = 0,
        by_temperature = {},
        by_humidity = {},
        by_continentalness = {},
        by_erosion = {},
        by_pv = {},
        priority_range = {min = math.huge, max = -math.huge},
        coverage_analysis = {}
    }
    
    for name, biome in pairs(all_biomes) do
        stats.total_biomes = stats.total_biomes + 1
        
        -- Track priority range
        local priority = biome.priority or 0
        stats.priority_range.min = math.min(stats.priority_range.min, priority)
        stats.priority_range.max = math.max(stats.priority_range.max, priority)
        
        -- Count temperature levels
        if biome.temperature_levels then
            for _, level in ipairs(biome.temperature_levels) do
                stats.by_temperature[level] = (stats.by_temperature[level] or 0) + 1
            end
        end
        
        -- Count humidity levels
        if biome.humidity_levels then
            for _, level in ipairs(biome.humidity_levels) do
                stats.by_humidity[level] = (stats.by_humidity[level] or 0) + 1
            end
        end
        
        -- Count continentalness names
        if biome.continentalness_names then
            for _, cont_name in ipairs(biome.continentalness_names) do
                stats.by_continentalness[cont_name] = (stats.by_continentalness[cont_name] or 0) + 1
            end
        end
        
        -- Count erosion levels
        if biome.erosion_levels then
            for _, level in ipairs(biome.erosion_levels) do
                stats.by_erosion[level] = (stats.by_erosion[level] or 0) + 1
            end
        end
        
        -- Count PV names
        if biome.pv_names then
            for _, pv_name in ipairs(biome.pv_names) do
                stats.by_pv[pv_name] = (stats.by_pv[pv_name] or 0) + 1
            end
        end
    end
    
    -- Fix priority range if no biomes
    if stats.total_biomes == 0 then
        stats.priority_range.min = 0
        stats.priority_range.max = 0
    end
    
    -- Analyze coverage gaps
    stats.coverage_analysis = biome_manager.analyze_biome_coverage(all_biomes)
    
    return stats
end

-- Analyze biome coverage to identify potential gaps
function biome_manager.analyze_biome_coverage(all_biomes)
    local analysis = {
        temperature_gaps = {},
        humidity_gaps = {},
        continentalness_gaps = {},
        erosion_gaps = {},
        pv_gaps = {},
        y_level_gaps = {},
        coverage_score = 0,
        recommendations = {}
    }
    
    -- Define all possible parameter values
    local all_temperature_levels = {0, 1, 2, 3, 4}
    local all_humidity_levels = {0, 1, 2, 3, 4}
    local all_continentalness_names = {"deep_ocean", "ocean", "coast", "near_inland", "mid_inland", "far_inland"}
    local all_erosion_levels = {0, 1, 2, 3, 4, 5, 6}
    local all_pv_names = {"valleys", "low", "mid", "high", "peaks"}
    
    -- Check temperature coverage
    local covered_temperatures = {}
    for _, biome in pairs(all_biomes) do
        if biome.temperature_levels then
            for _, level in ipairs(biome.temperature_levels) do
                covered_temperatures[level] = true
            end
        end
    end
    
    for _, level in ipairs(all_temperature_levels) do
        if not covered_temperatures[level] then
            table.insert(analysis.temperature_gaps, level)
        end
    end
    
    -- Check humidity coverage
    local covered_humidity = {}
    for _, biome in pairs(all_biomes) do
        if biome.humidity_levels then
            for _, level in ipairs(biome.humidity_levels) do
                covered_humidity[level] = true
            end
        end
    end
    
    for _, level in ipairs(all_humidity_levels) do
        if not covered_humidity[level] then
            table.insert(analysis.humidity_gaps, level)
        end
    end
    
    -- Check continentalness coverage
    local covered_continentalness = {}
    for _, biome in pairs(all_biomes) do
        if biome.continentalness_names then
            for _, name in ipairs(biome.continentalness_names) do
                covered_continentalness[name] = true
            end
        end
    end
    
    for _, name in ipairs(all_continentalness_names) do
        if not covered_continentalness[name] then
            table.insert(analysis.continentalness_gaps, name)
        end
    end
    
    -- Check erosion coverage
    local covered_erosion = {}
    for _, biome in pairs(all_biomes) do
        if biome.erosion_levels then
            for _, level in ipairs(biome.erosion_levels) do
                covered_erosion[level] = true
            end
        end
    end
    
    for _, level in ipairs(all_erosion_levels) do
        if not covered_erosion[level] then
            table.insert(analysis.erosion_gaps, level)
        end
    end
    
    -- Calculate overall coverage score
    local total_parameters = #all_temperature_levels + #all_humidity_levels + 
                            #all_continentalness_names + #all_erosion_levels + #all_pv_names
    local covered_parameters = (5 - #analysis.temperature_gaps) + (5 - #analysis.humidity_gaps) +
                              (6 - #analysis.continentalness_gaps) + (7 - #analysis.erosion_gaps) +
                              (5 - #analysis.pv_gaps)
    
    analysis.coverage_score = covered_parameters / total_parameters
    
    -- Generate recommendations
    if #analysis.temperature_gaps > 0 then
        table.insert(analysis.recommendations, "Add biomes for temperature levels: " .. table.concat(analysis.temperature_gaps, ", "))
    end
    
    if #analysis.humidity_gaps > 0 then
        table.insert(analysis.recommendations, "Add biomes for humidity levels: " .. table.concat(analysis.humidity_gaps, ", "))
    end
    
    if #analysis.continentalness_gaps > 0 then
        table.insert(analysis.recommendations, "Add biomes for continentalness: " .. table.concat(analysis.continentalness_gaps, ", "))
    end
    
    if #analysis.erosion_gaps > 0 then
        table.insert(analysis.recommendations, "Add biomes for erosion levels: " .. table.concat(analysis.erosion_gaps, ", "))
    end
    
    if analysis.coverage_score > 0.9 then
        table.insert(analysis.recommendations, "Excellent biome coverage! Consider adding variant biomes for diversity.")
    elseif analysis.coverage_score > 0.7 then
        table.insert(analysis.recommendations, "Good biome coverage. Fill remaining gaps for complete coverage.")
    else
        table.insert(analysis.recommendations, "Poor biome coverage. Significant gaps need to be filled.")
    end
    
    return analysis
end

-- Find best biome using fuzzy matching for realistic transitions
function biome_manager.find_best_fuzzy_match(candidates, parameters)
    local best_biome = nil
    local best_score = 0
    
    -- Use the enhanced calculate_match_score which already includes fuzzy logic
    for name, biome in pairs(candidates) do
        local score = calculate_match_score(biome, parameters)
        
        -- Accept biomes with fuzzy scores above 0.4 (allows adjacent temperature/humidity levels)
        if score > 0.4 and score > best_score then
            best_score = score
            best_biome = biome
        end
    end
    
    -- Log fuzzy matching results occasionally for debugging
    if best_biome and math.random() < 0.001 then
        log("info", "Fuzzy match selected: " .. best_biome.name .. " (score: " .. string.format("%.2f", best_score) .. ")")
    end
    
    return best_biome
end

-- SPATIAL COHERENCE SYSTEM: Prevents isolated biome patches
-- Apply spatial coherence filter to prevent tiny isolated patches
function biome_manager.apply_spatial_coherence_filter(biomes, parameters)
    local coherent_biomes = {}
    
    -- Get neighboring biome context if available
    local neighbor_context = biome_manager.get_neighbor_biome_context(parameters)
    
    for name, biome in pairs(biomes) do
        local coherence_score = biome_manager.calculate_spatial_coherence_score(biome, parameters, neighbor_context)
        
        -- Only include biomes that have good spatial coherence (score > 0.3)
        -- This prevents isolated patches of inappropriate biomes
        if coherence_score > 0.3 then
            coherent_biomes[name] = biome
            -- Store coherence score for later use
            biome._coherence_score = coherence_score
        end
    end
    
    -- If no biomes pass coherence test, return original set but log warning
    if not next(coherent_biomes) then
        if math.random() < 0.01 then -- Log 1% of cases to avoid spam
            log("warning", "No biomes passed spatial coherence filter at " .. 
                (parameters.x or "?") .. "," .. (parameters.y or "?") .. "," .. (parameters.z or "?"))
        end
        return biomes
    end
    
    return coherent_biomes
end

-- Calculate spatial coherence score based on neighboring biomes and terrain consistency
function biome_manager.calculate_spatial_coherence_score(biome, parameters, neighbor_context)
    local score = 1.0 -- Start with full score
    
    -- Factor 1: Terrain appropriateness (prevents desert in mountains, etc.)
    local terrain_score = biome_manager.calculate_terrain_appropriateness_score(biome, parameters)
    score = score * terrain_score
    
    -- Factor 2: Climate gradient consistency (prevents abrupt climate changes)
    local climate_score = biome_manager.calculate_climate_gradient_score(biome, parameters, neighbor_context)
    score = score * climate_score
    
    -- Factor 3: Biome compatibility with neighbors
    local neighbor_score = biome_manager.calculate_neighbor_compatibility_score(biome, neighbor_context)
    score = score * neighbor_score
    
    -- Factor 4: Minimum patch size enforcement
    local patch_size_score = biome_manager.calculate_patch_size_score(biome, parameters, neighbor_context)
    score = score * patch_size_score
    
    return score
end

-- Calculate how appropriate a biome is for the terrain type
function biome_manager.calculate_terrain_appropriateness_score(biome, parameters)
    local score = 1.0
    
    -- Strong penalties for obviously inappropriate combinations
    if biome_manager.is_desert_biome(biome) then
        -- Desert biomes should not appear in mountainous or very wet areas
        if parameters.erosion_level and parameters.erosion_level <= 2 then
            score = score * 0.1 -- Heavy penalty for desert in mountains
        end
        if parameters.terrain_height and parameters.terrain_height > 120 then
            score = score * 0.2 -- Penalty for desert at high altitude
        end
        if parameters.humidity_level and parameters.humidity_level >= 3 then
            score = score * 0.3 -- Penalty for desert in wet areas
        end
    end
    
    if biome_manager.is_mountain_biome(biome) then
        -- Mountain biomes should appear in mountainous terrain
        if parameters.erosion_level and parameters.erosion_level > 4 then
            score = score * 0.4 -- Penalty for mountain biome in flat areas
        end
        if parameters.terrain_height and parameters.terrain_height < 80 then
            score = score * 0.5 -- Penalty for mountain biome at low altitude
        end
    end
    
    if biome_manager.is_ocean_biome(biome) then
        -- Ocean biomes should only appear in oceanic areas
        if parameters.continentalness_name and 
           parameters.continentalness_name ~= "ocean" and 
           parameters.continentalness_name ~= "deep_ocean" then
            score = score * 0.1 -- Heavy penalty for ocean on land
        end
    end
    
    return math.max(score, 0.05) -- Minimum score to prevent complete elimination
end

-- Calculate climate gradient consistency to prevent abrupt transitions
function biome_manager.calculate_climate_gradient_score(biome, parameters, neighbor_context)
    if not neighbor_context or not neighbor_context.dominant_climate then
        return 1.0 -- No neighbor info, assume good
    end
    
    local score = 1.0
    local biome_climate = biome_manager.get_biome_climate_signature(biome)
    local neighbor_climate = neighbor_context.dominant_climate
    
    -- Calculate climate distance
    local temp_distance = math.abs((biome_climate.temperature or 2) - (neighbor_climate.temperature or 2))
    local humid_distance = math.abs((biome_climate.humidity or 2) - (neighbor_climate.humidity or 2))
    
    -- Penalize large climate jumps
    if temp_distance > 2 then
        score = score * 0.4 -- Heavy penalty for temperature jumps > 2 levels
    elseif temp_distance > 1 then
        score = score * 0.7 -- Moderate penalty for temperature jumps > 1 level
    end
    
    if humid_distance > 2 then
        score = score * 0.4 -- Heavy penalty for humidity jumps > 2 levels
    elseif humid_distance > 1 then
        score = score * 0.7 -- Moderate penalty for humidity jumps > 1 level
    end
    
    return score
end

-- Calculate compatibility with neighboring biomes
function biome_manager.calculate_neighbor_compatibility_score(biome, neighbor_context)
    if not neighbor_context or not neighbor_context.neighbor_biomes then
        return 1.0 -- No neighbor info, assume compatible
    end
    
    -- Check for hard incompatibility rules first
    if biome_manager.has_hard_incompatible_neighbors(biome, neighbor_context) then
        return 0.0 -- Completely incompatible
    end
    
    local compatibility_score = 0
    local neighbor_count = 0
    
    for _, neighbor_biome in pairs(neighbor_context.neighbor_biomes) do
        if neighbor_biome and neighbor_biome.name then
            local compatibility = biome_manager.get_biome_compatibility(biome, neighbor_biome)
            compatibility_score = compatibility_score + compatibility
            neighbor_count = neighbor_count + 1
        end
    end
    
    if neighbor_count == 0 then
        return 1.0
    end
    
    return compatibility_score / neighbor_count
end

-- Check for hard incompatibility rules that completely prevent certain biome combinations
function biome_manager.has_hard_incompatible_neighbors(biome, neighbor_context)
    if not biome or not biome.name or not neighbor_context or not neighbor_context.neighbor_biomes then
        return false
    end
    
    local biome_type = biome_manager.get_biome_type_from_name(biome.name)
    
    -- Hard incompatibility rules
    local hard_incompatible_pairs = {
        -- Savanna cannot border taiga/tundra biomes
        savanna = {"tundra"},
        tundra = {"savanna"}
    }
    
    if hard_incompatible_pairs[biome_type] then
        for _, neighbor_biome in pairs(neighbor_context.neighbor_biomes) do
            if neighbor_biome and neighbor_biome.name then
                local neighbor_type = biome_manager.get_biome_type_from_name(neighbor_biome.name)
                for _, incompatible_type in ipairs(hard_incompatible_pairs[biome_type]) do
                    if neighbor_type == incompatible_type then
                        return true -- Hard incompatibility found
                    end
                end
            end
        end
    end
    
    return false
end

-- Find a compatible alternative biome when hard incompatibility is detected
function biome_manager.find_compatible_alternative(biomes, parameters, neighbor_context)
    local compatible_biomes = {}
    
    -- Filter out biomes that would violate hard incompatibility rules
    for name, biome in pairs(biomes) do
        if not biome_manager.has_hard_incompatible_neighbors(biome, neighbor_context) then
            compatible_biomes[name] = biome
        end
    end
    
    if not next(compatible_biomes) then
        return nil -- No compatible alternatives found
    end
    
    -- Find the best match among compatible biomes
    return biome_manager.find_biome_with_flexible_matching(compatible_biomes, parameters)
end

-- Calculate patch size score to prevent tiny isolated patches
function biome_manager.calculate_patch_size_score(biome, parameters, neighbor_context)
    if not neighbor_context or not neighbor_context.neighbor_biomes then
        return 1.0 -- No neighbor info, assume good patch size
    end
    
    -- Count how many neighbors are the same biome type
    local same_biome_neighbors = 0
    local total_neighbors = 0
    
    for _, neighbor_biome in pairs(neighbor_context.neighbor_biomes) do
        if neighbor_biome and neighbor_biome.name then
            total_neighbors = total_neighbors + 1
            if neighbor_biome.name == biome.name then
                same_biome_neighbors = same_biome_neighbors + 1
            end
        end
    end
    
    if total_neighbors == 0 then
        return 1.0
    end
    
    local same_biome_ratio = same_biome_neighbors / total_neighbors
    
    -- If this would create an isolated patch (no same-biome neighbors), penalize heavily
    if same_biome_neighbors == 0 then
        -- Check if this biome type is compatible with the area
        local area_compatibility = biome_manager.calculate_area_compatibility(biome, neighbor_context)
        if area_compatibility < 0.5 then
            return 0.1 -- Heavy penalty for isolated incompatible patches
        else
            return 0.6 -- Moderate penalty for isolated but compatible patches
        end
    end
    
    -- Prefer biomes that form larger coherent patches
    return 0.3 + (same_biome_ratio * 0.7)
end

-- Get neighboring biome context for spatial analysis
function biome_manager.get_neighbor_biome_context(parameters)
    -- This would ideally sample neighboring positions, but for now we'll use
    -- a simplified approach based on the current parameters and some estimation
    
    local context = {
        neighbor_biomes = {},
        dominant_climate = nil,
        terrain_consistency = 1.0
    }
    
    -- Estimate dominant climate from current parameters
    if parameters.temperature_level and parameters.humidity_level then
        context.dominant_climate = {
            temperature = parameters.temperature_level,
            humidity = parameters.humidity_level
        }
    end
    
    -- In a full implementation, this would sample actual neighboring positions
    -- For now, we'll return the basic context
    return context
end

-- Get biome climate signature for comparison
function biome_manager.get_biome_climate_signature(biome)
    local signature = {
        temperature = nil,
        humidity = nil
    }
    
    -- Calculate average temperature level
    if biome.temperature_levels and #biome.temperature_levels > 0 then
        local temp_sum = 0
        for _, level in ipairs(biome.temperature_levels) do
            temp_sum = temp_sum + level
        end
        signature.temperature = temp_sum / #biome.temperature_levels
    end
    
    -- Calculate average humidity level
    if biome.humidity_levels and #biome.humidity_levels > 0 then
        local humid_sum = 0
        for _, level in ipairs(biome.humidity_levels) do
            humid_sum = humid_sum + level
        end
        signature.humidity = humid_sum / #biome.humidity_levels
    end
    
    return signature
end

-- Get compatibility score between two biomes (0.0 = incompatible, 1.0 = highly compatible)
function biome_manager.get_biome_compatibility(biome1, biome2)
    if not biome1 or not biome2 or not biome1.name or not biome2.name then
        return 0.5 -- Neutral compatibility if missing data
    end
    
    -- Same biome = perfect compatibility
    if biome1.name == biome2.name then
        return 1.0
    end
    
    -- Define biome compatibility matrix
    local compatibility_matrix = {
        -- Desert biomes are incompatible with cold/wet biomes
        desert = {
            forest = 0.3,
            grassland = 0.6,
            mountain = 0.2,
            ocean = 0.1,
            tundra = 0.1,
            swamp = 0.1,
            savanna = 0.8
        },
        -- Forest biomes are generally compatible with temperate biomes
        forest = {
            desert = 0.3,
            grassland = 0.8,
            mountain = 0.6,
            ocean = 0.4,
            tundra = 0.4,
            swamp = 0.7,
            savanna = 0.6
        },
        -- Grassland is very compatible with most biomes
        grassland = {
            desert = 0.6,
            forest = 0.8,
            mountain = 0.7,
            ocean = 0.5,
            tundra = 0.5,
            swamp = 0.6,
            savanna = 0.8
        },
        -- Mountain biomes have specific compatibility patterns
        mountain = {
            desert = 0.2,
            forest = 0.6,
            grassland = 0.7,
            ocean = 0.3,
            tundra = 0.8,
            swamp = 0.2,
            savanna = 0.4
        },
        -- Tundra biomes (including taiga) are cold and incompatible with warm biomes
        tundra = {
            desert = 0.1,
            forest = 0.4,
            grassland = 0.5,
            mountain = 0.8,
            ocean = 0.6,
            swamp = 0.2,
            savanna = 0.05  -- Very low compatibility to prevent savanna-taiga borders
        },
        -- Savanna biomes are warm and incompatible with cold biomes
        savanna = {
            desert = 0.8,
            forest = 0.6,
            grassland = 0.8,
            mountain = 0.4,
            ocean = 0.3,
            tundra = 0.05,  -- Very low compatibility to prevent savanna-taiga borders
            swamp = 0.4
        }
    }
    
    -- Get biome types from names
    local type1 = biome_manager.get_biome_type_from_name(biome1.name)
    local type2 = biome_manager.get_biome_type_from_name(biome2.name)
    
    if compatibility_matrix[type1] and compatibility_matrix[type1][type2] then
        return compatibility_matrix[type1][type2]
    end
    
    -- Default compatibility based on climate similarity
    local climate1 = biome_manager.get_biome_climate_signature(biome1)
    local climate2 = biome_manager.get_biome_climate_signature(biome2)
    
    if climate1.temperature and climate2.temperature and climate1.humidity and climate2.humidity then
        local temp_diff = math.abs(climate1.temperature - climate2.temperature)
        local humid_diff = math.abs(climate1.humidity - climate2.humidity)
        local climate_distance = math.sqrt(temp_diff^2 + humid_diff^2)
        
        -- Convert distance to compatibility (closer = more compatible)
        return math.max(0.1, 1.0 - (climate_distance / 4.0))
    end
    
    return 0.5 -- Default neutral compatibility
end

-- Extract biome type from biome name for compatibility checking
function biome_manager.get_biome_type_from_name(name)
    if not name then return "unknown" end
    
    local name_lower = string.lower(name)
    
    if string.find(name_lower, "desert") or string.find(name_lower, "arid") then
        return "desert"
    elseif string.find(name_lower, "forest") or string.find(name_lower, "woodland") then
        return "forest"
    elseif string.find(name_lower, "grass") or string.find(name_lower, "plain") then
        return "grassland"
    elseif string.find(name_lower, "mountain") or string.find(name_lower, "peak") or string.find(name_lower, "alpine") then
        return "mountain"
    elseif string.find(name_lower, "ocean") or string.find(name_lower, "sea") then
        return "ocean"
    elseif string.find(name_lower, "tundra") or string.find(name_lower, "frozen") or string.find(name_lower, "ice") or string.find(name_lower, "taiga") then
        return "tundra"
    elseif string.find(name_lower, "swamp") or string.find(name_lower, "marsh") or string.find(name_lower, "wetland") then
        return "swamp"
    elseif string.find(name_lower, "savanna") or string.find(name_lower, "steppe") then
        return "savanna"
    else
        return "unknown"
    end
end

-- Calculate area compatibility for isolated patch prevention
function biome_manager.calculate_area_compatibility(biome, neighbor_context)
    if not neighbor_context or not neighbor_context.neighbor_biomes then
        return 0.5 -- Neutral if no context
    end
    
    local total_compatibility = 0
    local neighbor_count = 0
    
    for _, neighbor_biome in pairs(neighbor_context.neighbor_biomes) do
        if neighbor_biome and neighbor_biome.name then
            local compatibility = biome_manager.get_biome_compatibility(biome, neighbor_biome)
            total_compatibility = total_compatibility + compatibility
            neighbor_count = neighbor_count + 1
        end
    end
    
    if neighbor_count == 0 then
        return 0.5
    end
    
    return total_compatibility / neighbor_count
end

-- ENHANCED CLOSEST MATCH ALGORITHM
-- Find the closest matching biome using improved distance calculation
function biome_manager.find_closest_match_biome(biomes, parameters)
    local best_biome = nil
    local best_distance = math.huge
    local best_priority = -math.huge
    
    for name, biome in pairs(biomes) do
        -- Skip biomes that are completely inappropriate for the Y-level
        if matches_y_range_with_blend(biome, parameters.y) then
            local distance = biome_manager.calculate_enhanced_biome_distance(biome, parameters)
            local priority = biome.priority or biome_registry.DEFAULT_PRIORITY
            
            -- Prefer closer matches, but also consider priority
            local is_better = false
            if distance < best_distance then
                is_better = true
            elseif distance == best_distance and priority > best_priority then
                is_better = true
            end
            
            if is_better then
                best_biome = biome
                best_distance = distance
                best_priority = priority
            end
        end
    end
    
    if best_biome and math.random() < 0.001 then
        log("info", "Enhanced closest match: " .. best_biome.name .. 
            " (distance: " .. string.format("%.2f", best_distance) .. ")")
    end
    
    return best_biome
end

-- Calculate enhanced distance between biome requirements and current parameters
function biome_manager.calculate_enhanced_biome_distance(biome, parameters)
    local distance = 0
    local weight_sum = 0
    
    -- Temperature distance (weight: 3.0)
    if biome.temperature_levels and parameters.temperature_level then
        local min_temp_distance = math.huge
        for _, temp_level in ipairs(biome.temperature_levels) do
            local temp_distance = math.abs(temp_level - parameters.temperature_level)
            min_temp_distance = math.min(min_temp_distance, temp_distance)
        end
        distance = distance + (min_temp_distance * 3.0)
        weight_sum = weight_sum + 3.0
    end
    
    -- Humidity distance (weight: 3.0)
    if biome.humidity_levels and parameters.humidity_level then
        local min_humid_distance = math.huge
        for _, humid_level in ipairs(biome.humidity_levels) do
            local humid_distance = math.abs(humid_level - parameters.humidity_level)
            min_humid_distance = math.min(min_humid_distance, humid_distance)
        end
        distance = distance + (min_humid_distance * 3.0)
        weight_sum = weight_sum + 3.0
    end
    
    -- Continentalness distance (weight: 2.0)
    if biome.continentalness_names and parameters.continentalness_name then
        local cont_distance = biome_manager.calculate_continentalness_distance(
            biome.continentalness_names, parameters.continentalness_name)
        distance = distance + (cont_distance * 2.0)
        weight_sum = weight_sum + 2.0
    end
    
    -- Erosion distance (weight: 2.0)
    if biome.erosion_levels and parameters.erosion_level then
        local min_erosion_distance = math.huge
        for _, erosion_level in ipairs(biome.erosion_levels) do
            local erosion_distance = math.abs(erosion_level - parameters.erosion_level)
            min_erosion_distance = math.min(min_erosion_distance, erosion_distance)
        end
        distance = distance + (min_erosion_distance * 2.0)
        weight_sum = weight_sum + 2.0
    end
    
    -- PV distance (weight: 1.0)
    if biome.pv_names and parameters.pv_name then
        local pv_distance = biome_manager.calculate_pv_distance(biome.pv_names, parameters.pv_name)
        distance = distance + (pv_distance * 1.0)
        weight_sum = weight_sum + 1.0
    end
    
    -- Y-level distance (weight: 1.0)
    if parameters.y then
        local y_distance = biome_manager.calculate_y_distance(biome, parameters.y)
        distance = distance + (y_distance * 1.0)
        weight_sum = weight_sum + 1.0
    end
    
    -- Return normalized distance
    return weight_sum > 0 and (distance / weight_sum) or 0
end

-- Calculate distance between continentalness values
function biome_manager.calculate_continentalness_distance(biome_continentalness, target_continentalness)
    local continentalness_order = {
        "deep_ocean", "ocean", "coast", "near_inland", "mid_inland", "far_inland"
    }
    
    local target_index = nil
    for i, name in ipairs(continentalness_order) do
        if name == target_continentalness then
            target_index = i
            break
        end
    end
    
    if not target_index then
        return 3 -- Default high distance for unknown continentalness
    end
    
    local min_distance = math.huge
    for _, biome_cont in ipairs(biome_continentalness) do
        for i, name in ipairs(continentalness_order) do
            if name == biome_cont then
                local distance = math.abs(i - target_index)
                min_distance = math.min(min_distance, distance)
                break
            end
        end
    end
    
    return min_distance == math.huge and 3 or min_distance
end

-- Calculate distance between PV values
function biome_manager.calculate_pv_distance(biome_pv_names, target_pv)
    local pv_order = {
        "valleys", "low", "mid", "high", "peaks"
    }
    
    local target_index = nil
    for i, name in ipairs(pv_order) do
        if name == target_pv then
            target_index = i
            break
        end
    end
    
    if not target_index then
        return 2 -- Default distance for unknown PV
    end
    
    local min_distance = math.huge
    for _, biome_pv in ipairs(biome_pv_names) do
        for i, name in ipairs(pv_order) do
            if name == biome_pv then
                local distance = math.abs(i - target_index)
                min_distance = math.min(min_distance, distance)
                break
            end
        end
    end
    
    return min_distance == math.huge and 2 or min_distance
end

-- Calculate Y-level distance with blending consideration
function biome_manager.calculate_y_distance(biome, target_y)
    local y_min = biome.y_min or -31000
    local y_max = biome.y_max or 31000
    
    -- If within range, distance is 0
    if target_y >= y_min and target_y <= y_max then
        return 0
    end
    
    -- Calculate distance to nearest edge of range
    if target_y < y_min then
        return (y_min - target_y) / 100.0 -- Normalize by dividing by 100
    else
        return (target_y - y_max) / 100.0 -- Normalize by dividing by 100
    end
end

-- Find the best terrain match among climate-matched biomes
function biome_manager.find_best_terrain_match(biomes, parameters)
    local best_biome = nil
    local best_score = -1
    
    for name, biome in pairs(biomes) do
        local terrain_score = biome_manager.calculate_terrain_match_score(biome, parameters)
        
        if terrain_score > best_score then
            best_score = terrain_score
            best_biome = biome
        end
    end
    
    if best_biome then
        best_biome._terrain_score = best_score
    end
    
    return best_biome
end

-- Calculate terrain match score (continentalness + erosion + PV + depth)
function biome_manager.calculate_terrain_match_score(biome, parameters)
    local score = 0
    local max_score = 0
    
    -- Continentalness matching (weight: 3.0)
    max_score = max_score + 3.0
    if matches_continentalness_names(biome, parameters.continentalness_name) then
        score = score + 3.0
    elseif biome_manager.matches_similar_continentalness(biome, parameters.continentalness_name) then
        score = score + 1.5 -- Partial match for similar continentalness
    end
    
    -- Erosion matching (weight: 2.5)
    max_score = max_score + 2.5
    if matches_erosion_levels(biome, parameters.erosion_level) then
        score = score + 2.5
    elseif biome_manager.matches_adjacent_erosion(biome, parameters.erosion_level) then
        score = score + 1.25 -- Partial match for adjacent erosion
    end
    
    -- PV matching (weight: 2.0)
    max_score = max_score + 2.0
    if matches_pv_names(biome, parameters.pv_name) then
        score = score + 2.0
    elseif biome_manager.matches_adjacent_pv(biome, parameters.pv_name) then
        score = score + 1.0 -- Partial match for adjacent PV
    end
    
    -- Depth matching (weight: 1.5)
    max_score = max_score + 1.5
    if matches_depth_range(biome, parameters.depth) then
        score = score + 1.5
    end
    
    -- Y-level blend factor (weight: 1.0)
    max_score = max_score + 1.0
    local y_blend_factor = calculate_y_blend_factor(biome, parameters.y)
    score = score + (1.0 * y_blend_factor)
    
    -- Return normalized score (0-1)
    return max_score > 0 and (score / max_score) or 0
end

-- Legacy fallback function (uses the old complex system)
function biome_manager.get_best_biome_legacy_fallback(all_biomes, parameters)
    -- Apply comprehensive noise validation to prevent inappropriate biome placement
    local validated_biomes = biome_manager.apply_comprehensive_noise_validation(all_biomes, parameters)
    
    if not next(validated_biomes) then
        validated_biomes = all_biomes
    end
    
    -- Apply spatial coherence analysis to prevent isolated patches
    local spatially_coherent_biomes = biome_manager.apply_spatial_coherence_filter(validated_biomes, parameters)
    
    -- Try multiple passes with progressively more relaxed criteria on spatially coherent biomes
    local best_biome = biome_manager.find_biome_with_flexible_matching(spatially_coherent_biomes, parameters)
    
    -- If no spatially coherent biome found, fall back to validated biomes
    if not best_biome then
        best_biome = biome_manager.find_biome_with_flexible_matching(validated_biomes, parameters)
        if best_biome then
            best_biome._selection_method = "legacy_fallback_without_spatial_coherence"
        end
    end
    
    -- Final fallback: use enhanced closest match algorithm
    if not best_biome then
        best_biome = biome_manager.find_closest_match_biome(all_biomes, parameters)
        if best_biome then
            best_biome._selection_method = "legacy_enhanced_closest_match"
        end
    end
    
    if best_biome then
        best_biome._selection_method = "legacy_" .. (best_biome._selection_method or "unknown")
    end
    
    return best_biome
end

-- Check if biome matches adjacent temperature levels
function biome_manager.matches_adjacent_temperature(biome, target_temp_level)
    if not biome.temperature_levels or not target_temp_level then return false end
    
    for _, temp_level in ipairs(biome.temperature_levels) do
        if math.abs(temp_level - target_temp_level) == 1 then
            return true
        end
    end
    return false
end

-- Check if biome matches adjacent humidity levels
function biome_manager.matches_adjacent_humidity(biome, target_humid_level)
    if not biome.humidity_levels or not target_humid_level then return false end
    
    for _, humid_level in ipairs(biome.humidity_levels) do
        if math.abs(humid_level - target_humid_level) == 1 then
            return true
        end
    end
    return false
end

-- Check if biome matches similar continentalness
function biome_manager.matches_similar_continentalness(biome, target_continentalness)
    if not biome.continentalness_names or not target_continentalness then return false end
    
    local continentalness_groups = {
        ocean = {"deep_ocean", "ocean"},
        coastal = {"coast", "near_inland"},
        inland = {"mid_inland", "far_inland"}
    }
    
    local target_group = nil
    for group, names in pairs(continentalness_groups) do
        for _, name in ipairs(names) do
            if name == target_continentalness then
                target_group = group
                break
            end
        end
        if target_group then break end
    end
    
    if not target_group then return false end
    
    for _, biome_cont in ipairs(biome.continentalness_names) do
        for _, name in ipairs(continentalness_groups[target_group]) do
            if biome_cont == name then
                return true
            end
        end
    end
    
    return false
end

-- Check if biome matches adjacent erosion levels
function biome_manager.matches_adjacent_erosion(biome, target_erosion_level)
    if not biome.erosion_levels or not target_erosion_level then return false end
    
    for _, erosion_level in ipairs(biome.erosion_levels) do
        if math.abs(erosion_level - target_erosion_level) == 1 then
            return true
        end
    end
    return false
end

-- Check if biome matches adjacent PV levels
function biome_manager.matches_adjacent_pv(biome, target_pv)
    if not biome.pv_names or not target_pv then return false end
    
    local pv_order = {"valleys", "low", "mid", "high", "peaks"}
    local target_index = nil
    
    for i, name in ipairs(pv_order) do
        if name == target_pv then
            target_index = i
            break
        end
    end
    
    if not target_index then return false end
    
    for _, biome_pv in ipairs(biome.pv_names) do
        for i, name in ipairs(pv_order) do
            if name == biome_pv then
                if math.abs(i - target_index) == 1 then
                    return true
                end
                break
            end
        end
    end
    
    return false
end

-- Export the manager
return biome_manager
