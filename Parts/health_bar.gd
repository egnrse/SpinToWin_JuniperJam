## a healthbar for parent
extends ProgressBar

@export var parent: Node2D		## expects [member parent.health], [member parent.max_health] to exist
@export var barColor := Color("777")	## the color of the healthbar
@export var autohideTime := 5.	## after how many seconds to hide the healthbar again

func _ready() -> void:
	var sb = StyleBoxFlat.new()
	add_theme_stylebox_override("fill", sb)
	sb.bg_color = barColor
	
	$Timer.wait_time = autohideTime
	self.max_value = parent.max_health
	self.value = parent.health

## call this update and to show the bar
func update() -> void:
	self.value = parent.health
	self.visible = true
	$Timer.start()

## hide the healthbar if nothing changes on it
func _on_timer_timeout() -> void:
	self.visible = false
