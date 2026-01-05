extends CharacterBody2D

var moving = false
var acceleration = 1500 #2000
var maxSpeed = 3500 #15000
var friction = 5000

@onready var camera = $Camera2D

#func _enter_tree():
#	set_multiplayer_authority(name.to_int())

func _ready():
#		if is_multiplayer_authority():
#			camera.make_current()
	pass

func _physics_process(delta):
#	if !is_multiplayer_authority():
#		return
	pass
	var dir : Vector2 = Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown")
	
	if dir:
		velocity = dir * maxSpeed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	#print(velocity)
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
