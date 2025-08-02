extends Node3D

var selected_dice: Area3D = null

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var ray_origin = $Camera3D.project_ray_origin(event.position)
		var ray_dir = $Camera3D.project_ray_normal(event.position)
		var space_state = get_world_3d().direct_space_state

		print("\n--- MOUSE CLICK ---")

		# === 1. Würfelauswahl (Layer 1) ===
		var dice_query = PhysicsRayQueryParameters3D.create(
			ray_origin,
			ray_origin + ray_dir * 1000
		)
		dice_query.collision_mask = 1  # nur Layer 1 (Würfel)

		var dice_hit = space_state.intersect_ray(dice_query)

		if dice_hit:
			print("🎯 Layer 1 HIT:", dice_hit.collider.name)
			var clicked_node = dice_hit.collider

			# Hochlaufen bis Root mit "dice"
			var safety = 0
			while clicked_node and not clicked_node.is_in_group("dice") and safety < 20:
				clicked_node = clicked_node.get_parent()
				safety += 1
				print("  ↳ Prüfe Parent:", clicked_node.name if clicked_node else "NULL")

			if clicked_node and clicked_node.is_in_group("dice"):
				selected_dice = clicked_node
				print("✅ Würfel ausgewählt:", selected_dice.name)
				return
		else:
			print("❌ Layer 1 (Würfel) – kein Treffer")

		# === 2. Brett-Zielklick (Layer 2) ===
		if selected_dice:
			var board_query = PhysicsRayQueryParameters3D.create(
				ray_origin,
				ray_origin + ray_dir * 1000
			)
			board_query.collision_mask = 1 << 1  # Layer 2 (Brett)

			var board_hit = space_state.intersect_ray(board_query)
			if board_hit:
				print("🎯 Layer 2 HIT:", board_hit.collider.name)
				print("➡ Zielklick bei:", board_hit.position)
				selected_dice.move_to_position(board_hit.position)
			else:
				print("❌ Layer 2 (Brett) – kein Treffer")
