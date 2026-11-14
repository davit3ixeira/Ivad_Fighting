class_name EntityVisuals
extends RefCounted


static func create(visual: String) -> EntityView:
	match visual:
		"gravity_well":
			return GravityWellView.new()
		"cosmic_mark":
			return CosmicMarkView.new()
		"singularity":
			return SingularityView.new()
	return EntityView.new()
