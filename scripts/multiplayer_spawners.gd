extends MultiplayerSpawner

@export var network_player: PackedScene

var player: Player

func spawn_player(id: int, index: int):
	if not multiplayer.is_server(): return
	player = network_player.instantiate()
	player.name = str(id)
	get_node(spawn_path).add_child(player)
	player.set_index.rpc_id(player.name.to_int(), index)
	
