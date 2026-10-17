class_name FxParticleState
extends RefCounted
## A live particle as the renderer sees it this frame, for its vertex streams
## (FxVertexStreams): where its centre is, its size and velocity, in the effect's units (Unity
## units, y up), and its flipbook frame.

var particle: FxParticle
var center := Vector3.ZERO
var size := Vector3.ONE
var velocity := Vector3.ZERO
var frame := 0.0
var varying_random := Vector4.ZERO  ## new every frame
