extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const GRID_HEIGHT=9
const GRID_WIDTH=16
var Grid = []
# these are sample numbers based on my 64x64 tilemap.  If the size of the tiles changes or
# you need more, change these.

# Called when the node enters the scene tree for the first time.
func _ready():
	for n in range(GRID_WIDTH):
		var Subgrid = []
		for m in range(GRID_HEIGHT):
			var t = tileprefab.Tile(false,n,m,false,true)
			#add_child(t)
			#Subgrid.append(t)
			# The intent here is to add an instance of the Tile class to the grid for each tile.
		Grid.append(Subgrid)
	print(Grid)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
