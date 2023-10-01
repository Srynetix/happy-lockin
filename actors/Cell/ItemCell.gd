extends Cell
class_name ItemCell

signal picked()

@onready var _pick_sfx := %PickSFX as SimpleFX

var _picked := false

func pick() -> void:
    if !_picked:
        _picked = true
        _pick_sfx.spawn()
        collision_layer = 0
        $AnimationPlayer.play("fade")
        await $AnimationPlayer.animation_finished
        picked.emit()
