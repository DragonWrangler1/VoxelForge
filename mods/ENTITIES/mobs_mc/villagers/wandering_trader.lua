local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)
local spawn_interval = 20 * 60
local max_lifetime = 60 * 60
local current_chance = 25
local wandering_trader = table.copy(mobs_mc.villager_mob)

local function E(f, t)
	return { "mcl_core:emerald", f or 1, t or f or 1 }
end

local function get_random_color()
	local _, color = table.random_element(mcl_dyes.colors)
	return color
end

local function get_random_dye()
	return "mcl_dyes:"..get_random_color()
end

local function get_random_tree()
	local _, wood = table.random_element(mcl_trees.woods)
	return "mcl_trees:tree_"..wood
end

local function get_random_sapling()
	local r = {}
	for k, v in pairs(mcl_trees.woods) do
		local sap = "mcl_trees:sapling_"..k
		if minetest.registered_nodes[sap] then
			table.insert(r, sap)
		end
	end
	return table.random_element(r)
end

local function get_random_flower()
	local _, flower = table.random_element(mcl_flowers.registered_simple_flowers)
	return flower
end

local wandering_trader_purchasing_table = {
	{ { "mcl_potions:water", 1, 1, }, E() },
	{ { "mcl_buckets:bucket_water", 1, 1, }, E(2) },
	{ { "mcl_mobitems:milk_bucket", 1, 1, }, E(2) },
	{ { "mcl_potions:fermented_spider_eye", 1, 1, }, E(3) },
	{ { "mcl_farming:potato_item_baked", 1, 1, }, E(1) },
	{ { "mcl_farming:hay_block", 1, 1, }, E(1) },
}

local wandering_trader_special_table = {
	{ E(), { "mcl_core:packed_ice", 1, 1, } },
	{ E(), { "mcl_mobitems:gunpowder", 4, 4, } },
	{ E(), { get_random_tree, 8, 8, } },
	{ E(3), { "mcl_core:podzol", 3, 3, } },
	{ E(5), { "mcl_core:ice", 1, 1, } },
	{ E(6), { "mcl_potions:invisibility", 1, 1, } },
	{ E(6, 20), { "mcl_tools:pick_diamond_enchanted", 1, 1 } },
}
local wandering_trader_ordinary_table = {
	{ E(), { "mcl_flowers:fern", 1, 1, } },
	{ E(), { "mcl_core:reeds", 1, 1, } },
	{ E(), { "mcl_farming:pumpkin", 1, 1, } },
	{ E(), { get_random_flower, 1, 1, } },

	{ E(), { "mcl_farming:wheat_seeds", 1, 1, } },
	{ E(), { "mcl_farming:beetroot_seeds", 1, 1, } },
	{ E(), { "mcl_farming:pumpkin_seeds", 1, 1, } },
	{ E(), { "mcl_farming:melon_seeds", 1, 1, } },
	{ E(5), { get_random_sapling, 8, 8, } },
	{ E(), { get_random_dye, 1, 1, } },
	{ E(), { "mcl_core:vine", 3, 3, } },
	{ E(), { "mcl_flowers:waterlily", 3, 3, } },
	{ E(), { "mcl_core:sand", 3, 3, } },
	{ E(), { "mcl_core:redsand", 3, 3, } },
	--{ E(), { "TODO: small_dripleaf", 3, 3, } },
	{ E(), { "mcl_mushrooms:mushroom_brown", 3, 3, } },
	{ E(), { "mcl_mushrooms:mushroom_red", 3, 3, } },
}


local function get_wandering_trades()
	local t = {}
	for i=1,2 do
		table.insert(t, wandering_trader_purchasing_table[math.random(#wandering_trader_purchasing_table)])
		table.insert(t, wandering_trader_special_table[math.random(#wandering_trader_special_table)])
	end
	for i=1,5 do
		table.insert(t, wandering_trader_ordinary_table[math.random(#wandering_trader_ordinary_table)])
	end
	return { t }
end

function wandering_trader:do_custom(dtime)

end

function wandering_trader:on_spawn(dtime)
	if self._id then
		if os.time() - self._spawn_time > max_lifetime then
			self:safe_remove()
		end
		self:set_textures()
		return
	end
	self._id = minetest.sha1(minetest.get_gametime()..minetest.pos_to_string(self.object:get_pos())..tostring(math.random()))
	self._spawn_time = os.time()
	self:set_textures()
end

function wandering_trader:on_rightclick(clicker)
	self._profession = "wandering_trader"
	self:init_trader_vars()
	local name = clicker:get_player_name()
	self._trading_players[name] = true

	if self._trades == nil or self._trades == false then
		mobs_mc.professions["wandering_trader"].trades = get_wandering_trades()
		self:init_trades()
	end
	self:update_max_tradenum()
	if self._trades == false then
		return
	end

	local inv = minetest.get_inventory({type="detached", name="mobs_mc:trade_"..name})
	if not inv then
		return
	end

	self:show_trade_formspec(name)

	local selfpos = self.object:get_pos()
	local clickerpos = clicker:get_pos()
	local dir = vector.direction(selfpos, clickerpos)
	self.object:set_yaw(minetest.dir_to_yaw(dir))
	self:stand_still()
end

table.update(wandering_trader, {
	description = S("Wandering Trader"),
	textures = {
		"mobs_mc_villager.png",
		"mobs_mc_villager.png", --hat
	},
	_profession = "wandering_trader",
})

mcl_mobs.register_mob("mobs_mc:wandering_trader", wandering_trader)

-- spawn eggs
mcl_mobs.register_egg("mobs_mc:wandering_trader", S("Wandering Trader"), "#1E90FF", "#bc8b72", 0)

function mobs_mc.spawn_trader_llama(pos)
	local o = minetest.add_entity(pos, "mobs_mc:llama")
	if o then
		local ot = o:get_properties().textures
		o:set_properties({
			textures = {"blank.png", "mobs_mc_llama_decor_wandering_trader.png", ot[3]},
		})
	end
end

function mobs_mc.spawn_wandering_trader(pos)
	minetest.add_entity(pos, "mobs_mc:wandering_trader")
	for i=1,math.random(2) do
		mobs_mc.spawn_trader_llama(pos)
	end
end

minetest.register_chatcommand("spawn_wandering_trader", {
	privs = { debug = true, },
	func = function(pn, pr)
		local pl = minetest.get_player_by_name(pn)
		mobs_mc.spawn_wandering_trader(pl:get_pos())
	end,
})

local function attempt_trader_spawn()
	if math.random(100) < current_chance then
		current_chance = 25
		local ow_players = {}
		for _, pl in pairs(minetest.get_connected_players()) do
			if mcl_worlds.pos_to_dimension(pl:get_pos()) == "overworld" then
				table.insert(ow_players, pl)
			end
		end
		table.shuffle(ow_players)

		--spawn_trader
	else
		current_chance = current_chance + 25
	end
	minetest.after(spawn_interval, attempt_trader_spawn)
end

minetest.after(spawn_interval, attempt_trader_spawn)
