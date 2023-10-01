extends Control
class_name EndGame

@onready var _keys := %Keys as Label
@onready var _enemies := %Enemies as Label
@onready var _secrets := %Secrets as Label
@onready var _time := %Time as Label
@onready var _total_score := %TotalScore as Label
@onready var _commentary := %Commentary as Label

var keys_value := 0
var secrets_value := 0
var enemies_value := 0
var time_value := 0
var total_value := 0

func _ready() -> void:
    var target_total_value = _get_total_value()

    _keys.get_parent().modulate = Color.TRANSPARENT
    _enemies.get_parent().modulate = Color.TRANSPARENT
    _secrets.get_parent().modulate = Color.TRANSPARENT
    _time.get_parent().modulate = Color.TRANSPARENT
    _total_score.get_parent().modulate = Color.TRANSPARENT
    _commentary.modulate = Color.TRANSPARENT

    _commentary.text = _get_commentary()

    var tween = create_tween()
    tween.tween_property(_keys.get_parent(), "modulate", Color.WHITE, 0.5)
    tween.tween_property(self, "keys_value", GameData.last_level_keys[0], 1)
    tween.tween_property(_enemies.get_parent(), "modulate", Color.WHITE, 0.5)
    tween.tween_property(self, "enemies_value", GameData.last_level_enemies[0], 1)
    tween.tween_property(_secrets.get_parent(), "modulate", Color.WHITE, 0.5)
    tween.tween_property(self, "secrets_value", GameData.last_level_secrets[0], 1)
    tween.tween_property(_time.get_parent(), "modulate", Color.WHITE, 0.5)
    tween.tween_property(self, "time_value", GameData.last_level_time, 1)
    tween.tween_property(_total_score.get_parent(), "modulate", Color.WHITE, 0.5)
    tween.tween_property(self, "total_value", target_total_value, 1)
    tween.tween_property(_commentary, "modulate", Color.WHITE, 1)
    await tween.finished

    await get_tree().create_timer(3.0).timeout

    GameSceneTransitioner.fade_to_scene_path("res://screens/Credits.tscn", 0.5)

func _process(_delta: float) -> void:
    _keys.text = str(keys_value) + " / " + str(GameData.last_level_keys[1])
    _enemies.text = str(enemies_value) + " / " + str(GameData.last_level_enemies[1])
    _secrets.text = str(secrets_value) + " / " + str(GameData.last_level_secrets[1])
    _time.text = str(time_value) + " seconds"
    _total_score.text = str(total_value) + "%"

func _get_total_value() -> float:
    var total = GameData.last_level_keys[1] + GameData.last_level_enemies[1] + GameData.last_level_secrets[1]
    var current = GameData.last_level_keys[0] + GameData.last_level_enemies[0] + GameData.last_level_secrets[0]

    return (float(current) / float(total)) * 100.0

func _get_commentary() -> String:
    var value = _get_total_value()
    if value < 50:
        return "Meh, you can do better."
    elif value < 75:
        return "Not bad, but you missed some things."
    elif value < 100:
        return "Good, still missing some things."
    else:
        return "Perfect, you found everything!"
