extends Node2D

# Get properties from multiplayer node
@onready var multiplayer_node = get_node("/root/Multiplayer")

# Game states
enum GameState{MENU, LOBBY, IN_GAME}

func _ready():
	
	# We only need to spawn players on the server.
	if multiplayer.is_server():
		
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(del_player)

		# Spawn already connected players
		for id in multiplayer.get_peers():
			add_player(id)
			
		# Spawn the local player unless this is a dedicated server export.
		if not OS.has_feature("dedicated_server"):
			add_player(1)
			
		multiplayer_node.game_state = GameState.IN_GAME
	
	await wait_for_multiple_players()
	set_fow()


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



###############
# NIEBLA DE GUERRA
###############

func set_fow():
	
	var team = multiplayer_node.players[multiplayer.get_unique_id()]["team"]
	
	print("Player: ", multiplayer.get_unique_id(), " TEAM: ", team, " Children: ", $Players.get_children())
	
	for id in multiplayer_node.players:
		if multiplayer_node.players[id].team != team:
			var enemy = $Players.get_node(str(id))
			var light = enemy.get_node("Vision")
			
			light.enabled = false
			
			print("Changed Player: ", id, " with light set to ", light.enabled)
			
			var sprite = enemy.get_node("Sprite2D")
			
			var mat = CanvasItemMaterial.new()
			mat.light_mode = CanvasItemMaterial.LIGHT_MODE_LIGHT_ONLY
			
			sprite.material = mat

func wait_for_multiple_players() -> void:
	while $Players.get_child_count() < multiplayer_node.players.size():
		await $Players.child_entered_tree
