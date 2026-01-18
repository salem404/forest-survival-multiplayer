extends Control

func _on_multiplayer_button_pressed() -> void:
	$Multiplayer.show()


func _on_singleplayer_button_pressed() -> void:
	%GameManager.swap_scene_to_file("res://scenes/game.tscn")


func _ready():
	$Multiplayer.visible = false
