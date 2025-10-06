@warning_ignore_start("unused_parameter")
extends CharacterBody3D
class_name Player
@onready var maincamera : Camera3D = %maincamera
@onready var camerapivot : Node3D = %camerapivot
@onready var canvas = %canvas
@onready var debugtext : Label3D = %debug
@onready var map = %map
@onready var aud = %audio2
@onready var damageUI : Sprite3D = %damage
@onready var tutorial : Label3D = %tutorial
@onready var gameend : Label3D = %gameend

@onready var lefthand : Sprite3D = %lefthand
@onready var righthand : Sprite3D = %righthand
@onready var LHdefaultpos : Vector3 = lefthand.position
@onready var RHdefaultpos : Vector3 = righthand.position
var LHtargetpos : Vector3
var RHtargetpos : Vector3
@onready var hand1 : Texture2D = preload("res://textures/hand1.png")
@onready var hand2 : Texture2D = preload("res://textures/hand2.png")
@onready var hand3 : Texture2D = preload("res://textures/hand3.png")


var sens : Vector2 = Vector2(1.0, 1.0)





func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
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
var accel := 1.0
var slowaccelrate = 2.0

var gravity := 1.2
var jumpforce := 20.0

var jumptimer := -1.0
var hititemtimer := -1.0

var inputdir : Vector2
var lmbpressed : float
var rmbpressed : float
var Epressed : float
var Qpressed : float
var Fpressed : float

func take_input(delta : float) -> void:
	var inputbuffer : float = delta * 5.0
	lmbpressed = boolinputasbuffer(Input.is_action_just_pressed("lmb"), lmbpressed, inputbuffer)
	rmbpressed = boolinputasbuffer(Input.is_action_just_pressed("rmb"), rmbpressed, inputbuffer)
	Epressed = boolinputasbuffer(Input.is_action_just_pressed("E"), Epressed, inputbuffer)
	Qpressed = boolinputasbuffer(Input.is_action_just_pressed("Q"), Qpressed, inputbuffer)
	Fpressed = boolinputasbuffer(Input.is_action_just_pressed("F"), Fpressed, inputbuffer)
	inputdir = Input.get_vector("left", "right", "up", "down");
	inputdir = inputdir.normalized()
	
func boolinputasbuffer(b : bool, bf : float, delta : float) -> float:
	if b:
		return 1.0
	bf -= delta
	return bf
	
	
var Gtimer : float = 0.0
func _physics_process(delta: float) -> void:
	if !Event.gameended:
		Gtimer += delta
	
	take_input(delta)
	
	var v := velocity
	
	do_camera_tilt()
	
	var wishdir := (camerapivot.transform.basis * Vector3(inputdir.x, 0, inputdir.y)).normalized()
	
	var realmaxspeed := maxspeed
	if abs(inputdir.x) > .5:
		realmaxspeed *= 1.01
	
	var dot = wishdir.dot(velocity.normalized())
	if dot < .95 and dot > .5:
		realmaxspeed *= 1.3
	 
	v += wishdir * accel * clampf(realmaxspeed / v.length(), 0.0, slowaccelrate)
	
	var friction := .98
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
		Event.play_sound(aud, "jump.wav", .03, 1.0)
		
	v.y -= gravity
	velocity = v;
	
	
	move_and_slide()
	
	hititemtimer -= delta
	for i in get_slide_collision_count():
		var col : Object = get_slide_collision(i).get_collider()
		
		if col is RigidBody3D and hititemtimer < 0.0:
			hititemtimer = .3
			var colasrb : RigidBody3D = col as RigidBody3D
			var pos : Vector3 = colasrb.global_position
			var dir : Vector3 = (global_position - pos).normalized()
			pos += dir  * 2
			Event.launch.emit(pos, 5.0, 30.0, true)
			Event.launcheffect(pos, map)
			Event.play_sound(aud, "jump.wav", .1, 3.0)
			
	
	debugtext.text = "%0.2f" % sqrt( pow(velocity.x, 2) + pow(velocity.z, 2) ) + "\n" + str(Engine.get_frames_per_second())
	debugtext.text = ""
	pstate.PhysUpdate(self)
	pstate.AnimateHands(self)
	var lerpvalue = .04
	righthand.position = lerp(righthand.position, RHtargetpos, lerpvalue)
	lefthand.position = lerp(lefthand.position, LHtargetpos, lerpvalue)
	
	interact_items()
	held_items()
	handle_health_and_death(delta)
	
	
		
	if Fpressed > 0.0:
		hp = -2
	tutorial.text = Event.tutorialtooltip
	
	if Event.gameended:
		var srr : String =  str(int(Gtimer * 100.0) / 100.0)
		gameend.text = "TRUTH FOUND IN: " + srr + "\nSECRETS: " + str(Event.secrets) + "/7"
		
	if global_position.y < -100.0:
		hp -= .05

func do_camera_tilt() -> void:
	camerapivot.rotation.z = lerpf(camerapivot.rotation.z, inputdir.x * -.03, .2)
	
var LHitem : Item
var RHitem : Item

@onready var topleft : Sprite3D = %topleft
@onready var topright : Sprite3D = %topright
@onready var bottomleft : Sprite3D = %bottomleft
@onready var bottomright : Sprite3D = %bottomright

@onready var inspect : Label3D = %inspect

func interact_items() -> void:
	
	if Qpressed >= 1.0 and LHitem:
		Event.dropitem.emit(-1.0)
		return
	if Epressed >= 1.0 and RHitem:
		Event.dropitem.emit(1.0)
		return
			
	if lmbpressed >= 1.0:
		Event.useitem.emit(-1.0)
	if rmbpressed >= 1.0:
		Event.useitem.emit(1.0)
		
	var result = cameraraycast(8)
	var col = result.get("collider")
	if col is Item:
		var colasitem : Item = col
		if colasitem.interactable:
			var shapeobj : CollisionShape3D = col.get_node("shape")
			var focus : Array = focus_on_bounds(shapeobj, maincamera)
			topleft.global_position = focus[0]
			topright.global_position = focus[1]
			bottomleft.global_position = focus[2]
			bottomright.global_position = focus[3]
			
			inspect.text = colasitem.itemdata.name
			inspect.global_position = lerp(topleft.global_position, bottomleft.global_position, .5)
			
			if colasitem.state is Item.Neutral and Event.tutorialdone > 0:
				Event.tutorialtooltip = "Q - E to pickup / drop"
			if colasitem.state is Item.EntityNeutral and Event.tutorialdone > 0:
				Event.tutorialtooltip = "Q - E to talk"
			
			if Qpressed >= 1.0 and !LHitem:
				colasitem.pickup_me(-1.0, colasitem.global_position)
				return
			if Epressed >= 1.0 and !RHitem:
				colasitem.pickup_me(1.0, colasitem.global_position)
				return
			return
	var outofview : Vector3 = Vector3(0, 99, 0)
	topleft.global_position = outofview
	topright.global_position = outofview
	bottomleft.global_position = outofview
	bottomright.global_position = outofview
	inspect.global_position = outofview
	inspect.text = ""
	
	if (RHitem or LHitem) and Event.tutorialdone > 0:
		Event.tutorialtooltip = "Left Click / Right Click to USE item"
		return
	Event.tutorialtooltip = ""

func held_items() -> void:
	if LHitem:
		lefthand.texture = hand3
	else:
		if Qpressed > 0.0:
			lefthand.texture = hand2
		else:
			lefthand.texture = hand1
	if RHitem:
		righthand.texture = hand3
	else:
		if Epressed > 0.0:
			righthand.texture = hand2
		else:
			righthand.texture = hand1
		
func focus_on_bounds(collision_shape: CollisionShape3D, camera: Camera3D) -> Array:
	if not collision_shape or not camera:
		push_error("Missing collision_shape or camera")
		return []

	var shape = collision_shape.shape
	if not shape or not (shape is BoxShape3D):
		push_error("focus_on_box_shape: supplied CollisionShape3D does not contain a BoxShape3D")
		return []

	var ext = shape.extents   

	var local_corners = [
		Vector3( ext.x,  ext.y,  ext.z),
		Vector3( ext.x,  ext.y, -ext.z),
		Vector3( ext.x, -ext.y,  ext.z),
		Vector3( ext.x, -ext.y, -ext.z),
		Vector3(-ext.x,  ext.y,  ext.z),
		Vector3(-ext.x,  ext.y, -ext.z),
		Vector3(-ext.x, -ext.y,  ext.z),
		Vector3(-ext.x, -ext.y, -ext.z),
	]

	var world_corners: Array = []
	for lc in local_corners:
		world_corners.append(collision_shape.global_transform * lc)

	var screen_points: Array = []
	for wc in world_corners:
		if camera.is_position_behind(wc):
			screen_points.append(null) 
		else:
			screen_points.append(camera.unproject_position(wc))

	var valid := []
	for sp in screen_points:
		if sp != null:
			valid.append(sp)

	if valid.is_empty():
		return []

	var min_x = valid[0].x
	var max_x = min_x
	var min_y = valid[0].y
	var max_y = min_y
	for p in valid:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var top_left     = Vector2(min_x, min_y)
	var top_right    = Vector2(max_x, min_y)
	var bottom_right = Vector2(max_x, max_y)
	var bottom_left  = Vector2(min_x, max_y)
	
	var realsc = []
	for sc in [top_left, top_right, bottom_left, bottom_right]:
		realsc.append(camera.project_position(sc, .4))
		
	return realsc

func cameraraycast(length : float) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var center = get_viewport().get_visible_rect().get_center()
	var origin = maincamera.project_ray_origin(center)
	var end = origin + maincamera.project_ray_normal(center) * length
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	return result

func raycast(start : Vector3, end : Vector3) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(start, end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	return result

func get_facing() -> Vector3:
	var pitch = maincamera.rotation.x
	var yaw = camerapivot.rotation.y
	var facing = Vector3(cos(pitch) * sin(yaw),-sin(pitch), cos(pitch) * cos(yaw)).normalized()
	return facing
	
var hp : float = 10.0
var dying : float = 1.0
func handle_health_and_death(delta : float) -> void:
	var maxhp = 10.0
	hp = min(hp, maxhp)
	
	
	var sinvalue : float = sin(Time.get_ticks_msec() * .002) * .05
	
	var col : int = 0
	for b : bool in Event.collection_status:
		if b:
			col += 1
	if col >= 5:
		sinvalue *= 6.0
	
	
	
	var realvalue : float = (1.0 - hp / 10.0) + sinvalue
	damageUI.material_override.set_shader_parameter("dissolve_value", realvalue)
	if dying < 0.0:
		dying -= delta
		
	if hp <= 0.0 and dying > 0.0:
		dying = -.1
		
	if dying < -1.0:
		Event.collection_status = [false, false, false, false, false]
		Event.tutorialtooltip = ""
		Event.gameended = false
		Event.secrets = 0
		get_tree().change_scene_to_file("res://entities/map.tscn")
		
	
@onready var launch_me_connect = Event.launch.connect(launch_me)
func launch_me(pos : Vector3, ramge : float, strength : float, playerimmune : bool):
	if playerimmune:
		return
	var dist : float = pos.distance_to(global_position)
	if dist < ramge:
		var dir = (global_position - pos).normalized()
		dir.y = max(.2, 0)
		velocity += (1.0 - (dist / ramge)) * strength * dir
		Event.launcheffect(pos, map)
		Event.play_sound(aud, "jump.wav", .1, 3.0)
		
	
@onready var damage_me_connect = Event.damage.connect(damage_me)
func damage_me(pos : Vector3, ramge : float, value : float, playerimmune : bool):
	if playerimmune:
		return
	var dist : float = pos.distance_to(global_position)
	if dist < ramge:
		hp -= value
		Event.play_sound(aud, "hurt1.mp3", .2, 1.0)
		Event.damageeffect(global_position, self)
	
@onready var pstate : PlayerState = Neutral.new();
	
	
	
	
	
	
	
	
@abstract class PlayerState:
	var yvelocitystep := 0.0
	var xvelocitystep := 1
	@abstract func PhysUpdate(p : Player) -> void
	@abstract func AnimateHands(p : Player) -> void
	var debugstate := false
	
class Neutral extends PlayerState:
	func PhysUpdate(p : Player) -> void:
		if debugstate:
			print("neutral")
		if p.velocity.y > yvelocitystep:
			p.pstate = Ascending.new()
		elif p.velocity.y < yvelocitystep:
			p.pstate = Falling.new()
		elif p.inputdir.length() > 0.0:
			p.pstate = Moving.new()
	func AnimateHands(p : Player) -> void:
		p.LHtargetpos = p.LHdefaultpos
		p.RHtargetpos = p.RHdefaultpos
		return
		
class Moving extends PlayerState:
	func PhysUpdate(p : Player) -> void:
		if debugstate:
			print("moving")
		if p.velocity.y > yvelocitystep:
			p.pstate = Ascending.new()
		elif p.velocity.y < yvelocitystep:
			p.pstate = Falling.new()
		elif !p.inputdir.length() > 0.0:
			p.pstate = Neutral.new()
	func AnimateHands(p : Player) -> void:
		var lhadd := Vector3(sin((Time.get_ticks_msec() + 50) * .005) * .1, sin(Time.get_ticks_msec() * .01) * .2, 0)
		var rhadd := Vector3(sin((Time.get_ticks_msec() + 60) * .005) * .1, sin((Time.get_ticks_msec() + 100) * .01) * .2, 0)
		lhadd.x += p.inputdir.x * .3
		rhadd.x += p.inputdir.x * .3
		p.LHtargetpos = p.LHdefaultpos + lhadd
		p.RHtargetpos = p.RHdefaultpos + rhadd
		return
		
class Ascending extends PlayerState:
	func PhysUpdate(p : Player) -> void:
		if debugstate:
			print("asc")
		if p.velocity.y <= 0.0:
			p.pstate = Neutral.new()
	func AnimateHands(p : Player) -> void:
		var lhadd := Vector3(0, .1, .2)
		var rhadd := Vector3(0, .1, .2)
		lhadd.x += p.inputdir.x * .3
		rhadd.x += p.inputdir.x * .3
		p.LHtargetpos = p.LHdefaultpos + lhadd
		p.RHtargetpos = p.RHdefaultpos + rhadd
		return
		
class Falling extends PlayerState:
	func PhysUpdate(p : Player) -> void:
		if debugstate:
			print("fall")
		if p.velocity.y >= 0.0:
			Event.smallhiteffect(p.global_position, p)
			p.pstate = Neutral.new()
	func AnimateHands(p : Player) -> void:
		var lhadd := Vector3(0, -.6, -.2)
		var rhadd := Vector3(0, -.6, -.2)
		lhadd.x += p.inputdir.x * .3
		rhadd.x += p.inputdir.x * .3
		p.LHtargetpos = p.LHdefaultpos + lhadd
		p.RHtargetpos = p.RHdefaultpos + rhadd
		return
	
	
	
	
