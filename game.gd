extends Node2D

#@onready var rot := get_node("Rotateing")
#@onready var player := get_node("Player")

# game flow
var startable = true
var score = 0			## increase score on enemy death
@onready var scoreUI := %Score 

# enemies
@onready var spawnTimer := %enemySpawnTimer
@onready var enemies := $Enemies

# audio
@onready var musicSlider := %Music_HSlider
@onready var sfxSlider := %SFX_HSlider
@onready var musicAudioBus := AudioServer.get_bus_index("Music")
@onready var sfxAudioBus := AudioServer.get_bus_index("SFX")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# prepare
	score = 0
	scoreUI.text = str(score)
	AudioServer.set_bus_volume_linear(musicAudioBus, musicSlider.value)
	AudioServer.set_bus_volume_linear(sfxAudioBus, sfxSlider.value)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	startable = false
	# enemy spawns
	spawnTimer.start()
	for n in 4:
		spawn_enemy()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#print("AudioPeak: ", max(AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("Master"), 0), AudioServer.get_bus_peak_volume_right_db(AudioServer.get_bus_index("Master"), 0)))
	pass

func reset_scene():
	get_tree().reload_current_scene()

## spawn 1 enemy somewhere on the SpawnLine
func spawn_enemy(type="res://enemies/enemy_melee.tscn") -> void:
	var randValue := randf()
	#print("enemy spawn: ", type, ", ", randValue)
	var enemy = load(type).instantiate()
	%PathFollow2D.progress_ratio = randValue
	enemy.global_position = %PathFollow2D.global_position
	enemy.death.connect(_on_enemy_death)
	enemies.add_child(enemy)

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
	%DeathScore.text = str(score)
	%GameOver.visible = true
	%Settings_PanelContainer.visible = true
	get_tree().paused = true
	%RestartDelay.start()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_restart_delay_timeout() -> void:
	startable = true

# Music
func _on_music_hslider_drag_ended(_value_changed: bool) -> void:
	AudioServer.set_bus_volume_linear(musicAudioBus, musicSlider.value)
func _on_sfx_hslider_drag_ended(_value_changed: bool) -> void:
	AudioServer.set_bus_volume_linear(sfxAudioBus, sfxSlider.value)
