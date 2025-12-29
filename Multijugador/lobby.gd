extends Control

# This dictionary is automatically synced
@export var players := {}  # peer_id -> { name, team, ready }

var _players_replica = {}

func _ready():
	# Server is authoritative
	if multiplayer.is_server():
		set_multiplayer_authority(1)
	
	update_ui()
	
	# Add ready button functionality for this client
	if multiplayer.has_multiplayer_peer():
		var my_id = multiplayer.get_unique_id()
		if players.has(my_id):
			# Check if we're already ready
			if players[my_id].get("ready", false):
				$Ready.text = "NOT READY"
			else:
				$Ready.text = "READY"
	
	# Replicate players dictionary for multiplayer sync
	if multiplayer.is_server():
		# Initialize replica
		_players_replica = players.duplicate(true)
	else:
		# Clients wait for server to send data
		await get_tree().create_timer(0.5).timeout
		update_ui()

########################
# AGREGAR JUGADOR
###########################

func add_player(peer_id: int, player_name: String):
	if players.has(peer_id):
		return

	players[peer_id] = {
		"name": player_name,
		"team": assign_team(),
		"ready": false
	}
	
	# If we're the server, update replica and notify clients
	if multiplayer.is_server():
		_players_replica = players.duplicate(true)
		rpc("update_players_replica", _players_replica)
	
	update_ui()
	check_all_ready()
	

########################
# ASIGNAR EQUIPO
###########################


func assign_team() -> int:
	var t1 := 0
	var t2 := 0

	for p in players.values():
		if p.team == 1:
			t1 += 1
		else:
			t2 += 1

	return 1 if t1 <= t2 else 2
	
		

########################
# ACTUALIZAR EL DICCIONARIO DE JUGADORES
###########################		

@rpc("authority", "call_local", "reliable")
func update_players_replica(replica: Dictionary):
	if not multiplayer.is_server():
		players = replica.duplicate(true)
	update_ui()
	
	# Update ready button text for this client
	if multiplayer.has_multiplayer_peer():
		var my_id = multiplayer.get_unique_id()
		if players.has(my_id):
			if players[my_id].get("ready", false):
				$Ready.text = "NOT READY"
			else:
				$Ready.text = "READY"
	
	check_all_ready()

func _on_ready_pressed():
	if not multiplayer.has_multiplayer_peer():
		return
	
	var my_id = multiplayer.get_unique_id()
	if players.has(my_id):
		# Toggle ready state
		var is_ready = !players[my_id].get("ready", false)
		
		# Call server to update ready state
		if multiplayer.is_server():
			set_player_ready(my_id, is_ready)
		else:
			rpc_id(1, "set_player_ready_request", my_id, is_ready)
			
# Server function to set player ready state
func set_player_ready(player_id: int, is_ready: bool):
	if not multiplayer.is_server():
		return
	
	if players.has(player_id):
		players[player_id]["ready"] = is_ready
		_players_replica = players.duplicate(true)
		rpc("update_players_replica", _players_replica)
		update_ui()
		check_all_ready()

# Client request to server
@rpc("any_peer", "reliable")
func set_player_ready_request(player_id: int, is_ready: bool):
	if multiplayer.is_server():
		set_player_ready(player_id, is_ready)

# Check if all players are ready
func check_all_ready():
	if not multiplayer.is_server():
		return
	
	if players.is_empty():
		return
	
	# Check if all players are ready
	var all_ready = true
	for player_data in players.values():
		if not player_data.get("ready", false):
			all_ready = false
			break
	
	# Enable/disable start button based on ready state
	$Start.disabled = not all_ready
	
	# Optional: Auto-start when all ready
	if all_ready and players.size() >= 2:  # Minimum 2 players
		# You can uncomment this for auto-start
		# await get_tree().create_timer(3.0).timeout  # 3 second delay
		# if all_ready:  # Double check after delay
		#     _on_start_pressed()
		pass

func update_ui():
	print(players)
	
	if !is_inside_tree():
		return

	for c in $Team1/PlayerList.get_children():
		c.queue_free()
	for c in $Team2/PlayerList.get_children():
		c.queue_free()

	for p in players.values():
		# Cuando entra un jugador agrego su nombre en la lsita		
		var label := Label.new()
		label.text = p.name
		
		label.add_theme_font_override("font", load("res://Assets/Font/Alkatra-VariableFont_wght.ttf"))
		
		label.add_theme_font_size_override("font_size", 50)
		label.custom_minimum_size = Vector2(450, 0)
		
		# Agrego ademas un icono de ready o no
		var readyState := TextureRect.new()
		readyState.texture = load("res://Assets/Menu/wait.svg")
		readyState.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		readyState.size_flags_horizontal = Control.SIZE_SHRINK_END
		readyState.size_flags_vertical = Control.SIZE_FILL
		
		if p.team == 1:
			$Team1/PlayerList.add_child(label)
			$Team1/PlayerList.add_child(readyState)
		else:
			$Team2/PlayerList.add_child(label)
			$Team2/PlayerList.add_child(readyState)
	
	# Show/hide start button based on authority
	$Start.visible = multiplayer.is_server()



########################
# EMPEZAR JUEGO
###########################

func _on_start_pressed():
	if !multiplayer.is_server():
		return

	get_node("/root/Multiplayer").start_game()


########################
# DESCONEXION DE JUGADOR
###########################

func remove_player(peer_id: int):
	if players.erase(peer_id):
		if multiplayer.is_server():
			_players_replica = players.duplicate(true)
			rpc("update_players_replica", _players_replica)
		update_ui()
		check_all_ready()


func _on_leave_pressed():
	if multiplayer.is_server():
		# Host leaves → everyone disconnects
		multiplayer.multiplayer_peer.close()
	else:
		# Client leaves → disconnect
		multiplayer.multiplayer_peer.close()
	

