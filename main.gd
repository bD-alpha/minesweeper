extends Node2D

@onready var field: TileMapLayer = %Field
@onready var overlay: TileMapLayer = %Overlay
@onready var time_label: Label = %TimeLabel
@onready var flags_label: Label = %FlagsLabel
@onready var bombs_label: Label = %BombsLabel
@onready var explosion: GPUParticles2D = %Explosion

const ATLAS_BOMB: Vector2i = Vector2i(2, 4)
const ATLAS_CLOSED: Vector2i = Vector2i(3, 4)
const ATLAS_FLAG: Vector2i = Vector2i(0, 4)

var time_passed: int = 0

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

var field_tensor: PackedInt32Array
var overlay_tensor: BitMap = BitMap.new()
var flags: Array[Vector2i] = []
var field_size: Vector2i = Vector2i.ONE * 12
var bomb_count: int = 20

var flags_placed: int = 0

func _ready() -> void:
	overlay_tensor.create(field_size)
	overlay_tensor.set_bit_rect(Rect2i(Vector2.ZERO, field_size), 1)
	
	# Drawing overlay
	for y in field_size.y:
		for x in field_size.x:
			overlay.set_cell(Vector2i(x, y), 1, Vector2i(3, 4))
	
	update_labels()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		var cell_position = field.local_to_map(field.to_local(event.position))
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not field_tensor:
				generate_field(cell_position)
			reveal_cell(cell_position)
		
		if event.button_index == MOUSE_BUTTON_RIGHT:
			toggle_flag(cell_position)


func generate_field(safe_spot: Vector2i) -> void:
	# Defining free cells
	var free_cells: Array[Vector2i] = []
	for x in field_size.x:
		for y in field_size.y:
			var cell = Vector2i(x, y)
			
			var is_near_safe_spot = false
			for neighbor in NEIGHBORS:
				if cell == safe_spot + neighbor:
					is_near_safe_spot = true
					break
			if cell == safe_spot or is_near_safe_spot: continue
			
			free_cells.append(cell)
	
	# Inititalizing field tensor
	field_tensor = []
	field_tensor.resize(field_size.x * field_size.y)
	
	# Creating bombs
	for i in bomb_count:
		var bomb_coord = free_cells.pop_at(randi() % free_cells.size())
		field_tensor[bomb_coord.x + bomb_coord.y * field_size.x] = -1
		
		# Creating bomb marks
		for neighbor in NEIGHBORS:
			var neighbor_coord = bomb_coord + neighbor
			if not Rect2i(Vector2i.ZERO,  field_size).has_point(neighbor_coord): continue
			if field_tensor[neighbor_coord.x + neighbor_coord.y * field_size.x] == -1: continue
			field_tensor[neighbor_coord.x + neighbor_coord.y * field_size.x] += 1
	
	# Drawing field and overlay
	for y in field_size.y:
		for x in field_size.x:
			overlay.set_cell(Vector2i(x, y), 1, Vector2i(3, 4))
			
			var field_value = field_tensor[x + y * field_size.x]
			if field_value == 0: continue
			
			if field_value > 0:
				field.set_cell(Vector2i(x, y), 1, Vector2i(field_value - 1, (x + y) % 2))
			else:
				field.set_cell(Vector2i(x, y), 1, ATLAS_BOMB)


func reveal_cell(cell: Vector2i) -> void:
	if not Rect2i(Vector2i.ZERO,  field_size).has_point(cell): return
	if cell in flags: return
	if not overlay_tensor.get_bitv(cell): return
	
	overlay_tensor.set_bitv(cell, 0)
	overlay.set_cell(cell)
	
	if field_tensor[cell.x + cell.y * field_size.x] == -1:
		game_over(cell)
		return
	
	win_check()
		
	if field_tensor[cell.x + cell.y * field_size.x] == 0:
		for neighbor in NEIGHBORS:
			reveal_cell(cell + neighbor)


func toggle_flag(cell: Vector2i) -> void:
	if not overlay_tensor.get_bitv(cell): return
	if cell in flags:
		flags.erase(cell)
		overlay.set_cell(cell, 1, ATLAS_CLOSED)
		flags_placed -= 1
		update_labels()
	else:
		flags.append(cell)
		overlay.set_cell(cell, 1, ATLAS_FLAG)
		flags_placed += 1
		update_labels()

func update_labels() -> void:
	%FlagsLabel.text = "%02d" % flags_placed
	%BombsLabel.text = "%02d" % (bomb_count - flags_placed)

func win_check() -> void:
	if overlay_tensor.get_true_bit_count() == bomb_count:
		%Smileys.restart()
		%Timer.stop()
		get_tree().create_timer(5).timeout.connect(get_tree().quit)

func game_over(bomb_position: Vector2i) -> void:
	var initial_position = get_tree().root.position
	var tween = create_tween()
	for i in 20:
		tween.tween_property(get_tree().root, "position", initial_position + Vector2i(Vector2.from_angle(randf() * TAU) * (25 - i)), 0.06)
	tween.tween_callback(get_tree().quit).set_delay(1)
	
	explosion.position = field.map_to_local(bomb_position)
	explosion.restart()
	
	%Timer.stop()
	set_process_unhandled_input(false)

func _on_timer_timeout() -> void:
	time_passed += 1
	time_label.text = "%03d" % time_passed
	
