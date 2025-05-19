class_name HealthBar
extends Control

# References
var progress_bar: ProgressBar

func _ready():
	progress_bar = $ProgressBar
	
func update_bar(current: int, maximum: int):
	# Update progress bar value
	progress_bar.max_value = maximum
	progress_bar.value = current
	
	# Update color based on health percentage
	var percentage = float(current) / float(maximum)
	var color = Color(1, 0, 0)  # Red at low health
	
	if percentage > 0.6:
		color = Color(0, 1, 0)  # Green at high health
	elif percentage > 0.3:
		color = Color(1, 1, 0)  # Yellow at medium health
	
	# Apply color
	progress_bar.modulate = color
