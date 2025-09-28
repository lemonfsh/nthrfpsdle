class_name player
extends CharacterBody3D

@onready var maincamera : Camera3D = %maincamera
@onready var camerapivot : Node3D = %camerapivot
@onready var canvas = %canvas
@onready var uiviewport : SubViewport = %ui
@onready var uitexture : TextureRect = %texture

@onready var lefthand : Sprite3D = %lefthand
@onready var righthand : Sprite3D = %righthand

var sens : Vector2 = Vector2(1.0, 1.0)


func _ready() -> void:
	wall_min_slide_angle = .01
	
	
	


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camerapivot.rotate_y(-event.relative.x * .005 * sens.y)
		maincamera.rotate_x(-event.relative.y * .005 * sens.x)
		maincamera.rotation.x = clamp(maincamera.rotation.x, -1.5, 1.5)
		


var maxspeed := 12.0
var accel := 4.0
var slowaccelrate = 5

var gravity := 2.0
var jumpforce := 30.0

var jumptimer := -1.0

func _physics_process(delta: float) -> void:
	
	
	var v := velocity
	
	var inputdir := Input.get_vector("left", "right", "up", "down");
	inputdir = inputdir.normalized()
	inputdir.x *= 1.1
	
	do_camera_tilt(inputdir)
	
	var wishdir := (camerapivot.transform.basis * Vector3(inputdir.x, 0, inputdir.y)).normalized()
	
	
	v += wishdir * accel * clampf(maxspeed / v.length(), 0.0, slowaccelrate)
	
	var friction := .99
	if is_on_floor() or is_on_wall():
		friction *= .95
	if wishdir.length() > 0.1:
		friction *= .98
	else:
		friction *= .95
	friction = min(friction, 1.0)
	v *= friction
	
	
	jumptimer -= delta;
	if Input.get_action_strength("space") > 0.0 and jumptimer < 0.0 and is_on_floor():
		v.y += jumpforce
		jumptimer = .2
		
	v.y -= gravity
	velocity = v;
	
	move_and_slide()
	
	
	pstate.PhysUpdate(self)

func do_camera_tilt(inputdir : Vector2) -> void:
	
	camerapivot.rotation.z = lerpf(camerapivot.rotation.z, -1.0 * inputdir.x * .05, .2)
	
	
		
@onready var pstate : PlayerState = Neutral.new();
	
	
@abstract class PlayerState:
	@abstract func PhysUpdate(p : player) -> void
	
class Neutral extends PlayerState:
	func PhysUpdate(p : player) -> void:
		print("neutral")
		if p.velocity.y > 0.0:
			p.pstate = Ascending.new()
		elif p.velocity.y < 0.0:
			p.pstate = Falling.new()
		
class Ascending extends PlayerState:
	func PhysUpdate(p : player) -> void:
		print("asc")
		if p.velocity.y <= 0.0:
			p.pstate = Neutral.new()
		
class Falling extends PlayerState:
	func PhysUpdate(p : player) -> void:
		print("fall")
		if p.velocity.y >= 0.0:
			p.pstate = Neutral.new()
	
	
	
	
	
