-- biome_registry.lua - Modular and reliable biome registration system
-- This is the core biome registry that handles all biome registration and management
-- Designed to be completely self-contained and reliable

local biome_registry = {}

-- Registry state
biome_registry.biomes = {}
biome_registry.initialized = false
biome_registry.content_ids_cache = {}

-- Constants
biome_registry.DEFAULT_PRIORITY = 0
biome_registry.MAX_PRIORITY = 1000
biome_registry.MIN_PRIORITY = -1000

-- Logging helper
local function log(level, message)
    minetest.log(level, "[VoxelGen BiomeRegistry] " .. message)
end

-- Node resolution system
local function resolve_node_to_content_id(node_input)
    if not node_input then
        return minetest.get_content_id("air")
    end
    
    -- If it's already a number (content ID), validate and return
    if type(node_input) == "number" then
        if node_input >= 0 and node_input < 65536 then
            return node_input
        else
            log("warning", "Invalid content ID " .. node_input .. ", using air")
            return minetest.get_content_id("air")
        end
    end
    
    -- If it's a string (node name), resolve to content ID
    if type(node_input) == "string" then
        -- Check cache first
        if biome_registry.content_ids_cache[node_input] then
            return biome_registry.content_ids_cache[node_input]
        end
        
        -- Try to resolve the node
        if minetest.registered_nodes[node_input] then
            local content_id = minetest.get_content_id(node_input)
            biome_registry.content_ids_cache[node_input] = content_id
            return content_id
        else
            log("warning", "Node '" .. node_input .. "' not found, using fallback")
            -- Use fallback and cache it
            local fallback_id = minetest.get_content_id("air")
            biome_registry.content_ids_cache[node_input] = fallback_id
            return fallback_id
        end
    end
    
    log("error", "Invalid node input type: " .. type(node_input) .. ", using air")
    return minetest.get_content_id("air")
end

-- Get fallback node for a specific field type
local function get_fallback_node(field_name)
    local fallbacks = {
        node_water_top = "default:water_source",
        node_water = "default:water_source", 
        node_river_water = "default:water_source",
        node_cave_liquid = "default:water_source",
        node_riverbed = "default:sand",
        node_top = "default:dirt_with_grass",
        node_filler = "default:dirt",
        node_stone = "default:stone",
        node_dungeon = "default:stone",
        node_dungeon_alt = "default:stone",
        node_dungeon_stair = "default:stone"
    }
    
    local fallback_name = fallbacks[field_name] or "default:stone"
    
    -- Try the fallback, if it doesn't exist use air
    if minetest.registered_nodes[fallback_name] then
        return fallback_name
    else
        return "air"
    end
end

-- Biome definition validator
local function validate_biome_definition(biome_def)
    if not biome_def then
        return false, "Biome definition is nil"
    end
    
    if type(biome_def) ~= "table" then
        return false, "Biome definition must be a table, got " .. type(biome_def)
    end
    
    -- Validate name
    if not biome_def.name then
        return false, "Biome name is required"
    end
    
    if type(biome_def.name) ~= "string" then
        return false, "Biome name must be a string, got " .. type(biome_def.name)
    end
    
    if biome_def.name == "" then
        return false, "Biome name cannot be empty"
    end
    
    -- Validate arrays (if present)
    local array_fields = {
        "temperature_levels", "humidity_levels", "continentalness_names", 
        "erosion_levels", "pv_names"
    }
    
    for _, field in ipairs(array_fields) do
        if biome_def[field] then
            if type(biome_def[field]) ~= "table" then
                return false, field .. " must be a table"
            end
            if #biome_def[field] == 0 then
                return false, field .. " cannot be empty"
            end
        end
    end
    
    -- Validate numeric fields (if present)
    local numeric_fields = {
        "depth_min", "depth_max", "y_min", "y_max", "y_blend", 
        "priority", "depth_top", "depth_filler", "depth_water_top", "depth_riverbed"
    }
    
    for _, field in ipairs(numeric_fields) do
        if biome_def[field] and type(biome_def[field]) ~= "number" then
            return false, field .. " must be a number, got " .. type(biome_def[field])
        end
    end
    
    -- Validate priority range
    if biome_def.priority then
        if biome_def.priority < biome_registry.MIN_PRIORITY or biome_def.priority > biome_registry.MAX_PRIORITY then
            return false, "Priority must be between " .. biome_registry.MIN_PRIORITY .. " and " .. biome_registry.MAX_PRIORITY
        end
    end
    
    return true, "Valid"
end

-- Create a standardized biome definition
function biome_registry.create_biome_def(name, parameters, nodes, properties)
    log("info", "Creating biome definition for: " .. tostring(name))
    
    -- Validate inputs
    if not name or type(name) ~= "string" or name == "" then
        log("error", "Invalid biome name: " .. tostring(name))
        return nil
    end
    
    -- Set defaults
    parameters = parameters or {}
    nodes = nodes or {}
    properties = properties or {}
    
    -- Create the biome definition with all defaults
    local biome_def = {
        -- Core identification
        name = name,
        
        -- Climate parameters (with sensible defaults)
        temperature_levels = parameters.temperature_levels or {0, 1, 2, 3, 4},
        humidity_levels = parameters.humidity_levels or {0, 1, 2, 3, 4},
        continentalness_names = parameters.continentalness_names or {"near_inland", "mid_inland"},
        erosion_levels = parameters.erosion_levels or {2, 3, 4},
        pv_names = parameters.pv_names or {"low", "mid", "high"},
        
        -- Depth and height constraints
        depth_min = parameters.depth_min or 0,
        depth_max = parameters.depth_max or 1000,
        y_min = parameters.y_min or -31000,
        y_max = parameters.y_max or 31000,
        y_blend = parameters.y_blend or 0,
        
        -- Weirdness variant
        weirdness_variant = parameters.weirdness_variant or false,
        
        -- Node definitions (store as strings for now, resolve later)
        node_top = nodes.node_top or get_fallback_node("node_top"),
        node_filler = nodes.node_filler or get_fallback_node("node_filler"),
        node_stone = nodes.node_stone or get_fallback_node("node_stone"),
        node_water_top = nodes.node_water_top or get_fallback_node("node_water_top"),
        node_water = nodes.node_water or get_fallback_node("node_water"),
        node_river_water = nodes.node_river_water or get_fallback_node("node_river_water"),
        node_riverbed = nodes.node_riverbed or get_fallback_node("node_riverbed"),
        node_cave_liquid = nodes.node_cave_liquid or get_fallback_node("node_cave_liquid"),
        node_dungeon = nodes.node_dungeon or get_fallback_node("node_dungeon"),
        node_dungeon_alt = nodes.node_dungeon_alt or get_fallback_node("node_dungeon_alt"),
        node_dungeon_stair = nodes.node_dungeon_stair or get_fallback_node("node_dungeon_stair"),
        
        -- Properties
        depth_top = properties.depth_top or 1,
        depth_filler = properties.depth_filler or 3,
        depth_water_top = properties.depth_water_top or 0,
        depth_riverbed = properties.depth_riverbed or 2,
        priority = properties.priority or biome_registry.DEFAULT_PRIORITY,
        
        -- Additional properties
        transition_zones = properties.transition_zones or {},
        vertical_blend = properties.vertical_blend or 0,
        
        -- Surface covering configuration
        node_dust = properties.node_dust,
        
        -- Metadata
        _created_at = os.time(),
        _source = "biome_registry"
    }
    
    -- Validate the created definition
    local valid, error_msg = validate_biome_definition(biome_def)
    if not valid then
        log("error", "Created biome definition is invalid: " .. error_msg)
        return nil
    end
    
    log("info", "Successfully created biome definition for: " .. name)
    return biome_def
end

-- Register a biome in the registry
function biome_registry.register_biome(biome_def)
    log("info", "Registering biome: " .. tostring(biome_def and biome_def.name or "unknown"))
    
    -- Validate the biome definition
    local valid, error_msg = validate_biome_definition(biome_def)
    if not valid then
        log("error", "Cannot register biome - validation failed: " .. error_msg)
        return false
    end
    
    -- Create a deep copy to avoid reference issues
    local biome_copy = {}
    for k, v in pairs(biome_def) do
        if type(v) == "table" then
            biome_copy[k] = {}
            for k2, v2 in pairs(v) do
                biome_copy[k][k2] = v2
            end
        else
            biome_copy[k] = v
        end
    end
    
    -- Resolve all node references to content IDs
    local node_fields = {
        "node_top", "node_filler", "node_stone", "node_water_top", "node_water",
        "node_river_water", "node_riverbed", "node_cave_liquid", "node_dungeon",
        "node_dungeon_alt", "node_dungeon_stair"
    }
    
    for _, field in ipairs(node_fields) do
        if biome_copy[field] then
            local original_value = biome_copy[field]
            biome_copy[field] = resolve_node_to_content_id(biome_copy[field])
            
            -- Log the resolution
            if type(original_value) == "string" then
                log("info", "Resolved " .. field .. " '" .. original_value .. "' to content ID " .. biome_copy[field])
            end
        end
    end
    
    -- Resolve node dust node if present
    if biome_copy.node_dust then
        local original_node = biome_copy.node_dust
        
        -- Check if the node exists first
        if type(original_node) == "string" and minetest.registered_nodes[original_node] then
            biome_copy.node_dust = minetest.get_content_id(original_node)
            log("info", "Resolved node_dust '" .. original_node .. "' to content ID " .. biome_copy.node_dust)
        else
            log("warning", "Node dust node '" .. tostring(original_node) .. "' not found, removing node dust")
            biome_copy.node_dust = nil
        end
    end
    
    -- Add registration metadata
    biome_copy._registered_at = os.time()
    biome_copy._registry_version = "1.0"
    
    -- Check for conflicts
    if biome_registry.biomes[biome_copy.name] then
        log("warning", "Overwriting existing biome: " .. biome_copy.name)
    end
    
    -- Register the biome
    biome_registry.biomes[biome_copy.name] = biome_copy
    
    log("info", "Successfully registered biome: " .. biome_copy.name .. " (priority: " .. biome_copy.priority .. ")")
    
    -- Log registry statistics
    local total_count = 0
    local external_count = 0
    for biome_name, _ in pairs(biome_registry.biomes) do
        total_count = total_count + 1
        if biome_name:match(":") then
            external_count = external_count + 1
        end
    end
    
    log("info", "Registry now contains " .. total_count .. " biomes (" .. external_count .. " external)")
    
    return true
end

-- Unregister a biome
function biome_registry.unregister_biome(biome_name)
    if not biome_name or type(biome_name) ~= "string" then
        log("error", "Invalid biome name for unregistration: " .. tostring(biome_name))
        return false
    end
    
    if not biome_registry.biomes[biome_name] then
        log("warning", "Attempted to unregister non-existent biome: " .. biome_name)
        return false
    end
    
    biome_registry.biomes[biome_name] = nil
    log("info", "Unregistered biome: " .. biome_name)
    return true
end

-- Get a registered biome
function biome_registry.get_biome(biome_name)
    return biome_registry.biomes[biome_name]
end

-- Get all registered biomes
function biome_registry.get_all_biomes()
    -- Return a copy to prevent external modification
    local copy = {}
    for name, biome in pairs(biome_registry.biomes) do
        copy[name] = biome
    end
    return copy
end

-- Check if a biome is registered
function biome_registry.is_biome_registered(biome_name)
    return biome_registry.biomes[biome_name] ~= nil
end

-- Get biomes by criteria
function biome_registry.get_biomes_by_criteria(criteria)
    local matching_biomes = {}
    
    for name, biome in pairs(biome_registry.biomes) do
        local matches = true
        
        -- Check each criterion
        for key, value in pairs(criteria) do
            if biome[key] ~= value then
                matches = false
                break
            end
        end
        
        if matches then
            matching_biomes[name] = biome
        end
    end
    
    return matching_biomes
end

-- Get biomes sorted by priority
function biome_registry.get_biomes_by_priority()
    local biome_list = {}
    
    -- Convert to list
    for name, biome in pairs(biome_registry.biomes) do
        table.insert(biome_list, {name = name, biome = biome})
    end
    
    -- Sort by priority (highest first)
    table.sort(biome_list, function(a, b)
        return (a.biome.priority or 0) > (b.biome.priority or 0)
    end)
    
    return biome_list
end

-- Clear all biomes (for testing/reset)
function biome_registry.clear_all_biomes()
    biome_registry.biomes = {}
    biome_registry.content_ids_cache = {}
    log("info", "Cleared all biomes from registry")
end

-- Get registry statistics
function biome_registry.get_statistics()
    local stats = {
        total_biomes = 0,
        external_biomes = 0,
        default_biomes = 0,
        priority_distribution = {},
        node_usage = {}
    }
    
    for name, biome in pairs(biome_registry.biomes) do
        stats.total_biomes = stats.total_biomes + 1
        
        if name:match(":") then
            stats.external_biomes = stats.external_biomes + 1
        else
            stats.default_biomes = stats.default_biomes + 1
        end
        
        -- Priority distribution
        local priority = biome.priority or 0
        stats.priority_distribution[priority] = (stats.priority_distribution[priority] or 0) + 1
    end
    
    return stats
end

-- Initialize the registry
function biome_registry.initialize()
    if biome_registry.initialized then
        log("info", "Registry already initialized")
        return true
    end
    
    log("info", "Initializing biome registry")
    
    -- Clear any existing state
    biome_registry.biomes = {}
    biome_registry.content_ids_cache = {}
    
    biome_registry.initialized = true
    log("info", "Biome registry initialized successfully")
    
    return true
end

-- Validate registry integrity
function biome_registry.validate_integrity()
    local issues = {}
    
    for name, biome in pairs(biome_registry.biomes) do
        local valid, error_msg = validate_biome_definition(biome)
        if not valid then
            table.insert(issues, "Biome '" .. name .. "': " .. error_msg)
        end
    end
    
    if #issues > 0 then
        log("warning", "Registry integrity issues found:")
        for _, issue in ipairs(issues) do
            log("warning", "  - " .. issue)
        end
        return false, issues
    end
    
    log("info", "Registry integrity check passed")
    return true, {}
end

-- Export the registry
return biome_registry