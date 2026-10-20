class_name FxMaterialDef
extends RefCounted
## One of the game's effect materials, as fx.json gives it (tools/fx_materials.py): the
## game's shader translated for Godot, the material's values as that shader reads them (its
## UnityPerMaterial buffer, four floats a register), its textures, and the values an Animator
## changes over the effect's life. make_material() builds the ShaderMaterial a system draws
## with; animate() keeps it up with the Animator.

const VALUES_UNIFORM := "material"  ## see tools/fx_shaders.py
const SAMPLER_PREFIX := "tex_"
const FLOATS_PER_REGISTER := 4
const CHANNELS := "rgba"

var shader_key := ""  ## under FxAssets.SHADER_DIR
var source := ""  ## the game's shader, for reference
var values := PackedFloat32Array()
var textures: Dictionary[String, String] = {}  ## property -> texture name under FxAssets
var depth_tested := false  ## the game's shader tests depth: the battle floor hides what it draws under it
var reads_screen := false  ## the shader draws the screen behind it (a distortion or a screen filter)
var _layout: Dictionary[String, Vector2i] = {}  ## property -> (first float, components)
var _float_keys: Dictionary[String, PackedVector2Array] = {}  ## animated floats: (time, value) keys
var _channel_keys: Dictionary[String, Dictionary] = {}  ## animated colours: property -> {channel: keys}


## data: the material; animated: the system's "anim" ({property: keys, or {channel: keys}}).
static func from_json(data: Dictionary, animated: Dictionary) -> FxMaterialDef:
	var material := FxMaterialDef.new()
	material.shader_key = data.shader
	material.source = data.get("source", "")
	material.values = PackedFloat32Array(data["values"])
	material.depth_tested = data.get("depth_tested", false)
	material.reads_screen = data.get("reads_screen", false)
	for property: String in data.get("textures", {}):
		material.textures[property] = data.textures[property]
	for property: String in data.get("layout", {}):
		var entry: Array = data.layout[property]
		material._layout[property] = Vector2i(int(entry[0]), int(entry[1]))
	for property: String in animated:
		if not material._layout.has(property):
			continue
		if animated[property] is Array:
			material._float_keys[property] = FxCurve.keys_from(animated[property])
		else:
			var channels := {}
			for channel: String in animated[property]:
				channels[CHANNELS.find(channel)] = FxCurve.keys_from(animated[property][channel])
			material._channel_keys[property] = channels
	return material


## The sampler a texture property is bound to in the translated shader.
static func sampler_name(property: String) -> String:
	return SAMPLER_PREFIX + property.lstrip("_")


func make_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = FxAssets.shader(shader_key)
	for property in textures:
		material.set_shader_parameter(sampler_name(property), FxAssets.texture(textures[property]))
	material.set_shader_parameter(VALUES_UNIFORM, _registers(values))
	return material


func is_animated() -> bool:
	return not (_float_keys.is_empty() and _channel_keys.is_empty())


## The material's values as the Animator keys them `time` seconds into the effect.
func animate(material: ShaderMaterial, time: float) -> void:
	if not is_animated():
		return
	var now := values.duplicate()
	for property in _float_keys:
		var at := _layout[property].x
		now[at] = FxCurve.keyed(_float_keys[property], time, now[at])
	for property in _channel_keys:
		var at := _layout[property].x
		var channels: Dictionary = _channel_keys[property]
		for channel: int in channels:
			if channel < _layout[property].y:
				now[at + channel] = FxCurve.keyed(channels[channel], time, now[at + channel])
	material.set_shader_parameter(VALUES_UNIFORM, _registers(now))


static func _registers(floats: PackedFloat32Array) -> PackedVector4Array:
	var registers := PackedVector4Array()
	for i in range(0, floats.size(), FLOATS_PER_REGISTER):
		registers.append(Vector4(floats[i], floats[i + 1], floats[i + 2], floats[i + 3]))
	return registers
