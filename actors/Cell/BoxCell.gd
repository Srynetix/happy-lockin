extends Cell
class_name BoxCell

signal broken()

const INITIAL_LIFE_POINTS = 3

var _current_life_points := INITIAL_LIFE_POINTS

@onready var _crack_sfx := %CrackSFX as SimpleFX
@onready var _break_vfx := %BreakVFX as SimpleVFX
@onready var _hit_sfx := %HitSFX as SimpleFX

func hit() -> void:
    _current_life_points = max(_current_life_points - 1, 0)
    if _current_life_points == 0:
        _crack_sfx.spawn()
        _break_vfx.spawn()
        broken.emit()
    else:
        _hit_sfx.spawn()
