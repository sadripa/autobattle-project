class_name StatusEffect
extends Resource

# Basic properties
var id: String
var name: String
var description: String
var duration: int  # How many turns the effect lasts
var permanent: bool = false  # If true, effect doesn't expire with time

# Visual
var icon_path: String

# Effect data
var stat_mods: Dictionary = {}  # Stat modifiers: {"attack": 5, "defense": -2}
var triggers: Array = []  # Special triggers for custom effects
var source  # Character who applied this effect

# Tick function gets called each turn
func tick(target) -> bool:
	"""
	Process the effect for one turn
	Returns true if effect should continue, false if it should end
	"""
	# Reduce duration if not permanent
	if not permanent:
		duration -= 1
	
	# Apply any per-turn effects
	apply_tick_effects(target)
	
	# Return whether effect should continue
	return permanent or duration > 0

func apply(target):
	"""
	Apply the initial effect
	"""
	# Apply stat modifiers
	for stat in stat_mods:
		match stat:
			"attack":
				target.attack += stat_mods[stat]
			"defense":
				target.defense += stat_mods[stat]
			"speed":
				target.speed += stat_mods[stat]
			# Add other stats as needed
	
	# Apply any custom effects
	apply_custom_effects(target)

func remove(target):
	"""
	Remove the effect (undo stat changes)
	"""
	# Remove stat modifiers
	for stat in stat_mods:
		match stat:
			"attack":
				target.attack -= stat_mods[stat]
			"defense":
				target.defense -= stat_mods[stat]
			"speed":
				target.speed -= stat_mods[stat]
			# Add other stats as needed
	
	# Remove any custom effects
	remove_custom_effects(target)

func apply_tick_effects(target):
	"""
	Apply any effects that happen each turn
	"""
	# Override this in derived effects or use triggers
	pass

func apply_custom_effects(target):
	"""
	Apply any custom effects beyond stat modifications
	"""
	# Override this in derived effects or use triggers
	pass

func remove_custom_effects(target):
	"""
	Remove any custom effects
	"""
	# Override this in derived effects or use triggers
	pass

func initialize(data: Dictionary):
	"""
	Initialize the status effect from a data dictionary
	"""
	id = data.get("id", "unknown_effect")
	name = data.get("name", "Unknown Effect")
	description = data.get("description", "")
	duration = data.get("duration", 1)
	permanent = data.get("permanent", false)
	icon_path = data.get("icon_path", "")
	
	# Set stat modifiers if provided
	if data.has("stat_mods"):
		stat_mods = data.stat_mods.duplicate()
	
	# Set source if provided
	if data.has("source"):
		source = data.source
	
	# Set triggers if provided
	if data.has("triggers"):
		triggers = data.triggers.duplicate()
