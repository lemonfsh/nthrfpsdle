@warning_ignore_start("unused_parameter")
extends RigidBody3D
class_name Item



@onready var sprite3d : Sprite3D = get_node("sprite")
@onready var player : CharacterBody3D = %player
@onready var playerScript : Player = player as Player
@onready var map = %map
@onready var uicamera = %uicamera
var state : ItemState

@export var itemDataAsString : String
var itemdata : ItemData

@export var interactable : bool = true

func _ready() -> void:
	state = Neutral.new(self)
	itemdata = create_instance("res://scripts/item.gd", itemDataAsString)
	if !itemdata:
		print("NO ITEM DATA STRING")
		itemdata = Stick.new()
	sprite3d.texture = itemdata.image

func _process(delta: float) -> void:
	state.on_process(delta, self)

@onready var drop_me_connect = Event.dropitem.connect(drop_me)
func drop_me(whichhand : float) -> void:
	if abs(whichhand - state.whichhand) < .1 and state is Held:
		var facing : Vector3 = playerScript.get_facing()
		state = Neutral.new(self)
		var ray = playerScript.cameraraycast(5)
		var pos = ray.get("position")
		var dist : float
		if !pos:
			dist = 4.0
		else:
			dist = playerScript.global_position.distance_to(pos)
		global_position = playerScript.global_position + facing * -.8 * dist + Vector3(0, .8, 0) 
		if whichhand < 0.0:
			playerScript.LHitem = null
		else:
			playerScript.RHitem = null
		
@onready var pickup_me_connect = Event.pickupitem.connect(pickup_me)
func pickup_me(whichhand : float, globalpos : Vector3):
	if state is Neutral and globalpos.distance_to(global_position) < .1:
		state = Held.new(self, whichhand)
		if whichhand < 0.0: 
			playerScript.LHitem = self
		else:
			playerScript.RHitem = self
			
@onready var use_me_connect = Event.useitem.connect(use_me)
func use_me(whichhand : float):
	if abs(whichhand - state.whichhand) < .1 and state is Held:
		itemdata.on_use(self)

@onready var launch_me_connect = Event.launch.connect(launch_me)
func launch_me(pos : Vector3, ramge : float, strength : float, playerimmune : bool):
	if pos.distance_to(global_position) > .01 and state is Neutral:
		var dist : float = pos.distance_to(global_position)
		if dist < ramge:
			var dir = (global_position - pos).normalized()
			dir.y = max(.2, 0)
			apply_impulse((1.0 - (dist / ramge)) * strength * dir)
			Event.launcheffect(global_position, map)


@abstract class ItemState:
	var name : String
	var whichhand := 0.0
	@abstract func on_process(delta : float, item : Item) -> void


class Neutral extends ItemState:
	func _init(item : Item) -> void:
		if !item.get_parent().name.contains("map"):
			item.get_parent().remove_child(item)
			item.map.add_child(item)
		item.sprite3d.set_layer_mask_value(2, false)
		item.sprite3d.set_layer_mask_value(1, true)
		item.sprite3d.pixel_size = .01
		item.sprite3d.flip_h = false
	func on_process(delta : float, item : Item) -> void:
		return
		
		
class Held extends ItemState:
	func _init(item : Item, whichH : float) -> void:
		whichhand = whichH
		item.get_parent().remove_child(item)
		var hand  
		if whichH < 0.0: 
			hand = item.playerScript.lefthand
		else:
			hand = item.playerScript.righthand
		hand.add_child(item)
		item.sprite3d.set_layer_mask_value(2, true)
		item.sprite3d.set_layer_mask_value(1, false)
		item.position = Vector3(whichhand * 1.8, -.6, -4)
		item.sprite3d.pixel_size = .02
		if whichH < 0:
			item.sprite3d.flip_h = true
	func on_process(delta : float, item : Item) -> void:
		item.position = Vector3(whichhand * 1.8, -.6, -4)
		
		
		
		
		
func create_instance(script_path: String, classname: String) -> Object:
	var script = load(script_path)
	if not script:
		return null
	var cls = script.get(classname)
	if not cls:
		return null
	return cls.new()

@abstract class ItemData:
	var name : String
	var image : Texture2D
	func AssignImage() -> void:
		image = load("res://textures/" + name + ".png")
	@abstract func on_use(item : Item) -> void
	

class Stick extends ItemData:
	func _init() -> void:
		name = "stick"
		AssignImage()
	func on_use(item : Item) -> void:
		print("used stick")
		
class Launcher extends ItemData:
	func _init() -> void:
		name = "ball"
		AssignImage()
	func on_use(item : Item) -> void:
		Event.dropitem.emit(item.state.whichhand)
		Event.launch.emit(item.global_position, 20.0, 50.0, false)
	
