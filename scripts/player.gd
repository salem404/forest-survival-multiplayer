class_name Player
extends CharacterBody2D

const SPEED: float = 200.0
const MAXLIFE: float = 50.0

var player_layers: Array[int] = [1, 2, 4, 8]
var collision_masks: Array[int] = [238, 221, 187, 119]

@export var index: int
@export var player_alive: bool = true
@export var current_life: float
@export var player_color: Color = Color.WHITE
@export var player_name: String = "Player"

var last_synced_position: Vector2 = Vector2.ZERO
var last_synced_moving: bool = false
var last_synced_flip: bool = false
var sync_timer: float = 0.0
const SYNC_INTERVAL: float = 0.01

var remote_target_position: Vector2 = Vector2.ZERO
var remote_has_target: bool = false
const REMOTE_SMOOTH_SPEED: float = 14.0


func _enter_tree() -> void:
	set_multiplayer_authority(_get_authority_id())


func _ready() -> void:
	current_life = MAXLIFE

	collision_layer = player_layers[index]
	collision_mask = collision_masks[index]

	if _is_local_authority():
		$Camera2D.enabled = true
	else:
		$Camera2D.enabled = false
		set_physics_process(false)

	$AnimatedSprite2D.self_modulate = player_color
	$NicknameLabel.text = player_name

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
		var flip_h = direction.x > 0 if is_moving else $AnimatedSprite2D.flip_h

		if is_moving:
			$AnimatedSprite2D.play()
			$AnimatedSprite2D.animation = "default"
			$AnimatedSprite2D.flip_h = flip_h
		else:
			$AnimatedSprite2D.animation = "default" # "idle"
			$AnimatedSprite2D.play()

	move_and_slide()

	sync_timer += get_physics_process_delta_time()
	if sync_timer >= SYNC_INTERVAL:
		sync_timer = 0.0
		var is_moving = velocity != Vector2.ZERO
		var flip_h = $AnimatedSprite2D.flip_h

		var position_changed = global_position != last_synced_position
		var moving_changed = is_moving != last_synced_moving
		var flip_changed = flip_h != last_synced_flip
		if position_changed or moving_changed or flip_changed:
			if _is_singleplayer():
				_update_last_synced(global_position, is_moving, flip_h)
				return
			sync_movement.rpc(global_position, is_moving, flip_h)
			_update_last_synced(global_position, is_moving, flip_h)


func _apply_remote_state(_position: Vector2, _is_moving: bool, _flip_h: bool) -> void:
	remote_target_position = _position
	remote_has_target = true
	if _is_moving:
		$AnimatedSprite2D.animation = "default" # "run"
	else:
		$AnimatedSprite2D.animation = "default"
	$AnimatedSprite2D.flip_h = _flip_h
	$AnimatedSprite2D.play()


@rpc("authority", "call_local", "unreliable")
func sync_movement(_position: Vector2, _is_moving: bool, _flip_h: bool):
	if _is_local_authority():
		return
	call_deferred("_apply_remote_state", _position, _is_moving, _flip_h)


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


func _check_player_count() -> void:
	var peer_count = multiplayer.get_peers().size() + 1 # +1 for self
	if peer_count == 1:
		$NicknameLabel.hide()
