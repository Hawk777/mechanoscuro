class_name Player
extends AnimatedSprite

signal moved()
signal death_started()
signal death_finished()

export(NodePath) var tile_grid_path: NodePath
export(AudioStream) var dead_sound

var _alive := true
var _frozen := false

onready var _tile_grid := get_node(tile_grid_path) as TileGrid
onready var _dead_player = get_node("DeadPlayer") as AudioStreamPlayer2D

func _ready() -> void:
	_dead_player.stream=dead_sound
	_tile_grid.get_tilev(_tile_grid.world_to_map(_tile_grid.to_local(global_position))).occupant = self

func is_in_light() -> bool:
	var tile := _tile_grid.get_tilev(_tile_grid.world_to_map(_tile_grid.to_local(global_position)))
	return tile.isLit || tile.lamped
	
func get_coordinates() -> Vector2:
	return _tile_grid.world_to_map(_tile_grid.to_local(global_position))

func get_object_coordinates(obj) -> Vector2:
	return _tile_grid.world_to_map(_tile_grid.to_local(obj.global_position))

func get_tile() -> Tile:
	return _tile_grid.get_tilev(get_coordinates())


func _unhandled_input(event: InputEvent) -> void:
	if _alive and not _frozen:
		var motion := Vector2.ZERO
		if event.is_action_pressed("move_down"):
			motion = Vector2(0, Constants.TILE_SIZE)
		elif event.is_action_pressed("move_up"):
			motion = Vector2(0, -Constants.TILE_SIZE)
		elif event.is_action_pressed("move_left"):
			motion = Vector2(-Constants.TILE_SIZE, 0)
		elif event.is_action_pressed("move_right"):
			motion = Vector2(Constants.TILE_SIZE, 0)
		if motion != Vector2.ZERO:
			var new_pos := global_position + motion
			var new_grid := _tile_grid.world_to_map(_tile_grid.to_local(new_pos))
			if _tile_grid.coord_is_passable(new_grid.x, new_grid.y):
				var old_grid := _tile_grid.world_to_map(_tile_grid.to_local(global_position))
				global_position = new_pos
				_tile_grid.get_tilev(old_grid).occupant = null
				var new_tile := _tile_grid.get_tilev(new_grid)
				if new_tile.occupant == null:
					new_tile.occupant = self
					emit_signal("moved")
					run_turn(new_grid, new_tile)
				else:
					kill(false)

func run_turn(new_coord, new_tile):
	var plate_lookup = {}
	for plate in get_tree().get_nodes_in_group("pressure-plates"):
		plate_lookup[get_object_coordinates(plate)] = plate
	
	if plate_lookup.has(new_coord):
		var plate = plate_lookup[new_coord]
		plate._on_pressed()
		toggle_doors_and_lighting()
	
	if move_lamp_enemies(plate_lookup) % 2 != 0:
		toggle_doors_and_lighting()

	if move_reg_enemies(plate_lookup) % 2 != 0:
		toggle_doors_and_lighting()
	
func toggle_doors_and_lighting() -> void:
	_tile_grid.toggle_light_new()
	for d in get_tree().get_nodes_in_group("doors"):
		d.toggle_new()

func move_lamp_enemies(plate_lookup) -> int:
	var toggles := 0

	for e in get_tree().get_nodes_in_group("lamp-enemies"):
		var old_coord = get_object_coordinates(e)
		e.move()
		var new_coord = get_object_coordinates(e)
		if new_coord != old_coord:
			if plate_lookup.has(new_coord) && !plate_lookup.has(old_coord):
				toggles = toggles + 1
	
	return toggles

func move_reg_enemies(plate_lookup) -> int:
	var toggles := 0

	for e in get_tree().get_nodes_in_group("non-lamp-enemies"):
		var old_coord = get_object_coordinates(e)
		e.move()
		var new_coord = get_object_coordinates(e)
		if new_coord != old_coord:
			if plate_lookup.has(new_coord) && !plate_lookup.has(old_coord):
				toggles = toggles + 1
	
	return toggles

func freeze() -> void:
	_frozen = true

func kill(_killed_by_door: bool) -> void:
	if _alive:
		_alive = false
		_tile_grid.get_tilev(_tile_grid.world_to_map(_tile_grid.to_local(global_position))).occupant = null
		emit_signal("death_started")
		_dead_player.play()
		self.play("explode")
		yield(self, "animation_finished")
		self.visible = false
		emit_signal("death_finished")
