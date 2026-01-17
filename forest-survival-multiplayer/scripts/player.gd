class_name Player
extends CharacterBody2D

@export var index: int

var player_layers: Array[int] = [1,2,4,8]
var collision_masks: Array[int] = [238,221,187,119]

@export var player_alive: bool = true
@export var current_life: float

const SPEED: float = 200.0
const OFFSET: float = 0.1
const MAXLIFE: float = 50.0

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	current_life = MAXLIFE
	
	if is_multiplayer_authority():
		collision_layer = player_layers[index]
		collision_mask = collision_masks[index]
		$Nickname.text = "a"
		

@rpc("any_peer","call_local","reliable")
func set_index(_index):
	index = _index
	collision_layer = player_layers[index]
	collision_mask = collision_masks[index]
	

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	if player_alive:
		velocity = Input.get_vector("ui_left","ui_right","ui_up","ui_down") * SPEED
	move_and_slide()
	
