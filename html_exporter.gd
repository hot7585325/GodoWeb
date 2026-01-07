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
	var inner_content = ""
	for child in node.get_children():
		if child is WebNode:
			inner_content += _generate_node_html(child)
			
	var style = "position: absolute; left: %dpx; top: %dpx; width: %dpx; height: %dpx;" % [
		node.position.x, 
		node.position.y, 
		node.size.x, 
		node.size.y
	]
	
	# 加入背景色與旋轉角度(如果有)
	var color = node.self_modulate.to_html()
	style += "background-color: #%s;" % color
	
	# 這裡暫時移除 border 方便預覽，或者你可以保留
	# style += "border: 1px solid #999;" 

	var html = '<div id="%s" class="%s" style="%s">\n%s\n</div>\n' % [
		node.html_id,
		node.html_class,
		style,
		inner_content 
	]
	
	return html
