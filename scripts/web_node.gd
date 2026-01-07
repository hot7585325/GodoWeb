class_name WebNode
extends Panel

# --- 訊號 ---
signal node_selected(node)

# --- [關鍵修復] 這裡必須宣告變數，下面的 get_inspector_data 才讀得到 ---
@export_group("HTML Attributes")
@export var html_tag: String = "div"
@export var html_id: String = ""
@export var html_class: String = ""

# --- 編輯器狀態 ---
var _is_dragging: bool = false
var _drag_offset: Vector2
var _parent_control: Control

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP # 設為 STOP 以便正確處理父子拖曳
	_parent_control = get_parent()
	
	# 預設樣式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(randf(), randf(), randf(), 0.5)
	style.set_border_width_all(2) # 簡寫設定邊框
	style.border_color = Color.WHITE
	add_theme_stylebox_override("panel", style)

# --- 核心互動邏輯 ---
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				_drag_offset = global_position - get_global_mouse_position()
				node_selected.emit(self)
				move_to_front()
				accept_event()
			else:
				_is_dragging = false
				_snap_to_grid(10)

	elif event is InputEventMouseMotion and _is_dragging:
		global_position = get_global_mouse_position() + _drag_offset

func _snap_to_grid(grid_size: int):
	position.x = round(position.x / grid_size) * grid_size
	position.y = round(position.y / grid_size) * grid_size

# --- 供外部讀取的 API (Inspector 用) ---
func get_inspector_data() -> Array:
	return [
		# 基本屬性 (現在這裡讀得到上面的變數了)
		{"name": "html_tag", "type": TYPE_STRING, "value": html_tag},
		{"name": "html_id", "type": TYPE_STRING, "value": html_id},
		{"name": "html_class", "type": TYPE_STRING, "value": html_class},
		
		# 尺寸屬性
		{"name": "width", "type": TYPE_INT, "value": size.x},
		{"name": "height", "type": TYPE_INT, "value": size.y},
		
		# 背景顏色
		{"name": "bg_color", "type": TYPE_COLOR, "value": self_modulate}
	]

# --- 供外部修改資料的 API ---
func update_data(property: String, value):
	match property:
		"width":
			size.x = value
		"height":
			size.y = value
		"bg_color":
			self_modulate = value
		_:
			# 使用 set() 來動態修改最上面的變數
			set(property, value)
