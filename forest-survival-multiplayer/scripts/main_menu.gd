extends Control

func _on_multiplayer_button_pressed() -> void:
	$Multiplayer.show()


func _on_singleplayer_button_pressed() -> void:
	if LANLobby.has_active_peer():
		LANLobby.remove_multiplayer_peer()
	if SteamLobby.has_active_peer():
		SteamLobby.remove_multiplayer_peer()
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	if game_manager:
		game_manager.swap_scene_to_file("res://scenes/game.tscn")


func _ready():
	$Multiplayer.visible = false


func reset_menu() -> void:
	$Multiplayer.visible = false
