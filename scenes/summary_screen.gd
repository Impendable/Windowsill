class_name SummaryScreen
extends Control

@onready var score_label: Label = %Score

func update(score: int, best: int) -> void:
	score_label.text = "Score: %d\nBest: %d" % [score, best]
