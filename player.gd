extends CharacterBody2D

signal playerDeath	## called when the player dies

@export var DAMAGE_RATE := 12	## how fast to get damaged
@export var max_health := 10.	## max health
var health := max_health		## current health

@export_subgroup("more")
@export var animate := true				## if animations should be shown

@onready var healthBar = $HealthBar
@onready var deathNode = $Death
#@onready var deathPart = $Death/DeathParticles
#@onready var deathAudio = $Death/DeathAudio
@onready var animatedSprite = $AnimatedSprite2D_png
@onready var animatedTimer = $AnimatedSprite2D_png/Timer

func _ready():
	reset()

func _physics_process(delta: float) -> void:
	# follow mouse
	var mouse := get_global_mouse_position()
	var motion := mouse - global_position
	move_and_collide(motion)
	
	# get damaged by enemies
	var enemies = %HurtArea.get_overlapping_bodies()
	if enemies.size() > 0:
		var count = 0
		# only count alive enemies
		for e in enemies:
			if 'alive' in e and e.alive:
				count += 1
		if count > 0:
			damage(DAMAGE_RATE * count * delta)

## call to damage [member self] (decreases [member health])
func damage(amount: float = 1) -> void:
	if amount <= 0:
		push_warning("player.damage(): amount <= 0, ", amount)
	self.health -=amount
	healthBar.update()
	
	if health <= 0:
		die()
	else:
		var hurtAudio = $HurtAudio
		if not hurtAudio.playing:
			hurtAudio.play()
		if animate:
			var frame = animatedSprite.frame
			var progress = animatedSprite.frame_progress
			animatedSprite.animation = "hit"
			animatedSprite.set_frame_and_progress(frame, progress)
			animatedTimer.start()

func die() -> void:
	deathNode.start(animate)
	playerDeath.emit()

## reset everything
func reset() -> void:
	health = max_health
	healthBar.update()
	if animate:
		animatedSprite.play("default")
	else:
		animatedSprite.stop()
	deathNode.reset()

## update animations (react to a change in the [member animate])
func animateUpdate() -> void:
	if animate:
		if not animatedSprite.is_playing():
			animatedSprite.play("default")
	else:
		animatedSprite.stop()

## reset animation to default
func _on_timer_timeout() -> void:
	animatedSprite.animation = "default"
	pass # Replace with function body.

func _on_animated_sprite_2d_png_animation_finished() -> void:
	animatedSprite.stop()
	pass # Replace with function body.
