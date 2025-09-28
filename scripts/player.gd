extends CharacterBody3D

@onready var mainCamera : Camera3D = %MainCamera
@onready var camerapivot : Node3D = %camerapivot

var sens : Vector2 = Vector2(1.0, 1.0)

enum States {NORMAL}
@onready var state := States.NORMAL

func _ready() -> void:
	wall_min_slide_angle = .01
	
	


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camerapivot.rotate_y(-event.relative.x * .005 * sens.y)
		mainCamera.rotate_x(-event.relative.y * .005 * sens.x)
		mainCamera.rotation.x = clamp(mainCamera.rotation.x, -1.5, 1.5)
		


var maxspeed := 6.0
var accel := 3.0

var gravity := 2.0
var jumpforce := 30.0


var jumptimer := -1.0

func _physics_process(delta: float) -> void:
	var v := velocity
	
	var inputdir := Input.get_vector("left", "right", "up", "down");
	var wishdir := (camerapivot.transform.basis * Vector3(inputdir.x, 0, inputdir.y)).normalized()
	
	
	v += wishdir * accel * clampf(maxspeed / v.length(), 0.0, 2.5)
	
	var friction := .98
	if is_on_floor() or is_on_wall():
		friction *= .95
	if wishdir.length() > 0.1:
		friction *= 1.0
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
	
func assign_state() -> void:
	if state == States.NORMAL:
		print()
	
	
	
	
	
	
	
	
	
