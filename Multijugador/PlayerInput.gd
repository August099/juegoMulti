extends MultiplayerSynchronizer


# Get properties from multiplayer node
@onready var multiplayer_node = get_node("/root/Multiplayer")

@onready var player = $".."

# Continuous input (synced every tick)
@export var move_direction: Vector2 = Vector2.ZERO

func _ready():
	# Only collect input for the local player
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_physics_process(get_multiplayer_authority() == multiplayer.get_unique_id())

func _physics_process(_delta):
	move_direction = Input.get_vector(
		"MoveLeft",
		"MoveRight",
		"MoveUp",
		"MoveDown"
	)
	

func _process(_delta):
		
	if Input.is_action_pressed("Attack"):
		var mouse_position = player.get_global_mouse_position()
		var direction_vector = mouse_position.direction_to(player.global_position)
		attack.rpc(true, direction_vector)
		
	if Input.is_action_just_released("Attack"):
		attack.rpc(false)
		
		
@rpc('call_local')
func attack(state, dir = Vector2(0,0)):
	if multiplayer.is_server():
		player.attacking = state
		player.attacking_dir = dir
	
