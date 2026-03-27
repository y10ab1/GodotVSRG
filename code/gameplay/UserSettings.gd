extends Node
class_name UserSettings

var reverse_scroll = false
var scroll_speed = 3.0
var cmod = true

var toasties = true
var nps = true

var clap = true
var hitsound = false

var hidden_start_y = 1.0
var hidden_end_y = 1.0
var sudden_start_y = 0.0
var sudden_end_y = 0.0

var note_global_offset = 0
var note_visual_offset = 0

var shockwaves = false
var shockwave_force = 0.0025
var shockwave_feather = 0.1

var hide_judgements_below = 0

var immediate_fail = false

const SETTINGS_PATH = "user://settings.json"

func load_settings():
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not f:
		return
	var json = JSON.new()
	var err = json.parse(f.get_as_text())
	f.close()
	if err != OK:
		return
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return
	
	if data.has("reverse_scroll"): reverse_scroll = data["reverse_scroll"]
	if data.has("scroll_speed"): scroll_speed = data["scroll_speed"]
	if data.has("cmod"): cmod = data["cmod"]
	if data.has("toasties"): toasties = data["toasties"]
	if data.has("nps"): nps = data["nps"]
	if data.has("clap"): clap = data["clap"]
	if data.has("hitsound"): hitsound = data["hitsound"]
	if data.has("hidden_start_y"): hidden_start_y = data["hidden_start_y"]
	if data.has("hidden_end_y"): hidden_end_y = data["hidden_end_y"]
	if data.has("sudden_start_y"): sudden_start_y = data["sudden_start_y"]
	if data.has("sudden_end_y"): sudden_end_y = data["sudden_end_y"]
	if data.has("note_global_offset"): note_global_offset = data["note_global_offset"]
	if data.has("note_visual_offset"): note_visual_offset = data["note_visual_offset"]
	if data.has("shockwaves"): shockwaves = data["shockwaves"]
	if data.has("shockwave_force"): shockwave_force = data["shockwave_force"]
	if data.has("shockwave_feather"): shockwave_feather = data["shockwave_feather"]
	if data.has("hide_judgements_below"): hide_judgements_below = data["hide_judgements_below"]
	if data.has("immediate_fail"): immediate_fail = data["immediate_fail"]

func save_settings():
	var data = {
		"reverse_scroll": reverse_scroll,
		"scroll_speed": scroll_speed,
		"cmod": cmod,
		"toasties": toasties,
		"nps": nps,
		"clap": clap,
		"hitsound": hitsound,
		"hidden_start_y": hidden_start_y,
		"hidden_end_y": hidden_end_y,
		"sudden_start_y": sudden_start_y,
		"sudden_end_y": sudden_end_y,
		"note_global_offset": note_global_offset,
		"note_visual_offset": note_visual_offset,
		"shockwaves": shockwaves,
		"shockwave_force": shockwave_force,
		"shockwave_feather": shockwave_feather,
		"hide_judgements_below": hide_judgements_below,
		"immediate_fail": immediate_fail
	}
	var f = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if not f:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
