extends PlayerMovement

func set_step_speed():
	stepSpeed = 400;

func shift_run():
	if !Input.is_action_pressed("shift"):
		transition.emit(self, "PlayerWalking")
