extends CharacterBody2D

var moving = false
var speed = 2000
var maxSpeed = 15000
var friction = 0.2

func _ready():
	pass



func _process(delta):
	var frictionX = true
	var frictionY = true
	
	if Input.is_action_pressed("MoveRight"):
		velocity.x = min(velocity.x + speed * delta, maxSpeed * delta)
		frictionX = false
	if Input.is_action_pressed("MoveUp"):
		velocity.y = max(velocity.y - speed * delta, -maxSpeed * delta)
		frictionY = false
	if Input.is_action_pressed("MoveLeft"):
		velocity.x = max(velocity.x - speed * delta, -maxSpeed * delta)
		frictionX = false
	if Input.is_action_pressed("MoveDown"):
		velocity.y = min(velocity.y + speed * delta, maxSpeed * delta)
		frictionY = false
		
	if frictionX:
		velocity.x = lerp(velocity.x, 0.0, friction)
	if frictionY:
		velocity.y = lerp(velocity.y, 0.0, friction)
	
	move_and_slide()
