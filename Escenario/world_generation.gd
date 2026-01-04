extends Node2D

@export var noise_temperature_text: NoiseTexture2D
@export var noise_moisture_text: NoiseTexture2D

@onready var tile_map = $TileMap

@export var world_seed: int

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
var source_arr = [0, 1, 2, 3, 4]

#world size
var width: int = 300
var height: int = 300

var center_x = width / 2.0
var center_y = height / 2.0
var max_distance = sqrt(center_x * center_x + center_y * center_y)

# la dificultad del bioma se aplica segun lo cercano que este a la estructura del boss
var biomes = {}

func _ready():
	temperature_noise = noise_temperature_text.noise
	moisture_noise = noise_moisture_text.noise
	
	temperature_noise.seed = world_seed
	moisture_noise.seed = world_seed + 1
	
	print(temperature_noise.seed)
	print(moisture_noise.seed)
	
	
	#generate_world()
	call_deferred("_start_world_generation")

func generate_world():
	
	# Esto hace que los mundos tengan diferentes colores para el server y los clientes
	#source_arr.shuffle()
	
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
			
			
			if (between(temperature_noise_value, 0, 0.35) && between(moisture_noise_value, 0, 0.55)) || (between(temperature_noise_value, 0.35, 0.6) && between(moisture_noise_value, 0.55, 0.75)):
				grass_tiles.color_0.append(pos)
				biomes[pos] = source_arr[0]
			elif between(temperature_noise_value, 0.35, 0.6) && between(moisture_noise_value, 0, 0.55):
				grass_tiles.color_1.append(pos)
				biomes[pos] = source_arr[1]
			elif between(temperature_noise_value, 0.6, 1) && between(moisture_noise_value, 0, 0.75):
				grass_tiles.color_2.append(pos)
				biomes[pos] = source_arr[2]
			elif between(temperature_noise_value, 0, 0.35) && between(moisture_noise_value, 0.55, 1):
				grass_tiles.color_3.append(pos)
				biomes[pos] = source_arr[3]
			elif between(temperature_noise_value, 0.35, 1) && between(moisture_noise_value, 0.75, 1):
				grass_tiles.color_4.append(pos)
				biomes[pos] = source_arr[4]
			else:
				grass_tiles.water.append(pos)
				tile_map.set_cell(water_layer, pos, water_atlas_id, Vector2i(0, 0))
			
			# Si consume muchos recursos para generar lo frena un poco para evitar que
			# el mutijugador se caiga
			counter += 1
			# Usar un valor mas alto hace que se cargue mas rapido el mapa pero haya
			# mayor posibilidad de que se caiga el multi, y viceversa
			#if counter % 100 == 0:
				#print("Almost crashed", counter)
				# await get_tree().process_frame
	
	switch_biome_probability(source_arr[0], 1)
	tile_map.set_cells_terrain_connect(ground_layer, grass_tiles.color_0, 0, 0)
	switch_biome_probability(source_arr[0], 0)
	
	switch_biome_probability(source_arr[1], 1)
	tile_map.set_cells_terrain_connect(ground_layer, grass_tiles.color_1, 0, 0)
	switch_biome_probability(source_arr[1], 0)
	
	switch_biome_probability(source_arr[2], 1)
	tile_map.set_cells_terrain_connect(ground_layer, grass_tiles.color_2, 0, 0)
	switch_biome_probability(source_arr[2], 0)
	
	switch_biome_probability(source_arr[3], 1)
	tile_map.set_cells_terrain_connect(ground_layer, grass_tiles.color_3, 0, 0)
	switch_biome_probability(source_arr[3], 0)
	
	switch_biome_probability(source_arr[4], 1)
	tile_map.set_cells_terrain_connect(ground_layer, grass_tiles.color_4, 0, 0)
	switch_biome_probability(source_arr[4], 0)
	
	set_decoration_world()
	
	# Si ya se cargo todo pongo el player en ready
	# get_parent().player_ready()

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
	if val > min && val <= max:
		return true
	return false

func switch_biome_probability(source_id, probability):
	var source = tile_map.tile_set.get_source(source_id)
	
	for x in range(3):
		for y in range(3):
			var tile_data = source.get_tile_data(Vector2i(x, y), 0)
			
			tile_data.probability = probability

#var noise_temp_val_arr = []
#var noise_moi_val_arr = []

#noise_temp_val_arr.append(temperature_noise_value)
#noise_moi_val_arr.append(moisture_noise_value)

#print(noise_temp_val_arr.max())
#print(noise_temp_val_arr.min())

#print(noise_moi_val_arr.max())
#print(noise_moi_val_arr.min())


###############################
# ESTO EVITA QUE EL MULTIJUGADOR SE CAIGA MIENTRAS CARGA EL MAPA
###############################

func _start_world_generation():
	await generate_world()
