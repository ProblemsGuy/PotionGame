extends Node2D

var player = preload("res://scenes/player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var playerSpawn = player.instantiate();
	playerSpawn.global_position = global_position;
	playerSpawn.startingPosition = global_position;
	playerSpawn.currentPosition = global_position;
	playerSpawn.targetPosition = global_position;
	get_parent().add_child(playerSpawn);
	queue_free();
