extends Node2D

@onready var gridNode = get_parent();
var tileNode : PackedScene;
var startPoint:Node;
var endPoint:Node;
var mode:String;
var dungeonOffset:Vector2;
var TILE_SIZE = Gamedefaults.TILE_SIZE;
var state:String;

var startVector:Vector2;
var endVector:Vector2;
var midVector1:Vector2;
var midVector2:Vector2;
var currentDirection:Vector2;
const gridType = 3;

signal complete;

func spawnNodeHere(nodeType):
	var newNode = gridNode.createSceneAtLocalPoint(nodeType,global_position);
	newNode.add_to_group("Floor");
	return newNode;

func calculateCurrentTileVector():
	return (global_position-dungeonOffset)/TILE_SIZE;

func findRelativePosition():
	return calculateCurrentTileVector() - startPoint;

func moveToTile(tile: Vector2):
	global_position = (TILE_SIZE*tile)+dungeonOffset;

func getStartEndVectors():
	startVector = calculateCurrentTileVector();
	global_position = endPoint.global_position;
	endVector = calculateCurrentTileVector();

func calculateMidPoint():
	if mode == "HORIZONTAL":
		var xDistance = endVector.x - startVector.x;
		if xDistance < 4:
			midVector1 = startVector + Vector2(2,0);
		else: 
			midVector1 = startVector + Vector2(randi_range(2,xDistance-2),0);
		midVector2 = Vector2(midVector1.x,endVector.y);
	if mode == "VERTICAL":
		var yDistance =  endVector.y - startVector.y;
		if yDistance < 4:
			midVector1 = startVector + Vector2(0,2);
		else: 
			midVector1 = startVector + Vector2(0,randi_range(2,yDistance-2));
		midVector2 = Vector2(endVector.x,midVector1.y);

func setStartDirection():
	if mode == "HORIZONTAL":
		currentDirection = Vector2(1,0);
	if mode == "VERTICAL":
		currentDirection = Vector2(0,1);

func turnDirection():
	if mode == "HORIZONTAL":
		if startVector.y < endVector.y:
			currentDirection = Vector2(0,1);
		else:
			currentDirection = Vector2(0,-1);
	if mode == "VERTICAL":
		if startVector.x < endVector.x:
			currentDirection = Vector2(1,0);
		else:
			currentDirection = Vector2(-1,0);

var currentPosition:Vector2;
func _process(_delta):
	if state == "active":
		getStartEndVectors();
		calculateMidPoint();
		setStartDirection();
		moveToTile(startVector);
		currentPosition = calculateCurrentTileVector()
		state = "building";
	
	if state == "building":
		
		moveToTile(currentPosition+currentDirection);
		currentPosition = calculateCurrentTileVector()
		
		if midVector1 == currentPosition:
			turnDirection();
		if midVector2 == currentPosition:
			setStartDirection();
		if endVector == currentPosition:
			emit_signal("complete");
			queue_free();
			return;
		
		spawnNodeHere(tileNode)
