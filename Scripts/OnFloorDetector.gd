extends Spatial
class_name OnFloorDetector


func is_on_floor() -> bool:
	var detectors = get_children()
	for ray in detectors:
		if ray.is_colliding():
			return true
	
	return false
