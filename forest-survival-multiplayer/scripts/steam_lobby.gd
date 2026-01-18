extends Lobby

const MAX_CONNECTIONS = 4

var is_host: bool = false
var lobby_id: int
var steam_peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()


func init():
	if not initialized:
		initialized = true
		var steam_status = Steam.steamInit(480, true)
		if steam_status:
			Steam.lobby_created.connect(_on_lobby_created)
			Steam.lobby_joined.connect(_on_lobby_joined)
			Steam.initRelayNetworkAccess()
		multiplayer.peer_connected.connect(_on_player_connected)
		multiplayer.peer_disconnected.connect(_on_player_disconnected)
		multiplayer.connected_to_server.connect(_on_connected_ok)
		multiplayer.connection_failed.connect(_on_connected_fail)
		multiplayer.server_disconnected.connect(_on_server_disconnected)
		#Steam.lobby_game_created.connect(_on_lobby_game_created)
		debug_log("Steam Status: %s" % steam_status)


func create_game():
	debug_log("Creating Lobby")
	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, MAX_CONNECTIONS)
	is_host = true


func _on_lobby_created(_result: int, _lobby_id: int):
	if _result == Steam.Result.RESULT_OK:
		debug_log("Lobby created: %d" % _lobby_id)
		lobby_id = _lobby_id
		steam_peer.server_relay = true
		steam_peer.create_host()

		multiplayer.multiplayer_peer = steam_peer
		players[1] = player_info
		player_connected.emit(1, player_info)
		#Lobby.debug_log("game created")
		game_start.connect(_on_game_started)
		server_created.emit()
	else:
		debug_log("Connection error: %d" % _result)


func join_game(_lobby_id: int = 0):
	debug_log("Joining Lobby %d" % _lobby_id)
	Steam.joinLobby(_lobby_id)


func _on_lobby_joined(_lobby_id: int, _permissions: int, _locked: bool, _response: int):
	if not is_host:
		lobby_id = _lobby_id
		steam_peer.server_relay = true
		steam_peer.create_client(Steam.getLobbyOwner(lobby_id))
		debug_log("Lobby joined: %d" % _lobby_id)
		multiplayer.multiplayer_peer = steam_peer
