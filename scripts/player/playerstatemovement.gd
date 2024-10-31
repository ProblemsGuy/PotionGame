extends State
class_name PlayerMovement

@onready var playerNode: CharacterBody2D = get_parent().get_parent();
@onready var gridNode: MovementGrid = playerNode.gridNode;
var stepSpeed: int;

var actionOptions:= Gamedefaults.actionOptions;
var currentInput: int;
var directionVector: Vector2i;
const directionDictonairy:= {
	"right":Vector2i(1,0),
	"left":Vector2i(-1,0),
	"down":Vector2i(0,1),
	"up":Vector2i(0,-1)
}

#Allows children states to set their own run speed
func set_step_speed():
	stepSpeed = 0;

#Finds the current direction being held at point of function being called.
func get_current_input_direction():
	for keyName in actionOptions:
		if Input.is_action_pressed(keyName.to_lower()):
			playerNode.currentDirection = actionOptions[keyName];
			directionVector = directionDictonairy[keyName];
			return actionOptions[keyName];
	return -1;

#Runs upon entering the state
func enter():
	set_step_speed();
	#Set the player's starting position at the beginning of a scene.
	currentInput = get_current_input_direction();
	if currentInput == -1:
		transition.emit(self, "PlayerIdle")
		return
	else:
		walk();

#Walk function; handles the player's movement and sprite changes
func walk():
	if gridNode.isGridPointValidInDirection(playerNode.global_position,directionVector):
		playerNode.targetPosition = gridNode.updateChildPosition(playerNode,directionVector);
	else:
		playerNode.targetPosition = playerNode.position;

#Handles running; overwritten in "PlayerRunning" to change back to walking when shift is released.
func shift_run():
	if Input.is_action_pressed("shift"):
		transition.emit(self, "PlayerRunning")

func physics_update(delta):
	shift_run();
	playerNode.global_position = playerNode.global_position.move_toward(playerNode.targetPosition,delta*stepSpeed);
	
	# Check if the player is close enough to the target position to snap to it
	if playerNode.global_position == playerNode.targetPosition:
		playerNode.global_position = playerNode.targetPosition
		if get_current_input_direction() == currentInput && currentInput != -1:
			walk();
		else:
			transition.emit(self, "PlayerIdle")
