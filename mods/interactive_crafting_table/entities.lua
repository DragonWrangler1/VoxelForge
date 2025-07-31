
minetest.register_entity("interactive_crafting_table:item_display", {
    initial_properties = {
        visual = "wielditem",
        visual_size = {x = 0.3, y = 0.3},
        collisionbox = {0,0,0,0,0,0},
        physical = false,
        textures = {""},
    },
    on_activate = function(self, staticdata)
        if staticdata and staticdata ~= "" then
            -- Extract just the item name from the itemstack string
            local stack = ItemStack(staticdata)
            self.itemstring = stack:get_name()
            if self.itemstring and self.itemstring ~= "" then
                self.object:set_properties({
                    textures = {self.itemstring},
                    visual_size = {x = 0.3, y = 0.3},
                })
            end
        end
    end,
    on_step = function(self, dtime)
        self.timer = (self.timer or 0) + dtime
        if self.timer > 10 then
            self.object:remove()
        end
        
        -- Set the texture if we have an itemstring
        if self.itemstring and not self.image_set then
            self.object:set_properties({
                textures = {self.itemstring},
                visual_size = {x = 0.3, y = 0.3},
            })
            self.image_set = true
        end
    end,
    get_staticdata = function(self)
        return self.itemstring or ""
    end,
})

-- Entity for displaying items in the crafting grid
minetest.register_entity("interactive_crafting_table:grid_item_display", {
    initial_properties = {
        visual = "wielditem",
        visual_size = {x = 0.15, y = 0.15},
        collisionbox = {0,0,0,0,0,0},
        physical = false,
        textures = {""},
        makes_footstep_sound = false,
        automatic_rotate = 0,
        selectionbox = {0,0,0,0,0,0},
        pointable = false,
    },
    on_activate = function(self, staticdata)
        if staticdata and staticdata ~= "" then
            self.itemstring = staticdata
            -- Set the texture to the item name directly
            self.object:set_properties({
                textures = {self.itemstring},
                visual_size = {x = 0.15, y = 0.15},
            })
            -- Rotate to lay flat on the table (90 degrees around X axis)
            self.object:set_rotation({x = math.pi/2, y = 0, z = 0})
        end
    end,
    on_step = function(self, dtime)
        -- Ensure it stays flat and has correct properties
        if self.itemstring and not self.setup_complete then
            self.object:set_properties({
                textures = {self.itemstring},
                visual_size = {x = 0.15, y = 0.15},
            })
            self.object:set_rotation({x = math.pi/2, y = 0, z = 0})
            self.setup_complete = true
        end
        
        -- Handle vertical-only bounce animation
        if self.bouncing and self.bounce_start_time and self.original_pos then
            local current_time = minetest.get_us_time() / 1000000
            local elapsed = current_time - self.bounce_start_time
            
            if elapsed <= self.bounce_duration then
                -- Calculate bounce position using a sine wave for smooth animation
                local progress = elapsed / self.bounce_duration
                local bounce_y = math.sin(progress * math.pi) * self.bounce_height
                
                -- Update position - only Y changes, X and Z stay the same
                self.object:set_pos({
                    x = self.original_pos.x,
                    y = self.original_pos.y + bounce_y,
                    z = self.original_pos.z
                })
            end
        end
    end,
    get_staticdata = function(self)
        return self.itemstring or ""
    end,
})

-- Entity for displaying the crafted item result on top of the table
minetest.register_entity("interactive_crafting_table:crafted_item_display", {
    initial_properties = {
        visual = "wielditem",
        visual_size = {x = 0.4, y = 0.4},
        collisionbox = {0,0,0,0,0,0},
        physical = false,
        glow = 5,
        textures = {""},
    },
    on_activate = function(self, staticdata)
        if staticdata and staticdata ~= "" then
            -- Extract just the item name from the itemstack string
            local stack = ItemStack(staticdata)
            self.itemstring = stack:get_name()
            if self.itemstring and self.itemstring ~= "" then
                self.object:set_properties({
                    textures = {self.itemstring},
                    visual_size = {x = 0.4, y = 0.4},
                })
            end
        end
    end,
    on_step = function(self, dtime)
        -- Rotate the item slowly for visual appeal
        self.timer = (self.timer or 0) + dtime
        local yaw = self.timer * 0.5
        self.object:set_yaw(yaw)
        
        -- Bob up and down slightly
        local bob = math.sin(self.timer * 2) * 0.1
        local pos = self.object:get_pos()
        if pos and self.base_y then
            self.object:set_pos({x = pos.x, y = self.base_y + bob, z = pos.z})
        elseif pos and not self.base_y then
            self.base_y = pos.y
        end
        
        -- Set the texture if we have an itemstring
        if self.itemstring and not self.image_set then
            self.object:set_properties({
                textures = {self.itemstring},
                visual_size = {x = 0.4, y = 0.4},
            })
            self.image_set = true
        end
    end,
    get_staticdata = function(self)
        return self.itemstring or ""
    end,
})

function spawn_items_on_table(pos, inv)
    for i = 1, 9 do
        local stack = inv:get_stack("grid", i)
        if not stack:is_empty() then
            local offset = vector.new(((i-1)%3 - 1) * 0.3, 0.6, (math.floor((i-1)/3) - 1) * 0.3)
            -- Pass the full stack string as staticdata for bouncing items
            local ent = minetest.add_entity(vector.add(pos, offset), "interactive_crafting_table:item_display", stack:to_string())
            -- The entity will handle extracting the item name in its on_activate function
        end
    end
end

-- Function to display items in the crafting grid (always visible)
function update_grid_display(pos, inv)
    -- Remove existing grid item displays
    for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 2)) do
        local ent = obj:get_luaentity()
        if ent and ent.name == "interactive_crafting_table:grid_item_display" then
            obj:remove()
        end
    end
    
    -- Add new grid item displays
    for i = 1, 9 do
        local stack = inv:get_stack("grid", i)
        if not stack:is_empty() then
            -- Position items lower on the table surface with smaller spacing for tiny gaps
            local offset = vector.new(((i-1)%3 - 1) * 0.25, 0.55, (math.floor((i-1)/3) - 1) * 0.25)
            -- Pass the item name directly as staticdata
            local item_name = stack:get_name()
            local ent = minetest.add_entity(vector.add(pos, offset), "interactive_crafting_table:grid_item_display", item_name)
            -- The entity will handle the rest in its on_activate function
        end
    end
end

function make_items_bounce(pos)
    for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 1)) do
        local ent = obj:get_luaentity()
        if ent and ent.name == "interactive_crafting_table:grid_item_display" then
            -- Make the grid items bounce only vertically (Y-axis only)
            local current_pos = obj:get_pos()
            if current_pos then
                -- Store original position for later restoration
                if not ent.original_pos then
                    ent.original_pos = {x = current_pos.x, y = current_pos.y, z = current_pos.z}
                end
                ent.bouncing = true
                
                -- Simple vertical bounce animation - no X or Z movement
                local bounce_height = math.random() * 0.3 + 0.2  -- Random bounce between 0.2 and 0.5 units
                local bounce_duration = 0.4  -- Duration of bounce animation
                
                -- Animate the bounce using position interpolation
                local start_time = minetest.get_us_time() / 1000000
                ent.bounce_start_time = start_time
                ent.bounce_height = bounce_height
                ent.bounce_duration = bounce_duration
                
                -- Reset after bounce completes
                minetest.after(bounce_duration + 0.1, function()
                    if obj and obj:get_pos() and ent.original_pos then
                        obj:set_pos(ent.original_pos)
                        obj:set_rotation({x = math.pi/2, y = 0, z = 0})  -- Ensure it stays flat
                        ent.bouncing = false
                        ent.bounce_start_time = nil
                    end
                end)
            end
        end
    end
end

function spawn_particles(pos)
    minetest.add_particlespawner({
        amount = 50,
        time = 1,
        minpos = vector.add(pos, {x=-0.5, y=0.5, z=-0.5}),
        maxpos = vector.add(pos, {x=0.5, y=1, z=0.5}),
        minvel = {x=-1, y=1, z=-1},
        maxvel = {x=1, y=2, z=1},
        minacc = {x=0, y=-2, z=0},
        maxacc = {x=0, y=-4, z=0},
        texture = "craft_particle.png",
        glow = 5,
    })
end

function drop_crafted_item(pos, item)
    minetest.add_item(vector.add(pos, {x=0, y=1, z=0}), ItemStack(item))
end
