extends CanvasLayer

var active_touches: Dictionary = {}
var zone_highlights: Array[ColorRect] = []

const TOUCH_ZONE_RATIO = 0.40

const ZONE_COLORS = [
	Color(0.54, 0.92, 0.94, 0.25),
	Color(0.96, 0.71, 0.11, 0.25),
	Color(0.71, 0.84, 0.24, 0.25),
	Color(0.22, 0.47, 0.66, 0.25),
]

func _ready():
	layer = 100
	var vp = get_viewport().get_visible_rect().size
	var zone_top = vp.y * (1.0 - TOUCH_ZONE_RATIO)
	var zone_height = vp.y * TOUCH_ZONE_RATIO
	var zone_width = vp.x / 4.0
	
	for i in range(4):
		var highlight = ColorRect.new()
		highlight.position = Vector2(zone_width * i, zone_top)
		highlight.size = Vector2(zone_width, zone_height)
		highlight.color = ZONE_COLORS[i]
		highlight.color.a = 0.0
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(highlight)
		zone_highlights.append(highlight)
	
	var separator_color = Color(1, 1, 1, 0.15)
	for i in range(1, 4):
		var sep = ColorRect.new()
		sep.position = Vector2(zone_width * i - 1, zone_top)
		sep.size = Vector2(2, zone_height)
		sep.color = separator_color
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sep)
	
	var border = ColorRect.new()
	border.position = Vector2(0, zone_top)
	border.size = Vector2(vp.x, 2)
	border.color = Color(1, 1, 1, 0.2)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)

func _get_zone_for_position(pos: Vector2) -> int:
	var vp = get_viewport().get_visible_rect().size
	var zone_width = vp.x / 4.0
	return clampi(int(pos.x / zone_width), 0, 3)

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			var zone = _get_zone_for_position(event.position)
			active_touches[event.index] = zone
			_emit_press(zone)
		else:
			if active_touches.has(event.index):
				var zone = active_touches[event.index]
				active_touches.erase(event.index)
				if not _is_zone_still_held(zone):
					_emit_release(zone)
	
	elif event is InputEventScreenDrag:
		if active_touches.has(event.index):
			var old_zone = active_touches[event.index]
			var new_zone = _get_zone_for_position(event.position)
			if old_zone != new_zone:
				active_touches[event.index] = new_zone
				if not _is_zone_still_held(old_zone):
					_emit_release(old_zone)
				_emit_press(new_zone)

func _is_zone_still_held(zone: int) -> bool:
	for z in active_touches.values():
		if z == zone:
			return true
	return false

func _emit_press(zone: int):
	var action = "col_%d" % zone
	var ev = InputEventAction.new()
	ev.action = action
	ev.pressed = true
	ev.strength = 1.0
	Input.parse_input_event(ev)
	zone_highlights[zone].color.a = ZONE_COLORS[zone].a

func _emit_release(zone: int):
	var action = "col_%d" % zone
	var ev = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)
	zone_highlights[zone].color.a = 0.0

func _process(delta):
	for i in range(4):
		if zone_highlights[i].color.a > 0 and not _is_zone_still_held(i):
			zone_highlights[i].color.a = max(0, zone_highlights[i].color.a - delta * 4.0)
