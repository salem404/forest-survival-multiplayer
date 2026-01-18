extends Control

@export var player_info_list: PackedScene
@export var game_scene: PackedScene
@export var connection_type: String

@onready var playername = %PlayerNameInput
@onready var serverbutton = %ServerButton
@onready var clientbutton = %ClientButton
@onready var statuslabel = %StatusLabel
@onready var startgamebutton = %StartGameButton
@onready var player_list = %PlayerList
@onready var portinput = %PortInput
@onready var ipinput = %IPInput
@onready var lobbyinput = %LobbyInput
@onready var invitebutton = %InviteButton
@onready var player_color_picker = %PlayerColor


func _ready() -> void:
	if not game_scene:
		game_scene = load("res://scenes/game.tscn")
	
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	
	if connection_type == "Steam":
		SteamLobby.init()
		game_manager.current_lobby = SteamLobby
		# event callback when invited by friend
		Steam.join_requested.connect(_on_join_requested)
		# events from lobby
		SteamLobby.player_connected.connect(_on_player_connected)
		SteamLobby.server_created.connect(_on_server_created)
		SteamLobby.server_disconnected.connect(_on_server_disconnected)
		SteamLobby.connection_failed.connect(_on_connection_failed)

		### debug only
		playername.text = Steam.getFriendPersonaName(Steam.getSteamID())
	else:
		LANLobby.init()
		game_manager.current_lobby = LANLobby
		LANLobby.player_connected.connect(_on_player_connected)
		LANLobby.server_disconnected.connect(_on_server_disconnected)
		LANLobby.connection_failed.connect(_on_connection_failed)

		portinput.text = str(LANLobby.DEFAULT_PORT)
		ipinput.text = LANLobby.DEFAULT_SERVER_IP

		### debug only
		playername.text = "debug player"


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _on_player_connected(id, player_info):
	if not player_info_list:
		return
	var info_list = player_info_list.instantiate()
	info_list.id = id
	info_list.player_info = player_info
	player_list.add_child(info_list)


func _on_connection_failed():
	statuslabel.text = "Status: Connection failed"
	disable_buttons(false)


func _on_back_to_menu_button_pressed() -> void:
	$".".hide()


func _on_server_mode_tab_selected(tab: int) -> void:
	match tab:
		0:
			connection_type = "LAN"
		1:
			connection_type = "Steam"


func _on_player_color_color_changed(color: Color) -> void:
	pass # Replace with function body.


func _on_server_button_pressed() -> void:
	if not _required_data():
		return

	if connection_type == "Steam":
		SteamLobby.create_game()
	else:
		LANLobby.create_game()
	disable_buttons(true)
	startgamebutton.visible = true

func _on_server_created():
	lobbyinput.text = str(SteamLobby.lobby_id)
	invitebutton.disabled = false


func _on_client_button_pressed() -> void:
	if not _required_data():
		return
	if connection_type == "Steam":
		SteamLobby.join_game(lobbyinput.text.to_int())
	else:
		LANLobby.join_game(ipinput.text, portinput.text.to_int())
	disable_buttons(true)


func _on_join_requested(_lobby_id: int, _friend_id: int) -> void:
	if not _required_data():
		return
	lobbyinput.text = str(_lobby_id)
	disable_buttons(true)
	SteamLobby.join_game(_lobby_id)


func _on_start_game_button_pressed() -> void:
	if game_scene:
		LANLobby.start_game(game_scene.resource_path)
	else:
		statuslabel.text = "Status: Game scene not set"


func disable_buttons(status = false):
	serverbutton.disabled = status
	clientbutton.disabled = status

	#func _on_joined_game(peer_id, player_info):
	#Lobby.debug_log("joining game: "+str(player_info)+" ("+str(peer_id)+")")
	##Lobby.game_start.connect(_on_game_started)

	#func _on_game_started():
	#LANLobby.load_game(game_scene.resource_path)


func _on_server_disconnected():
	%GameManager.swap_scene_to_file("res://scenes/main_menu.tscn")


func _required_data() -> bool:
	statuslabel.text = "Status: "
	var result = true
	if not playername.text:
		statuslabel.text += "Name required "
		result = false
	if result:
		statuslabel.text += "Waiting "
		LANLobby.player_info["name"] = playername.text
		LANLobby.player_info["color"] = player_color_picker.color
	return result


func _on_overlay_button_pressed() -> void:
	Steam.activateGameOverlay()


func _on_invite_button_pressed() -> void:
	Steam.activateGameOverlayInviteDialog(SteamLobby.lobby_id)
