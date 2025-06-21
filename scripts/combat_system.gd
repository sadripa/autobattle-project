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

# Target markers
var active_markers = []  # Array of active target markers

# Signals
signal combat_state_changed(new_state)
signal turn_started(character)
signal turn_ended(character)
signal combat_action_performed(action_data)
signal combat_log_message(message)
signal targets_marked(targets)
signal targets_unmarked()

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
	if current_character == null or !is_instance_valid(current_character) or current_character.health.is_dead():
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
	
	# Process health system turn effects (regeneration, decay, etc.)
	current_character.health.process_turn()
	
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
		result = await character.use_ability(GameEnums.AbilityType.PASSIVE, self)
	else:
		# Use basic ability by default
		result = await character.use_ability(GameEnums.AbilityType.BASIC, self)
	
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
			elif effect.type == "armor":
				emit_signal("combat_log_message", "  → " + effect.target.char_name + " gains " + str(effect.value) + " armor")
			elif effect.type == "shield":
				emit_signal("combat_log_message", "  → " + effect.target.char_name + " gains " + str(effect.value) + " shield")
			elif effect.type == "overhealth":
				emit_signal("combat_log_message", "  → " + effect.target.char_name + " gains " + str(effect.value) + " overhealth")
			elif effect.type == "buff":
				var buff_name = effect.get("buff_id", "buff")
				var duration = effect.get("duration", "?")
				emit_signal("combat_log_message", "  → " + effect.target.char_name + " gained " + buff_name + " for " + str(duration) + " turns")
			elif effect.type == "debuff":
				var debuff_name = effect.get("debuff_id", "debuff")
				var duration = effect.get("duration", "?")
				emit_signal("combat_log_message", "  → " + effect.target.char_name + " gained " + debuff_name + " for " + str(duration) + " turns")
	
	# Hide target markers after ability execution
	hide_target_markers()
	
	# End turn after a short delay
	await get_tree().create_timer(turn_duration).timeout
	end_current_turn()

func show_target_markers(targets: Array):
	"""
	Show visual markers on targeted characters
	"""
	print("DEBUG: show_target_markers called with ", targets.size(), " targets")
	
	# Clear any existing markers first
	hide_target_markers()
	
	# Create markers for each target
	for target in targets:
		if target and is_instance_valid(target):
			print("DEBUG: Creating marker for target: ", target.char_name)
			var marker = _create_or_get_marker()
			
			if marker:
				# Position marker in global space
				var marker_global_pos = target.global_position + Vector2(0, 80)
				
				print("DEBUG: Target at global pos: ", target.global_position, ", marker at global pos: ", marker_global_pos)
				
				# Set global position directly
				marker.global_position = marker_global_pos
				marker.z_index = 10  # Ensure it's rendered on top
				marker.show_marker(_get_marker_color_for_target(target))
				
				# Add to active markers list
				active_markers.append(marker)
			else:
				print("ERROR: Failed to create marker!")
	
	# Emit signal for any additional UI updates
	emit_signal("targets_marked", targets)

func hide_target_markers():
	"""
	Hide all active target markers
	"""
	for marker in active_markers:
		if marker and is_instance_valid(marker):
			marker.hide_marker()
	
	# Clear the list (markers will be reused)
	active_markers.clear()
	
	# Emit signal
	emit_signal("targets_unmarked")

func _create_or_get_marker() -> TargetMarker:
	"""
	Create a new target marker or get an unused one from pool
	"""
	# Look for an existing hidden marker
	for child in get_children():
		if child is TargetMarker and not child.visible:
			print("DEBUG: Reusing existing marker")
			return child
	
	# Create a new marker
	print("DEBUG: Creating new marker")
	
	# Try to load the scene
	var marker_scene_path = "res://scenes/ui/target_marker.tscn"
	if not ResourceLoader.exists(marker_scene_path):
		print("ERROR: Target marker scene not found at: ", marker_scene_path)
		# Create a fallback marker programmatically
		var marker = TargetMarker.new()
		add_child(marker)
		return marker
	
	var marker_scene = load(marker_scene_path)
	if marker_scene:
		var marker = marker_scene.instantiate()
		add_child(marker)
		print("DEBUG: Marker created and added to combat system")
		return marker
	else:
		print("ERROR: Failed to load marker scene")
		return null

func _get_marker_color_for_target(target: Character) -> Color:
	"""
	Get appropriate marker color based on target type
	"""
	if target.party.is_player_party:
		# Friendly target - green
		return Color(0.2, 1.0, 0.2, 0.8)
	else:
		# Enemy target - red
		return Color(1.0, 0.2, 0.2, 0.8)

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
	# Hide any remaining target markers
	hide_target_markers()
	
	# This will be expanded later
	pass

func _on_player_party_defeated():
	change_combat_state(CombatState.DEFEAT)

func _on_enemy_party_defeated():
	change_combat_state(CombatState.VICTORY)

# New helper method to handle health-specific effects
func apply_health_effect(target: Character, effect_type: String, amount: int) -> void:
	"""
	Apply a health-related effect (armor, shield, overhealth) to a target
	"""
	match effect_type:
		"armor":
			target.add_armor(amount)
			emit_signal("combat_log_message", target.char_name + " gains " + str(amount) + " armor")
		"shield":
			target.add_shield(amount)
			emit_signal("combat_log_message", target.char_name + " gains " + str(amount) + " shield")
		"overhealth":
			target.add_overhealth(amount)
			emit_signal("combat_log_message", target.char_name + " gains " + str(amount) + " overhealth")
