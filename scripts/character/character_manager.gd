extends Node

# Store all loaded character data
var characters = {}

# Path to character resource files
const CHARACTER_PATH = "res://resources/characters/"

func _ready():
	# Load all character resources on startup
	load_all_characters()

func load_all_characters():
	"""
	Load all character resources from the characters directory and its subdirectories
	"""
	_load_characters_in_directory(CHARACTER_PATH)

func _load_characters_in_directory(path: String):
	"""
	Recursively load character resources from a directory and its subdirectories
	"""
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				# Recursively process subdirectory
				_load_characters_in_directory(path + file_name + "/")
			elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
				# Check if it's a character resource
				var resource_path = path + file_name
				var resource = load(resource_path)
				
				if resource is CharacterData:
					var character_id = resource.id
					if character_id.is_empty():
						# Use filename as fallback ID if id property is empty
						character_id = file_name.get_basename()
						resource.id = character_id
					
					characters[character_id] = resource
					print("Loaded character: " + character_id + " from " + resource_path)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("Error: Can't open directory at: " + path)

func get_character_data(character_id: String) -> CharacterData:
	"""
	Get a character data resource by ID
	"""
	if characters.has(character_id):
		return characters[character_id]
	
	# Try to load it if not already loaded
	var path = CHARACTER_PATH + character_id + ".tres"
	if ResourceLoader.exists(path):
		var data = load(path)
		if data is CharacterData:
			characters[character_id] = data
			return data
	
	print("Character not found: " + character_id)
	return null

func get_character_dictionary(character_id: String) -> Dictionary:
	"""
	Get character data as dictionary (for compatibility with existing code)
	"""
	var character_data = get_character_data(character_id)
	if character_data:
		return character_data.to_dictionary()
	return {}

func get_all_character_ids() -> Array:
	"""
	Get a list of all available character IDs
	"""
	return characters.keys()

func get_characters_by_role(role: int) -> Array:
	"""
	Get all characters with a specific role
	"""
	var result = []
	for id in characters:
		var character = characters[id]
		if character.role == role:
			result.append(character)
	return result

func get_characters_by_tier(tier: int) -> Array:
	"""
	Get all characters with a specific tier
	"""
	var result = []
	for id in characters:
		var character = characters[id]
		if character.tier == tier:
			result.append(character)
	return result
