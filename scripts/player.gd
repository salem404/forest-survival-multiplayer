class_name Player
extends CharacterBody2D

const SPEED: float = 200.0
const MAXLIFE: float = 100.0

const SYNC_INTERVAL: float = 0.01
const REMOTE_SMOOTH_SPEED: float = 14.0
const PLAYER_LAYER_MASK: int = 1 | 2 | 4 | 8

@export var index: int
@export var player_alive: bool = true
@export var current_life: float
@export var player_color: Color = Color.WHITE
@export var player_name: String = "Player"

var player_layers: Array[int] = [1, 2, 4, 8]
var collision_masks: Array[int] = [238, 221, 187, 119]

var last_synced_position: Vector2 = Vector2.ZERO
var last_synced_moving: bool = false
var last_synced_flip: bool = false
var last_synced_animation: String = "idleFront"
var sync_timer: float = 0.0
var last_facing: Vector2 = Vector2(0, 1)
var remote_target_position: Vector2 = Vector2.ZERO
var remote_has_target: bool = false

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var camera: Camera2D = $Camera2D
@onready var player_sprite: Sprite2D = $Sprite2D
@onready var nickname_label: Label = $NicknameLabel


func _enter_tree() -> void:
	set_multiplayer_authority(_get_authority_id())


func _ready() -> void:
	current_life = 50.0

	collision_layer = player_layers[index]
	collision_mask = collision_masks[index]

	if _is_local_authority():
		camera.enabled = true
	else:
		camera.enabled = false
		set_physics_process(false)

	player_sprite.self_modulate = player_color
	nickname_label.text = player_name

	call_deferred("_check_player_count")


func _is_singleplayer() -> bool:
	var is_offline = multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	return is_offline or multiplayer.get_peers().is_empty()


func _get_authority_id() -> int:
	return 1 if _is_singleplayer() else name.to_int()


func _is_local_authority() -> bool:
	return _is_singleplayer() or is_multiplayer_authority()


func _physics_process(_delta: float) -> void:
	if not _is_local_authority():
		return

	if player_alive:
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = direction * SPEED
		var is_moving = direction != Vector2.ZERO
		var flip_h = direction.x > 0 if is_moving else player_sprite.flip_h

		if is_moving:
			last_facing = direction.normalized()
			_update_blend_positions(last_facing)
		else:
			_update_blend_positions(last_facing)

		player_sprite.flip_h = flip_h

	move_and_slide()

	sync_timer += get_physics_process_delta_time()
	if sync_timer >= SYNC_INTERVAL:
		sync_timer = 0.0
		var is_moving = velocity != Vector2.ZERO
		var flip_h = player_sprite.flip_h

		var position_changed = global_position != last_synced_position
		var moving_changed = is_moving != last_synced_moving
		var flip_changed = flip_h != last_synced_flip

		if position_changed or moving_changed or flip_changed:
			if _is_singleplayer():
				_update_last_synced(global_position, is_moving, flip_h)
				return
			var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			sync_movement.rpc(global_position, is_moving, flip_h, direction)
			_update_last_synced(global_position, is_moving, flip_h)


func _update_blend_positions(direction: Vector2) -> void:
	animation_tree.set("parameters/Walk/blend_position", direction)
	animation_tree.set("parameters/Idle/blend_position", direction)


func _apply_remote_state(
		_position: Vector2,
		_is_moving: bool,
		_flip_h: bool,
		_direction: Vector2,
) -> void:
	remote_target_position = _position
	remote_has_target = true
	# Update animation tree blend position for remote players
	if _direction != Vector2.ZERO:
		last_facing = _direction.normalized()
	else:
		# Use last_facing if direction is zero
		_direction = last_facing
	_update_blend_positions(_direction)
	player_sprite.flip_h = _flip_h


@rpc("any_peer", "call_remote", "unreliable")
func sync_movement(_position: Vector2, _is_moving: bool, _flip_h: bool, _direction: Vector2):
	if _is_local_authority():
		return
	call_deferred("_apply_remote_state", _position, _is_moving, _flip_h, _direction)


func _process(_delta: float) -> void:
	if _is_local_authority():
		return
	if not remote_has_target:
		return
	var t = 1.0 - exp(-REMOTE_SMOOTH_SPEED * _delta)
	global_position = global_position.lerp(remote_target_position, t)


func _update_last_synced(_position: Vector2, _is_moving: bool, _flip_h: bool) -> void:
	last_synced_position = _position
	last_synced_moving = _is_moving
	last_synced_flip = _flip_h


@rpc("any_peer", "call_local", "reliable")
func set_index(_index):
	index = _index
	collision_layer = player_layers[index]
	collision_mask = collision_masks[index]


@rpc("any_peer", "call_local", "reliable")
func heal(amount: float) -> void:
	current_life = min(current_life + amount, MAXLIFE)


func _check_player_count() -> void:
	var peer_count = multiplayer.get_peers().size() + 1 # +1 for self
	if peer_count == 1:
		nickname_label.hide()
