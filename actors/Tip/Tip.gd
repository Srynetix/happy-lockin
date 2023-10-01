extends Area2D
class_name Tip

signal shown()

const VISIBILITY_DURATION := 30.0

@export_multiline var text: String = "This is a [shake]tip[/shake]"

@onready var _label := %Label as RichTextLabel

var _already_shown := false

func _ready() -> void:
    # Hide text
    modulate.a = 0

    _label.text = "[center]%s[/center]" % text
    await get_tree().process_frame
    _label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

    area_entered.connect(func(area: Area2D):
        if !_already_shown && area.is_in_group("player_area"):
            var player = area.get_parent() as Player
            if player.behavior_type == Player.BehaviorType.Player:
                _show_text()
    )

func _show_text() -> void:
    _already_shown = true
    shown.emit()

    var tween := create_tween()
    tween.tween_property(self, "modulate", Color.WHITE, 0.5).from(Color.TRANSPARENT).set_ease(Tween.EASE_IN)
    # tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5).from(Color.WHITE).set_ease(Tween.EASE_IN).set_delay(VISIBILITY_DURATION)
