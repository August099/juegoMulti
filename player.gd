extends CharacterBody2D

var speed = 100
var maxSpeed = 100

func _ready():
	pass



func _process(delta):
	if Input.is_action_pressed("MoveRight"):
		velocity.x = min(velocity.x + speed * delta, maxSpeed * delta) 
	if Input.is_action_pressed("MoveUp"):
		velocity.y = max(velocity.y - speed * delta, -maxSpeed * delta) 
	if Input.is_action_pressed("MoveLeft"):
		velocity.x = max(velocity.x - speed * delta, -maxSpeed * delta) 
	if Input.is_action_pressed("MoveDown"):
		velocity.y = min(velocity.y + speed * delta, maxSpeed * delta) 
