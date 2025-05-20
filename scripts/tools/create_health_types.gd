@tool
extends EditorScript

# This script creates predefined health type resources in the project
# Run this script from the Editor -> Tools -> Create Health Types

const HEALTH_TYPES_PATH = "res://resources/health_types/"

func _run():
	print("Creating health type resources...")
	
	# Create directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(HEALTH_TYPES_PATH):
		DirAccess.make_dir_recursive_absolute(HEALTH_TYPES_PATH)
	
	# Create regular health type
	var regular = HealthType.new()
	regular.type = HealthType.Type.REGULAR
	regular.name = "Regular Health"
	regular.description = "Basic health with no special effects"
	regular.color = Color(0.8, 0.2, 0.2)  # Red
	save_resource(regular, "regular_health")
	
	# Create armor health type
	var armor = HealthType.new()
	armor.type = HealthType.Type.ARMOR
	armor.name = "Armor"
	armor.description = "Reduces incoming damage by 50%"
	armor.color = Color(1.0, 0.8, 0.0)  # Yellow
	armor.damage_reduction_percent = 0.5
	save_resource(armor, "armor")
	
	# Create shield health type
	var shield = HealthType.new()
	shield.type = HealthType.Type.SHIELD
	shield.name = "Shield"
	shield.description = "Regenerates 5 points per turn"
	shield.color = Color(0.2, 0.6, 1.0)  # Blue
	shield.regen_per_turn = 5
	save_resource(shield, "shield")
	
	# Create overhealth health type
	var overhealth = HealthType.new()
	overhealth.type = HealthType.Type.OVERHEALTH
	overhealth.name = "Overhealth"
	overhealth.description = "Temporary health that decays by 10 points after 2 turns"
	overhealth.color = Color(0.4, 1.0, 0.4)  # Green
	overhealth.decay_per_turn = 10
	overhealth.decay_delay = 2
	save_resource(overhealth, "overhealth")
	
	print("Health type resources created successfully!")

func save_resource(resource: Resource, name: String):
	var result = ResourceSaver.save(resource, HEALTH_TYPES_PATH + name + ".tres")
	if result == OK:
		print("  Saved resource: " + name)
	else:
		print("  Failed to save resource: " + name)
