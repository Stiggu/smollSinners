class_name LaunchOptions
extends RefCounted
## Debug switches, given after `--` on the command line, e.g.
##   godot --path . -- --screen 2 --identity faust/10201_Base --clash-test --fake-icons
##  --screen N             start on this monitor (0 is the first) instead of the remembered one
##  --identity <path>      only this identity out, e.g. faust/10201_Base
##  --sp N, --damage N     the first sinner starts with this much Sanity / this much damage taken
##  --clash-test           clash as soon as the first sinner is idle, again and again (logged)
##  --clash-icon <text>    only fight icons whose name contains this
##  --clash-skill S3       always use this skill slot
##  --clash-win, --clash-lose   the sinner's coins always land heads (or tails), the icon's the other way
##  --fake-icons           made-up desktop icons instead of the real ones: nothing real moves
##  --icon-boxes           outline every desktop icon
##  --capture-dir <dir> [--capture-every <s>]   save frames around the first sinner (see capture.gd)
##  --settings-shot <png> [--settings-sinner <key>]   open Settings and save a picture of it

const NOT_GIVEN := -1

var screen := NOT_GIVEN
var identity := ""
var start_sp := 0
var start_damage := 0
var clash_test := false
var clash_icon := ""
var clash_skill := ""
var clash_outcome := Clash.Outcome.BY_CHANCE
var fake_icons := false
var icon_boxes := false
var capture_dir := ""
var capture_every := 0.0  ## 0: the capture's own default
var settings_shot := ""
var settings_sinner := ""

var _args: PackedStringArray


static func from_command_line() -> LaunchOptions:
	return parse(OS.get_cmdline_user_args())


static func parse(args: PackedStringArray) -> LaunchOptions:
	var options := LaunchOptions.new()
	options._args = args
	options.screen = int(options._value_after("--screen", str(NOT_GIVEN)))
	options.identity = options._value_after("--identity")
	options.start_sp = int(options._value_after("--sp", "0"))
	options.start_damage = int(options._value_after("--damage", "0"))
	options.clash_test = options._has("--clash-test")
	options.clash_icon = options._value_after("--clash-icon")
	options.clash_skill = options._value_after("--clash-skill")
	if options._has("--clash-win"):
		options.clash_outcome = Clash.Outcome.SINNER_WINS
	elif options._has("--clash-lose"):
		options.clash_outcome = Clash.Outcome.SINNER_LOSES
	options.fake_icons = options._has("--fake-icons")
	options.icon_boxes = options._has("--icon-boxes")
	options.capture_dir = options._value_after("--capture-dir")
	options.capture_every = float(options._value_after("--capture-every", "0"))
	options.settings_shot = options._value_after("--settings-shot")
	options.settings_sinner = options._value_after("--settings-sinner")
	return options


func _has(flag: String) -> bool:
	return flag in _args


## The argument after `flag`, or `fallback` when the flag isn't there.
func _value_after(flag: String, fallback := "") -> String:
	var at := _args.find(flag)
	return _args[at + 1] if at >= 0 and at + 1 < _args.size() else fallback
