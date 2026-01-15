extends CharacterBody2D

var moving = false
var speed = 20000 #2000
var maxSpeed = 150000 #15000
var friction = 0.2

@onready var camera = $Camera2D

# Animations
@onready var AnimatedSprite = $AnimatedSprite2D
var last_facing_dir

# Get properties from multiplayer node
@onready var multiplayer_node = get_node("/root/Multiplayer")

func _ready():
	# Set the camera as current if we are this player.
	if player == multiplayer.get_unique_id():
		$Camera2D.make_current()
		
	# Si no es visible no lo proceso
	set_process(false)
		

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
	
	play_animation(dir)
	
	move_and_slide()

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
