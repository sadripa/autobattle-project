class_name HealthType
extends Resource

# Enum for health type identification
enum Type {
	REGULAR,
	ARMOR,
	SHIELD,
	OVERHEALTH
}

# Properties
@export var type: Type = Type.REGULAR
@export var color: Color = Color.RED
@export var name: String = "Regular Health"
@export var description: String = "Basic health with no special effects"

# Behavior parameters
@export var damage_reduction_percent: float = 0.0  # For armor
@export var regen_per_turn: int = 0  # For shields
@export var decay_per_turn: int = 0  # For overhealth
@export var max_amount: int = 100  # Maximum amount for this health type
@export var decay_delay: int = 0  # Turns before decay starts (for overhealth)

# Debug mode
var debug_mode = true

static func load_from_resources(type_name: String) -> HealthType:
	var path = "res://resources/health_types/" + type_name + ".tres"
	if ResourceLoader.exists(path):
		return load(path)
	else:
		# Fallback to default
		match type_name:
			"regular_health": return create_regular()
			"armor": return create_armor()
			"shield": return create_shield()
			"overhealth": return create_overhealth()
			_: return create_regular()

# Static factory methods to create predefined health types
static func create_regular(max_amount: int = 100) -> HealthType:
	var health_type = HealthType.new()
	health_type.type = Type.REGULAR
	health_type.color = Color(0.8, 0.2, 0.2)  # Red
	health_type.name = "Regular Health"
	health_type.description = "Basic health with no special effects"
	health_type.max_amount = max_amount
	
	return health_type

static func create_armor(max_amount: int = 100, reduction: float = 0.5) -> HealthType:
	var health_type = HealthType.new()
	health_type.type = Type.ARMOR
	health_type.color = Color(1.0, 0.8, 0.0)  # Yellow
	health_type.name = "Armor"
	health_type.description = "Reduces incoming damage"
	health_type.damage_reduction_percent = reduction
	health_type.max_amount = max_amount
	
	return health_type

static func create_shield(max_amount: int = 100, regen: int = 5) -> HealthType:
	var health_type = HealthType.new()
	health_type.type = Type.SHIELD
	health_type.color = Color(0.2, 0.6, 1.0)  # Blue
	health_type.name = "Shield"
	health_type.description = "Regenerates over time"
	health_type.regen_per_turn = regen
	health_type.max_amount = max_amount
	
	return health_type

static func create_overhealth(max_amount: int = 100, decay: int = 10, delay: int = 2) -> HealthType:
	var health_type = HealthType.new()
	health_type.type = Type.OVERHEALTH
	health_type.color = Color(0.4, 1.0, 0.4)  # Green
	health_type.name = "Overhealth"
	health_type.description = "Temporary health that decays over time"
	health_type.decay_per_turn = decay
	health_type.decay_delay = delay
	health_type.max_amount = max_amount
	
	return health_type

func process_damage(damage_amount: int) -> int:
	"""
	Process incoming damage according to health type rules
	Returns the modified damage amount
	"""
	
	var modified_damage = damage_amount
	
	match type:
		Type.ARMOR:
			# Armor reduces damage by percentage
			modified_damage = int(modified_damage * (1.0 - damage_reduction_percent))
			# Ensure at least 1 damage is dealt unless damage was already 0
			if damage_amount > 0:
				modified_damage = max(1, modified_damage)
		# Other types don't modify damage
			
	return modified_damage

func process_turn() -> int:
	"""
	Process turn-based effects like regeneration or decay
	Returns the amount to change (positive for regen, negative for decay)
	"""
	
	match type:
		Type.SHIELD:
			if regen_per_turn > 0:
				return regen_per_turn
		Type.OVERHEALTH:
			if decay_delay > 0:
				# Still in delay period
				decay_delay -= 1
				return 0
			else:
				# Start decaying
				if decay_per_turn > 0:
					return -decay_per_turn
	
	# Default case - no change
	return 0
