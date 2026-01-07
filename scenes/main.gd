extends Control

# --- 節點路徑參照 (請根據你的實際場景結構確認路徑是否正確) ---
# 畫布外框 (負責裁切)
@onready var canvas = $HSplitContainer/HSplitContainer/Canvas
# 世界節點 (負責縮放與移動，所有 WebNode 都會放在這裡)
@onready var world = $HSplitContainer/HSplitContainer/Canvas/World 
# 屬性面板容器
@onready var inspector: VBoxContainer = $HSplitContainer/HSplitContainer/InspectorContainer/InspectorVBox

# 左側場景樹管理器
@onready var scene_tree = $HSplitContainer/VSplitContainer/SceneTreeManager

# 預載 WebNode 場景
var web_node_scene = preload("res://nodes/WebNode.tscn")

# [新增] 專案全域設定 (對應 HTML Head 與 Body 樣式)
var project_settings = {
    "title": "My Godot Website",
    "bg_color": Color(0.95, 0.95, 0.95) # 預設背景色 (淺灰)
}

func _ready():
    # 1. 連接 SceneTree 的訊號
    if scene_tree:
        scene_tree.request_add_node.connect(_on_request_add_node)
        scene_tree.request_select_node.connect(_on_request_select_node_from_tree)
        scene_tree.request_reparent_node.connect(_on_reparent_request)
    
    # 2. 如果你有一個 Export 按鈕，請在這裡連接 (假設按鈕名稱為 ExportButton)
    # 如果你是透過編輯器介面連接訊號，這段可以忽略
    if has_node("ExportButton"):
        $ExportButton.pressed.connect(_on_export_button_pressed)

# --- 功能 1: 新增節點 ---
func _on_request_add_node(type_id: int):
    var new_node = web_node_scene.instantiate()
    
    # 設定不同類型的預設值
    match type_id:
        0: # Div
            new_node.name = "Div"
            new_node.html_tag = "div"
            new_node.html_class = "container"
            new_node.size = Vector2(200, 200) # 給一個初始大小
        1: # Button
            new_node.name = "Button"
            new_node.html_tag = "button"
            new_node.html_class = "btn"
            new_node.size = Vector2(120, 50)
            new_node.self_modulate = Color(0.3, 0.6, 1.0) # 預設藍色
        2: # Image
            new_node.name = "Image"
            new_node.html_tag = "img"
            new_node.size = Vector2(150, 150)
            new_node.self_modulate = Color(0.8, 0.8, 0.8) # 預設灰色

    # [重要修正] 加到 World 而不是 Canvas
    world.add_child(new_node)
    
    # 給一個初始位置 (稍微隨機一點，避免全部疊在一起)
    new_node.position = Vector2(50, 50) + Vector2(randf_range(0, 30), randf_range(0, 30))
    
    # 同步：加到左側場景樹
    scene_tree.add_node_item(new_node)
    
    # 連接選取訊號 (當你在畫布點擊方塊時)
    new_node.node_selected.connect(_on_node_selected_in_canvas)
    
    # 生成後直接選取它
    _on_node_selected_in_canvas(new_node)

# --- 功能 2: 選取同步 (雙向綁定) ---

# 情況 A: 使用者在畫布 (Canvas) 點擊方塊
func _on_node_selected_in_canvas(node):
    inspector.refresh_ui(node)           # 更新右側屬性欄
    scene_tree.select_item_by_node(node) # 更新左側場景樹的反白

# 情況 B: 使用者在場景樹 (Tree) 點擊項目
func _on_request_select_node_from_tree(node):
    inspector.refresh_ui(node)           # 更新右側屬性欄
    # 可以在這裡加一些視覺回饋 (例如顯示黃色框框 Gizmo)

# --- 功能 3: 父子關係拖曳 (Reparenting) ---
func _on_reparent_request(child_node: WebNode, new_parent_node: WebNode):
    # 1. 記錄當前的全域位置 (這是視覺不亂跳的關鍵)
    var saved_global_pos = child_node.global_position
    
    # 2. 脫離舊爸爸
    child_node.get_parent().remove_child(child_node)
    
    # 3. 加入新爸爸
    if new_parent_node:
        new_parent_node.add_child(child_node)
    else:
        # 如果 new_parent_node 是 null，代表使用者把它拖到了最上層
        # 這時候它的新爸爸應該是 World
        world.add_child(child_node)
        
    # 4. 還原全域位置
    child_node.global_position = saved_global_pos
    
    # 5. 通知 UI 樹狀圖更新結構 (移動 Item)
    scene_tree.move_item_in_tree(child_node, new_parent_node)

# --- 功能 4: 匯出 HTML ---
func _on_export_button_pressed():
    # 為了測試方便，直接存到專案根目錄
    # 實際產品建議使用 FileDialog 讓使用者選擇存檔位置
    var path = "res://export.html"
    
    # [重要修正] 呼叫新的 export_project 方法
    # 傳入 world (因為所有節點都在這)，以及 project_settings
    HTMLExporter.export_project(world, project_settings, path)
    
    # 自動打開瀏覽器預覽
    OS.shell_open(ProjectSettings.globalize_path(path))
