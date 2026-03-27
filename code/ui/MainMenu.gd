extends Control

func _ready():
	pass

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/song_select.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed():
	get_tree().quit()
