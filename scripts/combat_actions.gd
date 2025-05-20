class_name CombatActions
extends Node

# Static methods for executing different types of combat actions

static func execute_attack(character, targets: Array, ability: Ability, result: Dictionary) -> Dictionary:
	"""
	Execute an attack ability
	"""
	for target in targets:
		var damage = calculate_damage(character, target, ability)
		
		# Check for critical hit
		var is_critical = is_critical_hit(character)
		if is_critical:
			damage = int(damage * 1.5)  # 50% bonus damage for crits
			
		# Apply damage to target
		var actual_damage = target.take_damage(damage)
		
		# Record effect
		var effect = {
			"type": "damage",
			"target": target,
			"value": actual_damage,
			"critical": is_critical
		}
		result.effects.append(effect)
	
	return result

static func execute_defend(character, targets: Array, ability: Ability, result: Dictionary) -> Dictionary:
	"""
	Execute a defensive ability
	"""
	
	for target in targets:
		# Determine the effect type from custom params
		if ability.custom_params.has("apply_armor") and ability.custom_params.apply_armor:
			# Apply armor
			var armor_amount = int(character.defense * ability.power)
			target.add_armor(armor_amount)
			
			# Record effect
			var effect = {
				"type": "armor",
				"target": target,
				"value": armor_amount
			}
			result.effects.append(effect)
		elif ability.custom_params.has("apply_shield") and ability.custom_params.apply_shield:
			# Apply shield
			var shield_amount = int(character.defense * ability.power)
			target.add_shield(shield_amount)
			
			# Record effect
			var effect = {
				"type": "shield",
				"target": target,
				"value": shield_amount
			}
			result.effects.append(effect)
		else:
			# Apply defensive buff (legacy behavior)
			var defense_boost = int(character.defense * ability.power)
			
			# Get duration from custom params or use default
			var duration = 2  # Default duration in turns
			if ability.custom_params.has("duration"):
				duration = ability.custom_params.duration
			
			# Determine the buff ID and name
			var buff_id = "defense_up"
			var buff_name = "Defense Up"
			
			# Check for specific buff types in custom params
			if ability.custom_params.has("defense_boost") and ability.custom_params.defense_boost:
				buff_id = "defense_up"
				buff_name = "Defense Up"
			elif ability.custom_params.has("attack_boost") and ability.custom_params.attack_boost:
				buff_id = "attack_up"
				buff_name = "Attack Up"
				defense_boost = int(character.attack * ability.power)  # Use attack instead of defense
			elif ability.custom_params.has("speed_boost") and ability.custom_params.speed_boost:
				buff_id = "speed_up"
				buff_name = "Speed Up"
				defense_boost = int(character.speed * ability.power)  # Use speed instead of defense
			
			# Create appropriate stat mods
			var stat_mods = {}
			if buff_id == "defense_up":
				stat_mods = {"defense": defense_boost}
			elif buff_id == "attack_up":
				stat_mods = {"attack": defense_boost}
			elif buff_id == "speed_up":
				stat_mods = {"speed": defense_boost}
			
			# Create a buff status effect
			var buff = StatusEffect.new()
			buff.initialize({
				"id": buff_id,
				"name": buff_name,
				"duration": duration,
				"stat_mods": stat_mods,
				"source": character
			})
			
			# Add buff to target
			target.add_status_effect(buff)
			
			# Record effect
			var effect = {
				"type": "buff",
				"target": target,
				"buff_id": buff_id,
				"value": defense_boost,
				"duration": duration
			}
			result.effects.append(effect)
	
	return result

static func execute_support(character, targets: Array, ability: Ability, result: Dictionary) -> Dictionary:
	"""
	Execute a support ability (healing, buffing)
	"""
	match ability.effect_type:
		GameEnums.EffectType.HEAL:
			for target in targets:
				# Calculate healing amount
				var heal_amount = 0
				
				# Healing can be flat or based on user's stats
				if ability.custom_params.has("flat_heal"):
					heal_amount = ability.custom_params.flat_heal
				else:
					# Base healing on a percentage of max HP
					heal_amount = int(target.max_hp * ability.power * 0.2)
				
				# Check for special health types
				if ability.custom_params.has("apply_overhealth") and ability.custom_params.apply_overhealth:
					target.add_overhealth(heal_amount)
					
					# Record effect
					var effect = {
						"type": "overhealth",
						"target": target,
						"value": heal_amount
					}
					result.effects.append(effect)
				else:
					# Apply regular healing
					var actual_heal = target.heal(heal_amount)
					
					# Record effect
					var effect = {
						"type": "heal",
						"target": target,
						"value": actual_heal
					}
					result.effects.append(effect)
				
		GameEnums.EffectType.BUFF:
			for target in targets:
				# Apply appropriate buff based on ability
				var buff = StatusEffect.new()
				var duration = ability.custom_params.get("duration", 2)
				
				if ability.custom_params.has("attack_boost"):
					# Attack buff
					var boost = int(target.attack * ability.power)
					buff.initialize({
						"id": "attack_up",
						"name": "Attack Up",
						"duration": duration,
						"stat_mods": {"attack": boost},
						"source": character
					})
				elif ability.custom_params.has("speed_boost"):
					# Speed buff
					var boost = int(target.speed * ability.power)
					buff.initialize({
						"id": "speed_up",
						"name": "Speed Up",
						"duration": duration,
						"stat_mods": {"speed": boost},
						"source": character
					})
				
				# Add buff to target
				target.add_status_effect(buff)
				
				# Record effect
				var effect = {
					"type": "buff",
					"target": target,
					"buff_id": buff.id,
					"duration": duration
				}
				result.effects.append(effect)
	
	return result

static func execute_utility(character, targets: Array, ability: Ability, result: Dictionary) -> Dictionary:
	"""
	Execute a utility ability (debuffs, special effects)
	"""
	match ability.effect_type:
		GameEnums.EffectType.DEBUFF:
			for target in targets:
				# Apply debuff
				var debuff = StatusEffect.new()
				var duration = ability.custom_params.get("duration", 2)
				
				if ability.custom_params.has("defense_reduction"):
					# Defense debuff
					var reduction = int(target.defense * ability.power)
					debuff.initialize({
						"id": "defense_down",
						"name": "Defense Down",
						"duration": duration,
						"stat_mods": {"defense": -reduction},
						"source": character
					})
				elif ability.custom_params.has("speed_reduction"):
					# Speed debuff
					var reduction = int(target.speed * ability.power)
					debuff.initialize({
						"id": "speed_down",
						"name": "Speed Down",
						"duration": duration,
						"stat_mods": {"speed": -reduction},
						"source": character
					})
				
				# Add debuff to target
				target.add_status_effect(debuff)
				
				# Record effect
				var effect = {
					"type": "debuff",
					"target": target,
					"debuff_id": debuff.id,
					"duration": duration
				}
				result.effects.append(effect)
	
	return result

# Helper functions

static func calculate_damage(attacker, defender, ability: Ability) -> int:
	"""
	Calculate damage based on attacker and defender stats
	"""
	var base_damage = int(attacker.attack * ability.power)
	var defense_factor = 0.5  # How much defense reduces damage
	var damage_reduction = int(defender.defense * defense_factor)
	
	# Minimum damage is 1
	return max(1, base_damage - damage_reduction)

static func is_critical_hit(character) -> bool:
	"""
	Determine if an attack is a critical hit
	Base critical chance is 10%
	"""
	# Critical hit chance (can be modified by character stats later)
	var crit_chance = 10
	
	# Generate random number 1-100
	var roll = randi() % 100 + 1
	
	return roll <= crit_chance
