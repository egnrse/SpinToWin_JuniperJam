# class for enemies
class_name EnemyBase
extends CharacterBody2D

@onready var Player = get_node("/root/Game/Player")
@onready var Game = get_node("/root/Game/")

signal damaged(entity, amount:int)		## emited when [member self] is damaged
signal death(entity,position:Vector2)	## emited when [member self] dies

@export var max_health := 2			## max health
@export var speed := 100			## movement speed

var health := max_health			## current health
var alive := true					## if [member self] is currently alive

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.init()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

## init some basic things
func init() -> void:
	health = max_health
	alive = true

## call to damage [member self] (decreases [member health])
func damage(amount: int = 1) -> void:
	print("damage: ", amount)	#dev
	self.health -=amount
	damaged.emit(self, amount)
	
	if health <= 0:
		self.die()

## called when [member health] <= 0
func die() -> void:
	death.emit(self, self.global_position)
	alive = false
	queue_free()
