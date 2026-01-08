class_name WebButton
extends WebNode

@export_group("Button Settings")
@export var label_text: String = "Click Me":
	set(val):
		label_text = val
		if btn_internal: btn_internal.text = val
		property_changed.emit("label_text", val)

@export var disabled: bool = false:
	set(val):
		disabled = val
		if btn_internal: btn_internal.disabled = val
		property_changed.emit("disabled", val)

@onready var btn_internal = $Button

func _ready():
	super._ready()
	html_tag = "button" # 設定 HTML 標籤
	
	# 初始化
	label_text = label_text
	disabled = disabled

func get_inspector_data() -> Array:
	var data = super.get_inspector_data()
	data.append({"name": "label_text", "type": TYPE_STRING, "value": label_text})
	# Bool 類型 Inspector 會自動變成 Checkbox
	data.append({"name": "disabled", "type": TYPE_BOOL, "value": disabled})
	return data

func update_data(property: String, value):
	match property:
		"label_text": label_text = value
		"disabled": disabled = value
		_: super.update_data(property, value)
