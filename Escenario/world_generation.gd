extends Node2D

@export var noise_temperature_text: NoiseTexture2D
@export var noise_moisture_text: NoiseTexture2D

@onready var tile_map = $TileMap

var temperature_noise: Noise
var moisture_noise: Noise

#layers
var decoration_layer = 0
var ground_layer = 1
var back_side_decoration_layer = 2
var water_layer = 3

#atlas
var water_atlas_id = 5
var water_foam_atlas_id = 6
var tree_atlas_id = 9
#terrain
var terrain_grass_color_0 = 0
var terrain_grass_color_1 = 1
var terrain_grass_color_2 = 2
var terrain_grass_color_3 = 3
var terrain_grass_color_4 = 4

#world size
var width: int = 200
var height: int = 200

# la dificultad del bioma se aplica segun lo cercano que este a la estructura del boss
var biome = {}

func _ready():
	temperature_noise = noise_temperature_text.noise
	moisture_noise = noise_moisture_text.noise
	
	temperature_noise.seed = randi()
	moisture_noise.seed = randi()
	
	print(temperature_noise.seed)
	print(moisture_noise.seed)
	
	generate_world()

func generate_world():
	var grass_tiles = {
		"color_0": [],
		"color_1": [],
		"color_2": [],
		"color_3": [],
		"color_4": []
	}
	
	for x in range(-width/2.0, width/2.0):
		for y in range(-height/2.0, height/2.0):
			var pos = Vector2(x, y)
			var temperature_noise_value = (temperature_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var moisture_noise_value = (moisture_noise.get_noise_2d(x, y) + 1.0) * 0.5
			
			if (between(temperature_noise_value, 0, 0.35) && between(moisture_noise_value, 0, 0.55)) || (between(temperature_noise_value, 0.35, 0.6) && between(moisture_noise_value, 0.55, 0.75)):
				grass_tiles.color_0.append(pos)
			if between(temperature_noise_value, 0.35, 0.6) && between(moisture_noise_value, 0, 0.55):
				grass_tiles.color_1.append(pos)
			if between(temperature_noise_value, 0.6, 1) && between(moisture_noise_value, 0, 0.75):
				grass_tiles.color_2.append(pos)
			if between(temperature_noise_value, 0, 0.35) && between(moisture_noise_value, 0.55, 1):
				grass_tiles.color_3.append(pos)
			if between(temperature_noise_value, 0.35, 1) && between(moisture_noise_value, 0.75, 1):
				grass_tiles.color_4.append(pos)
	
	
	tile_map.set_cells_terrain_connect(ground_layer, grass_tiles.color_0, terrain_grass_color_0, 0)
	tile_map.set_cells_terrain_connect(ground_layer, grass_tiles.color_1, terrain_grass_color_1, 0)
	tile_map.set_cells_terrain_connect(ground_layer, grass_tiles.color_2, terrain_grass_color_2, 0)
	tile_map.set_cells_terrain_connect(ground_layer, grass_tiles.color_3, terrain_grass_color_3, 0)
	tile_map.set_cells_terrain_connect(ground_layer, grass_tiles.color_4, terrain_grass_color_4, 0)

func between(val, min, max):
	if val >= min && val < max:
		return true
	return false

#var noise_temp_val_arr = []
#var noise_moi_val_arr = []

#noise_temp_val_arr.append(temperature_noise_value)
#noise_moi_val_arr.append(moisture_noise_value)

#print(noise_temp_val_arr.max())
#print(noise_temp_val_arr.min())

#print(noise_moi_val_arr.max())
#print(noise_moi_val_arr.min())
