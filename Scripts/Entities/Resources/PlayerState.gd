class_name PlayerState

enum Type {
	IDLE,
	ATTACK,
	DEFEND,
	PASS,
	TAKE_CARDS
}

static func get_state(state: Type) -> String:
	match state:
		Type.IDLE:
			return "Idle"
		Type.ATTACK:
			return "Attack"
		Type.DEFEND:
			return "Defend"
		Type.PASS:
			return "Pass"
		Type.TAKE_CARDS:
			return "Take"
	
	return "NONE" 
