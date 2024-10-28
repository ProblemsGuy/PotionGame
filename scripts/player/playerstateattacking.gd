extends State

#NEEDS; external data about the types of attacks the player has "loaded", and which one is "selected".
@onready var playerNode: CharacterBody2D = get_parent().get_parent();
@export var attackScene: PackedScene;

#PLACEHOLDER;Should be calling an external value that has the player's "loaded" spells. Also needs a mana value
var distanceOfAttack : Vector2 = Vector2(0.0,1.0)*Gamedefaults.TILE_SIZE;
var kick : Vector2 = Vector2(0.0,1.0)*Gamedefaults.TILE_SIZE;

func enter():
	#Create an "attack object"
	var attack = attackScene.instantiate();
	#Connect the signal so when the attack finishes the state completes
	attack.attackComplete.connect(finish_attack);
	#Spawn the attack at at position and towards the camera
	var direction = playerNode.currentDirection;
	attack.position = Gamedefaults.rotateDownwardFacingVector(distanceOfAttack,direction);
	attack.z_index = 100;
	#NEEDS; Mana deduction based on how much the spell costs.
	#NEEDS; Damage control over what the attack is doing
	#NEEDS; Type control of the attack type
	attack.kick = Gamedefaults.rotateDownwardFacingVector(kick,direction);
	#Add the attack to the hierarcy of the Player so it's visible.
	playerNode.add_child(attack);

func finish_attack():
	transition.emit(self, "PlayerIdle");
