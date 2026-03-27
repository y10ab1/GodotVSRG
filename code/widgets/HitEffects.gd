extends Node2D

var particles: Array = []

class HitParticle:
	var pos: Vector2
	var vel: Vector2
	var color: Color
	var life: float
	var max_life: float
	var size: float
	
	func _init(p_pos: Vector2, p_color: Color):
		pos = p_pos
		var angle = randf() * TAU
		var speed = randf_range(150, 400)
		vel = Vector2(cos(angle), sin(angle)) * speed
		color = p_color
		color.a = 1.0
		life = randf_range(0.2, 0.5)
		max_life = life
		size = randf_range(3, 8)

var camera: Camera2D
var shake_intensity = 0.0
var shake_decay = 8.0

func _ready():
	z_index = 200
	camera = get_viewport().get_camera_2d()

func spawn_hit_particles(world_pos: Vector2, color: Color, count: int = 12):
	for i in range(count):
		particles.append(HitParticle.new(world_pos, color))

func trigger_camera_shake(intensity: float):
	shake_intensity = max(shake_intensity, intensity)

func _process(delta):
	if shake_intensity > 0 and camera:
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = max(shake_intensity - shake_decay * delta * shake_intensity, 0)
		if shake_intensity < 0.1:
			shake_intensity = 0
			camera.offset = Vector2.ZERO
	
	var i = particles.size() - 1
	while i >= 0:
		var p = particles[i]
		p.life -= delta
		if p.life <= 0:
			particles.remove_at(i)
		else:
			p.vel *= 1.0 - (4.0 * delta)
			p.pos += p.vel * delta
			p.color.a = (p.life / p.max_life)
		i -= 1
	
	queue_redraw()

func _draw():
	for p in particles:
		draw_rect(
			Rect2(p.pos - Vector2(p.size, p.size) * 0.5, Vector2(p.size, p.size)),
			p.color
		)
