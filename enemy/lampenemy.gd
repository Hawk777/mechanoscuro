extends "res://enemy/enemy.gd"
class_name lampEnemy

export(NodePath) var tile_grid_path: NodePath

onready var tile_grid := get_node(tile_grid_path) as TileGrid

var directionFacing:=Vector2(1,0) # keeps moving in that direction until it hits a wall, then turns.  Default moves right.

func _on_Player_moved():
	if directionFacing!=Vector2(0,0):
		# check that the tile immediately in front of this has no collision box.  If so, advance.  If not, multiply directionFacing by -1 and advance.
		var new_pos = self.position + directionFacing*Constants.TILE_SIZE
		if (tile_grid.coord_is_passable(new_pos[0] / 64, new_pos[1] / 64)):
			self.position = new_pos
		else:
			flip_h=!flip_h
			directionFacing*=-1
			new_pos = self.position + directionFacing*Constants.TILE_SIZE
			self.position=new_pos
