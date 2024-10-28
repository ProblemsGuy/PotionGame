extends Node

const TILE_SIZE := Vector2(32.0, 32.0);
enum Direction {RIGHT=0, LEFT=1, DOWN=2, UP=3}
const actionOptions := {
	"right":Direction.RIGHT,
	"left":Direction.LEFT,
	"down":Direction.DOWN,
	"up":Direction.UP,
}

func rotateDownwardFacingVector(startingVector:Vector2,direction:Direction):
	match (direction):
		0:
			return Vector2(startingVector.y,startingVector.x)
		1:
			return Vector2(-startingVector.y,startingVector.x)
		2:
			return startingVector;
		3:
			return startingVector*Vector2(-1,-1);
