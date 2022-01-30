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

const MAX_INT := 9223372036854775807
const PRINT_DEBUG := false

const SEARCHING := "SEARCHING"
const CHASING := "CHASING"

var _alive := true
var mode := SEARCHING
var ppt = null # Vector2 that always saves the player's previous location (unused but pls dont delete i may need it later)

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

class NodePathData:
	var shortest_path_value: int
	var shortest_path_predecessors: Array
	var tile: Tile

	func _init(_tile: Tile, is_origin: bool):
		tile = _tile
		if (is_origin):
			shortest_path_value = 0
		else:
			shortest_path_value = MAX_INT
		shortest_path_predecessors = []

	# returns the value of the current shortest path(s) to this node
	# returns 0 if this is origin and MAX_INT if no path has been found to this node yet
	func current_best() -> int:
		return shortest_path_value
		
	func is_origin() -> bool:
		return shortest_path_value == 0

	func consider_path(value: int, predecessor: NodePathData) -> void:
		if value < shortest_path_value:
			# if this path beats our current path(s), replace the list entirely
			shortest_path_value = value
			shortest_path_predecessors = [ predecessor ]
		elif value == shortest_path_value:
			# if this path is just tied with current path(s) we already know of, just add to the list
			shortest_path_predecessors.push_back(predecessor)

func find_best_path_to_player():
	var player_location = player.get_coordinates()
	var our_location = get_coordinates()
	
	var player_tile = tile_grid.get_tilev(player_location)
	var our_tile = tile_grid.get_tilev(our_location)
	
	var unvisited_nodes = { our_tile: true }
	var shortest_paths = {}
	
	for tile in tile_grid.Grid:
		if tile != our_tile && tile.passable:
			unvisited_nodes[tile] = true
			shortest_paths[tile] = NodePathData.new(tile, false)
	shortest_paths[our_tile] = NodePathData.new(our_tile, true)
	
	while !unvisited_nodes.empty():
		var current_min_node = null
		
		for tile in unvisited_nodes.keys():
			if (current_min_node == null):
				current_min_node = tile
			elif shortest_paths[tile].current_best() < shortest_paths[current_min_node].current_best():
				current_min_node = tile
			
		var neighbouring_tiles = [
			tile_grid.get_tile(current_min_node.xPos + 1, current_min_node.yPos),
			tile_grid.get_tile(current_min_node.xPos - 1, current_min_node.yPos),
			tile_grid.get_tile(current_min_node.xPos, current_min_node.yPos + 1),
			tile_grid.get_tile(current_min_node.xPos, current_min_node.yPos - 1)
		]
		
		for nt in neighbouring_tiles:
			if nt != null && shortest_paths.has(nt): # (all traversable tiles are in shortest_paths)
				var tentative_value = shortest_paths[current_min_node].current_best() + 1
				shortest_paths[nt].consider_path(tentative_value, shortest_paths[current_min_node])
		
		unvisited_nodes.erase(current_min_node)
		
	if shortest_paths[player_tile].current_best() < MAX_INT:
		var valid_initial_moves = {}
		
		var paths_considered = [ shortest_paths[player_tile] ]
		while !paths_considered.empty():
			var this_node_path_data = paths_considered.pop_back()
			for predecessor_node_path_data in this_node_path_data.shortest_path_predecessors:
				paths_considered.push_back(predecessor_node_path_data)
				if (predecessor_node_path_data.is_origin()):
					valid_initial_moves[this_node_path_data.tile] = this_node_path_data
				
		if PRINT_DEBUG:
			print("we are on " + str(our_tile.xPos) + "," + str(our_tile.yPos))
			
		for valid_initial_move in valid_initial_moves.values():
			var tile = valid_initial_move.tile
			
			if PRINT_DEBUG:
				print("a best path to target is to move to " + str(tile.xPos) + "," + str(tile.yPos))

		# we will need to analyze the possible moves we can start with vs our axis preference
		var moves = valid_initial_moves.values()
		
		# if pref axis is x, find a move that keeps y constant, and vice versa if pref axis is y
		for move in moves:
			if move.tile.yPos == our_location.y && preferredAxis == "x":
				return move.tile
			if move.tile.xPos == our_location.x && preferredAxis == "y":	
				return move.tile
		
		# otherwise just return one of the moves
		return moves[0].tile
	else:
		return null
	
# each turn: move, THEN determine if player is in darkness, and if so turn off alert.
func _on_Player_moved():
	if !_alive:
		return
	
	var move_towards_player := false
	
	# when in  idle mode, check if the player is seen and move to chasing  mode if so
	if mode == SEARCHING:
		var player_found = player.is_in_light() && we_have_los_to_player()
		if player_found:
			alert_player.play()
			play("alert")
			mode = CHASING
	
	# when in chasing mode, move along best available path to player unless they are in the shadows 
	# (in which case move to finalizing chase)
	elif mode == CHASING:
		move_towards_player = true
		if !player.is_in_light():
			dealert_player.play()
			play("idle")
			mode = SEARCHING
		
	# move towards the player by 1 tile according to best path available
	if move_towards_player:
		var move_to_tile = find_best_path_to_player()
		if move_to_tile != null && (move_to_tile.occupant == null || move_to_tile.occupant == player):
			var old_tile = get_occupied_tile()
			old_tile.occupant = null
			if move_to_tile.occupant != null:
				move_to_tile.occupant.kill(false)
			move_to_tile.occupant = self

			var old_position = global_position
			
			if PRINT_DEBUG:
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

func kill(_killed_by_door: bool):
	if _alive:
		_alive = false
		get_occupied_tile().occupant = null
		self.play("explode")
		if _killed_by_door:
			$MonsterDieDoor.play()
		yield(self, "animation_finished")
		self.visible = false
		self.queue_free()
