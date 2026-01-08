extends VBoxContainer

var current_node: WebNode

func refresh_ui(node: WebNode):
    # --- 除錯代碼開始 ---
    print("---------------------------------")
    print("Inspector 正在處理節點名稱：", node.name)
    if node.get_script():
        print("此節點掛載的腳本路徑：", node.get_script().resource_path)
    else:
        print("！！嚴重錯誤！！此節點沒有掛載任何腳本！")
    # --- 除錯代碼結束 ---
    
    # 如果是同一個節點，且該節點還活著，就先斷開舊的訊號連接 (避免重複連接)
    if is_instance_valid(current_node) and current_node.property_changed.is_connected(_on_node_property_changed):
        current_node.property_changed.disconnect(_on_node_property_changed)
    
    current_node = node
    
    # 1. 監聽節點的變更訊號 (實現雙向綁定)
    if not node.property_changed.is_connected(_on_node_property_changed):
        node.property_changed.connect(_on_node_property_changed)
    
    # 2. 清空舊 UI
    for child in get_children():
        child.queue_free()
    
    # 3. 標題
    var title = Label.new()
    title.text = node.name + " Properties"
    title.add_theme_font_size_override("font_size", 16)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(title)
    add_child(HSeparator.new())
    
    # 4. 取得資料並生成欄位
    var data_list = node.get_inspector_data()
    
    for item in data_list:
        var row = HBoxContainer.new()
        
        # 左邊標籤
        var label = Label.new()
        label.text = item["name"].capitalize()
        label.custom_minimum_size.x = 110 # 固定寬度對齊
        row.add_child(label)
        
        var input_control: Control
        
        # --- 根據類型生成對應輸入框 ---
        
        # 情況 A: 字串 (LineEdit)
        if item["type"] == TYPE_STRING:
            var input = LineEdit.new()
            input.text = item["value"]
            input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            input.text_changed.connect(func(new_text): 
                if is_instance_valid(current_node):
                    current_node.update_data(item["name"], new_text)
            )
            input_control = input
            
        # 情況 B: 整數/浮點數 (SpinBox)
        elif item["type"] == TYPE_INT or item["type"] == TYPE_FLOAT:
            var input = SpinBox.new()
            input.min_value = -9999 # 允許負座標
            input.max_value = 9999
            input.value = item["value"]
            input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            
            # UI 改動 -> 通知 Node
            input.value_changed.connect(func(new_value): 
                if is_instance_valid(current_node):
                    current_node.update_data(item["name"], new_value)
            )
            input_control = input
            
        # 情況 C: 顏色 (ColorPicker)
        elif item["type"] == TYPE_COLOR:
            var input = ColorPickerButton.new()
            input.color = item["value"]
            input.custom_minimum_size.x = 50
            input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            
            input.color_changed.connect(func(new_color):
                if is_instance_valid(current_node):
                    current_node.update_data(item["name"], new_color)
            )
            input_control = input
        
        if input_control:
            # 將欄位名稱綁定在 Meta 裡，方便稍後反向更新時尋找
            input_control.set_meta("property_name", item["name"])
            row.add_child(input_control)
            
        add_child(row)

# --- 反向更新邏輯 (Node -> UI) ---
# 當使用者在畫布上拖曳節點時，這裡會被呼叫
func _on_node_property_changed(prop_name: String, new_value):
    # 遍歷所有的輸入框，找到負責顯示這個屬性的那個框
    for row in get_children():
        if not row is HBoxContainer: continue
        
        # 輸入框通常是 row 的第二個子節點 (第一個是 Label)
        if row.get_child_count() < 2: continue
        var input = row.get_child(1)
        
        # 檢查 Meta 標籤是否匹配
        if input.has_meta("property_name") and input.get_meta("property_name") == prop_name:
            
            # 根據類型更新數值 (使用 set_value_no_signal 避免無窮迴圈)
            if input is SpinBox:
                if input.value != new_value:
                    input.set_value_no_signal(new_value)
                    
            elif input is LineEdit:
                if input.text != str(new_value):
                    input.text = str(new_value)
                    # LineEdit 沒有 set_text_no_signal，但通常不會造成問題，
                    # 因為我們在 text_changed 裡有判斷值是否改變
                    
            elif input is ColorPickerButton:
                if input.color != new_value:
                    input.color = new_value
            
            break # 找到後就跳出迴圈
