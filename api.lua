local S = core.get_translator("boats")

local function is_group(pos, group)
	local nn = core.get_node(pos).name
	return core.get_item_group(nn, group) ~= 0
end

function more_boats.groups(pos, groups)
	for _, group in pairs(groups) do
		if is_group(pos, group) then
			return true
		end
	end
	return false
end

local function get_velocity(v, yaw, y)
	local x = -math.sin(yaw) * v
	local z =  math.cos(yaw) * v
	return {x = x, y = y, z = z}
end

local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end

function more_boats.on_rightclick(self, clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	local name = clicker:get_player_name()
	if self.driver and name == self.driver then
		clicker:set_detach()

		player_api.set_animation(clicker, "stand", 30)
		local pos = clicker:get_pos()
		pos = {x = pos.x, y = pos.y + 0.2, z = pos.z}
		core.after(0.1, function()
			clicker:set_pos(pos)
		end)
	elseif not self.driver then
		clicker:set_attach(self.object, "",
			{x = 0.5, y = 1, z = -3}, {x = 0, y = 0, z = 0})

		self.driver = name
		player_api.player_attached[name] = true

		core.after(0.2, function()
			player_api.set_animation(clicker, "sit", 30)
		end)
		clicker:set_look_horizontal(self.object:get_yaw())
	end
end

function more_boats.on_detach_child(self, child)
	if child and child:get_player_name() == self.driver then
		player_api.player_attached[child:get_player_name()] = false

		self.driver = nil
		self.auto = false
	end
end

function more_boats.on_activate(self, staticdata, dtime_s)
	self.object:set_armor_groups({immortal = 1})
	if staticdata then
		self.v = tonumber(staticdata)
	end
	self.last_v = self.v
end

function more_boats.get_staticdata(self)
	return tostring(self.v)
end

function more_boats.on_punch(self, puncher)
	if not puncher or not puncher:is_player() or self.removed then
		return
	end
	local name = puncher:get_player_name()
	if self.driver and name == self.driver then
		self.driver = nil
		puncher:set_detach()
		player_api.player_attached[name] = false
	end
	if not self.driver then
		self.removed = true
		local inv = puncher:get_inventory()
		local luamob = self.object:get_luaentity().name
		if not core.is_creative_enabled(name)
				or not inv:contains_item("main", luamob) then
			local leftover = inv:add_item("main", luamob)
			if not leftover:is_empty() then
				core.add_item(self.object:get_pos(), leftover)
			end
		end
		local name = puncher:get_player_name()
		core.after(0.1, function()
			self.object:remove()
		end)
	end
end

function more_boats.on_step(self, dtime)
	self.v = get_v(self.object:get_velocity()) * math.sign(self.v)
	if self.driver then
		local driver_objref = core.get_player_by_name(self.driver)
		if driver_objref then
			local ctrl = driver_objref:get_player_control()
			if ctrl.up and ctrl.down then
				if not self.auto then
					self.auto = true
					core.chat_send_player(self.driver, S("Boat cruise mode on"))
				end
			elseif ctrl.down then
				self.v = self.v - dtime * 2.0
				if self.auto then
					self.auto = false
					core.chat_send_player(self.driver, S("Boat cruise mode off"))
				end
			elseif ctrl.up or self.auto then
				self.v = self.v + dtime * 2.0
			end
			if ctrl.left then
				if self.v < -0.001 then
					self.object:set_yaw(self.object:get_yaw() - dtime * 0.9)
				else
					self.object:set_yaw(self.object:get_yaw() + dtime * 0.9)
				end
			elseif ctrl.right then
				if self.v < -0.001 then
					self.object:set_yaw(self.object:get_yaw() + dtime * 0.9)
				else
					self.object:set_yaw(self.object:get_yaw() - dtime * 0.9)
				end
			end
		end
	end
	local velo = self.object:get_velocity()
	if not self.driver and
			self.v == 0 and velo.x == 0 and velo.y == 0 and velo.z == 0 then
		self.object:set_pos(self.object:get_pos())
		return
	end
	local drag = dtime * math.sign(self.v) * (0.01 + 0.0796 * self.v * self.v)
	if math.abs(self.v) <= math.abs(drag) then
		self.v = 0
	else
		self.v = self.v - drag
	end

	local p = self.object:get_pos()
	p.y = p.y - 0.5
	local new_velo
	local new_acce = {x = 0, y = 0, z = 0}
	local group = self.node_group
	if not more_boats.groups(p, group) then
		local nodedef = core.registered_nodes[core.get_node(p).name]
		if (not nodedef) or nodedef.walkable then
			self.v = 0
			new_acce = {x = 0, y = 1, z = 0}
		else
			new_acce = {x = 0, y = -9.8, z = 0}
		end
		new_velo = get_velocity(self.v, self.object:get_yaw(),
			self.object:get_velocity().y)
		self.object:set_pos(self.object:get_pos())
	else
		p.y = p.y + 1
		if more_boats.groups(p, group) then
			local y = self.object:get_velocity().y
			if y >= 5 then
				y = 5
			elseif y < 0 then
				new_acce = {x = 0, y = 20, z = 0}
			else
				new_acce = {x = 0, y = 5, z = 0}
			end
			new_velo = get_velocity(self.v, self.object:get_yaw(), y)
			self.object:set_pos(self.object:get_pos())
		else
			new_acce = {x = 0, y = 0, z = 0}
			if math.abs(self.object:get_velocity().y) < 1 then
				local pos = self.object:get_pos()
				pos.y = math.floor(pos.y) + 0.5
				self.object:set_pos(pos)
				new_velo = get_velocity(self.v, self.object:get_yaw(), 0)
			else
				new_velo = get_velocity(self.v, self.object:get_yaw(),
					self.object:get_velocity().y)
				self.object:set_pos(self.object:get_pos())
			end
		end
	end
	self.object:set_velocity(new_velo)
	self.object:set_acceleration(new_acce)
end

function more_boats.register_boat(name, def)
	more_boats.registered_boats[name] = def
	local group = def.group
	if not group then
		group = {}
	end
	table.insert(group, "water")

	local boat_def = {
		initial_properties = {
			physical = true,
			collisionbox = {-0.5, -0.35, -0.5, 0.5, 0.3, 0.5},
			visual = "mesh",
			mesh = "boats_boat.obj",
			textures = {def.texture},
		},
		driver = nil,
		node_group = group,
		v = 0,
		last_v = 0,
		removed = false,
		auto = false
	}

	boat_def.on_rightclick = more_boats.on_rightclick
	boat_def.on_detach_child = more_boats.on_detach_child
	boat_def.on_activate = more_boats.on_step
	boat_def.get_staticdata = more_boats.get_staticdata
	boat_def.on_punch = more_boats.on_punch
	boat_def.on_step = more_boats.on_step

	core.register_entity(name, boat_def)
	core.register_craftitem(name, {
		description = def.description,
		inventory_image = def.texture.."^[mask:more_boats_inv_mask.png",
		wield_image = def.texture.."^[mask:more_boats_wield_mask.png",
		wield_scale = {x = 2, y = 2, z = 1},
		liquids_pointable = true,
		groups = {flammable = 2},
		on_place = function(itemstack, placer, pointed_thing)
			local under = pointed_thing.under
			local node = core.get_node(under)
			local udef = core.registered_nodes[node.name]
			if udef and udef.on_rightclick and
					not (placer and placer:is_player() and
					placer:get_player_control().sneak) then
				return udef.on_rightclick(under, node, placer, itemstack,
					pointed_thing) or itemstack
			end
			if pointed_thing.type ~= "node" then
				return itemstack
			end
			if not more_boats.groups(pointed_thing.under, group) then
				return itemstack
			end
			pointed_thing.under.y = pointed_thing.under.y + 0.5
			boat = core.add_entity(pointed_thing.under, name)
			if boat then
				if placer then
					boat:set_yaw(placer:get_look_horizontal())
				end
				local player_name = placer and placer:get_player_name() or ""
				if not core.is_creative_enabled(player_name) then
					itemstack:take_item()
				end
			end
			return itemstack
		end,
	})

	local m = def.material
	core.register_craft({
		output = name,
		recipe = {
			{m, "",m},
			{m, m, m},
		}
	})

	if not def.no_fuel then
		if def.cooking then
			core.register_craft({
				type = "cooking",
				output = def.cooking,
				recipe = name,
				cooktime = 15,
			})
		else
			core.register_craft({
				type = "fuel",
				recipe = name,
				burntime = 20,
			})
		end
	end
end