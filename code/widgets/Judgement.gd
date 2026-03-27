extends Sprite2D

var FADE_TIME = 0.5
var t = FADE_TIME

var textures = []
var sparks = []
var spark_sprites: Array[Sprite2D] = []
var current_judge = 0

func judge(j):
	t = 0
	current_judge = j
	texture = textures[j]
	
	for i in range(spark_sprites.size()):
		spark_sprites[i].texture = sparks[mini(j, sparks.size() - 1)]
		spark_sprites[i].modulate = Global.colors[j]
		spark_sprites[i].modulate.a = 1.0
		spark_sprites[i].scale = Vector2(0.3, 0.3)
		spark_sprites[i].rotation = randf() * TAU
	
func _ready():	
	Global.judge = self
	
	textures.append(preload("res://sprites/MA.png"))
	textures.append(preload("res://sprites/PF.png"))
	textures.append(preload("res://sprites/GR.png"))
	textures.append(preload("res://sprites/GD.png"))
	textures.append(preload("res://sprites/BD.png"))
	textures.append(preload("res://sprites/MS.png"))
	
	sparks.append(preload("res://sprites/jsparkma.png"))
	sparks.append(preload("res://sprites/jsparkpf.png"))
	sparks.append(preload("res://sprites/jsparkgr.png"))
	sparks.append(preload("res://sprites/jsparkgd.png"))
	sparks.append(preload("res://sprites/jsparkbd.png"))
	sparks.append(preload("res://sprites/jsparkms.png"))
	
	for i in range(4):
		var spark = Sprite2D.new()
		spark.texture = sparks[0]
		spark.modulate.a = 0
		spark.scale = Vector2(0.3, 0.3)
		spark.z_index = 91
		add_child(spark)
		spark_sprites.append(spark)

func _process(delta):
	if t < FADE_TIME:
		t += delta

	var inv_time = 1.0 - (t / FADE_TIME)
	var ease_out = 1.0 - (inv_time * inv_time)
	
	var bounce = 1.0
	if t < 0.08:
		bounce = lerp(1.3, 1.0, t / 0.08)
	scale = Vector2(.5, .5) * lerp(bounce, .6, ease_out)
	rotation = lerp(0.0, -deg_to_rad(25.0), ease_out)
	modulate.a = 1 - (t / FADE_TIME)
	
	for i in range(spark_sprites.size()):
		var spark = spark_sprites[i]
		if spark.modulate.a > 0:
			spark.modulate.a = max(0, spark.modulate.a - delta * 3.0)
			spark.scale += Vector2(delta * 2.0, delta * 2.0)
			var angle = (TAU / spark_sprites.size()) * i + spark.rotation
			spark.position = Vector2(cos(angle), sin(angle)) * (1.0 - spark.modulate.a) * 80
