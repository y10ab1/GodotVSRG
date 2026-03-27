extends Control

@onready var song_list: VBoxContainer = %SongList
@onready var info_title: Label = %InfoTitle
@onready var info_artist: Label = %InfoArtist
@onready var info_diff: Label = %InfoDiff

var selected_index = -1
var selected_btn: Button = null

func _ready():
	SongManager.scan_songs()
	_populate_list()

func _populate_list():
	for child in song_list.get_children():
		child.queue_free()
	
	if SongManager.get_song_count() == 0:
		var empty_label = Label.new()
		empty_label.text = "No songs found.\nPlace .osu files in the song/ folder."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.55))
		empty_label.add_theme_font_size_override("font_size", 16)
		song_list.add_child(empty_label)
		return
	
	for i in range(SongManager.get_song_count()):
		var song = SongManager.get_song(i)
		var btn = Button.new()
		btn.text = "%s  -  %s" % [song.title, song.artist]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size.y = 64
		btn.add_theme_font_size_override("font_size", 17)
		
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.12, 0.1, 0.16, 0.9)
		style_normal.corner_radius_top_left = 6
		style_normal.corner_radius_top_right = 6
		style_normal.corner_radius_bottom_left = 6
		style_normal.corner_radius_bottom_right = 6
		style_normal.content_margin_left = 20
		style_normal.content_margin_right = 20
		style_normal.border_width_left = 3
		style_normal.border_color = Color(0.3, 0.2, 0.5, 0)
		btn.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover = style_normal.duplicate()
		style_hover.bg_color = Color(0.18, 0.14, 0.25, 0.95)
		style_hover.border_color = Color(0.5, 0.3, 0.8, 0.5)
		btn.add_theme_stylebox_override("hover", style_hover)
		
		var style_pressed = style_normal.duplicate()
		style_pressed.bg_color = Color(0.25, 0.18, 0.4, 1.0)
		style_pressed.border_color = Color(0.6, 0.4, 1.0, 1.0)
		btn.add_theme_stylebox_override("pressed", style_pressed)
		
		var style_focus = style_normal.duplicate()
		style_focus.bg_color = Color(0.2, 0.15, 0.32, 1.0)
		style_focus.border_color = Color(0.6, 0.4, 1.0, 0.8)
		btn.add_theme_stylebox_override("focus", style_focus)
		
		btn.add_theme_color_override("font_color", Color(0.85, 0.82, 0.92))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		
		var idx = i
		btn.pressed.connect(func(): _on_song_selected(idx, btn))
		song_list.add_child(btn)

func _on_song_selected(index: int, btn: Button):
	selected_index = index
	var song = SongManager.get_song(index)
	if not song:
		return
	info_title.text = song.title
	info_artist.text = song.artist
	info_diff.text = song.difficulty if song.difficulty != "" else "Default"
	
	if selected_btn and is_instance_valid(selected_btn):
		var old_style = selected_btn.get_theme_stylebox("normal").duplicate()
		old_style.border_color = Color(0.3, 0.2, 0.5, 0)
		selected_btn.add_theme_stylebox_override("normal", old_style)
	
	selected_btn = btn
	var active_style = btn.get_theme_stylebox("normal").duplicate()
	active_style.bg_color = Color(0.2, 0.15, 0.32, 1.0)
	active_style.border_color = Color(0.6, 0.4, 1.0, 0.8)
	btn.add_theme_stylebox_override("normal", active_style)

func _on_play_pressed():
	if selected_index >= 0:
		SongManager.play_song(selected_index)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
