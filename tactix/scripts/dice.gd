extends Area3D

var is_selected = false
var base_color: Color
var mat: StandardMaterial3D
var mesh_node: MeshInstance3D

func _ready():
	# Suche erstes MeshInstance3D in diesem Würfel (rekursiv)
	mesh_node = _find_first_mesh(self)
	if mesh_node == null:
		push_error("Kein MeshInstance3D im Würfel gefunden!")
		return

	# Eigenes Material erzeugen (damit es nur diesen Würfel betrifft)
	var original_mat = mesh_node.get_surface_override_material(0)
	if original_mat == null:
		original_mat = mesh_node.mesh.surface_get_material(0)

	if original_mat:
		mat = original_mat.duplicate()
		mesh_node.set_surface_override_material(0, mat)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		base_color = mat.albedo_color
		mat.albedo_color.a = 1.0
	else:
		push_error("Kein Material gefunden!")

func _find_first_mesh(node: Node) -> MeshInstance3D:
	# Falls dieser Node ein MeshInstance3D ist → zurückgeben
	if node is MeshInstance3D:
		return node
	# Sonst alle Kinder durchsuchen
	for child in node.get_children():
		var found = _find_first_mesh(child)
		if found != null:
			return found
	return null

func _input_event(camera, event, click_position, click_normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Falls derselbe Würfel nochmal geklickt → abwählen
		if is_selected:
			is_selected = false
			_animate_transparency(1.0)
			return
		
		# Alle anderen Würfel abwählen
		for d in get_tree().get_nodes_in_group("dice"):
			if d != self:
				d.is_selected = false
				if d.has_method("_animate_transparency"):
					d._animate_transparency(1.0)
		
		# Diesen auswählen
		is_selected = true
		_animate_transparency(0.5)

func _animate_transparency(target_alpha: float):
	if mat == null:
		return
	var tween = create_tween()
	tween.tween_property(
		mat, "albedo_color:a",
		target_alpha,
		0.25
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)



func move_to_position(target_pos: Vector3):
	# Distanz in Weltkoordinaten
	var distance = global_position.distance_to(target_pos)
	if distance < 0.01:
		return # Kein Bewegen nötig

	# Geschwindigkeit in Einheiten/Sekunde
	var speed = 3.0
	var move_time = distance / speed

	# Bewegungsrichtung bestimmen
	var dir = (target_pos - global_position).normalized()

	# Achse bestimmen:
	var rotations = Vector3.ZERO
	if abs(dir.x) > abs(dir.z):
		# Bewegung in X-Richtung → Rolle um Z
		var direction_sign = sign(dir.x)
		rotations = Vector3(0, 0, direction_sign * (distance / 2.0) * (PI / 2.0))
	else:
		# Bewegung in Z-Richtung → Rolle um X
		var direction_sign = -sign(dir.z) # Minus für visuell korrekt
		rotations = Vector3(direction_sign * (distance / 2.0) * (PI / 2.0), 0, 0)

	# Tween erstellen
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, move_time)
	tween.parallel().tween_property(self, "rotation", rotation + rotations, move_time)
