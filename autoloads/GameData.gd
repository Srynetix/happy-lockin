extends SxGameData

var fx_volume := 1.0 :
    set(value):
        _set_bus_volume("FX", value)
        store_value("fx_volume", value)

var music_volume := 1.0 :
    set(value):
        _set_bus_volume("Music", value)
        store_value("music_volume", value)

var last_level_keys := [0, 0]
var last_level_enemies := [0, 0]
var last_level_secrets := [0, 0]
var last_level_time := 0

func _ready() -> void:
    default_file_path = "user://ld54-save.dat"
    _logger.set_max_log_level(SxLog.LogLevel.DEBUG)

    load_from_disk()
    fx_volume = load_value("fx_volume", 1.0)
    music_volume = load_value("music_volume", 1.0)


func _input(event: InputEvent) -> void:
    # Alt + Enter = Full Screen
    if event is InputEventKey:
        if event.pressed && event.alt_pressed && event.keycode == KEY_ENTER:
            var current_mode := DisplayServer.window_get_mode()
            if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
                DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            else:
                DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

        elif event.pressed && event.keycode == KEY_F3:
            var img := get_viewport().get_texture().get_image()
            var frame := Time.get_ticks_msec()
            img.save_png("./screenshot-%d.png" % frame)
            print("SCREENSHOT TAKEN")

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
    var bus_id := AudioServer.get_bus_index(bus_name)
    var value := linear_to_db(linear_value)
    AudioServer.set_bus_volume_db(bus_id, value)
