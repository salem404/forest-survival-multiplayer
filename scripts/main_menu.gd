extends Control

@onready var multiplayer_menu: Control = get_node_or_null("Multiplayer")
@onready var singleplayer_button: Button = get_node_or_null("SingleplayerButton")
@onready var multiplayer_button: Button = get_node_or_null("MultiplayerButton")
@onready var game_manager: Node = get_tree().root.find_child("GameManager", true, false)


func _ready():

	if OS.has_feature("web") and multiplayer_button:
		multiplayer_button.hide()

	if multiplayer_menu:
		multiplayer_menu.hide()


func _on_multiplayer_button_pressed() -> void:
	if multiplayer_menu:
		multiplayer_menu.show()


func _on_singleplayer_button_pressed() -> void:
	if LANLobby.has_active_peer():
		LANLobby.remove_multiplayer_peer()
	if SteamLobby.has_active_peer():
		SteamLobby.remove_multiplayer_peer()
	if game_manager:
		game_manager.swap_scene_to_file("res://scenes/game.tscn")



func _on_settings_button_pressed() -> void:
	game_manager.toggle_settings_menu()


func reset_menu() -> void:
	if multiplayer_menu:
		multiplayer_menu.hide()
