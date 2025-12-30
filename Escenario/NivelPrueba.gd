extends Node2D

@onready var multiplayer_node = get_node("/root/Multiplayer")
@onready var game_state = multiplayer_node.game_state

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
	game_state = multiplayer_node.game_state
	
	print("changed gamestate from level:", game_state)


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
	
	print("player id added to match: ", id, "current game state: ", game_state)
	if game_state == GameState.LOBBY:
		$Players.add_child(character, true)


func del_player(id: int):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()
