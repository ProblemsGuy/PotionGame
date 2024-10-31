extends Node2D

@onready var gridNode = get_parent();
var TILE_SIZE = Gamedefaults.TILE_SIZE;
var tileNode : PackedScene;
var startPoint : Vector2;
var chamberId : int;
var chamberScale;
var active := false;
const gridType = 3;

signal complete;

func calculateCurrentTileVector():
	return gridNode.local_to_map(global_position);

func findRelativePosition():
	return calculateCurrentTileVector() - Vector2i(startPoint);

func moveToTile(tile: Vector2):
	global_position = gridNode.warpChildPosition(self,Vector2i(tile));

func spawnNodeHere(nodeType):
	var newNode = gridNode.createSceneAtLocalPoint(nodeType,global_position);
	newNode.add_to_group("Floor");
	newNode.add_to_group("Chamber");
	return newNode;

func _process(_delta):
	if active:
		var currentPosition = calculateCurrentTileVector();
		var currentRelativePosition = findRelativePosition();
		var atNorth = currentRelativePosition.y == 0;
		var atWest = currentRelativePosition.x == 0;
		var atEast = currentRelativePosition.x == chamberScale[0]-1
		var atSouth = currentRelativePosition.y == chamberScale[1]-1
		
		var newFloor : Node = spawnNodeHere(tileNode);
		
		if atNorth:
			newFloor.add_to_group("Chamber"+str(chamberId)+"North");
		if atEast:
			newFloor.add_to_group("Chamber"+str(chamberId)+"East");
		if atSouth:
			newFloor.add_to_group("Chamber"+str(chamberId)+"South");
		if atWest:
			newFloor.add_to_group("Chamber"+str(chamberId)+"West");
		
		if atEast and atSouth:
			emit_signal("complete")
			queue_free();
		elif atEast:
			moveToTile(Vector2(startPoint.x,currentPosition.y+1));
		else:
			moveToTile(Vector2(currentPosition.x+1,currentPosition.y));

