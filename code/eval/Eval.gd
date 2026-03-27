extends Node2D

@onready
var graph = get_node("../ui/Graph")
@onready
var counts = get_node("../ui/count_bg/counts")
@onready
var grade = get_node("../ui/grade")
@onready
var accuracy = get_node("../ui/acc")
@onready
var songtitle = get_node("../ui/songtitle")

var judgements = [0,0,0,0,0,0,0,0]

func test_graph():
	Global.results.reset()
	for x in range(-180,181):
		Global.results.add_hit(x+180,x*1000,false,false)
	Global.results.song_start = 0
	Global.results.song_end = 361

func get_judge(t):
	for x in range(len(Global.windows)):
		if abs(t) < Global.windows[x]:
			return x
	return 5

func _ready():
	if len(Global.results.hits)==0:
		test_graph()
	
	var graph_w = 640
	var graph_h = 360
	var image = Image.create_empty(graph_w, graph_h, false, Image.FORMAT_RGBA8)
	var image_texture: ImageTexture
	var total_acc = 0
	var mAcc = 0
	for note in Global.results.hits:
		if !is_note_hold_info(note):
			total_acc += Global.wife3(note.offset/float(1000000), 1)
			mAcc += 2
			judgements[get_judge(note.offset)] += 1
			var note_c = Global.colors[Global.window_from_offset(note.offset)]			
			var note_offset = clamp(floor(note.offset/1000.0),-180,179)
			var song_pos = clamp(floor(get_hit_song_percent(note)*graph_w),0,graph_w-1)
			image.set_pixel(song_pos, graph_h/2 + note_offset, note_c)
		else:
			if note.type == Global.results.HitInfoType.NO_GOOD:
				judgements[7] += 1
			else:
				judgements[6] += 1
	
	if mAcc > 0:
		total_acc = (total_acc / float(mAcc)) * 100.0
	else:
		total_acc = 0.0
	var g = Global.WifeAccToGrade(total_acc)
	var g2 = g.replace(".","").replace(":","")
	set_grade(g, g2)
	
	accuracy.text = "[center]%.2f%%[/center]" % total_acc
				
	counts.text = "[right]"
	for x in range(6):
		counts.text += str(judgements[x])
		counts.text += "\n"
	counts.text += str(judgements[6])+"/"+str(judgements[6]+judgements[7])
	counts.text += "[/right]"
	
	songtitle.text = "[center][color=#fff]%s\n[font_size=24]%s[/font_size][/color][/center]" % [Global.results.title, Global.results.artist]
			
	image_texture = ImageTexture.create_from_image(image)
	graph.texture = image_texture

func set_grade(subgrade, _grade):
	grade.text = "[center][color=%s]%s[/color][/center]" % [Global.colours["grade"][_grade],subgrade]

func is_note_hold_info(note):
	return note.type == Global.results.HitInfoType.NO_GOOD or note.type == Global.results.HitInfoType.OK
	
func get_hit_song_percent(note):
	return note.time/float(Global.results.song_end-Global.results.song_start)

func _on_retry_pressed():
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/song_select.tscn")

func _input(event):
	if event.is_action_pressed("restart"):
		_on_retry_pressed()
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
