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
onready var _dead_player = get_node("DeadPlayer") as AudioStreamPlayer

func _ready() -> void:
	_dead_player.stream=dead_sound
	_tile_grid.get_tilev(_tile_grid.world_to_map(_tile_grid.to_local(global_position))).occupant = self

func is_in_light() -> bool:
	var tile := _tile_grid.get_tilev(_tile_grid.world_to_map(_tile_grid.to_local(global_position)))
	return tile.isLit
	
func get_coordinates() -> Vector2:
	return _tile_grid.world_to_map(_tile_grid.to_local(global_position))

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
				else:
					kill()


func freeze() -> void:
	_frozen = true


func kill() -> void:
	if _alive:
		_alive = false
		_tile_grid.get_tilev(_tile_grid.world_to_map(_tile_grid.to_local(global_position))).occupant = null
		emit_signal("death_started")
		_dead_player.play()
		self.play("explode")
		yield(self, "animation_finished")
		self.visible = false
		emit_signal("death_finished")
