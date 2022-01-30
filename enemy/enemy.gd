extends AnimatedSprite

class_name enemy

onready var player=$Player
onready var tilemap := $TileMap as TileGrid

var _alive := true
var lastKnownCoords # Vector2 for where the player was last seen
var alert #if it sees the player/the player isn't in darkness, this is true.  Also set the animation to/from alert/idle.
var preferredAxis # preferred movement axis, for making enemies move how they're supposed to.


func checkMoveX():
	if player.position.x - position.x > 10:
		#10 is a sample value
		return Vector2(Constants.TILE_SIZE, 0)
	elif player.position.x - position.x < -10:
		return Vector2(-Constants.TILE_SIZE, 0)
	return Vector2.ZERO
	
func checkMoveY():
	if player.position.y - position.y > 10:
		#10 is a sample value
		return Vector2(0, Constants.TILE_SIZE)
	elif player.position.y - position.y < -10:
		return Vector2(0, -Constants.TILE_SIZE)
	return Vector2.ZERO
	

# each turn: move, THEN determine if player is in darkness, and if so turn off alert.
# TODO: this object isn't yet linked to the signal emitted by the Player.  Do that when they're in the scene together.
func _on_Player_moved():
	# if alive and alert, make a move
	if _alive and alert:
		var motion;
		#move toward player on preferred axis
		if preferredAxis=="x":
			motion = checkMoveX()
			if motion==Vector2.ZERO:
				motion=checkMoveY()
		if preferredAxis=="y":
			motion = checkMoveY()
			if motion==Vector2.ZERO:
				motion=checkMoveX()
		self.position+=motion
	# check to see if Player is in light and in line of sight.  If so, turn on alert and update animation and update lastKnownCoords
	# possibly just cheat and check exactly 3 or 4 tiles in each direction?  That should probably work, even if it's not all the way accurate
		var playerPos = tilemap.world_to_map(player.position)
		if abs(playerPos.x-self.position.x) < Constants.TILE_SIZE*4 and abs(playerPos.y) < 10 and tilemap.Grid[playerPos.x][playerPos.y].isLit:
			alert=true
			play("alert")
			lastKnownCoords=playerPos
			#lastKnownCoords currently doesn't do anything.
		if abs(playerPos.y-self.position.y) < Constants.TILE_SIZE*4 and abs(playerPos.x) < 10 and tilemap.Grid[playerPos.x][playerPos.y].isLit:
			alert=true
			play("alert")
			lastKnownCoords=playerPos
	# check to see if Player is in darkness.  If so, turn off alert and update animation.
		if !tilemap.Grid[playerPos.x][playerPos.y].isLit:
			alert=false
			play("idle")


func kill():
	if _alive:
		_alive = false
		self.play("explode")
		yield(self, "animation_finished")
		self.visible = false
		self.queue_free()
