class_name Lobby
extends Node

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal connection_failed
signal server_created
signal server_disconnected
signal game_start(scene_path)

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = { }

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = { "name": "Player 1", "color": Color.WHITE }

var initialized: bool = false
var players_loaded = 1
var game_started: bool = false
var game_scene


func _on_game_started(_game_scene):
	game_scene = _game_scene
	if players.size() > 1:
		load_game.rpc(_game_scene)
	else:
		load_game(_game_scene)


func start_game(_game_scene):
	game_start.emit(_game_scene)


# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_remote", "reliable")
func load_game(_game_scene: String):
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	if game_manager:
		game_manager.swap_scene_to_file("res://scenes/game.tscn")


# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			game_started = true
			load_game(game_scene)


# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	if game_started:
		_game_has_started.rpc_id(id)
		return
	_register_player.rpc_id(id, player_info)


@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)


@rpc("any_peer", "call_remote", "reliable")
func _game_has_started():
	remove_multiplayer_peer()
	server_disconnected.emit()


func _on_player_disconnected(id):
	debug_log("player disconnected %d" % id)
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)


func _on_connected_fail():
	remove_multiplayer_peer()
	connection_failed.emit()


func _on_server_disconnected():
	remove_multiplayer_peer()
	server_disconnected.emit()


func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()


func debug_log(text: String):
	print(str(Time.get_ticks_msec()) + "ms (" + str(multiplayer.get_unique_id()) + "): " + text)
