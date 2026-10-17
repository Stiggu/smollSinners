class_name AppSettings
extends RefCounted
## What's remembered between runs, in user://settings.cfg:
##  - pet/screen: the monitor the overlay covers
##  - pet/team: the identities out on the desktop (older versions kept just one, pet/identity)
##  - formation/<sinner>: the identity that sinner's card shows in Settings
## The project keeps config/name "smollSinner" because it names the user:// folder.

const FILE := "user://settings.cfg"


## The monitor picked last time, if it's still there; else the main one.
static func screen() -> int:
	var saved: int = _load().get_value("pet", "screen", DisplayServer.get_primary_screen())
	return saved if saved < DisplayServer.get_screen_count() else DisplayServer.get_primary_screen()


static func save_screen(screen_index: int) -> void:
	var config := _load()
	config.set_value("pet", "screen", screen_index)
	config.save(FILE)


## The identity paths out last time, as saved (they may not all be playable any more).
static func team() -> Array[String]:
	var config := _load()
	var legacy_single: String = config.get_value("pet", "identity", IdentityLibrary.DEFAULT_IDENTITY)
	var saved: Array = config.get_value("pet", "team", [legacy_single])
	var paths: Array[String] = []
	paths.assign(saved)
	return paths


static func save_team(paths: Array[String]) -> void:
	var config := _load()
	config.set_value("pet", "team", paths)
	if config.has_section_key("pet", "identity"):
		config.erase_section_key("pet", "identity")
	config.save(FILE)


## The identity folder a sinner's Settings card shows, e.g. "10404_Pierre"; "" if none picked yet.
static func formation_pick(sinner_key: String) -> String:
	return _load().get_value("formation", sinner_key, "")


static func save_formation_pick(sinner_key: String, folder: String) -> void:
	var config := _load()
	config.set_value("formation", sinner_key, folder)
	config.save(FILE)


static func _load() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(FILE)  # a missing file is just empty
	return config
