class_name Party
extends Node2D

# Party properties
var characters = []  # Array of Character instances
var is_player_party: bool = true

# Signals
signal party_defeated
signal positions_updated

func _ready():
	pass

func initialize(is_player: bool, character_data_list: Array):
	"""
	Initialize the party with character data
	"""
	is_player_party = is_player
	
	# Create characters from data
	for i in range(character_data_list.size()):
		var char_data = character_data_list[i]
		var character = create_character(char_data)
		add_character(character, i)

func create_character(character_data: Dictionary) -> Character:
	"""
	Create a character instance from data
	"""
	var character_scene = load("res://scenes/character.tscn")
	var character = character_scene.instantiate()
	character.initialize(character_data)
	character.party = self
	
	# Set name label text
	if character.has_node("NameLabel"):
		character.get_node("NameLabel").text = character.char_name
	
	# Connect signals
	character.connect("character_died", Callable(self, "_on_character_died"))
	
	return character

func add_character(character: Character, position: int = -1):
	"""
	Add a character to the party at specified position
	"""
	# Add to our array
	if position < 0 or position >= characters.size():
		characters.append(character)
		position = characters.size() - 1
	else:
		characters.insert(position, character)
	
	# Update all positions
	update_positions()
	
	# Add to scene tree
	add_child(character)

func remove_character(character: Character):
	"""
	Remove a character from the party
	"""
	var index = characters.find(character)
	if index != -1:
		characters.erase(character)
		update_positions()
	
	if characters.size() == 0:
		emit_signal("party_defeated")
	
	if character.is_inside_tree():
		character.queue_free()

func update_positions():
	"""
	Update the positions of all characters in the party
	Handles the horizontal row arrangement with both parties centered
	"""
	# Constants for positioning
	var screen_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var screen_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var center_x = screen_width / 2
	var center_y = screen_height / 2
	
	var gap_between_parties = 350  # Gap between player and enemy parties
	var character_spacing = 160    # Spacing between characters in the same party
	
	# Calculate total width needed for each party
	var party_width = (characters.size() - 1) * character_spacing
	
	# Starting position depends on party type
	var start_x = 0
	
	if is_player_party:
		# Player party on the left side
		# Rightmost character is closest to center, index 0
		start_x = center_x - (gap_between_parties / 2) - party_width
		
		for i in range(characters.size()):
			var character = characters[i]
			character.position_index = i
			
			# Calculate position - player characters go right to left (higher index = further left)
			var x_pos = start_x + ((characters.size() - 1) - i) * character_spacing
			var y_pos = center_y  # Center vertically
			
			# Animate to new position
			var tween = create_tween()
			tween.tween_property(character, "position", Vector2(x_pos, y_pos), 0.5).set_ease(Tween.EASE_OUT)
	else:
		# Enemy party on the right side
		# Leftmost character is closest to center, index 0
		start_x = center_x + (gap_between_parties / 2)
		
		for i in range(characters.size()):
			var character = characters[i]
			character.position_index = i
			
			# Calculate position - enemy characters go left to right (higher index = further right)
			var x_pos = start_x + i * character_spacing
			var y_pos = center_y  # Center vertically
			
			# Animate to new position
			var tween = create_tween()
			tween.tween_property(character, "position", Vector2(x_pos, y_pos), 0.5).set_ease(Tween.EASE_OUT)
	
	emit_signal("positions_updated")

func _on_character_died(character):
	"""
	Handle character death event
	"""
	# Remove character from party after a delay (for death animation)
	await get_tree().create_timer(1.0).timeout
	remove_character(character)

# Utility functions for targeting

func get_living_characters() -> Array:
	"""
	Get all living characters in the party
	"""
	var living = []
	for character in characters:
		if character.current_hp > 0:
			living.append(character)
	return living

func get_frontmost_character() -> Character:
	"""
	Get the frontmost character (first to take damage)
	For player party: rightmost character (index 0)
	For enemy party: leftmost character (index 0)
	"""
	var living = get_living_characters()
	if living.size() > 0:
		return living[0]
	return null

func get_random_character() -> Character:
	"""
	Get a random living character
	"""
	var living = get_living_characters()
	if living.size() > 0:
		return living[randi() % living.size()]
	return null

func get_lowest_health_character() -> Character:
	"""
	Get the lowest health character
	based on on max health
	from all living character
	"""
	var living = get_living_characters()
	if living.size() > 0:
		var target = living[0]
		for c in living:
			if c.max_hp - c.current_hp > target.max_hp - target.current_hp: target = c
		if target.max_hp - target.current_hp != 0:
			return target
	return null

func get_character_at_position(pos: int) -> Character:
	"""
	Get character at specific position index
	Returns null if position is invalid
	"""
	if pos >= 0 and pos < characters.size():
		return characters[pos]
	return null
