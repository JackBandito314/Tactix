extends Area3D

var is_selected = false


func _input_event(camera, event, click_position, click_normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		# Wenn dieser Würfel schon ausgewählt ist → abwählen
		if is_selected:
			is_selected = false
			_update_visual_state()
			return
		
		# Sonst alle anderen Würfel abwählen
		for d in get_tree().get_nodes_in_group("dice"):
			d.is_selected = false
			d._update_visual_state()
		
		# Diesen Würfel auswählen
		is_selected = true
		_update_visual_state()


func _update_visual_state():
	if is_selected:
		scale = Vector3(1.1, 1.1, 1.1) # vergrößert
	else:
		scale = Vector3(1, 1, 1)       # normal
