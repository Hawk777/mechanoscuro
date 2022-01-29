extends AnimatedSprite

class_name enemy


var lastKnownCoords # Vector2 for where the player was last seen
var alert #if it sees the player/the player isn't in darkness, this is true.  Also set the animation to/from alert/idle.
var preferredAxis # preferred movement axis, for making enemies move how they're supposed to.


func checkMoveX():
	if get_node("Player").position.x - position.x > 10:
		#10 is a sample value
		return Vector2(Constants.TILE_SIZE, 0)
	elif get_node("Player").position.x - position.x < -10:
		return Vector2(-Constants.TILE_SIZE, 0)
	return Vector2(0,0)
	
func checkMoveY():
	if get_node("Player").position.y - position.y > 10:
		#10 is a sample value
		return Vector2(0, Constants.TILE_SIZE)
	elif get_node("Player").position.y - position.y < -10:
		return Vector2(0, -Constants.TILE_SIZE)
	return Vector2(0,0)
	

# each turn: move, THEN determine if player is in darkness, and if so turn off alert.
func _on_Player_moved():
	# if alert, make a move
	if alert:
		var motion;
		#move toward player on preferred axis
		if preferredAxis=="x":
			motion = checkMoveX()
			if motion==Vector2(0,0):
				motion=checkMoveY()
		if preferredAxis=="y":
			motion = checkMoveY()
			if motion==Vector2(0,0):
				motion=checkMoveX()
		self.position+=motion
	# check to see if Player is in light and in line of sight.  If so, turn on alert and update animation and update lastKnownCoords
	
	# check to see if Player is in darkness.  If so, turn off alert and update animation.
	
