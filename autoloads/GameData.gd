extends SxGameData

var fx_volume := 1.0 :
    set(value):
        _set_bus_volume("FX", value)
        store_value("fx_volume", value)

var music_volume := 1.0 :
    set(value):
        _set_bus_volume("Music", value)
        store_value("music_volume", value)


func _ready() -> void:
    default_file_path = "user://ld54-save.dat"
    _logger.set_max_log_level(SxLog.LogLevel.DEBUG)

    load_from_disk()
    fx_volume = load_value("fx_volume", 1.0)
    music_volume = load_value("music_volume", 1.0)

    _set_bus_volume("FX", fx_volume)
    _set_bus_volume("Music", music_volume)


func _set_bus_volume(bus_name: String, linear_value: float) -> void:
    var bus_id := AudioServer.get_bus_index(bus_name)
    AudioServer.set_bus_volume_db(bus_id, linear_to_db(linear_value))
