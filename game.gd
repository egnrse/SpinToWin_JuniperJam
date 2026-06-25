extends Node2D

@onready var rot := get_node("Rotateing")
@onready var player := get_node("Player")

# game flow
var startable = true
var running = false
var score = 0			## increase score on enemy death
@onready var scoreUI := %Score 

# enemies
@onready var spawnTimer := %enemySpawnTimer
@onready var enemies := %Enemies
@onready var enemyContainer := %EnemyContainer

# audio
var musicReverbIdx = 0
var musicLPIdx = 1
var musicHPIdx = 2
@onready var musicSlider := %Music_HSlider
@onready var sfxSlider := %SFX_HSlider
@onready var musicAudioBus := AudioServer.get_bus_index("Music")
@onready var sfxAudioBus := AudioServer.get_bus_index("SFX")
@onready var music := $Music
@onready var musicReverb = AudioServer.get_bus_effect(musicAudioBus, musicReverbIdx) as AudioEffectReverb
@onready var musicLP = AudioServer.get_bus_effect(musicAudioBus, musicLPIdx) as AudioEffectFilter
@onready var musicHP = AudioServer.get_bus_effect(musicAudioBus, musicHPIdx) as AudioEffectFilter

#
@export var animate := true			## if animations should be shown
var animTween: Tween
var pauseTween: Tween
@onready var camera = $Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioServer.set_bus_volume_linear(musicAudioBus, musicSlider.value)
	AudioServer.set_bus_volume_linear(sfxAudioBus, sfxSlider.value)
	
	gameStart(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#print("AudioPeak: ", max(AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("Master"), 0), AudioServer.get_bus_peak_volume_right_db(AudioServer.get_bus_index("Master"), 0)))
	pass

#region HELPER
## reset and start the game (force a game start even if its in a bad state)
func gameStart(force:bool = false) -> bool:
	if not startable or running:
		push_warning("Game is not startable or running")
		if not force: return false
	startable = false
	
	# reset
	%enemySpawnTimer.wait_time = 4.
	AudioServer.set_bus_effect_enabled(musicAudioBus, musicReverbIdx, false)
	music.playing = true
	# free all enemies in EnemyContainer
	for e in enemyContainer.get_children():	
		if e is EnemyBase:	# savety check
			e.queue_free()
	player.reset()
	rot.reset()
	%GameOver.visible = false
	%PauseMenu.visible = false
	%Settings_PanelContainer.visible = false
	
	# prepare
	updateAnimate()
	score = 0
	scoreUI.text = str(score)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	# enemy spawns
	spawnTimer.start()
	for n in 4:
		spawn_enemy()
	
	running = true
	return true

func gameEnd() -> void:
	running = false
	AudioServer.set_bus_effect_enabled(musicAudioBus, musicReverbIdx, true)
	music.playing = false
	%DeathScore.text = str(score)
	%GameOver.visible = true
	%Settings_PanelContainer.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%RestartDelay.start()

# called right before/after a pause
func pause(start:bool = true) -> void:
	# menus
	%PauseMenu.visible = start
	%Settings_PanelContainer.visible = start
	
	# audio
	if start:
		AudioServer.set_bus_effect_enabled(musicAudioBus, musicHPIdx, true)
		AudioServer.set_bus_effect_enabled(musicAudioBus, musicLPIdx, true)
		musicHP.cutoff_hz = 350
		musicLP.cutoff_hz = 2000	
	else:
		if pauseTween:	# dont double tween
			pauseTween.kill()
		pauseTween = create_tween()
		pauseTween.set_trans(Tween.TRANS_SINE)
		pauseTween.set_ease(Tween.EASE_OUT)
		pauseTween.parallel().tween_property(musicHP, "cutoff_hz", 20.0, 0.2)
		pauseTween.parallel().tween_property(musicLP, "cutoff_hz", 20500.0, 0.4)
		pauseTween.finished.connect(func():
			AudioServer.set_bus_effect_enabled(musicAudioBus, musicHPIdx, false)
			AudioServer.set_bus_effect_enabled(musicAudioBus, musicLPIdx, false)
		)

## deprecated game restart
func reset_scene():
	push_warning("reset_scene(): is deprecated, use gameEnd()/gameStart()")
	get_tree().reload_current_scene()

## spawn 1 enemy somewhere on the SpawnLine
func spawn_enemy(type="res://enemies/enemy_melee.tscn") -> void:
	var randValue := randf()
	#print("enemy spawn: ", type, ", ", randValue)
	var enemy = load(type).instantiate()
	%PathFollow2D.progress_ratio = randValue
	enemy.global_position = %PathFollow2D.global_position
	enemy.death.connect(_on_enemy_death)
	if 'animate' in enemy: enemy.animate = animate
	enemyContainer.add_child(enemy)

## update the animate value of some children
func updateAnimate() -> void:
	player.animate = animate
	rot.animate = animate
	player.animateUpdate()
	rot.animateUpdate()
	for e in enemyContainer.get_children():
		if "animate" in e:
			e.animate = animate
#endregion HELPER

#region SIGNALS
##  called on all enemy deaths
func _on_enemy_death(entity, _position) -> void:
	if 'score' in entity:
		score += entity.score
	elif 'max_health' in entity:
		score += entity.max_health
	else:
		push_warning("_on_enemy_death: entity has no 'score' or 'max_health'")
		score += 1
	scoreUI.text = str(score)

## called by enemySpawnTimer
func _on_enemy_spawn_timer_timeout() -> void:
	spawn_enemy()

## called by spawnTimeTimer
func _on_spawn_time_timer_timeout() -> void:
	# make the spawning of enemies faster
	var multi = 1.
	if spawnTimer.get_wait_time() > 1.0:
		multi = 0.8
	if spawnTimer.get_wait_time() > 0.6:
		multi = 0.9
	else:
		multi = 0.96
	spawnTimer.set_wait_time(spawnTimer.get_wait_time() * multi)
	#print(spawnTimer.get_wait_time())

func _on_player_player_death() -> void:
	anim_death()
	gameEnd()

func anim_death() -> void:
	if animTween:
		animTween.kill()
	animTween = create_tween()
	animTween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	animTween.set_trans(Tween.TRANS_EXPO)
	animTween.set_ease(Tween.EASE_OUT)
	var o = camera.zoom
	var val = o + Vector2(0.03, 0.03)
	animTween.tween_property(camera, "zoom", val, 0.01)
	animTween.tween_property(camera, "zoom", o, 0.1)
	pass

## force wait timer before allowing to restart
func _on_restart_delay_timeout() -> void:
	startable = true

func _on_animate_check_box_toggled(toggled_on: bool) -> void:
	animate = toggled_on
	updateAnimate()
	pass # Replace with function body.
#endregion SIGNALS

#region AUDIO
func _on_music_hslider_drag_ended(_value_changed: bool) -> void:
	AudioServer.set_bus_volume_linear(musicAudioBus, musicSlider.value)
func _on_sfx_hslider_drag_ended(_value_changed: bool) -> void:
	AudioServer.set_bus_volume_linear(sfxAudioBus, sfxSlider.value)
#endregion AUDIO
