class_name FxTrailDef
extends RefCounted
## A particle system's trails (Unity's Trails module, per particle): each particle leaves a
## ribbon behind it, drawn with the renderer's trail material. See FxTrails.

var ratio := 1.0  ## the share of particles that get a trail
var lifetime: FxCurve  ## how long a trail point lasts, as a share of the particle's lifetime
var min_vertex_distance := 0.1  ## Unity units a particle moves before a new trail point
var width_over_trail: FxCurve  ## from the particle (0) to the tail (1)
var color_over_trail: FxColorCurve
var color_over_lifetime: FxColorCurve  ## over the particle's life
var size_affects_width := true
var inherit_particle_color := false
var material: FxMaterialDef


static func from_json(data: Dictionary, material_data: Dictionary) -> FxTrailDef:
	var trail := FxTrailDef.new()
	trail.ratio = data.get("ratio", 1.0)
	trail.lifetime = FxCurve.from_json(data.lifetime)
	trail.min_vertex_distance = data.get("min_vertex_distance", 0.1)
	trail.width_over_trail = FxCurve.from_json(data.width_over_trail)
	trail.color_over_trail = FxColorCurve.from_json(data.color_over_trail)
	trail.color_over_lifetime = FxColorCurve.from_json(data.color_over_lifetime)
	trail.size_affects_width = data.get("size_affects_width", true)
	trail.inherit_particle_color = data.get("inherit_particle_color", false)
	if not material_data.is_empty():
		trail.material = FxMaterialDef.from_json(material_data, {})
	return trail


## Seconds a point of this particle's trail lasts.
func point_life(particle: FxParticle) -> float:
	return lifetime.sample(0.0, particle.custom_pick) * particle.lifetime
