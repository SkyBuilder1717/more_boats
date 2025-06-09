local modname = core.get_current_modname()
local S = core.get_translator(modname)

more_boats = {
	registered_boats = {},
	boats = {
		["more_boats:aspen_boat"] = {
			description = S("Aspen Boat"),
			texture = "default_aspen_wood.png",
			material = "default:aspen_wood"
		},
		["more_boats:acacia_boat"] = {
			description = S("Acacia Boat"),
			texture = "default_acacia_wood.png",
			material = "default:acacia_wood"
		},
		["more_boats:pine_boat"] = {
			description = S("Pine Boat"),
			texture = "default_pine_wood.png",
			material = "default:pine_wood"
		},
		["more_boats:jungle_boat"] = {
			description = S("Jungle Wood Boat"),
			texture = "default_junglewood.png",
			material = "default:junglewood"
		},
		["more_boats:obsidian_boat"] = {
			description = S("Obsidian Boat"),
			texture = "default_obsidian.png",
			material = "default:obsidian",
			group = {"lava"},
			no_fuel = true
		}
	}
}

local modpath = core.get_modpath(modname)
dofile(modpath .."/api.lua")

core.clear_craft({
	output = "boats:boat",
	recipe = {
		{"",           "",           ""          },
		{"group:wood", "",           "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
	}
}) 
core.register_craft({
	output = "boats:boat",
	recipe = {
		{"default:wood", "", "default:wood"},
		{"default:wood", "default:wood", "default:wood"},
	},
})

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

for name, def in pairs(more_boats.boats) do
	more_boats.register_boat(name, def)
end