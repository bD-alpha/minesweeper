extends Node2D

@export var bombs: FastNoiseLite

const CHUNK_SIZE = 16
const NEIGHBORS: Array[Vector2i] = [
	Vector2i.RIGHT, 
	Vector2i.RIGHT + Vector2i.UP, 
	Vector2i.UP,
	Vector2i.UP + Vector2i.LEFT,
	Vector2i.LEFT,
	Vector2i.LEFT + Vector2i.DOWN,
	Vector2i.DOWN,
	Vector2i.DOWN + Vector2i.RIGHT
]

func _ready() -> void:
	
	pass

func _process(delta: float) -> void:
	pass
	
func in_safe_spot(cell: Vector2i, safe_spot: Vector2i) -> bool:
	var is_neighbor: bool = false
	for neighbor in NEIGHBORS:
		if cell + neighbor == safe_spot: return true
	return cell == safe_spot

func generate_chunk(chunk_coord: Vector2i, safe_spot: Vector2i = -Vector2i.ONE) -> void:
	var free_cells: Array[Vector2i] = []
	var bomb_cells: Array[Vector2i] = []
	for y in CHUNK_SIZE:
		for x in CHUNK_SIZE:
			var cell = Vector2i(x, y)
			
			if safe_spot != -Vector2i.ONE and in_safe_spot(cell, safe_spot): 
				continue
				
			if bombs.get_noise_2dv(cell) > 0.9: 
				bomb_cells.append(cell)
				continue
			
			free_cells
