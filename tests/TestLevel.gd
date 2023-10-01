extends Node2D

@onready var _player := %Player as Player
@onready var _camera := %Camera2D as SxFxCamera
@onready var _scanner := %AlarmScanner as AlarmScanner
@onready var _map := %TileMap as TileMap

@onready var _middleground_cells := %MiddlegroundCells as Node2D
@onready var _foreground_cells := %ForegroundCells as Node2D

@onready var _health_ui := %HealthUI as ProgressBar
@onready var _score_ui := %ScoreUI as Label
@onready var _timer_ui := %TimerUI as Label

var _is_game_over := false

var _keys_count := 0
var _enemy_killed := 0
var _secrets_count := 0

var _initial_keys_count := 0
var _initial_enemy_count := 0
var _initial_secrets_count := 0

var _lock_positions := []

const MIDDLEGROUND_LAYER_ID := 2

const BOX_CELL_SCENE := preload("res://actors/Cell/BoxCell.tscn")
const ITEM_CELL_SCENE := preload("res://actors/Cell/ItemCell.tscn")
const ZONE_CELL_SCENE := preload("res://actors/Cell/ZoneCell.tscn")
const PLAYER_SCENE := preload("res://actors/Player/Player.tscn")

var _started_at: int = 0

func _ready() -> void:
    _started_at = int(Time.get_ticks_msec() / 1000.0)

    GameMusic.fade_in()
    if !GameMusic.playing:
        GameMusic.set_track(GameMusic.Track.Theme1)
        GameMusic.play()

    _scanner.scan_started.connect(func():
        %UI/Overlay/AnimationPlayer.play("alert")
    )
    _scanner.scan_finished.connect(func():
        %UI/Overlay/AnimationPlayer.play("fade")
    )

    _scanner.player_detected.connect(_on_player_detected)
    _player.fired.connect(_on_player_fire.bind(_player))
    _player.dead.connect(_on_player_dead)

    %UI.visible = true

    var size = _map.get_used_rect()
    _scanner.set_scan_radius(size.size.length() / 2.0 * 64.0)

    # Spawn boxes
    for cell_position in _map.get_used_cells(MIDDLEGROUND_LAYER_ID):
        var cell_tile_data := _map.get_cell_tile_data(MIDDLEGROUND_LAYER_ID, cell_position)
        var cell_name := cell_tile_data.get_custom_data("name") as String
        var source_id := _map.get_cell_source_id(MIDDLEGROUND_LAYER_ID, cell_position)
        var atlas_coords := _map.get_cell_atlas_coords(MIDDLEGROUND_LAYER_ID, cell_position)
        var tileset_source := _map.tile_set.get_source(source_id) as TileSetAtlasSource
        var texture_region := tileset_source.get_tile_texture_region(atlas_coords)

        if cell_name == "box":
            var cell_instance := BOX_CELL_SCENE.instantiate() as BoxCell
            cell_instance.broken.connect(_on_box_broken.bind(cell_instance))

            _middleground_cells.add_child(cell_instance)
            cell_instance.position = (cell_position * 64.0) + (64.0 / 2.0) * Vector2.ONE

            var sprite := cell_instance.get_node("Sprite2D") as Sprite2D
            sprite.texture = tileset_source.texture
            sprite.region_enabled = true
            sprite.region_rect = texture_region

            # Clear cell
            _map.set_cell(MIDDLEGROUND_LAYER_ID, cell_position, -1)

        elif cell_name == "item":
            var cell_instance := ITEM_CELL_SCENE.instantiate() as ItemCell
            cell_instance.picked.connect(_on_item_picked.bind(cell_instance))

            _middleground_cells.add_child(cell_instance)
            cell_instance.position = (cell_position * 64.0) + (64.0 / 2.0) * Vector2.ONE

            var sprite := cell_instance.get_node("Sprite2D") as Sprite2D
            sprite.texture = tileset_source.texture
            sprite.region_enabled = true
            sprite.region_rect = texture_region

            # Clear cell
            _map.set_cell(MIDDLEGROUND_LAYER_ID, cell_position, -1)

            _initial_keys_count += 1

        elif cell_name == "enemy":
            var enemy := PLAYER_SCENE.instantiate() as Player
            enemy.fired.connect(_on_player_fire.bind(enemy))
            enemy.dead.connect(_on_enemy_dead.bind(enemy))

            enemy.behavior_type = Player.BehaviorType.Enemy
            _middleground_cells.add_child(enemy)
            enemy.position = (cell_position * 64.0) + (64.0 / 2.0) * Vector2.ONE

            _map.set_cell(MIDDLEGROUND_LAYER_ID, cell_position, -1)

            _initial_enemy_count += 1

        elif cell_name == "safe":
            var cell_instance := ZONE_CELL_SCENE.instantiate() as ZoneCell
            _foreground_cells.add_child(cell_instance)
            cell_instance.position = (cell_position * 64.0) + (64.0 / 2.0) * Vector2.ONE

            var sprite := cell_instance.get_node("Sprite2D") as Sprite2D
            sprite.texture = tileset_source.texture
            sprite.region_enabled = true
            sprite.region_rect = texture_region

            cell_instance.effect = ZoneCell.ZoneCellEffect.Safe

            _map.set_cell(MIDDLEGROUND_LAYER_ID, cell_position, -1)

        elif cell_name == "lock":
            _lock_positions.push_back(cell_position)

    # Scan secrets
    for node in get_tree().get_nodes_in_group("secret_zone"):
        var zone = node as SecretZone
        zone.found.connect(func():
            _secrets_count += 1
        )
        _initial_secrets_count += 1

    # Scan weird zones
    for node in get_tree().get_nodes_in_group("weird"):
        var weird = node as Weird
        weird.weird_started.connect(func():
            GameMusic.fade_out()
            %ChromaticVFX.enabled = true
            %ChromaticVFX/AnimationPlayer.play("wave")
        )
        weird.weird_stopped.connect(func():
            GameMusic.fade_in()
            %ChromaticVFX/AnimationPlayer.play("fade_out")
        )

    # End zones
    for node in get_tree().get_nodes_in_group("end_zone"):
        var zone := node as EndZone
        zone.finished.connect(func():
            GameMusic.fade_out()
            GameData.last_level_keys = [_keys_count, _initial_keys_count]
            GameData.last_level_enemies = [_enemy_killed, _initial_enemy_count]
            GameData.last_level_secrets = [_secrets_count, _initial_secrets_count]
            GameData.last_level_time = int(float(Time.get_ticks_msec()) / 1000.0 - _started_at)
            GameMusic.fade_out_and_stop()
            GameSceneTransitioner.fade_to_scene_path("res://screens/EndGame.tscn", 0.5)
        )

func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        if event.pressed && event.keycode == KEY_F2:
            %TopHUD.visible = !%TopHUD.visible

func _process(_delta: float) -> void:
    _camera.global_position = _player.global_position.round()

    _score_ui.text = "Keys: %d / %d\nEnemies: %d / %d\nSecrets: %d / %d" % [_keys_count, _initial_keys_count, _enemy_killed, _initial_enemy_count, _secrets_count, _initial_secrets_count]

    var health_ratio = _player._current_life_points / float(_player.max_life_points)
    _health_ui.value = health_ratio * 100
    if health_ratio <= 0.25:
        _health_ui.modulate = Color.RED
    elif health_ratio <= 0.5:
        _health_ui.modulate = Color.ORANGE
    elif health_ratio <= 0.75:
        _health_ui.modulate = Color.YELLOW
    else:
        _health_ui.modulate = Color.GREEN

    if _scanner.is_scanning():
        _timer_ui.text = "SCANNING"
        _camera.shake_ratio = 1.0
    else:
        _timer_ui.text = "Scanning in\n%2.2f seconds" % _scanner.get_remaining_seconds_before_scan()
        _camera.shake_ratio = 0.0

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

    if player.behavior_type == Player.BehaviorType.Enemy:
        bullet.color = Color.LIGHT_CORAL
        bullet.max_bounces = 0

func _on_player_dead() -> void:
    _is_game_over = true
    _scanner.stop()
    %GameOverUI.visible = true
    GameMusic.fade_out()

    await get_tree().create_timer(1.0).timeout
    GameSceneTransitioner.fade_to_scene_path("res://tests/TestLevel.tscn", 0.5)

func _on_enemy_dead(enemy: Player) -> void:
    _enemy_killed += 1
    enemy.queue_free()

func _on_item_picked(item: ItemCell) -> void:
    _keys_count += 1
    if _keys_count == _initial_keys_count:
        _unlock_locks()
    item.queue_free()

func _unlock_locks() -> void:
    for pos in _lock_positions:
        _map.set_cell(MIDDLEGROUND_LAYER_ID, pos, -1)
