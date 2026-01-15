class_name WorldGenerator

var seed: int
var width: int
var height: int
var biomes: Array[Biome]

var worldData: WorldData
var biome_map = {}

var temperature_noise := FastNoiseLite.new()
var moisture_noise := FastNoiseLite.new()
var altitude_noise := FastNoiseLite.new()
var border_noise := FastNoiseLite.new()

func _init(_seed: int, _width: int, _height: int, _biomes: Array[Biome]):
	seed = _seed
	width = _width
	height = _height
	biomes = _biomes
	
	for biome in biomes:
		biome_map[biome.biome_type] = biome
	
	worldData = WorldData.new(seed, width, height)
	
	temperature_noise.seed = seed + 1000
	moisture_noise.seed = seed + 2000
	altitude_noise.seed = seed + 3000
	border_noise.seed = seed + 4000
	
	temperature_noise.frequency = 0.003
	moisture_noise.frequency = 0.004
	altitude_noise.frequency = 0.01
	border_noise.frequency = 0.003
	
	temperature_noise.fractal_octaves = 3
	moisture_noise.fractal_octaves = 3
	altitude_noise.fractal_octaves = 4
	border_noise.fractal_octaves = 1
	
	temperature_noise.fractal_lacunarity = 1.4
	moisture_noise.fractal_lacunarity = 1.3
	altitude_noise.fractal_lacunarity = 2
	border_noise.fractal_lacunarity = 2
	
	temperature_noise.fractal_gain = 1.8
	moisture_noise.fractal_gain = 1.5
	altitude_noise.fractal_gain = 0.45
	border_noise.fractal_gain = 0.4

func generate():
	# PASADA 1
	for y in range(height):
		for x in range(width):
			var pos = Vector2i(x, y)
			var cell = CellData.new()
			
			var temperature_noise_value = (temperature_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var moisture_noise_value = (moisture_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var altitude_noise_value = (altitude_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var border_noise_value = (border_noise.get_noise_2d(x, y) + 1.0) * 0.5

			var dx = min(x, width - x) / (width * 0.5)
			var dy = min(y, height - y) / (height * 0.5)
			var distance = clamp(min(dx, dy), 0.0, 1.0)
			var falloff = clamp(pow((distance + 0.08) * 1.8 + border_noise_value * 0.8, 3.0), 0.0, 1.0)

			if altitude_noise_value < 0.6:
				altitude_noise_value = 0.45 + 0.15 * pow(altitude_noise_value / 0.6, 1.5)

			altitude_noise_value *= falloff

			if altitude_noise_value > 0.5:
				if (between(temperature_noise_value, 0, 0.35) && between(moisture_noise_value, 0, 0.55)) || (between(temperature_noise_value, 0.35, 0.6) && between(moisture_noise_value, 0.55, 0.75)):
					cell.biome = BiomeType.Biome.FOREST
				elif between(temperature_noise_value, 0.35, 0.6) && between(moisture_noise_value, 0, 0.55):
					cell.biome = BiomeType.Biome.MEADOW
				elif between(temperature_noise_value, 0.6, 1) && between(moisture_noise_value, 0, 0.75):
					cell.biome = BiomeType.Biome.TAIGA
				elif between(temperature_noise_value, 0, 0.35) && between(moisture_noise_value, 0.55, 1):
					cell.biome = BiomeType.Biome.SNOW
				elif between(temperature_noise_value, 0.35, 1) && between(moisture_noise_value, 0.75, 1):
					cell.biome = BiomeType.Biome.SWAMP
			else:
				cell.biome = BiomeType.Biome.OCEAN
			
			worldData.cells_terrain[pos] = cell.biome
			worldData.cells[pos] = cell

	# PASADA 2
	for y in range(height):
		for x in range(width):
			var pos = Vector2i(x, y)
			var cell = worldData.cells[pos]
			var biome = biome_map[cell.biome]
			var ctx = GenerationContext.new()
			ctx.x = x
			ctx.y = y
			ctx.cells = worldData.cells
			ctx.width = width
			ctx.height = height
			ctx.seed = seed

			for rule in biome.rules:
				rule.apply(cell, ctx)

	return worldData

#func generate_chunk(cpos: Vector2i):
#	var chunk := ChunkData.new()
#	chunk.chunk_pos = cpos
#
#	for y in range(8):
#		for x in range(8):
#			var wx = cpos.x * 8 + x
#			var wy = cpos.y * 8 + y
#			var pos = Vector2i(wx, wy)
#
#			if is_inside_world(wx, wy):
#				var cell = CellData.new()
#
#				var temperature_noise_value = (temperature_noise.get_noise_2d(wx, wy) + 1.0) * 0.5
#				var moisture_noise_value = (moisture_noise.get_noise_2d(wx, wy) + 1.0) * 0.5
#				var altitude_noise_value = (altitude_noise.get_noise_2d(wx, wy) + 1.0) * 0.5
#				var border_noise_value = (border_noise.get_noise_2d(wx, wy) + 1.0) * 0.5
#
#				var dx = min(wx, width - wx) / (width * 0.5)
#				var dy = min(wy, height - wy) / (height * 0.5)
#				var distance = clamp(min(dx, dy), 0.0, 1.0)
#				var falloff = clamp(pow((distance + 0.08) * 1.8 + border_noise_value * 0.8, 3.0), 0.0, 1.0)
#
#				if altitude_noise_value < 0.6:
#					altitude_noise_value = 0.45 + 0.15 * pow(altitude_noise_value / 0.6, 1.5)
#
#				altitude_noise_value *= falloff
#
#				if altitude_noise_value > 0.5:
#					if (between(temperature_noise_value, 0, 0.35) && between(moisture_noise_value, 0, 0.55)) || (between(temperature_noise_value, 0.35, 0.6) && between(moisture_noise_value, 0.55, 0.75)):
#						cell.biome = BiomeType.Biome.FOREST
#					elif between(temperature_noise_value, 0.35, 0.6) && between(moisture_noise_value, 0, 0.55):
#						cell.biome = BiomeType.Biome.MEADOW
#					elif between(temperature_noise_value, 0.6, 1) && between(moisture_noise_value, 0, 0.75):
#						cell.biome = BiomeType.Biome.TAIGA
#					elif between(temperature_noise_value, 0, 0.35) && between(moisture_noise_value, 0.55, 1):
#						cell.biome = BiomeType.Biome.SNOW
#					elif between(temperature_noise_value, 0.35, 1) && between(moisture_noise_value, 0.75, 1):
#						cell.biome = BiomeType.Biome.SWAMP
#				else:
#					cell.biome = BiomeType.Biome.OCEAN
#
#				chunk.cells_terrain[pos] = cell.biome
#				chunk.cells[pos] = cell
#
#	# PASADA 2
#	for y in range(8):
#		for x in range(8):
#			var wx = cpos.x * 8 + x
#			var wy = cpos.y * 8 + y
#			var pos = Vector2i(wx, wy)
#
#			if is_inside_world(wx, wy):
#				var cell = chunk.cells[pos]
#				var biome = biome_map[cell.biome]
#				var ctx = GenerationContext.new()
#				ctx.x = wx
#				ctx.y = wy
#				ctx.cells = chunk.cells
#				ctx.width = width
#				ctx.height = height
#				ctx.seed = seed
#
#				for rule in biome.rules:
#					rule.apply(cell, ctx)
#
#	return chunk

#func is_inside_world(x: int, y: int) -> bool:
#	return x >= 0 and y >= 0 and x < width and y < height

func between(val, min, max):
	if val >= min && val <= max:
		return true
	return false
