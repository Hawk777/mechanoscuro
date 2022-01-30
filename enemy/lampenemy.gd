extends "res://enemy/enemy.gd"
class_name lampEnemy

signal lighting_changed()

export(Vector2) var directionFacing
#var directionFacing:=Vector2(1,0) # keeps moving in that direction until it hits a wall, then turns.  Default moves right.

func _move_by(motion: Vector2) -> void:
	if motion != Vector2.ZERO:
		var old_grid := tile_grid.world_to_map(tile_grid.to_local(global_position))
		var old_tile := tile_grid.get_tilev(old_grid)
		#check if there's a wall in that direction
		if tile_grid.coord_is_passable(old_grid.x+motion[0]/64, old_grid.y+motion[1]/64):
			position += motion
			var new_grid := tile_grid.world_to_map(tile_grid.to_local(global_position))
			var new_tile := tile_grid.get_tilev(new_grid)
			old_tile.occupant = null
			if new_tile.occupant != null:
				new_tile.occupant.kill()
			new_tile.occupant = self
func delight():
	var self_grid := tile_grid.world_to_map(tile_grid.to_local(global_position))
	for n in range(-1,2):
		for m in range(-1,2):
			# turn off adjacent lights
			if tile_grid.Grid[tile_grid.coord2idx(self_grid.x+n,self_grid.y+m)].doubleLamped:
				tile_grid.Grid[tile_grid.coord2idx(self_grid.x+n,self_grid.y+m)].doubleLamped=false
			else:
				tile_grid.Grid[tile_grid.coord2idx(self_grid.x+n,self_grid.y+m)].lamped=false
			var cell := tile_grid.get_cellv(Vector2(self_grid.x+n,self_grid.y+m))
			var name := tile_grid.tile_set.tile_get_name(cell)
			if name.ends_with("_dark") or name.ends_with("_light"):
				name = name.trim_suffix("_dark").trim_suffix("_light")
				if tile_grid.Grid[tile_grid.coord2idx(self_grid.x+n,self_grid.y+m)].isLit or tile_grid.Grid[tile_grid.coord2idx(self_grid.x+n,self_grid.y+m)].lamped:
					name += "_light"
				else:
					name += "_dark"
				cell = tile_grid.tile_set.find_tile_by_name(name)
				tile_grid.set_cellv(Vector2(self_grid.x+n,self_grid.y+m), cell)

func light():
	var self_grid := tile_grid.world_to_map(tile_grid.to_local(global_position))
	for n in range(-1,2):
		for m in range(-1,2):
			#turn on adjacent lights
			if tile_grid.Grid[tile_grid.coord2idx(self_grid.x+n,self_grid.y+m)].lamped:
				tile_grid.Grid[tile_grid.coord2idx(self_grid.x+n,self_grid.y+m)].doubleLamped=true
			tile_grid.Grid[tile_grid.coord2idx(self_grid.x+n,self_grid.y+m)].lamped=true
			var cell := tile_grid.get_cellv(Vector2(self_grid.x+n,self_grid.y+m))
			var name := tile_grid.tile_set.tile_get_name(cell)
			if name.ends_with("_dark") or name.ends_with("_light"):
				name = name.trim_suffix("_dark").trim_suffix("_light")
				name += "_light"
				cell = tile_grid.tile_set.find_tile_by_name(name)
				tile_grid.set_cellv(Vector2(self_grid.x+n,self_grid.y+m), cell)
	emit_signal("lighting_changed")

func _ready():
	step_player.stream=step_sound
	tile_grid.get_tilev(tile_grid.world_to_map(tile_grid.to_local(global_position))).occupant = self
	# light up adjacent spaces
	light()

func _on_Player_moved():
	pass
	
func move():
	if directionFacing!=Vector2(0,0):
		# check that the tile immediately in front of this has no collision box.  If so, advance.  If not, multiply directionFacing by -1 and advance.
		#turn off the lights around this, then turn them back on after movement
		delight()
		var finished=false
		var nextDirection = Vector2(-directionFacing.y,directionFacing.x)
		var new_pos = self.position + nextDirection*Constants.TILE_SIZE
		while !finished:
			if (tile_grid.coord_is_passable(new_pos[0] / 64, new_pos[1] / 64)):
				finished=true
			else:
				nextDirection=Vector2(nextDirection.y,-nextDirection.x) # if my math is right, this will rotate it 90 degrees
				new_pos = self.position + nextDirection*Constants.TILE_SIZE
		_move_by(nextDirection*Constants.TILE_SIZE)
		emit_signal("enemy_moved")
		directionFacing=nextDirection
		if directionFacing.x+directionFacing.y<0:
			flip_h=true
		else:
			flip_h=false
		if _alive:
			light()
