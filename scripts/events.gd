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

signal damage(pos : Vector3, range : float, value : float, playerimmune : bool)

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

var gameended : bool = false

var secrets : int = 0
