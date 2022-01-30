extends AnimatedSprite

class_name enemy

export(NodePath) var player_path
export(NodePath) var tile_grid_path
export(AudioStream) var alert_sound
export(AudioStream) var dealert_sound
export(AudioStream) var step_sound
onready var alert_player = get_node("MonsterAlertPlayer") as AudioStreamPlayer2D
onready var dealert_player = get_node("MonsterDeAlertPlayer") as AudioStreamPlayer2D
onready var step_player = get_node("MonsterStepPlayer") as AudioStreamPlayer2D
onready var player := get_node(player_path) as Node2D
onready var tilemap := get_node(tile_grid_path) as TileGrid

var _alive := true
var lastKnownCoords # Vector2 for where the player was last seen
var alert #if it sees the player/the player isn't in darkness, this is true.  Also set the animation to/from alert/idle.
export var preferredAxis="y" # preferred movement axis, for making enemies move how they're supposed to.


func _ready() -> void:
	if alert_player:
		alert_player.stream=alert_sound
	if dealert_player:
		dealert_player.stream=dealert_sound
	step_player.stream=step_sound
	tilemap.get_tilev(tilemap.world_to_map(tilemap.to_local(global_position))).occupant = self


func checkMoveX():
	var player_grid := tilemap.world_to_map(tilemap.to_local(player.global_position))
	var player_tile := tilemap.get_tilev(player_grid)
	var self_grid := tilemap.world_to_map(tilemap.to_local(global_position))
	if player.global_position.x - global_position.x > 10 and tilemap.coord_is_passable(self_grid.x+1,self_grid.y):
		#10 is a sample value
		return Vector2(Constants.TILE_SIZE, 0)
	elif player.global_position.x - global_position.x < -10 and tilemap.coord_is_passable(self_grid.x-1,self_grid.y):
		return Vector2(-Constants.TILE_SIZE, 0)
	return Vector2.ZERO
	
func checkMoveY():
	var player_grid := tilemap.world_to_map(tilemap.to_local(player.global_position))
	var player_tile := tilemap.get_tilev(player_grid)
	var self_grid := tilemap.world_to_map(tilemap.to_local(global_position))
	if player.global_position.y - global_position.y > 10 and tilemap.coord_is_passable(self_grid.x,self_grid.y+1):
		#10 is a sample value
		return Vector2(0, Constants.TILE_SIZE)
	elif player.global_position.y - global_position.y < -10 and tilemap.coord_is_passable(self_grid.x,self_grid.y-1):
		return Vector2(0, -Constants.TILE_SIZE)
	return Vector2.ZERO
	

# each turn: move, THEN determine if player is in darkness, and if so turn off alert.
# TODO: this object isn't yet linked to the signal emitted by the Player.  Do that when they're in the scene together.
func _on_Player_moved():
	# if alive and alert, make a move
	if _alive:
		if alert:
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
			if motion!=Vector2.ZERO:
				emit_signal("enemy_moved")
				step_player.play()
		# check to see if Player is in light and in line of sight.  If so, turn on alert and update animation and update lastKnownCoords
		# possibly just cheat and check exactly 3 or 4 tiles in each direction?  That should probably work, even if it's not all the way accurate
		var player_grid := tilemap.world_to_map(tilemap.to_local(player.global_position))
		var player_tile := tilemap.get_tilev(player_grid)
		var self_grid := tilemap.world_to_map(tilemap.to_local(global_position))
		if abs(player_grid.x-self_grid.x) < 4 and player_grid.y==self_grid.y and player_tile.isLit:
			if !alert:
				alert_player.play()
			alert=true
			play("alert")
			lastKnownCoords=player_grid
			#lastKnownCoords currently doesn't do anything.
		if abs(player_grid.y-self_grid.y) < 4 and player_grid.x==self_grid.x and player_tile.isLit:
			if !alert:
				alert_player.play()
			alert=true
			play("alert")
			lastKnownCoords=player_grid
		# check to see if Player is in darkness.  If so, turn off alert and update animation.
		if !player_tile.isLit:
			if alert:
				dealert_player.play()
			alert=false
			play("idle")


func _move_by(motion: Vector2) -> void:
	if motion != Vector2.ZERO:
		var old_grid := tilemap.world_to_map(tilemap.to_local(global_position))
		var old_tile := tilemap.get_tilev(old_grid)
		#check if there's a wall in that direction
		if tilemap.coord_is_passable(old_grid.x+motion[0]/64, old_grid.y+motion[1]/64):
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
