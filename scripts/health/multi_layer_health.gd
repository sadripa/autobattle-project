class_name MultiLayerHealth
extends Resource

# Array of health layers, ordered from bottom to top
# [0] is base health, higher indices are layers on top
var layers: Array = []
var owner = null  # Reference to the character this health belongs to

# Debug mode
var debug_mode = true

signal health_changed(layer_index, current, maximum)
signal layer_depleted(layer_index)
signal layer_added(layer_index, health_type)

func _init(character = null):
	owner = character
	if debug_mode:
		var owner_name = "Unknown"
		if owner and owner.has_method("get_name"):
			owner_name = owner.get_name()
		elif owner and owner.has_method("get") and owner.get("char_name"):
			owner_name = owner.char_name

func initialize_with_base_health(amount: int) -> void:
	"""
	Initialize with basic health
	"""
	# Clear any existing layers
	layers.clear()
	
	# Add regular health as the base layer
	var health_type = HealthType.load_from_resources("regular_health")
	health_type.max_amount = amount  # Still set the max amount
	add_health_layer(health_type, amount)

func add_health_layer(health_type: HealthType, amount: int) -> void:
	"""
	Add a new health layer on top
	"""
	var layer = HealthLayer.new(health_type, amount)
	layers.append(layer)
	
	# CRITICAL FIX: Store the layer index before emitting signals
	var layer_index = layers.size() - 1
	
	# Emit signals
	emit_signal("layer_added", layer_index, health_type)
	emit_signal("health_changed", layer_index, layer.current_amount, layer.max_amount)

func remove_health_layer(index: int) -> void:
	"""
	Remove a health layer by index
	"""
	if index >= 0 and index < layers.size():
		# CRITICAL FIX: Emit signal before removing the layer
		emit_signal("layer_depleted", index)
		
		# Now remove the layer
		layers.remove_at(index)

func get_total_health() -> int:
	"""
	Get the total current health across all layers
	"""
	var total = 0
	for layer in layers:
		total += layer.current_amount
	return total

func get_max_total_health() -> int:
	"""
	Get the maximum possible health across all layers
	"""
	var total = 0
	for layer in layers:
		total += layer.max_amount
	return total

func get_health_percentage() -> float:
	"""
	Get the overall health percentage
	"""
	var max_total = get_max_total_health()
	if max_total <= 0:
		return 0.0
	return float(get_total_health()) / float(max_total)

func take_damage(amount: int) -> int:
	"""
	Apply damage to health layers, starting from the top
	Returns the actual damage dealt
	"""
	var remaining_damage = amount
	var original_amount = amount
	
	# Process layers from top to bottom
	for i in range(layers.size() - 1, -1, -1):
		if remaining_damage <= 0:
			break
			
		var layer = layers[i]
		var before_amount = layer.current_amount
		
		remaining_damage = layer.apply_damage(remaining_damage)
		
		# CRITICAL FIX: Only emit signal if health actually changed
		if layer.current_amount != before_amount:
			# Emit signal for UI update
			emit_signal("health_changed", i, layer.current_amount, layer.max_amount)
		
		# If layer is depleted, emit signal
		if layer.current_amount <= 0 and before_amount > 0:
			emit_signal("layer_depleted", i)
			
			# Remove empty layers except the base layer (index 0)
			if i > 0:
				# Don't remove here to avoid array index issues while iterating
				# Mark for removal instead
				call_deferred("remove_health_layer", i)
	
	var actual_damage = original_amount - remaining_damage
	return actual_damage  # Actual damage dealt

func heal(amount: int, target_layer_index: int = 0) -> int:
	"""
	Apply healing to a specific layer (default is base layer)
	Returns the actual healing done
	"""
	var actual_healing = 0
	
	if target_layer_index >= 0 and target_layer_index < layers.size():
		var layer = layers[target_layer_index]
		var before = layer.current_amount
		var overflow = layer.apply_healing(amount)
		actual_healing = amount - overflow
		
		# CRITICAL FIX: Only emit signal if health actually changed
		if layer.current_amount != before:
			# Emit signal for UI update
			emit_signal("health_changed", target_layer_index, layer.current_amount, layer.max_amount)

	return actual_healing

func heal_any_layer(amount: int) -> int:
	"""
	Heals layers from bottom to top, filling each before moving up
	"""
	var remaining_heal = amount
	var total_healed = 0
	
	# Start from base health and work up
	for i in range(layers.size()):
		if remaining_heal <= 0:
			break
			
		var layer = layers[i]
		var before = layer.current_amount
		remaining_heal = layer.apply_healing(remaining_heal)
		var healed = layer.current_amount - before
		
		if healed > 0:
			total_healed += healed
			emit_signal("health_changed", i, layer.current_amount, layer.max_amount)
	
	return total_healed

func add_armor(amount: int, damage_reduction: float = 0.5) -> void:
	"""
	Add armor layer
	"""
	if amount <= 0:
		return
	
	add_health_layer(HealthType.create_armor(amount, damage_reduction), amount)

func add_shield(amount: int, regen: int = 5) -> void:
	"""
	Add shield layer
	"""
	if amount <= 0:
		return
		
	add_health_layer(HealthType.create_shield(amount, regen), amount)

func add_overhealth(amount: int, decay: int = 10, delay: int = 2) -> void:
	"""
	Add overhealth layer
	"""
	if amount <= 0:
		return
	
	add_health_layer(HealthType.create_overhealth(amount, decay, delay), amount)

func process_turn() -> void:
	"""
	Process turn-based effects for all layers
	"""
	for i in range(layers.size() - 1, -1, -1):
		var layer = layers[i]
		var before_amount = layer.current_amount
		
		layer.process_turn()
		
		# CRITICAL FIX: Only emit signal if health actually changed
		if layer.current_amount != before_amount:
			# Emit signal for UI update
			emit_signal("health_changed", i, layer.current_amount, layer.max_amount)
		
		# If layer is depleted, emit signal
		if layer.current_amount <= 0 and before_amount > 0:
			emit_signal("layer_depleted", i)
			
			# Remove empty layers except the base layer (index 0)
			if i > 0:
				# Don't remove here to avoid array index issues
				call_deferred("remove_health_layer", i)

func is_dead() -> bool:
	"""
	Check if character is dead (base layer is empty)
	"""
	var dead = layers.size() == 0 or layers[0].current_amount <= 0
	
	return dead
