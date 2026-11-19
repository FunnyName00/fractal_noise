
extends Control

var noise := FastNoiseLite.new()

var values : PackedFloat32Array
var grid_w := 16
var grid_h := 16

var view: Control
func _ready() -> void:
	noise.seed = 4
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.frequency = 0.04
	_regenerate()
	_build_ui()
	print(values)


func _build_ui():
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)
 
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 280
	root.add_child(panel)
 
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	panel.add_child(margin)
 
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	
	view = Control.new()
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical= Control.SIZE_EXPAND_FILL
	view.clip_contents = true
	view.draw.connect(_draw_grid)
	view.resized.connect(view.queue_redraw)
	root.add_child(view)


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l


func _regenerate():
	values.resize(grid_h * grid_w)
	for y in range(grid_h):
		for x in range(grid_w):
			var n = noise.get_noise_2d(x, y)
			values[y * grid_w + x] = clampf((n+1.0) * 0.5, 0.0, 1.0)

func _draw_grid():
	if values.size() != grid_w * grid_h:
		return
	var cell := minf(view.size.x / grid_w, view.size.y / grid_h)
	var origin := (view.size - Vector2(cell * grid_w, cell * grid_h)) * 0.5
	var font := ThemeDB.fallback_font
	var font_size := int(clampf(cell * 0.3, 8.0, 22.0))
	
	for y in grid_h:
		for x in grid_w:
			var v := values[y * grid_w + x]
			var color = Color.BLACK
			var rect := Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell))
			view.draw_rect(rect, color)
			var text_color := Color.BLACK if color.get_luminance() > 0.5 else Color.WHITE
			var pos := rect.position + Vector2(0, cell * 0.5 + font_size * 0.35)
			view.draw_string(font, pos, "%.2f" % v,
			HORIZONTAL_ALIGNMENT_CENTER, cell, font_size, text_color)
