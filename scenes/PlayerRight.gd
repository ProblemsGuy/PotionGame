extends Area2D

@onready var playerNode: CharacterBody2D = get_parent()

func _on_area_entered(_area):
	playerNode.directionHasBlock[0] = true;

func _on_area_exited(_area):
	playerNode.directionHasBlock[0] = false;
