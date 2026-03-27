extends Node

class_name Chart

var column_count = 4
var audiofilename = ""
var audioleadin = 0
var bpm = -1
var scroll_vels = []
var max_score = 0
var clap_times = []
var columns = []
var duration = -1

var title
var artist

var sv_lookup_start = 0

func load_chart(directory, file):

	duration = -1
	for x in range(column_count):
		columns.append(null)
	
	sv_lookup_start = 0
	scroll_vels = []
	max_score = 0
	parse_osu(directory, file)
	
	for x in range(1, len(scroll_vels)):
		scroll_vels[x].z = scroll_vels[x-1].z + scroll_vels[x-1].x * (scroll_vels[x].y - scroll_vels[x-1].y)

func parse_osu(directory, file):
	var f = FileAccess.open(directory + file, FileAccess.READ)
	if not f:
		push_error("Cannot open chart: " + directory + file)
		return
	var lines = f.get_as_text().split("\n", false)
	var parsemode = ""
	var last_notes = []
	var last_sv_time = 0
	for x in range(column_count):
		last_notes.append(null)
	for line in lines:
		line = line.strip_edges()
		if line.is_empty():
			continue
		if line.begins_with("[") and line.ends_with("]"):
			parsemode = line.substr(1, line.length() - 2)
			continue
		if parsemode == "General":
			if line.begins_with("AudioFilename:"):
				audiofilename = line.substr(14).strip_edges()
			if line.begins_with("AudioLeadIn:"):
				var _audioleadin = line.substr(12).strip_edges().to_int()
				if _audioleadin > 0:
					audioleadin = _audioleadin
		elif parsemode == "Metadata":
			if line.begins_with("Title:"):
				var t = line.substr(6).strip_edges()
				Global.set_title(t)
				Global.results.title = t
			if line.begins_with("Artist:"):
				Global.results.artist = line.substr(7).strip_edges()
		elif parsemode == "TimingPoints":
			var sv = line.split(",")
			if len(sv) < 2:
				continue
			var sv1 = sv[1].to_float()
			if bpm == -1 and sv1 > 0:
				bpm = sv1
			var velocity = 1.0
			if sv1 < 0:
				velocity = 100.0 / abs(sv1)
				var v = 1.0 - velocity
				velocity = 1.0 + (v / 16.0)
			
			var vel_time = last_sv_time
			last_sv_time = (sv[0].to_int() + audioleadin) * 1000
			scroll_vels.append(Vector3(velocity, vel_time, 0))
		elif parsemode == "HitObjects":
			var note = line.split(",", false)
			if len(note) < 5:
				continue
			var n = NoteInfo.new()
			max_score += 320
			n.c = int((note[0].to_int() - 64) / 128.0)
			n.t = note[2].to_int() * 1000 + (audioleadin * 1000)
			
			if note[3].to_int() == 128:
				n.t2 = note[5].split(":")[0].to_int() * 1000 + (audioleadin * 1000)
				n.h = true
			else:
				n.h = false
				
			if len(clap_times) == 0:
				clap_times.append(n.t)
			else:
				if clap_times[len(clap_times) - 1] < n.t:
					clap_times.append(n.t)
				
			if n.c >= 0 and n.c < column_count:
				if columns[n.c] == null:
					columns[n.c] = n
				else:
					last_notes[n.c].n = n
				last_notes[n.c] = n
			
	for x in range(column_count):
		if last_notes[x] == null:
			continue
		if last_notes[x].t > duration:
			duration = last_notes[x].t
		if last_notes[x].h:
			if last_notes[x].t2 > duration:
				duration = last_notes[x].t2
	
	if duration < 0:
		duration = 1000000

func get_adjusted_time(in_time, update_min=false):
	var sv_index = -1
	for svi in range(sv_lookup_start, len(scroll_vels)):
		var vel_change = scroll_vels[svi]
		if vel_change.y > in_time:
			sv_index = svi
			break
	if update_min:
		sv_lookup_start = sv_index
	if sv_index == 0:
		return in_time
	if sv_index != -1:
		var lerp_amount = (float(in_time) - scroll_vels[sv_index-1].y) / (scroll_vels[sv_index].y - scroll_vels[sv_index-1].y)
		return lerp(scroll_vels[sv_index-1].z, scroll_vels[sv_index].z, lerp_amount)
	sv_index = len(scroll_vels) - 1
	
	var out_time = ((in_time - scroll_vels[sv_index].y) * scroll_vels[sv_index].x) + scroll_vels[sv_index].z
	
	return out_time
