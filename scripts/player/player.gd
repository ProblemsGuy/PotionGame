extends CharacterBody2D

var startingPosition: Vector2 
var targetPosition: Vector2 

var gridNode: MovementGrid;
const gridType = 0;

var directionHasBlock: Array = [false,false,false,false];

@export var currentDirection : Gamedefaults.Direction
@onready var current_state : State
@onready var states : Dictionary

const animationSprites:= [
	{
		"stillSprite": "right_still",
		"walkSprite": "right_walk"
	}, 
	{
		"stillSprite": "left_still",
		"walkSprite": "left_walk"
	}, 
	{
		"stillSprite": "down_still",
		"walkSprite": "down_walk"
	}, 
	{
		"stillSprite": "up_still",
		"walkSprite": "up_walk"
	}
]

func _ready():
	gridNode = get_parent();
	if gridNode == null:
		push_error("PLAYER NEEDS MOVEMENT GRID")
		get_tree().quit();
	
	startingPosition = gridNode.local_to_map(global_position);
	targetPosition = startingPosition;

func _process(_delta):
	current_state = $PlayerStateMachine.current_state;
	states = $PlayerStateMachine.states;
	
	if current_state == states["playeridle"]:
		$PlayerAppearance.play(animationSprites[currentDirection].stillSprite); 
	if current_state == states["playerwalking"] or current_state == states["playerrunning"]:
		$PlayerAppearance.play(animationSprites[currentDirection].walkSprite);
		
