class_name Ability
extends Resource

# Basic ability properties
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var ability_type: int = GameEnums.AbilityType.BASIC  # Basic, Passive, or Active
@export var action_type: int = GameEnums.ActionType.ATTACK   # Attack, Defend, Support, Utility
@export var effect_type: int = GameEnums.EffectType.DAMAGE  # Primary effect

# NEW: Targeting properties
@export var target_side: int = GameEnums.TargetSide.ENEMIES
@export var target_range: int = GameEnums.TargetRange.CLOSE
@export var target_section: int = GameEnums.TargetSection.NONE
@export var target_size: int = GameEnums.TargetSize.SINGLE
@export var target_filter: int = GameEnums.TargetFilter.NONE
@export var target_priority: int = GameEnums.TargetPriority.NONE
@export var fallback: int = GameEnums.Fallback.FAIL
@export var penetration: int = GameEnums.Penetration.NONE

# Parameters specific to the ability
@export var power: float = 1.0  # Base multiplier for effects
@export var cooldown: int = 0   # Turns until ability can be used again (0 = no cooldown)

# Custom parameters (can be used for special abilities)
@export var custom_params: Dictionary = {}

# For passive abilities - trigger conditions
@export var trigger_conditions: Array = []  # Array of condition dictionaries

# Visual representation
@export var icon_path: String = ""  # Path to ability icon (if applicable)
@export var effect_animation: String = ""  # Name of animation to play

func can_activate(character, combat_state = null) -> bool:
	"""
	Check if the ability can be activated
	Different logic depending on ability type
	"""
	
	# Check and process cooldown
	match ability_type: 
		GameEnums.AbilityType.BASIC:
			if character.ability_cooldown["basic"] > 0:
				character.ability_cooldown["basic"] -= 1
				return false
			else:
				return true
		GameEnums.AbilityType.ACTIVE:
			if character.ability_cooldown["active"] > 0:
				character.ability_cooldown["active"] -= 1 
				return false
			else:
				return true
		GameEnums.AbilityType.PASSIVE:
			if character.ability_cooldown["passive"] > 0:
				character.ability_cooldown["passive"] -= 1 
				return false
			else: 
				return check_trigger_conditions(character, combat_state)
				

	return false

func check_trigger_conditions(character, combat_state) -> bool:
	"""
	Check if passive ability trigger conditions are met
	"""
	# This would contain custom logic for each passive ability
	# For now, just a placeholder
	return false  # Will implement specific conditions later

func get_targets(character, combat_state) -> Array:
	"""
	Get appropriate targets using the new targeting system
	"""
	return TargetingSystem.get_targets(self, character, combat_state)

func execute(character, targets, combat_state) -> Dictionary:
	"""
	Execute the ability on targets and return results
	"""
	var result = {
		"ability": self,
		"user": character,
		"targets": targets,
		"effects": []
	}
	
	print("DEBUG: Ability.execute called with ", targets.size(), " targets")
	
	# Show target markers before executing
	if combat_state and is_instance_valid(combat_state) and combat_state.has_method("show_target_markers"):
		print("DEBUG: Calling combat_state.show_target_markers")
		combat_state.show_target_markers(targets)
	else:
		print("WARNING: combat_state is invalid or doesn't have show_target_markers method")
		if combat_state:
			print("  combat_state valid: ", is_instance_valid(combat_state))
			print("  has method: ", combat_state.has_method("show_target_markers"))
	
	# Wait a bit so players can see the markers
	if targets.size() > 0:
		await character.get_tree().create_timer(0.5).timeout
	
	# Different execution based on action type
	match action_type:
		GameEnums.ActionType.ATTACK:
			result = CombatActions.execute_attack(character, targets, self, result)
			
		GameEnums.ActionType.DEFEND:
			result = CombatActions.execute_defend(character, targets, self, result)
			
		GameEnums.ActionType.SUPPORT:
			result = CombatActions.execute_support(character, targets, self, result)
			
		GameEnums.ActionType.UTILITY:
			result = CombatActions.execute_utility(character, targets, self, result)
	
	# Handle penetration effects
	if penetration != GameEnums.Penetration.NONE and result.effects.size() > 0:
		result = _apply_penetration(character, targets, combat_state, result)
	
	# Set cooldown if needed
	if cooldown > 0:
		match ability_type: 
			GameEnums.AbilityType.BASIC:
				if character.ability_cooldown["basic"] == 0:
					character.ability_cooldown["basic"] = cooldown
			GameEnums.AbilityType.ACTIVE:
				if character.ability_cooldown["active"] == 0:
					character.ability_cooldown["active"] = cooldown
			GameEnums.AbilityType.PASSIVE:
				if character.ability_cooldown["passive"] == 0:
					character.ability_cooldown["passive"] = cooldown
	
	return result

func _apply_penetration(character, initial_targets, combat_state, result) -> Dictionary:
	"""
	Apply penetration effects like pierce, chain, or splash
	"""
	match penetration:
		GameEnums.Penetration.PIERCE:
			# Continue through targets in a line
			# This would need additional logic based on positioning
			pass
			
		GameEnums.Penetration.CHAIN:
			# Jump to next valid target
			if initial_targets.size() > 0 and result.effects.size() > 0:
				var last_target = initial_targets[-1]
				var next_targets = _find_chain_targets(last_target, initial_targets, combat_state)
				if next_targets.size() > 0:
					# Execute on chain targets with reduced power
					var chain_power = power * 0.7  # 70% power for chain
					var temp_power = power
					power = chain_power
					
					match action_type:
						GameEnums.ActionType.ATTACK:
							CombatActions.execute_attack(character, next_targets, self, result)
						GameEnums.ActionType.SUPPORT:
							CombatActions.execute_support(character, next_targets, self, result)
					
					power = temp_power  # Restore original power
					
		GameEnums.Penetration.SPLASH:
			# Affect adjacent targets
			for target in initial_targets:
				var adjacent = _find_adjacent_targets(target, initial_targets)
				if adjacent.size() > 0:
					# Apply splash damage with reduced power
					var splash_power = power * 0.5  # 50% power for splash
					var temp_power = power
					power = splash_power
					
					if action_type == GameEnums.ActionType.ATTACK:
						CombatActions.execute_attack(character, adjacent, self, result)
					
					power = temp_power  # Restore original power
	
	return result

func _find_chain_targets(last_target, already_hit: Array, combat_state) -> Array:
	"""
	Find valid targets for chain effect
	"""
	var candidates = []
	var target_party = last_target.party
	
	# Get all living characters in the same party
	for char in target_party.get_living_characters():
		if char not in already_hit:
			candidates.append(char)
	
	# Sort by distance from last target
	candidates.sort_custom(func(a, b):
		var dist_a = abs(a.position_index - last_target.position_index)
		var dist_b = abs(b.position_index - last_target.position_index)
		return dist_a < dist_b
	)
	
	# Return closest target
	return [candidates[0]] if candidates.size() > 0 else []

func _find_adjacent_targets(target, already_hit: Array) -> Array:
	"""
	Find adjacent targets for splash effect
	"""
	var adjacent = []
	var target_party = target.party
	var target_pos = target.position_index
	
	# Check positions directly adjacent
	for offset in [-1, 1]:
		var check_pos = target_pos + offset
		var char = target_party.get_character_at_position(check_pos)
		if char and char not in already_hit and char.health.get_total_health() > 0:
			adjacent.append(char)
	
	return adjacent

# Initialize from AbilityData (for backward compatibility)
func initialize_from_data(ability_data: AbilityData):
	"""
	Initialize this ability from an AbilityData resource
	"""
	id = ability_data.id
	name = ability_data.name
	description = ability_data.description
	ability_type = ability_data.ability_type
	action_type = ability_data.action_type
	effect_type = ability_data.effect_type
	
	# New targeting properties
	target_side = ability_data.target_side
	target_range = ability_data.target_range
	target_section = ability_data.target_section
	target_size = ability_data.target_size
	target_filter = ability_data.target_filter
	target_priority = ability_data.target_priority
	fallback = ability_data.fallback
	penetration = ability_data.penetration
	
	power = ability_data.power
	cooldown = ability_data.cooldown
	custom_params = ability_data.custom_params.duplicate()
	icon_path = ability_data.icon_path
	effect_animation = ability_data.effect_animation
