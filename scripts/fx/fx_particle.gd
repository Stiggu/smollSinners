class_name FxParticle
extends RefCounted
## One live particle of an FxParticleSystem, in its system's space (Unity units, y up).

var age := 0.0
var lifetime := 1.0
var position := Vector3.ZERO
var velocity := Vector3.ZERO  ## its own: start speed and gravity
var moving := Vector3.ZERO  ## how it moved last frame, every module's velocity in
var size := Vector3.ONE
var rotation := Vector3.ZERO  ## Unity Euler angles, radians
var color := Color.WHITE  ## its start colour (times a parent's, when it inherits one)
## Random picks (0..1) made at birth, so each over-lifetime curve that picks between two
## chooses the same way all the particle's life.
var velocity_pick := 0.0
var orbit_pick := 0.0
var size_pick := 0.0
var color_pick := 0.0
var noise_pick := 0.0
var flipbook_pick := 0.0
var spin_pick := 0.0
var custom_pick := 0.0
var noise_phase := 0.0  ## where its noise sway starts
var stable_random := Vector4.ZERO  ## Unity's per-particle random numbers, for the shader
var custom1 := Vector4.ZERO  ## its custom data now (FxCustomData), for the shader
var custom2 := Vector4.ZERO
var shown_color := Color.WHITE  ## its colour now, as its vertices carry it
var shown_size := Vector3.ONE  ## its size now (Unity units)
## Where it has been, for its trail (FxTrails): points in its system's space, oldest first,
## each with the age it was at there.
var has_trail := false
var trail_points := PackedVector3Array()
var trail_ages := PackedFloat32Array()


## How far through its life it is, 0..1.
func life_fraction() -> float:
	return age / lifetime


func is_alive() -> bool:
	return age < lifetime
