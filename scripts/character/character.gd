class_name Character
extends Node2D

# Character properties
var id: String
var char_name: String
var role: int  # Now using enum: GameEnums.Role
var tier: int  # Now using enum: GameEnums.Tier

# Base stats
var max_hp: int
var current_hp: int  # Kept for backward compatibility
var attack: int
var defense: int
var speed: int

# New health system
var health: MultiLayerHealth

# Position in party (0-based, right to left)
var position_index: int = 0

# Abilities
var abilities = {
	"basic": null,   # Always available, used automatically
	"passive": null, # Triggered by conditions
	"active": null   # Player-activated
}
var ability_cooldown = {
	"basic": 0,   
	"passive": 0, 
	"active": 0   
}

# Status effects
var status_effects = []

# References
var party  # Reference to the party this character belongs to
var sprite: Sprite2D
var health_bar  # Reference to health bar UI, will be replaced with MultiLayerHealthBar

# Debug mode
var debug_mode = true

# Signals
signal hp_changed(current, maximum)  # Kept for backward compatibility
signal character_died(character)
signal ability_used(ability_data, targets, result)
signal status_effect_added(effect)
signal status_effect_removed(effect)

func _ready():
	sprite = $Sprite2D
	
	# IMPORTANT: Initialize health if not already initialized
	# This ensures health exists before we try to use the health bar
	if health == null:
		health = MultiLayerHealth.new(self)
		health.initialize_with_base_health(max_hp)
	
	# Check if we have the new multi-layer health bar
	if has_node("MultiLayerHealthBar"):
		health_bar = $MultiLayerHealthBar
	else:
		health_bar = $HealthBar  # Fallback to old health bar
	
	# CRITICAL FIX: Connect health signals to the UI with error checking
	_connect_health_signals()
	
	# CRITICAL FIX: Delay the initial health display update
	# This ensures all nodes are properly initialized
	call_deferred("delayed_health_update")

# Separate method to connect health signals with error checking
func _connect_health_signals():
	if health:
		
		# Disconnect any existing connections to avoid duplicates
		if health.is_connected("health_changed", Callable(self, "_on_health_changed")):
			health.disconnect("health_changed", Callable(self, "_on_health_changed"))
			
		if health.is_connected("layer_depleted", Callable(self, "_on_layer_depleted")):
			health.disconnect("layer_depleted", Callable(self, "_on_layer_depleted"))
			
		if health.is_connected("layer_added", Callable(self, "_on_layer_added")):
			health.disconnect("layer_added", Callable(self, "_on_layer_added"))
		
		# Connect the signals again
		health.connect("health_changed", Callable(self, "_on_health_changed"))
		health.connect("layer_depleted", Callable(self, "_on_layer_depleted"))
		health.connect("layer_added", Callable(self, "_on_layer_added"))

# New method to handle delayed health update
func delayed_health_update():
	# Wait a short time to ensure the MultiLayerHealthBar is fully initialized
	await get_tree().create_timer(0.1).timeout
	
	# Force update the health display
	update_health_display()
	
func initialize(character_data: Dictionary):
	"""
	Initialize character from data dictionary
	"""
	id = character_data.id
	char_name = character_data.name
	
	# Convert string role/tier to enum if needed
	if character_data.role is String:
		role = GameEnums.string_to_role(character_data.role)
	else:
		role = character_data.role
		
	if character_data.tier is String:
		tier = GameEnums.string_to_tier(character_data.tier)
	else:
		tier = character_data.tier
	
	# Set base stats
	max_hp = character_data.hp
	current_hp = max_hp
	attack = character_data.attack
	defense = character_data.defense
	speed = character_data.speed
	
	# Initialize the new health system
	health = MultiLayerHealth.new(self)
	health.initialize_with_base_health(max_hp)
	
	# Add additional health layers based on character role or custom properties
	if character_data.has("armor"):
		var armor_amount = character_data.armor
		if armor_amount > 0:
			health.add_armor(armor_amount)
	
	if character_data.has("shield"):
		var shield_amount = character_data.shield
		if shield_amount > 0:
			health.add_shield(shield_amount)
	
	if character_data.has("overhealth"):
		var overhealth_amount = character_data.overhealth
		if overhealth_amount > 0:
			health.add_overhealth(overhealth_amount)
	
	# Connect the health signals
	_connect_health_signals()
	
	# Initialize abilities
	if character_data.has("abilities"):
		# Set up each ability type if provided
		if character_data.abilities.has("basic"):
			var ability_data = character_data.abilities.basic
			var ability = Ability.new()
			ability.id = ability_data.id
			ability.name = ability_data.name
			ability.description = ability_data.get("description", "")
			ability.ability_type = GameEnums.AbilityType.BASIC
			ability.action_type = GameEnums.string_to_action_type(ability_data.type)
			ability.target_type = GameEnums.string_to_target_type(ability_data.target)
			ability.effect_type = GameEnums.string_to_effect_type(ability_data.effect)
			ability.power = ability_data.power
			ability.cooldown = ability_data.cooldown
			# Set custom params if any
			if ability_data.has("custom_params"):
				ability.custom_params = ability_data.custom_params.duplicate()
			
			abilities.basic = ability
		
		# Similar initialization for passive and active abilities
		if character_data.abilities.has("passive"):
			# Initialize passive ability
			pass
			
		if character_data.abilities.has("active"):
			# Initialize active ability
			pass
	else:
		# Backward compatibility with old data format
		# Create a basic ability from the single ability entry
		var ability_data = character_data.ability
		var ability = Ability.new()
		ability.id = char_name.to_lower() + "_basic"
		ability.name = ability_data.name
		ability.ability_type = GameEnums.AbilityType.BASIC
		ability.action_type = GameEnums.string_to_action_type(ability_data.type)
		ability.target_type = GameEnums.string_to_target_type(ability_data.target)
		ability.effect_type = GameEnums.string_to_effect_type(ability_data.effect)
		ability.power = ability_data.power
		
		abilities.basic = ability
	
	# Update visuals
	update_health_display()
	# Update sprite based on character
	$Sprite2D.modulate = get_role_color()
	
	# Update name label
	if has_node("NameLabel"):
		$NameLabel.text = char_name

func get_role_color() -> Color:
	"""
	Return a color based on character role for easy visual identification
	"""
	match role:
		GameEnums.Role.BLADE: return Color(0.9, 0.3, 0.3)  # Red for attackers
		GameEnums.Role.BANNER: return Color(0.3, 0.3, 0.9)  # Blue for defenders
		GameEnums.Role.ECHO: return Color(0.3, 0.9, 0.3)  # Green for supports
		GameEnums.Role.FRACTURE: return Color(0.9, 0.3, 0.9)  # Purple for disruptors
		GameEnums.Role.BOND: return Color(0.9, 0.9, 0.3)  # Yellow for hybrid
		_: return Color(0.7, 0.7, 0.7)  # Gray default

func take_damage(amount: int) -> int:
	"""
	Apply damage to character and return actual damage dealt
	"""
	
	var actual_damage = health.take_damage(amount)
	
	# Update current_hp for backward compatibility
	current_hp = health.get_total_health()
	
	# Visual feedback
	play_damage_animation()
	
	# CRITICAL FIX: Force update the health display
	update_health_display()
	
	# Check if dead
	if health.is_dead():
		die()
	
	# Emit legacy signal for compatibility
	emit_signal("hp_changed", current_hp, max_hp)
	
	return actual_damage

func heal(amount: int) -> int:
	"""
	Heal character and return actual amount healed
	"""
	
	var actual_heal = health.heal(amount)
	
	# Update current_hp for backward compatibility
	current_hp = health.get_total_health()

	# Visual feedback
	if actual_heal > 0:
		play_heal_animation()
	
	# CRITICAL FIX: Force update the health display
	update_health_display()
	
	# Emit legacy signal for compatibility
	emit_signal("hp_changed", current_hp, max_hp)
	
	return actual_heal

func add_armor(amount: int) -> void:
	"""
	Add armor layer to character
	"""
	
	health.add_armor(amount)
	
	# Update current_hp for backward compatibility
	current_hp = health.get_total_health()
	
	# CRITICAL FIX: Force update the health display
	update_health_display()
	
	# Emit legacy signal for compatibility
	emit_signal("hp_changed", current_hp, max_hp)

func add_shield(amount: int) -> void:
	"""
	Add shield layer to character
	"""
	
	health.add_shield(amount)
	
	# Update current_hp for backward compatibility
	current_hp = health.get_total_health()
	
	# CRITICAL FIX: Force update the health display
	update_health_display()
	
	# Emit legacy signal for compatibility
	emit_signal("hp_changed", current_hp, max_hp)

func add_overhealth(amount: int) -> void:
	"""
	Add overhealth layer to character
	"""
	
	health.add_overhealth(amount)
	
	# Update current_hp for backward compatibility
	current_hp = health.get_total_health()
	
	# CRITICAL FIX: Force update the health display
	update_health_display()
	
	# Emit legacy signal for compatibility
	emit_signal("hp_changed", current_hp, max_hp)

func use_ability(ability_type: int, combat_state) -> Dictionary:
	"""
	Use specified ability type (basic, passive, active)
	Returns the result of the ability execution
	"""
	var ability = null
	match ability_type:
		GameEnums.AbilityType.BASIC:
			ability = abilities.basic
		GameEnums.AbilityType.PASSIVE:
			ability = abilities.passive
		GameEnums.AbilityType.ACTIVE:
			ability = abilities.active
	
	if ability and ability.can_activate(self, combat_state):
		# Visual feedback for ability use
		play_ability_animation()
		
		# Get targets
		var targets = ability.get_targets(self, combat_state)
		
		# Execute ability
		var result = ability.execute(self, targets, combat_state)
		
		# Emit signal
		emit_signal("ability_used", ability, targets, result)
		
		return result
	
	return {"success": false, "message": "Ability can't be activated"}

func die():
	"""
	Handle character death
	"""
	
	emit_signal("character_died", self)
	
	# Visual feedback for death
	modulate = Color(1, 1, 1, 0.5)

func update_health_display():
	"""
	Update health bar UI
	"""
	
	# CRITICAL FIX: Add safeguards
	if health == null:
		# Create health system if missing
		health = MultiLayerHealth.new(self)
		health.initialize_with_base_health(max_hp)
	
	if health_bar == null:
		# Try to find health bar again
		if has_node("MultiLayerHealthBar"):
			health_bar = $MultiLayerHealthBar
		else:
			health_bar = $HealthBar  # Fallback to old health bar
	
	# Ensure the health bar has the right methods
	if health_bar and health_bar.has_method("update_multi_layer_health"):
		# New multi-layer health bar
		
		# CRITICAL FIX: Ensure the health bar is visible
		health_bar.visible = true
		health_bar.show()
		
		# Update the health display
		health_bar.update_multi_layer_health(health)
	elif health_bar and health_bar.has_method("update_bar"):
		# Legacy health bar
		health_bar.update_bar(current_hp, max_hp)
	
	# Emit legacy signal for compatibility
	emit_signal("hp_changed", current_hp, max_hp)

func _on_health_changed(layer_index, current, maximum):
	"""
	Handle health change events from the health system
	"""
	
	update_health_display()

func _on_layer_depleted(layer_index):
	"""
	Handle layer depletion events
	"""
	
	update_health_display()

func _on_layer_added(layer_index, health_type):
	"""
	Handle layer addition events
	"""
	
	update_health_display()

func play_damage_animation():
	"""
	Visual feedback when taking damage
	"""
	var tween = create_tween()
	tween.tween_property(self.sprite, "modulate", Color(1, 0.5, 0.5), 0.1)
	tween.tween_property(self.sprite, "modulate", Color(1, 0.5, 0.5), 0.1)
	tween.tween_property(self.sprite, "modulate", get_role_color(), 0.1)

func play_heal_animation():
	"""
	Visual feedback when healed
	"""
	var tween = create_tween()
	tween.tween_property(self.sprite, "modulate", Color(0.5, 1, 0.5), 0.1)
	tween.tween_property(self.sprite, "modulate", get_role_color(), 0.1)

func play_ability_animation():
	"""
	Visual feedback when using ability
	"""
	var tween = create_tween()
	tween.tween_property(self.sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self.sprite, "scale", Vector2(1.0, 1.0), 0.1)

func add_status_effect(effect: StatusEffect):
	"""
	Add a status effect to the character
	"""
	# Check if there's already an effect with the same id
	for existing in status_effects:
		if existing.id == effect.id:
			# Replace the existing effect
			existing.remove(self)
			status_effects.erase(existing)
			break
	
	# Add the new effect
	status_effects.append(effect)
	effect.apply(self)
	
	# Emit signal
	emit_signal("status_effect_added", effect)

func remove_status_effect(effect_id: String):
	"""
	Remove a status effect by id
	"""
	for i in range(status_effects.size() - 1, -1, -1):
		if status_effects[i].id == effect_id:
			status_effects[i].remove(self)
			var effect = status_effects[i]
			status_effects.remove_at(i)
			emit_signal("status_effect_removed", effect)
			break

func process_status_effects():
	"""
	Process all status effects for a turn
	"""
	for i in range(status_effects.size() - 1, -1, -1):
		var effect = status_effects[i]
		# If effect should end, remove it
		if not effect.tick(self):
			effect.remove(self)
			status_effects.remove_at(i)
			emit_signal("status_effect_removed", effect)
	
	# Process health system turn effects
	health.process_turn()
	
	# CRITICAL FIX: Update display after processing effects
	update_health_display()
