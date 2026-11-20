extends Control

var noise := FastNoiseLite.new()
var noise_seed := 4

var values := PackedFloat32Array()
var grid_w := 100
var grid_h := grid_w

var gradient := Gradient.new()
var view: Control

var regenerate_button: Button
var seed_button: Button


func _ready() -> void:
	_gradient()
	_build_ui()
	_refresh_view()


func _build_ui() -> void:
	var root := $root
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)

	regenerate_button = $root/panel/margin/box/Regenerate
	regenerate_button.pressed.connect(_refresh_view)
	
	seed_button = $root/panel/margin/box/Seed
	seed_button.pressed.connect(_on_seed_pressed)
	
	var grid_size_control: Range = $root/panel/margin/box/gridsize
	grid_size_control.value_changed.connect(_on_gridsize_changed)
	var visible_text_button: BaseButton = $root/panel/margin/box/visible_text
	visible_text_button.toggled.connect(func(_pressed: bool) -> void:
		if view:
			view.queue_redraw()
		)
	var controls: Array[Range] = [
		$root/panel/margin/box/octave,
		$root/panel/margin/box/frequency,
		$root/panel/margin/box/gain,
		$root/panel/margin/box/lacunarity,
	]
	for control in controls:
		control.value_changed.connect(_on_param_changed)

	view = $root/view
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.draw.connect(_draw_grid)
	view.resized.connect(view.queue_redraw)


func _gradient() -> void:
	# 0 = bas (eau profonde) -> 1 = haut (neige)
	gradient.offsets = PackedFloat32Array([0.0, 0.35, 0.5, 0.7, 0.85, 1.0])
	gradient.colors = PackedColorArray([
		Color("0b1d51"), Color("2a6fdb"), Color("3fae49"),
		Color("c9b458"), Color("8a6a4a"), Color("ffffff"),
	])


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l


func _regenerate() -> void:
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = int($root/panel/margin/box/octave.value)
	noise.frequency = $root/panel/margin/box/frequency.value
	noise.fractal_gain = $root/panel/margin/box/gain.value
	noise.fractal_lacunarity = $root/panel/margin/box/lacunarity.value

	values.resize(grid_h * grid_w)
	for y in range(grid_h):
		for x in range(grid_w):
			var n := noise.get_noise_2d(x, y)
			values[y * grid_w + x] = clampf((n + 1.0) * 0.5, 0.0, 1.0)


func _refresh_view() -> void:
	_regenerate()
	if view:
		view.queue_redraw()


func _draw_grid() -> void:
	var visible_text = $root/panel/margin/box/visible_text.button_pressed
	
	if values.size() != grid_w * grid_h:
		return

	var cell_size := minf(view.size.x / grid_w, view.size.y / grid_h)
	var origin := (view.size - Vector2(cell_size * grid_w, cell_size * grid_h)) * 0.5
	var font := ThemeDB.fallback_font
	var font_size := int(clampf(cell_size * 0.3, 8.0, 22.0))

	for y in range(grid_h):
		for x in range(grid_w):
			var v := values[y * grid_w + x]
			var color := gradient.sample(v)
			var rect := Rect2(origin + Vector2(x, y) * cell_size, Vector2(cell_size, cell_size))
			view.draw_rect(rect, color)
			if(visible_text):
				var text_color := Color.BLACK if color.get_luminance() > 0.5 else Color.WHITE
				var pos := rect.position + Vector2(0.0, cell_size * 0.5 + font_size * 0.35)
				view.draw_string(
					font,
					pos,
					"%.2f" % v,
					HORIZONTAL_ALIGNMENT_CENTER,
					cell_size,
					font_size,
					text_color
				)

func _on_gridsize_changed(value: float) -> void:
	var new_size := int(value)
	grid_w = new_size
	grid_h = new_size
	_refresh_view()

func _on_param_changed(_value: float) -> void:
	_refresh_view()


func _on_seed_pressed() -> void:
	noise_seed = randi()
	_refresh_view()
