extends Node2D

@onready var cells = $Cells
@onready var cell_scene = preload("res://scenes/Cell.tscn")

@onready var pieces = $Pieces
@onready var piece_scene = preload("res://scenes/PuzzlePiece.tscn")

@onready var http: HTTPRequest
var image: Image = null
var object_ids = []

#var piece_size: Vector2 = Vector2.ZERO
var piece_size: Vector2 = Vector2(100, 100)
@onready var preview: TextureRect = $ImagePreview
@onready var loader = $Control2
@onready var score_label = $ScoreLabel

func _ready():
	http = HTTPRequest.new()
	add_child(http)
	G.game_won.connect(game_won)
	init_game()

func init_game(reload=false):
	free_stuff()
	G.game_over = false
	loader.show()
	await load_random_artwork()
	if reload or not image:
		image = G.get_image()
	image = scale_image(image)
	loader.hide()
	preview.texture = ImageTexture.create_from_image(image)
	generate_pieces()
	draw_cells()

func free_stuff():
	for cell in G.cells:
		cell.queue_free()
	for piece in G.pieces:
		piece.queue_free()
	G.cells = []
	G.pieces = []

func draw_cells():
	for i in range(G.grid_size.x):
		for j in range(G.grid_size.y):
			add_cell(i, j)

func add_cell(i, j):
	var cell = cell_scene.instantiate()
	cells.add_child(cell)
	G.cells.append(cell)
	cell.position = Vector2(
		int(piece_size.x) * i,
		int(piece_size.y) * j
	)
	var idx = int(i * G.grid_size.x) + j 
	cell.init_cell(idx, piece_size)

func generate_pieces():
	#var image: Image = G.get_image()
	var texture = ImageTexture.create_from_image(image)
	piece_size = Vector2(
		texture.get_width() / G.grid_size.x,
		texture.get_height() / G.grid_size.y
	)
	
	for i in range(G.grid_size.x):
		for j in range(G.grid_size.y):
			var piece = piece_scene.instantiate()
			pieces.add_child(piece)
			G.pieces.append(piece)
			
			# Select region from image
			var region = Rect2(i * piece_size.x, j * piece_size.y, piece_size.x, piece_size.y)
			var sub_image = image.get_region(Rect2i(region.position, region.size))
			var sub_tex = ImageTexture.create_from_image(sub_image)
			var pos
			var index = int(i * G.grid_size.x + j)
			randomize()
			if index < (G.grid_size.x * G.grid_size.y) / 2:
				pos = Vector2(
					randi_range(100, 200),
					randi_range(400, 700)
				)
			else:
				pos = Vector2(
					randi_range(700, 900),
					randi_range(200, 800)
				)
			
			piece.init_piece(
				index,
				sub_tex,
				pos,
				piece_size
			)

func load_random_artwork():
	if len(object_ids) == 0:
		# Step 1: Get list of painting object IDs
		var search_url = G.base_url + "/search?hasImages=true&q=painting"
		var err = await http.request(search_url)
		if err != HTTPRequest.RESULT_SUCCESS:
			print("Failed to get painting list")
			return
		var result_data = await http.request_completed
		var body = result_data[3] # this is a PoolByteArray
		var text = body.get_string_from_utf8()
		var data = JSON.parse_string(text)
		if data == null or "objectIDs" not in data:
			print("Invalid response from search")
			return

		object_ids = data["objectIDs"]
		randomize()
	
	object_ids.shuffle()

	for object_id in object_ids:
		# Step 2: Get metadata for one object
		var object_url = G.base_url + "/objects/" + str(int(object_id))
		print("URL: ", object_url)
		var err = await http.request(object_url)
		if err != HTTPRequest.RESULT_SUCCESS:
			continue
		var result_data = await http.request_completed
		var body = result_data[3]
		var text = body.get_string_from_utf8()
		var obj_data = JSON.parse_string(text)
		print(obj_data)
		if obj_data and obj_data.has("primaryImage") and obj_data["primaryImage"] != "":
			await load_image_from_url(obj_data["primaryImage"])
			return  # Done

func load_image_from_url(url: String):
	print("Loading image from url")
	var image_result = await http.request(url)
	if image_result != HTTPRequest.RESULT_SUCCESS:
		print("Image download failed")
		return
	image = Image.new()
	var result_data = await http.request_completed
	var body = result_data[3]
	var err = image.load_jpg_from_buffer(body)
	if err != OK:
		err = image.load_png_from_buffer(body)
	if err != OK:
		print("Could not load image buffer")
		return

func scale_image(image: Image):
	var new_image = Image.new()
	new_image.copy_from(image)
	var original_size = image.get_size()
	var max_size = Vector2(800, 800)
	var scale_factor = min(
		max_size.x / original_size.x,
		max_size.y / original_size.y
	)
	var new_size = (original_size * scale_factor).floor()
	new_image.resize(new_size.x, new_size.y, Image.INTERPOLATE_LANCZOS)
	return new_image


func _on_button_pressed():
	init_game(false)

func game_won():
	score_label.text = "Score: " + str(G.score)
