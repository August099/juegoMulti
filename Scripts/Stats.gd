class_name Stats
extends Resource

signal health_depleted
signal stat_changed(stat, change)

@export var base_max_health: int = 100
@export var base_attack_speed: float = 1
@export var base_damage: int = 10
@export var base_movement_speed: float = 1

enum stats{HEALTH, MAX_HEALTH, DAMAGE, ATTACK_SPEED, MOVEMENT_SPEED}

var health

var max_health: int
var attack_speed: float
var damage: int
var movement_speed: float

func _init():
	resource_local_to_scene = true
	stat_changed.connect(_on_stat_changed)
	health_depleted.connect(_on_health_depleted)
	setup_stats()


func setup_stats():
	on_spawn_stats()
	
func on_spawn_stats():
	max_health = base_max_health*1
	attack_speed = base_attack_speed*1
	damage = base_damage*1
	movement_speed = base_movement_speed*1
	
	health = max_health


func _on_health_depleted():
	print('ME MORIIIIII')


func _on_stat_changed(stat, change):
	match stat:
		stats.HEALTH: health = change
		stats.MAX_HEALTH: max_health = change
		stats.DAMAGE: damage = change
		stats.ATTACK_SPEED: attack_speed = change
		stats.MOVEMENT_SPEED: movement_speed = change
	
	health = clamp(health, 0, max_health)
	if health <= 0:
		health_depleted.emit()
