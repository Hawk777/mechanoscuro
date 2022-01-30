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
onready var tile_grid := get_node(tile_grid_path) as TileGrid

const SEARCHING := "SEARCHING"
const ALERTING := "ALERTING"
const CHASING := "CHASING"
const FINALIZING_CHASE := "FINALIZING_CHASE"

var _alive := true
var mode := SEARCHING
var ppt = null # Vector2 that always saves the player's previous location

export var preferredAxis="y" # preferred movement axis, for making enemies move how they're supposed to.

func _ready() -> void:
	if alert_player:
		alert_player.stream=alert_sound
	if dealert_player:
		dealert_player.stream=dealert_sound
	step_player.stream=step_sound
	tile_grid.get_tilev(tile_grid.world_to_map(tile_grid.to_local(global_position))).occupant = self
	
func get_tile(vector) -> Tile:
	return tile_grid.get_tilev(vector)
	
func get_occupied_tile() -> Tile:
	return tile_grid.get_tilev(get_coordinates())
	
func get_coordinates() -> Vector2:
	return tile_grid.world_to_map(tile_grid.to_local(global_position))

func we_have_los_to_player() -> bool:
	var player_location = player.get_coordinates()
	var our_location = get_coordinates()
	
	# if we are lined up in y axis, check if there are walls in between
	if player_location.y == our_location.y:
		
		var lesserX
		var greaterX
		if player_location.x < our_location.x:
			lesserX = player_location.x
			greaterX = our_location.x
		else:
			lesserX = our_location.x
			greaterX = player_location.x
		
		# if there's any wall in between, return false
		for x in range(lesserX+1, greaterX):
			if !tile_grid.get_tile(x, player_location.y).passable:
				return false

		# else return true
		return true
		
	# if we are lined up in x axis, check if there are walls in between
	elif player_location.x == our_location.x:
		var lesserY
		var greaterY
		if player_location.y < our_location.y:
			lesserY = player_location.y
			greaterY = our_location.y
		else:
			lesserY = our_location.y
			greaterY = player_location.y
		
		# if there's any wall in between, return false
		for y in range(lesserY + 1, greaterY):
			if !tile_grid.get_tile(player_location.x, y).passable:
				return false

		# else return true
		return true
	
	# if we were not lined up along either axis, return false
	return false

func manhattan_distance(vectorA: Vector2, vectorB: Vector2) -> float:
	return abs(vectorA.x - vectorB.x) + abs(vectorA.y - vectorB.y)

func find_best_path_to_player():
	var player_location = player.get_coordinates()
	var our_location = get_coordinates()
	
	var player_tile = tile_grid.get_tilev(player_location)
	var our_tile = tile_grid.get_tilev(our_location)
	
	# always follow into the player's last inhabited tile if it is adjacent to us
	if ppt != null && ppt.passable && ppt.occupant == null:
		if ppt.xPos == our_tile.xPos:
			if ppt.yPos == our_tile.yPos + 1 || ppt.yPos == our_tile.yPos - 1:
				return ppt
		if ppt.yPos == our_tile.yPos:
			if ppt.xPos == our_tile.xPos + 1 || ppt.xPos == our_tile.xPos - 1:
				return ppt
	
	var unvisited_nodes = { our_tile: true, player_tile: true }
	var shortest_path = {}
	var previous_nodes = {}
	
	for tile in tile_grid.Grid:
		if tile.passable && (tile.occupant == null):
			unvisited_nodes[tile] = true
			shortest_path[tile] = INF
	shortest_path[our_tile] = 0
	shortest_path[player_tile] = INF # remember player tile has an occupant, but we must treat it as traversable
	
	while !unvisited_nodes.empty():
		var current_min_node = null
		
		for tile in unvisited_nodes.keys():
			if (current_min_node == null):
				current_min_node = tile
			elif shortest_path[tile] < shortest_path[current_min_node]:
				current_min_node = tile
			
		var neighbouring_tiles = [
			tile_grid.get_tile(current_min_node.xPos + 1, current_min_node.yPos),
			tile_grid.get_tile(current_min_node.xPos - 1, current_min_node.yPos),
			tile_grid.get_tile(current_min_node.xPos, current_min_node.yPos + 1),
			tile_grid.get_tile(current_min_node.xPos, current_min_node.yPos - 1)
		]
		
		for nt in neighbouring_tiles:
			if nt != null && shortest_path.has(nt): # (all traversable tiles are in shortest path)
				var tentative_value = shortest_path[current_min_node] + 1
				if (tentative_value < shortest_path[nt]):
					shortest_path[nt] = tentative_value
					previous_nodes[nt] = current_min_node
		
		unvisited_nodes.erase(current_min_node)
		
	if previous_nodes.has(player_tile):
		var curr = player_tile
		while previous_nodes[curr] != our_tile:
			curr = previous_nodes[curr]
		print("we are on " + str(our_tile.xPos) + "," + str(our_tile.yPos))
		print("best path to target is to move to " + str(curr.xPos) + "," + str(curr.yPos))
		return curr
	else:
		return null
	
# each turn: move, THEN determine if player is in darkness, and if so turn off alert.
func _on_Player_moved():
	if !_alive:
		return
	
	var chase_player := false
	
	# when in  idle mode, check if the player is seen and move to alerting mode if so
	if mode == SEARCHING:
		var player_found = player.is_in_light() && we_have_los_to_player()
		if player_found:
			alert_player.play()
			play("alert")
			mode = ALERTING
	
	# alerting mode is just used to delay the chase by 1 turn, when in alerting mode always move to chasing mode
	# unless the player is already in the shadows (in which case move to finalizing chase)
	elif mode == ALERTING:
		if player.is_in_light():
			mode = CHASING
		else:
			mode = FINALIZING_CHASE
	
	# when in chasing mode, move along best available path to player unless they are in the shadows 
	# (in which case move to finalizing chase)
	elif mode == CHASING:
		chase_player = true
		if !player.is_in_light():
			mode = FINALIZING_CHASE

	# finalizing_chase mode is just used to make the enemy move towards the player one last time before 
	elif mode == FINALIZING_CHASE:
		chase_player = true
		mode = SEARCHING
		dealert_player.play()
		play("idle")
		
	# move towards the player by 1 tile according to best path available
	if chase_player:
		var move_to_tile = find_best_path_to_player()
		if move_to_tile != null:
			var old_tile = get_occupied_tile()
			old_tile.occupant = null
			if move_to_tile.occupant != null:
				move_to_tile.occupant.kill()
			move_to_tile.occupant = self
			
			var old_position = global_position
			print(old_position)
			print("x: " + str(move_to_tile.xPos) + " y: " + str(move_to_tile.yPos))
			global_position = Vector2(
				old_position.x + (Constants.TILE_SIZE * (move_to_tile.xPos - old_tile.xPos)),
				old_position.y + (Constants.TILE_SIZE * (move_to_tile.yPos - old_tile.yPos))
			)
				
		else:
			# it is possible for enemies to be stuck. if they become stuck, they will execute this code
			pass
	
	ppt = tile_grid.get_tilev(player.get_coordinates())

func kill():
	if _alive:
		_alive = false
		get_occupied_tile().occupant = null
		self.play("explode")
		yield(self, "animation_finished")
		self.visible = false
		self.queue_free()
