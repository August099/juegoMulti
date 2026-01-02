extends Node2D

# Get properties from multiplayer node
@onready var multiplayer_node = get_node("/root/Multiplayer")
@onready var players = multiplayer_node.players

# Game states
enum GameState{MENU, LOBBY, IN_GAME}

var world_seed
var clients_ready_for_game = {}

var first_tab = true

func _ready():
	# Lockeo todo hasta que los jugadores tengan todo cargado
	$PantallaCarga.visible = false
	multiplayer_node.movement_unlocked = true
	# Cambio todos los estados de ready por no, para usarlo en el contexto
	# de carga de mapa y no de lobby
	for id in players:
		multiplayer_node.players[id].ready = false
	
	# We only need to spawn players on the server.
	if multiplayer.is_server():
		
		# Agregar a los jugadores
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(del_player)

		for id in multiplayer.get_peers():
			add_player(id)
			
		# Spawn the local player unless this is a dedicated server export.
		if not OS.has_feature("dedicated_server"):
			add_player(1)
			
		# Cambio el estado del juego
		multiplayer_node.game_state = GameState.IN_GAME
		
		# Actualizo la pantalla de carga
		actualizar_carga()
		
		await wait_clients()
		
		# Generacion del mundo
		world_seed = randi()
		
		# Envio a los clientes a que generen el mundo y despues empieza el server a generarlo
		#rpc("receive_world_seed", world_seed, multiplayer_node.players)
		#_spawn_world()
		
	else :
		# El cliente ya esta listo para recibir informacion
		rpc_id(1, "client_ready_for_game")
		
		# Actualizo datos en los clientes
		multiplayer_node.game_state = GameState.IN_GAME
		actualizar_carga()
	
	# Despues de que todos se unieron seteo la niebla de guerra para cada equipo
	await wait_for_multiple_players()
	set_fow()
	# Empiezo a medir el ping
	if multiplayer.is_server():
		update_ping_loop()
	
	await every_map_loaded()
	
	
	
	

func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)

####################
# AGREGAR JUGADORES AL NIVEL
####################

func add_player(id: int):
	var character = preload("res://Escenario/player.tscn").instantiate()
	# Set player id.
	character.player = id
	character.name = str(id)
	
	if multiplayer_node.game_state == GameState.LOBBY:
		# Agrego la escena del jugador
		$Players.add_child(character, true)
		
		# Obtengo el nodo del jugador
		var player = $Players.get_node(str(id))
		
		# Aleatorizo la posicion donde spawnea
		player.position = set_spawn_point(id)
		

func del_player(id: int):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()
	
	
func set_spawn_point(id: int):
	var team = players[id]["team"]
	
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
	
	# Veo el equipo del jugador
	var team = players[multiplayer.get_unique_id()]["team"]
	
	# Si otro jugador no esta en su equipo elimina la luz que emite el jugador
	# y los esconde detras de las sombras
	for id in players:
		var player = $Players.get_node(str(id))
		
		if players[id].team != team:
			
			# Escondo la luz que emite
			player.get_node("Vision").enabled = false
			
			# Tambien escondo el nombre y la vida
			player.get_node("Stats").visible = false
			
			# Creo un material visible unicamente con luz
			var mat = CanvasItemMaterial.new()
			mat.light_mode = CanvasItemMaterial.LIGHT_MODE_LIGHT_ONLY
			
			# Agrego el material al sprite
			player.get_node("Sprite2D").material = mat
		
		# Si el jugador si esta en su equipo
		else:
			
			# Agrego su nombre
			player.get_node("Stats").get_node("PlayerName").text = players[id]["name"]
			

func wait_for_multiple_players() -> void:
	while $Players.get_child_count() < players.size():
		await $Players.child_entered_tree


#####################################
# GENERACION DEL MUNDO
#####################################

func _spawn_world():
	
	var world_scene := preload("res://Escenario/world_generation.tscn")
	var world = world_scene.instantiate()
	
	world.world_seed = world_seed

	add_child(world)
	

@rpc("any_peer", "reliable")
func receive_world_seed(seed: int, players: Dictionary):
	world_seed = seed
	multiplayer_node.players = players
	
	_spawn_world()


#####################################
# PANTALLA DE CARGA
#####################################

################## Esto es porque tengo que esperar a que todos los clientes ejecuten _ready()
@rpc("any_peer", "reliable")
func client_ready_for_game():
	var client_id = multiplayer.get_remote_sender_id()
	clients_ready_for_game[client_id] = true

# El servidor espera a que todos los clientes confirmen
func wait_clients():
	if not multiplayer.is_server():
		return
	
	var expected_clients = multiplayer.get_peers()
	
	while clients_ready_for_game.size() < expected_clients.size():
		await get_tree().process_frame


#########################
###### Estas funciones son para ver si los jugadores ya generaron el mapa
###########################

func player_ready():
	if not multiplayer.has_multiplayer_peer():
		return
	
	var id = multiplayer.get_unique_id()
		
	# Call server to update ready state
	if multiplayer.is_server():
		set_player_ready(id, true)
		actualizar_carga()
	else:
		rpc_id(1, "set_player_ready_request", id, true)
		

# Client request to server
@rpc("any_peer", "reliable")
func set_player_ready_request(player_id: int, is_ready: bool):
	if multiplayer.is_server():
		set_player_ready(player_id, is_ready)


# Server function to set player ready state
func set_player_ready(player_id: int, is_ready: bool):
	
	if not multiplayer.is_server():
		return
	
	if multiplayer_node.players.has(player_id):
		multiplayer_node.players[player_id]["ready"] = is_ready
		rpc("update_players_replica", multiplayer_node.players)

@rpc("authority", "call_local", "reliable")
func update_players_replica(replica: Dictionary):
	
	if !multiplayer_node.movement_unlocked:
		multiplayer_node.players = replica.duplicate(true)
		actualizar_carga()
		return
	
	# Solo actualizo el tab si la partida ya esta cargada y si el menu es visible
	if (multiplayer_node.movement_unlocked and multiplayer_node.get_node("TabMenu").visible) or first_tab:
		multiplayer_node.players = replica.duplicate(true)
		update_tab()
		return


# Check if all players are ready
func every_map_loaded():
	
	while true:
		var all_ready = true
		
		# Verifica si todos tienen ready=true
		for player_data in multiplayer_node.players.values():
			if not player_data.get("ready", false):
				all_ready = false
				break
		
		# Si todos están listos, sale del loop
		if all_ready:
			break
			
		await get_tree().process_frame
	
	print("TODOS ESTAN LISTOS: ", multiplayer.get_unique_id() ,multiplayer_node.players)
	
	# Cuando todos estan listos saco la pantalla de carga y habilito el movimiento de las entidades
	$PantallaCarga.visible = false
	multiplayer_node.movement_unlocked = true
	
	
func actualizar_carga():
	
	var listos = $PantallaCarga/Control/PanelContainer/MarginContainer/VBoxContainer/Listos
	
	var players_list = multiplayer_node.players
	
	var num_players = players_list.size()
	var count: int = 0
	for id in players_list:
		if players_list[id].ready:
			count += 1
	
	listos.text = "Jugadores listos: " + str(count) + "/" + str(num_players)


################################
# MEDIR PING
###############################

func update_ping_loop() -> void:
	
	if multiplayer_node.game_state != GameState.IN_GAME:
		return
	
	while true:
		await get_tree().create_timer(2.0).timeout
		for id in players.keys():
			if id == 1:
				multiplayer_node.players[id]["ping"] = 1
			else:
				var ping = get_player_ping(id)
				multiplayer_node.players[id]["ping"] = ping
		
		rpc("update_players_replica", multiplayer_node.players)
		
		
func get_player_ping(peer_id: int) -> int:
	var peer := multiplayer.multiplayer_peer
	
	if peer.get_peer(peer_id) == null:
		return -1
	
	if (peer is ENetMultiplayerPeer):
		var packet_peer = peer.get_peer(peer_id)
		return packet_peer.get_statistic(
			ENetPacketPeer.PEER_LAST_ROUND_TRIP_TIME
		)
	return -1



func update_tab():
	
	if !is_inside_tree():
		return
	
	var tab1 = multiplayer_node.get_node("TabMenu/Control/PanelContainer/MarginContainer/HBoxContainer/Equipo1/GridContainer")
	var tab2 = multiplayer_node.get_node("TabMenu/Control/PanelContainer/MarginContainer/HBoxContainer/Equipo2/GridContainer")
	
	if first_tab:
		# Limpio el tab
		for label in tab1.get_children():
			tab1.remove_child(label)
			label.free()
		for label in tab2.get_children():
			tab2.remove_child(label)
			label.free()
		
		first_tab = false
	
	# Si el tab ya existe, en vez de borrar todo y volver a crearlo, soloa ctualizo el ping
	if tab1.get_child_count() + tab2.get_child_count() == multiplayer_node.players.size()*2:
		for player_id in multiplayer_node.players:
			if tab1.get_node(str(player_id)) != null:
				tab1.get_node(str(player_id)).text = str(multiplayer_node.players[player_id].ping) + "ms"
			
			if tab2.get_node(str(player_id)) != null:
				tab2.get_node(str(player_id)).text = str(multiplayer_node.players[player_id].ping) + "ms"
				
		return

	for player_id in multiplayer_node.players:
		var p = multiplayer_node.players[player_id]
		
		# Agrego el jugador al tab
		var tablabel := Label.new()
		
		tablabel.text = p.name
		tablabel.add_theme_font_size_override("font_size", 40)
		tablabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if player_id == multiplayer.get_unique_id():
			tablabel.add_theme_color_override("font_color", Color("00d0ff"))
		
		# Agrego tambien el ping
		var pinglabel := Label.new()
		
		pinglabel.text = str(p.ping) + "ms"
		pinglabel.add_theme_font_size_override("font_size", 40)
		if player_id == multiplayer.get_unique_id():
			pinglabel.add_theme_color_override("font_color", Color("00d0ff"))
			
		# Le agrego nombre al label del ping para cambiarlo y no tener que recrearlo
		pinglabel.name = str(player_id)
		
		if p.team == 1:
			tab1.add_child(tablabel)
			tab1.add_child(pinglabel)
		else:
			tab2.add_child(tablabel)
			tab2.add_child(pinglabel)
