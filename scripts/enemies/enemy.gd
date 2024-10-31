extends Area2D

@export var health := 50;
var attackAffinities: Dictionary = {"Leo":2,}

func take_damage(damage:int,type:String,kick:Vector2,effect:Callable):
	#Apply damage equal to the damage dealt by the attack, multiplied by the enemies' affinity for that type
	health -= damage * attackAffinities[type];
	
	#Kick is applied to the enemy, pushing it in a certain direction
	position += kick;
	
	#External effects are applied to the enemy, that the spell might have applied to it
	effect.call();

func _physics_process(_delta):
	#PLACEHOLDER; Will be replaced by sprite rendering
	$EnemyAppearance.play("front");

func _process(_delta):
	#PLACEHOLDER; Debug to show health stat
	$Health.text = str(health);
	if health <= 0:
		#PLACEHOLDER; will be replaced by death function
		queue_free();
