extends Node3D

@export var itemDataAsString : String 
@onready var map = %map
var itemdata : Item.ItemData

var itemprefab = preload("res://entities/item.tscn")
func _ready() -> void:
	itemdata = create_instance("res://scripts/item.gd", itemDataAsString)
	var part : Item  = itemprefab.instantiate()
	part.name = "asdjiaosjd"
	return
	
	
var spawndelay : float
func _physics_process(delta: float) -> void:
	spawndelay += delta
	if spawndelay > 2.0:
		spawndelay = 0.0
		var d : Node = get_tree().get_current_scene()
		var found : bool = false
		for i : Item in get_items(d):
			if i.itemDataAsString.match(itemDataAsString):
				if i.global_position.distance_to(global_position) < 10.0:
					found = true
					print("found one ", i)
		if !found:
			print("spaoned on")
			var part : Item  = itemprefab.instantiate()
			part.itemDataAsString = itemDataAsString
			map.add_child(part)
			part.global_position = global_position
	
	




func create_instance(script_path: String, classname: String) -> Object:
	var script = load(script_path)
	if not script:
		return null
	var cls = script.get(classname)
	if not cls:
		return null
	return cls.new()
	
func get_items(parent : Node) -> Array:
	var matches = []
	for node : Node in parent.get_children():
		if node is Item:
			matches.append(node)
		else:
			matches += get_items(node)
	return matches
