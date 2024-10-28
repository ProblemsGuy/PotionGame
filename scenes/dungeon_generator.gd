extends Node2D

#These should stay the same no matter what
@onready var MAIN_NODE = get_parent().get_child(0);
const TILE_SIZE = Gamedefaults.TILE_SIZE;
const NORTH = 0;
const EAST = 1;
const SOUTH = 2;
const WEST = 3;
var start_point = Vector2(16.0,16.0)

## The PackedScene that is used for walls; change to change wall appearance.
@export var wallNode:PackedScene = preload("res://scenes/dungeon/dungeon_wall.tscn");
## The PackedScene that is used for floors; change to change floor appearance.
@export var floorNode:PackedScene = preload("res://scenes/dungeon/dungeon_floor.tscn");
var chamberNode:PackedScene = preload("res://scenes/dungeon/dungeon_chamber_generator.tscn");
var corridorNode:PackedScene = preload("res://scenes/dungeon/dungeon_corridor_generator.tscn");
var fillNode:PackedScene = preload("res://scenes/dungeon/dungeon_flood_fill.tscn")
## The tile width which the room should be generated too
@export var roomTileWidth := 80; 
## The tile height which the room should be generated too
@export var roomTileHeight := 80;
## The number of vertical slices of the level for room gen.
## Must be a factor of roomTileWidth
@export var roomXSlices := 8; 
## The number of horizontal slices of the level for room gen
## Must be a factor of roomTileHeight
@export var roomYSlices := 8;

var roomSliceWidth = roomTileWidth/roomXSlices;
var roomSliceHeight = roomTileHeight/roomYSlices;
var numberOfSlices = roomXSlices*roomYSlices;

## How many rooms should be generated
@export var chamberQuanity := 26;
#CONSIDER REPLACING - Could just be a random range for both variable
## Tile shapes that the rooms can be
@export var chamberScales := [[6,6],[4,3],[6,4],[3,7]]; 
@export var corridorQuantity := 60;


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
	return (global_position-start_point)/TILE_SIZE;

func moveToTile(tile: Vector2):
	if tile.x > roomTileWidth:
		push_error("tileX exceeding width entered")
		get_tree().quit();
	elif tile.y > roomTileHeight:
		push_error("tileY exceeding height entered")
		get_tree().quit();
	else:
		global_position = (TILE_SIZE*tile)+start_point;

func moveToNode(tile: Node):
	global_position = tile.global_position;

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
	var newNode = nodeType.instantiate();
	newNode.global_position = global_position;
	newNode.name = nodeName+str(calculateCurrentTileVector());
	MAIN_NODE.add_child(newNode);
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
	newCorridor.dungeonOffset = start_point;
	newCorridor.state = "active";
	newCorridor.complete.connect(onCorridorComplete);
	corridorsCreated += 1;

var floodCompleted = false;
func onFloodCompleted():
	floodCompleted = true;

func spawnFloodFill():
	var newNode = fillNode.instantiate();
	newNode.global_position = global_position;
	newNode.wallNode = wallNode;
	newNode.completed.connect(onFloodCompleted);
	get_parent().add_child(newNode);
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
		var nodeList = MAIN_NODE.get_children();
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
		
		moveToNode(foundChamberTiles.pick_random());
		spawnNodeHere(preload("res://scenes/dungeon/dungeon_staircase.tscn"),"DungeonStaircase");
		moveToNode(foundChamberTiles.pick_random());
		spawnNodeHere(preload("res://scenes/dungeon/dungeon_spawn.tscn"),"DungeonSpawn");
		moveToTile(Vector2(0,0));
		state = "final";
		
	if state == "final":
		for node in get_tree().get_nodes_in_group("Floor"):
			node.queue_free();
		#get_parent().get_child(2).queue_free();
		#queue_free();











































#var walkable_tiles = 0;
#var roomEdgeTiles= [];
##Counts for naming walls and floors
#var tileCount =0;
#
##Slice up the level
#var roomSliceWidth = roundi(roomTileWidth/roomSliceX);
#var roomSliceHeight = roundi(roomTileHeight/roomSliceY);
#
#func spawnTileHere(tileType,tileName:String):
	#var newTile = tileType.instantiate();
	#newTile.global_position = global_position;
	#newTile.name = tileName+str(tileCount);
	#tileCount+=1;
	#MAIN_NODE.add_child(newTile);
	#return newTile;
#
#func spawnWallHere():
	#spawnTileHere(wallNode,"DungeonWall");
#
#func calculateCurrentTileInt():
	#var currentVector = calculateCurrentTileVector();
	#return currentVector.x + (currentVector.y*roomTileWidth)
#
#func calculateCurrentTileVector():
	#return (global_position-start_point)/TILE_SIZE;
#
#func fetchCurrentTile():
	#var childList = MAIN_NODE.get_children();
	#var currentChildIndex = calculateCurrentTileInt();
	#if currentChildIndex < childList.size():
		#var child = childList[currentChildIndex];
		#return child;
	#push_error("Out of index bounds: " + str(currentChildIndex));
	#return null;
#
#func spawnFloorHere():
	#var oldChild = fetchCurrentTile();
	#if oldChild.name.contains("DungeonWall"):
		#MAIN_NODE.remove_child(oldChild);
		#oldChild.queue_free();
		#var newFloor = spawnTileHere(floorNode,"DungeonFloor");
		#MAIN_NODE.move_child(newFloor,calculateCurrentTileInt());
	#else:
		#push_error("No wall to delete here: " + str(calculateCurrentTileVector()))
#
#func moveToTile(tile: Vector2):
	#if tile.x > roomTileWidth:
		#push_error("tileX exceeding width entered")
	#elif tile.y > roomTileHeight:
		#push_error("tileY exceeding height entered")
	#else:
		#global_position = (TILE_SIZE*tile)+start_point;
#
#func fillRoom():
	#var completedFill = false;
	#while !completedFill:
		#if global_position.x-start_point.x < roomTileWidth*TILE_SIZE.x:
			#spawnWallHere();
			#global_position.x += TILE_SIZE.x;
		#elif global_position.y-start_point.y+TILE_SIZE.y < roomTileHeight*TILE_SIZE.y:
			#global_position.y += TILE_SIZE.y;
			#global_position.x = start_point.x;
		#else:
			#completedFill = true;
			#global_position = start_point;
#
#func arrayTotal(array):
	#var total = 0;
	#for value in array:
		#total += value;
	#return total;
#
#func binaryArrayGenerator(bitSize,length):
	#var binaryList = [];
	#binaryList.resize(length);
	#binaryList.fill(0);
	#
	#if bitSize >= length:
		#binaryList.fill(1);
		#return binaryList;
	#
	#while(arrayTotal(binaryList) != bitSize):
		#binaryList[randi_range(0,length-1)] = 1;
	#
	#return binaryList;
	#
#func generateRoomHere(roomScale:Vector2,roomId:int,turnpoint: Vector2):
	#var direction = Vector2(1,1);
	#var currentLocation = calculateCurrentTileVector()
	#var roomStartPoint = currentLocation;
	#if turnpoint.x < currentLocation.x+roomScale.x:
		#direction.x = -1;
	#if turnpoint.y < currentLocation.y+roomScale.y:
		#direction.y = -1;
	#
	#var northList = [];
	#northList.resize(roomScale.x)
	#var westList = [];
	#westList.resize(roomScale.y)
	#var southList = [];
	#southList.resize(roomScale.x)
	#var eastList = [];
	#eastList.resize(roomScale.y)
	#
	#var northSide = int(roomStartPoint.y) 
	#if direction.y==-1: 
		#northSide = roomStartPoint.y-roomScale.y+1;
		#
	#var westSide = int(roomStartPoint.x)
	#if direction.x==-1: 
		#westSide = roomStartPoint.x-roomScale.x+1;
		#
	#var southSide = roomStartPoint.y+roomScale.y-1;
	#if direction.y==-1:
		#southSide = roomStartPoint.y; 
		#
	#var eastSide = roomStartPoint.x+roomScale.x-1; 
	#if direction.x==-1:
		#eastSide = roomStartPoint.x;
	#
	#var northPointer=0;
	#var eastPointer=0;
	#var southPointer=0;
	#var westPointer=0;
	#
	#for yDepth in range(0,roomScale.y):
		#for xDepth in range(0,roomScale.x):
			#if currentLocation.y==northSide:
				#northList[northPointer] = currentLocation;
				#northPointer+=1
			#if currentLocation.x==eastSide:
				#eastList[eastPointer] = currentLocation;
				#eastPointer+=1;
			#if currentLocation.y==southSide:
				#southList[southPointer] = currentLocation;
				#southPointer+=1;
			#if currentLocation.x==westSide:
				#westList[westPointer] = currentLocation;
				#westPointer+=1;
			#spawnFloorHere();
			#currentLocation += Vector2(1,0)*direction;
			#moveToTile(currentLocation);
		#currentLocation += Vector2(0,1)*direction;
		#currentLocation.x = roomStartPoint.x;
		#moveToTile(currentLocation);
	#
	#roomEdgeTiles[roomId] = [northList,eastList,southList,westList];
#
#func generateRooms():
	##PLACEHOLDER; This probably should happen somewhere else
	#randomize();
	#roomEdgeTiles.resize(roomSliceX*roomSliceY);
	#var lookUpTable = binaryArrayGenerator(roomQuanity,(roomSliceX*roomSliceY));
	#
	#roomEdgeTiles.resize(roomSliceX*roomSliceY);
	#roomEdgeTiles.fill([[],[],[],[]]);
	#
	#for j in range(0,roomSliceY):
		#for i in range(0,roomSliceX):
			#var roomSliceTopLeftTile= Vector2(i*roomSliceWidth,j*roomSliceHeight);
			#var roomSliceBottomRightTile= roomSliceTopLeftTile + Vector2(roomSliceWidth-1,roomSliceHeight-1);
			#
			#var currentLocation = Vector2((roomSliceWidth*i)+randi_range(roomRange,roomSliceWidth-roomRange),(roomSliceHeight*j)+randi_range(roomRange,roomSliceHeight-roomRange));
			#moveToTile(currentLocation);
			#var roomId = i+(j*roomSliceX);
			#
			#if lookUpTable[roomId]==0:
				#roomEdgeTiles[roomId] = [[currentLocation],[currentLocation],[currentLocation],[currentLocation]];
				#spawnFloorHere();
				#continue;
				#
			#var roomScaleHolder = roomScales.pick_random();
			#var roomScale = Vector2(roomScaleHolder[0],roomScaleHolder[1]);
			#
			#generateRoomHere(roomScale,roomId,roomSliceBottomRightTile);
#
#func invertDirection(direction):
	#match direction:
		#NORTH:
			#return SOUTH;
		#EAST:
			#return WEST;
		#SOUTH:
			#return NORTH;
		#WEST:
			#return EAST;
#
#func goToRoomIdDirection(roomId,direction):
	#match direction:
		#NORTH:
			#return roomId-roomSliceX;
		#EAST:
			#return roomId+1;
		#SOUTH:
			#return roomId+roomSliceX;
		#WEST:
			#return roomId-1;
#
#func getCardinality(input):
	#if input >= 0:
		#return 1;
	#else:
		#return -1;
#
#func generateCorridors():
	#var directions = [];
	#directions.resize(roomSliceX*roomSliceY);
	#for i in range(directions.size()):
		#directions[i] = [NORTH,EAST,SOUTH,WEST];
	#
	#for yDepth in range(0,roomSliceY):
		#for xDepth in range(0,roomSliceX):
			#var roomId = xDepth+(yDepth*roomSliceX);
			#var currentDirections = directions[roomId];
			#if yDepth == 0:
				#currentDirections[NORTH] = -1;
			#if xDepth == roomSliceX-1:
				#currentDirections[EAST] = -1;
			#if yDepth == roomSliceY-1:
				#currentDirections[SOUTH] = -1;
			#if xDepth == 0:
				#currentDirections[WEST] = -1;
			#
			#while(currentDirections.has(-1)):
				#currentDirections.erase(-1);
			#
			#if currentDirections.size()==0:
				#continue;
			#
			#var chosenDirection = currentDirections[randi_range(0,currentDirections.size()-1)];
			#
			#var startPoint = roomEdgeTiles[roomId][chosenDirection][randi_range(0,roomEdgeTiles[roomId][chosenDirection].size()-1)];
			#var targetRoomId = goToRoomIdDirection(roomId,chosenDirection);
			#var targetPoint = roomEdgeTiles[targetRoomId][invertDirection(chosenDirection)][randi_range(0,roomEdgeTiles[targetRoomId][invertDirection(chosenDirection)].size()-1)];
			#if targetRoomId > roomId:
				#directions[targetRoomId][invertDirection(chosenDirection)] = -1;
			#
			#print("CORRIDOR START");
			#print("Direction: "+ str(chosenDirection));
			#print("Start Point: " + str(startPoint));
			#print("Target Point: "+str(targetPoint));
			#
			#var pointDifference = targetPoint - startPoint;
			#var currentLocation = startPoint;
			#moveToTile(currentLocation);
			#
			#match chosenDirection:
				#NORTH,SOUTH:
					#var yDirection = getCardinality(pointDifference.y);
					#for i in range(0,abs(pointDifference.y)):
						#currentLocation.y += yDirection;
						#print(currentLocation);
						#moveToTile(currentLocation);
						#spawnFloorHere();
						#if i == roundi(abs(pointDifference.y)/2):
							#var xDirection = getCardinality(pointDifference.x);
							#for j in range(0,abs(pointDifference.x)):
								#currentLocation.x += xDirection;
								#print(currentLocation);
								#moveToTile(currentLocation);
								#spawnFloorHere();
				#EAST, WEST:
					#var xDirection = getCardinality(pointDifference.x);
					#for i in range(0,abs(pointDifference.x)):
						#currentLocation.x += xDirection;
						#print(currentLocation);
						#moveToTile(currentLocation);
						#spawnFloorHere();
						#if i == roundi(abs(pointDifference.x)/2):
							#var yDirection = getCardinality(pointDifference.y);
							#for j in range(0,abs(pointDifference.y)):
								#currentLocation.y += yDirection;
								#print(currentLocation);
								#moveToTile(currentLocation);
								#spawnFloorHere();

