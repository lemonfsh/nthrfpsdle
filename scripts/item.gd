extends Node
class_name Item

var itemdata : ItemData

@onready var sprite3d : Sprite3D = get_node("sprite")

func _ready() -> void:
	
	itemdata = Stick.new()
	sprite3d.texture = itemdata.image
	print("im item")







@abstract class ItemData:
	var name : String
	var image : Texture2D
	func AssignImage() -> void:
		image = load("res://textures/" + name + ".png")
	
class Stick extends ItemData:
	func _init() -> void:
		name = "stick"
		AssignImage()
