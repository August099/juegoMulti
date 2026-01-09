extends CharacterBody2D

var moving = false
var speed = 2000 #2000
var maxSpeed = 15000 #15000
var friction = 0.2

@onready var camera = $Camera2D

# Animations
@onready var AnimatedSprite = $AnimatedSprite2D
var last_facing_dir: Vector2
var WeaponDefaultPosition: Vector2
var WeaponDefaultRotation: float
var attacking = false

@onready var AnimatedWeapon = $AnimatedWeapon
@export var weapon: String = 'Hand'


# Get properties from multiplayer node
@onready var multiplayer_node = get_node("/root/Multiplayer")

func _ready():
	# Set the camera as current if we are this player.
	if player == multiplayer.get_unique_id():
		$Camera2D.make_current()
		
	WeaponDefaultPosition = AnimatedWeapon.position
	WeaponDefaultRotation = AnimatedWeapon.rotation
	AnimatedWeapon.play(weapon + "Idle")
	AnimatedWeapon.animation_finished.connect(_on_animated_weapon_animation_finished)
	
	
		

# Set by the authority, synchronized on spawn
@export var player := 1:
	set(id):
		player = id
		# Give authority over input to the owning peer
		$PlayerInput.set_multiplayer_authority(id)

@onready var input := $PlayerInput

func _physics_process(delta):
	#if !is_multiplayer_authority():
	#	return
		
	#if not multiplayer_node.movement_unlocked:
	#	return

	var dir : Vector2 = input.move_direction
	var friction_x := true
	var friction_y := true
	
	if dir.x != 0:
		velocity.x = clamp(
			velocity.x + dir.x * speed * delta,
			-maxSpeed * delta,
			maxSpeed * delta
		)
		friction_x = false

	if dir.y != 0:
		velocity.y = clamp(
			velocity.y + dir.y * speed * delta,
			-maxSpeed * delta,
			maxSpeed * delta
		)
		friction_y = false

	if friction_x:
		velocity.x = lerp(velocity.x, 0.0, friction)
	if friction_y:
		velocity.y = lerp(velocity.y, 0.0, friction)
	
	move_and_slide()
	
	play_animation(dir)

func _input(event):
	if Input.is_action_just_pressed('ZoomIn'):
		var zoom_value = camera.zoom.x + 0.2
		camera.zoom = Vector2(zoom_value, zoom_value)
	if Input.is_action_just_pressed('ZoomOut'):
		var zoom_value = camera.zoom.x - 0.2
		camera.zoom = Vector2(zoom_value, zoom_value)
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()


#################
# ANIMACIONES
#################

func play_animation(dir: Vector2):
	var anim
	
	if last_facing_dir == null:
		last_facing_dir = Vector2(1,0)
	
	if dir.x == 0 and dir.y == 0:
		if last_facing_dir.x > 0:
			anim = "IdleRight"
		else:
			anim = "IdleLeft"
	
	else:
		anim = "Walk"
		if abs(dir.x) > abs(dir.y):
			if dir.x > 0:
				anim += "Right"
			else:
				anim += "Left"
		else:
			if dir.y > 0:
				anim += "Front"
			else:
				anim += "Back"
	
	if AnimatedSprite.animation != anim:
		if abs(dir.x) > 0:
			last_facing_dir = dir
		AnimatedSprite.play(anim)

##############################
# ATAQUES
##############################
func _unhandled_input(event):
	
	if multiplayer_node.game_state != multiplayer_node.GameState.IN_GAME:
		return
		

	if event.is_action_pressed("Attack"):
		var mouse_position = get_global_mouse_position()
		var direction_vector = mouse_position.direction_to(global_position)
		rpc('attack_animation', multiplayer.get_unique_id(), direction_vector)
		
	if event.is_action_released("Attack"):
		attacking = false
		



func _on_animated_weapon_animation_finished():
	if AnimatedWeapon.animation.contains("Idle"):
		return
	
	if attacking:
		var mouse_position = get_global_mouse_position()
		var direction_vector = mouse_position.direction_to(global_position)
		rpc('attack_animation', multiplayer.get_unique_id(), direction_vector)
		return
	
	rpc('play_idle', multiplayer.get_unique_id())


@rpc("any_peer", "call_local", "reliable")
func attack_animation(player_id, direction_vector):
	
	if player != player_id:
		return
	
	attacking = true
	
	var normalized_vector = direction_vector.normalized()
	
	var rotation_angle = direction_vector.angle()
	
	AnimatedWeapon.rotation = WeaponDefaultRotation + 270*PI/180 + rotation_angle
	AnimatedWeapon.position = WeaponDefaultPosition - normalized_vector*50
	
	var degrees = AnimatedWeapon.rotation_degrees
	
	if degrees > 360:
		degrees -= 360
	elif degrees < 0:
		degrees +=360
		
	if degrees > 180:
		AnimatedWeapon.flip_h = true
	else:
		AnimatedWeapon.flip_h = false
	
	AnimatedWeapon.play(weapon + "Attack")

@rpc("any_peer", "call_local", "reliable")
func play_idle(player_id):
	if player != player_id:
		return
	
	AnimatedWeapon.play(weapon + "Idle")
	AnimatedWeapon.position = WeaponDefaultPosition
	AnimatedWeapon.rotation = WeaponDefaultRotation
	AnimatedWeapon.flip_h = false
