extends Node

signal second_has_passed
signal minute_has_passed
signal hour_has_passed
signal day_has_passed
signal config_has_updated
signal time_has_jumped

const ID = "LSTAPI"
const mod_ver = "0.1.4"
onready var real_time: Dictionary = {"hour": 0, "minute": 0, "second": 0}
onready var ingame_time: Dictionary = {"hour": 6, "minute": 0, "second": 0}

var irl_sec_timer: Timer
var irl_min_timer: Timer
var irl_hour_timer: Timer
var irl_day_timer: Timer
var in_game_sec_timer: Timer
var in_game_min_timer: Timer

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

	_cleanup()
	config = new_config
	_check_config()

	match config["real_time"]:
		true:
			current_mode = TimeMode.REALTIME
			emit_signal("time_has_jumped", real_time)
		false:
			current_mode = TimeMode.INGAMETIME
			emit_signal("time_has_jumped", ingame_time)

	emit_signal("config_has_updated", config)

	_startup()

func get_second():
	match current_mode:
		TimeMode.REALTIME:
			return real_time["second"]
		TimeMode.INGAMETIME:
			return ingame_time["second"]

func get_minute():
	match current_mode:
		TimeMode.REALTIME:
			return real_time["minute"]
		TimeMode.INGAMETIME:
			return ingame_time["minute"]

func get_hour():
	if config["force_hour"] != 0:
		return config["force_hour"]
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
			real_time = Time.get_time_dict_from_system()
			irl_sec_timer = _create_timer("irl_sec_timer", 1, self, "_emit_second")
			irl_min_timer = _create_timer("irl_min_timer", 60, self, "_emit_minute")
			irl_hour_timer = _create_timer("irl_hour_timer", 3600, self, "_emit_hour")
			irl_day_timer = _create_timer("irl_day_timer", 86400, self, "_emit_day")
		TimeMode.INGAMETIME:
			ingame_time["second"] = 0
			in_game_sec_timer = _create_timer("in_game_sec_timer", config["in_game_minute_length_in_seconds"] / 60, self, "_emit_second")
			in_game_min_timer = _create_timer("in_game_min_timer", config["in_game_minute_length_in_seconds"], self, "_in_game_time_has_passed")

func _cleanup():
	match current_mode:
		TimeMode.REALTIME:
			irl_sec_timer.free()
			irl_min_timer.free()
			irl_hour_timer.free()
			irl_day_timer.free()
		TimeMode.INGAMETIME:
			in_game_sec_timer.free()
			in_game_min_timer.free()

func _emit_second():
	match current_mode:
		TimeMode.REALTIME:
			real_time = Time.get_time_dict_from_system()
			emit_signal("second_has_passed", real_time)
		TimeMode.INGAMETIME:
			ingame_time["second"] = ingame_time["second"] + 1
			if ingame_time["second"] >= 60:
				ingame_time["second"] = 0
			emit_signal("second_has_passed", ingame_time)

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

func _create_timer(timer_name: String, wait_by, connect_target: Node, function: String):
	var timer = Timer.new()
	timer.name = timer_name
	timer.wait_time = wait_by
	add_child(timer)
	timer.connect("timeout", connect_target, function)
	timer.start()
	return timer

# This only handles minute/hour/day, second is seperated for performance reasons.
func _in_game_time_has_passed():
	ingame_time["minute"] = ingame_time["minute"] + 1
	if ingame_time["minute"] >= 60:
		ingame_time["minute"] = 0
		ingame_time["hour"] = ingame_time["hour"] + 1
		if ingame_time["hour"] >= 24:
			ingame_time = {"hour": 0, "minute": 0, "second": 0}
			_emit_day()
		if config["force_hour"] == 0: _emit_hour()
	_emit_minute()
	if config["force_hour"] != 0:
		ingame_time["hour"] = config["force_hour"]

func check_time():
	match current_mode:
		TimeMode.REALTIME:
			if config["force_hour"] != 0:
				real_time["hour"] = config["force_hour"]
			return real_time
		TimeMode.INGAMETIME:
			if config["force_hour"] != 0:
				ingame_time["hour"] = config["force_hour"]
			return ingame_time
