class_name CombatSpeedController
extends Control

# Speed settings
enum SpeedMode {
	QUARTER = 0,
	THIRD = 1,
	HALF = 2,
	NORMAL = 3,
	DOUBLE = 4,
	QUAD = 5,
	OCTUPLE = 6
}

# Speed values and labels
const SPEED_VALUES = {
	SpeedMode.QUARTER: 0.25,
	SpeedMode.THIRD: 0.33,
	SpeedMode.HALF: 0.5,
	SpeedMode.NORMAL: 1.0,
	SpeedMode.DOUBLE: 2.0,
	SpeedMode.QUAD: 4.0,
	SpeedMode.OCTUPLE: 8.0
}

const SPEED_LABELS = {
	SpeedMode.QUARTER: "1/4x",
	SpeedMode.THIRD: "1/3x",
	SpeedMode.HALF: "1/2x",
	SpeedMode.NORMAL: "1x",
	SpeedMode.DOUBLE: "2x",
	SpeedMode.QUAD: "4x",
	SpeedMode.OCTUPLE: "8x"
}

# Current state
var current_speed_mode: SpeedMode = SpeedMode.NORMAL
var is_playing: bool = true
var is_combat_finished: bool = false

# UI References
@onready var play_stop_button: TextureButton = $HBoxContainer/PlayStopButton
@onready var slower_button: TextureButton = $HBoxContainer/SlowerButton
@onready var speed_label: Label = $HBoxContainer/SpeedLabel
@onready var faster_button: TextureButton = $HBoxContainer/FasterButton

# Icons (to be set in inspector)
@export var play_icon: Texture2D
@export var stop_icon: Texture2D
@export var slower_icon: Texture2D
@export var faster_icon: Texture2D

# Combat system reference
var combat_system: CombatSystem

func _ready():
	# Connect button signals
	play_stop_button.pressed.connect(_on_play_stop_pressed)
	slower_button.pressed.connect(_on_slower_pressed)
	faster_button.pressed.connect(_on_faster_pressed)
	
	# Set button icons
	if slower_icon:
		slower_button.texture_normal = slower_icon
	if faster_icon:
		faster_button.texture_normal = faster_icon
	if play_icon:
		play_stop_button.texture_normal = play_icon
	
	# Set initial UI state
	_update_ui()
	
	# Get combat system reference
	var parent = get_parent()
	while parent and not parent is CombatSystem:
		parent = parent.get_parent()
	
	if parent:
		combat_system = parent
		# Connect to combat state changes
		combat_system.combat_state_changed.connect(_on_combat_state_changed)

func _on_play_stop_pressed():
	if is_combat_finished:
		return
		
	is_playing = !is_playing
	_apply_speed_change()
	_update_ui()
	_animate_button(play_stop_button)

func _on_slower_pressed():
	if is_combat_finished or current_speed_mode <= SpeedMode.QUARTER:
		return
		
	# Move to slower speed
	current_speed_mode = current_speed_mode - 1
	
	# If we were stopped, start playing
	if not is_playing:
		is_playing = true
	
	_apply_speed_change()
	_update_ui()
	_animate_button(slower_button)

func _on_faster_pressed():
	if is_combat_finished or current_speed_mode >= SpeedMode.OCTUPLE:
		return
		
	# Move to faster speed
	current_speed_mode = current_speed_mode + 1
	
	# If we were stopped, start playing
	if not is_playing:
		is_playing = true
	
	_apply_speed_change()
	_update_ui()
	_animate_button(faster_button)

func _apply_speed_change():
	var speed_multiplier = SPEED_VALUES[current_speed_mode] if is_playing else 0.0
	
	# Apply to engine time scale
	Engine.time_scale = speed_multiplier
	
	# If stopped, pause the combat system
	if combat_system:
		combat_system.set_process(speed_multiplier > 0)
		combat_system.set_physics_process(speed_multiplier > 0)
		
		# Also update turn duration for smoother speed changes
		if speed_multiplier > 0:
			combat_system.turn_duration = 0.8 / SPEED_VALUES[current_speed_mode]

func _update_ui():
	# Update play/stop button icon
	if is_playing:
		play_stop_button.texture_normal = stop_icon
	else:
		play_stop_button.texture_normal = play_icon
	
	# Update speed label - show stop status with current speed
	if is_playing:
		speed_label.text = SPEED_LABELS[current_speed_mode]
	else:
		speed_label.text = "Stop (" + SPEED_LABELS[current_speed_mode] + ")"
	
	# Update button states
	_update_button_states()

func _update_button_states():
	# Disable/enable buttons based on state
	var can_go_slower = current_speed_mode > SpeedMode.QUARTER and not is_combat_finished
	var can_go_faster = current_speed_mode < SpeedMode.OCTUPLE and not is_combat_finished
	
	slower_button.disabled = not can_go_slower
	faster_button.disabled = not can_go_faster
	play_stop_button.disabled = is_combat_finished
	
	# Update visual appearance
	slower_button.modulate.a = 1.0 if can_go_slower else 0.5
	faster_button.modulate.a = 1.0 if can_go_faster else 0.5
	play_stop_button.modulate.a = 1.0 if not is_combat_finished else 0.5

func _animate_button(button: TextureButton):
	# Small scale animation for feedback
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	var original_scale = button.scale
	tween.tween_property(button, "scale", original_scale * 1.15, 0.05)
	tween.tween_property(button, "scale", original_scale, 0.1)

func _on_combat_state_changed(new_state):
	# Check if combat is finished
	if new_state in [CombatSystem.CombatState.VICTORY, CombatSystem.CombatState.DEFEAT]:
		is_combat_finished = true
		
		# Reset time scale to normal when combat ends
		Engine.time_scale = 1.0
		
		# Update UI to reflect disabled state
		_update_button_states()
		
		# Optionally update the label to show combat is over
		speed_label.text = "Finished"

func reset():
	"""Reset the controller to default state"""
	current_speed_mode = SpeedMode.NORMAL
	is_playing = true
	is_combat_finished = false
	Engine.time_scale = 1.0
	_update_ui()
