class_name TargetMarker
extends Node2D

# Visual properties
@export var marker_color: Color = Color(1.0, 0.2, 0.2, 0.8)  # Red by default
@export var pulse_speed: float = 2.0
@export var pulse_scale: float = 0.2

# Internal state
var base_scale: Vector2
var time: float = 0.0

# References
@onready var sprite: Sprite2D = $MarkerSprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	base_scale = scale
	
	# Set initial visibility
	visible = false
	
	# Create sprite if it doesn't exist
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "MarkerSprite"
		add_child(sprite)
		
		# Create a simple target texture
		var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		
		# Draw a simple circle target
		for x in range(64):
			for y in range(64):
				var distance = Vector2(x - 32, y - 32).length()
				if distance < 30 and distance > 26:
					image.set_pixel(x, y, Color.WHITE)
				elif distance < 20 and distance > 16:
					image.set_pixel(x, y, Color.WHITE)
				elif distance < 2:
					image.set_pixel(x, y, Color.WHITE)
		
		var texture = ImageTexture.create_from_image(image)
		sprite.texture = texture
	
	# Apply color
	sprite.modulate = marker_color

func _process(delta):
	if visible:
		time += delta
		# Pulse effect
		var pulse = sin(time * pulse_speed) * pulse_scale
		scale = base_scale * (1.0 + pulse)
		
		# Rotation effect
		rotation += delta * 0.5

func show_marker(color: Color = marker_color):
	"""
	Show the target marker with optional color override
	"""
	sprite.modulate = color
	visible = true
	
	# Start with scale 0 and grow
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", base_scale, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func hide_marker():
	"""
	Hide the target marker with animation
	"""
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): visible = false)

func flash_marker(flash_color: Color = Color.WHITE, duration: float = 0.3):
	"""
	Flash the marker with a color
	"""
	var original_color = sprite.modulate
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", flash_color, duration * 0.5)
	tween.tween_property(sprite, "modulate", original_color, duration * 0.5)
