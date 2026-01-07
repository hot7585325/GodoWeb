extends Panel

@onready var world = $World # 確保你有建立這個子節點

var zoom_level: float = 1.0
var zoom_step: float = 0.1
var min_zoom: float = 0.2
var max_zoom: float = 5.0

var is_panning: bool = false
var pan_start_pos: Vector2

func _gui_input(event):
	# --- 1. 平移 (Panning) ---
	# 使用滑鼠中鍵 (Middle) 或 空白鍵+左鍵 來平移
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
			else:
				is_panning = false
	
	elif event is InputEventMouseMotion and is_panning:
		world.position += event.relative

	# --- 2. 縮放 (Zooming) ---
	if event is InputEventMouseButton and event.pressed:
		var old_zoom = zoom_level
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = min(zoom_level + zoom_step, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = max(zoom_level - zoom_step, min_zoom)
			
		# 如果縮放值有變，執行縮放邏輯
		if old_zoom != zoom_level:
			_apply_zoom(event.position, old_zoom)

func _apply_zoom(mouse_pos: Vector2, old_zoom: float):
	# 這是「以滑鼠為中心縮放」的關鍵數學
	# 1. 計算滑鼠在 World 裡的相對位置
	var mouse_in_world = (mouse_pos - world.position) / old_zoom
	
	# 2. 套用新縮放
	world.scale = Vector2(zoom_level, zoom_level)
	
	# 3. 調整 World 位置，讓滑鼠底下的點保持不動
	world.position = mouse_pos - (mouse_in_world * zoom_level)

	# (可選) 在這裡通知 Inspector 更新顯示比例，或重繪格線
