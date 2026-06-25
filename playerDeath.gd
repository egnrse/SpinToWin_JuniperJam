extends Node2D

@export var animatedSprite: AnimatedSprite2D

@onready var deathAudio := $DeathAudio
@onready var deathPart := $DeathParticles
@onready var animDeath := $AnimatedSprite2D_death

## reset the things we changed in [member start]
func reset() -> void:
	animatedSprite.visible = true
	deathPart.visible = false
	deathPart.restart()


## start death animations
func start(animate=true) -> void:
	deathAudio.play()
	if animate:
		animatedSprite.stop()
		animatedSprite.visible = false
		animDeath.visible = true
		animDeath.play("death")
		deathPart.visible = true
		deathPart.emitting = true

func _on_animated_sprite_2d_death_animation_finished() -> void:
	animDeath.visible = false
	pass # Replace with function body.
