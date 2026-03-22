class_name VolunteerData
extends RefCounted

var pos: Vector2i
var dir_index: int
var deployed_day: int


func _init(initial_pos: Vector2i, initial_dir_index: int, day: int) -> void:
	pos = initial_pos
	dir_index = initial_dir_index
	deployed_day = day
