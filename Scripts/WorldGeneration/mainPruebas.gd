extends Node2D

@export_category("World data")
@export var seed: int
@export var width: int
@export var height: int
@export var biomes: Array[Biome]
@export var load_radius := 2

var generator: WorldGenerator
var world_data: WorldData

@onready var tilemap : TileMap = $TileMap
@onready var trees := $trees
#@onready var chunks := $chunks
@onready var player := $player

var changeset: Dictionary
var loaded_chunks := {}
var current_chunk := Vector2i(99999, 99999)

func _ready():
	generator = WorldGenerator.new(seed, width, height, biomes)
	build_world()
#	world_data = WorldData.new(seed, width, height)
#	current_chunk = world_to_chunk(player.global_position)
#	update_chunks(player.global_position)

#func _process(_delta):
#	var new_chunk = world_to_chunk(player.global_position)
#	if new_chunk != current_chunk:
#		current_chunk = new_chunk
#		update_chunks(player.global_position)
#
#func update_chunks(player_pos: Vector2):
#	var center_chunk = world_to_chunk(player_pos)
#
#	var needed := {}
#
#	for y in range(-load_radius, load_radius + 1):
#		for x in range(-load_radius, load_radius + 1):
#			var cpos = center_chunk + Vector2i(x, y)
#			needed[cpos] = true
#
#			if not loaded_chunks.has(cpos):
#				load_chunk(cpos)
#
#	# descargar los que sobran
#	for cpos in loaded_chunks.keys():
#		if not needed.has(cpos):
#			unload_chunk(cpos)
#
#func load_chunk(cpos: Vector2i):
#	var chunk = generator.generate_chunk(cpos)
#	world_data.chunks[cpos] = chunk
#
#	var chunkNode = Node2D.new()
#	chunkNode.name = "Chunk_%d_%d" % [cpos.x, cpos.y]
#
#	var trees = Node2D.new()
#	trees.name = "Trees"
#	chunkNode.add_child(trees)
#
#	chunks.add_child(chunkNode)
#
#	render_chunk(chunkNode, chunk)
#	loaded_chunks[cpos] = true
#
#func render_chunk(chunkNode: Node2D, chunk: ChunkData):
#	changeset = BetterTerrain.create_terrain_changeset(tilemap, 1, chunk.cells_terrain)
#
#	if changeset.valid:
#		BetterTerrain.wait_for_terrain_changeset(changeset)
#		BetterTerrain.apply_terrain_changeset(changeset)
#
#	for pos in chunk.cells:
#		if chunk.cells[pos].decoration:
#			var tree = chunk.cells[pos].decoration.instantiate()
#			tree.global_position = tilemap.map_to_local(pos)
#			chunkNode.get_node("Trees").add_child(tree)
#
#func unload_chunk(cpos: Vector2i):
#	var chunk = world_data.chunks[cpos]
#
#	BetterTerrain.set_cells(tilemap, 1, chunk.cells.keys(), -1)
#
#	chunks.get_node("Chunk_%d_%d" % [cpos.x, cpos.y]).queue_free()
#	loaded_chunks.erase(cpos)

func build_world():
	tilemap.clear()
	var world_data: WorldData = generator.generate()

	changeset = BetterTerrain.create_terrain_changeset(tilemap, 1, world_data.cells_terrain)

	if changeset.valid:
		BetterTerrain.wait_for_terrain_changeset(changeset)
		BetterTerrain.apply_terrain_changeset(changeset)

	for pos in world_data.cells:
		if world_data.cells[pos].decoration:
			var tree = world_data.cells[pos].decoration.instantiate()
			tree.global_position = tilemap.map_to_local(pos)
			trees.add_child(tree)

#func world_to_chunk(pos: Vector2) -> Vector2i:
#	return Vector2i(
#		floor(pos.x / (8 * 32)),
#		floor(pos.y / (8 * 32))
#	)
