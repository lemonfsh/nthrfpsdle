extends RigidBody3D
class_name Item

var itemdata : ItemData

@onready var sprite3d : Sprite3D = get_node("sprite")
@onready var playe : CharacterBody3D = %player
@onready var map = %map
@onready var uicamera = %uicamera
var state : ItemState
func _ready() -> void:
	state = Neutral.new(self)
	itemdata = Stick.new()
	sprite3d.texture = itemdata.image

func _process(delta: float) -> void:
	state.on_process(delta, self)
	



@abstract class ItemState:
	var name : String
	var localvar := 0.0
	@abstract func on_process(delta : float, item : Item) -> void


class Neutral extends ItemState:
	func _init(item : Item) -> void:
		item.sprite3d.look_at(item.playe.position)
		item.get_parent().remove_child(item)
		item.map.add_child(item)
		item.sprite3d.set_layer_mask_value(2, false)
		item.sprite3d.set_layer_mask_value(1, true)
		
	@warning_ignore("unused_parameter")
	func on_process(delta : float, item : Item) -> void:
		item.sprite3d.look_at(item.playe.position)
		
		
class Held extends ItemState:
	func _init(item : Item, localv) -> void:
		localvar = localv
		item.get_parent().remove_child(item)
		item.uicamera.add_child(item)
		item.sprite3d.set_layer_mask_value(2, true)
		item.sprite3d.set_layer_mask_value(1, false)
		item.position = Vector3(localvar, -2, -4)
		item.sprite3d.rotation = Vector3(0, 0, 0)
		item.rotation = Vector3(0, 0, 0)
	@warning_ignore("unused_parameter")
	func on_process(delta : float, item : Item) -> void:
		item.position = Vector3(localvar, -2, -4)
		
		
		
		


@abstract class ItemData:
	var name : String
	var image : Texture2D
	func AssignImage() -> void:
		image = load("res://textures/" + name + ".png")
	
class Stick extends ItemData:
	func _init() -> void:
		name = "stick"
		AssignImage()
