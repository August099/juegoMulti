extends Control

@onready var sync := $MultiplayerSynchronizer

# This dictionary is automatically synced
@export var players := {}  # peer_id -> { name, team }

func _ready():
	# Server is authoritative
	sync.set_multiplayer_authority(1)

	update_ui()
	

func add_player(peer_id: int, player_name: String):
	if players.has(peer_id):
		return

	players[peer_id] = {
		"name": player_name,
		"team": assign_team()
	}

	update_ui()
	

func assign_team() -> int:
	var t1 := 0
	var t2 := 0

	for p in players.values():
		if p.team == 1:
			t1 += 1
		else:
			t2 += 1

	return 1 if t1 <= t2 else 2


func update_ui():
	if !is_inside_tree():
		return

	for c in $Team1List.get_children():
		c.queue_free()
	for c in $Team2List.get_children():
		c.queue_free()

	for p in players.values():
		var label := Label.new()
		label.text = p.name
		if p.team == 1:
			$Team1List.add_child(label)
		else:
			$Team2List.add_child(label)


func _on_start_pressed():
	if !multiplayer.is_server():
		return

	get_node("/root/Multiplayer").start_game()
