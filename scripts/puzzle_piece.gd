extends Area2D
# Puzzle Piece

var index = -1
var cell_index = -1
var size

var dragging = false
var drag_offset = Vector2.ZERO

@onready var sprite2d: Sprite2D = $Sprite2D
@onready var collishape: CollisionShape2D = $CollisionShape2D

func init_piece(
	_index: int,
	texture: ImageTexture,
	pos: Vector2,
	piece_size: Vector2
):
	index = _index
	sprite2d.texture = texture
	position = pos
	collishape.shape.set("size", piece_size)
	size = piece_size

func _on_input_event(viewport, event, shape_idx):
	if G.game_over:
		return
	if G.dragging and dragging == false:
		# do not drag current piece, if some other piece is being dragged
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			# Begin dragging
			
			# Reset cell position when a piece is moved
			if cell_index != -1:
				var cell = G.find_cell(cell_index)
				cell.unoccupy()
				cell_index = -1

			G.dragging = true
			dragging = true
			z_index = 100
			drag_offset = global_position - get_global_mouse_position()
		else:
			# Release 
			sprite2d.material.set("shader_parameter/shadow_offset", Vector2(0, 0))
			G.dragging = false
			dragging = false
			z_index = 0
			drop_piece()
			G.check_win()
	elif event is InputEventMouseMotion and dragging:
		var new_pos = get_global_mouse_position() + drag_offset
		sprite2d.material.set("shader_parameter/mouse_screen_pos", new_pos)
		handle_drag_animation()
		position = new_pos

func drop_piece():
	# Check whether to place the piece on a cell
	var overlapping_areas = get_overlapping_areas()
	for cell in overlapping_areas:
		if cell.is_in_group("cell"):
			if cell.is_free():
				cell_index = cell.index
				cell.occupy()
				position = cell.global_position
				return

func handle_drag_animation():
	sprite2d.material.set("shader_parameter/shadow_offset", Vector2(10, -10))
