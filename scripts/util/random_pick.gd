class_name RandomPick
extends RefCounted
## Random choices between named options.


## One of the keys of `weights`, each as likely as its weight (a float).
static func weighted(weights: Dictionary) -> Variant:
	var total := 0.0
	for option: Variant in weights:
		total += weights[option]
	var roll := randf() * total
	for option: Variant in weights:
		roll -= weights[option]
		if roll <= 0.0:
			return option
	return weights.keys()[0]
