extends "res://enemy/enemy.gd"
class_name lampEnemy

export(Vector2) var directionFacing
#var directionFacing:=Vector2(1,0) # keeps moving in that direction until it hits a wall, then turns.  Default moves right.

func _on_Player_moved():
	if directionFacing!=Vector2(0,0):
		# check that the tile immediately in front of this has no collision box.  If so, advance.  If not, multiply directionFacing by -1 and advance.
		#turn off the lights around this, then turn them back on after movement

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
