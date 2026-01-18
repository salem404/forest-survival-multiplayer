class_name Lobby
extends Node

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal connection_failed
signal server_created
signal server_disconnected
signal game_start(scene_path)
signal lobby_full

const MAX_PLAYERS = 4

var players = { }

var player_info = { "name": "Player 1", "color": Color.WHITE }

var initialized: bool = false
var players_loaded = 1
var game_started: bool = false
var game_scene


func start_game(_game_scene):
	if multiplayer.is_server():
		debug_log("Starting game with %d players" % players.size())
		game_scene = _game_scene
		_start_game.rpc(_game_scene)


@rpc("authority", "call_local", "reliable")
func _start_game(_game_scene: String):
	game_scene = _game_scene
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	if game_manager:
		game_manager.swap_scene_to_file("res://scenes/game.tscn")


# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_remote", "reliable")
func load_game(_game_scene: String):
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	if game_manager:
		game_manager.swap_scene_to_file("res://scenes/game.tscn")


@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			game_started = true


func _on_player_connected(id):
	if game_started:
		_game_has_started.rpc_id(id)
		return
	if multiplayer.is_server():
		if players.size() >= MAX_PLAYERS:
			_reject_peer(id)
			return
		_register_player.rpc_id(id, 1, player_info)
		for peer_id in players:
			if peer_id != 1:
				_register_player.rpc_id(id, peer_id, players[peer_id])


@rpc("any_peer", "call_local", "reliable")
func _register_player(new_player_id: int, new_player_info):
	if multiplayer.is_server() and not players.has(new_player_id) and players.size() >= MAX_PLAYERS:
		_reject_peer(new_player_id)
		return
	if players.has(new_player_id):
		players[new_player_id] = new_player_info
		return
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)
	if multiplayer.is_server():
		for peer_id in players:
			if peer_id != new_player_id:
				_register_player.rpc_id(peer_id, new_player_id, new_player_info)


@rpc("any_peer", "call_remote", "reliable")
func _game_has_started():
	remove_multiplayer_peer()
	server_disconnected.emit()


func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)
	if not multiplayer.is_server():
		_register_player.rpc_id(1, peer_id, player_info)


func _on_connected_fail():
	remove_multiplayer_peer()
	connection_failed.emit()


func _on_server_disconnected():
	remove_multiplayer_peer()
	server_disconnected.emit()


func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()


func has_active_peer() -> bool:
	return (
		multiplayer.multiplayer_peer != null
		and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer)
	)


func _reject_peer(id: int) -> void:
	_lobby_full_message.rpc_id(id)
	await get_tree().create_timer(0.2).timeout
	multiplayer.disconnect_peer(id)


@rpc("call_remote", "reliable")
func _lobby_full_message() -> void:
	lobby_full.emit()


func debug_log(text: String):
	print(str(Time.get_ticks_msec()) + "ms (" + str(multiplayer.get_unique_id()) + "): " + text)
