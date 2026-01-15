extends BiomeRule
class_name TreeGroupPlacementRule
@export_category("Config")
@export var tree : PackedScene
@export_range(0.0, 1.0, 0.001) var chance := 0.06
@export var spacing := 2
@export var seed_offset := 10
@export var forest_noise: FastNoiseLite

func apply(cell: CellData, ctx: GenerationContext):
	if cell.decoration:
		return

	forest_noise.seed = ctx.seed + seed_offset

	var density = (forest_noise.get_noise_2d(ctx.x, ctx.y) + 1) * 0.5

	if density < 0.45:
		return
	
	var effective_chance = chance * density

	if ctx.has_near(spacing, tree):
		return
	
	if ctx.rand(seed_offset) < effective_chance :
		cell.decoration = tree
