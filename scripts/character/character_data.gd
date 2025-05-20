@tool
class_name CharacterData
extends Resource

# Basic properties
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export_enum("Blade", "Banner", "Echo", "Fracture", "Bond") var role: int = GameEnums.Role.BLADE
@export_enum("Common Adventurer", "Recurring Resource", "Lost Seal", "Silent Core", "Living Error") var tier: int = GameEnums.Tier.COMMON_ADVENTURER

# Base stats
@export var hp: int = 100
@export var attack: int = 10
@export var defense: int = 10
@export var speed: int = 5

# Health layers - new properties for multi-layered health
@export var armor: int = 0
@export var shield: int = 0
@export var overhealth: int = 0

# Abilities
@export var basic_ability: AbilityData
@export var passive_ability: AbilityData
@export var active_ability: AbilityData

# Optional additional properties
@export var tags: Array[String] = []
@export var custom_properties: Dictionary = {}

# Visual properties
@export var sprite_path: String = ""
@export var portrait_path: String = ""

func get_abilities_dict() -> Dictionary:
	"""
	Convert the abilities to a dictionary format for use in Character class
	"""
	var abilities_dict = {}
	
	if basic_ability:
		abilities_dict["basic"] = basic_ability.to_dictionary()
	
	if passive_ability:
		abilities_dict["passive"] = passive_ability.to_dictionary()
	
	if active_ability:
		abilities_dict["active"] = active_ability.to_dictionary()
	
	return abilities_dict

func to_dictionary() -> Dictionary:
	"""
	Convert this resource to a dictionary format
	(For backward compatibility with existing code)
	"""
	var data = {
		"id": id,
		"name": name,
		"role": GameEnums.role_to_string(role),
		"tier": GameEnums.tier_to_string(tier),
		"hp": hp,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"abilities": get_abilities_dict(),
		"sprite_path": sprite_path,
		"portrait_path": portrait_path,
		"description": description
	}
	
	# Add health layer information
	if armor > 0:
		data["armor"] = armor
	if shield > 0:
		data["shield"] = shield
	if overhealth > 0:
		data["overhealth"] = overhealth
	
	# Add any custom properties
	for key in custom_properties:
		data[key] = custom_properties[key]
	
	return data
