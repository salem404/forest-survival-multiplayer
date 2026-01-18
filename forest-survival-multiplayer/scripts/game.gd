extends Node2D

@export var spawners: Array[MultiplayerSpawner]

@onready var players_nodes = $Players


func _ready() -> void:
	if %GameManager and %GameManager.is_online:
		%GameManager.current_lobby.server_disconnected.connect(_on_server_disconnected)
		%GameManager.current_lobby.player_disconnected.connect(_on_player_disconnected)
		call_deferred("start_game_server")
	else:
		# Singleplayer mode - spawn a single player
		call_deferred("spawn_singleplayer_player")


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


# Called only on the server.
func start_game_server():
	if multiplayer.is_server():
		var i = 0
		for id in %GameManager.current_lobby.players:
			spawners[i % 4].spawn_player(id, i)
			i += 1
	else:
		%GameManager.current_lobby.player_loaded.rpc_id(1)
	# Tell the server that this peer has loaded.


func spawn_singleplayer_player():
	# For singleplayer, directly instantiate the player scene
	var player_scene = load("res://scenes/player.tscn")
	if player_scene:
		var player = player_scene.instantiate()
		player.name = "1"  # Set ID to 1
		player.index = 0   # First player slot
		# For singleplayer, set collision to detect the tilemap physics
		# TileMapLayer uses physics_layer_0 by default
		player.collision_layer = 1  # Player is on layer 1
		player.collision_mask = 1   # Player collides with layer 1 (tilemap)
		# Position at the first player spawn point
		if players_nodes.get_child_count() > 0:
			player.global_position = players_nodes.get_child(0).global_position
		players_nodes.add_child(player)


func _on_server_disconnected():
	%GameManager.swap_scene_to_file("res://scenes/main_menu.tscn")


func _on_player_disconnected(id: int):
	if multiplayer.is_server():
		var player_node = players_nodes.find_child(str(id), true, false)
		if player_node:
			player_node.queue_free()
