class_name WebNode
extends Panel

# --- 訊號定義 ---
signal node_selected(node)
signal property_changed(prop_name: String, new_value) # 雙向綁定用：通知 Inspector 更新

# --- 1. HTML 通用屬性 ---
@export_group("HTML Attributes")
@export var html_tag: String = "div"
@export var html_id: String = ""
@export var html_class: String = ""

# --- 2. 盒模型 (Box Model) ---
# 使用 Setter (set) 來確保數值改變時，畫面會馬上重畫
@export_group("Box Model")
@export var padding: int = 0:
	set(val):
		padding = val
		_update_stylebox() # 更新畫面樣式
		property_changed.emit("padding", val) # 通知 Inspector

@export var margin: int = 0:
	set(val):
		margin = val
		# Margin 不影響 Godot 內部的繪製，但要通知 Inspector
		property_changed.emit("margin", val)

@export var border_width: int = 0:
	set(val):
		border_width = val
		_update_stylebox()
		property_changed.emit("border_width", val)

@export var border_color: Color = Color.BLACK:
	set(val):
		border_color = val
		_update_stylebox()
		property_changed.emit("border_color", val)

@export var corner_radius: int = 0:
	set(val):
		corner_radius = val
		_update_stylebox()
		property_changed.emit("corner_radius", val)

# --- 編輯器內部狀態 ---
var _is_dragging: bool = false
var _drag_offset: Vector2

func _ready():
	# 確保自己能攔截滑鼠事件，讓拖曳正常運作
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 初始化樣式 (如果還沒設定過)
	if not has_theme_stylebox_override("panel"):
		_update_stylebox()

# --- 3. 視覺樣式更新核心 ---
func _update_stylebox():
	var style: StyleBoxFlat
	
	# [修正點] Godot 4 API 檢查與獲取方式
	# 先檢查我們是否已經在這個節點上覆寫過 "panel" 樣式
	if has_theme_stylebox_override("panel"):
		# 如果有，就把它抓出來 (Godot 4 統一用 get_theme_stylebox)
		style = get_theme_stylebox("panel")
	else:
		# 如果沒有，就新建一個
		style = StyleBoxFlat.new()
		style.bg_color = Color(0.9, 0.9, 0.9) # 預設淺灰色背景
		add_theme_stylebox_override("panel", style)
	
	# 以下設定邏輯不變
	
	# 設定 Padding (Content Margin)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	
	# 設定 Border
	style.set_border_width_all(border_width)
	style.border_color = border_color
	
	# 設定圓角
	style.set_corner_radius_all(corner_radius)
	
	queue_redraw()

# --- 4. 拖曳與互動邏輯 ---
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				_drag_offset = global_position - get_global_mouse_position()
				node_selected.emit(self)
				accept_event()
			else:
				_is_dragging = false
				_snap_to_grid(10)

	elif event is InputEventMouseMotion and _is_dragging:
		# 移動位置
		global_position = get_global_mouse_position() + _drag_offset
		
		# [關鍵] 拖曳時，發送訊號通知 Inspector 更新 X, Y 數值
		property_changed.emit("x", position.x)
		property_changed.emit("y", position.y)

# 為了讓 Resize (調整大小) 也能同步，我們覆寫 _notification
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		property_changed.emit("width", size.x)
		property_changed.emit("height", size.y)

func _snap_to_grid(grid_size: int):
	position.x = round(position.x / grid_size) * grid_size
	position.y = round(position.y / grid_size) * grid_size
	# 吸附後也要通知更新
	property_changed.emit("x", position.x)
	property_changed.emit("y", position.y)

# --- 5. 供 Inspector 讀寫的接口 (Super Pattern 基礎) ---
func get_inspector_data() -> Array:
	return [
		{"name": "html_tag", "type": TYPE_STRING, "value": html_tag},
		{"name": "html_id", "type": TYPE_STRING, "value": html_id},
		{"name": "html_class", "type": TYPE_STRING, "value": html_class},
		
		# Layout
		{"name": "x", "type": TYPE_INT, "value": position.x},
		{"name": "y", "type": TYPE_INT, "value": position.y},
		{"name": "width", "type": TYPE_INT, "value": size.x},
		{"name": "height", "type": TYPE_INT, "value": size.y},
		
		# Box Model
		{"name": "padding", "type": TYPE_INT, "value": padding},
		{"name": "margin", "type": TYPE_INT, "value": margin},
		{"name": "border_width", "type": TYPE_INT, "value": border_width},
		{"name": "border_color", "type": TYPE_COLOR, "value": border_color},
		{"name": "corner_radius", "type": TYPE_INT, "value": corner_radius},
		
		# Appearance
		{"name": "bg_color", "type": TYPE_COLOR, "value": self_modulate}
	]

func update_data(property: String, value):
	match property:
		"x": position.x = value
		"y": position.y = value
		"width": size.x = value
		"height": size.y = value
		"bg_color": self_modulate = value
		# 透過 set() 觸發上面定義的 set(val) 函數，自動更新畫面
		_: set(property, value)
