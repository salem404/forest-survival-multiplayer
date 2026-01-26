class_name SafeZone
extends Area2D

@export var healing_rate: float = 5.0 # Health points per second
@export var radius: float = 100.0
var collision_shape: CollisionShape2D
var circle_shape = CircleShape2D
var players_in_zone: Array[Player] = []

func _ready():
	# Set the collision shape radius
	if not has_node("CollisionShape2D"):
		collision_shape = CollisionShape2D.new()
		add_child(collision_shape)
	else:
		collision_shape = $CollisionShape2D

	if not has_node("CollisionShape2D/Shape"):
		circle_shape = CircleShape2D.new()
		circle_shape.radius = radius
		collision_shape.shape = circle_shape
	else:
		circle_shape = collision_shape.shape
	
	set_radius(radius)
	
	# Detect all player layers (1, 2, 4, 8)
	collision_mask = 0b1111  # Detect layers 1, 2, 3, 4
	
	# Connect signals for body entered and exited
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta) -> void:
	# Apply healing to all players in the zone (server only to avoid duplicate calls)
	if multiplayer.is_server():
		for player in players_in_zone:
			if is_instance_valid(player):
				player.rpc("heal", healing_rate * delta)

func _on_body_entered(_body: Node2D) -> void:
	if _body is Player:
		players_in_zone.append(_body)
	print("player in area")

func _on_body_exited(_body: Node2D) -> void:
	if _body is Player:
		players_in_zone.erase(_body)
	print("player leaving area")

func set_radius(new_radius: float) -> void:
	radius = new_radius
	circle_shape.radius = radius
