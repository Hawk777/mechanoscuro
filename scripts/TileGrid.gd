extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const GRID_HEIGHT=9
const GRID_WIDTH=16
var Grid = []
var tileprefab;
# these are sample numbers based on my 64x64 tilemap.  If the size of the tiles changes or
# you need more, change these.

# Called when the node enters the scene tree for the first time.
func _ready():
	tileprefab= preload("res://Tile.tscn")
	for n in range(GRID_WIDTH):
		var Subgrid = []
		for m in range(GRID_HEIGHT):
			var t = tileprefab.instance()
			t.xPos=n
			t.yPos=m
			# t.position=get_node("TileMap").map_to_world(Vector2(n,m))
			# The above line doesn't work right now, not sure how to fix it.
			# TODO:
			# The intent is to have all of the above Tiles visible at runtime, then disable them when the player is close enough to show the level underneath
			# To that end, whenever the player moves, check against each tile in Grid to see if the player is close enough (2 or 3 tiles maybe?) and set visible to false.
			# In the absolute worst case, we'll need to set the world coordinates for all of these when the level starts, as well as the states for each tile (passable, contains a lightswitch, etc.)
			add_child(t)
			Subgrid.append(t)
		Grid.append(Subgrid)
	#print(Grid)
	print(Grid[12][3].xPos)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
