extends Sprite

# The possible values of a pixel in this node’s texture.
# The pixel values are used to communicate to the shader, not for actual display.
enum _PixelValue {
	# The tile is rendered normally.
	NORMAL = 255,
	# The tile is remembered but not visible, so it is blurred.
	BLURRED = 128,
	# The tile is unknown, so it is blacked out.
	BLACK = 0,
}

export(NodePath) var tile_grid_path: NodePath
export(NodePath) var player_path: NodePath
export(float) var blurred_mipmap_lod := 1.0

onready var _tile_grid := get_node(tile_grid_path) as TileGrid
onready var _player := get_node(player_path) as Player
onready var _camera := _player.get_node("Camera2D") as Camera2D

# The image used to communicate bulk data to the shader.
#
# This image contains one 8-bit pixel per tile in the tilemap.
# The pixel value is one of the _PixelValue values.
var _image := Image.new()
# Whether an update needs to be performed.
var _dirty := true


func _ready() -> void:
	# Update static shader parameters.
	material.set_shader_param("blurred_mipmap_lod", blurred_mipmap_lod)

	# Create the image that stores the fog data and fill it with all BLACK.
	var dimensions := _tile_grid.get_used_rect().size
	_image.create(dimensions.x as int, dimensions.y as int, false, Image.FORMAT_L8)
	_image.fill(Color8(_PixelValue.BLACK, 0, 0))

	# Create a texture that can be loaded with the image.
	texture = ImageTexture.new()
	(texture as ImageTexture).create(_image.get_width(), _image.get_height(), _image.get_format(), 0)

	# Ask to be pinged whenever lighting changes and whenever the player or an enemy moves.
	_tile_grid.connect("lighting_changed", self, "refresh")
	_player.connect("moved", self, "refresh")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.connect("moved", self, "refresh")


func _process(_delta: float) -> void:
	# Update dynamic shader parameters.
	var _screen_size := get_viewport().size
	var _camera_aimed_at := _camera.get_camera_screen_center()
	var _top_left_corner := _camera_aimed_at - _screen_size / 2
	# The shader starts with a UV coordinate in the range [0, 1].
	# We consider the case after the inversion of Y coordinate.
	# The point is in screenspace, so 0 means it points at the pixel _top_left_corner.
	# 1 means it points at the bottom right corner pixel.
	# UV × screen_size gives the actual screenspace pixel being shaded.
	# UV × screen_size + TLC gives the worldspace pixel being shaded.
	# UV × screen_size + TLC - tilemap.origin gives the tilemapspace pixel being shaded.
	# floor((UV × screen_size + TLC - tilemap.origin) ÷ TILE_SIZE) gives the tile being shaded.
	#
	# The shader, for efficiency, just calculates floor(UV × scale + offset).
	# Converting the above expression to that form:
	#
	# floor((UV × screen_size + TLC - tilemap.origin) ÷ TILE_SIZE)
	# = floor(UV × screen_size ÷ TILE_SIZE + TLC ÷ TILE_SIZE - tilemap.origin ÷ TILE_SIZE)
	# = floor(UV × (screen_size ÷ TILE_SIZE) + ((TLC - tilemap.origin) ÷ TILE_SIZE))
	material.set_shader_param("screen_scale", _screen_size / Constants.TILE_SIZE)
	material.set_shader_param("screen_offset", (_top_left_corner - _tile_grid.transform.get_origin()) / Constants.TILE_SIZE)

	# Refresh the fog if needed.
	_refresh()


func refresh() -> void:
	# Mark the fog of war as dirty and needing updating.
	# The actual recalculation will happen on the next _process call.
	# This allows multiple requests (e.g. player moved *and* lighting toggled) to be coalesced.
	_dirty = true


func _refresh() -> void:
	if _dirty:
		# Determine the player’s tile location and view distance.
		# Rule: if the tile the player is standing on is lit, the view distance is 4; otherwise, 2.
		var player_grid := _player.get_coordinates()
		var player_tile := _tile_grid.get_tilev(player_grid)
		var view_distance_squared: float
		if player_tile.isLit:
			view_distance_squared = 4.0 * 4.0
		else:
			view_distance_squared = 2.0 * 2.0

		# Go through all the tiles and update their visibility state.
		_image.lock()
		for t in _tile_grid.Grid:
			var tile := t as Tile
			var tile_grid := Vector2(tile.xPos, tile.yPos)
			if player_grid.distance_squared_to(tile_grid) <= view_distance_squared:
				# This tile is within view distance.
				# It is fully visible and the player remembers it.
				tile.remembered = true
				_image.set_pixelv(tile_grid, Color8(_PixelValue.NORMAL, 0, 0))
				if tile.occupant != null:
					tile.occupant.visible = true
			elif tile.remembered:
				# This tile is not currently visible, but the player remembers it.
				_image.set_pixelv(tile_grid, Color8(_PixelValue.BLURRED, 0, 0))
				if tile.occupant != null:
					tile.occupant.visible = false
			else:
				# The player knows nothing about this tile.
				_image.set_pixelv(tile_grid, Color8(_PixelValue.BLACK, 0, 0))
		_image.unlock()

		# Ship the new data to the shader.
		(texture as ImageTexture).set_data(_image)

		# Clear the dirty flag.
		_dirty = false
