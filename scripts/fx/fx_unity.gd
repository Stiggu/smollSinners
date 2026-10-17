class_name FxUnity
extends RefCounted
## Conversions from the Unity data tools/extract_effects.py exports: Unity is y-up and turns
## by Euler angles z, then x, then y; its colours and vectors arrive as JSON arrays.

const PX_PER_UNIT := 60.0  ## as tools/extract_effects.py exports sizes


static func vector3(values: Array) -> Vector3:
	return Vector3(values[0], values[1], values[2])


## [r, g, b] or [r, g, b, a].
static func color(values: Array) -> Color:
	return Color(values[0], values[1], values[2], values[3] if values.size() > 3 else 1.0)


## A rotation from Unity Euler angles (radians): z first, then x, then y.
static func rotation(euler: Vector3) -> Basis:
	return Basis(Vector3.UP, euler.y) * Basis(Vector3.RIGHT, euler.x) * Basis(Vector3.BACK, euler.z)


## A 3×4 matrix given as rows (the transform from a system's space to the effect's, in px).
static func transform(rows: Array) -> Transform3D:
	var columns := Basis(
			Vector3(rows[0][0], rows[1][0], rows[2][0]),
			Vector3(rows[0][1], rows[1][1], rows[2][1]),
			Vector3(rows[0][2], rows[1][2], rows[2][2]))
	return Transform3D(columns, Vector3(rows[0][3], rows[1][3], rows[2][3]))


## A point in a system's space onto the screen (y down), through its transform; depth is dropped.
static func to_screen(system_transform: Transform3D, point: Vector3) -> Vector2:
	var placed := system_transform * point
	return Vector2(placed.x, -placed.y)
