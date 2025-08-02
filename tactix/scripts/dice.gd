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
	var cube_size := 2.0
	var half_size := cube_size / 2.0
	var step_time := 0.25 # Zeit pro Feld

	# 1️⃣ Ziel auf Grid runden
	target_pos.x = round(target_pos.x / cube_size) * cube_size
	target_pos.z = round(target_pos.z / cube_size) * cube_size

	# 2️⃣ Bewegungsdifferenz
	var diff = target_pos - global_position

	# Nur geradeaus erlauben
	if abs(diff.x) > 0.01 and abs(diff.z) > 0.01:
		push_error("Nur gerade Bewegungen erlaubt!")
		return

	# 3️⃣ Anzahl Felder bestimmen
	var steps := int(round(diff.length() / cube_size))
	if steps <= 0:
		return

	# 4️⃣ Richtung bestimmen
	var dir = diff.normalized()

	# 5️⃣ Achse & Pivot-Offset bestimmen
	var axis: Vector3
	var edge_offset: Vector3

	if abs(dir.x) > abs(dir.z):
		# Bewegung in X-Richtung → Drehung um Z-Achse
		axis = Vector3(0, 0, -sign(dir.x))
		edge_offset = Vector3(sign(dir.x) * half_size, -half_size, 0)
	else:
		# Bewegung in Z-Richtung → Drehung um X-Achse
		axis = Vector3(sign(dir.z), 0, 0)
		edge_offset = Vector3(0, -half_size, sign(dir.z) * half_size)

	# 6️⃣ Tween-Sequenz erstellen
	var sequence = create_tween()
	var start_transform: Transform3D = global_transform

	for i in range(steps):
		sequence.tween_method(
			func(v):
				var current_angle = (PI / 2.0) * v
				var temp_transform: Transform3D = start_transform

				# 1. Zum Pivot verschieben
				temp_transform.origin += edge_offset
				# 2. Rotieren
				temp_transform.basis = Basis(axis, current_angle) * start_transform.basis
				# 3. Zurück verschieben
				temp_transform.origin -= edge_offset

				# 💡 Translation während der Drehung mit einberechnen
				temp_transform.origin += dir * cube_size * v

				# Höhe fixieren
				temp_transform.origin.y = 1.0

				# Setzen
				global_transform = temp_transform, 0.0, 1.0, step_time
		)

		# Nach jedem Schritt Start-Transform updaten
		sequence.tween_callback(func():
			global_position += dir * cube_size
			global_position.y = 1.0
			start_transform = global_transform
		)

	# Am Ende sauber auf Ziel setzen
	sequence.tween_callback(func():
		global_position = target_pos
		global_position.y = 1.0
	)
