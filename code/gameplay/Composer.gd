extends Node2D

var n_mat = preload("res://Material/Hidden.tres")

var cScore = 0
var mScore = 0

var osuScore = 0

var column_count = 4

var spawned_notes = []

var audio = null
var clap = null
var hitsound = null

var time
var t_song_zero
var spawn_distance = 1500000
var t_begin = 0
var t_delay = 0
var alreadyplayed = false

var combo = 0

const usec = 1000000

var song_failed = false

var clap_index = 0

var audiofilename = ""
var audioleadin = 0
var bpm = -1

var chart = null

var song_dir = "res://song/"
var chart_file = "chart.osu"

func _ready():
	Global.reset_gameplay()
	Global.composer = self
	Global.worst_hit = 0
	
	if Global.has_meta("current_song_dir"):
		song_dir = Global.get_meta("current_song_dir")
	if Global.has_meta("current_chart_file"):
		chart_file = Global.get_meta("current_chart_file")
	
	t_song_zero = Time.get_ticks_usec()+(3*usec)
	
	n_mat.set_shader_parameter("h_end_y", Global.user_settings.hidden_end_y)
	n_mat.set_shader_parameter("h_start_y", Global.user_settings.hidden_start_y)
	n_mat.set_shader_parameter("s_end_y", Global.user_settings.sudden_end_y)
	n_mat.set_shader_parameter("s_start_y", Global.user_settings.sudden_start_y)
	
	t_begin = Time.get_ticks_usec()
	for x in range(column_count):
		spawned_notes.append([])	
	
	audio = get_node("../audio")
	clap = get_node("../clap")
	hitsound = get_node("../hitsound")
	
	var hit_fx = get_node_or_null("../HitEffects")
	if hit_fx:
		Global.hit_effects = hit_fx
	
	var chart_path = song_dir + chart_file
	if not FileAccess.file_exists(chart_path):
		push_error("Chart file not found: " + chart_path)
		get_tree().change_scene_to_file("res://scenes/song_select.tscn")
		return
	
	chart = Chart.new()
	chart.load_chart(song_dir, chart_file)
	
	var audio_path = song_dir + chart.audiofilename.strip_edges()
	if FileAccess.file_exists(audio_path):
		if audio_path.ends_with(".mp3"):
			var mp3 = AudioStreamMP3.new()
			mp3.data = FileAccess.get_file_as_bytes(audio_path)
			audio.stream = mp3
		elif audio_path.ends_with(".ogg"):
			var ogg = AudioStreamOggVorbis.load_from_file(audio_path)
			audio.stream = ogg
	else:
		push_warning("Audio file not found: " + audio_path)
	
	var clap_snd = load("res://sounds/clap.ogg")
	if clap_snd:
		clap.stream = clap_snd
		hitsound.stream = clap_snd
	
	Global.results.reset()
	Global.results.song_start = Time.get_ticks_usec()
	Global.results.song_end = Time.get_ticks_usec() + chart.duration
				
func _process(_delta):
	if chart == null:
		return
	time = Global.song_time()
	
	Global.SetProgress(time/chart.duration)
	
	if time >= 0 and !audio.playing and !alreadyplayed:
		t_song_zero = Time.get_ticks_usec()
		
		Global.results.song_start = Global.song_time()
		Global.results.song_end   = Global.song_time()+chart.duration
		
		t_delay = (AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()) * 1000000.0
		if audio.stream:
			audio.play(0)
		alreadyplayed = true
	
	check_to_spawn_notes()
	check_to_despawn_notes()
	check_to_play_clap()
	
	if song_failed and Global.user_settings.immediate_fail:
		get_tree().change_scene_to_file("res://scenes/eval.tscn")
		
	if time > chart.duration:
		audio.volume_db = -20 - ((time-chart.duration)*15)/float(usec)
		
		if time > chart.duration + usec*2.5:
			get_tree().change_scene_to_file("res://scenes/eval.tscn")
			
func check_to_play_clap():
	if !Global.user_settings.clap:
		return
	if clap_index < len(chart.clap_times):
		var ct = chart.clap_times[clap_index]
		var _time = Global.song_time()+Global.user_settings.note_global_offset-ct
		if _time > 0:
			clap.play(0)
			clap_index += 1
		
func check_to_spawn_notes():
	for x in range(column_count):
		var cf = chart.columns[x]
		var check = cf != null
		while check and cf.t < Global.song_time()+spawn_distance+Global.user_settings.note_global_offset:
			spawn_note(cf)
			chart.columns[x] = cf.n
			cf = cf.n
			check = cf != null
			
func spawn_note(noteinfo):
	var note = NoteObject.new()
	note.texture = preload("res://sprites/note.png")
	note.texture_filter = note.TEXTURE_FILTER_NEAREST
	
	note.material = n_mat;
	
	note.scale = Vector2(5, 2)
	note.c = noteinfo.c
	note.t = noteinfo.t
	note.t2 = noteinfo.t2
	note.h = noteinfo.h
	
	note.r_pos = Vector2(-270 + noteinfo.c * 180, 500)
	
	spawned_notes[note.c].append(note)
	
	add_child(note)

func check_to_despawn_notes():
	var _time = Global.song_time()+Global.user_settings.note_global_offset
	for col in range(column_count):
		if len(spawned_notes[col]) > 0:
			var n = spawned_notes[col][0]
			if n != null:
				if n.h:
					if n.isheld:
						if n.life < 0:
							n.missed()
							Global.results.add_hit( Global.song_time(), _time-n.t2, true, true )
							handle_score(n, Global.windows[Global.WINDOWS.BD])
							spawned_notes[col].remove_at(0)
						if _time-n.t2 > Global.windows[Global.WINDOWS.BD]-n.life*usec:
							n.completed()
							Global.results.add_hit( Global.song_time(), _time-n.t2, false, true )
							spawned_notes[col].remove_at(0)
					else:
						if _time-n.t > Global.windows[Global.WINDOWS.BD]:
							n.missed()
							Global.results.add_hit( Global.song_time(), _time-n.t2, true, false )
							Global.results.add_hit( Global.song_time(), _time-n.t2, true, true )
							handle_score(n, Global.windows[Global.WINDOWS.BD])
							spawned_notes[col].remove_at(0)
				else:
					if _time-n.t > Global.windows[Global.WINDOWS.BD]:
						n.missed()
						Global.results.add_hit( Global.song_time(), _time-n.t, true, false )
						handle_score(n, Global.windows[Global.WINDOWS.BD])
						spawned_notes[col].remove_at(0)

func handle_score(noteobj,t):
	var judge = -1
	for x in range(len(Global.windows)):
		if abs(t) < Global.windows[x] and judge == -1:
			judge = x
		
	match(judge):
		0: 
			osuScore += 320
			combo += 1
		1: 
			osuScore += 300
			combo += 1
		2: 
			osuScore += 200
			combo += 1
		3: 
			osuScore += 100
			combo = 0
		4: 
			osuScore += 50
			combo = 0
		-1: 
			osuScore += 0
			combo = 0
			
	if combo > 0 and combo % 100 == 0:
		Global.DoToastie()
		
	Global.score.update_score((osuScore*1000000.0)/float(chart.max_score))
		
	cScore += Global.wife3(t/float(usec), 1)
	mScore += 2
	
	var percent = cScore/mScore*100
	Global.acc.text = ("%.2f" % percent)+"%"
	
	Global.set_combo(combo)
	Global.DoJudge(judge, noteobj.c)
	Global.DoHitError(t)

func handle_hit(col):
	if Global.user_settings.hitsound:
		hitsound.play(0)
	var _time = Global.song_time()+Global.user_settings.note_global_offset
	if len(spawned_notes[col]) > 0:
		var n = spawned_notes[col][0]
		if n != null:
			if _time-n.t > -Global.windows[Global.WINDOWS.BD]:
				n.hit()
				handle_score(n, _time-n.t)
				if n.h != true:
					spawned_notes[col].remove_at(0)
				Global.add_nps_note(_time)
				Global.results.add_hit( Global.song_time(), _time-n.t, false, false )

func handle_release(col):
	var _time = Global.song_time()+Global.user_settings.note_global_offset
	if len(spawned_notes[col]) > 0:
		var n = spawned_notes[col][0]
		if n != null:
			if n.h:
				n.release()
				if _time-n.t2 > Global.windows[Global.WINDOWS.BD]-n.life*usec:
					n.completed()
					Global.results.add_hit( Global.song_time(), _time-n.t2, false, true )
					spawned_notes[col].remove_at(0)

func _input(event):
	if event.is_action_pressed("col_0"):
		handle_hit(0)
	if event.is_action_pressed("col_1"):
		handle_hit(1)
	if event.is_action_pressed("col_2"):
		handle_hit(2)
	if event.is_action_pressed("col_3"):
		handle_hit(3)
	
	if event.is_action_released("col_0"):
		handle_release(0)
	if event.is_action_released("col_1"):
		handle_release(1)
	if event.is_action_released("col_2"):
		handle_release(2)
	if event.is_action_released("col_3"):
		handle_release(3)

	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
