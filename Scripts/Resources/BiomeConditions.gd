extends Resource
class_name BiomeConditions

@export_category("TEMPERATURE")
@export_range(0, 1, 0.001) var min_temperature: float = 0
@export_range(0, 1, 0.001) var max_temperature: float = 1

@export_category("MOISTURE")
@export_range(0, 1, 0.001) var min_moisture: float = 0
@export_range(0, 1, 0.001) var max_moisture: float = 1

@export_category("ALTITUDE")
@export_range(0, 1, 0.001) var min_altitude: float = 0
@export_range(0, 1, 0.001) var max_altitude: float = 1
