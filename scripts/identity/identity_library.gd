class_name IdentityLibrary
extends RefCounted
## Where tools/export_godot.py puts the identities, and how the app names them: an identity
## path is "<sinner>/<folder>" under ROOT, e.g. "yisang/10101_Base".

const ROOT := "res://assets/limbus"
const DEFAULT_IDENTITY := "yisang/10101_Base"
## How an identity is animated: the pet plays sprite identities (a few use a cutout rig instead).
const PLAYABLE_KIND := "sprite"


static func path_of(sinner_key: String, folder: String) -> String:
	return "%s/%s" % [sinner_key, folder]


static func dir_of(identity_path: String) -> String:
	return ROOT.path_join(identity_path)


## The sinner an identity belongs to, e.g. "yisang".
static func sinner_of(identity_path: String) -> String:
	return identity_path.get_slice("/", 0)


## Exported, and animated in a way the pet can play.
static func is_playable(identity_path: String) -> bool:
	var file := dir_of(identity_path).path_join("identity.json")
	if not FileAccess.file_exists(file):
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
	return data is Dictionary and data.get("kind") == PLAYABLE_KIND


static func load_identity(identity_path: String) -> IdentityData:
	return IdentityData.load_from(dir_of(identity_path), identity_path)
