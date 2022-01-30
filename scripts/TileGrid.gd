class_name TileGrid
extends TileMap

# var tile_set := self.tile_set as TileSet

var max_x := 0
var max_y := 0
var Grid := []
var tileprefab;

func coord2idx(x: int, y: int) -> int:
	return x + (y * max_x)
	
func idx2coord(idx: int) -> Vector2:
	return Vector2(idx % max_x, idx / max_x)
	
func get_tile(x: int, y: int) -> Tile:
	return Grid[coord2idx(x, y)]

func coord_is_passable(x: int, y: int) -> bool:
	var tile := Grid[coord2idx(x, y)] as Tile
	return !tile.wall_tile && tile.passable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var used_cells := self.get_used_cells()
	
	# determine dimensions of the grid
	for cell in used_cells:
		var x := cell[0] as int
		var y := cell[1] as int
		if (x > max_x):
			max_x = x
		if (y > max_y):
			max_y = y
	
	# instantiate array of correct size
	Grid.resize(coord2idx(max_x, max_y) + 1)
	
	tileprefab = preload("res://Tile.tscn")
	for cell in used_cells:
		var x := cell[0] as int
		var y := cell[1] as int
		var t := tileprefab.instance() as Tile
		
		var tile_set_tile_idx := get_cell(x, y)
		var shape_count := tile_set.tile_get_shape_count(tile_set_tile_idx)
		
		t.xPos = x
		t.yPos = y
		t.wall_tile = shape_count > 0
		
		add_child(t)
		Grid[coord2idx(x, y)] = t
		
	pass


func toggle_light() -> void:
	for i in range(Grid.size()):
		var tile := Grid[i] as Tile
		if tile.light_toggles:
			tile.isLit = not tile.isLit
			var coord := idx2coord(i)
			var cell := self.get_cellv(coord)
			var name := self.tile_set.tile_get_name(cell)
			print_debug("Light toggles at index %d, coordinates %s, initial tile %s" % [i, coord, name])
			if name.ends_with("_dark") or name.ends_with("_light"):
				name = name.trim_suffix("_dark").trim_suffix("_light")
				if tile.isLit:
					name += "_light"
				else:
					name += "_dark"
				print_debug("change name to ", name)
				cell = self.tile_set.find_tile_by_name(name)
				self.set_cellv(coord, cell)
