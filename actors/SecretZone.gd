extends Node2D
class_name SecretZone

signal found()

@onready var _tip := %Tip as Tip

func _ready() -> void:
    _tip.shown.connect(func():
        found.emit()
    )
