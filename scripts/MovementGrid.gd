extends TileMap
class_name MovementGrid;

var tile_size := Gamedefaults.TILE_SIZE;
var half_tile_size := tile_size/2;

enum ENTITY_TYPES {PLAYER, OBSTACLE, COLLECTIBLE, GENERATOR, FLOOR}

@export var grid_size = Vector2(80,80);
var entity_grid = [];
var node_grid = [];

func isGridPointValid(gridVector:Vector2):
	if gridVector.x >= 0 and gridVector.x < grid_size.x:
		if gridVector.y >= 0 and gridVector.y < grid_size.y:
			if entity_grid[gridVector.x][gridVector.y] != ENTITY_TYPES.OBSTACLE:
				return true;
	return false;

func isGridPointValidInDirection(gridVector:Vector2,direction:Vector2i):
	return isGridPointValid(local_to_map(gridVector)+direction);

func createSceneAtGridPoint(nodeType:PackedScene,gridVector:Vector2i):
	return createSceneAtLocalPoint(nodeType,map_to_local(gridVector));

func createSceneAtLocalPoint(nodeType:PackedScene,localVector:Vector2):
	var gridVector = local_to_map(localVector);
	if !isGridPointValid(local_to_map(localVector)):
		push_error("Unable to create " +str(nodeType)+" at "+str(localVector));
		return null;
	var newNode = nodeType.instantiate();
	newNode.position = localVector;
	newNode.gridNode = self;
	entity_grid[gridVector.x][gridVector.y] = newNode.gridType;
	node_grid[gridVector.x][gridVector.y] = newNode
	add_child(newNode);
	return newNode;

func createGeneratorAtLocalPoint(nodeType:PackedScene,localVector:Vector2):
	var gridVector = local_to_map(localVector);
	if !isGridPointValid(local_to_map(localVector)):
		push_error("Unable to create " +str(nodeType)+" at "+str(localVector));
		return null;
	var newNode = nodeType.instantiate();
	newNode.position = localVector;
	newNode.gridNode = self;
	add_child(newNode);
	return newNode;

func updateChildPosition(childNode:Node,direction:Vector2i):
	var gridVector = local_to_map(childNode.global_position);
	entity_grid[gridVector.x][gridVector.y] = null;
	node_grid[gridVector.x][gridVector.y] = null;
	var newGridVector = gridVector+direction;
	entity_grid[newGridVector.x][newGridVector.y] = childNode.gridType;
	node_grid[gridVector.x][gridVector.y] = childNode
	var targetPosition = map_to_local(newGridVector);
	return targetPosition;

func warpChildPosition(childNode:Node,newPosition:Vector2i):
	var gridVector = local_to_map(childNode.global_position);
	var targetPosition = map_to_local(newPosition);
	return targetPosition;

func warpChildPositionLocal(childNode:Node,newPosition:Vector2i):
	return warpChildPosition(childNode,local_to_map(newPosition));

func _ready():
	for i in range(grid_size.x):
		entity_grid.append([]);
		entity_grid[i].resize(grid_size.y);
	for i in range(grid_size.x):
		node_grid.append([]);
		node_grid[i].resize(grid_size.y);
