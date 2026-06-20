extends "res://enemies/_EnemyClass.gd"

func _physics_process(delta: float) -> void:
	move(delta)
	
func move(_delta: float) -> void:
	var direction = global_position.direction_to(self.Player.global_position)
	velocity = direction * self.speed
	move_and_slide()
