extends Node

@warning_ignore_start("unused_signal")
signal launch(pos : Vector3, range : float, strength : float, playerimmune : bool)

@onready var launchparticle = preload("res://entities/hitparticle.tscn")
func launcheffect(pos : Vector3, parent : Node):
	var part : CPUParticles3D = launchparticle.instantiate()
	parent.add_child(part)
	part.global_position = pos
	part.emitting = true
	

signal useitem(whichhand : float)

signal dropitem(whichhand : float)

signal pickupitem(whichhand : float, globalpos : Vector3)

signal damage(pos : Vector3, range : float, value : float, source : String)

@onready var damageparticle = preload("res://entities/hurtparticle.tscn")
func damageeffect(pos : Vector3, parent : Node):
	var part : CPUParticles3D = damageparticle.instantiate()
	parent.add_child(part)
	part.global_position = pos
	part.emitting = true
	
@onready var smallhitparticle = preload("res://entities/smallhitparticle.tscn")
func smallhiteffect(pos : Vector3, parent : Node):
	var part : CPUParticles3D = smallhitparticle.instantiate()
	parent.add_child(part)
	part.global_position = pos
	part.emitting = true
	
@onready var deathparticle = preload("res://entities/deathparticle.tscn")
func deatheffect(pos : Vector3, parent : Node):
	var part : CPUParticles3D = deathparticle.instantiate()
	parent.add_child(part)
	part.global_position = pos
	part.emitting = true

func play_sound(aud : AudioStreamPlayer, sound : String, volume : float, pitch : float):
	var soundfile = load("res://sound/" + sound)
	aud.stream = soundfile
	var rng = RandomNumberGenerator.new()
	aud.pitch_scale = rng.randf_range(.8, 1.2) * pitch
	aud.volume_linear = volume
	aud.play()
	

	



var collection_status = [false, false, false, false, false]
#var collection_status = [true, true, true, true, false]
var tutorialtooltip : String = ""
var tutorialdone : int = 3

signal endgame
var gameended : bool = false

var secrets : int = 0

var order : String = ""

func toorderchar(to : String) -> String:
	if to == "heart":
		return "H"
	elif to == "stomach":
		return "S"
	elif to == "brain":
		return "B"
	elif to == "skin":
		return "S"
	elif to == "lungs":
		return "L"
	else:
		return "X"


var chars = "qwertyuiopasdfghjklzxcvbnm"

func resetGame() -> void:
	Event.collection_status = [false, false, false, false, false]
	Event.tutorialtooltip = ""
	Event.secrets = 0
	Event.gameended = false
	var r := RandomNumberGenerator.new()
	Event.order = chars[r.randi() % chars.length()] + chars[r.randi() % chars.length()]
	get_tree().change_scene_to_file("res://entities/map.tscn")






var lbNAME := "TBD"
func submit(name : String, time : float):
	await Talo.players.identify("username", order)
	var res := await Talo.leaderboards.add_entry(lbNAME, time)
	
	assert(is_instance_valid(res))
	print("VALID ENTRY OF NAME ", name, " AND TIME ", time)
	
func readLB() -> Array:
	var options := Talo.leaderboards.GetEntriesOptions.new()
	options.page = 0

	var res := await Talo.leaderboards.get_entries(lbNAME, options)
	var entries: Array[TaloLeaderboardEntry] = res.entries
	var count: int = res.count
	var is_last_page: bool = res.is_last_page
	return entries
	
