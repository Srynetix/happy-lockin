extends Control
class_name TitleScreen

@onready var _start_game := %StartGame as Button

@onready var _fx_volume := %FXVolume as HSlider
@onready var _music_volume := %MusicVolume as HSlider

func _ready():
    _start_game.pressed.connect(func():
        GameSceneTransitioner.fade_to_scene_path("res://screens/HowToPlayScreen.tscn")
    )

    _fx_volume.value_changed.connect(func(value: float):
        GameData.fx_volume = value
        GameData.persist_to_disk()
    )
    _music_volume.value_changed.connect(func(value: float):
        GameData.music_volume = value
        GameData.persist_to_disk()
    )

    # Initial values
    _fx_volume.value = GameData.fx_volume
    _music_volume.value = GameData.music_volume
