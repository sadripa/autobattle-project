@tool
class_name AbilityData
extends Resource

# Basic properties
@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""

# Enum dropdown properties with explicit values
@export_enum("Basic", "Passive", "Active") var ability_type: int = GameEnums.AbilityType.BASIC
@export_enum("Attack", "Defend", "Support", "Utility") var action_type: int = GameEnums.ActionType.ATTACK
@export_enum("Damage", "Heal", "Buff", "Debuff", "Special") var effect_type: int = GameEnums.EffectType.DAMAGE

# TARGETING SYSTEM
@export_group("Targeting")
@export_enum("None", "Allies", "Enemies", "Allies and Enemies") var target_side: int = GameEnums.TargetSide.ENEMIES
@export_enum("None", "Self", "Close", "Mid", "Long", "Random") var target_range: int = GameEnums.TargetRange.CLOSE
@export_enum("None", "Before", "After") var target_section: int = GameEnums.TargetSection.NONE
@export_enum("Single", "Double", "Triple", "Adjacent", "All") var target_size: int = GameEnums.TargetSize.SINGLE

@export_group("Advanced Targeting")
@export_enum("None", "Lowest HP", "Highest HP", "Has Debuff", "Missing Health", "Has Role", "Custom") var target_filter: int = GameEnums.TargetFilter.NONE
@export_enum("None", "Protect Valuable", "Finish Wounded", "Break Formation") var target_priority: int = GameEnums.TargetPriority.NONE
@export_enum("Fail", "Random Valid", "Self", "Wait") var fallback: int = GameEnums.Fallback.FAIL
@export_enum("None", "Pierce", "Chain", "Splash") var penetration: int = GameEnums.Penetration.NONE

# Parameters
@export_group("Parameters")
@export var power: float = 1.0
@export var cooldown: int = 0

# Visual properties
@export_group("Visual")
@export_file("*.png") var icon_path: String = ""
@export var effect_animation: String = ""

# Custom parameters for special abilities
@export_group("Custom")
@export var custom_params: Dictionary = {}

func _init():
	# Validate targeting combinations on initialization
	validate_targeting()

func validate_targeting() -> bool:
	"""
	Validate that targeting combination is valid
	Returns true if valid, false otherwise
	"""
	# System breaking cases
	if target_range == GameEnums.TargetRange.SELF and target_side != GameEnums.TargetSide.ALLIES:
		push_error("Target Range is Self but Target Side is not Allies")
		return false
	
	if target_range == GameEnums.TargetRange.SELF and target_size in [GameEnums.TargetSize.DOUBLE, GameEnums.TargetSize.TRIPLE, GameEnums.TargetSize.ALL]:
		push_error("Target Range is Self but Target Size is Double, Triple, or All")
		return false
	
	if target_section != GameEnums.TargetSection.NONE and target_size == GameEnums.TargetSize.ALL:
		push_error("Target Section is not None but Target Size is All")
		return false
	
	return true

func to_dictionary() -> Dictionary:
	"""
	Convert this resource to a dictionary format
	(For backward compatibility with existing code)
	"""
	var data = {
		"id": id,
		"name": name,
		"description": description,
		"type": GameEnums.action_type_to_string(action_type),
		"effect": GameEnums.effect_type_to_string(effect_type),
		"power": power,
		"cooldown": cooldown,
		# Targeting system
		"target_side": target_side,
		"target_range": target_range,
		"target_section": target_section,
		"target_size": target_size,
		"target_filter": target_filter,
		"target_priority": target_priority,
		"fallback": fallback,
		"penetration": penetration
	}
	
	# Add custom parameters
	if custom_params.size() > 0:
		data["custom_params"] = custom_params.duplicate()
	
	return data
