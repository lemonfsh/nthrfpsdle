@warning_ignore_start("unused_parameter")
extends RigidBody3D
class_name Item



@onready var sprite3d : Sprite3D = get_node("sprite")
@onready var player : CharacterBody3D = $"../../player"

@onready var map = $"../../map"
@onready var uicamera = $"../../canvas/SubViewportContainer/uiviewport/uicamera"
@onready var aud = $"../../director/audio"
@onready var collection = [
	$"../../canvas/SubViewportContainer/uiviewport/uicamera/collection/col1", 
	$"../../canvas/SubViewportContainer/uiviewport/uicamera/collection/col2",
	$"../../canvas/SubViewportContainer/uiviewport/uicamera/collection/col3", 
	$"../../canvas/SubViewportContainer/uiviewport/uicamera/collection/col4",
	$"../../canvas/SubViewportContainer/uiviewport/uicamera/collection/col5"
	]
@onready var playerScript : Player = player as Player
@onready var noise = preload("res://textures/realnoise.png")
var state : ItemState

@export var itemDataAsString : String
var itemdata : ItemData

@export var interactable : bool = true

var dissolve : float = 1.0

var hp : float = 10.0
var maxhp : float = 10.0
var immune : bool = false

func _ready() -> void:
	state = Neutral.new(self)
	itemdata = create_instance("res://scripts/item.gd", itemDataAsString)
	if !itemdata:
		print("NO ITEM DATA STRING")
		itemdata = ThrowingKnife.new()
	sprite3d.texture = itemdata.image
	var shader : ShaderMaterial = load("res://shaders/dissolver.tres") 
	sprite3d.material_override = shader.duplicate(true)
	sprite3d.material_override.set_shader_parameter("dissolve_texture", noise)
	sprite3d.material_override.set_shader_parameter("real_texture", itemdata.image)
	
	var shape : CollisionShape3D = get_node("shape")
	var shapebox : BoxShape3D = shape.shape
	shapebox.size = itemdata.sizeoverride
	contact_monitor = true
	max_contacts_reported = 4
func _process(delta: float) -> void:
	dissolve = clamp(dissolve, 0.0, 1.0)
	sprite3d.material_override.set_shader_parameter("dissolve_value", dissolve)
	
func _physics_process(delta: float) -> void:
	state.on_process(delta, self)
	itemdata.on_process(delta, self)
	
	if !immune:
		dissolve = lerpf(dissolve, hp / maxhp, .15)
		if dissolve <= 0.0:
			if itemdata.on_death(self):
				Event.play_sound(aud, "hurt2.mp3", .4, 1.0)
				Event.deatheffect(global_position, map)
				queue_free()

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
		if dist < 1:
			dist = 0.1
		global_position = playerScript.global_position + facing * -.8 * dist + Vector3(0, .8, 0) 
		if whichhand < 0.0:
			playerScript.LHitem = null
		else:
			playerScript.RHitem = null
		Event.play_sound(aud, "click.ogg", .6, 1.0)
		
@onready var pickup_me_connect = Event.pickupitem.connect(pickup_me)
func pickup_me(whichhand : float, globalpos : Vector3):
	if state is Neutral and globalpos.distance_to(global_position) < .1:
		state = Held.new(self, whichhand)
		if whichhand < 0.0: 
			playerScript.LHitem = self
		else:
			playerScript.RHitem = self
		Event.play_sound(aud, "clickgood.wav", .6, 1.0)
		return
	if state is EntityNeutral and globalpos.distance_to(global_position) < .1:
		itemdata.on_interact(self)
		Event.play_sound(aud, "clickgood.wav", .6, 2.0)
		return
			
@onready var use_me_connect = Event.useitem.connect(use_me)
func use_me(whichhand : float):
	if abs(whichhand - state.whichhand) < .1 and state is Held:
		itemdata.on_use(self)
		Event.tutorialdone -= 1

@onready var launch_me_connect = Event.launch.connect(launch_me)
func launch_me(pos : Vector3, ramge : float, strength : float, playerimmune : bool):
	if pos.distance_to(global_position) > .01 and state is Neutral:
		var dist : float = pos.distance_to(global_position)
		if dist < ramge:
			var dir = (global_position - pos).normalized()
			dir.y = max(.2, 0)
			apply_impulse((1.0 - (dist / ramge)) * strength * dir)
			Event.launcheffect(global_position, map)
			Event.play_sound(aud, "jump.wav", .1, 3.0)

@onready var damage_me_connect = Event.damage.connect(damage_me)
func damage_me(pos : Vector3, ramge : float, value : float, playerimmune : bool):
	var dist : float = pos.distance_to(global_position)
	if dist < ramge and dist > .01:
		hp -= value
		Event.play_sound(aud, "hurt1.mp3", .2, 1.0)
		Event.damageeffect(global_position, self)



@abstract class ItemState:
	var name : String
	var local : float
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
		
		
class Collected extends ItemState:
	func _init(item : Item) -> void:
		item.get_parent().remove_child(item)
		var collected : int = 0
		for b in Event.collection_status:
			if b:
				collected += 1
			else:
				break
		if collected >= 4:
			Event.play_sound(item.aud, "doorslam.mp3", 1.0, 1.0)
		else:
			Event.play_sound(item.aud, "bigget.mp3", .5, 1.0)
		Event.collection_status[collected] = true
		item.collection[collected].add_child(item)
		item.sprite3d.set_layer_mask_value(2, true)
		item.sprite3d.set_layer_mask_value(1, false)
		item.position = Vector3(0, 0, 0)
		item.sprite3d.pixel_size = .004
		item.hp = item.maxhp
		
		return
	func on_process(delta : float, item : Item) -> void:
		item.position = Vector3(0, 0, 0)
		return

class EntityNeutral extends ItemState:
	func _init(item : Item) -> void:
		return
	func on_process(delta : float, item : Item) -> void:
		if item.hp < item.maxhp:
			item.state = EntityAggresive.new(item)

class EntityAggresive extends ItemState:
	func _init(item : Item) -> void:
		item.interactable = false
		return
	func on_process(delta : float, item : Item) -> void:
		var dir : Vector3 = (item.global_position - item.player.global_position).normalized()
		item.linear_velocity = dir * -5.0
		item.linear_velocity.y = min(item.linear_velocity.y, .1)
		local += delta
		var dist : float = item.global_position.distance_to(item.player.global_position)
		if dist < (1.5 + item.itemdata.sizeoverride.x) and local > 0.0:
			local = -.5
			Event.damage.emit(item.global_position, 3.5, 3.5, false)
			Event.launch.emit(item.global_position, 5.0, 15.0, false)
		
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
	var local : float = 1.0
	var sizeoverride : Vector3 = Vector3(1.0, 1.0, 1.0)
	func AssignImage() -> void:
		image = load("res://textures/" + name + ".png")
	@abstract func on_use(item : Item) -> void
	func on_process(delta : float, item : Item) -> void:
		return
	func on_physics_process(delta : float, item : Item) -> void:
		return
	func on_interact(item : Item) -> void:
		return
	func on_death(item : Item) -> bool:
		return true
		
	func collectable_eat_use(item : Item):
		item.hp = -.1
		item.interactable = false
		Event.play_sound(item.aud, "eat.ogg", .4, 1.0)
	
	func collectable_eat_death(item : Item) -> bool:
		if item.state is not Collected:
			item.interactable = false
			Event.dropitem.emit(item.state.whichhand)
			item.state = Collected.new(item)
		return false
	
class ThrowingKnife extends ItemData:
	func _init() -> void:
		name = "throwing knife"
		local = -1.0
		AssignImage()
	func on_use(item : Item) -> void:
		Event.dropitem.emit(item.state.whichhand)
		item.apply_impulse(item.player.get_facing() * -30.0 + Vector3(0, 2.0, 0))
		local = 1.0
	func on_process(delta : float, item : Item) -> void:
		var collisions = item.get_colliding_bodies()
		if local > 0.0:
			if collisions.size() > 0:
				var dmg = max(.2 * item.linear_velocity.length(), 3.5)
				Event.damage.emit(item.global_position, 3.5, dmg, true)
				local = -1.0
	
class MultiKnife extends ItemData:
	func _init() -> void:
		name = "multi knife"
		local = -1.0
		AssignImage()
	func on_use(item : Item) -> void:
		Event.dropitem.emit(item.state.whichhand)
		item.apply_impulse(item.player.get_facing() * -30.0 + Vector3(0, 2.0, 0))
		local = 1.0
	func on_process(delta : float, item : Item) -> void:
		var collisions = item.get_colliding_bodies()
		item.immune = true
		if local > 0.0:
			if collisions.size() > 0:
				var dmg = max(.2 * item.linear_velocity.length(), 13.0)
				Event.damage.emit(item.global_position, 5.0, dmg, true)
				local = -1.0
				
class Bomb extends ItemData:
	func _init() -> void:
		name = "bomb"
		AssignImage()
	func on_use(item : Item) -> void:
		Event.dropitem.emit(item.state.whichhand)
		item.interactable = false
		item.hp = -.1
	func on_death(item : Item) -> bool:
		Event.launch.emit(item.global_position, 20.0, 30.0, false)
		Event.damage.emit(item.global_position, 5.0, 5.0, false)
		return true
			
class Food extends ItemData:
	func _init() -> void:
		name = "food"
		AssignImage()
	func on_use(item : Item) -> void:
		item.hp = -.1
	func on_death(item : Item) -> bool:
		item.player.hp += 5.0
		return true
			
class Flight extends ItemData:
	func _init() -> void:
		name = "flight"
		AssignImage()
	func on_use(item : Item) -> void:
		if local > 0.0:
			item.player.velocity += Vector3(0, 60.0, 0)
			local = -1.0
		else:
			Event.play_sound(item.aud, "selectno.wav", .5, 1.0)
	func on_process(delta : float, item : Item) -> void:
		item.immune = true
		item.dissolve = local + 1.0
		local += delta
		
class Butter extends ItemData:
	func _init() -> void:
		name = "butter"
		AssignImage()
	func on_use(item : Item) -> void:
		var real = clampf(local + 1.0, 0.0, 1.0)
		item.player.velocity += Vector3(0, 100.0 * real , 0)
		local = -1.0
	func on_process(delta : float, item : Item) -> void:
		item.immune = true
		item.dissolve = local + 1.0
		local += delta
		
class Ascent extends ItemData:
	func _init() -> void:
		name = "ascent"
		AssignImage()
	func on_use(item : Item) -> void:
		if item.hp > 0.0:
			item.player.velocity = Vector3(item.player.velocity.x, 60.0, item.player.velocity.z)
			Event.play_sound(item.aud, "selectno.wav", .5, 1.0)
			item.hp = -.1
	func on_process(delta : float, item : Item) -> void:
		return
			
class Truth extends ItemData:
	func _init() -> void:
		name = "truth"
		AssignImage()
	func on_use(item : Item) -> void:
		var col : int = 0
		for b : bool in Event.collection_status:
			if b:
				col += 1
		if col >= 5 and !Event.gameended:
			item.interactable = false
			Event.gameended = true
			Event.play_sound(item.aud, "win.mp3", .6, 1.0)
		else:
			Event.play_sound(item.aud, "selectno.wav", .5, 1.0)
	func on_process(delta : float, item : Item) -> void:
		item.immune = false
		return
			
class Secret extends ItemData:
	func _init() -> void:
		name = "secret"
		AssignImage()
	func on_use(item : Item) -> void:
		item.hp = -.1
	func on_death(item : Item) -> bool:
		Event.play_sound(item.aud, "bigget.mp3", .5, 3.0)
		Event.secrets += 1
		return true
			
class Stenemy extends ItemData:
	var dialouge : Array = [
		"YOU CAN FEEL IT.", 
		"THE VIBRATION. ITS OFF. \nIT ALWAYS HAS BEEN.", 
		"THE CANCER WAS GROWN FROM THE HEART. \nTHE ORIGIN.", 
		"ITS SO OBVIOUS."
		]
	var dialougeindex : int = 0
	func _init() -> void:
		name = "stenemy"
		sizeoverride = Vector3(1.0, 3.0, 1.0)
		AssignImage()
	func on_use(item : Item) -> void:
		return
	func on_process(delta : float, item : Item) -> void:
		if item.state is not EntityNeutral and item.state is not EntityAggresive:
			item.state = EntityNeutral.new(item)
		super(delta, item)
					
	func on_interact(item : Item) -> void:
		if dialougeindex >= dialouge.size():
			item.state = EntityAggresive.new(item)
			dialougeindex = 0
		name = dialouge[dialougeindex]
		dialougeindex += 1
		
class Crab extends ItemData:
	var dialouge : Array = [
		"YOU CAN TASTE IT.",
		"IT COMES FROM CONSUMPTION.",
		"THE GREED. THE PLAGUE.\nITS ALL THE STOMACH.",
		"ITS PROVEN."
		]
	var dialougeindex : int = 0
	func _init() -> void:
		name = "crab"
		sizeoverride = Vector3(1.0, 3.0, 1.0)
		AssignImage()
	func on_use(item : Item) -> void:
		return
	func on_process(delta : float, item : Item) -> void:
		if item.state is not EntityNeutral and item.state is not EntityAggresive:
			item.state = EntityNeutral.new(item)
		super(delta, item)
					
	func on_interact(item : Item) -> void:
		if dialougeindex >= dialouge.size():
			item.state = EntityAggresive.new(item)
			dialougeindex = 0
		name = dialouge[dialougeindex]
		dialougeindex += 1
		
			
			
class Minion extends ItemData:
	var dialouge : Array = [
		"YOU CAN BREATHE IT.",
		"IT FEELS DISGUSTING.",
		"ROTTEN ON THE INSIDE.",
		"TURNED BLACK.",
		"THE INFECTION IS IN THE LUNGS.",
		"IT CANT BE ANYWHERE ELSE."
		]
	var dialougeindex : int = 0
	func _init() -> void:
		name = "minion"
		sizeoverride = Vector3(1.0, 2.5, 1.0)
		AssignImage()
	func on_use(item : Item) -> void:
		return
	func on_process(delta : float, item : Item) -> void:
		if item.state is not EntityNeutral and item.state is not EntityAggresive:
			item.state = EntityNeutral.new(item)
		super(delta, item)
		
	func on_interact(item : Item) -> void:
		if dialougeindex >= dialouge.size():
			item.state = EntityAggresive.new(item)
			dialougeindex = 0
		name = dialouge[dialougeindex]
		dialougeindex += 1
		
			
			
class Killer extends ItemData:
	func _init() -> void:
		name = "killer"
		sizeoverride = Vector3(1, 3.0, 1)
		AssignImage()
	func on_use(item : Item) -> void:
		return
	func on_process(delta : float, item : Item) -> void:
		if item.state is not EntityNeutral and item.state is not EntityAggresive:
			item.state = EntityNeutral.new(item)
			
		var dist : float = item.global_position.distance_to(item.player.global_position)
		if dist < 20.0:
			item.state = EntityAggresive.new(item)
		super(delta, item)
		
	func on_interact(item : Item) -> void:
		return
		
class Killer2 extends ItemData:
	func _init() -> void:
		name = "soldier"
		sizeoverride = Vector3(1, 3.0, 1)
		AssignImage()
	func on_use(item : Item) -> void:
		return
	func on_process(delta : float, item : Item) -> void:
		if item.hp < item.maxhp:
			item.hp += .15
		if item.state is not EntityNeutral and item.state is not EntityAggresive:
			item.state = EntityNeutral.new(item)
			
		var dist : float = item.global_position.distance_to(item.player.global_position)
		if dist < 20.0:
			item.state = EntityAggresive.new(item)
		super(delta, item)
		
	func on_interact(item : Item) -> void:
		return
		
class Wall extends ItemData:
	var dialouge : Array = [
		"YOU ARE BEING CONTROLLED BY IT.",
		"THE THOUGHTS ARE CORRUPT.",
		"IT LEADS THE REST OF THE BODY.",
		"THE TUMOR IS ROOTED IN THE BRAIN.",
		"IT COULDNT BE MORE CLEAR.",
		]
	var dialougeindex : int = 0
	func _init() -> void:
		name = "wall"
		sizeoverride = Vector3(3.0, 3.0, 3.0)
		AssignImage()
	func on_use(item : Item) -> void:
		return
	func on_process(delta : float, item : Item) -> void:
		if item.state is not EntityNeutral:
			item.state = EntityNeutral.new(item)
		if item.hp < item.maxhp:
			item.hp += .35
		
		item.linear_velocity = Vector3(0, 0, 0)
		item.position = Vector3(28, -20, 38.45)
		var dist : float = item.global_position.distance_to(item.player.global_position)
		if dist < 5.0:
			Event.launch.emit(item.global_position, 7.0, 40.0, false)
	func on_interact(item : Item) -> void:
		if dialougeindex >= dialouge.size():
			item.state = EntityAggresive.new(item)
			dialougeindex = 0
		name = dialouge[dialougeindex]
		dialougeindex += 1
		return
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
class Lungs extends ItemData:
	func _init() -> void:
		name = "lungs"
		local = 1.0
		AssignImage()
	func on_use(item : Item) -> void:
		collectable_eat_use(item)
	func on_death(item : Item) -> bool:
		return collectable_eat_death(item)
	
class Heart extends ItemData:
	func _init() -> void:
		name = "heart"
		local = 1.0
		AssignImage()
	func on_use(item : Item) -> void:
		collectable_eat_use(item)
	func on_death(item : Item) -> bool:
		return collectable_eat_death(item)
		
class Stomach extends ItemData:
	func _init() -> void:
		name = "stomach"
		local = 1.0
		AssignImage()
	func on_use(item : Item) -> void:
		collectable_eat_use(item)
	func on_death(item : Item) -> bool:
		return collectable_eat_death(item)
class Brain extends ItemData:
	func _init() -> void:
		name = "brain"
		local = 1.0
		AssignImage()
	func on_use(item : Item) -> void:
		collectable_eat_use(item)
	func on_death(item : Item) -> bool:
		return collectable_eat_death(item)

class Skinn extends ItemData:
	func _init() -> void:
		name = "skin"
		local = 1.0
		AssignImage()
	func on_use(item : Item) -> void:
		collectable_eat_use(item)
		Event.damage.emit(item.player.global_position, 1.0, 2.0, false)
	func on_death(item : Item) -> bool:
		return collectable_eat_death(item)
