extends Node

# Create sample party compositions for testing
func create_test_player_party() -> Array:
	var party_data = []
	
	# Get characters from CharacterManager
	var guardian_data = CharacterManager.get_character_dictionary("guardian")
	var warrior_data = CharacterManager.get_character_dictionary("warrior")
	var healer_data = CharacterManager.get_character_dictionary("healer")
	var mage_data = CharacterManager.get_character_dictionary("mage")
	
	# Add to party if found
	if warrior_data.size() > 0:
		party_data.append(warrior_data)
	if guardian_data.size() > 0:
		party_data.append(guardian_data)
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
	
	# Add to party if found
	if orc_data.size() > 0:
		party_data.append(orc_data)
	if goblin_data.size() > 0:
		party_data.append(goblin_data)
		party_data.append(goblin_data.duplicate()) # Add a second goblin
	if shaman_data.size() > 0:
		party_data.append(shaman_data)
	
	return party_data
