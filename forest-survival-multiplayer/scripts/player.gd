class_name Player
extends CharacterBody2D

const SPEED: float = 200.0
const OFFSET: float = 0.1
const MAXLIFE: float = 50.0

var player_layers: Array[int] = [1, 2, 4, 8]
var collision_masks: Array[int] = [238, 221, 187, 119]

@export var index: int
@export var player_alive: bool = true
@export var current_life: float
@export var player_color: Color = Color.WHITE


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	current_life = MAXLIFE

	if is_multiplayer_authority():
		collision_layer = player_layers[index]
		collision_mask = collision_masks[index]

	# Apply color modulation to the sprite
	$AnimatedSprite2D.self_modulate = player_color

	# Hide nickname label if only 1 player
	call_deferred("_check_player_count")


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
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
		
		# Synchronize position, animation and direction to other clients
		sync_movement.rpc(global_position, is_moving, flip_h)

	move_and_slide()


@rpc("any_peer", "call_local", "unreliable")
func sync_movement(_position: Vector2, _is_moving: bool, _flip_h: bool):
	global_position = _position
	
	if _is_moving:
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.animation = "default"
		$AnimatedSprite2D.flip_h = _flip_h
	else:
		$AnimatedSprite2D.animation = "default"
		$AnimatedSprite2D.play()


@rpc("any_peer", "call_local", "reliable")
func set_index(_index):
	index = _index
	collision_layer = player_layers[index]
	collision_mask = collision_masks[index]


@rpc("any_peer", "call_local", "reliable")
func set_player_color(_color: Color):
	player_color = _color
	$AnimatedSprite2D.self_modulate = player_color


func _check_player_count() -> void:
	# In singleplayer, there's only 1 peer (self)
	# In multiplayer, there are multiple peers
	var peer_count = multiplayer.get_peers().size() + 1 # +1 for self
	if peer_count == 1:
		$NicknameLabel.hide()
