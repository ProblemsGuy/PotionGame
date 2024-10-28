extends State
class_name PlayerMovement

@onready var playerNode: CharacterBody2D = get_parent().get_parent();
var stepSpeed: int;

var actionOptions:= Gamedefaults.actionOptions;
var currentInput: int;

#Allows children states to set their own run speed
func set_step_speed():
	stepSpeed = 0;

#Finds the current direction being held at point of function being called.
func get_current_input_direction():
	for keyName in actionOptions:
		if Input.is_action_pressed(keyName.to_lower()):
			playerNode.currentDirection = actionOptions[keyName];
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
	if !playerNode.directionHasBlock[currentInput]:
		playerNode.targetPosition = find_closest_tile(playerNode.currentPosition);
	else:
		playerNode.targetPosition = playerNode.position;

#Finds the closest tile point to where the player is right now
func find_closest_tile(point: Vector2):
	var x_difference = fmod(point.x-playerNode.startingPosition.x,Gamedefaults.TILE_SIZE.x);
	var y_difference = fmod(point.y-playerNode.startingPosition.y,Gamedefaults.TILE_SIZE.y);
	match currentInput:
		0:
			return Vector2(point.x+(Gamedefaults.TILE_SIZE.x-x_difference),point.y)
		1:
			return Vector2(point.x-(Gamedefaults.TILE_SIZE.x-x_difference),point.y)
		2:
			return Vector2(point.x,point.y+(Gamedefaults.TILE_SIZE.y-y_difference))
		3:
			return Vector2(point.x,point.y-(Gamedefaults.TILE_SIZE.y-y_difference))
		_:
			return point;

#Handles running; overwritten in "PlayerRunning" to change back to walking when shift is released.
func shift_run():
	if Input.is_action_pressed("shift"):
		transition.emit(self, "PlayerRunning")

func physics_update(delta):
	shift_run();
	playerNode.position += (playerNode.targetPosition - playerNode.currentPosition) * stepSpeed * delta
	
	# Check if the player is close enough to the target position to snap to it
	if playerNode.position.distance_to(playerNode.currentPosition) >= playerNode.targetPosition.distance_to(playerNode.currentPosition):
		playerNode.position = playerNode.targetPosition
		playerNode.currentPosition = playerNode.position
		if get_current_input_direction() == currentInput && currentInput != -1:
			walk();
		else:
			transition.emit(self, "PlayerIdle")
