class_name WorldUtils

# funcion que deterministica, sirve para obtener numeros pseudoaleatorios
static func hash_rand(x:int, y:int, seed:int) -> float:
	var n = x * 73856093
	n ^= y * 19349663
	n ^= seed * 83492791

	# aseguramos positivo
	n = n & 0x7fffffff

	# normalizamos a 0..1
	return float(n % 1000000) / 1000000.0

static func has_deco_near(cells, width, height, x, y, radius, deco):
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var nx = x + dx
			var ny = y + dy
			
			if nx < 0 or ny < 0 or nx >= width or ny >= height:
				continue
			if cells[Vector2i(nx, ny)].decoration:
				return true
	return false
