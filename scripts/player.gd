class_name player
extends CharacterBody3D

@onready var maincamera : Camera3D = %maincamera
@onready var camerapivot : Node3D = %camerapivot
@onready var canvas = %canvas
@onready var debugtext : Label3D = %debug

@onready var lefthand : Sprite3D = %lefthand
@onready var righthand : Sprite3D = %righthand
@onready var LHdefaultpos : Vector3 = lefthand.position
@onready var RHdefaultpos : Vector3 = righthand.position
var LHtargetpos : Vector3
var RHtargetpos : Vector3
@onready var hand1 : Texture2D = preload("res://textures/hand1.png")
@onready var hand2 : Texture2D = preload("res://textures/hand2.png")



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
var accel := 2.0
var slowaccelrate = 2.0

var gravity := 1.5
var jumpforce := 30.0

var jumptimer := -1.0
var hititemtimer := -1.0

var inputdir : Vector2
var lmbpressed : float
var rmbpressed : float
var Epressed : float
var Qpressed : float


func take_input(delta : float) -> void:
	var inputbuffer : float = delta * 5.0
	lmbpressed = boolinputasbuffer(Input.is_action_just_pressed("lmb"), lmbpressed, inputbuffer)
	rmbpressed = boolinputasbuffer(Input.is_action_just_pressed("rmb"), rmbpressed, inputbuffer)
	Epressed = boolinputasbuffer(Input.is_action_just_pressed("E"), Epressed, inputbuffer)
	Qpressed = boolinputasbuffer(Input.is_action_just_pressed("Q"), Qpressed, inputbuffer)
	inputdir = Input.get_vector("left", "right", "up", "down");
	inputdir = inputdir.normalized()
	
func boolinputasbuffer(b : bool, bf : float, delta : float) -> float:
	if b:
		return 1.0
	bf -= delta
	return bf
	
func _physics_process(delta: float) -> void:
	
	take_input(delta)
	
	var v := velocity
	
	
	print(Qpressed)
	do_camera_tilt()
	
	var wishdir := (camerapivot.transform.basis * Vector3(inputdir.x, 0, inputdir.y)).normalized()
	
	var realmaxspeed := maxspeed
	if abs(inputdir.x) > .5:
		realmaxspeed *= 1.01
	
	var dot = wishdir.dot(velocity.normalized())
	if dot < .95 and dot > .5:
		realmaxspeed *= 1.3
	 
	v += wishdir * accel * clampf(realmaxspeed / v.length(), 0.0, slowaccelrate)
	
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
	
	hititemtimer -= delta
	for i in get_slide_collision_count():
		var col = get_slide_collision(i).get_collider()
		if col is RigidBody3D and hititemtimer < 0.0:
			hititemtimer = .3
			var normal = -1.0 * get_slide_collision(i).get_normal()
			var forcevector : Vector3 = Vector3(0, 3.0, 0) + normal * 10.0
			col.apply_central_impulse(forcevector)
			#velocity += forcevector * -2.0
			
	
	debugtext.text = "%0.2f" % sqrt( pow(velocity.x, 2) + pow(velocity.z, 2) ) + "\n" + str(Engine.get_frames_per_second())
	
	pstate.PhysUpdate(self)
	pstate.AnimateHands(self)
	var lerpvalue = .04
	righthand.position = lerp(righthand.position, RHtargetpos, lerpvalue)
	lefthand.position = lerp(lefthand.position, LHtargetpos, lerpvalue)
	
	interact_items()
	held_items()

func do_camera_tilt() -> void:
	camerapivot.rotation.z = lerpf(camerapivot.rotation.z, -1.0 * inputdir.x * .05, .2)
	
var LHitem : Item
var RHitem : Item

func interact_items() -> void:
	
	var pitch = maincamera.rotation.x
	var yaw = camerapivot.rotation.y
	var facing = Vector3(cos(pitch) * sin(yaw),-sin(pitch), cos(pitch) * cos(yaw)).normalized()
	if Epressed >= 1.0 and LHitem:
		LHitem.state = LHitem.Neutral.new(LHitem)
		LHitem.global_position = global_position + facing * -4
		LHitem = null
		return
	if Qpressed >= 1.0 and RHitem:
		RHitem.state = RHitem.Neutral.new(RHitem)
		RHitem.global_position = global_position + facing * -4
		RHitem = null
		return
			
	
	var raylength := 10
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()

	var origin = maincamera.project_ray_origin(mousepos)
	var end = origin + maincamera.project_ray_normal(mousepos) * raylength
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true

	var result = space_state.intersect_ray(query)
	var col = result.get("collider")
	if col is Item:
		var colasitem : Item = col
		if Epressed >= 1.0 and !LHitem:
			LHitem = colasitem
			LHitem.state = LHitem.Held.new(LHitem, 1)
			return
		if Qpressed >= 1.0 and !RHitem:
			RHitem = colasitem
			RHitem.state = RHitem.Held.new(RHitem, -1)
			return
		
			

func held_items() -> void:
	if Qpressed > 0.0:
		lefthand.texture = hand2
	else:
		lefthand.texture = hand1
		
	if Epressed > 0.0:
		righthand.texture = hand2
	else:
		righthand.texture = hand1
		
		
@onready var pstate : PlayerState = Neutral.new();
	
	
	
	
	
	
	
	
@abstract class PlayerState:
	var yvelocitystep := 0.0
	var xvelocitystep := 1
	@abstract func PhysUpdate(p : player) -> void
	@abstract func AnimateHands(p : player) -> void
	var debugstate := false
	
class Neutral extends PlayerState:
	func PhysUpdate(p : player) -> void:
		if debugstate:
			print("neutral")
		if p.velocity.y > yvelocitystep:
			p.pstate = Ascending.new()
		elif p.velocity.y < yvelocitystep:
			p.pstate = Falling.new()
		elif p.inputdir.length() > 0.0:
			p.pstate = Moving.new()
	func AnimateHands(p : player) -> void:
		p.LHtargetpos = p.LHdefaultpos
		p.RHtargetpos = p.RHdefaultpos
		return
		
class Moving extends PlayerState:
	func PhysUpdate(p : player) -> void:
		if debugstate:
			print("moving")
		if p.velocity.y > yvelocitystep:
			p.pstate = Ascending.new()
		elif p.velocity.y < yvelocitystep:
			p.pstate = Falling.new()
		elif !p.inputdir.length() > 0.0:
			p.pstate = Neutral.new()
	func AnimateHands(p : player) -> void:
		var lhadd := Vector3(sin((Time.get_ticks_msec() + 50) * .005) * .1, sin(Time.get_ticks_msec() * .01) * .2, 0)
		var rhadd := Vector3(sin((Time.get_ticks_msec() + 60) * .005) * .1, sin((Time.get_ticks_msec() + 100) * .01) * .2, 0)
		lhadd.x += p.inputdir.x * .3
		rhadd.x += p.inputdir.x * .3
		p.LHtargetpos = p.LHdefaultpos + lhadd
		p.RHtargetpos = p.RHdefaultpos + rhadd
		return
		
class Ascending extends PlayerState:
	func PhysUpdate(p : player) -> void:
		if debugstate:
			print("asc")
		if p.velocity.y <= 0.0:
			p.pstate = Neutral.new()
	func AnimateHands(p : player) -> void:
		var lhadd := Vector3(0, .2, .2)
		var rhadd := Vector3(0, .2, .2)
		lhadd.x += p.inputdir.x * .3
		rhadd.x += p.inputdir.x * .3
		p.LHtargetpos = p.LHdefaultpos + lhadd
		p.RHtargetpos = p.RHdefaultpos + rhadd
		return
		
class Falling extends PlayerState:
	func PhysUpdate(p : player) -> void:
		if debugstate:
			print("fall")
		if p.velocity.y >= 0.0:
			p.pstate = Neutral.new()
	func AnimateHands(p : player) -> void:
		var lhadd := Vector3(0, -.6, -.2)
		var rhadd := Vector3(0, -.6, -.2)
		lhadd.x += p.inputdir.x * .3
		rhadd.x += p.inputdir.x * .3
		p.LHtargetpos = p.LHdefaultpos + lhadd
		p.RHtargetpos = p.RHdefaultpos + rhadd
		return
	
	
	
	
