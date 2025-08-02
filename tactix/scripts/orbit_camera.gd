extends Camera3D

@export var target: Node3D         # Zielpunkt, um den sich die Kamera dreht
@export var distance := 20.0       # Start-Abstand
@export var min_distance := 5.0    # Min. Zoom
@export var max_distance := 50.0   # Max. Zoom
@export var zoom_speed := 2.0
@export var rotate_speed := 0.01   # Maus-Empfindlichkeit
@export var smooth_factor := 8.0   # Je höher, desto schneller reagiert die Glättung

# Aktuelle Rotation
var rotation_x := deg_to_rad(30)   # Vertikal
var rotation_y := deg_to_rad(45)   # Horizontal

# Zielwerte für sanftes Gleiten
var target_rotation_x := rotation_x
var target_rotation_y := rotation_y
var target_distance := distance

var rotating := false              # Ist Rechtsklick gedrückt?

func _input(event):
	# Rechtsklick gedrückt -> Rotation aktivieren
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotating = event.pressed
			if rotating:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		# Mausrad-Zoom (nur Zielwert ändern)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_distance = max(min_distance, target_distance - zoom_speed)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_distance = min(max_distance, target_distance + zoom_speed)

	# Mausbewegung zum Rotieren (nur Zielwert ändern)
	if event is InputEventMouseMotion and rotating:
		target_rotation_y -= event.relative.x * rotate_speed
		target_rotation_x += event.relative.y * rotate_speed  # Vertikale Bewegung invertiert
		target_rotation_x = clamp(target_rotation_x, deg_to_rad(5), deg_to_rad(85))

func _process(delta):
	if not target:
		return

	# Sanft Richtung Zielwerte bewegen
	rotation_x = lerp_angle(rotation_x, target_rotation_x, delta * smooth_factor)
	rotation_y = lerp_angle(rotation_y, target_rotation_y, delta * smooth_factor)
	distance = lerp(distance, target_distance, delta * smooth_factor)

	# Kameraposition aus Rotationswerten berechnen
	var offset = Vector3(
		distance * sin(rotation_y) * cos(rotation_x),
		distance * sin(rotation_x),
		distance * cos(rotation_y) * cos(rotation_x)
	)
	global_position = target.global_position + offset
	look_at(target.global_position, Vector3.UP)
