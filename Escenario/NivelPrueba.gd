extends Node2D

# Get properties from multiplayer node
@onready var multiplayer_node = get_node("/root/Multiplayer")

# Game states
enum GameState{MENU, LOBBY, IN_GAME}

func _ready():
	
	# We only need to spawn players on the server.
	if not multiplayer.is_server():
		return
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)

	# Spawn already connected players
	for id in multiplayer.get_peers():
		add_player(id)
		
	# Spawn the local player unless this is a dedicated server export.
	if not OS.has_feature("dedicated_server"):
		add_player(1)
		
	multiplayer_node.game_state = GameState.IN_GAME


func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)


func add_player(id: int):
	var character = preload("res://Escenario/player.tscn").instantiate()
	# Set player id.
	character.player = id
	character.name = str(id)
	
	if multiplayer_node.game_state == GameState.LOBBY:
		$Players.add_child(character, true)
		
		var player = $Players.get_node(str(id))
		
		player.position = set_spawn_point(id)


func del_player(id: int):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()
	
	
func set_spawn_point(id: int):
	var team = multiplayer_node.players[id]["team"]
	
	var rand_spawn = Vector2(randf_range(-2, 2), randf_range(-2, 2))
	
	if team == 1:
		position = $Spawn1.position + rand_spawn
	else:
		position = $Spawn2.position + rand_spawn
		
	return position
