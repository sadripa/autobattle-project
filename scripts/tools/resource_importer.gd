@tool
extends EditorScript

# Preload the GameEnums script to access its functions directly
const GameEnumsClass = preload("res://scripts/game_enums.gd")
var GameEnums = GameEnumsClass.new()

# Resource paths
const CHARACTER_RESOURCE_PATH = "res://resources/characters/"
const ABILITY_RESOURCE_PATH = "res://resources/abilities/"

# CSV file paths
const CHARACTER_CSV_PATH = "res://data/characters.csv"
const ABILITY_CSV_PATH = "res://data/abilities.csv"

func _run():
	print("Starting CSV import...")
	
	# Check if CharacterData and AbilityData classes are registered
	print("Checking class registration:")
	var test_character = CharacterData.new()
	var test_ability = AbilityData.new()
	print("  CharacterData class check: " + ("OK" if test_character else "FAILED"))
	print("  AbilityData class check: " + ("OK" if test_ability else "FAILED"))
	
	# Import abilities first (since characters reference them)
	import_abilities_from_csv()
	
	# Then import characters
	import_characters_from_csv()
	
	print("CSV import completed!")

func import_abilities_from_csv():
	"""
	Import abilities from CSV and create/update ability resources
	"""
	print("Importing abilities...")
	var csv_content = FileAccess.get_file_as_string(ABILITY_CSV_PATH)
	if csv_content.is_empty():
		print("Error: Failed to read abilities CSV file")
		return
	
	var rows = csv_content.split("\n")
	if rows.size() <= 1:
		print("No ability data found in CSV")
		return
	
	# Extract header row and convert to lowercase for case-insensitive matching
	var headers = rows[0].split(",")
	for i in range(headers.size()):
		headers[i] = headers[i].strip_edges().to_lower()
	
	# Process each row (skipping header)
	for i in range(1, rows.size()):
		var row = rows[i].split(",")
		if row.size() < headers.size():
			continue  # Skip incomplete rows
		
		# Create a dictionary from this row
		var ability_data = {}
		for j in range(headers.size()):
			var value = row[j].strip_edges()
			ability_data[headers[j]] = value
		
		# Skip rows without an ID
		if !ability_data.has("id") or ability_data.id.is_empty():
			continue
		
		# Create or update the ability resource
		create_or_update_ability(ability_data)

func create_or_update_ability(data: Dictionary):
	"""
	Create a new ability resource or update an existing one
	"""
	var ability_id = data.id
	
	# Set up file path (respect folder structure if specified)
	var file_path = ABILITY_RESOURCE_PATH
	if data.has("folder") and !data.folder.is_empty():
		file_path += data.folder + "/"
		# Create directory if it doesn't exist
		if !DirAccess.dir_exists_absolute(file_path):
			var dir = DirAccess.open(ABILITY_RESOURCE_PATH)
			dir.make_dir_recursive(data.folder)
	
	file_path += ability_id + ".tres"
	
	# Check if resource already exists
	var ability: AbilityData
	if ResourceLoader.exists(file_path):
		ability = load(file_path) as AbilityData
		print("Updating existing ability: " + ability_id)
	else:
		ability = AbilityData.new()
		print("Creating new ability: " + ability_id)
	
	# Update ability properties
	ability.id = ability_id
	
	# Basic properties
	if data.has("name"):
		ability.name = data.name
	if data.has("description"):
		ability.description = data.description
	
	# Enum properties
	if data.has("ability_type"):
		var ability_type_str = data.ability_type.to_lower()
		match ability_type_str:
			"basic": ability.ability_type = GameEnums.AbilityType.BASIC
			"passive": ability.ability_type = GameEnums.AbilityType.PASSIVE
			"active": ability.ability_type = GameEnums.AbilityType.ACTIVE
	
	if data.has("action_type"):
		var action_type_str = data.action_type.to_lower()
		ability.action_type = GameEnums.string_to_action_type(action_type_str)
	
	if data.has("effect_type"):
		var effect_type_str = data.effect_type.to_lower()
		ability.effect_type = GameEnums.string_to_effect_type(effect_type_str)
	
	# NEW: Targeting properties
	if data.has("target_side"):
		ability.target_side = GameEnums.string_to_target_side(data.target_side)
	
	if data.has("target_range"):
		ability.target_range = GameEnums.string_to_target_range(data.target_range)
	
	if data.has("target_section"):
		ability.target_section = GameEnums.string_to_target_section(data.target_section)
	
	if data.has("target_size"):
		ability.target_size = GameEnums.string_to_target_size(data.target_size)
	
	if data.has("target_filter"):
		ability.target_filter = GameEnums.string_to_target_filter(data.target_filter)
	
	if data.has("target_priority"):
		ability.target_priority = GameEnums.string_to_target_priority(data.target_priority)
	
	if data.has("fallback"):
		ability.fallback = GameEnums.string_to_fallback(data.fallback)
	
	if data.has("penetration"):
		ability.penetration = GameEnums.string_to_penetration(data.penetration)
	
	# Numeric properties
	if data.has("power"):
		ability.power = float(data.power)
	if data.has("cooldown"):
		ability.cooldown = int(data.cooldown)
	
	# Visual properties
	if data.has("icon_path"):
		ability.icon_path = data.icon_path
	if data.has("effect_animation"):
		ability.effect_animation = data.effect_animation
	
	# Custom parameters - need special handling
	# These would be in columns like "custom_defense_boost", "custom_duration", etc.
	var custom_params = {}
	for key in data:
		if key.begins_with("custom_"):
			var param_name = key.substr(7)  # Remove "custom_" prefix
			
			# Try to convert to appropriate type
			var value = data[key]
			if value.to_lower() == "true":
				value = true
			elif value.to_lower() == "false":
				value = false
			elif value.is_valid_int():
				value = int(value)
			elif value.is_valid_float():
				value = float(value)
			
			custom_params[param_name] = value
	
	# Check for health system related parameters
	if data.has("apply_armor") and data.apply_armor.to_lower() == "true":
		custom_params["apply_armor"] = true
	if data.has("apply_shield") and data.apply_shield.to_lower() == "true":
		custom_params["apply_shield"] = true
	if data.has("apply_overhealth") and data.apply_overhealth.to_lower() == "true":
		custom_params["apply_overhealth"] = true
	
	# Add specific role filters if needed
	if ability.target_filter == GameEnums.TargetFilter.HAS_ROLE:
		if data.has("filter_role"):
			custom_params["filter_role"] = GameEnums.string_to_role(data.filter_role)
	
	# Handle buff/debuff specific params
	if data.has("attack_boost") and data.attack_boost.to_lower() == "true":
		custom_params["attack_boost"] = true
	if data.has("defense_boost") and data.defense_boost.to_lower() == "true":
		custom_params["defense_boost"] = true
	if data.has("speed_boost") and data.speed_boost.to_lower() == "true":
		custom_params["speed_boost"] = true
	
	ability.custom_params = custom_params
	
	# Validate the targeting combination
	if not ability.validate_targeting():
		print("  Warning: Invalid targeting combination for ability: " + ability_id)
	
	# Save the resource
	var result = ResourceSaver.save(ability, file_path)
	if result == OK:
		print("  Saved ability resource: " + file_path)
	else:
		print("  Failed to save ability resource: " + file_path)

func import_characters_from_csv():
	"""
	Import characters from CSV and create/update character resources
	"""
	print("Importing characters...")
	var csv_content = FileAccess.get_file_as_string(CHARACTER_CSV_PATH)
	if csv_content.is_empty():
		print("Error: Failed to read characters CSV file")
		return
	
	var rows = csv_content.split("\n")
	if rows.size() <= 1:
		print("No character data found in CSV")
		return
	
	# Extract header row and convert to lowercase for case-insensitive matching
	var headers = rows[0].split(",")
	for i in range(headers.size()):
		headers[i] = headers[i].strip_edges().to_lower()
	
	# Process each row (skipping header)
	for i in range(1, rows.size()):
		var row = rows[i].split(",")
		if row.size() < headers.size():
			continue  # Skip incomplete rows
		
		# Create a dictionary from this row
		var character_data = {}
		for j in range(headers.size()):
			var value = row[j].strip_edges()
			character_data[headers[j]] = value
		
		# Skip rows without an ID
		if !character_data.has("id") or character_data.id.is_empty():
			continue
		
		# Create or update the character resource
		create_or_update_character(character_data)

func create_or_update_character(data: Dictionary):
	"""
	Create a new character resource or update an existing one
	"""
	var character_id = data.id
	
	# Set up file path (respect folder structure if specified)
	var file_path = CHARACTER_RESOURCE_PATH
	if data.has("folder") and !data.folder.is_empty():
		file_path += data.folder + "/"
		# Create directory if it doesn't exist
		if !DirAccess.dir_exists_absolute(file_path):
			var dir = DirAccess.open(CHARACTER_RESOURCE_PATH)
			dir.make_dir_recursive(data.folder)
	
	file_path += character_id + ".tres"
	
	# Check if resource already exists
	var character: CharacterData
	if ResourceLoader.exists(file_path):
		character = load(file_path) as CharacterData
		print("Updating existing character: " + character_id)
	else:
		character = CharacterData.new()
		print("Creating new character: " + character_id)
	
	# Update character properties
	character.id = character_id
	
	# Basic properties
	if data.has("name"):
		character.name = data.name
	if data.has("description"):
		character.description = data.description
	
	# Enum properties
	if data.has("role"):
		var role_str = data.role
		character.role = GameEnums.string_to_role(role_str)
	
	if data.has("tier"):
		var tier_str = data.tier
		character.tier = GameEnums.string_to_tier(tier_str)
	
	# Stats
	if data.has("hp"):
		character.hp = int(data.hp)
	if data.has("attack"):
		character.attack = int(data.attack)
	if data.has("defense"):
		character.defense = int(data.defense)
	if data.has("speed"):
		character.speed = int(data.speed)
	
	# Health layers - new properties
	if data.has("armor"):
		character.armor = int(data.armor)
	if data.has("shield"):
		character.shield = int(data.shield)
	if data.has("overhealth"):
		character.overhealth = int(data.overhealth)
	
	# Visual properties
	if data.has("sprite_path"):
		character.sprite_path = data.sprite_path
	if data.has("portrait_path"):
		character.portrait_path = data.portrait_path
	
	# Tags
	if data.has("tags"):
		var tags_str = data.tags
		
		# Try different approaches
		var tags_array = tags_str.split(";")
		
		# For Array[String] (typed array in Godot 4)
		if typeof(character.tags) == TYPE_ARRAY:
			# Clear the existing array and add new elements
			character.tags.clear()
			for tag in tags_array:
				if !tag.is_empty():
					character.tags.append(tag)
		else:
			# Try direct assignment
			character.tags = tags_array
	else:
		print("  No tags provided")
	
	# Abilities - link to ability resources
	if data.has("basic_ability_id") and !data.basic_ability_id.is_empty():
		var ability_path = find_ability_resource(data.basic_ability_id)
		if !ability_path.is_empty() and ResourceLoader.exists(ability_path):
			character.basic_ability = load(ability_path)
	
	if data.has("passive_ability_id") and !data.passive_ability_id.is_empty():
		var ability_path = find_ability_resource(data.passive_ability_id)
		if !ability_path.is_empty() and ResourceLoader.exists(ability_path):
			character.passive_ability = load(ability_path)
	
	if data.has("active_ability_id") and !data.active_ability_id.is_empty():
		var ability_path = find_ability_resource(data.active_ability_id)
		if !ability_path.is_empty() and ResourceLoader.exists(ability_path):
			character.active_ability = load(ability_path)
	
	# Save the resource
	var result = ResourceSaver.save(character, file_path)
	if result == OK:
		print("  Saved character resource: " + file_path)
	else:
		print("  Failed to save character resource: " + file_path)

func find_ability_resource(ability_id: String) -> String:
	"""
	Find an ability resource file path by ID
	"""
	# First try direct path
	var direct_path = ABILITY_RESOURCE_PATH + ability_id + ".tres"
	if ResourceLoader.exists(direct_path):
		return direct_path
	
	# If not found, search in subdirectories
	return _search_resource_in_directory(ABILITY_RESOURCE_PATH, ability_id + ".tres")

func _search_resource_in_directory(directory: String, filename: String) -> String:
	"""
	Recursively search for a resource file in a directory and its subdirectories
	"""
	var dir = DirAccess.open(directory)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				# Search in subdirectory
				var result = _search_resource_in_directory(directory + file_name + "/", filename)
				if !result.is_empty():
					return result
			elif file_name == filename:
				return directory + filename
			
			file_name = dir.get_next()
	
	return ""  # Not found
