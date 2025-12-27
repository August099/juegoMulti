extends Node

const IP_ADRESS: String= "localHost"
const PORT: int = 42069

var peer: ENetMultiplayerPeer

func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	
	
func start_client() -> void:
	peer = ENetMultiplayerPeer.new()
	
	peer.create_client(IP_ADRESS, PORT)
	multiplayer.multiplayer_peer = peer
