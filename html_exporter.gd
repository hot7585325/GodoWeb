class_name HTMLExporter
extends RefCounted

# 改名為 export_project，並多接收一個 settings 字典
static func export_project(root_node: Control, settings: Dictionary, save_path: String):
	var html_body = ""
	
	# 遍歷 World 底下的節點 (WebNodes)
	for child in root_node.get_children():
		if child is WebNode:
			html_body += _generate_node_html(child)

	# 處理設定值 (如果沒傳某些設定，就給預設值)
	var page_title = settings.get("title", "My Godot Website")
	var bg_color = settings.get("bg_color", Color.WHITE).to_html()

	# 組合完整 HTML (加入 Head 設定)
	var full_html = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>%s</title>
    <style>
        body { 
            margin: 0; 
            padding: 0; 
            width: 100vw; 
            height: 100vh; 
            position: relative; 
            overflow: hidden; 
            background-color: #%s; /* 這裡應用 BODY 背景色 */
        }
        div { box-sizing: border-box; } 
    </style>
</head>
<body>
    %s
</body>
</html>
	""" % [page_title, bg_color, html_body]
	
	# 寫入檔案
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(full_html)
		print("匯出成功！路徑: ", save_path)
	else:
		printerr("存檔失敗！")

# 這個遞迴函數維持不變
static func _generate_node_html(node: WebNode) -> String:
	# 1. 處理內部內容 (文字 + 子節點)
	var inner_content = ""
	
	# [新增] 檢查是否有文字內容
	# 使用 get() 安全存取，因為不是每個節點都有這些屬性
	if "text_content" in node:
		inner_content += node.text_content
	if "label_text" in node:
		inner_content += node.label_text
	
	# [維持] 遞迴處理子節點 (例如 Div 裡面包 Button)
	for child in node.get_children():
		if child is WebNode:
			inner_content += _generate_node_html(child)
			
	# 2. 處理 CSS 樣式 (維持不變，或加上你的 Margin/Padding 邏輯)
	var style = "position: absolute; left: %dpx; top: %dpx; width: %dpx; height: %dpx;" % [
		node.position.x, node.position.y, node.size.x, node.size.y
	]
	style += "background-color: #%s;" % node.self_modulate.to_html()
	
	# [新增] 處理 HTML 屬性 (例如 disabled)
	var extra_attrs = ""
	if "disabled" in node and node.disabled:
		extra_attrs += " disabled"

	# Box Model CSS (如果之前有加的話請保留)
	if node.padding > 0: style += "padding: %dpx;" % node.padding
	if node.border_width > 0: style += "border: %dpx solid #%s;" % [node.border_width, node.border_color.to_html()]
	if node.corner_radius > 0: style += "border-radius: %dpx;" % node.corner_radius

	# 3. 組合
	var html = '<%s id="%s" class="%s" style="%s"%s>\n%s\n</%s>\n' % [
		node.html_tag, # 自動變成 div, p, 或 button
		node.html_id,
		node.html_class,
		style,
		extra_attrs,   # 插入額外屬性
		inner_content, # 插入文字 + 子節點
		node.html_tag
	]
	
	return html
