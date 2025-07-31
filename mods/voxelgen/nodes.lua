-- nodes.lua - VoxelGen node management system
-- Provides fallback nodes when default mod is not available

local nodes = {}

-- Define basic nodes that VoxelGen needs
local basic_nodes = {
    stone = {
        name = "voxelgen:stone",
        description = "Stone",
        tiles = {"default_stone.png"},
        groups = {cracky = 3, stone = 1},
        drop = "voxelgen:stone",
        sounds = {
            footstep = {name = "default_hard_footstep", gain = 0.3},
            dug = {name = "default_hard_footstep", gain = 1.0},
        }
    },
    dirt = {
        name = "voxelgen:dirt",
        description = "Dirt",
        tiles = {"default_dirt.png"},
        groups = {crumbly = 3, soil = 1},
        sounds = {
            footstep = {name = "default_dirt_footstep", gain = 0.4},
            dug = {name = "default_dirt_footstep", gain = 1.0},
        }
    },
    dirt_with_grass = {
        name = "voxelgen:dirt_with_grass",
        description = "Dirt with Grass",
        tiles = {"default_grass.png", "default_dirt.png", 
                {name = "default_dirt.png^default_grass_side.png",
                 tileable_vertical = false}},
        groups = {crumbly = 3, soil = 1, spreading_dirt_type = 1},
        drop = "voxelgen:dirt",
        sounds = {
            footstep = {name = "default_grass_footstep", gain = 0.25},
        }
    },
    sand = {
        name = "voxelgen:sand",
        description = "Sand",
        tiles = {"default_sand.png"},
        groups = {crumbly = 3, falling_node = 1, sand = 1},
        sounds = {
            footstep = {name = "default_sand_footstep", gain = 0.12},
            dug = {name = "default_sand_footstep", gain = 0.24},
        }
    },
    gravel = {
        name = "voxelgen:gravel",
        description = "Gravel",
        tiles = {"default_gravel.png"},
        groups = {crumbly = 2, falling_node = 1},
        sounds = {
            footstep = {name = "default_gravel_footstep", gain = 0.4},
            dug = {name = "default_gravel_footstep", gain = 1.0},
        }
    },
    water_source = {
        name = "voxelgen:water_source",
        description = "Water Source",
        drawtype = "liquid",
        tiles = {
            {
                name = "default_water_source_animated.png",
                backface_culling = false,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 16,
                    aspect_h = 16,
                    length = 2.0,
                },
            },
            {
                name = "default_water_source_animated.png",
                backface_culling = true,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 16,
                    aspect_h = 16,
                    length = 2.0,
                },
            },
        },
        alpha = 160,
        paramtype = "light",
        walkable = false,
        pointable = false,
        diggable = false,
        buildable_to = true,
        is_ground_content = false,
        drop = "",
        drowning = 1,
        liquidtype = "source",
        liquid_alternative_flowing = "voxelgen:water_flowing",
        liquid_alternative_source = "voxelgen:water_source",
        liquid_viscosity = 1,
        post_effect_color = {a = 103, r = 30, g = 60, b = 90},
        groups = {water = 3, liquid = 3, cools_lava = 1},
        sounds = {
            footstep = {name = "default_water_footstep", gain = 0.18},
        }
    },
    water_flowing = {
        name = "voxelgen:water_flowing",
        description = "Flowing Water",
        drawtype = "flowingliquid",
        tiles = {"default_water.png"},
        special_tiles = {
            {
                name = "default_water_flowing_animated.png",
                backface_culling = false,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 16,
                    aspect_h = 16,
                    length = 0.5,
                },
            },
            {
                name = "default_water_flowing_animated.png",
                backface_culling = true,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 16,
                    aspect_h = 16,
                    length = 0.5,
                },
            },
        },
        alpha = 160,
        paramtype = "light",
        paramtype2 = "flowingliquid",
        walkable = false,
        pointable = false,
        diggable = false,
        buildable_to = true,
        is_ground_content = false,
        drop = "",
        drowning = 1,
        liquidtype = "flowing",
        liquid_alternative_flowing = "voxelgen:water_flowing",
        liquid_alternative_source = "voxelgen:water_source",
        liquid_viscosity = 1,
        post_effect_color = {a = 103, r = 30, g = 60, b = 90},
        groups = {water = 3, liquid = 3, not_in_creative_inventory = 1, cools_lava = 1},
        sounds = {
            footstep = {name = "default_water_footstep", gain = 0.18},
        }
    },
    ice = {
        name = "voxelgen:ice",
        description = "Ice",
        tiles = {"default_ice.png"},
        is_ground_content = false,
        paramtype = "light",
        groups = {cracky = 3, cools_lava = 1, slippery = 3},
        sounds = {
            footstep = {name = "default_glass_footstep", gain = 0.3},
            dug = {name = "default_glass_footstep", gain = 1.0},
        }
    },
    snow = {
        name = "voxelgen:snow",
        description = "Snow",
        tiles = {"default_snow.png"},
        inventory_image = "default_snowball.png",
        wield_image = "default_snowball.png",
        paramtype = "light",
        buildable_to = true,
        floodable = true,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
            },
        },
        groups = {crumbly = 3, falling_node = 1, snowy = 1},
        sounds = {
            footstep = {name = "default_snow_footstep", gain = 0.15},
            dug = {name = "default_snow_footstep", gain = 0.2},
        }
    },
    dirt_with_snow = {
        name = "voxelgen:dirt_with_snow",
        description = "Dirt with Snow",
        tiles = {"default_snow.png", "default_dirt.png",
                {name = "default_dirt.png^default_snow_side.png",
                 tileable_vertical = false}},
        groups = {crumbly = 3, soil = 1, spreading_dirt_type = 1, snowy = 1},
        drop = "voxelgen:dirt",
        sounds = {
            footstep = {name = "default_snow_footstep", gain = 0.15},
        }
    },
    sandstone = {
        name = "voxelgen:sandstone",
        description = "Sandstone",
        tiles = {"default_sandstone.png"},
        groups = {crumbly = 1, cracky = 3},
        sounds = {
            footstep = {name = "default_stone_footstep", gain = 0.4},
            dug = {name = "default_stone_footstep", gain = 1.0},
        }
    },
    clay = {
        name = "voxelgen:clay",
        description = "Clay",
        tiles = {"default_clay.png"},
        groups = {crumbly = 3},
        drop = "voxelgen:clay_lump 4",
        sounds = {
            footstep = {name = "default_dirt_footstep", gain = 0.4},
            dug = {name = "default_dirt_footstep", gain = 1.0},
        }
    },
    clay_lump = {
        name = "voxelgen:clay_lump",
        description = "Clay Lump",
        inventory_image = "default_clay_lump.png",
        groups = {}
    }
}

-- Node mapping system
nodes.node_map = {}

-- Initialize the node system
function nodes.init()
    minetest.log("action", "[VoxelGen] Initializing node system...")
    
    -- Check if default mod is available
    local has_default = minetest.get_modpath("vlf_blocks") ~= nil
    
    if has_default then
        minetest.log("action", "[VoxelGen] Default mod found, using default nodes")
        -- Map to default nodes
        nodes.node_map = {
            stone = "vlf_blocks:stone",
           -- dirt = "vlf_blocks:dirt", 
            dirt_with_grass = "vlf_blocks:dirt_with_grass",
            --sand = "vlf_blocks:sand",
            --gravel = "vlf_blocks:gravel",
            water_source = "vlf_blocks:water_source",
            water_flowing = "vlf_blocks:water_flowing",
            --ice = "vlf_blocks:ice",
            --snow = "vlf_blocks:snow",
            --dirt_with_snow = "vlf_blocks:dirt_with_snow",
            --sandstone = "vlf_blocks:sandstone",
            --clay = "vlf_blocks:clay"
        }
    else
        minetest.log("action", "[VoxelGen] Default mod not found, registering fallback nodes")
        -- Register our own nodes and map to them
        for node_type, node_def in pairs(basic_nodes) do
            -- Only register if the node doesn't already exist
            if not minetest.registered_nodes[node_def.name] then
                minetest.register_node(node_def.name, node_def)
            end
            nodes.node_map[node_type] = node_def.name
        end
    end
    
    minetest.log("action", "[VoxelGen] Node system initialized with " .. 
                 (has_default and "default" or "fallback") .. " nodes")
end

-- Get the actual node name for a node type
function nodes.get(node_type)
    return nodes.node_map[node_type] or "air"
end

-- Get content ID for a node type
function nodes.get_content_id(node_type)
    local node_name = nodes.get(node_type)
    return minetest.get_content_id(node_name)
end

-- Check if a node type is available
function nodes.is_available(node_type)
    local node_name = nodes.get(node_type)
    return node_name ~= "air" and minetest.registered_nodes[node_name] ~= nil
end

-- Get all available node mappings
function nodes.get_all_mappings()
    return nodes.node_map
end

return nodes
