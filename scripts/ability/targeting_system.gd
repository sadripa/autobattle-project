class_name TargetingSystem
extends RefCounted

# Static class for handling the new targeting system

static func get_targets(ability: Ability, character, combat_state) -> Array:
	"""
	Main entry point for the new targeting system
	"""
	var targets = []
	
	# Step 1: Get candidate pool based on target_side
	var candidate_pool = _get_candidate_pool(ability, character, combat_state)
	if candidate_pool.is_empty() and ability.fallback != GameEnums.Fallback.WAIT:
		return _handle_fallback(ability, character, combat_state)
	
	# Store original positions for section filtering
	var original_positions = {}
	for candidate in candidate_pool:
		original_positions[candidate] = candidate.position_index
	
	# Step 2: Order candidates based on target_range
	var ordered_candidates = _order_by_range(ability, character, candidate_pool)
	
	# Step 3: Apply target_filter if specified
	if ability.target_filter != GameEnums.TargetFilter.NONE:
		ordered_candidates = _apply_filter(ability, ordered_candidates)
	
	# Step 4: Apply target_section if specified
	if ability.target_section != GameEnums.TargetSection.NONE and ordered_candidates.size() > 0:
		ordered_candidates = _apply_section(ability, ordered_candidates, original_positions)
	
	# Step 5: Apply target_priority to reorder if needed
	if ability.target_priority != GameEnums.TargetPriority.NONE:
		ordered_candidates = _apply_priority(ability, ordered_candidates)
	
	# Step 6: Apply target_size to select final targets
	targets = _apply_size(ability, character, ordered_candidates)
	
	# If no valid targets and fallback is set
	if targets.is_empty():
		return _handle_fallback(ability, character, combat_state)
	
	return targets

static func _get_candidate_pool(ability: Ability, character, combat_state) -> Array:
	"""
	Get initial candidate pool based on target_side
	"""
	var candidates = []
	var user_party = character.party
	var enemy_party = null
	
	# Determine enemy party
	if combat_state:
		if user_party.is_player_party:
			enemy_party = combat_state.enemy_party
		else:
			enemy_party = combat_state.player_party
	
	match ability.target_side:
		GameEnums.TargetSide.NONE:
			# Special case - no candidates
			pass
		GameEnums.TargetSide.ALLIES:
			candidates = user_party.get_living_characters()
		GameEnums.TargetSide.ENEMIES:
			if enemy_party:
				candidates = enemy_party.get_living_characters()
		GameEnums.TargetSide.ALLIES_AND_ENEMIES:
			candidates = user_party.get_living_characters()
			if enemy_party:
				candidates.append_array(enemy_party.get_living_characters())
	
	return candidates

static func _order_by_range(ability: Ability, character, candidates: Array) -> Array:
	"""
	Order candidates based on target_range
	"""
	if candidates.is_empty():
		return candidates
	
	var ordered = []
	
	match ability.target_range:
		GameEnums.TargetRange.NONE:
			ordered = candidates
			
		GameEnums.TargetRange.SELF:
			# Add self first
			if character in candidates:
				ordered.append(character)
				candidates.erase(character)
			
			# Add remaining by distance from self
			var self_pos = character.position_index
			var by_distance = []
			
			for candidate in candidates:
				var distance = abs(candidate.position_index - self_pos)
				by_distance.append({"char": candidate, "dist": distance, "pos": candidate.position_index})
			
			# Sort by distance, then by position
			by_distance.sort_custom(func(a, b):
				if a.dist == b.dist:
					return a.pos < b.pos
				return a.dist < b.dist
			)
			
			for item in by_distance:
				ordered.append(item.char)
				
		GameEnums.TargetRange.CLOSE:
			# Sort by position index (ascending)
			candidates.sort_custom(func(a, b): return a.position_index < b.position_index)
			ordered = candidates
			
		GameEnums.TargetRange.MID:
			ordered = _order_by_mid(candidates)
			
		GameEnums.TargetRange.LONG:
			# Sort by position index (descending)
			candidates.sort_custom(func(a, b): return a.position_index > b.position_index)
			ordered = candidates
			
		GameEnums.TargetRange.RANDOM:
			ordered = candidates.duplicate()
			ordered.shuffle()
	
	return ordered

static func _order_by_mid(candidates: Array) -> Array:
	"""
	Special ordering for MID range
	"""
	var ordered = []
	var size = candidates.size()
	
	if size == 0:
		return ordered
	elif size == 1:
		return candidates
	elif size == 2:
		# Random order for 2 characters
		ordered = candidates.duplicate()
		if randi() % 2 == 0:
			ordered.reverse()
		return ordered
	
	# Sort candidates by position first
	var sorted = candidates.duplicate()
	sorted.sort_custom(func(a, b): return a.position_index < b.position_index)
	
	if size % 2 == 0:
		# Even number - pick one of two middle randomly
		var mid1 = size / 2 - 1
		var mid2 = size / 2
		
		if randi() % 2 == 0:
			ordered.append(sorted[mid1])
			ordered.append(sorted[mid2])
		else:
			ordered.append(sorted[mid2])
			ordered.append(sorted[mid1])
		
		# Add remaining by distance
		var left = mid1 - 1
		var right = mid2 + 1
		
		while left >= 0 or right < size:
			if left >= 0:
				ordered.append(sorted[left])
				left -= 1
			if right < size:
				ordered.append(sorted[right])
				right += 1
	else:
		# Odd number - straightforward
		var mid = size / 2
		ordered.append(sorted[mid])
		
		# Add remaining by distance
		var left = mid - 1
		var right = mid + 1
		
		while left >= 0 or right < size:
			if left >= 0 and right < size:
				# Add closer one first
				ordered.append(sorted[left])
				ordered.append(sorted[right])
			elif left >= 0:
				ordered.append(sorted[left])
			elif right < size:
				ordered.append(sorted[right])
			
			left -= 1
			right += 1
	
	return ordered

static func _apply_filter(ability: Ability, candidates: Array) -> Array:
	"""
	Apply stat-based filtering
	"""
	if candidates.is_empty():
		return candidates
	
	var filtered = candidates.duplicate()
	
	match ability.target_filter:
		GameEnums.TargetFilter.LOWEST_HP:
			filtered.sort_custom(func(a, b): 
				return a.health.get_health_percentage() < b.health.get_health_percentage()
			)
		
		GameEnums.TargetFilter.HIGHEST_HP:
			filtered.sort_custom(func(a, b): 
				return a.health.get_health_percentage() > b.health.get_health_percentage()
			)
		
		GameEnums.TargetFilter.HAS_DEBUFF:
			filtered = filtered.filter(func(c): 
				return c.status_effects.any(func(e): return e.stat_mods.values().any(func(v): return v < 0))
			)
		
		GameEnums.TargetFilter.MISSING_HEALTH:
			filtered = filtered.filter(func(c): 
				return c.health.get_health_percentage() < 0.5
			)
		
		GameEnums.TargetFilter.HAS_ROLE:
			if ability.custom_params.has("filter_role"):
				var role = ability.custom_params.filter_role
				filtered = filtered.filter(func(c): return c.role == role)
		
		GameEnums.TargetFilter.CUSTOM:
			if ability.custom_params.has("filter_function"):
				# This would call a custom function defined in the ability
				pass
	
	return filtered

static func _apply_section(ability: Ability, candidates: Array, original_positions: Dictionary) -> Array:
	"""
	Apply section filtering based on original positions
	"""
	if candidates.is_empty():
		return candidates
	
	var first_char = candidates[0]
	var first_pos = original_positions[first_char]
	var filtered = []
	
	match ability.target_section:
		GameEnums.TargetSection.BEFORE:
			for candidate in candidates:
				if original_positions[candidate] < first_pos:
					filtered.append(candidate)
		
		GameEnums.TargetSection.AFTER:
			for candidate in candidates:
				if original_positions[candidate] > first_pos:
					filtered.append(candidate)
	
	# If no candidates meet criteria, return original list
	return filtered if filtered.size() > 0 else candidates

static func _apply_priority(ability: Ability, candidates: Array) -> Array:
	"""
	Apply priority-based reordering
	"""
	if candidates.is_empty():
		return candidates
	
	var prioritized = candidates.duplicate()
	
	match ability.target_priority:
		GameEnums.TargetPriority.PROTECT_VALUABLE:
			prioritized.sort_custom(func(a, b): return a.tier > b.tier)
		
		GameEnums.TargetPriority.FINISH_WOUNDED:
			prioritized.sort_custom(func(a, b): 
				return a.health.get_health_percentage() < b.health.get_health_percentage()
			)
		
		GameEnums.TargetPriority.BREAK_FORMATION:
			# Prioritize middle positions
			var max_pos = 0
			for c in prioritized:
				if c.position_index > max_pos:
					max_pos = c.position_index
			
			var mid_pos = max_pos / 2.0
			prioritized.sort_custom(func(a, b):
				var dist_a = abs(a.position_index - mid_pos)
				var dist_b = abs(b.position_index - mid_pos)
				return dist_a < dist_b
			)
	
	return prioritized

static func _apply_size(ability: Ability, character, candidates: Array) -> Array:
	"""
	Select final targets based on target_size
	"""
	if candidates.is_empty():
		return candidates
	
	var selected = []
	
	match ability.target_size:
		GameEnums.TargetSize.SINGLE:
			if candidates.size() > 0:
				selected.append(candidates[0])
		
		GameEnums.TargetSize.DOUBLE:
			for i in range(min(2, candidates.size())):
				selected.append(candidates[i])
		
		GameEnums.TargetSize.TRIPLE:
			for i in range(min(3, candidates.size())):
				selected.append(candidates[i])
		
		GameEnums.TargetSize.ADJACENT:
			if candidates.size() > 0:
				var first = candidates[0]
				var party_size = first.party.characters.size()
				
				# Check if at edge
				if first.position_index == 0 or first.position_index == party_size - 1:
					# Edge position - select 2
					for i in range(min(2, candidates.size())):
						selected.append(candidates[i])
				else:
					# Middle position - select 3
					for i in range(min(3, candidates.size())):
						selected.append(candidates[i])
		
		GameEnums.TargetSize.ALL:
			selected = candidates
	
	return selected

static func _handle_fallback(ability: Ability, character, combat_state) -> Array:
	"""
	Handle fallback behavior when no valid targets
	"""
	match ability.fallback:
		GameEnums.Fallback.FAIL:
			return []
		
		GameEnums.Fallback.RANDOM_VALID:
			# Try to find any valid target
			var all_living = []
			if ability.target_side in [GameEnums.TargetSide.ALLIES, GameEnums.TargetSide.ALLIES_AND_ENEMIES]:
				all_living.append_array(character.party.get_living_characters())
			if ability.target_side in [GameEnums.TargetSide.ENEMIES, GameEnums.TargetSide.ALLIES_AND_ENEMIES]:
				var enemy_party = combat_state.player_party if !character.party.is_player_party else combat_state.enemy_party
				if enemy_party:
					all_living.append_array(enemy_party.get_living_characters())
			
			if all_living.size() > 0:
				return [all_living[randi() % all_living.size()]]
			return []
		
		GameEnums.Fallback.SELF:
			return [character]
		
		GameEnums.Fallback.WAIT:
			# This is handled in the combat system
			return []
		
		_:
			# Default case - treat as FAIL
			return []
