class_name FxCustomData
extends RefCounted
## A particle system's custom data (Unity's Custom Data module): two values a particle carries
## to the game's shader (Custom1 and Custom2), each four curves over the particle's life or a
## colour. The shaders read them as dissolve, scroll, glow intensity and the like.

## One of the two: up to four curves, or a colour; neither when that stream is off.
class Stream:
	var curves: Array[FxCurve] = []
	var color: FxColorCurve

	static func from_json(data: Variant) -> Stream:
		var stream := Stream.new()
		if data is Dictionary and data.has("vector"):
			for curve: Dictionary in data.vector:
				stream.curves.append(FxCurve.from_json(curve))
		elif data is Dictionary and data.has("color"):
			stream.color = FxColorCurve.from_json(data.color)
		return stream

	func sample(life: float, pick: float) -> Vector4:
		if color:
			var c := color.sample(life, pick)
			return Vector4(c.r, c.g, c.b, c.a)
		var value := Vector4.ZERO
		for i in curves.size():
			value[i] = curves[i].sample(life, pick)
		return value


var custom1 := Stream.new()
var custom2 := Stream.new()


static func from_json(streams: Array) -> FxCustomData:
	var data := FxCustomData.new()
	if streams.size() > 0:
		data.custom1 = Stream.from_json(streams[0])
	if streams.size() > 1:
		data.custom2 = Stream.from_json(streams[1])
	return data


## Sets the particle's custom values for where it is in its life.
func update(particle: FxParticle) -> void:
	var life := particle.life_fraction()
	particle.custom1 = custom1.sample(life, particle.custom_pick)
	particle.custom2 = custom2.sample(life, particle.custom_pick)
