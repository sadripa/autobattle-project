class_name Ability
extends Resource

# Basic ability properties
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var ability_type: int = GameEnums.AbilityType.BASIC  # Basic, Passive, or Active
@export var action_type: int = GameEnums.ActionType.ATTACK   # Attack, Defend, Support, Utility
@export var target_type: int = GameEnums.TargetType.SINGLE_ENEMY  # Targeting method
@export var effect_type: int = GameEnums.EffectType.DAMAGE  # Primary effect

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
	Get appropriate targets based on target_type
	"""
	var targets = []
	var user_party = character.party
	var enemy_party = null
	
	# Determine enemy party
	if combat_state:
		if user_party.is_player_party:
			enemy_party = combat_state.enemy_party
		else:
			enemy_party = combat_state.player_party
	
	# Get targets based on targeting type
	match target_type:
		GameEnums.TargetType.SINGLE_ENEMY:
			if enemy_party:
				var target = enemy_party.get_frontmost_character()
				if target:
					targets.append(target)
		
		GameEnums.TargetType.ALL_ENEMIES:
			if enemy_party:
				targets = enemy_party.get_living_characters()
		
		GameEnums.TargetType.SINGLE_ALLY:
			var target = null
			# Can implement different selection methods (random, lowest health, etc.)
			target = user_party.get_random_character()
			if target:
				targets.append(target)
		
		GameEnums.TargetType.LOWEST_ALLY:
			var target = null
			# Only search within character's own party
			target = user_party.get_lowest_health_character()
			if target:
				targets.append(target)
		
		GameEnums.TargetType.ALL_ALLIES:
			targets = user_party.get_living_characters()
		
		GameEnums.TargetType.SELF:
			targets.append(character)
		
		GameEnums.TargetType.POSITION_BASED:
			# Custom position-based targeting logic
			# Will implement based on specific ability needs
			pass
	
	return targets

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
