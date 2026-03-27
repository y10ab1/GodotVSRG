extends Control

@onready var scroll_speed_slider: HSlider = %ScrollSpeedSlider
@onready var scroll_speed_label: Label = %ScrollSpeedLabel
@onready var offset_slider: HSlider = %OffsetSlider
@onready var offset_label: Label = %OffsetLabel
@onready var cmod_check: CheckButton = %CmodCheck
@onready var reverse_check: CheckButton = %ReverseCheck
@onready var clap_check: CheckButton = %ClapCheck
@onready var hitsound_check: CheckButton = %HitsoundCheck
@onready var nps_check: CheckButton = %NPSCheck
@onready var toasties_check: CheckButton = %ToastiesCheck

var settings: UserSettings

func _ready():
	settings = Global.user_settings
	
	scroll_speed_slider.value = settings.scroll_speed
	scroll_speed_label.text = "%.2f" % settings.scroll_speed
	
	offset_slider.value = settings.note_global_offset / 1000.0
	offset_label.text = "%d ms" % (settings.note_global_offset / 1000)
	
	cmod_check.button_pressed = settings.cmod
	reverse_check.button_pressed = settings.reverse_scroll
	clap_check.button_pressed = settings.clap
	hitsound_check.button_pressed = settings.hitsound
	nps_check.button_pressed = settings.nps
	toasties_check.button_pressed = settings.toasties

func _on_scroll_speed_slider_value_changed(value: float):
	settings.scroll_speed = value
	scroll_speed_label.text = "%.2f" % value

func _on_offset_slider_value_changed(value: float):
	settings.note_global_offset = int(value * 1000)
	offset_label.text = "%d ms" % int(value)

func _on_cmod_check_toggled(toggled_on: bool):
	settings.cmod = toggled_on

func _on_reverse_check_toggled(toggled_on: bool):
	settings.reverse_scroll = toggled_on

func _on_clap_check_toggled(toggled_on: bool):
	settings.clap = toggled_on

func _on_hitsound_check_toggled(toggled_on: bool):
	settings.hitsound = toggled_on

func _on_nps_check_toggled(toggled_on: bool):
	settings.nps = toggled_on

func _on_toasties_check_toggled(toggled_on: bool):
	settings.toasties = toggled_on

func _on_back_pressed():
	settings.save_settings()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
