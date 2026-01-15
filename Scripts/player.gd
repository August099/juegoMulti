extends CharacterBody2D

var moving = false
var speed = 5000 #2000
var maxSpeed = 50000 #15000
var friction = 0.2

@onready var camera = $Camera2D

# Animations
@onready var AnimatedSprite = $AnimatedSprite2D
var move_dir: Vector2
var last_facing_dir: Vector2

var WeaponDefaultPosition: Vector2
var WeaponDefaultRotation: float
var attacking = false
var attacking_dir = Vector2(0,0)

# Combat
@onready var WeaponSprite = $WeaponSprite
@onready var WeaponAnimation = $WeaponAnimation
@export var weapon: String = 'Hand'


# Get properties from multiplayer node
@onready var multiplayer_node = get_node("/root/Multiplayer")

# Stats
@export var stats : Stats

# Set by the authority, synchronized on spawn
@export var player := 1:
	set(id): 
		player = id
		# Give authority over input to the owning peer
		%PlayerInput.set_multiplayer_authority(id)

func _ready():
	# Set the camera as current if we are this player.
	if player == multiplayer.get_unique_id():
		$Camera2D.make_current()
	
	print("STATS: ", stats.health, ' ', stats.damage)
	
	WeaponDefaultPosition = WeaponSprite.position
	WeaponDefaultRotation = WeaponSprite.rotation
	AnimatedSprite.play("IdleRight")
	WeaponAnimation.play(weapon + "Idle")
	WeaponSprite.animation_finished.connect(_on_weapon_animation_animation_finished)
	
	
func _physics_process(delta):
	
	#if not multiplayer_node.movement_unlocked:
	#	return
	
	if multiplayer.is_server():
		_apply_movement_from_input(delta)
		
	play_animations()


func _apply_movement_from_input(delta):
	move_dir = %PlayerInput.move_direction
	var friction_x := true
	var friction_y := true
	
	if move_dir.x != 0:
		velocity.x = clamp(
			velocity.x + move_dir.x * speed * delta,
			-maxSpeed * delta,
			maxSpeed * delta
		)
		friction_x = false

	if move_dir.y != 0:
		velocity.y = clamp(
			velocity.y + move_dir.y * speed * delta,
			-maxSpeed * delta,
			maxSpeed * delta
		)
		friction_y = false

	if friction_x:
		velocity.x = lerp(velocity.x, 0.0, friction)
	if friction_y:
		velocity.y = lerp(velocity.y, 0.0, friction)
	
	move_and_slide()
	
	play_animation(move_dir)

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

func play_animations():
	move_dir = %PlayerInput.move_direction
	play_animation(move_dir)
	
	if attacking:
		attack_animation(attacking_dir)
	

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

func attack_animation(direction_vector):
	
	var normalized_vector = direction_vector.normalized()
	
	var rotation_angle = direction_vector.angle()
	
	WeaponSprite.rotation = WeaponDefaultRotation + 270*PI/180 + rotation_angle
	WeaponSprite.position = WeaponDefaultPosition - normalized_vector*50
	
	var degrees = WeaponSprite.rotation_degrees
	
	if degrees > 360:
		degrees -= 360
	elif degrees < 0:
		degrees +=360
		
	if degrees > 180:
		WeaponSprite.flip_h = true
	else:
		WeaponSprite.flip_h = false
	
	WeaponAnimation.play(weapon + "Attack")


func _on_weapon_animation_animation_finished(anim_name):
	if anim_name.contains("Idle"):
		return
	
	if attacking:
		return
	else :
		play_idle()

func play_idle():
	WeaponAnimation.play(weapon + "Idle")
	WeaponSprite.position = WeaponDefaultPosition
	WeaponSprite.rotation = WeaponDefaultRotation
	WeaponSprite.flip_h = false
	


###################
# COMBATE
###################

func _on_hit_box_area_entered(area):
	# Es el dueño del nodo?
	if !is_multiplayer_authority():
		return
	
	# Entonces manda una señal para aplicar el daño
	rpc("request_damage", area.owner.player, stats.damage)
	

@rpc("any_peer", "call_local")
func request_damage(target_player_id, dmg):
	# Si es el server...
	if !multiplayer.is_server():
		return
	
	# Agarra el nodo representante del jugador golpeado y le aplica el daño
	var target = multiplayer_node.get_node('Level/NivelPrueba/Players/'+str(target_player_id))
	target.apply_damage(dmg)
	
func apply_damage(dmg):
	# Aplica el daño
	stats.health -= dmg
	# Y manda una señal a todos los jugadores y a si mismo de actualizar la vida
	rpc("sync_health", stats.health)


@rpc("call_local")
func sync_health(new_health):
	
	# Todos los jugadores actualizan la barra de vida del jugador golpeado
	stats.stat_changed.emit(stats.stats.HEALTH, new_health)
	%HealthBar.value = stats.health
