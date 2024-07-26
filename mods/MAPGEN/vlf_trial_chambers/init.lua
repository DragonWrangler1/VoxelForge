-- Register the schematic placer node
minetest.register_node("vlf_trial_chambers:reward_all", {
    description = "Schematic Placer",
    tiles = {"default_wood.png"},
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
   --[[ on_construct = function(pos)
        minetest.get_node_timer(pos):start(1)
    end,
    on_timer = function(pos)
        -- Specify the schematic file path and position offset
        local schematic_path = minetest.get_modpath("vlf_trial_chambers") .. "/schematics/my_schematic.mts"
        local offset = {x = 0, y = -1, z = 0} -- Position in front of the node

        -- Get the position in front of the node
        local node = minetest.get_node(pos)
        local front_pos = vector.add(pos, offset)

        -- Place the schematic at the specified position
        minetest.place_schematic(front_pos, schematic_path, "90", nil, false)
        minetest.set_node(pos, {name = "air"})
    end,]]
})

--[[ Register the on_generated function
minetest.register_on_generated(function(minp, maxp, seed)
    -- Iterate over all nodes in the generated chunk
    for x = minp.x, maxp.x do
        for y = minp.y, maxp.y do
            for z = minp.z, maxp.z do
                local pos = {x = x, y = y, z = z}
                local node = minetest.get_node(pos)

                -- Check if the node is the schematic placer
                if node.name == "vlf_trial_chambers:reward_all" then
                    -- Specify the schematic file path and position offset
                    local schematic_path = minetest.get_modpath("vlf_trial_chambers") .. "/schems/my_schematic.mts"
                    local offset = {x = 0, y = -1, z = 0} -- Position in front of the node

                    -- Get the position in front of the node
                    local front_pos = vector.add(pos, offset)

                    -- Place the schematic at the specified position
                    minetest.place_schematic(front_pos, schematic_path, "90", nil, false)

                    -- Replace the schematic placer node with air
                    minetest.set_node(pos, {name = "air"})
                end
            end
        end
    end
end)
]]

--[[ Register the LBM
minetest.register_lbm({
    name = "vlf_trial_chambers:place_schematic",
    nodenames = {"vlf_trial_chambers:reward_all"},
    run_at_every_load = false,
    action = function(pos, node)
        -- Specify the schematic file path and position offset
        local schematic_path = minetest.get_modpath("vlf_trial_chambers") .. "/schematics/my_schematic.mts"
        local offset = {x = 0, y = -1, z = 0} -- Position in front of the node

        -- Get the position in front of the node
        local front_pos = vector.add(pos, offset)

        -- Place the schematic at the specified position
        minetest.place_schematic(front_pos, schematic_path, "random", nil, false)

        -- Replace the schematic placer node with air
        minetest.set_node(pos, {name = "air"})
    end,
})]]

minetest.register_abm({
    label = "Place Schematic",
    nodenames = {"vlf_trial_chambers:reward_all"},
    interval = 1.0,
    chance = 2,
    action = function(pos, node)
        -- Specify the schematic file path and position offset
        local schematic_path = minetest.get_modpath("vlf_trial_chambers") .. "/schematics/my_schematic.mts"
        local offset = {x = 1, y = 0, z = 0} -- Position in front of the node

        -- Get the position in front of the node
        local front_pos = vector.add(pos, offset)

        -- Place the schematic at the specified position
        minetest.place_schematic(front_pos, schematic_path, "90", nil, false)

        -- Replace the schematic placer node with air
        minetest.set_node(pos, {name = "air"})
    end,
})
