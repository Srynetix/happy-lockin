extends Control
class_name BootScreen


func _ready():
    GameSceneTransitioner.fade_in()

    GameMusic.play()
    await get_tree().create_timer(1.0).timeout

    GameSceneTransitioner.fade_to_scene_path("res://screens/TitleScreen.tscn")
