extends VBoxContainer

var current_node: WebNode

func refresh_ui(node: WebNode):
    current_node = node
    
    # 1. 清空舊的 UI
    for child in get_children():
        child.queue_free()
    
    # 2. 取得節點資料配置
    var data_list = node.get_inspector_data()
    
    # 3. 加上標題
    var title = Label.new()
    title.text = "Properties for: " + node.name
    title.add_theme_font_size_override("font_size", 18)
    add_child(title)
    add_child(HSeparator.new())
    
    # 4. 動態生成欄位
    for item in data_list:
        var row = HBoxContainer.new()
        
        # 左邊標籤 (例如 "Html Id")
        var label = Label.new()
        label.text = item["name"].capitalize()
        label.custom_minimum_size.x = 100 # 固定寬度讓排版整齊
        row.add_child(label)
        
        # --- [新增] 判斷資料型態 ---
        
        # 情況 A: 字串 (String) -> 使用 LineEdit
        if item["type"] == TYPE_STRING:
            var input = LineEdit.new()
            input.text = item["value"]
            input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            input.text_changed.connect(func(new_text): 
                if is_instance_valid(current_node):
                    current_node.update_data(item["name"], new_text)
            )
            row.add_child(input)
            
        # 情況 B: 整數/浮點數 (Int/Float) -> 使用 SpinBox
        elif item["type"] == TYPE_INT or item["type"] == TYPE_FLOAT:
            var input = SpinBox.new()
            input.min_value = 0
            input.max_value = 9999 # 設定最大值，避免拉過頭
            input.value = item["value"]
            input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            
            # 連接數值改變訊號
            input.value_changed.connect(func(new_value): 
                if is_instance_valid(current_node):
                    current_node.update_data(item["name"], new_value)
            )
            row.add_child(input)
            
        # 情況 C: 顏色 (Color) -> 使用 ColorPickerButton (順便做起來)
        elif item["type"] == TYPE_COLOR:
            var input = ColorPickerButton.new()
            input.color = item["value"]
            input.custom_minimum_size.x = 50
            input.color_changed.connect(func(new_color):
                if is_instance_valid(current_node):
                    current_node.update_data(item["name"], new_color)
            )
            row.add_child(input)
        
        add_child(row)
