extends AnimatedSprite

class_name enemy

export(NodePath) var player_path
export(NodePath) var tile_grid_path

onready var player := get_node(player_path) as Node2D
onready var tilemap := get_node(tile_grid_path) as TileGrid

var _alive := true
var lastKnownCoords # Vector2 for where the player was last seen
var alert #if it sees the player/the player isn't in darkness, this is true.  Also set the animation to/from alert/idle.
var preferredAxis # preferred movement axis, for making enemies move how they're supposed to.


func _ready() -> void:
	tilemap.get_tilev(tilemap.world_to_map(tilemap.to_local(global_position))).occupant = self


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
		_move_by(motion)
	# check to see if Player is in light and in line of sight.  If so, turn on alert and update animation and update lastKnownCoords
	# possibly just cheat and check exactly 3 or 4 tiles in each direction?  That should probably work, even if it's not all the way accurate
		var player_grid := tilemap.world_to_map(player.position)
		var self_grid := tilemap.world_to_map(position)
		if abs(player_grid.x-self_grid.x) < 4 and abs(player_grid.y) < 10 and tilemap.Grid[player_grid.x][player_grid.y].isLit:
			alert=true
			play("alert")
			lastKnownCoords=player_grid
			#lastKnownCoords currently doesn't do anything.
		if abs(player_grid.y-self_grid.y) < 4 and abs(player_grid.x) < 10 and tilemap.Grid[player_grid.x][player_grid.y].isLit:
			alert=true
			play("alert")
			lastKnownCoords=player_grid
	# check to see if Player is in darkness.  If so, turn off alert and update animation.
		if !tilemap.Grid[player_grid.x][player_grid.y].isLit:
			alert=false
			play("idle")


func _move_by(motion: Vector2) -> void:
	if motion != Vector2.ZERO:
		var old_grid := tilemap.world_to_map(tilemap.to_local(global_position))
		var old_tile := tilemap.get_tilev(old_grid)
		position += motion
		var new_grid := tilemap.world_to_map(tilemap.to_local(global_position))
		var new_tile := tilemap.get_tilev(new_grid)
		old_tile.occupant = null
		if new_tile.occupant != null:
			new_tile.occupant.kill()
		new_tile.occupant = self


func kill():
	if _alive:
		_alive = false
		tilemap.get_tilev(tilemap.world_to_map(tilemap.to_local(global_position))).occupant = null
		self.play("explode")
		yield(self, "animation_finished")
		self.visible = false
		self.queue_free()
