extends Control
class_name BootScreen


func _ready():
    GameMusic.set_track(GameMusic.Track.Intro)
    GameMusic.play()

    GameSceneTransitioner.fade_in()
    await get_tree().create_timer(5.0).timeout
    GameSceneTransitioner.fade_to_scene_path("res://screens/TitleScreen.tscn", 0.5)
