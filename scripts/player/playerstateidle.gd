extends State

func update(_delta):
	for keyName in Gamedefaults.actionOptions:
		if Input.is_action_pressed(keyName):
			transition.emit(self,"PlayerWalking");
		
	if Input.is_action_pressed("attack1"):
		transition.emit(self,"PlayerAttacking");
