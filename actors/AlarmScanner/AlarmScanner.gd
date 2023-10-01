extends Node2D
class_name AlarmScanner

signal player_detected()
signal scan_started()
signal scan_finished()

const MINIMUM_SCAN_RADIUS := 100.0

enum ScanState {
    Init,
    Scan,
    Fade
}

@onready var _area := $Area2D as Area2D
@onready var _collision_shape := %CollisionShape2D as CollisionShape2D
@onready var _shape := _collision_shape.shape as CircleShape2D
@onready var _scan_sfx := %ScanSFX as AudioStreamPlayer

var _initial_scan_delay := 10.0
var _initial_scan_radius := 1000.0

var _scan_speed := 4.0
var _scan_state := ScanState.Init

var _current_scan_delay := _initial_scan_delay
var _current_scan_radius := _initial_scan_radius

func set_scan_radius(radius: float) -> void:
    _initial_scan_radius = radius
    _current_scan_radius = radius
    _set_state(ScanState.Init)

func is_scanning() -> bool:
    return _scan_state == ScanState.Scan

func get_remaining_seconds_before_scan() -> float:
    return _initial_scan_delay - (_initial_scan_delay - _current_scan_delay)

func _ready() -> void:
    _set_state(ScanState.Init)

    _shape.radius = _initial_scan_radius
    _area.area_exited.connect(_on_area_exited)

func _handle_state_transition(prev_state: ScanState, new_state: ScanState) -> void:
    if prev_state == ScanState.Scan:
        scan_finished.emit()
        _scan_sfx.stop()

    if new_state == ScanState.Init:
        modulate.a = 0
        _current_scan_delay = _initial_scan_delay

    if new_state == ScanState.Scan:
        modulate.a = 1
        _current_scan_radius = _initial_scan_radius
        _shape.radius = _initial_scan_radius
        _scan_sfx.play()
        scan_started.emit()

    if prev_state == ScanState.Fade:
        _current_scan_radius = _initial_scan_radius

func _set_state(new_state: ScanState) -> void:
    _handle_state_transition(_scan_state, new_state)
    _scan_state = new_state

func _physics_process(delta: float) -> void:
    if _scan_state == ScanState.Init:
        _current_scan_delay -= delta
        _current_scan_delay = max(_current_scan_delay, 0)

        if _current_scan_delay == 0:
            _set_state(ScanState.Scan)

    if _scan_state == ScanState.Scan:
        _current_scan_radius -= _scan_speed
        _current_scan_radius = max(_current_scan_radius, MINIMUM_SCAN_RADIUS)

        # Adjust the volume depending on the distance with the player
        var radius_to_player := (_get_player().position - position).length()
        var ratio := radius_to_player / _current_scan_radius
        if ratio > 1:
            ratio = 1 - ratio
        ratio = max(ratio, 0.25)
        _scan_sfx.volume_db = linear_to_db(ratio)

        if _current_scan_radius == MINIMUM_SCAN_RADIUS:
            _set_state(ScanState.Fade)

    if _scan_state == ScanState.Fade:
        modulate.a = max(modulate.a - delta * 2, 0)
        if modulate.a == 0:
            _set_state(ScanState.Init)

    _shape.radius = _current_scan_radius

    queue_redraw()

func _on_area_exited(area: Area2D) -> void:
    if _scan_state == ScanState.Scan && area.is_in_group("player_area"):
        var player := area.get_parent() as Player
        if player.behavior_type == Player.BehaviorType.Player && !player.is_safe:
            player_detected.emit()

func reset() -> void:
    _set_state(ScanState.Fade)

func stop() -> void:
    set_physics_process(false)

func _draw() -> void:
    var points_count := int(max(_current_scan_radius / 10.0, 24))
    draw_arc(Vector2.ZERO, _current_scan_radius, 0, TAU, points_count, Color.RED, 8)

func _get_player() -> Player:
    for node in get_tree().get_nodes_in_group("player"):
        var player := node as Player
        if player.behavior_type == Player.BehaviorType.Player:
            return player

    push_error("Missing player")
    return null
