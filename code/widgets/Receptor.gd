extends Sprite2D

@export
var input_str: String
var tex_p = preload("res://sprites/receptor-pressed.png")
var tex_u = preload("res://sprites/receptor-unpressed.png")

var base_scale = Vector2(5, 5)
var press_scale = Vector2(5.6, 5.6)
var current_scale_t = 1.0
var glow_alpha = 0.0

var flash_sprite: Sprite2D

func _ready():
	flash_sprite = Sprite2D.new()
	flash_sprite.texture = preload("res://sprites/white.png")
	flash_sprite.scale = Vector2(32, 32)
	flash_sprite.modulate = Color(1, 1, 1, 0)
	flash_sprite.z_index = -1
	add_child(flash_sprite)

func _input(event):
	if event.is_action_pressed(input_str):
		texture = tex_p
		current_scale_t = 0.0
		glow_alpha = 0.6
	if event.is_action_released(input_str):
		texture = tex_u

func _process(delta):
	current_scale_t = min(current_scale_t + delta * 8.0, 1.0)
	var ease_t = current_scale_t * current_scale_t
	scale = press_scale.lerp(base_scale, ease_t)
	
	glow_alpha = max(glow_alpha - delta * 4.0, 0.0)
	flash_sprite.modulate.a = glow_alpha
