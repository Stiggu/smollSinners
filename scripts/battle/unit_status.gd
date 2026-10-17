class_name UnitStatus
extends RefCounted
## A unit's HP and Sanity (SP), by the game's rules, for one identity (identity.json
## "battle", from tools/export_godot.py):
##  - Sanity runs from -45 to +45, and coins land heads (50 + SP)% of the time.
##  - The identity's Sanity rules move it after a clash: a base amount, more for every clash
##    count after the first (most identities: +10 on a win, 20% more per clash count).
##  - At -45 the unit panics: it does nothing for a turn, then its Sanity goes back to 0.
##  - Hits are scaled by the identity's resistance to the attack type (x2 while staggered).
##    Dropping past a stagger threshold (a % of max HP) staggers it for a turn; at 0 HP it dies.
## The pet has no turns: a turn is TURN seconds. Once nothing has happened for BATTLE_OVER
## seconds the battle is over, and like a new stage HP comes back, broken thresholds mend and
## Sanity settles back to 0. A dead unit gets back up after DEAD_TIME.

## HP went up or down by delta.
signal hp_changed(delta: int)
## Sanity went up or down by delta; shown: play the up/down effect (not for the slow drift).
signal sp_changed(delta: int, shown: bool)
## Staggered, panicked, died, or got over it.
signal condition_changed

## How well a unit takes an attack type, as the game's attack icons show it.
enum ResistLevel { RESISTED, ENDURED, NORMAL, FATAL }

const MIN_SP := -45
const MAX_SP := 45
const DEFAULT_MAX_HP := 100
const TURN := 12.0  ## seconds
const DEAD_TIME := 25.0
const BATTLE_OVER := 60.0  ## seconds after the last clash
const REGEN_TIME := 120.0  ## seconds to heal from nothing to full once the battle is over
const SP_DRIFT := 0.25  ## SP per second back towards 0 once the battle is over
const STAGGERED_RESIST := 2.0  ## a staggered unit takes Fatal damage from everything
const EVEN_ODDS := 50.0  ## % chance of heads at 0 Sanity
const ENDURED_FROM := 0.5  ## damage multipliers above this are only "endured", not resisted

var max_hp := DEFAULT_MAX_HP
var hp := DEFAULT_MAX_HP
var sp := 0
var panic_name := "Panic"  ## what the identity's panic is called
## HP at which the unit staggers, highest first, and whether each broke this battle.
var thresholds: Array[int] = []
var broken: Array[bool] = []
var staggered_for := 0.0  ## seconds left
var panicked_for := 0.0
var dead_for := 0.0

var _resist: Dictionary  ## damage multiplier per attack type
## The identity's Sanity rules: {on: "win"|"lose", sp, per_clash (% more per clash count after
## the first), min_sp (only at this Sanity or more), foe_lower_sp (only against a saner foe)}.
var _sanity_rules: Array
var _quiet := BATTLE_OVER  ## seconds since the last clash
var _regen := 0.0  ## HP healed but not yet a whole point
var _drift := 0.0  ## Sanity drifted back but not yet a whole point


func _init(battle: Dictionary) -> void:
	max_hp = int(battle.get("hp", DEFAULT_MAX_HP))
	hp = max_hp
	_resist = battle.get("resist", {})
	_sanity_rules = battle.get("sanity", [])
	panic_name = battle.get("panic", panic_name)
	for percent: float in battle.get("stagger", []):
		thresholds.append(int(max_hp * percent / 100.0))
		broken.append(false)


func is_dead() -> bool:
	return hp <= 0


func is_staggered() -> bool:
	return staggered_for > 0.0


func is_panicked() -> bool:
	return panicked_for > 0.0


## Not staggered, panicked or dead.
func can_act() -> bool:
	return not (is_dead() or is_staggered() or is_panicked())


## The damage multiplier for a "slash", "pierce" or "blunt" hit (before staggering).
func resistance(attack: String) -> float:
	return _resist.get(attack, 1.0)


## How well it takes an attack type, for the attack icons.
func resistance_level(attack: String) -> ResistLevel:
	var multiplier := resistance(attack)
	if multiplier > 1.0:
		return ResistLevel.FATAL
	if multiplier >= 1.0:
		return ResistLevel.NORMAL
	return ResistLevel.ENDURED if multiplier > ENDURED_FROM else ResistLevel.RESISTED


func heads_chance() -> float:
	return (EVEN_ODDS + sp) / 100.0


## Keeps the battle going (call while clashing).
func fighting() -> void:
	_quiet = 0.0


## A clash ended; clash_count is how many times the coins were compared. foe_sp: the foe's
## Sanity (desktop icons have none, so 0).
func clash_ended(won: bool, clash_count: int, foe_sp := 0) -> void:
	_quiet = 0.0
	var total := 0
	for rule: Dictionary in _sanity_rules:
		if _rule_applies(rule, won, foe_sp):
			total += int(rule.sp * (1.0 + rule.per_clash / 100.0 * (clash_count - 1)))
	add_sp(total)


func _rule_applies(rule: Dictionary, won: bool, foe_sp: int) -> bool:
	if rule.on != ("win" if won else "lose"):
		return false
	if rule.has("min_sp") and sp < rule.min_sp:
		return false
	return not (rule.get("foe_lower_sp", false) and foe_sp >= sp)


## Take a hit of `damage` from a "slash", "pierce" or "blunt" attack. Returns the damage taken.
func take_hit(damage: int, attack: String) -> int:
	if is_dead():
		return 0
	_quiet = 0.0
	var multiplier := STAGGERED_RESIST if is_staggered() else resistance(attack)
	var taken := maxi(roundi(damage * multiplier), 0)
	_set_hp(hp - taken)
	var crossed_threshold := _break_thresholds()
	if is_dead():
		staggered_for = 0.0
		panicked_for = 0.0
		dead_for = DEAD_TIME
		condition_changed.emit()
	elif crossed_threshold and not is_staggered():
		staggered_for = TURN
		condition_changed.emit()
	return taken


## Raise or lower Sanity, within MIN_SP..MAX_SP; panics at MIN_SP.
func add_sp(delta: int, shown := true) -> void:
	var before := sp
	sp = clampi(sp + delta, MIN_SP, MAX_SP)
	if sp != before:
		sp_changed.emit(sp - before, shown)
	if sp <= MIN_SP and not is_panicked() and not is_dead():
		panicked_for = TURN
		condition_changed.emit()


func tick(delta: float) -> void:
	_quiet += delta
	if is_dead():
		dead_for -= delta
		if dead_for <= 0.0:
			_get_up()
		return
	if staggered_for > 0.0:
		staggered_for -= delta
		if staggered_for <= 0.0:
			condition_changed.emit()
	if panicked_for > 0.0:
		panicked_for -= delta
		if panicked_for <= 0.0:
			panicked_for = 0.0
			add_sp(-sp)  # the panic is over: Sanity back to 0
			condition_changed.emit()
	if _quiet >= BATTLE_OVER:
		_recover(delta)


func _set_hp(value: int) -> void:
	var before := hp
	hp = clampi(value, 0, max_hp)
	if hp != before:
		hp_changed.emit(hp - before)


## Marks the thresholds HP has dropped to; true if any broke just now.
func _break_thresholds() -> bool:
	var crossed := false
	for i in thresholds.size():
		if not broken[i] and hp <= thresholds[i]:
			broken[i] = true
			crossed = true
	return crossed


## Between battles: heal, mend the thresholds HP is back above, settle Sanity towards 0.
func _recover(delta: float) -> void:
	if hp < max_hp:
		_regen += delta * max_hp / REGEN_TIME
		var heal := mini(int(_regen), max_hp - hp)
		if heal > 0:
			_regen -= heal
			_set_hp(hp + heal)
	for i in thresholds.size():
		if broken[i] and hp > thresholds[i]:
			broken[i] = false
	if sp == 0:
		_drift = 0.0
		return
	_drift += delta * SP_DRIFT
	var step := mini(int(_drift), absi(sp))
	if step > 0:
		_drift -= step
		add_sp(-signi(sp) * step, false)


func _get_up() -> void:
	dead_for = 0.0
	_set_hp(max_hp)
	broken.fill(false)
	add_sp(-sp, false)
	_quiet = BATTLE_OVER
	condition_changed.emit()
