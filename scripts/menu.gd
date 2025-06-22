extends Node2D

@onready var option: OptionButton = $Menu/OptionButton

func _on_button_pressed():
	match option.selected:
		0:
			G.chosen_difficulty = G.DIFFICULTY.EASY
		1: 
			G.chosen_difficulty = G.DIFFICULTY.MEDIUM
		2:
			G.chosen_difficulty = G.DIFFICULTY.HARD
	G.grid_size = Vector2i(
		G.DIFFICULTY_VALUES[G.chosen_difficulty],
		G.DIFFICULTY_VALUES[G.chosen_difficulty]
	)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
