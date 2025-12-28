# multiplayer.gd
extends Node

const PORT = 4433

func _ready():
	# Start paused.
	get_tree().paused = true
	# You can save bandwidth by disabling server relay and peer notifications.
	multiplayer.server_relay = false

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
	if multiplayer.is_server():
		change_lobby.call_deferred("res://Multijugador/lobby.tscn")
	
	await wait_for_connection()
	await wait_for_lobby()
	
	lobbyScene = $Lobby.get_child(0)
	
	send_player_name($UI/Net/Options/PlayerName.text)
	

func wait_for_lobby() -> void:
	while $Lobby.get_child_count() == 0:
		await get_tree().process_frame

func wait_for_connection() -> void:
	while multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		await get_tree().process_frame
		
		
# Guardo el nombre del jugador
func send_player_name(playerName: String):
	if multiplayer.is_server():
		var id := multiplayer.get_unique_id()
		lobbyScene.add_player(id, playerName)
	else:
		rpc_id(1, "register_player", playerName)
	
@rpc("authority")
func register_player(playerName: String):
	var id := multiplayer.get_remote_sender_id()
	lobbyScene.add_player(id, playerName)

@rpc("any_peer")
func change_lobby(scene_path: String):
	var lobby := $Lobby
	for c in lobby.get_children():
		c.queue_free()
	lobby.add_child(load(scene_path).instantiate())

# ======================
# GAME START
# ======================

@rpc("authority")
func start_game():
	change_level(load("res://Escenario/NivelPrueba.tscn"))

func change_level(scene: PackedScene):
	lobbyScene.hide()
	
	var level := $Level
	for c in level.get_children():
		c.queue_free()
	level.add_child(scene.instantiate())

