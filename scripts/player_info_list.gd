extends HBoxContainer

@export var id: int
@export var player_info: Dictionary

@onready var id_label = $Label
@onready var reference_rect = $ReferenceRect
@onready var avatar = $ReferenceRect/AnimatedSprite2D
@onready var name_label = $Label2

func _ready() -> void:
	id_label.text = str(id)
	name_label.text = player_info.get("name", "Unknown Player")
	
	# Apply player color to the avatar container using self_modulate
	if player_info.has("color"):
		reference_rect.self_modulate = player_info["color"]
		avatar.self_modulate = player_info["color"]
