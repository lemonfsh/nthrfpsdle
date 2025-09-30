extends RigidBody3D
class_name Item

var itemdata : ItemData

@onready var sprite3d : Sprite3D = get_node("sprite")
@onready var playe : CharacterBody3D = %player

var state : ItemState
func _ready() -> void:
	state = Neutral.new()
	itemdata = Stick.new()
	sprite3d.texture = itemdata.image

func _process(delta: float) -> void:
	state.on_process(delta, self)
	



@abstract class ItemState:
	var name : String
	@abstract func on_process(delta : float, item : Item) -> void

class Neutral extends ItemState:
	func on_process(delta : float, item : Item) -> void:
		item.sprite3d.look_at(item.playe.position)
		
class Held extends ItemState:
	var hand : int # 0 = left, 1 = right 
	func on_process(delta : float, item : Item) -> void:
		print("yes")
		
		


@abstract class ItemData:
	var name : String
	var image : Texture2D
	func AssignImage() -> void:
		image = load("res://textures/" + name + ".png")
	
class Stick extends ItemData:
	func _init() -> void:
		name = "stick"
		AssignImage()
