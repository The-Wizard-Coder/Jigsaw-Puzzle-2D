extends Node

var cells = []
var pieces = []
var dragging = false # global dragging, to avoid dragging multiple pieces
var score = 0;
var game_over = false;

var base_url := "https://collectionapi.metmuseum.org/public/collection/v1"

signal game_won

const images = [
	"res://images/1.jpg",
	"res://images/2.jpg",
	"res://images/3.jpg",
]

enum DIFFICULTY {
	EASY,
	MEDIUM,
	HARD
}

const DIFFICULTY_VALUES = {
	DIFFICULTY.EASY: 3,
	DIFFICULTY.MEDIUM: 4,
	DIFFICULTY.HARD: 5
}

var chosen_difficulty = DIFFICULTY.EASY
var grid_size = Vector2i(
	DIFFICULTY_VALUES[chosen_difficulty],
	DIFFICULTY_VALUES[chosen_difficulty]
)


func get_image():
	randomize()
	var image = Image.load_from_file(images.pick_random())
	return image

func find_cell(index: int):
	for cell in cells:
		if cell.index == index:
			return cell

func check_win():
	for piece in pieces:
		if piece.index != piece.cell_index:
			return
	score = score + 1
	game_over = true
	game_won.emit()
