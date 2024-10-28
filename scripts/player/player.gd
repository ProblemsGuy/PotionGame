extends CharacterBody2D

@onready var startingPosition := position;
var currentPosition: Vector2 = startingPosition;
var targetPosition: Vector2 = startingPosition;

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

func _process(_delta):
	current_state = $PlayerStateMachine.current_state;
	states = $PlayerStateMachine.states;
	
	if current_state == states["playeridle"]:
		$PlayerAppearance.play(animationSprites[currentDirection].stillSprite); 
	if current_state == states["playerwalking"]:
		$PlayerAppearance.play(animationSprites[currentDirection].walkSprite);
		
