class_name FxAssets
extends RefCounted
## The effects' shared pieces from tools/extract_effects.py (assets/limbus/fx): the game's
## shaders translated for Godot, their textures, and particle meshes, each loaded once.

const DIR := "res://assets/limbus/fx"
const SHADER_DIR := DIR + "/shaders"
const TEXTURE_DIR := DIR + "/textures"
const FACING_CAMERA := Vector3(0, 0, -1)  ## a normal pointing back at Unity's camera


## A mesh's triangles in its own space (Unity units, y up), with their normals and uvs.
class MeshData:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	func uv(vertex: int) -> Vector2:
		return uvs[vertex] if vertex < uvs.size() else Vector2.ZERO

	func normal(vertex: int) -> Vector3:
		return normals[vertex] if vertex < normals.size() else FACING_CAMERA


static var _meshes: Dictionary[String, MeshData] = {}
static var _textures: Dictionary[String, Texture2D] = {}
static var _shaders: Dictionary[String, Shader] = {}
static var _quad: MeshData


## A mesh by name, or a unit quad (what billboards are drawn with) if there's none by that name.
static func mesh(mesh_name: String) -> MeshData:
	if _meshes.is_empty():
		_load_meshes()
	return _meshes.get(mesh_name, quad())


## A square of side 1 about the origin, facing the camera.
static func quad() -> MeshData:
	if _quad == null:
		_quad = MeshData.new()
		_quad.vertices = PackedVector3Array([Vector3(-0.5, -0.5, 0), Vector3(0.5, -0.5, 0), Vector3(0.5, 0.5, 0), Vector3(-0.5, 0.5, 0)])
		_quad.uvs = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		_quad.indices = PackedInt32Array([0, 1, 2, 0, 2, 3])
	return _quad


static func texture(texture_name: String) -> Texture2D:
	if not _textures.has(texture_name):
		_textures[texture_name] = load("%s/%s.png" % [TEXTURE_DIR, texture_name])
	return _textures[texture_name]


## A translated game shader by its key (see tools/fx_shaders.py).
static func shader(key: String) -> Shader:
	if not _shaders.has(key):
		_shaders[key] = load("%s/%s.gdshader" % [SHADER_DIR, key])
	return _shaders[key]


static func _load_meshes() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "/meshes.json"))
	for mesh_name: String in data:
		var parsed := MeshData.new()
		for vertex: Array in data[mesh_name].vertices:
			parsed.vertices.append(FxUnity.vector3(vertex))
		for normal: Array in data[mesh_name].get("normals", []):
			parsed.normals.append(FxUnity.vector3(normal))
		for uv: Array in data[mesh_name].uvs:
			parsed.uvs.append(Vector2(uv[0], uv[1]))
		parsed.indices = PackedInt32Array(data[mesh_name].triangles)
		_meshes[mesh_name] = parsed
