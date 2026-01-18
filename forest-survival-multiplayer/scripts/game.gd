extends Node2D

const PLAYER_SCENE = preload("res://scenes/player.tscn")

@onready var players_nodes = $Players
@onready var spawners = get_spawner_positions()


func get_spawner_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var players_node = $Players
	if players_node:
		for child in players_node.get_children():
			positions.append(child.position)
	return positions


func _ready() -> void:
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	var has_lobby = game_manager and game_manager.current_lobby
	var has_lobby_players = has_lobby and game_manager.current_lobby.players.size() > 0

	if _is_multiplayer_active() and has_lobby_players:
		game_manager.current_lobby.server_disconnected.connect(_on_server_disconnected)
		game_manager.current_lobby.player_disconnected.connect(_on_player_disconnected)
		call_deferred("start_game_server")
	else:
		call_deferred("spawn_singleplayer_player")


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _is_multiplayer_active() -> bool:
	var is_offline = multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	return not (is_offline or multiplayer.get_peers().is_empty())


func start_game_server():
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	if not game_manager:
		return

	var i = 0
	var sorted_ids = game_manager.current_lobby.players.keys()
	sorted_ids.sort()

	for id in sorted_ids:
		var player_info = game_manager.current_lobby.players[id]
		var player = PLAYER_SCENE.instantiate()
		player.name = str(id)
		player.index = i
		player.player_color = player_info.get("color", Color.WHITE)
		var player_display_name = player_info.get("name", "Player %d" % (i + 1))
		player.player_name = player_display_name

		if spawners.size() > i:
			player.global_position = spawners[i]
		else:
			player.global_position = Vector2(100 + i * 50, 100)

		players_nodes.add_child(player)
		i += 1

	if not multiplayer.is_server():
		game_manager.current_lobby.player_loaded.rpc_id(1)


func spawn_singleplayer_player():
	var player = PLAYER_SCENE.instantiate()
	if player:
		player.name = "1"
		player.index = 0
		player.collision_layer = 1
		player.collision_mask = 1
		if players_nodes.get_child_count() > 0:
			player.global_position = players_nodes.get_child(0).global_position
		players_nodes.add_child(player)


func _on_server_disconnected():
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	if game_manager:
		game_manager.swap_scene_to_file("res://scenes/main_menu.tscn")


func _on_player_disconnected(id: int):
	if multiplayer.is_server():
		var player_node = players_nodes.find_child(str(id), true, false)
		if player_node:
			player_node.queue_free()
