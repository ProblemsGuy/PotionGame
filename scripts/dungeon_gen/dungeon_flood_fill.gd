extends Node2D

@onready var gridNode:MovementGrid = get_parent();
var openList = [];
var closedList = [];
var TILE_SIZE = Gamedefaults.TILE_SIZE;
var wallNode: PackedScene;
var gridType = 3;

signal completed;

const directions = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]

func spawnNodeHere(nodeType,direction):
	var currentTile = gridNode.local_to_map(global_position);
	var newNode = gridNode.createSceneAtGridPoint(nodeType,currentTile+direction);
	return newNode;

func moveToTile(tile:Vector2):
	global_position = gridNode.warpChildPosition(self,Vector2i(tile));

func calculateCurrentTileVector():
	return gridNode.local_to_map(global_position);

func getNeighbours():
	var currentTile = calculateCurrentTileVector();
	var returnList = []
	for value in directions:
		var currentDirection = currentTile + value;
		if gridNode.entity_grid[currentDirection.x][currentDirection.y] == 4:
			returnList.append(currentDirection);
	return returnList;

func getNewNeighbours():
	var neighbours = getNeighbours();
	for value in neighbours:
		if !closedList.has(value):
			if !openList.has(value):
				openList.append(value);

func initSelf():
	z_index =2000;
	var startList = getNeighbours();
	openList.append_array(startList);

func generateWalls():
	var currentTile = calculateCurrentTileVector();
	for value in directions:
		var currentDirection = currentTile + value;
		if gridNode.entity_grid[currentDirection.x][currentDirection.y] == null:
			spawnNodeHere(wallNode,value);

func adjustLists():
	var currentTile = calculateCurrentTileVector();
	closedList.append(currentTile);
	openList.erase(currentTile);
	gridNode.node_grid[currentTile.x][currentTile.y].add_to_group("Found");

var state = "init";
func _physics_process(_delta):
	if state=="init":
		initSelf();
		state = "null";
	
	if state == "null":
		generateWalls();
		adjustLists();
		while openList.size() > 0:
			moveToTile(openList[0]);
			getNewNeighbours();
			generateWalls();
			adjustLists();
		state = "";
	else:
		emit_signal("completed");
		queue_free();
		
