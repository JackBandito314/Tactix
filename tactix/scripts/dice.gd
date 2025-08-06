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

	# Eigenes Material erzeugen (wirklich nur für diesen Würfel)
	var original_mat = mesh_node.get_surface_override_material(0)
	if original_mat == null:
		original_mat = mesh_node.mesh.surface_get_material(0)

	if original_mat:
		mat = original_mat.duplicate(true) # tiefes Duplizieren
		mesh_node.set_surface_override_material(0, mat)

		# Standard: nur Rückseiten werden nicht gerendert
		mat.cull_mode = BaseMaterial3D.CULL_BACK

		base_color = mat.albedo_color
	else:
		push_error("Kein Material gefunden!")

func _find_first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
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
			_animate_transparency(false)
			return
		
		# Alle anderen Würfel abwählen
		for d in get_tree().get_nodes_in_group("dice"):
			if d != self:
				d.is_selected = false
				if d.has_method("_animate_transparency"):
					d._animate_transparency(false)
		
		# Diesen auswählen
		is_selected = true
		_animate_transparency(true)


func _animate_transparency(selected: bool):
	if mat == null:
		return
	# Ausgewählt → Vorderseiten nicht rendern → Blick ins Innere
	if selected:
		mat.cull_mode = BaseMaterial3D.CULL_FRONT
	else:
		mat.cull_mode = BaseMaterial3D.CULL_BACK


# ====================================================================
# Würfelbewegung
# ====================================================================

func rotate_cube_around_edge(cube: Node3D, edge_offset: Vector3, axis: Vector3, angle: float, duration: float) -> void:
	var old_parent: Node = cube.get_parent()
	var old_transform: Transform3D = cube.global_transform

	# Pivot-Node erstellen
	var pivot_node := Node3D.new()
	get_tree().current_scene.add_child(pivot_node)

	# Pivot an die richtige Kante setzen
	pivot_node.global_transform.origin = old_transform.origin + edge_offset

	# Würfel in Pivot hängen (ohne Weltposition zu verändern)
	old_parent.remove_child(cube)
	pivot_node.add_child(cube)
	cube.global_transform = old_transform

	# Rotation animieren
	var tween = pivot_node.create_tween()
	tween.tween_property(
		pivot_node,
		"rotation",
		pivot_node.rotation + axis.normalized() * angle,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Auf Animation warten
	await tween.finished

	# Würfel zurückhängen
	var new_pos = cube.global_transform
	pivot_node.remove_child(cube)
	old_parent.add_child(cube)
	cube.global_transform = new_pos
	pivot_node.queue_free()

	# Sicherheits‑Snap
	var cube_size := 2.0
	cube.global_position.x = round(cube.global_position.x / cube_size) * cube_size
	cube.global_position.z = round(cube.global_position.z / cube_size) * cube_size
	cube.global_position.y = 1.0

func move_to_position(target_pos: Vector3):
	# Würfel beim Start der Bewegung abwählen und wieder deckend machen
	if is_selected:
		is_selected = false
		_animate_transparency(false)

	var cube_size := 2.0
	var step_time := .5 # Zeit pro Feld

	# Ziel auf Grid runden
	target_pos.x = round(target_pos.x / cube_size) * cube_size
	target_pos.z = round(target_pos.z / cube_size) * cube_size
	target_pos.y = 1.0

	# Bewegungsdifferenz
	var diff = target_pos - global_position

	# Nur geradeaus erlauben
	if abs(diff.x) > 0.01 and abs(diff.z) > 0.01:
		push_error("Nur gerade Bewegungen erlaubt!")
		return

	# Anzahl Felder bestimmen
	var steps := int(round(diff.length() / cube_size))
	if steps <= 0:
		return

	# Richtung bestimmen
	var dir = diff.normalized()

	# Achse & Pivot-Offset bestimmen
	var down := Vector3(0, -1, 0)
	var axis := dir.cross(down)
	var edge_offset := Vector3(dir + down)

	# Seriell pro Feld bewegen
	for i in range(steps):
		await rotate_cube_around_edge(self, edge_offset, axis, PI / 2.0, step_time)
