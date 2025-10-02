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
		item.get_parent().remove_child(item)
		item.map.add_child(item)
		item.sprite3d.set_layer_mask_value(2, false)
		item.sprite3d.set_layer_mask_value(1, true)
		item.sprite3d.pixel_size = .01
		item.sprite3d.flip_h = false
	@warning_ignore("unused_parameter")
	func on_process(delta : float, item : Item) -> void:
		return
		
		
class Held extends ItemState:
	func _init(item : Item, localv, hand) -> void:
		localvar = localv
		item.get_parent().remove_child(item)
		hand.add_child(item)
		item.sprite3d.set_layer_mask_value(2, true)
		item.sprite3d.set_layer_mask_value(1, false)
		item.position = Vector3(localvar * 1.8, -.6, -4)
		item.sprite3d.pixel_size = .02
		if localv < 0:
			item.sprite3d.flip_h = true
	@warning_ignore("unused_parameter")
	func on_process(delta : float, item : Item) -> void:
		item.position = Vector3(localvar * 1.8, -.6, -4)
		
		
		
		
		


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
