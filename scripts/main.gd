extends Node2D

func _ready():
	# Get references
	var player_party = $Combat/PlayerParty
	var enemy_party = $Combat/EnemyParty
	
	# Initialize parties with test data
	player_party.initialize(true, GameData.create_test_player_party())
	enemy_party.initialize(false, GameData.create_test_enemy_party())

# For testing, add some basic controls
func _input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_R:
					# Restart scene
					get_tree().reload_current_scene()
				KEY_SPACE:
					# For debugging - force next turn
					var combat_system = $Combat/CombatSystem
					if combat_system.current_state == combat_system.CombatState.IN_PROGRESS:
						combat_system.start_next_turn()
