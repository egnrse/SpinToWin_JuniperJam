extends RigidBody2D

signal did_damage(amount:int)		## emited when [member self] damages sth else

@export var anker : Node2D			## where the object is attached to

@export_subgroup("Rope", "rope")
@export var rope_length := 80.0		## when the rope starts pulling
@export var rope_strength := 70.0	## how strong the rope pulls if streched
@export var rope_max := 400.0		## max distance before clipping position (disable: -1)
@export var rope_max_f := 60		## max force (when to start limiting the force applied to [member self])

@export_subgroup("Damage")
@export var base_damage := 1			## the damage collisions with [member self] do to others (by calling other.damage())
@export var crit1_damage := 2			## the damage a critical hit level1 does (see [member crit1_speed])
@export var crit1_speed := 7000.		## how much speed is needed for a crit1 hit
@export var crit2_damage := 3			## the damage a critical hit level2 does (see [member crit2_speed])
@export var crit2_speed := 8000.		## how much speed is needed for a crit2 hit

@export_subgroup("more")
@export var animate := true				## if animations should be shown

var potents := 2.	## increase rope force with distance**potents

# values for speed streching
var pre_angle := self.rotation	## angle of [member self] in the previous tick
var pre_stretch := 1.0			## stretch multiplier in the previous tick
@onready var strechObjs := [$DamageArea/DamageShape, $ColorRect, $Sprite2D, $Particles]	## which objects to apply stretching to

# values for enemy collisions
var pre_pos := self.global_position	## position of [member self] in the previous tick

func _physics_process(_delta: float) -> void:
	# connect self to anker
	var deltaX = 0.016	# internet said dont use delta, so we do this now
	var diff = anker.global_position - self.global_position
	
	# limit the max amount of rope length
	if rope_max > 0 and diff.length() > rope_max:
		#global_position = anker.global_position - diff.normalized() * rope_max	#deprecated, does not catch collisions
		var target = anker.global_position - diff.normalized() * rope_max
		# raycast to catch colisions when teleporting the obj
		# (does not fully work, try shape casting?)
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(self.global_position, target)
		query.exclude = [self, anker]
		var result = space_state.intersect_ray(query)
		if result:
			# do nothing on collision
			#print("Collision: ", result.position)
			pass
		else:
			global_position = target
	
	# normal rope pull
	if diff.length() > rope_length:
		var f = diff.normalized() * (diff.length() - rope_length)**potents * rope_strength
		# limit to high forces
		if f.length()*deltaX > diff.length()*rope_max_f:
			#print("Limiting ", f*deltaX)
			f = diff*rope_max_f**potents
		self.apply_central_force(
			f * deltaX 
		)
		#print(f*delta)
	#print(diff.length())
	
	# rotate in the direction of the speed
	var angle = linear_velocity.angle()
	var correction = (angle-pre_angle)/2	# try to look into the future
	for obj in strechObjs:
		obj.rotation = angle + correction
	pre_angle = angle
	
	# deform with speed
	var speed := linear_velocity.length()
	var stretch: float = round(speed / 1000.0) * 0.1 + 1.0
	# dont update all the time
	if abs(stretch - pre_stretch) > 0.05:
		pre_stretch = stretch
		update_stretch(stretch)
	#print(stretch)
	
	# shapecast collisions from here to pre_pos
	var cast = $DamageArea/ShapeCast2D
	cast.target_position = self.global_position - pre_pos
	cast.force_shapecast_update()
	for collision in cast.get_collision_count():
		collide(cast.get_collider(collision), speed)
	pre_pos = global_position
	
	# audio
	var audio := $AudioStreamPlayer2D
	var pitch: float = speed / 25000.0 + 0.6
	var volume: float = min(speed / 10000.0, 1)**2 * 0.36
	audio.pitch_scale = pitch
	audio.volume_linear = volume
	
	# particles!
	var speedPart := $Particles/Speed
	if animate:
		if speed > crit1_speed:
			speedPart.emitting = true
			var a:float = (speed-crit1_speed)/(crit2_speed-crit1_speed)
			speedPart.color.a = min(a*0.7,1)
		else:
			speedPart.emitting = false
	else:
		speedPart.emitting = false
	
func update_stretch(stretch:float) -> void:
	for obj in strechObjs:
		obj.scale.x = stretch
	pass

func collide(body: Node2D, speed: float = 1.) -> void:
	#print(body)
	if body.has_method("damage"):
		# calc damage from speed
		var damage = base_damage
		if speed > crit1_speed:
			damage = crit1_damage
		# animate
		if animate:
			var part := $Particles/Damage
			if "alive" in body and body.alive:
				if damage > base_damage:
					part.emitting = true
		# damage enemy
		body.damage(damage)
		did_damage.emit(damage)

## reset everything
func reset() -> void:
	pre_angle = 0
	pre_stretch = 1
	pre_pos = self.global_position
	update_stretch(1)
