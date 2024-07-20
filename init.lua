
more_boats = {}
more_boats.boats = {
	{
		"Aspen Boat",
		"more_boats:aspen_boat",
		"more_boats_aspen_inv.png",
		"more_boats_aspen_wield.png",
		{"default_aspen_wood.png"},
		"default:aspen_wood"
	},
	{
		"Acacia Boat",
		"more_boats:acacia_boat",
		"more_boats_acacia_inv.png",
		"more_boats_acacia_wield.png",
		{"default_acacia_wood.png"},
		"default:acacia_wood"
	},
	{
		"Pine Boat",
		"more_boats:pine_boat",
		"more_boats_pine_inv.png",
		"more_boats_pine_wield.png",
		{"default_pine_wood.png"},
		"default:pine_wood"
	},
	{
		"Jungle Wood Boat",
		"more_boats:jungle_boat",
		"more_boats_jungle_inv.png",
		"more_boats_jungle_wield.png",
		{"default_junglewood.png"},
		"default:junglewood"
	},
	{
		"Obsidian Boat",
		"more_boats:obsidian_boat",
		"more_boats_obsidian_inv.png",
		"more_boats_obsidian_wield.png",
		{"default_obsidian.png"},
		"default:obsidian",
		true
	}
}
local S = minetest.get_translator("more_boats")
local modpath = minetest.get_modpath("more_boats")
dofile(modpath .."/api.lua")
minetest.clear_craft({
	output = "boats:boat",
	recipe = {
		{"",           "",           ""          },
		{"group:wood", "",           "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
	},
}) 
minetest.register_craft({
	output = "boats:boat",
	recipe = {
		{"", "", ""},
		{"default:wood", "", "default:wood"},
		{"default:wood", "default:wood", "default:wood"},
	},
})
local function is_water(pos)
	local nn = minetest.get_node(pos).name
	return minetest.get_item_group(nn, "water") ~= 0
end
local function is_lava(pos)
	local nn = minetest.get_node(pos).name
	return minetest.get_item_group(nn, "lava") ~= 0
end
for i, def in ipairs(more_boats.boats) do
	local desc = def[1]
	local name = def[2]
	local texture_inv = def[3]
	local texture_wield = def[4]
	local texture_boat = def[5]
	local material = def[6]
	local isnt_lava = def[7]
	local boat_def = {
		initial_properties = {
			physical = true,
			collisionbox = {-0.5, -0.35, -0.5, 0.5, 0.3, 0.5},
			visual = "mesh",
			mesh = "boats_boat.obj",
			textures = texture_boat,
		},
		driver = nil,
		v = 0,
		last_v = 0,
		removed = false,
		auto = false
	}
	boat_def.on_rightclick = more_boat.on_rightclick
	boat_def.on_detach_child = more_boat.on_detach_child
	boat_def.on_activate = more_boat.on_step
	boat_def.get_staticdata = more_boat.get_staticdata
	boat_def.on_punch = more_boat.on_punch
	if not isnt_lava then
		boat_def.on_step = more_boat.on_step
	else
		boat_def.on_step = more_boat.LAVA.on_step
	end
	minetest.register_entity(name, boat_def)
	minetest.register_craftitem(name, {
		description = S(desc),
		inventory_image = texture_inv,
		wield_image = texture_wield,
		wield_scale = {x = 2, y = 2, z = 1},
		liquids_pointable = true,
		groups = {flammable = 2},
		on_place = function(itemstack, placer, pointed_thing)
			local under = pointed_thing.under
			local node = minetest.get_node(under)
			local udef = minetest.registered_nodes[node.name]
			if udef and udef.on_rightclick and
					not (placer and placer:is_player() and
					placer:get_player_control().sneak) then
				return udef.on_rightclick(under, node, placer, itemstack,
					pointed_thing) or itemstack
			end
			if pointed_thing.type ~= "node" then
				return itemstack
			end
			if not isnt_lava then
				if not is_water(pointed_thing.under) then
					return itemstack
				end
			else
				if not is_lava(pointed_thing.under) then
					return itemstack
				end
			end
			pointed_thing.under.y = pointed_thing.under.y + 0.5
			boat = minetest.add_entity(pointed_thing.under, name)
			if boat then
				if placer then
					boat:set_yaw(placer:get_look_horizontal())
				end
				local player_name = placer and placer:get_player_name() or ""
				if not minetest.is_creative_enabled(player_name) then
					itemstack:take_item()
				end
			end
			return itemstack
		end,
	})
	minetest.register_craft({
		output = name,
		recipe = {
			{"", "", ""},
			{material, "", material},
			{material, material, material},
		}
	})
	if not is_lava then
		minetest.register_craft({
			type = "fuel",
			recipe = name,
			burntime = 20,
		})
	end
end
