extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
class_name Tile

var isLit = false;
var xPos;
var yPos;
var isOccupied=false;
var passable=true;

func Tile(var lit, var x,var y,var occ,var p):
	isLit=lit
	xPos=x
	yPos=y
	isOccupied=occ
	passable=p


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
