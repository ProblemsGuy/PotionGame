extends Area2D

@onready var MAIN_NODE = get_parent().get_child(0);
var openList = [];
var closedList = [];
var dungeonOffset := Vector2(16,16);
var TILE_SIZE = Gamedefaults.TILE_SIZE;
var wallNode: PackedScene;

signal completed;

func spawnNodeHere(nodeType,direction):
	var newNode = nodeType.instantiate();
	newNode.global_position = global_position+(direction*TILE_SIZE);
	MAIN_NODE.add_child(newNode);
	return newNode;

func calculateTileVector(tile:Node):
	return (tile.global_position-dungeonOffset)/TILE_SIZE;

func initSelf():
	z_index =2000;
	var startList = get_overlapping_areas();
	openList.append_array(startList);

var currentTile:Node;
func stepForward():
	
	currentTile.add_to_group("Found");
	closedList.append(currentTile);
	openList.remove_at(0);

func determineWallsNeeded(surroundingSpaces):
	var westSpace = true;
	var northSpace = true;
	var southSpace = true;
	var eastSpace = true;
	var currentVector = calculateTileVector(currentTile);
	
	for value in surroundingSpaces:
		var positionVector = calculateTileVector(value);
		if positionVector.x < currentVector.x:
			westSpace = false;
		elif positionVector.x > currentVector.x:
			eastSpace = false;
		elif positionVector.y < currentVector.y:
			northSpace = false;
		elif positionVector.y > currentVector.y:
			southSpace = false;
	
	if northSpace:
		spawnNodeHere(wallNode,Vector2(0,-1));
		#currentTile.get_child(0).color += Color(0.5,0,0);
	if eastSpace:
		spawnNodeHere(wallNode,Vector2(1,0));
		#currentTile.get_child(0).color += Color(0.5,0,0.5);
	if southSpace:
		spawnNodeHere(wallNode,Vector2(0,1));
		#currentTile.get_child(0).color += Color(0,0.5,0);
	if westSpace:
		spawnNodeHere(wallNode,Vector2(-1,0));
		#currentTile.get_child(0).color += Color(0,0,0.5);

func getSurroundingTiles():
	var surroundingTiles = get_overlapping_areas();
	currentTile.get_child(0).color = Color(0,1,0);
	if surroundingTiles.size() != 5:
		determineWallsNeeded(surroundingTiles);
	
	for value in surroundingTiles:
		if value.name.contains("DungeonFloor"):
			if !closedList.has(value):
				if !openList.has(value):
					openList.append(value);

var state = "init";
func _physics_process(_delta):
	if state=="init":
		await get_tree().physics_frame
		initSelf();
		state = "null";
	
	if openList.size() > 0:
		currentTile = openList[0];
		global_position = currentTile.global_position
		await get_tree().physics_frame
		getSurroundingTiles();
		stepForward();
		
	else:
		emit_signal("completed");
		queue_free();
		
	
