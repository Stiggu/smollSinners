class_name Roster
extends RefCounted
## The twelve sinners and all their identities, in the game's order, as tools/export_godot.py
## lists them in sinners.json. The Settings panel shows them as cards.

const FILE := IdentityLibrary.ROOT + "/sinners.json"


## One identity's entry.
class IdentityEntry:
	var folder := ""  ## e.g. "10101_Base"
	var path := ""  ## "<sinner>/<folder>"
	var title := ""  ## e.g. "LCB Sinner"
	var card_title := ""  ## the title as its card breaks it into lines
	var rank := 1  ## 1 to 3: its card's frame and grade marks
	var supported := true  ## animated with sprites, so the pet can play it


## One sinner's entry.
class SinnerEntry:
	var key := ""  ## e.g. "yisang"
	var name := ""  ## e.g. "Yi Sang"
	var identities: Array[IdentityEntry] = []


var sinners: Array[SinnerEntry] = []


static func load_file() -> Roster:
	var roster := Roster.new()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE)) if FileAccess.file_exists(FILE) else null
	if not data is Dictionary:
		return roster
	for sinner_data: Dictionary in data.sinners:
		var sinner := SinnerEntry.new()
		sinner.key = sinner_data.key
		sinner.name = sinner_data.name
		for identity_data: Dictionary in sinner_data.identities:
			sinner.identities.append(_identity_entry(sinner.key, identity_data))
		roster.sinners.append(sinner)
	return roster


static func _identity_entry(sinner_key: String, data: Dictionary) -> IdentityEntry:
	var identity := IdentityEntry.new()
	identity.folder = data.folder
	identity.path = IdentityLibrary.path_of(sinner_key, identity.folder)
	identity.title = data.title
	identity.card_title = data.get("card_title", identity.title)
	identity.rank = int(data.get("rank", 1))
	identity.supported = data.get("supported", true)
	return identity


func is_empty() -> bool:
	return sinners.is_empty()


## A sinner by key, e.g. "ryoshu"; null if there's none.
func find(sinner_key: String) -> SinnerEntry:
	for sinner in sinners:
		if sinner.key == sinner_key:
			return sinner
	return null
