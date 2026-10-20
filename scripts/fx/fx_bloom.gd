class_name FxBloom
extends Node
## The game's bloom (URP, battle profile "PostProcessing Profile_Main") as a chain of
## SubViewports, each nested in the one that reads it so all render in the same frame.

const PREFILTER := preload("res://scripts/fx/bloom/fx_bloom_prefilter.gdshader")
const BLUR_ACROSS := preload("res://scripts/fx/bloom/fx_bloom_blur_across.gdshader")
const BLUR_DOWN := preload("res://scripts/fx/bloom/fx_bloom_blur_down.gdshader")
const UPSAMPLE := preload("res://scripts/fx/bloom/fx_bloom_upsample.gdshader")
const SCATTER_RANGE := Vector2(0.05, 0.95)  ## URP takes the profile's 0..1 scatter into this

@export var threshold := 1.0  ## the brightest channel where glowing starts (the profile's)
@export_range(0.0, 1.0) var scatter := 0.8  ## how far the glow spreads (the profile's)
@export var clamp_max := 65472.0  ## caps absurdly bright pixels (URP's default)
@export_range(2, 8) var levels := 6  ## the pyramid's levels (URP's default most)
## First level's size vs the overlay (the game uses half, but shows the world ~2x bigger).
@export var start_scale := 1.0

var effects: Node2D  ## where effects go, drawn in HDR into `picture`
var picture: ViewportTexture  ## the effects, HDR, premultiplied
var glow: ViewportTexture  ## the bloom to add to them

var _scales: Dictionary[SubViewport, float] = {}  ## each pass's size, as a share of the overlay's


func build(size: Vector2i) -> void:
	var chain: Array[SubViewport] = []
	var stage := _viewport(chain, 1.0)
	stage.transparent_bg = true
	effects = Node2D.new()
	effects.name = "Effects"
	stage.add_child(effects)
	picture = stage.get_texture()
	var blurred: Array[SubViewport] = [_pass(chain, start_scale, PREFILTER,
			{"source": picture, "threshold": threshold, "clamp_max": clamp_max})]
	for level in range(1, levels):
		var across := _pass(chain, _level_scale(level), BLUR_ACROSS, {"source": blurred[-1].get_texture()})
		blurred.append(_pass(chain, _level_scale(level), BLUR_DOWN, {"source": across.get_texture()}))
	var summed: SubViewport = blurred[-1]
	var carried := lerpf(SCATTER_RANGE.x, SCATTER_RANGE.y, scatter)
	for level in range(levels - 2, -1, -1):
		summed = _pass(chain, _level_scale(level), UPSAMPLE,
				{"high": blurred[level].get_texture(), "low": summed.get_texture(), "scatter": carried})
	glow = summed.get_texture()
	for i in chain.size() - 1:
		chain[i + 1].add_child(chain[i])
	add_child(chain[-1])
	resize(size)


func resize(size: Vector2i) -> void:
	for viewport in _scales:
		var scaled := Vector2(size) * _scales[viewport]
		viewport.size = Vector2i(maxi(1, ceili(scaled.x)), maxi(1, ceili(scaled.y)))


func run(running: bool) -> void:
	var mode := SubViewport.UPDATE_ALWAYS if running else SubViewport.UPDATE_DISABLED
	for viewport in _scales:
		viewport.render_target_update_mode = mode


func _level_scale(level: int) -> float:
	return start_scale / pow(2.0, level)


func _viewport(chain: Array[SubViewport], share: float) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.use_hdr_2d = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_scales[viewport] = share
	chain.append(viewport)
	return viewport


func _pass(chain: Array[SubViewport], share: float, shader: Shader, parameters: Dictionary) -> SubViewport:
	var viewport := _viewport(chain, share)
	var material := ShaderMaterial.new()
	material.shader = shader
	for parameter: String in parameters:
		material.set_shader_parameter(parameter, parameters[parameter])
	var fill := ColorRect.new()
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.material = material
	viewport.add_child(fill)
	return viewport
