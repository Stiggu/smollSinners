class_name FxVertexData
extends RefCounted
## Hands a translated shader the per-vertex inputs a canvas can't carry (Unity's TEXCOORDs and
## normals, see FxVertexStreams): a float texture, VERTICES_PER_ROW vertices a row, each vertex
## `slots` texels side by side. The shader finds a vertex's texels by its VERTEX_ID, so the
## vertices must be drawn in one triangle array, in the order they were added.

const VERTICES_PER_ROW := 256  ## as tools/fx_shaders.py reads them
const FLOATS_PER_TEXEL := 4

var _image: Image
var _texture: ImageTexture
var _rows := 0  ## the texture's height


## Uploads `data` (FxVertexStreams rows, one a vertex) and points the material at it.
func upload(data: PackedFloat32Array, streams: FxVertexStreams, material: ShaderMaterial) -> void:
	var slots := streams.slots()
	if slots == 0 or data.is_empty():
		return
	var width := VERTICES_PER_ROW * slots
	var vertices := data.size() / (slots * FLOATS_PER_TEXEL)
	var rows := ceili(float(vertices) / VERTICES_PER_ROW)
	data.resize(width * rows * FLOATS_PER_TEXEL)
	var bytes := data.to_byte_array()
	if _texture == null or rows != _rows:
		_rows = rows
		_image = Image.create_from_data(width, rows, false, Image.FORMAT_RGBAF, bytes)
		_texture = ImageTexture.create_from_image(_image)
	else:
		_image.set_data(width, rows, false, Image.FORMAT_RGBAF, bytes)
		_texture.update(_image)
	material.set_shader_parameter("vertex_data", _texture)
	material.set_shader_parameter("vertex_data_slots", slots)
	material.set_shader_parameter("normal_slot", streams.normal_slot)
