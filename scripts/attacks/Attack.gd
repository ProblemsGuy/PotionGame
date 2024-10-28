extends Area2D

var creator : Node;
#DEFAULTS; Being used to ensure code works, may be kept just so there is always a placeholder value
var damage := 5;
var type := "Leo";
var kick := Vector2(0.0,1.0)*Gamedefaults.TILE_SIZE;
var effect : Callable = func():
	print("Effect applied!");

signal attackComplete;

func _on_area_entered(area):
	await $Sprite.animation_finished;
	if area.name == "Enemy":
		area.take_damage(damage,type,kick,effect);

func _process(_delta):
	$Sprite.play("default");
	await $Sprite.animation_finished;
	attackComplete.emit();
	queue_free();
