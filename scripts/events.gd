extends Node

@warning_ignore_start("unused_signal")
signal launch(pos : Vector3, range : float, strength : float, playerimmune : bool)

@onready var launchparticle = preload("res://prefabs/hitparticle.tscn")
func launcheffect(pos : Vector3, parent : Node):
	var part : CPUParticles3D = launchparticle.instantiate()
	parent.add_child(part)
	part.global_position = pos
	part.emitting = true
	

signal useitem(whichhand : float)

signal dropitem(whichhand : float)

signal pickupitem(whichhand : float, globalpos : Vector3)
