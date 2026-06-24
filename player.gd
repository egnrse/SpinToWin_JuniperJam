extends CharacterBody2D

signal playerDeath	## called when the player dies

@export var DAMAGE_RATE := 12	## how fast to get damaged
@export var max_health := 10.	## max health
var health := max_health		## current health

@export_subgroup("more")
@export var animate := true				## if animations should be shown

@onready var healthBar = $HealthBar
@onready var deathPart = $DeathParticles

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

func die() -> void:
	$DeathAudio.play()
	if animate:
		deathPart.visible = true
		deathPart.emitting = true
	playerDeath.emit()

## reset everything
func reset() -> void:
	health = max_health
	healthBar.update()
	deathPart.visible = false
	if animate:
		deathPart.restart()
