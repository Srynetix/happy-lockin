extends Area2D
class_name Weird

signal weird_started()
signal weird_stopped()

func _ready() -> void:
    area_entered.connect(func(area):
        if area.is_in_group("player_area"):
            var player = area.get_parent() as Player
            if player.behavior_type == Player.BehaviorType.Player:
                weird_started.emit()
    )

    area_exited.connect(func(area):
        if area.is_in_group("player_area"):
            var player = area.get_parent() as Player
            if player.behavior_type == Player.BehaviorType.Player:
                weird_stopped.emit()
    )

