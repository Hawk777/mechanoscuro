extends "res://enemy/enemy.gd"
class_name lampEnemy

export(Vector2) var directionFacing
#var directionFacing:=Vector2(1,0) # keeps moving in that direction until it hits a wall, then turns.  Default moves right.

func delight():
	var self_grid := tilemap.world_to_map(tilemap.to_local(global_position))
	for n in range(-1,2):
		for m in range(-1,2):
			# turn off adjacent lights
			tilemap.Grid[tilemap.coord2idx(self_grid.x+n,self_grid.y+m)].lamped=false
			var cell := tilemap.get_cellv(Vector2(self_grid.x+n,self_grid.y+m))
			var name := tilemap.tile_set.tile_get_name(cell)
			if name.ends_with("_dark") or name.ends_with("_light"):
				name = name.trim_suffix("_dark").trim_suffix("_light")
				if tilemap.Grid[tilemap.coord2idx(self_grid.x+n,self_grid.y+m)].isLit or tilemap.Grid[tilemap.coord2idx(self_grid.x+n,self_grid.y+m)].lamped:
					name += "_light"
				else:
					name += "_dark"
				cell = tilemap.tile_set.find_tile_by_name(name)
				tilemap.set_cellv(Vector2(self_grid.x+n,self_grid.y+m), cell)

func light():
	var self_grid := tilemap.world_to_map(tilemap.to_local(global_position))
	for n in range(-1,2):
		for m in range(-1,2):
			#turn on adjacent lights
			tilemap.Grid[tilemap.coord2idx(self_grid.x+n,self_grid.y+m)].lamped=true
			var cell := tilemap.get_cellv(Vector2(self_grid.x+n,self_grid.y+m))
			var name := tilemap.tile_set.tile_get_name(cell)
			if name.ends_with("_dark") or name.ends_with("_light"):
				name = name.trim_suffix("_dark").trim_suffix("_light")
				name += "_light"
				cell = tilemap.tile_set.find_tile_by_name(name)
				tilemap.set_cellv(Vector2(self_grid.x+n,self_grid.y+m), cell)
	emit_signal("lighting_changed")

func _ready():
	step_player.stream=step_sound
	tilemap.get_tilev(tilemap.world_to_map(tilemap.to_local(global_position))).occupant = self
	# light up adjacent spaces
	light()

func _on_Player_moved():
	if directionFacing!=Vector2(0,0):
		# check that the tile immediately in front of this has no collision box.  If so, advance.  If not, multiply directionFacing by -1 and advance.
		#turn off the lights around this, then turn them back on after movement
		delight()
		var finished=false
		var new_pos = self.position + directionFacing*Constants.TILE_SIZE
		while !finished:
			if (tilemap.coord_is_passable(new_pos[0] / 64, new_pos[1] / 64)):
				finished=true
			else:
				directionFacing=Vector2(directionFacing.y,-directionFacing.x) # if my math is right, this will rotate it 90 degrees
				if directionFacing.x+directionFacing.y<0:
					flip_h=true
				else:
					flip_h=false
			new_pos = self.position + directionFacing*Constants.TILE_SIZE
		_move_by(directionFacing*Constants.TILE_SIZE)
		emit_signal("enemy_moved")
		if _alive:
			light()
