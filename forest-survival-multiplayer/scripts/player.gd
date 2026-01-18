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


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	current_life = MAXLIFE

	if is_multiplayer_authority():
		collision_layer = player_layers[index]
		collision_mask = collision_masks[index]
		$Nickname.text = "a"


func _physics_process(_delta: float) -> void:
	#if not is_multiplayer_authority():
	#	return
	if player_alive:
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = direction * SPEED
		if direction != Vector2.ZERO:
			$AnimatedSprite2D.play()
			$AnimatedSprite2D.animation = "default"
			$AnimatedSprite2D.flip_h = direction.x > 0
		else:
			$AnimatedSprite2D.animation = "default" # "idle"
			$AnimatedSprite2D.play()

	move_and_slide()


@rpc("any_peer", "call_local", "reliable")
func set_index(_index):
	index = _index
	collision_layer = player_layers[index]
	collision_mask = collision_masks[index]
