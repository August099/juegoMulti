extends Node2D

@export var noise_height_text: NoiseTexture2D
@export var noise_tree_text: NoiseTexture2D

@onready var tile_map = $TileMap

var noise: Noise
var tree_noise: Noise

#layers
var decoration_layer = 0
var ground_layer = 1
var back_side_decoration_layer = 2
var water_layer = 3

var water_atlas_id = 5
var water_atlas = Vector2(0, 0)

var water_foam_atlas_id = 6
var water_foam_atlas = Vector2(0, 0)

var tree_atlas_id = 9
var tree_atlas = Vector2(0, 0)

var grass_tiles_arr = []
var terrain_grass_id = 0

var width: int = 200
var height: int = 200

# Called when the node enters the scene tree for the first time.
func _ready():
	noise = noise_height_text.noise
	noise.seed = randi()
	tree_noise = noise_tree_text.noise
	generate_world()

func generate_world():
	for x in range(-width/2.0, width/2.0):
		for y in range(-height/2.0, height/2.0):
			var noise_value = noise.get_noise_2d(x, y)
			var tree_noise_value = tree_noise.get_noise_2d(x, y)
			
			if noise_value >= 0.0:
				if noise_value >= 0.05 && tree_noise_value >= 0.8:
					tile_map.set_cell(decoration_layer, Vector2(x, y), tree_atlas_id, tree_atlas)
				
				grass_tiles_arr.append(Vector2i(x, y))
			elif noise_value < 0.0:
				tile_map.set_cell(water_layer, Vector2(x, y), water_atlas_id, water_atlas)
	
	tile_map.set_cells_terrain_connect(ground_layer, grass_tiles_arr, terrain_grass_id, 0)
