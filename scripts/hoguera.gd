extends Node2D


func _ready() -> void:
	# Access the SafeZone node and modify its properties

	$SafeZone.healing_rate = 5.0
	$SafeZone.set_radius(100.0)

	
