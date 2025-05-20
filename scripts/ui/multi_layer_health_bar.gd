class_name MultiLayerHealthBar
extends Control

# Constants
const UNIT_SIZE = 10  # How much HP each visual unit represents
const UNITS_PER_ROW = 10  # Maximum units per row
const UNIT_WIDTH = 8  # Visual width of each unit in pixels
const UNIT_HEIGHT = 8  # Visual height of each unit in pixels
const UNIT_SPACING = 1  # Spacing between units in pixels
const ROW_SPACING = 2  # Spacing between rows of health units

# References
var health_data: MultiLayerHealth
var health_units = []  # 2D array of health unit nodes [row][column]

func _ready():
	# Initialize empty health bar
	# Set initial size for the background
	if has_node("Background"):
		$Background.custom_minimum_size = Vector2(88, 20)
		$Background.size = Vector2(88, 20)
	
	# Make sure we're visible
	self.visible = true
	
	# Try to get health data from parent right away
	var parent = get_parent()
	if parent is Character and parent.health != null:
		# Defer the update to ensure the UI is fully ready
		call_deferred("update_multi_layer_health", parent.health)

# Method to handle visibility changes
func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		# If becoming visible and we have health data, rebuild
		if is_visible_in_tree() and health_data:
			call_deferred("rebuild_health_display")

func update_multi_layer_health(multi_layer_health: MultiLayerHealth) -> void:
	"""
	Update the health bar to show the multi-layered health system
	"""
	
	if multi_layer_health == null:
		return
	
	if multi_layer_health.layers.size() == 0:
		return
	
	# Store the health data
	health_data = multi_layer_health
	
	# Ensure we're visible
	self.visible = true
	
	# Rebuild the display now
	rebuild_health_display()
	
	# Schedule another rebuild after a short delay
	# This helps with timing issues
	call_deferred("delayed_rebuild")

# Add a delayed rebuild method
func delayed_rebuild():
	await get_tree().create_timer(0.1).timeout
	rebuild_health_display()

func rebuild_health_display() -> void:
	"""
	Rebuild the entire health display based on current health data
	"""
	
	# Clear existing health units
	for row in health_units:
		for unit in row:
			unit.queue_free()
	health_units.clear()
	
	if not health_data:
		return
	
	if health_data.layers.size() == 0:
		return
	
	# Calculate total units and rows needed
	var total_units = []  # Array of [health_type, units_count] entries
	
	# Process from bottom to top (base health first)
	for i in range(health_data.layers.size()):
		var layer = health_data.layers[i]
		var units_for_layer = ceil(float(layer.current_amount) / float(UNIT_SIZE))
		if units_for_layer > 0:
			total_units.append([layer.health_type, units_for_layer])
	
	# Create the health units from bottom to top
	var current_row = 0
	var current_col = 0
	
	for layer_info in total_units:
		var health_type = layer_info[0]
		var units_count = layer_info[1]
		
		# Initialize new row if needed
		if health_units.size() <= current_row:
			health_units.append([])
		
		# Create units for this layer
		for i in range(units_count):
			# Move to next row if current row is full
			if current_col >= UNITS_PER_ROW:
				current_row += 1
				current_col = 0
				# Initialize new row if needed
				if health_units.size() <= current_row:
					health_units.append([])
			
			# Create health unit
			var unit = create_health_unit(health_type)
			add_child(unit)
			
			# Position the unit
			unit.position = Vector2(
				current_col * (UNIT_WIDTH + UNIT_SPACING),
				current_row * (UNIT_HEIGHT + ROW_SPACING)
			)
			
			# Store unit reference
			health_units[current_row].append(unit)
			
			# Move to next column
			current_col += 1
	
	# Update the control's minimum size
	var new_width = min(UNITS_PER_ROW * (UNIT_WIDTH + UNIT_SPACING) - UNIT_SPACING, 88)
	var new_height = max((current_row + 1) * (UNIT_HEIGHT + ROW_SPACING) - ROW_SPACING, 20)
	
	custom_minimum_size = Vector2(new_width, new_height)
	size = custom_minimum_size
	
	# Update background size
	if has_node("Background"):
		$Background.custom_minimum_size = custom_minimum_size
		$Background.size = custom_minimum_size

func create_health_unit(health_type: HealthType) -> ColorRect:
	"""
	Create a visual unit for displaying health
	"""
	var unit = ColorRect.new()
	unit.color = health_type.color
	unit.size = Vector2(UNIT_WIDTH, UNIT_HEIGHT)
	unit.custom_minimum_size = Vector2(UNIT_WIDTH, UNIT_HEIGHT)
	
	# Make sure the unit is visible
	unit.mouse_filter = Control.MOUSE_FILTER_PASS
	unit.visible = true
	
	# Optional: Add border
	var border = ReferenceRect.new()
	border.size = unit.size
	border.border_color = Color(0.2, 0.2, 0.2, 0.5)
	border.border_width = 1
	border.editor_only = false
	unit.add_child(border)
	
	# Optional: Add tooltip for health type
	unit.tooltip_text = health_type.name
	
	return unit

# Animation methods
func animate_damage(layer_index: int, amount: int) -> void:
	"""
	Animate health loss
	"""
	# This could animate units fading out or flashing
	# For simplicity, we'll just rebuild the display for now
	rebuild_health_display()

func animate_healing(layer_index: int, amount: int) -> void:
	"""
	Animate health gain
	"""
	# This could animate units fading in
	# For simplicity, we'll just rebuild the display for now
	rebuild_health_display()

func animate_layer_added(layer_index: int) -> void:
	"""
	Animate new health layer being added
	"""
	# This could animate units fading in with a special effect
	# For simplicity, we'll just rebuild the display for now
	rebuild_health_display()

func animate_layer_depleted(layer_index: int) -> void:
	"""
	Animate health layer being depleted
	"""
	# This could animate all units in the layer fading out
	# For simplicity, we'll just rebuild the display for now
	rebuild_health_display()
