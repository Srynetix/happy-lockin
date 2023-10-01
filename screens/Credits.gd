extends Control


func _ready():
    %Instructions.meta_clicked.connect(func(data):
        OS.shell_open(data)
    )

    %Happy.modulate.a = 0

    await get_tree().create_timer(6.0).timeout

    var tween = create_tween()
    tween.tween_property(%Happy, "modulate", Color.RED, 0.25).set_ease(Tween.EASE_IN)
    tween.tween_property(%Happy, "modulate", Color.TRANSPARENT, 0.25).set_ease(Tween.EASE_IN)

    tween.tween_property(%Happy, "modulate", Color.RED, 1).set_delay(1.0)
    await tween.finished

    GameSceneTransitioner.fade_to_scene_path("res://screens/TitleScreen.tscn")
