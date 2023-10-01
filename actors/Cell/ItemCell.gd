extends Cell
class_name ItemCell

signal picked()

@onready var _pick_sfx := %PickSFX as SimpleFX

var _picked := false

func pick() -> void:
    if !_picked:
        _pick_sfx.spawn()
        picked.emit()
        _picked = true
