class_name SceneTreeManager
extends Tree

# 新增訊號：請求重新設定父子關係
# dragged_node: 被拖曳的節點 (WebNode)
# new_parent_node: 新的爸爸 (WebNode, 如果是根目錄則為 null)
signal request_reparent_node(dragged_node: WebNode, new_parent_node: WebNode)
signal request_select_node(node: WebNode)
signal request_add_node(type_id: int)

var popup: PopupMenu
var root_item: TreeItem
var node_to_item_map = {} 

func _ready():
	# 1. 初始化設定
	root_item = create_item()
	hide_root = true
	select_mode = SELECT_SINGLE
	
	# [關鍵] 啟用拖放模式
	# DROP_MODE_ON_ITEM: 允許拖到項目上 (變成子項目)
	# DROP_MODE_INBETWEEN: 允許拖到項目之間 (排序用，這邊我們先專注做父子關係)
	drop_mode_flags = DROP_MODE_ON_ITEM | DROP_MODE_INBETWEEN
	
	# 2. 初始化右鍵選單 (維持原樣)
	popup = PopupMenu.new()
	popup.add_item("Add Div (Container)", 0)
	popup.add_item("Add Button", 1)
	popup.add_item("Add Image", 2)
	popup.id_pressed.connect(_on_popup_item_pressed)
	add_child(popup)
	
	item_selected.connect(_on_tree_item_selected)

# --- 拖放邏輯核心 (Drag & Drop) ---

# 1. 當使用者開始拖曳時
func _get_drag_data(at_position):
	var item = get_item_at_position(at_position)
	if not item: return null
	
	var node = item.get_metadata(0)
	
	# 建立預覽圖 (跟著滑鼠跑的小圖示)
	var preview = Label.new()
	preview.text = item.get_text(0)
	set_drag_preview(preview)
	
	# 回傳資料：這包資料會傳給 _drop_data
	return { "item": item, "node": node }

# 2. 檢查是否可以放下
func _can_drop_data(at_position, data):
	# 檢查資料格式是否正確
	return data is Dictionary and data.has("node")

# 3. 當使用者放開滑鼠時
func _drop_data(at_position, data):
	var target_item = get_item_at_position(at_position)
	var dragged_node = data["node"]
	
	# 取得放下區域：0 = 在項目上, -1 = 上半部, 1 = 下半部
	var section = get_drop_section_at_position(at_position)
	
	var new_parent_node = null
	
	if target_item:
		if section == 0:
			# 情況 A: 拖到某個項目「上面」 -> 變成該項目的子節點
			var target_node = target_item.get_metadata(0)
			
			# 防止自己拖到自己裡面，或拖到自己的子孫裡面 (會無窮迴圈)
			if target_node == dragged_node: return
			if dragged_node.is_ancestor_of(target_node): return 
			
			new_parent_node = target_node
		else:
			# 情況 B: 拖到項目縫隙 -> 變成該項目的兄弟 (目前簡化邏輯：視同移到該項目的父層)
			# 為了簡化，這裡暫時將「縫隙」視為「移到同一層級」
			# 若要精確排序需要更複雜的 reorder 邏輯
			var target_node = target_item.get_metadata(0)
			new_parent_node = target_node.get_parent() # 取得目標的爸爸
			# 如果目標的爸爸不是 WebNode (例如是 Canvas)，則 new_parent_node 視為 null (根目錄)
			if not (new_parent_node is WebNode):
				new_parent_node = null
	else:
		# 情況 C: 拖到空白處 -> 變成最上層 (Canvas 的子節點)
		new_parent_node = null
		
	# 發出訊號給 Main 去處理真實邏輯
	request_reparent_node.emit(dragged_node, new_parent_node)

# --- 原有功能 (維持不變) ---
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		popup.position = get_screen_position() + get_local_mouse_position()
		popup.popup()

func _on_popup_item_pressed(id):
	request_add_node.emit(id)

func _on_tree_item_selected():
	var selected_item = get_selected()
	if selected_item:
		var node = selected_item.get_metadata(0)
		if is_instance_valid(node):
			request_select_node.emit(node)

func add_node_item(node: WebNode):
	# 改良：檢查 node 的 parent 是否已有對應的 TreeItem
	var parent_item = root_item
	var parent_node = node.get_parent()
	
	if parent_node is WebNode and parent_node in node_to_item_map:
		parent_item = node_to_item_map[parent_node]
		
	var item = create_item(parent_item)
	item.set_text(0, node.name)
	item.set_metadata(0, node)
	node_to_item_map[node] = item

func select_item_by_node(node: WebNode):
	if node in node_to_item_map:
		var item = node_to_item_map[node]
		set_selected(item, 0)
		ensure_cursor_is_visible()

# [新增] 用來更新樹狀圖結構的輔助函數
func move_item_in_tree(node: WebNode, new_parent_node: WebNode):
	if not node in node_to_item_map: return
	
	var item = node_to_item_map[node]
	var new_parent_item = root_item
	
	if new_parent_node and new_parent_node in node_to_item_map:
		new_parent_item = node_to_item_map[new_parent_node]
		
	# TreeItem 無法直接換爸爸，必須「剪下 -> 貼上」
	# 但為了保持原本的設定比較麻煩，Godot 4 提供了 move_after
	# 這裡我們用最簡單暴力的方法：刪除舊 Item，重建新 Item
	# (注意：這會導致子節點顯示暫時消失，需要遞迴重建，為了 MVP 先做簡單版)
	
	item.get_parent().remove_child(item) # 從樹上移除
	new_parent_item.add_child(item) # 加到新爸爸底下
