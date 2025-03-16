# LSTAPI
The LonelyStars TimeAPI, made for WEBFISHING.
A mod API for synchronizing time related mods to a central source.

## The Problem
Right now WEBFISHING mods related to time rely on using the users real life time to remain synced with one another, the instant one tries to use an in-game time cycle the whole ship breaks apart. This fixes that.

## The Solution
Making one mod serve as the pseudo time that all others follow keeps them all synced to one source instead of each making up their own and therefore aren't synced with one another.

# Mod Author Instructions
We provide the signals minute_has_passed, hour_has_passed and day_has_passed, if you want to for example run something every hour/minute or count how many hours/minutes have passed then run something.

check_time() returns a dictionary of either the real life time or the in-game time (Default) depending on the users LSTAPI config.

You shouldn't use seconds in your logic, it's only provided for API compatibility between real time and in-game time.

## Examples

### Initialize with:
```
onready var LSTAPI = get_node_or_null("/root/LSTAPI")
```

### Using the signals:
```
onready var LSTAPI = get_node_or_null("/root/LSTAPI")

func _ready():
    if LSTAPI != null:
        LSTAPI.connect("minute_has_passed", self, "_on_minute_update")

func _on_minute_update():
    print("Minute has updated.")
```

### Checking the time:
```
onready var LSTAPI = get_node_or_null("/root/LSTAPI")
var current_time

func _ready():
    if LSTAPI != null:
        LSTAPI.connect("minute_has_passed", self, "_on_minute_update")

func _on_minute_update():
    current_time = LSTAPI.check_time()

    if current_time["hour"] != 5:
        print("Hour is not 5. Returning.")
        return

    print("Current Minute is: " + str(current_time["minute"])
    
    if current_time["minute"] == 27:
        print("Minute is 27. Do a thing!")
```

### Getting the config:
The reason this is provided is so you don't have to depend on TackleBox (like LSTAPI does) just to make your code reactive to it's config.

```
onready var LSTAPI = get_node_or_null("/root/LSTAPI")
var LSTAPI_config

func _ready():
    if LSTAPI != null:
        LSTAPI.connect("config_has_updated", self, "_on_config_update")
        LSTAPI_config = LSTAPI.get_config()
        
        _scan_config()

func _scan_config():
    if LSTAPI_config["real_time"] == true:
        print("LSTAPI RealTime setting is being used.")

func _on_config_update():
    LSTAPI_config = LSTAPI.get_config()
    _scan_config()
```

