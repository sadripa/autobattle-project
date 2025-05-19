class_name CombatSystem
extends Node

# References to parties
@onready var player_party: Party = $"PlayerParty"
@onready var enemy_party: Party = $"EnemyParty"

# Combat state
enum CombatState {PREPARING, IN_PROGRESS, VICTORY, DEFEAT, ESCAPED}
var current_state = CombatState.PREPARING

# Turn tracking
var turn_order = []  # Array of characters in turn order
var current_turn_index = 0
var turn_count = 0

# Turn speed
var turn_duration = 0.8

# Signals
signal combat_state_changed(new_state)
signal turn_started(character)
signal turn_ended(character)
signal combat_action_performed(action_data)
signal combat_log_message(message)

func _ready():
	# Call initialize after a short delay to ensure parties are ready
	call_deferred("initialize_combat")

func initialize_combat():
	"""
	Initialize the combat system
	"""
	# Connect signals
	player_party.connect("party_defeated", Callable(self, "_on_player_party_defeated"))
	enemy_party.connect("party_defeated", Callable(self, "_on_enemy_party_defeated"))
	
	# Set initial state
	change_combat_state(CombatState.PREPARING)
	
	# Start combat after a short delay
	await get_tree().create_timer(1.0).timeout
	start_combat()
	
	# Emit initial state for UI setup
	emit_signal("combat_state_changed", current_state)
	emit_signal("combat_log_message", "Initializing combat...")

func start_combat():
	emit_signal("combat_log_message", "Combat started!")
	change_combat_state(CombatState.IN_PROGRESS)
	
	"""
	Begin the combat sequence
	"""
	emit_signal("combat_log_message", "Combat started!")
	change_combat_state(CombatState.IN_PROGRESS)
	calculate_turn_order()
	start_next_turn()

func calculate_turn_order():
	"""
	Calculate turn order based on speed
	"""
	turn_order = []
	
	# Gather all living characters
	var all_characters = []
	all_characters.append_array(player_party.get_living_characters())
	all_characters.append_array(enemy_party.get_living_characters())
	
	# Sort by speed (higher speed goes first)
	all_characters.sort_custom(Callable(self, "sort_by_speed"))
	
	turn_order = all_characters
	current_turn_index = 0

func sort_by_speed(a, b):
	"""
	Custom sort function for turn order
	"""
	return a.speed > b.speed

func start_next_turn():
	"""
	Start the next character's turn
	"""
	# Check if we need to recalculate turn order
	if current_turn_index >= turn_order.size():
		turn_count += 1
		calculate_turn_order()
		emit_signal("combat_log_message", "Turn " + str(turn_count) + " started")
	
		# If after recalculation there are no characters left, combat is over
		if turn_order.size() == 0:
			return
	
	# Safety check - ensure we're in range
	if current_turn_index >= turn_order.size():
		current_turn_index = 0
		if turn_order.size() == 0:
			return
	
	# Get current character
	var current_character = turn_order[current_turn_index]
	
	# Skip invalid or dead characters
	if current_character == null or !is_instance_valid(current_character) or current_character.current_hp <= 0:
		# Remove invalid character from turn order
		turn_order.remove_at(current_turn_index)
		
		# Don't increment the index since we just removed an element
		# Just call start_next_turn again to process the next character
		start_next_turn()
		return
	
	# Begin turn
	emit_signal("turn_started", current_character)
	emit_signal("combat_log_message", current_character.char_name + "'s turn")
	
	# Process status effects
	current_character.process_status_effects()
	
	# Process ability cooldowns
	if current_character.abilities.active:
		current_character.abilities.active.process_cooldown()
	
	# Execute character's turn (with a slight delay for readability)
	await get_tree().create_timer(0.5).timeout
	execute_character_turn(current_character)

func execute_character_turn(character: Character):
	"""
	Execute the character's turn
	"""
	var result = {}
	
	# Check for passive ability activation first
	if character.abilities.passive and character.abilities.passive.can_activate(character, self):
		result = character.use_ability(GameEnums.AbilityType.PASSIVE, self)
	else:
		# Use basic ability by default
		result = character.use_ability(GameEnums.AbilityType.BASIC, self)
	
	# If the result indicates success
	if result.has("success") and result.success == false:
		emit_signal("combat_log_message", character.char_name + " could not use ability")
	
	# Improve logging for better clarity
	if result.has("effects") and result.effects.size() > 0:
		for effect in result.effects:
			if effect.type == "damage":
				emit_signal("combat_log_message", "  → " + effect.target.char_name + " takes " + str(effect.value) + " damage")
				if effect.has("critical") and effect.critical:
					emit_signal("combat_log_message", "    Critical hit!")
			elif effect.type == "heal":
				emit_signal("combat_log_message", "  → " + effect.target.char_name + " heals for " + str(effect.value))
			elif effect.type == "buff" or effect.type == "debuff":
				emit_signal("combat_log_message", "  → " + effect.target.char_name + " gained " + effect.buff_id + " for " + str(effect.duration) + " turns")
	
	# End turn after a short delay
	await get_tree().create_timer(turn_duration).timeout
	end_current_turn()

func end_current_turn():
	"""
	End the current character's turn
	"""
	var character = turn_order[current_turn_index]
	emit_signal("turn_ended", character)
	
	# Move to next character
	current_turn_index += 1
	
	# Check combat state
	check_combat_state()
	
	# If combat still in progress, start next turn
	if current_state == CombatState.IN_PROGRESS:
		start_next_turn()

func check_combat_state():
	"""
	Check if combat is over
	"""
	# Already in a terminal state
	if current_state == CombatState.VICTORY or current_state == CombatState.DEFEAT:
		return
	
	var player_living = player_party.get_living_characters().size()
	var enemy_living = enemy_party.get_living_characters().size()
	
	if player_living == 0:
		change_combat_state(CombatState.DEFEAT)
	elif enemy_living == 0:
		change_combat_state(CombatState.VICTORY)

func change_combat_state(new_state):
	"""
	Change combat state and emit signal
	"""
	current_state = new_state
	emit_signal("combat_state_changed", new_state)
	
	match new_state:
		CombatState.VICTORY:
			emit_signal("combat_log_message", "Victory!")
			end_combat()
		CombatState.DEFEAT:
			emit_signal("combat_log_message", "Defeat!")
			end_combat()

func end_combat():
	"""
	Handle end of combat cleanup and transitions
	"""
	# This will be expanded later
	pass

func _on_player_party_defeated():
	change_combat_state(CombatState.DEFEAT)

func _on_enemy_party_defeated():
	change_combat_state(CombatState.VICTORY)
