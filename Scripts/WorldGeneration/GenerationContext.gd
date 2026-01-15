class_name GenerationContext

var seed : int
var cells : Dictionary
var x : int
var y : int
var width: float
var height: float

func rand(offset := 0):
	return WorldUtils.hash_rand(x, y, seed + offset)

func has_near(radius, deco_type):
	return WorldUtils.has_deco_near(cells, width, height, x, y, radius, deco_type)
