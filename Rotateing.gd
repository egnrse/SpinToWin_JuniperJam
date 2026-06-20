extends RigidBody2D

@export var anker : Node2D			## where the object is attached to

@export var rope_length := 80.0		## when the rope starts pulling
@export var rope_strength := 70.0	## how strong the rope pulls if streched
@export var rope_max := 400.0		## max distance before clipping position (disable: -1)
@export var max_f := 60				## when to start limiting the force

var potents := 2	# increase rope force with distance**potents

# values for speed streching
var pre_angle := 0.0
var pre_stretch := 1.0
@onready var strechObjs = [$DamageArea/DamageShape, $ColorRect, $Sprite2D]

# values for enemy collisions
var pre_pos := self.global_position	# previous position

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
		if f.length()*deltaX > diff.length()*max_f:
			#print("Limiting ", f*deltaX)
			f = diff*max_f**potents
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
		collide(cast.get_collider(collision))
	pre_pos = global_position

func update_stretch(stretch:float) -> void:
	for obj in strechObjs:
		obj.scale.x = stretch
	pass

func collide(body: Node2D) -> void:
	#print(body)
	if body.has_method("damage"):
		# damage enemies
		body.damage()
