extends CharacterBody2D

var moving = false
var speed = 300 #2000
var maxSpeed = 500 #15000
var friction = 0.2

@onready var camera = $Camera2D

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
		if is_multiplayer_authority():
			camera.make_current()

func _physics_process(delta):
	if !is_multiplayer_authority():
		return

	var dir : Vector2 = Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown")
	
	if dir:
		velocity = dir * speed
	else:
		velocity = Vector2(0, 0)
	
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
