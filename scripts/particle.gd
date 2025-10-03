extends CPUParticles3D

var timer : float
func _physics_process(delta: float) -> void:
	timer += delta
	if timer > 5.0:
		queue_free()
