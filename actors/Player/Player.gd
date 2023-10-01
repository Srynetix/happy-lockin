extends CharacterBody2D
class_name Player

signal fired(fire_position: Vector2, fire_direction: Vector2)
signal dead()

enum BehaviorType {
    Player,
    Enemy
}

const MOVE_SPEED := 100
const MOVE_DAMPING := 0.75

const AI_MOVE_SPEED := 10

const ARROW_MARGIN := 24
const ARROW_SIZE := 4
const ARROW_COLOR := Color.ALICE_BLUE

const FIRE_COOLDOWN := 0.05
const ENEMY_FIRE_COOLDOWN := 0.4
const ENEMY_FIRE_DELAY := 1.0
const HIT_COOLDOWN := 1
const ZONE_DETECTION_THRESHOLD := 0.5

@export var behavior_type := BehaviorType.Player

@onready var _raycast := %RayCast2D as RayCast2D
@onready var _sprite := %Sprite2D as Sprite2D
@onready var _area := %Area as Area2D
@onready var _kill_sfx := %KillSFX as SimpleFX
@onready var _hit_sfx := %HitSFX as SimpleFX

var _enemy_ready_to_fire := false
var _fire_enemy_delay := Timer.new()
var _fire_timer := Timer.new()
var _hit_timer := Timer.new()

var _current_zone_cell: ZoneCell = null

var max_life_points := 5
var aim_direction := Vector2.RIGHT
var acceleration := Vector2.ZERO
var is_safe := false
var _dead := false

var _current_life_points := max_life_points

func _ready() -> void:
    add_child(_fire_timer)
    add_child(_hit_timer)
    add_child(_fire_enemy_delay)

    if behavior_type == BehaviorType.Player:
        _fire_timer.wait_time = FIRE_COOLDOWN
    else:
        _fire_timer.wait_time = ENEMY_FIRE_COOLDOWN

    _fire_timer.autostart = false
    _fire_timer.one_shot = true

    _hit_timer.wait_time = HIT_COOLDOWN
    _hit_timer.autostart = false
    _hit_timer.one_shot = true

    _fire_enemy_delay.wait_time = ENEMY_FIRE_DELAY
    _fire_enemy_delay.autostart = false
    _fire_enemy_delay.one_shot = true
    _fire_enemy_delay.timeout.connect(func():
        _enemy_ready_to_fire = true
    )

    if behavior_type == BehaviorType.Player:
        _area.area_entered.connect(func(area: Area2D):
            if area is ZoneCell:
                _current_zone_cell = area
                _on_zone_entered(area)
        )
        _area.area_exited.connect(func(area: Area2D):
            if area is ZoneCell:
                if _current_zone_cell != null && _current_zone_cell == area:
                    _on_zone_exited(area)
        )


func _on_zone_entered(zone: ZoneCell) -> void:
    if zone.effect == ZoneCell.ZoneCellEffect.Safe:
        is_safe = true


func _on_zone_exited(zone: ZoneCell) -> void:
    if zone.effect == ZoneCell.ZoneCellEffect.Safe:
        is_safe = false


func _process(_delta: float) -> void:
    if is_safe:
        _sprite.modulate = Color.GREEN
    else:
        if behavior_type == BehaviorType.Player:
            _sprite.modulate = Color.WHITE
        else:
            _sprite.modulate = Color.RED

    queue_redraw()

func _handle_input() -> void:
    if behavior_type == BehaviorType.Enemy:
        pass

    else:
        if Input.is_action_pressed("move_forward"):
            acceleration.y -= MOVE_SPEED
        elif Input.is_action_pressed("move_backward"):
            acceleration.y += MOVE_SPEED
        if Input.is_action_pressed("move_left"):
            acceleration.x -= MOVE_SPEED
        elif Input.is_action_pressed("move_right"):
            acceleration.x += MOVE_SPEED

        var mouse_position := get_local_mouse_position()
        aim_direction = Vector2.RIGHT.rotated(mouse_position.angle())

        if Input.is_action_just_pressed("fire"):
            _fire()

func _fire() -> void:
    if _fire_timer.is_stopped():
        # Spawn bullet
        var spawn_position := position + (Vector2.RIGHT * ARROW_MARGIN).rotated(aim_direction.angle())
        fired.emit(spawn_position, aim_direction)
        _fire_timer.start()

func hit() -> void:
    _hit_sfx.spawn()

    if behavior_type == BehaviorType.Enemy:
        _current_life_points = max(_current_life_points - 1, 0)
        if _current_life_points == 0:
            if behavior_type == BehaviorType.Enemy:
                kill()
    else:
        if _hit_timer.is_stopped():
            _current_life_points = max(_current_life_points - 1, 0)
            if _current_life_points == 0:
                kill()

            _hit_timer.start()

func _physics_process(_delta: float) -> void:
    acceleration = Vector2.ZERO
    _handle_input()

    velocity += acceleration
    move_and_slide()

    var collision_count := get_slide_collision_count()
    for collision_idx in range(collision_count):
        var collision := get_slide_collision(collision_idx)
        var collider := collision.get_collider()
        if collider is ItemCell:
            collider.pick()

    # Damping
    velocity *= MOVE_DAMPING

    if behavior_type == BehaviorType.Enemy:
        var player_detected := false

        var player := _get_player()
        var player_direction := (player.position - position).normalized()

        _raycast.rotation = player_direction.angle()
        if _raycast.is_colliding():
            var collider = _raycast.get_collider()
            if collider is Player:
                if collider.behavior_type == BehaviorType.Player and !collider._dead:
                    player_detected = true

                    if _enemy_ready_to_fire:
                        _fire()
                    else:
                        if _fire_enemy_delay.is_stopped():
                            _fire_enemy_delay.start()

        if !player_detected:
            _fire_enemy_delay.stop()
            _enemy_ready_to_fire = false
        else:
            aim_direction = player_direction

func _draw() -> void:
    _draw_arrow()

func _draw_arrow() -> void:
    draw_circle(aim_direction * ARROW_MARGIN, ARROW_SIZE, ARROW_COLOR)

func kill() -> void:
    set_physics_process(false)
    _kill_sfx.spawn()
    _dead = true
    dead.emit()

func _get_player() -> Player:
    for node in get_tree().get_nodes_in_group("player"):
        var player := node as Player
        if player.behavior_type == BehaviorType.Player:
            return player

    push_error("Missing player")
    return null
