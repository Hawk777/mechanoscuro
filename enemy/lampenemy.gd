extends "res://enemy/enemy.gd"
class_name lampEnemy

var directionFacing:=Vector2(0,0) # keeps moving in that direction until it hits a wall, then turns.

func _on_Player_moved():
	if directionFacing!=Vector2(0,0):
		# check that the tile immediately in front of this has no collision box.  If so, advance.  If not, multiply directionFacing by -1 and advance.
		
