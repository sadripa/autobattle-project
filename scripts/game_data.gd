extends Node

# Create sample party compositions for testing with multi-layered health
func create_test_player_party() -> Array:
	var party_data = []
	
	# Get characters from CharacterManager
	var guardian_data = CharacterManager.get_character_dictionary("guardian")
	var warrior_data = CharacterManager.get_character_dictionary("warrior")
	var healer_data = CharacterManager.get_character_dictionary("healer")
	var mage_data = CharacterManager.get_character_dictionary("mage")
	
	# Add health layer information for testing
	if guardian_data.size() > 0:
		guardian_data["armor"] = 40  # Guardian has armor
	
	if mage_data.size() > 0:
		mage_data["shield"] = 30  # Mage has shield
	
	if healer_data.size() > 0:
		healer_data["overhealth"] = 20  # Healer has overhealth
	
	# Add to party if found
	if guardian_data.size() > 0:
		party_data.append(guardian_data)
	if warrior_data.size() > 0:
		party_data.append(warrior_data)
	if healer_data.size() > 0:
		party_data.append(healer_data)
	if mage_data.size() > 0:
		party_data.append(mage_data)
	
	return party_data

func create_test_enemy_party() -> Array:
	var party_data = []
	
	# Get characters from CharacterManager
	var orc_data = CharacterManager.get_character_dictionary("orc")
	var goblin_data = CharacterManager.get_character_dictionary("goblin")
	var shaman_data = CharacterManager.get_character_dictionary("shaman")
	
	# Add health layer information for testing
	if orc_data.size() > 0:
		orc_data["armor"] = 20  # Orc has armor
	
	if shaman_data.size() > 0:
		shaman_data["shield"] = 15  # Shaman has shield
	
	# Add to party if found
	if orc_data.size() > 0:
		party_data.append(orc_data)
	if goblin_data.size() > 0:
		party_data.append(goblin_data)
		# Add a second goblin with different health configuration
		var second_goblin = goblin_data.duplicate()
		second_goblin["armor"] = 10
		party_data.append(second_goblin)
	if shaman_data.size() > 0:
		party_data.append(shaman_data)
	
	return party_data

# Create abilities that interact with the health system
func create_health_abilities() -> Dictionary:
	var abilities = {}
	
	# Armor-granting ability
	abilities["iron_skin"] = {
		"id": "iron_skin",
		"name": "Iron Skin",
		"description": "Grants armor to the target",
		"type": "defend",
		"target": "self",
		"effect": "buff",
		"power": 1.0,
		"cooldown": 3,
		"custom_params": {
			"apply_armor": true,
			"armor_amount": 20
		}
	}
	
	# Shield-granting ability
	abilities["arcane_barrier"] = {
		"id": "arcane_barrier",
		"name": "Arcane Barrier",
		"description": "Creates a regenerating shield",
		"type": "defend",
		"target": "single_ally",
		"effect": "buff",
		"power": 1.0,
		"cooldown": 3,
		"custom_params": {
			"apply_shield": true,
			"shield_amount": 30
		}
	}
	
	# Overhealth-granting ability
	abilities["vitality_surge"] = {
		"id": "vitality_surge",
		"name": "Vitality Surge",
		"description": "Grants temporary overhealth",
		"type": "support",
		"target": "all_allies",
		"effect": "heal",
		"power": 0.5,
		"cooldown": 4,
		"custom_params": {
			"apply_overhealth": true,
			"flat_heal": 25
		}
	}
	
	return abilities
