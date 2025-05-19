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
@export_enum("Single Enemy", "All Enemies", "Single Ally", "All Allies", "Lowest Ally", "Self", "Position Based") var target_type: int = GameEnums.TargetType.SINGLE_ENEMY
@export_enum("Damage", "Heal", "Buff", "Debuff", "Special") var effect_type: int = GameEnums.EffectType.DAMAGE

# Parameters
@export var power: float = 1.0
@export var cooldown: int = 0

# Visual properties
@export_file("*.png") var icon_path: String = ""
@export var effect_animation: String = ""

# Custom parameters for special abilities
@export var custom_params: Dictionary = {}

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
		"target": GameEnums.target_type_to_string(target_type),
		"effect": GameEnums.effect_type_to_string(effect_type),
		"power": power,
		"cooldown": cooldown
	}
	
	# Add custom parameters
	if custom_params.size() > 0:
		data["custom_params"] = custom_params.duplicate()
	
	return data
