extends CharacterBody2D
class_name Bullet

const MAX_BOUNCES := 1

const BULLET_SCENE := preload("res://actors/Bullet/Bullet2.tscn")
const BULLET_SIZE := 6.0
const BULLET_SPEED := 800.0

@onready var _fire_sfx := %FireSFX as SimpleFX

var direction := Vector2.LEFT

var _bounces := 0

func _ready() -> void:
    _fire_sfx.spawn()

func _process(_delta: float) -> void:
    queue_redraw()

func _physics_process(delta: float) -> void:
    velocity = direction * BULLET_SPEED

    var collision := move_and_collide(velocity * delta)
    if collision:
        var collider = collision.get_collider()
        if collider is Cell:
            collider.hit()
            queue_free()

        if collider is Player:
            collider.hit()
            queue_free()

        if _bounces < MAX_BOUNCES:
            # Let's bounce!
            direction = direction.bounce(collision.get_normal())
            _bounces += 1
        else:
            queue_free()


func _draw() -> void:
    draw_circle(Vector2.ZERO, BULLET_SIZE, Color.LIGHT_GREEN)
