extends Node2D

@onready var _player := %Player as Player
@onready var _camera := %Camera2D as Camera2D
@onready var _mask := $UI/Mask as TextureRect
@onready var _scanner := %AlarmScanner as AlarmScanner
@onready var _map := %TileMap as TileMap
@onready var _cells := %Cells as Node2D

@onready var _health_ui := %HealthUI as Label
@onready var _score_ui := %ScoreUI as Label
@onready var _timer_ui := %TimerUI as Label

var _is_game_over := false

var _keys_count := 0
var _enemy_killed := 0
var _secrets_count := 0

var _initial_keys_count := 0
var _initial_enemy_count := 0
var _initial_secrets_count := 3

const BOX_CELL_SCENE := preload("res://actors/Cell/BoxCell.tscn")
const ITEM_CELL_SCENE := preload("res://actors/Cell/ItemCell.tscn")
const ZONE_CELL_SCENE := preload("res://actors/Cell/ZoneCell.tscn")
const PLAYER_SCENE := preload("res://actors/Player/Player.tscn")

func _ready() -> void:
    if !GameMusic.playing:
        GameMusic.play()

    _scanner.finished.connect(_on_scan_finished)
    _scanner.player_detected.connect(_on_player_detected)
    _player.fired.connect(_on_player_fire.bind(_player))
    _player.dead.connect(_on_player_dead)

    %UI.visible = true

    var way_atlas_coords := Vector2(2, 3)

    # Set radius
    var size = _map.get_used_rect()
    _scanner.set_scan_radius(size.size.length() / 2.0 * 64.0)

    # Spawn boxes
    for cell_position in _map.get_used_cells(0):
        var cell_tile_data := _map.get_cell_tile_data(0, cell_position)
        var cell_name := cell_tile_data.get_custom_data("name") as String
        var source_id := _map.get_cell_source_id(0, cell_position)
        var atlas_coords := _map.get_cell_atlas_coords(0, cell_position)
        var tileset_source := _map.tile_set.get_source(source_id) as TileSetAtlasSource
        var texture_region := tileset_source.get_tile_texture_region(atlas_coords)

        if cell_name == "box":
            var cell_instance := BOX_CELL_SCENE.instantiate() as BoxCell
            cell_instance.broken.connect(_on_box_broken.bind(cell_instance))

            _cells.add_child(cell_instance)
            cell_instance.position = (cell_position * 64.0) + (64.0 / 2.0) * Vector2.ONE

            var sprite := cell_instance.get_node("Sprite2D") as Sprite2D
            sprite.texture = tileset_source.texture
            sprite.region_enabled = true
            sprite.region_rect = texture_region

            # Clear cell
            _map.set_cell(0, cell_position, source_id, way_atlas_coords)

        elif cell_name == "item":
            var cell_instance := ITEM_CELL_SCENE.instantiate() as ItemCell
            cell_instance.picked.connect(_on_item_picked.bind(cell_instance))

            _cells.add_child(cell_instance)
            cell_instance.position = (cell_position * 64.0) + (64.0 / 2.0) * Vector2.ONE

            var sprite := cell_instance.get_node("Sprite2D") as Sprite2D
            sprite.texture = tileset_source.texture
            sprite.region_enabled = true
            sprite.region_rect = texture_region

            # Clear cell
            _map.set_cell(0, cell_position, source_id, way_atlas_coords)

            _initial_keys_count += 1

        elif cell_name == "safe":
            var cell_instance := ZONE_CELL_SCENE.instantiate() as ZoneCell
            _cells.add_child(cell_instance)
            cell_instance.position = (cell_position * 64.0) + (64.0 / 2.0) * Vector2.ONE

            var sprite := cell_instance.get_node("Sprite2D") as Sprite2D
            sprite.texture = tileset_source.texture
            sprite.region_enabled = true
            sprite.region_rect = texture_region

            cell_instance.effect = ZoneCell.ZoneCellEffect.Safe

            # Clear cell
            _map.set_cell(0, cell_position, source_id, way_atlas_coords)

        elif cell_name == "enemy":
            var enemy := PLAYER_SCENE.instantiate() as Player
            enemy.fired.connect(_on_player_fire.bind(enemy))
            enemy.dead.connect(_on_enemy_dead.bind(enemy))

            enemy.behavior_type = Player.BehaviorType.Enemy
            _cells.add_child(enemy)
            enemy.position = (cell_position * 64.0) + (64.0 / 2.0) * Vector2.ONE

            _map.set_cell(0, cell_position, source_id, way_atlas_coords)

            _initial_enemy_count += 1


func _process(_delta: float) -> void:
    _camera.global_position = _player.global_position

    _score_ui.text = "Keys: %d / %d\nEnemies: %d / %d\nSecrets: %d / %d" % [_keys_count, _initial_keys_count, _enemy_killed, _initial_enemy_count, _secrets_count, _initial_secrets_count]
    _health_ui.text = "Health\n%d" % _player._current_life_points

    if _scanner.is_scanning():
        _timer_ui.text = "SCANNING"
    else:
        _timer_ui.text = "Scanning in\n%2.2f seconds" % _scanner.get_remaining_seconds_before_scan()

func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        if event.pressed && event.keycode == KEY_SPACE:
            _mask.visible = !_mask.visible

        if event.pressed && event.keycode == KEY_F1:
            _scanner.trigger()

func _on_scan_finished() -> void:
    print("Scan finished.")

func _on_player_detected() -> void:
    _player.kill()
    _scanner.reset()

func _on_box_broken(box: BoxCell) -> void:
    box.queue_free()

func _on_player_fire(fire_position: Vector2, fire_direction: Vector2, player: Player) -> void:
    var bullet := Bullet.BULLET_SCENE.instantiate() as Bullet
    bullet.position = fire_position
    bullet.direction = fire_direction
    bullet.add_collision_exception_with(player)
    add_child(bullet)

func _on_player_dead() -> void:
    _is_game_over = true
    _scanner.stop()
    %GameOverUI.visible = true

    await get_tree().create_timer(3.0).timeout
    GameSceneTransitioner.fade_to_scene_path("res://tests/TestLevel.tscn")

func _on_enemy_dead(enemy: Player) -> void:
    _enemy_killed += 1
    enemy.queue_free()

func _on_item_picked(item: ItemCell) -> void:
    _keys_count += 1
    item.queue_free()
