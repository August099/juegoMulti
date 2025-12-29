# multiplayer.gd
extends Node

const PORT = 4433

signal player_connected(_peerID: int)
signal player_disconnected(_peerID: int)
signal server_disconnected()

func _ready():
	# Start paused.
	get_tree().paused = true
	# You can save bandwidth by disabling server relay and peer notifications.
	multiplayer.server_relay = false
	
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.server_disconnected.connect(_server_disconnected)

	# Automatically start the server in headless mode.
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server.")
		_on_host_pressed.call_deferred()

#################################
# CONEXIONES
#################################

# Abro el puerto
func setup_upnp(port: int):
	var upnp := UPNP.new()
	var result = upnp.discover()
	if result == UPNP.UPNP_RESULT_SUCCESS:
		upnp.add_port_mapping(port)
		print("UPnP port opened:", port)
	else:
		print("UPnP failed:", result)


func _on_host_pressed():
	# Abro el puerto
	setup_upnp(PORT)
	
	# Start as server
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server")
		return
	multiplayer.multiplayer_peer = peer
	
	go_lobby()

func _on_join_pressed():
	# Start as client
	var txt : String = $UI/Net/Options/IP.text
	if txt == "":
		OS.alert("Need a remote to connect to.")
		return
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(txt, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client")
		return
	multiplayer.multiplayer_peer = peer
	
	go_lobby()
	
	

# ======================
# LOBBY
# ======================

var lobbyScene: Node = null


func go_lobby():
	
	$UI.hide()
	get_tree().paused = false
	
	# Only change level on the server.
	# Clients will instantiate the level via the spawner.
	# Configure the spawner
	$LobbySpawner.spawn_function = _spawn_lobby_callback
	
	# Server spawns the lobby
	if multiplayer.is_server():
		$LobbySpawner.spawn([multiplayer.get_unique_id()])
	
	await wait_for_connection()
	print("connection waited")	
	print($Lobby.get_child_count())
	await wait_for_lobby()
	print("lobby waited")
	
	lobbyScene = $Lobby.get_child(0) if $Lobby.get_child_count() > 0 else null
	
	if lobbyScene:
		send_player_name($UI/Net/Options/PlayerName.text)
	
	

func wait_for_lobby() -> void:
	while $Lobby.get_child_count() == 0:
		await get_tree().process_frame

func wait_for_connection() -> void:
	while multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		await get_tree().process_frame
		

@rpc("any_peer")
func change_lobby(scene_path: String):
	var lobby := $Lobby
	for c in lobby.get_children():
		c.queue_free()
	lobby.add_child(load(scene_path).instantiate())
	
	print("lobby changed")
	
func _spawn_lobby_callback(_data: Array):
	
	# Check if lobby already exists
	if $Lobby.get_child_count() > 0:
		# Lobby already exists, return the existing one
		return $Lobby.get_child(0)
	
	var lobby_instance = load("res://Multijugador/lobby.tscn").instantiate()
	lobby_instance.name = "LobbyScene"
	$Lobby.add_child(lobby_instance, true)
	return lobby_instance



# Guardo el nombre del jugador
func send_player_name(playerName: String):
	if multiplayer.is_server():
		var id := multiplayer.get_unique_id()
		lobbyScene.add_player(id, playerName)
	else:
		rpc_id(1, "register_player", playerName)
		
	print("sent playername:", playerName)
	
@rpc("any_peer")
func register_player(playerName: String):
	var id := multiplayer.get_remote_sender_id()
	if lobbyScene:
		lobbyScene.add_player(id, playerName)

# ======================
# GAME START
# ======================

@rpc("authority")
func start_game():
	change_level("res://Escenario/NivelPrueba.tscn")

func change_level(scene: String):
	lobbyScene.hide()
	
	var level := $Level
	for c in level.get_children():
		c.queue_free()
	level.add_child(load(scene).instantiate())
	
	print("level changed")

# ======================
# DESCONEXION
# ======================

func _player_disconnected(peer_id: int):
	print("Peer disconnected:", peer_id)

	if lobbyScene:
		lobbyScene.remove_player(peer_id)

func _server_disconnected():
	print("Server disconnected")

	_cleanup_and_return_to_menu()
	
func _cleanup_and_return_to_menu():
	# Clear lobby
	if lobbyScene:
		lobbyScene.queue_free()
		lobbyScene = null

	# Close peer if still open
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()

	get_tree().paused = true
	get_tree().change_scene_to_file("res://Multijugador/Escena_Multijugador.tscn")
