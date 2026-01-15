extends Node2D

@export var noise_temperature_text: NoiseTexture2D
@export var noise_moisture_text: NoiseTexture2D
@export var noise_altitude_text: NoiseTexture2D
@export var noise_island_falloff_text: NoiseTexture2D

@onready var tile_map = $TileMap

@export var world_seed: int = randi()

var temperature_noise: Noise
var moisture_noise: Noise
var altitude_noise: Noise
var island_falloff_noise: Noise

#layers
var decoration_layer = 0
var ground_layer = 1
var back_side_decoration_layer = 2
var water_layer = 3

#atlas
var water_atlas_id = 110
var water_foam_atlas_id = 111
var tree_atlas_id = 20

#world size
var width: float = 500.0
var height: float = 500.0

var center_x = width / 2.0
var center_y = height / 2.0

var island_size := 0.8

# la dificultad del bioma se aplica segun lo cercano que este a la estructura del boss
var biomes = {
	"meadow": {
		"source": 0,
		"atlas": [
			Vector2i(0,0),
			Vector2i(1,0),
			Vector2i(2,0),
			Vector2i(3,0),
			Vector2i(4,0),
			Vector2i(5,0),
			Vector2i(6,0),
			Vector2i(0,1),
			Vector2i(1,1),
			Vector2i(2,1),
			Vector2i(3,1),
			Vector2i(0,2),
			Vector2i(1,2),
			Vector2i(2,2),
			Vector2i(3,2)
		]
	},
	"forest": {
		"source": 1,
		"atlas": [
			Vector2i(0,0),
			Vector2i(1,0),
			Vector2i(2,0),
			Vector2i(3,0),
			Vector2i(4,0),
			Vector2i(5,0),
			Vector2i(0,1),
			Vector2i(1,1),
			Vector2i(2,1),
			Vector2i(3,1),
			Vector2i(0,2),
			Vector2i(1,2),
			Vector2i(2,2),
			Vector2i(3,2)
		]
	}
}

# PARA PROTOTIPAR
@export var multiplayer_options = false

func _ready():
	temperature_noise = noise_temperature_text.noise
	moisture_noise = noise_moisture_text.noise
	altitude_noise = noise_altitude_text.noise
	island_falloff_noise = noise_island_falloff_text.noise
	
	temperature_noise.seed = randi() #world_seed
	moisture_noise.seed = randi() #world_seed + 1
	altitude_noise.seed = randi()
	island_falloff_noise.seed = randi()
	
	print(temperature_noise.seed)
	print(moisture_noise.seed)
	
	
	if multiplayer_options:
		call_deferred("_start_world_generation")
	else:
		generate_world()

func generate_world():
	var grass_tiles = {
		"color_0": [],
		"color_1": [],
		"color_2": [],
		"color_3": [],
		"color_4": []
	}

	var counter := 0

	for x in range(width):
		for y in range(height):
			var pos = Vector2i(x, y)
			var temperature_noise_value = (temperature_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var moisture_noise_value = (moisture_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var altitude_noise_value = (altitude_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var island_falloff_value = (island_falloff_noise.get_noise_2d(x, y) + 1.0) * 0.5

			var dx = min(x, width - x) / (width * 0.5)
			var dy = min(y, height - y) / (height * 0.5)
			var distance = clamp(min(dx, dy), 0.0, 1.0)
			
			if pos == Vector2i(0,250):
				print(pos, " ", distance)

# pow((distance + x) * y + island_falloff_value * z, 3.0)
# x = mueve la funcion en el eje x (puede hacer que 
#     la tierra este mas cerca o mas lejos de los bordes)
# y = indica la fuerza del corte, mas grande es, mas bruzco es el corte
# z = le da forma a los bordes, mientras mas grande el numero, 
#     mas relieve tiene el borde
			var falloff = clamp(pow((distance + 0.08) * 1.8 + island_falloff_value * 0.8, 3.0), 0.0, 1.0)

			if altitude_noise_value < 0.6:
				altitude_noise_value = 0.45 + 0.15 * pow(altitude_noise_value / 0.6, 1.5)

			altitude_noise_value *= falloff

			if altitude_noise_value > 0.5:
				if (between(temperature_noise_value, 0, 0.35) && between(moisture_noise_value, 0, 0.55)) || (between(temperature_noise_value, 0.35, 0.6) && between(moisture_noise_value, 0.55, 0.75)):
					grass_tiles.color_0.append(pos)
				elif between(temperature_noise_value, 0.35, 0.6) && between(moisture_noise_value, 0, 0.55):
					grass_tiles.color_1.append(pos)
				elif between(temperature_noise_value, 0.6, 1) && between(moisture_noise_value, 0, 0.75):
					pass
				elif between(temperature_noise_value, 0, 0.35) && between(moisture_noise_value, 0.55, 1):
					pass
				elif between(temperature_noise_value, 0.35, 1) && between(moisture_noise_value, 0.75, 1):
					pass
			else:
				tile_map.set_cell(water_layer, pos, water_atlas_id, Vector2i(0, 0))
			
			# Si consume muchos recursos para generar lo frena un poco para evitar que
			# el mutijugador se caiga
			counter += 1
			# Usar un valor mas alto hace que se cargue mas rapido el mapa pero haya
			# mayor posibilidad de que se caiga el multi, y viceversa
			if (counter % 100 == 0) and multiplayer_options:
				#print("Almost crashed", counter)
				await get_tree().process_frame
	
	set_biome(biomes.meadow.source, biomes.meadow.atlas, grass_tiles.color_0)
	
	set_biome(biomes.forest.source, biomes.forest.atlas, grass_tiles.color_1)
	
	set_decoration_world()
	
	# Si ya se cargo todo pongo el player en ready
	if multiplayer_options:
		get_parent().player_ready()

func set_decoration_world():
	for x in range(width):
		for y in range(height):
			var pos = Vector2i(x, y)
			
			var cell_data = tile_map.get_cell_tile_data(ground_layer, pos)
			var atlas_coords = tile_map.get_cell_atlas_coords(ground_layer, pos)
			
			if cell_data:
				if atlas_coords != Vector2i(1, 1) :
					tile_map.set_cell(back_side_decoration_layer, pos, water_foam_atlas_id, Vector2i(0, 0))
					tile_map.set_cell(water_layer, pos, water_atlas_id, Vector2i(0, 0))

func between(val, min, max):
	if val >= min && val <= max:
		return true
	return false

func set_biome(source_id: int, tiles_biome, cells):
	switch_tiles_probability(source_id, tiles_biome)
	tile_map.set_cells_terrain_connect(ground_layer, cells, 0, 0)
	switch_tiles_probability(source_id, tiles_biome)

func switch_tiles_probability(source_id: int, tiles_position):
	var source = tile_map.tile_set.get_source(source_id)

	for pos in tiles_position:
		var tile_data = source.get_tile_data(pos, 0)

		if tile_data:
			var tile_probability = tile_data.get_custom_data("probability")

			if tile_data.probability != 0:
				tile_data.probability = 0
			else:
				tile_data.probability = tile_probability

###############################
# ESTO EVITA QUE EL MULTIJUGADOR SE CAIGA MIENTRAS CARGA EL MAPA
###############################

func _start_world_generation():
	await generate_world()
