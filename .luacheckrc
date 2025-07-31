-- Luacheck configuration for VoxelForge Reimagined
-- This defines the global variables available in the Minetest environment

-- Standard Minetest globals
globals = {
	-- Core Minetest API
	"minetest",
	"core",
	
	-- Vector utilities
	"vector",
	
	-- Item and inventory
	"ItemStack",
	
	-- Noise generation
	"PerlinNoise",
	"PseudoRandom",
	
	-- Mod-specific globals
	"i3",
	"fancy_place",
	"voxelgen",
	
	-- Optional mod integrations
	"armor",
	"sfinv",
	"unified_inventory",
	"awards",
	"skinsdb",
	
	-- Common utility functions that may be defined globally
	"IMPORT",
	"spawn_item",
	"get_detached_inv",
	"reset_data",
	"play_sound",
	"update_inv_size",
	"copy",
	"slz",
	"insert",
	"min",
	"max",
	"floor",
	"ceil",
	"abs",
	"random",
	"sort",
	"concat",
	"remove",
	"unpack",
	"pairs",
	"ipairs",
	"next",
	"type",
	"tostring",
	"tonumber",
	"setmetatable",
	"getmetatable",
	"rawget",
	"rawset",
	"rawlen",
	"select",
	"pcall",
	"xpcall",
	"error",
	"assert",
	"print",
	"string",
	"table",
	"math",
	"os",
	"io",
	"debug",
	"coroutine",
	"package",
	"require",
	"load",
	"loadfile",
	"loadstring",
	"dofile",
}

-- Allow setting these globals (for mod initialization)
allow_defined_top = true

-- Standard Lua version
std = "lua51+luajit"

-- Ignore some common patterns
ignore = {
	"212", -- Unused argument (common in callbacks)
	"213", -- Unused loop variable
	"311", -- Value assigned to a local variable is unused
	"314", -- Value of field is unused
}

-- File-specific configurations
files = {
	-- Test files can be more lenient
	["**/tests/**"] = {
		ignore = {"111", "112", "113"},
	},
}

exclude_files = {
    "mods/i3",
}

-- Maximum line length
max_line_length = 120

-- Don't check for trailing whitespace in specific cases
-- (will be handled by our cleanup)
