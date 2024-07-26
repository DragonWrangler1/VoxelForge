local S = minetest.get_translator("vlf_structures")
local modpath = minetest.get_modpath("vlf_structures")
vlf_structures = {}
vlf_structures.schempath = minetest.get_modpath("vlf_schematics")

dofile(modpath.."/api.lua")
dofile(modpath.."/shipwrecks.lua")
dofile(modpath.."/desert_temple.lua")
dofile(modpath.."/jungle_temple.lua")
dofile(modpath.."/ocean_ruins.lua")
dofile(modpath.."/witch_hut.lua")
dofile(modpath.."/igloo.lua")
dofile(modpath.."/woodland_mansion.lua")
dofile(modpath.."/ruined_portal.lua")
dofile(modpath.."/geode.lua")
dofile(modpath.."/pillager_outpost.lua")
dofile(modpath.."/end_spawn.lua")
dofile(modpath.."/end_city.lua")
dofile(modpath.."/ancient_hermitage.lua")
dofile(modpath.."/trial_chamber.lua")


vlf_structures.register_structure("desert_well",{
	place_on = {"group:sand"},
	fill_ratio = 0.01,
	flags = "place_center_x, place_center_z",
	not_near = { "desert_temple_new" },
	solid_ground = true,
	sidelen = 4,
	chunk_probability = 600,
	y_max = vlf_vars.mg_overworld_max,
	y_min = 1,
	y_offset = -2,
	biomes = { "Desert" },
	filenames = { vlf_structures.schempath.."/schems/vlf_structures_desert_well.mts" },
	after_place = function(pos,def,pr)
		local hl = def.sidelen / 2
		local p1 = vector.offset(pos,-hl,-hl,-hl)
		local p2 = vector.offset(pos,hl,hl,hl)
		if minetest.registered_nodes["vlf_sus_nodes:sand"] then
			local sus_poss = minetest.find_nodes_in_area(vector.offset(p1,0,-3,0), vector.offset(p2,0,-hl+2,0), {"vlf_core:sand","vlf_core:sandstone","vlf_core:redsand","vlf_core:redsandstone"})
			if #sus_poss > 0 then
				table.shuffle(sus_poss)
				for i = 1,pr:next(1,#sus_poss) do
					minetest.set_node(sus_poss[i],{name="vlf_sus_nodes:sand"})
					local meta = minetest.get_meta(sus_poss[i])
					meta:set_string("structure","desert_well")
				end
			end
		end
	end,
	loot = {
		["SUS"] = {
		{
			stacks_min = 1,
			stacks_max = 1,
			items = {
				{ itemstring = "vlf_pottery_sherds:arms_up", weight = 2, },
				{ itemstring = "vlf_pottery_sherds:brewer", weight = 2, },
				{ itemstring = "vlf_core:brick", weight = 1 },
				{ itemstring = "vlf_core:emerald", weight = 1 },
				{ itemstring = "vlf_core:stick", weight = 1 },
				{ itemstring = "vlf_sus_stew:stew", weight = 1 },

			}
		}},
	},
})

vlf_structures.register_structure("fossil",{
	place_on = {"group:material_stone","group:sand"},
	fill_ratio = 0.01,
	flags = "place_center_x, place_center_z",
	solid_ground = true,
	sidelen = 13,
	chunk_probability = 1000,
	y_offset = function(pr) return ( pr:next(1,16) * -1 ) -16 end,
	y_max = 15,
	y_min = vlf_vars.mg_overworld_min + 35,
	biomes = { "Desert" },
	filenames = {
		vlf_structures.schempath.."/schems/vlf_structures_fossil_skull_1.mts", -- 4×5×5
		vlf_structures.schempath.."/schems/vlf_structures_fossil_skull_2.mts", -- 5×5×5
		vlf_structures.schempath.."/schems/vlf_structures_fossil_skull_3.mts", -- 5×5×7
		vlf_structures.schempath.."/schems/vlf_structures_fossil_skull_4.mts", -- 7×5×5
		vlf_structures.schempath.."/schems/vlf_structures_fossil_spine_1.mts", -- 3×3×13
		vlf_structures.schempath.."/schems/vlf_structures_fossil_spine_2.mts", -- 5×4×13
		vlf_structures.schempath.."/schems/vlf_structures_fossil_spine_3.mts", -- 7×4×13
		vlf_structures.schempath.."/schems/vlf_structures_fossil_spine_4.mts", -- 8×5×13
	},
})

vlf_structures.register_structure("boulder",{
	filenames = {
		vlf_structures.schempath.."/schems/vlf_structures_boulder_small.mts",
		vlf_structures.schempath.."/schems/vlf_structures_boulder_small.mts",
		vlf_structures.schempath.."/schems/vlf_structures_boulder_small.mts",
		vlf_structures.schempath.."/schems/vlf_structures_boulder.mts",
		-- small boulder 3x as likely
	},
},true) --is spawned as a normal decoration. this is just for /spawnstruct

vlf_structures.register_structure("ice_spike_small",{
	filenames = { vlf_structures.schempath.."/schems/vlf_structures_ice_spike_small.mts"	},
},true) --is spawned as a normal decoration. this is just for /spawnstruct
vlf_structures.register_structure("ice_spike_large",{
	sidelen = 6,
	filenames = { vlf_structures.schempath.."/schems/vlf_structures_ice_spike_large.mts"	},
},true) --is spawned as a normal decoration. this is just for /spawnstruct

-- Debug command
local function dir_to_rotation(dir)
	local ax, az = math.abs(dir.x), math.abs(dir.z)
	if ax > az then
		if dir.x < 0 then
			return "270"
		end
		return "90"
	end
	if dir.z < 0 then
		return "180"
	end
	return "0"
end

minetest.register_chatcommand("spawnstruct", {
	params = "dungeon",
	description = S("Generate a pre-defined structure near your position."),
	privs = {debug = true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then return end
		local pos = player:get_pos()
		if not pos then return end
		pos = vector.round(pos)
		local dir = minetest.yaw_to_dir(player:get_look_horizontal())
		local rot = dir_to_rotation(dir)
		local pr = PseudoRandom(pos.x+pos.y+pos.z)
		local errord = false
		local message = S("Structure placed.")
		if param == "dungeon" and vlf_dungeons and vlf_dungeons.spawn_dungeon then
			vlf_dungeons.spawn_dungeon(pos, rot, pr)
		elseif param == "" then
			message = S("Error: No structure type given. Please use “/spawnstruct <type>”.")
			errord = true
		else
			for n,d in pairs(vlf_structures.registered_structures) do
				if n == param then
					vlf_structures.place_structure(pos,d,pr,math.random(),rot)
					return true,message
				end
			end
			message = S("Error: Unknown structure type. Please use “/spawnstruct <type>”.")
			errord = true
		end
		minetest.chat_send_player(name, message)
		if errord then
			minetest.chat_send_player(name, S("Use /help spawnstruct to see a list of available types."))
		end
	end
})
minetest.register_on_mods_loaded(function()
	local p = ""
	for n,_ in pairs(vlf_structures.registered_structures) do
		p = p .. " | "..n
	end
	minetest.registered_chatcommands["spawnstruct"].params = minetest.registered_chatcommands["spawnstruct"].params .. p
end)
