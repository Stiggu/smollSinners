class_name IconStatuses
extends Node
## Each desktop icon's UnitStatus by id, kept between clashes; healed ones are forgotten.

## An icon's HP ran out.
signal icon_died(icon_id: String)
## A defeated icon is back, at full HP.
signal icon_got_up(icon_id: String)

const STAYS_DOWN := INF  ## a defeated icon's dead_time while it's dust: the graveyard gets it up

## Defeated icons turn to dust and stay down for a while; off, they get back up at once.
var turn_to_dust := true:
	set = _set_turn_to_dust

var _statuses: Dictionary[String, UnitStatus] = {}


## The icon's status for a clash, made on first use and marked fighting (or it'd be forgotten).
func status_of(icon: DesktopIcon) -> UnitStatus:
	if not _statuses.has(icon.id):
		var status := UnitStatus.new(IconStats.of(icon.short_name()).battle)
		status.dead_time = _dead_time()
		status.died.connect(icon_died.emit.bind(icon.id))
		status.got_up.connect(icon_got_up.emit.bind(icon.id))
		_statuses[icon.id] = status
	_statuses[icon.id].fighting()
	return _statuses[icon.id]


## The status of the icon with this id, or null while it's untouched.
func status_by_id(icon_id: String) -> UnitStatus:
	return _statuses.get(icon_id)


func _process(delta: float) -> void:
	for icon_id in _statuses.keys():
		var status := _statuses[icon_id]
		status.tick(delta)
		if not status.is_in_battle() and not status.is_dead():
			_statuses.erase(icon_id)


func _set_turn_to_dust(value: bool) -> void:
	turn_to_dust = value
	for status in _statuses.values():
		status.dead_time = _dead_time()
		if status.is_dead() and not turn_to_dust:
			status.get_up()


func _dead_time() -> float:
	return STAYS_DOWN if turn_to_dust else 0.0
