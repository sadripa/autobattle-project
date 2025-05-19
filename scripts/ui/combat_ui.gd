extends CanvasLayer

# References to UI elements
@onready var turn_indicator = $TurnIndicator
@onready var state_label = $StateLabel
@onready var combat_log = $CombatLog

func _ready():
	# Get reference to combat system
	var combat_system = get_parent()
	
	# Connect signals
	combat_system.connect("combat_state_changed", Callable(self, "_on_combat_state_changed"))
	combat_system.connect("turn_started", Callable(self, "_on_turn_started"))
	combat_system.connect("combat_log_message", Callable(self, "_on_combat_log_message"))

func _on_combat_state_changed(new_state):
	# Update state label
	var state_text = "Unknown"
	match new_state:
		CombatSystem.CombatState.PREPARING: state_text = "Preparing"
		CombatSystem.CombatState.IN_PROGRESS: state_text = "In Progress"
		CombatSystem.CombatState.VICTORY: state_text = "Victory!"
		CombatSystem.CombatState.DEFEAT: state_text = "Defeat!"
		CombatSystem.CombatState.ESCAPED: state_text = "Escaped"
	
	state_label.text = "State: " + state_text

func _on_turn_started(character):
	# Update turn indicator
	if character:
		turn_indicator.text = "Turn: " + character.char_name + " (" + GameEnums.role_to_string(character.role) + ")"

func _on_combat_log_message(message):
	# Add message to combat log
	combat_log.text += message + "\n"
	
	# Auto-scroll to bottom
	combat_log.scroll_to_line(combat_log.get_line_count())
