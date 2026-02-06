class_name DelayService

static var _tree: SceneTree = null

static func wait(seconds: float) -> void:
	if _tree == null:
		push_error("DelayService not initialized")
		return

	await _tree.create_timer(seconds).timeout
	
static func set_tree(tree: SceneTree) -> bool:
	_tree = tree
	
	return true	
