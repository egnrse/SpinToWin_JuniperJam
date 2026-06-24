## a healthbar for parent
extends ProgressBar

@export var parent: Node2D		## expects [member parent.health], [member parent.max_health] to exist
@export var barColor := Color("777")	## the color of the healthbar
@export var autohideTime := 5.	## after how many seconds to hide the healthbar again

var animTween: Tween

func _ready() -> void:
	var sb = StyleBoxFlat.new()
	add_theme_stylebox_override("fill", sb)
	sb.bg_color = barColor
	
	$Timer.wait_time = autohideTime
	self.max_value = parent.max_health
	self.value = parent.health

## call this update and to show the bar
func update() -> void:
	if "animate" in parent and not parent.animate: 
		self.value = parent.health
	else:
		anim_update()
	self.visible = true
	$Timer.start()

func anim_update(speed:float=0.08) -> void:
	if animTween: animTween.kill()
	animTween = create_tween()
	animTween.set_trans(Tween.TRANS_EXPO)
	animTween.set_ease(Tween.EASE_OUT)
	animTween.tween_property(self, "value", parent.health, speed)
	await animTween.finished

## hide the healthbar if nothing changes on it
func _on_timer_timeout() -> void:
	self.visible = false
