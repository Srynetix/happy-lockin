extends Control
class_name HowToPlayScreen


func _ready():
    await get_tree().create_timer(5.0).timeout
    GameSceneTransitioner.fade_to_scene_path("res://tests/TestLevel.tscn")
