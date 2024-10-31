extends Node2D

#These should stay the same no matter what
@onready var gridNode:MovementGrid = get_parent().get_child(0);
const TILE_SIZE = Gamedefaults.TILE_SIZE;
const NORTH = 0;
const EAST = 1;
const SOUTH = 2;
const WEST = 3;
const gridType = 3;

## The PackedScene that is used for walls; change to change wall appearance.
@export var wallNode:PackedScene = preload("res://scenes/dungeon/dungeon_wall.tscn");
## The PackedScene that is used for floors; change to change floor appearance.
@export var floorNode:PackedScene = preload("res://scenes/dungeon/dungeon_floor.tscn");

var chamberNode:PackedScene = preload("res://scenes/dungeon/generators/dungeon_chamber_generator.tscn");
var corridorNode:PackedScene = preload("res://scenes/dungeon/generators/dungeon_corridor_generator.tscn");
var fillNode:PackedScene = preload("res://scenes/dungeon/generators/dungeon_flood_fill.tscn")

## The tile width which the room should be generated too
@onready var roomTileWidth:int = gridNode.grid_size.x; 
## The tile height which the room should be generated too
@onready var roomTileHeight:int = gridNode.grid_size.y;
## The number of vertical slices of the level for room gen.
## Must be a factor of roomTileWidth
@export var roomXSlices := 8; 
## The number of horizontal slices of the level for room gen
## Must be a factor of roomTileHeight
@export var roomYSlices := 8;

@onready var roomSliceWidth = roomTileWidth/roomXSlices;
@onready var roomSliceHeight = roomTileHeight/roomYSlices;
@onready var numberOfSlices = roomXSlices*roomYSlices;

## How many rooms should be generated
@export var chamberQuanity := 47;
#CONSIDER REPLACING - Could just be a random range for both variable
## Tile shapes that the rooms can be
@export var chamberScales := [[6,6]]; 
@export var corridorQuantity := 100;


func arrayTotal(array):
	var total = 0;
	for value in array:
		if value != 0:
			total += 1;
	return total;

func chamberArrayGenerator(bitSize,length):
	if(bitSize > length):
		push_error("INVALID CHAMBER QUANTITY ENTERED");
		get_tree().quit();
	
	var chamberList = [];
	chamberList.resize(length);
	chamberList.fill(0);
	
	while(arrayTotal(chamberList) != bitSize):
		chamberList[randi_range(0,length-1)] = randi_range(1,chamberScales.size());
	
	for i in range(0,chamberList.size()):
		chamberList[i] -= 1;
	
	return chamberList;

func calculateCurrentTileVector():
	return gridNode.local_to_map(global_position);

func moveToTile(tile: Vector2):
	global_position = gridNode.warpChildPosition(self,Vector2i(tile));

func moveToNode(tile: Node):
	global_position = gridNode.warpChildPositionLocal(self,Vector2i(tile.global_position));

func findValidChamberArea(chamberId, chamberScale):
	var sliceCoordinate= Vector2(chamberId%roomXSlices,int(chamberId)/int(roomXSlices));
	var veryTopLeft = sliceCoordinate*Vector2(roomSliceWidth,roomSliceHeight);
	var veryBottomRight = veryTopLeft+Vector2(roomSliceWidth-1,roomSliceHeight-1);
	var topLeftCorner = veryTopLeft + Vector2(1,1);
	var bottomRightCorner = veryBottomRight - Vector2(chamberScale[0]+1,chamberScale[1]+1);
	return [topLeftCorner,bottomRightCorner];

func pickTileInArea(topLeftCorner,bottomRightCorner):
	return Vector2(randi_range(topLeftCorner.x,bottomRightCorner.x),randi_range(topLeftCorner.y,bottomRightCorner.y));

func spawnNodeHere(nodeType,nodeName):
	var newNode = gridNode.createGeneratorAtLocalPoint(nodeType,global_position);
	return newNode;

func spawnChamberGenerator(chamberId,chamberScale):
	var newGenerator = spawnNodeHere(chamberNode,"DungeonChamberGenerator");
	newGenerator.chamberId = chamberId;
	newGenerator.chamberScale = chamberScale;
	newGenerator.tileNode = floorNode;
	newGenerator.startPoint = calculateCurrentTileVector();
	newGenerator.active = true;
	newGenerator.complete.connect(_on_complete);

var completedRooms = 0;
func _on_complete():
	completedRooms += 1;

func makeAChamber(chamberId,chamberScale):
	var validChamberArea = findValidChamberArea(chamberId,chamberScale);
	var chosenTile = pickTileInArea(validChamberArea[0],validChamberArea[1]);
	moveToTile(chosenTile);
	spawnChamberGenerator(chamberId,chamberScale);

func calculateNumberOfCorridors():
	return (roomXSlices*(roomYSlices-1))+(roomYSlices*(roomXSlices-1));

func createCorridorList():
	var corridorList=[];
	corridorList.resize(calculateNumberOfCorridors());
	
	var corridorPointer = 0;
	for i in range(0,numberOfSlices-1):
		if i%roomXSlices==roomXSlices-1:
			corridorList[corridorPointer]=[i,i+roomXSlices];
			corridorPointer +=1;
		elif i>= roomXSlices*(roomYSlices-1):
			corridorList[corridorPointer]=[i,i+1];
			corridorPointer +=1;
		else:
			corridorList[corridorPointer]=[i,i+1];
			corridorPointer +=1;
			corridorList[corridorPointer]=[i,i+roomXSlices];
			corridorPointer +=1;
	return corridorList;	

var corridorsCreated = 0;
var corridorsCompleted = 0;
func onCorridorComplete():
	corridorsCompleted += 1;

func generateCorridor(corridor):
	var mode = "VERTICAL";
	if corridor[0]+1 == corridor[1]:
		mode = "HORIZONTAL";
	
	var randomStartTile;
	var randomEndTile;
	if mode == "HORIZONTAL":
		randomStartTile = get_tree().get_nodes_in_group("Chamber"+str(corridor[0])+"East").pick_random();
		randomEndTile = get_tree().get_nodes_in_group("Chamber"+str(corridor[1])+"West").pick_random();
	else:
		randomStartTile = get_tree().get_nodes_in_group("Chamber"+str(corridor[0])+"South").pick_random();
		randomEndTile = get_tree().get_nodes_in_group("Chamber"+str(corridor[1])+"North").pick_random();
	
	global_position = randomStartTile.global_position;
	var newCorridor = spawnNodeHere(corridorNode,"DungeonCorridorGenerator");
	newCorridor.tileNode = floorNode;
	newCorridor.startPoint = randomStartTile;
	newCorridor.endPoint = randomEndTile;
	newCorridor.mode = mode;
	newCorridor.state = "active";
	newCorridor.complete.connect(onCorridorComplete);
	corridorsCreated += 1;

var floodCompleted = false;
func onFloodCompleted():
	floodCompleted = true;

func spawnFloodFill():
	var newNode = spawnNodeHere(fillNode,"DungeonFloodFill");
	newNode.global_position = global_position;
	newNode.wallNode = wallNode;
	newNode.completed.connect(onFloodCompleted);
	return newNode;

var state = "init";
var currentChamberId = 0;
var chamberList = [];
var corridorList = [];
func _process(_delta):
	
	if state == "init":
		chamberList = chamberArrayGenerator(chamberQuanity,numberOfSlices);
		corridorList = createCorridorList();
		state = "chamber"
		
	if state == "chamber":
		var currentScale = [1,1];
		var currentScaleIndex = chamberList[currentChamberId];
		if currentScaleIndex != -1:
			currentScale = chamberScales[currentScaleIndex];
		makeAChamber(currentChamberId,currentScale);
		currentChamberId += 1;
		if currentChamberId == numberOfSlices:
			state = "hold"
	
	if state == "hold":
		if completedRooms == numberOfSlices:
			state = "corridor";
		
	if state == "corridor":
		var chosenCorridor = corridorList.pick_random();
		generateCorridor(chosenCorridor);
		corridorList.erase(chosenCorridor);
		if corridorList.size() <= calculateNumberOfCorridors()-corridorQuantity:
			state = "hold2";
		
	if state == "hold2":
		if corridorsCompleted == corridorsCreated:
			state = "check";
	
	if state == "check":
		var nodeList = gridNode.get_children();
		moveToNode(nodeList[0]);
		spawnFloodFill();
		moveToTile(Vector2(0,0));
		state = "hold3";
	
	if state == "hold3":
		if floodCompleted:
			state = "stair";
	
	if state == "stair":
		var foundTiles = get_tree().get_nodes_in_group("Found");
		var chamberTiles = get_tree().get_nodes_in_group("Chamber");
		var foundChamberTiles = foundTiles.filter(func (item): return item in chamberTiles);
		
		#moveToNode(foundChamberTiles.pick_random());
		#spawnNodeHere(preload("res://scenes/dungeon/dungeon_staircase.tscn"),"DungeonStaircase");
		moveToNode(foundChamberTiles.pick_random());
		spawnNodeHere(preload("res://scenes/player.tscn"),"DungeonSpawn");
		moveToTile(Vector2(0,0));
		state = "final";
		
	if state == "final":
		for node in get_tree().get_nodes_in_group("Floor"):
			node.queue_free();
		get_parent().get_child(2).queue_free();
		queue_free();

