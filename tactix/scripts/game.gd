extends Node3D

var selected_dice: Area3D = null

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var ray_origin = $Camera3D.project_ray_origin(event.position)
		var ray_dir = $Camera3D.project_ray_normal(event.position)

		# --- Wichtig: Wir nutzen jetzt intersect_point, um auch Areas zu finden ---
		var space_state = get_world_3d().direct_space_state

		# Ray-Parameter für Abfrage
		var query = PhysicsRayQueryParameters3D.create(
			ray_origin,
			ray_origin + ray_dir * 1000
		)
		query.collision_mask = 1  # Layer 1 = Würfel
		query.collide_with_areas = true   # <---- NEU: auch Area3D erkennen
		query.collide_with_bodies = true  # Falls später doch Bodies genutzt werden

		var result = space_state.intersect_ray(query)

		print("\n--- MOUSE CLICK ---")
		if not result:
			print("❌ Kein Treffer auf Layer 1")
		else:
			print("🎯 Layer 1 HIT:", result.collider.name)

		if result:
			var clicked_node = result.collider

			# Hochlaufen bis zur Würfel-Root mit "dice"
			var safety = 0
			while clicked_node and not clicked_node.is_in_group("dice") and safety < 20:
				clicked_node = clicked_node.get_parent()
				safety += 1
				print("  ↳ Prüfe Parent:", clicked_node.name if clicked_node else "NULL")

			# Fall 1: Würfel angeklickt
			if clicked_node and clicked_node.is_in_group("dice"):
				selected_dice = clicked_node
				print("✅ Würfel ausgewählt:", selected_dice.name)
				return

		# === Brett-Zielklick ===
		if selected_dice:
			var board_query = PhysicsRayQueryParameters3D.create(
				ray_origin,
				ray_origin + ray_dir * 1000
			)
			board_query.collision_mask = 1 << 1  # Layer 2 = Brett
			board_query.collide_with_areas = true
			board_query.collide_with_bodies = true

			var board_hit = space_state.intersect_ray(board_query)
			if board_hit:
				print("🎯 Brett getroffen:", board_hit.collider.name)
				print("➡ Zielposition:", board_hit.position)
				selected_dice.move_to_position(board_hit.position)
			else:
				print("❌ Brett nicht getroffen")
				
