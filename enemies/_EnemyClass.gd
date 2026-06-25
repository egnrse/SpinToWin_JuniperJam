## base class for enemies
## (handles health/damage/score/death)
class_name EnemyBase
extends CharacterBody2D

@onready var healthBar:ProgressBar = get_node_or_null("HealthBar")	## the healthbar of [member self] (fails silently if none exist)
#@onready var look:Node2D = get_node_or_null("Look")		## look of  for animations (fails silently if none exist)


signal damaged(entity, amount:int)		## emited when [member self] is damaged
signal death(entity,position:Vector2)	## emited when [member self] dies

@export var max_health := 2			## max health of [member self]
@export var speed := 100			## movement speed of [member self]
@export var score := max_health		## score player gets on kill of [member self] (default: [member max_health])


@export_subgroup("animation", "anim")
@export var animLook: Node2D = null				## object holding the visuals of [member self] which can be animated
@export var animSprite: AnimatedSprite2D = null	## object with animations (expects: "default", "hit", "die")
@export var animNameDefault := "default"		## the name of the default animation
@export var animNameHit := "hit"				## the name of the hit/hurt animation
@export var animNameDie := "die"				## the name of the die/death animation
@export var animHitTime := 0.2					## how to long to play the hit animation for, before switching back to default

@export_subgroup("more")
@export var INVUL_TIME := 0.1;		## invulnerability time between damage instances (see [member iTimer])
@export var animate := true			## if animations should be shown


var health := max_health			## current health
var alive := true					## if [member self] is currently alive
var justDamaged := false			## [member self] can only take damage if false (is reset by [member iTimer])
var iTimer := Timer.new()			## invulnerability timer, gets started after taking damage

# audio
var audioHurt := AudioStreamPlayer2D.new()	## the audio player
var audioHurtStream := preload("res://Assets/Enemy_HurtV3.wav")	## the audiostream obj
var audioHurtVolume := 0		## volume in db
var audioHurtPitchRange := 0.3	## range of the pith diviation
var audioDie := AudioStreamPlayer2D.new()	## the audio player
var audioDieStream := preload("res://Assets/Enemy_HurtV2.wav")	## the audiostream obj
var audioDieVolume := -5		## volume in db
var audioDiePitchRange := 0.3	## range of the pith diviation

# animation
var animTween:Tween	## for animations
@onready var animTimer: Timer	## the timer to stop hit animations

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.init()
	self.initAudio()
	self.initAnim()

## init some basic things
func init() -> void:
	# health
	health = max_health
	alive = true
	if healthBar: healthBar.update()
	# timer
	add_child(iTimer)
	iTimer.wait_time = INVUL_TIME
	iTimer.one_shot = true
	iTimer.timeout.connect(_on_iTimer_timeout)

## init audio stuff
func initAudio() -> void:
	# prep audio
	add_child(audioHurt)
	audioHurt.bus = &"SFX_enemy"
	audioHurt.stream = audioHurtStream
	audioHurt.volume_db = audioHurtVolume
	add_child(audioDie)
	audioDie.bus = &"SFX_enemy"
	audioDie.stream = audioDieStream
	audioDie.volume_db = audioDieVolume

## init animation stuff
func initAnim() -> void:
	if not animate:
		animSprite.animation = animNameDefault
		animSprite.stop()
		return
	
	animTimer = Timer.new()
	animTimer.wait_time = animHitTime
	animTimer.one_shot = true
	add_child(animTimer)
	animTimer.timeout.connect(_on_animTimer_timeout)
	animSprite.play(animNameDefault)

## call to damage [member self] (decreases [member health])
func damage(amount: int = 1) -> void:
	# wait for the damage pause to run out
	if self.justDamaged:
		#print("justDamaged")
		return
	elif not self.alive:
		# only take damage if self is alive
		return
	else:
		justDamaged = true # set a new damage pause
		iTimer.start()
	
	#print("damage: ", amount)	#dev
	self.health -=amount
	damaged.emit(self, amount)
	if healthBar: healthBar.update()
		
	if health <= 0:
		self.die() 
	else:
		# only play hurt if not dying
		audioHurt.pitch_scale = randf_range(1-audioHurtPitchRange, 1+audioHurtPitchRange)
		audioHurt.play()
		anim_damage(amount)

## called when [member health] <= 0
func die() -> void:
	if not alive:
		push_warning("die(): called but already dead: ", self)
		return
	alive = false
	#self.visible = false	# deprecated, use anim_die
	# disable collisions
	collision_layer = 0
	collision_mask = 0
	death.emit(self, self.global_position)
	# play audio (and wait for it to finish)
	audioDie.pitch_scale = randf_range(1-audioDiePitchRange, 1+audioDiePitchRange)
	audioDie.play()
	await anim_die()
	await audioDie.finished
	
	queue_free()

#region ANIMATIONS
func anim_damage(amount: int = 1) -> void:
	if not animate: return
	
	# do both animations if their needed obj exists
	if animSprite and animSprite.sprite_frames.has_animation(animNameHit) and animTimer:
		var frame = animSprite.get_frame()
		var progress = animSprite.get_frame_progress()
		animSprite.play(animNameHit)
		animSprite.set_frame_and_progress(frame, progress)
		animTimer.start()
	if animLook:
		if animTween: animTween.kill()
		animTween = create_tween()
		animTween.set_trans(Tween.TRANS_EXPO)
		animTween.set_ease(Tween.EASE_OUT)
		var o := animLook.scale
		var val := o - Vector2(min(amount/13., 0.3), min(amount/13., 0.3))
		animTween.tween_property(animLook, "scale", val, 0.08)
		animTween.tween_property(animLook, "scale", o, 0.03)
		await animTween.finished
	
func anim_die() -> void:
	if not animate: return
	
	if animSprite and animSprite.sprite_frames.has_animation(animNameDie):
		animSprite.play(animNameDie)
	if animLook:
		if animTween: animTween.kill()
		animTween = create_tween()
		animTween.set_trans(Tween.TRANS_SINE)
		animTween.set_ease(Tween.EASE_OUT)
		#var val := animLook.scale + Vector2(0.1,0.1)
		#animTween.tween_property(animLook, "scale", val, 0.25)
		#animTween.set_parallel(true)
		animTween.tween_property(self, "modulate:a", 0.0, 1)
		await animTween.finished
	if animSprite and animSprite.is_playing(): await animSprite.animation_finished
#endregion ANIMATIONS

## called when [member iTimer] runs out
func _on_iTimer_timeout() -> void:
	justDamaged = false

## reset animation after being hit
func _on_animTimer_timeout() -> void:
	animSprite.animation = animNameDefault
