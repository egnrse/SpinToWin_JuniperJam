extends "res://enemies/_EnemyClass.gd"

@onready var Player = get_node("/root/Game/Player")
#@onready var Game = get_node("/root/Game/")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.init()
	self.initAudio()
	self.initAnim()
	#var pitchRange = 0.4
	#$AudioStreamPlayer2D.pitch_scale = randf_range(1-pitchRange,1+pitchRange)

func _physics_process(delta: float) -> void:
	if self.alive:
		move(delta)
	else:
		$AudioStreamPlayer2D.stop()
	
func move(_delta: float) -> void:
	var direction = global_position.direction_to(self.Player.global_position)
	velocity = direction * self.speed
	move_and_slide()
