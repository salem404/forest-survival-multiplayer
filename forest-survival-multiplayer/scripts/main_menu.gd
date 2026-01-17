extends Control

func _ready() :
	$Multiplayer.visible = false




func _on_multiplayer_button_pressed() -> void:
	$Multiplayer.show()
