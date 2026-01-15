class_name WorldData

var seed: int
var width: int
var height: int
#var chunk_size := 8
#var chunks := {}
var cells := {}
var cells_terrain := {}

func _init(_seed: int, _width: int, _height: int):
	seed = _seed
	width = _width
	height = _height
