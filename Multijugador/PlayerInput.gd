extends MultiplayerSynchronizer

# Continuous input (synced every tick)
@export var move_direction: Vector2 = Vector2.ZERO

func _ready():
	# Only collect input for the local player
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())

func _process(_delta):
	move_direction = Input.get_vector(
		"MoveLeft",
		"MoveRight",
		"MoveUp",
		"MoveDown"
	)
