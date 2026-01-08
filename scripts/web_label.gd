class_name WebLabel
extends WebNode  # 繼承我們寫好的通用基底

# --- 文字專屬屬性 ---
@export_group("Text Settings")
@export var text_content: String = "Hello World":
	set(val):
		text_content = val
		if label_internal: label_internal.text = val
		property_changed.emit("text_content", val) # 通知 Inspector

@export var font_size: int = 16:
	set(val):
		font_size = val
		if label_internal: 
			label_internal.add_theme_font_size_override("font_size", val)
		property_changed.emit("font_size", val)

@export var font_color: Color = Color.BLACK:
	set(val):
		font_color = val
		if label_internal:
			label_internal.add_theme_color_override("font_color", val)
		property_changed.emit("font_color", val)

@export_enum("Left", "Center", "Right") var align: int = 0:
	set(val):
		align = val
		if label_internal:
			match val:
				0: label_internal.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				1: label_internal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				2: label_internal.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		property_changed.emit("align", val)

# 取得內部的 Label 節點
@onready var label_internal = $Label

func _ready():
	super._ready() # 記得呼叫爸爸的 _ready
	
	# 初始化：把變數的值套用到 Label 上
	html_tag = "p" # 預設標籤改為 p
	text_content = text_content # 觸發 setter
	font_size = font_size
	font_color = font_color
	align = align

# --- Inspector 資料疊加 (Super Pattern) ---
func get_inspector_data() -> Array:
	# 1. 先拿爸爸 (WebNode) 的所有資料 (位置、尺寸、邊框...)
	var data = super.get_inspector_data()
	
	# 2. 加上自己的資料
	data.append({"name": "text_content", "type": TYPE_STRING, "value": text_content})
	data.append({"name": "font_size", "type": TYPE_INT, "value": font_size})
	data.append({"name": "font_color", "type": TYPE_COLOR, "value": font_color})
	# 對齊比較特別，它是 Enum，但在 Inspector 暫時先用 Int (0,1,2) 控制
	data.append({"name": "align", "type": TYPE_INT, "value": align}) 
	
	return data

# --- 資料更新 ---
func update_data(property: String, value):
	# 處理自己獨有的屬性
	match property:
		"text_content": text_content = value
		"font_size": font_size = value
		"font_color": font_color = value
		"align": align = value
		_:
			# 如果不是自己的，就丟給爸爸處理 (x, y, padding...)
			super.update_data(property, value)
