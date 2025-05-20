class_name HealthLayer
extends Resource

# References
var health_type: HealthType
var current_amount: int = 0
var max_amount: int = 0
var decay_timer: int = 0  # For tracking overhealth decay delay

# Debug mode
var debug_mode = true

func _init(type: HealthType = null, amount: int = 0):
	if type:
		health_type = type
		max_amount = type.max_amount
		current_amount = min(amount, max_amount)
		
		# Initialize decay timer for overhealth
		if type.type == HealthType.Type.OVERHEALTH:
			decay_timer = type.decay_delay

func is_empty() -> bool:
	return current_amount <= 0

func is_full() -> bool:
	return current_amount >= max_amount

func get_percentage() -> float:
	if max_amount <= 0:
		return 0.0
	return float(current_amount) / float(max_amount)

func apply_damage(damage_amount: int) -> int:
	"""
	Apply damage to this layer
	Returns the remaining damage that wasn't absorbed by this layer
	"""
	
	var modified_damage = health_type.process_damage(damage_amount)
	
	var before_health = current_amount
	
	if modified_damage >= current_amount:
		var overflow = modified_damage - current_amount
		current_amount = 0
		
		return overflow
	else:
		current_amount -= modified_damage
		
		return 0

func apply_healing(heal_amount: int) -> int:
	"""
	Apply healing to this layer
	Returns the overflow healing that wasn't used by this layer
	"""
	
	var before_health = current_amount
	var space_left = max_amount - current_amount
	
	if heal_amount > space_left:
		current_amount = max_amount
		var overflow = heal_amount - space_left
		return overflow
	else:
		current_amount += heal_amount
		return 0

func process_turn() -> void:
	"""
	Process turn-based effects like regeneration or decay
	"""
	var before_health = current_amount
	var change = health_type.process_turn()
	
	if change > 0:
		# Regeneration
		var old_amount = current_amount
		current_amount = min(current_amount + change, max_amount)
		
	elif change < 0:
		# Decay
		var old_amount = current_amount
		current_amount = max(0, current_amount + change)  # change is negative
