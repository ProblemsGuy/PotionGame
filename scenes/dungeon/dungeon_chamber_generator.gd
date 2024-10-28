extends Node2D

@onready var MAIN_NODE = get_parent();
var TILE_SIZE = Gamedefaults.TILE_SIZE;
var tileNode : PackedScene;
var dungeonOffset = Vector2(16,16);
var startPoint : Vector2;
var chamberId : int;
var chamberScale;
var active := false;

signal complete;

func calculateCurrentTileVector():
	return (global_position-dungeonOffset)/TILE_SIZE;

func findRelativePosition():
	return calculateCurrentTileVector() - startPoint;

func moveToTile(tile: Vector2):
	global_position = (TILE_SIZE*tile)+dungeonOffset;

func spawnNodeHere(nodeType,nodeName):
	var newNode = nodeType.instantiate();
	newNode.global_position = global_position;
	newNode.name = nodeName+str(calculateCurrentTileVector());
	newNode.add_to_group("Floor");
	newNode.add_to_group("Chamber");
	if chamberId == 0:
		newNode.add_to_group("FirstChamber");
	MAIN_NODE.add_child(newNode);
	return newNode;

func _process(_delta):
	if active:
		var currentPosition = calculateCurrentTileVector();
		var currentRelativePosition = findRelativePosition();
		var atNorth = currentRelativePosition.y == 0;
		var atWest = currentRelativePosition.x == 0;
		var atEast = currentRelativePosition.x == chamberScale[0]-1
		var atSouth = currentRelativePosition.y == chamberScale[1]-1
		
		var newFloor : Node = spawnNodeHere(tileNode,"DungeonFloor");
		
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

