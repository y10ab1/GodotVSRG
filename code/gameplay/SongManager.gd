extends Node
class_name SongManagerClass

var songs: Array = []
var songs_dir_res = "res://song/"

class SongEntry:
	var dir_path: String
	var chart_file: String
	var title: String
	var artist: String
	var audio_file: String
	var difficulty: String
	
	func _init(p_dir: String = "", p_chart: String = ""):
		dir_path = p_dir
		chart_file = p_chart
		title = "Unknown"
		artist = "Unknown"
		audio_file = ""
		difficulty = ""

func _ready():
	scan_songs()

func scan_songs():
	songs.clear()
	_scan_directory(songs_dir_res)
	_scan_user_songs()
	print("SongManager: Found %d songs" % songs.size())

func _scan_user_songs():
	var user_songs_dir = "user://songs/"
	if not DirAccess.dir_exists_absolute(user_songs_dir):
		DirAccess.make_dir_recursive_absolute(user_songs_dir)
		return
	_scan_directory(user_songs_dir)

func _scan_directory(base_dir: String):
	var dir = DirAccess.open(base_dir)
	if not dir:
		return
	
	_scan_for_osu_in(base_dir)
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			var sub_dir = base_dir + folder_name + "/"
			_scan_for_osu_in(sub_dir)
		folder_name = dir.get_next()
	dir.list_dir_end()

func _scan_for_osu_in(dir_path: String):
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".osu"):
			var entry = _parse_osu_metadata(dir_path, file_name)
			if entry:
				songs.append(entry)
		file_name = dir.get_next()
	dir.list_dir_end()

func _parse_osu_metadata(dir_path: String, file_name: String) -> SongEntry:
	var full_path = dir_path + file_name
	if not FileAccess.file_exists(full_path):
		return null
	
	var f = FileAccess.open(full_path, FileAccess.READ)
	if not f:
		return null
	
	var entry = SongEntry.new(dir_path, file_name)
	var in_section = ""
	
	while not f.eof_reached():
		var line = f.get_line().strip_edges()
		if line.begins_with("["):
			in_section = line.trim_prefix("[").trim_suffix("]")
			if in_section == "HitObjects":
				break
			continue
		
		if in_section == "General":
			if line.begins_with("AudioFilename:"):
				entry.audio_file = line.substr(14).strip_edges()
		elif in_section == "Metadata":
			if line.begins_with("Title:"):
				entry.title = line.substr(6).strip_edges()
			elif line.begins_with("Artist:"):
				entry.artist = line.substr(7).strip_edges()
			elif line.begins_with("Version:"):
				entry.difficulty = line.substr(8).strip_edges()
	
	return entry

func get_song_count() -> int:
	return songs.size()

func get_song(index: int) -> SongEntry:
	if index >= 0 and index < songs.size():
		return songs[index]
	return null

func play_song(index: int):
	var song = get_song(index)
	if not song:
		return
	Global.set_meta("current_song_dir", song.dir_path)
	Global.set_meta("current_chart_file", song.chart_file)
	Global.set_meta("current_song_index", index)
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")

func add_song_from_files(audio_data: PackedByteArray, audio_ext: String, osu_content: String, folder_name: String) -> bool:
	var dir_path = "user://songs/" + folder_name + "/"
	DirAccess.make_dir_recursive_absolute(dir_path)
	
	var audio_file = "audio" + audio_ext
	var f_audio = FileAccess.open(dir_path + audio_file, FileAccess.WRITE)
	if not f_audio:
		return false
	f_audio.store_buffer(audio_data)
	f_audio.close()
	
	var f_chart = FileAccess.open(dir_path + "chart.osu", FileAccess.WRITE)
	if not f_chart:
		return false
	f_chart.store_string(osu_content)
	f_chart.close()
	
	scan_songs()
	return true
