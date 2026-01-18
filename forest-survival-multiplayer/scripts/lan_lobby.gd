extends Lobby

const DEFAULT_PORT = 6666
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 4


func init():
	if not initialized:
		initialized = true
		multiplayer.peer_connected.connect(_on_player_connected)
		multiplayer.peer_disconnected.connect(_on_player_disconnected)
		multiplayer.connected_to_server.connect(_on_connected_ok)
		multiplayer.connection_failed.connect(_on_connected_fail)
		multiplayer.server_disconnected.connect(_on_server_disconnected)


func create_game(port = 0):
	if port == 0:
		port = DEFAULT_PORT
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

	players[1] = player_info
	player_connected.emit(1, player_info)
	#Lobby.debug_log("game created")
	game_start.connect(_on_game_started)


func join_game(address = "", port = 0):
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	if port == 0:
		port = DEFAULT_PORT
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(address, port)
	if result:
		return result
	multiplayer.multiplayer_peer = peer
