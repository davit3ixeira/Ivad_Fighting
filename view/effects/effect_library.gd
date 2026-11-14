class_name EffectLibrary
extends RefCounted

const BURSTS := {
	"cosmic_ring": {
		"lifetime": 28, "start_radius": 16.0, "radius": 150.0, "ring_width": 5.0, "inner_ring": true,
		"stars": 12, "star_size": 9.0, "spin": 1.2, "rays": 8, "ray_length": 70.0, "flash": 46.0,
	},
	"supernova": {
		"lifetime": 44, "start_radius": 30.0, "radius": 430.0, "ring_width": 9.0, "inner_ring": true,
		"stars": 22, "star_size": 13.0, "spin": 0.6, "rays": 16, "ray_length": 300.0, "flash": 190.0,
	},
	"clash": {
		"lifetime": 12, "start_radius": 6.0, "radius": 54.0, "ring_width": 3.0, "stars": 6, "star_size": 6.0, "flash": 16.0,
	},
	"well_pop": {
		"lifetime": 14, "start_radius": 20.0, "radius": 64.0, "ring_width": 3.0, "stars": 5, "star_size": 6.0,
	},
	"hellfire": {
		"lifetime": 16, "start_radius": 10.0, "radius": 76.0, "ring_width": 4.0, "rays": 7, "ray_length": 54.0, "flash": 24.0,
	},
	"hellfire_burst": {
		"lifetime": 30, "start_radius": 20.0, "radius": 200.0, "ring_width": 7.0, "inner_ring": true, "rays": 12, "ray_length": 130.0, "flash": 80.0,
	},
	"pact": {
		"lifetime": 28, "start_radius": 12.0, "radius": 150.0, "ring_width": 5.0, "inner_ring": true, "rays": 10, "ray_length": 90.0, "flash": 40.0,
	},
	"true_form": {
		"lifetime": 36, "start_radius": 30.0, "radius": 300.0, "ring_width": 8.0, "inner_ring": true, "rays": 14, "ray_length": 200.0, "flash": 100.0,
	},
	"armor": {
		"lifetime": 12, "start_radius": 8.0, "radius": 58.0, "ring_width": 4.0, "stars": 4, "star_size": 7.0, "flash": 20.0,
	},
	"grab": {
		"lifetime": 12, "start_radius": 6.0, "radius": 48.0, "ring_width": 3.0, "rays": 6, "ray_length": 30.0,
	},
	"mark_plant": {
		"lifetime": 20, "start_radius": 8.0, "radius": 74.0, "ring_width": 3.0, "stars": 6, "star_size": 7.0, "flash": 14.0,
	},
}



static func create(effect_name: String, params: Dictionary) -> Node2D:
	if BURSTS.has(effect_name):
		var burst := BurstEffect.new()
		burst.setup(BURSTS[effect_name], params)
		return burst
	match effect_name:
		"rift":
			var rift := RiftEffect.new()
			rift.setup({}, params)
			return rift
	return null
