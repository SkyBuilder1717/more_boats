local modname = core.get_current_modname()
local S = core.get_translator(modname)

more_boats = {
	registered_boats = {},
	boats = {
		["more_boats:aspen_boat"] = {
			description = S("Aspen Boat"),
			texture = "default_aspen_wood.png",
			material = "default:aspen_wood",
			fuel = true
		},
		["more_boats:acacia_boat"] = {
			description = S("Acacia Boat"),
			texture = "default_acacia_wood.png",
			material = "default:acacia_wood",
			fuel = true
		},
		["more_boats:pine_boat"] = {
			description = S("Pine Boat"),
			texture = "default_pine_wood.png",
			material = "default:pine_wood",
			fuel = true
		},
		["more_boats:jungle_boat"] = {
			description = S("Jungle Wood Boat"),
			texture = "default_junglewood.png",
			material = "default:junglewood",
			fuel = true
		},
		["more_boats:obsidian_boat"] = {
			description = S("Obsidian Boat"),
			texture = "default_obsidian.png",
			material = "default:obsidian",
			group = {"lava"}
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

for name, def in pairs(more_boats.boats) do
	more_boats.register_boat(name, def)
end