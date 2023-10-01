extends Area2D
class_name EndZone

signal finished()

var _finished = false

func _ready() -> void:
    area_entered.connect(func(area):
        if !_finished && area.is_in_group("player_area"):
            var player := area.get_parent() as Player
            if player.behavior_type == Player.BehaviorType.Player:
                _finished = true
                finished.emit()
    )
