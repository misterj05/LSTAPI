extends Node

signal minute_has_passed
signal hour_has_passed
signal day_has_passed
signal config_has_updated

const ID = "LSTAPI"
const mod_ver = "0.1.0"
onready var real_time = {"hour": 0, "minute": 0, "second": 0}
onready var ingame_time = {"hour": 6, "minute": 0, "second": 0}

var poll_realtime_timer:Timer
var irl_second_timer:Timer
var irl_min_timer:Timer
var irl_hour_timer:Timer
var irl_day_timer:Timer
var in_game_min_timer:Timer

var config: Dictionary
var LSTAPI_config_default: Dictionary = {
	"real_time": false,
	"force_hour": 0,
	"in_game_minute_length_in_seconds": 1
}

enum TimeMode {
	INGAMETIME,
	REALTIME,
}
var current_mode

onready var tb = get_node_or_null("/root/TackleBox")

func _init_config():
	var saved_config = tb.get_mod_config(ID)

	for key in LSTAPI_config_default.keys():
		if !saved_config.has(key):
			saved_config[key] = LSTAPI_config_default[key]

	config = saved_config

	_check_config()

	tb.set_mod_config(ID, config)
	tb.connect("mod_config_updated", self, "_on_config_update")

func _check_config():
	if (config["force_hour"] > 23) || (config["force_hour"] < 0):
		print(ID + ": force_hour config option is not set correctly, resetting to 0.")
		config["force_hour"] = 0

func _on_config_update(mod_id: String, new_config: Dictionary):
	if mod_id != ID:
		return

	config = new_config
	_check_config()
	emit_signal("config_has_updated",config)

func get_config():
	return config

func get_minute():
	match current_mode:
		TimeMode.REALTIME:
			return real_time["minute"]
		TimeMode.INGAMETIME:
			return ingame_time["minute"]

func get_hour():
	match current_mode:
		TimeMode.REALTIME:
			return real_time["hour"]
		TimeMode.INGAMETIME:
			return ingame_time["hour"]

func _ready():
	print(ID + " has loaded!")
	if tb != null:
		_init_config()
	else: config = LSTAPI_config_default
	if config["real_time"]:
		current_mode = TimeMode.REALTIME
	else:
		current_mode = TimeMode.INGAMETIME
	_startup()

func _startup():
	match current_mode:
		TimeMode.REALTIME:
			check_time()
			_create_timer(poll_realtime_timer, 1, "check_time") # Needed to keep the real_time var up to date
			_create_timer(irl_min_timer, 60, "_emit_minute")
			_create_timer(irl_hour_timer, 3600, "_emit_hour")
			_create_timer(irl_day_timer, 86400, "_emit_day")
		TimeMode.INGAMETIME:
			_create_timer(in_game_min_timer, config["in_game_minute_length_in_seconds"], "_in_game_time_has_passed")

func _emit_minute():
	match current_mode:
		TimeMode.REALTIME:
			emit_signal("minute_has_passed", real_time)
		TimeMode.INGAMETIME:
			emit_signal("minute_has_passed", ingame_time)

func _emit_hour():
	match current_mode:
		TimeMode.REALTIME:
			emit_signal("hour_has_passed", real_time)
		TimeMode.INGAMETIME:
			emit_signal("hour_has_passed", ingame_time)

func _emit_day():
	match current_mode:
		TimeMode.REALTIME:
			emit_signal("day_has_passed", real_time)
		TimeMode.INGAMETIME:
			emit_signal("day_has_passed", ingame_time)

func _physics_process(delta):
	#print(str(check_time()))
	pass

func _create_timer(timer, wait_by, function):
	timer = Timer.new()
	timer.wait_time = wait_by
	add_child(timer)
	timer.connect("timeout", self, function)
	timer.start()
	return timer

func _in_game_time_has_passed():
	ingame_time["minute"] = ingame_time["minute"] + 1
	_emit_minute()
	if ingame_time["minute"] >= 60:
		ingame_time["minute"] = 0
		ingame_time["hour"] = ingame_time["hour"] + 1
		if config["force_hour"] == 0: _emit_hour()
	if config["force_hour"] != 0:
		ingame_time["hour"] = config["force_hour"]
	if ingame_time["hour"] >= 24:
		ingame_time = {"hour": 0, "minute": 0, "second": 0}
		_emit_day()

func check_time():
	match current_mode:
		TimeMode.REALTIME:
			real_time = Time.get_time_dict_from_system()
			if config["force_hour"] != 0:
				real_time["hour"] = config["force_hour"]
			return real_time
		TimeMode.INGAMETIME:
			if config["force_hour"] != 0:
				ingame_time["hour"] = config["force_hour"]
			return ingame_time
