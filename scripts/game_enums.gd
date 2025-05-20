extends Node

# Character roles
enum Role {
	BLADE,    # Attackers
	BANNER,   # Defenders
	ECHO,     # Support
	FRACTURE, # Disruptors
	BOND      # Synergy
}

# Character tiers (singularity tiers from your design)
enum Tier {
	COMMON_ADVENTURER,  # Basic characters
	RECURRING_RESOURCE, # More tactical characters
	LOST_SEAL,        # Lore-bound figures
	SILENT_CORE,      # Rare entities
	LIVING_ERROR      # Singular characters that bend rules
}

# Ability types
enum AbilityType {
	BASIC,   # Automatically used in combat
	PASSIVE, # Triggered based on conditions
	ACTIVE   # Player-activated
}

# Ability action types
enum ActionType {
	ATTACK,  # Damage dealing
	DEFEND,  # Protection
	SUPPORT, # Healing/buffing
	UTILITY  # Special effects
}

# Targeting options
enum TargetType {
	SINGLE_ENEMY,    # Target one enemy (usually frontmost)
	ALL_ENEMIES,     # Target all enemies
	SINGLE_ALLY,     # Target one ally
	ALL_ALLIES,      # Target all allies
	LOWEST_ALLY,     # Target ally with lowest health
	SELF,            # Target self
	POSITION_BASED   # Target based on specific position logic
}

# Effect types
enum EffectType {
	DAMAGE,          # Dealing damage
	HEAL,            # Healing
	BUFF,            # Positive status effect
	DEBUFF,          # Negative status effect
	SPECIAL          # Unique effect with custom logic
}

# Conversion functions for string representation
func role_to_string(role_enum: int) -> String:
	match role_enum:
		Role.BLADE: return "Blade"
		Role.BANNER: return "Banner"
		Role.ECHO: return "Echo"
		Role.FRACTURE: return "Fracture"
		Role.BOND: return "Bond"
		_: return "Unknown"

func string_to_role(role_string: String) -> int:
	match role_string:
		"Blade": return Role.BLADE
		"Banner": return Role.BANNER
		"Echo": return Role.ECHO
		"Fracture": return Role.FRACTURE
		"Bond": return Role.BOND
		_: return -1

func tier_to_string(tier_enum: int) -> String:
	match tier_enum:
		Tier.COMMON_ADVENTURER: return "Common Adventurer"
		Tier.RECURRING_RESOURCE: return "Recurring Resource"
		Tier.LOST_SEAL: return "Lost Seal"
		Tier.SILENT_CORE: return "Silent Core"
		Tier.LIVING_ERROR: return "Living Error"
		_: return "Unknown"

func string_to_tier(tier_string: String) -> int:
	match tier_string:
		"Common Adventurer": return Tier.COMMON_ADVENTURER
		"Recurring Resource": return Tier.RECURRING_RESOURCE
		"Lost Seal": return Tier.LOST_SEAL
		"Silent Core": return Tier.SILENT_CORE
		"Living Error": return Tier.LIVING_ERROR
		_: return -1

# Helper functions for string to enum conversion (to add to GameEnums)
func string_to_action_type(action_string: String) -> int:
	match action_string:
		"attack": return GameEnums.ActionType.ATTACK
		"defend": return GameEnums.ActionType.DEFEND
		"support": return GameEnums.ActionType.SUPPORT
		"utility": return GameEnums.ActionType.UTILITY
		_: return GameEnums.ActionType.ATTACK  # Default

func string_to_target_type(target_string: String) -> int:
	match target_string:
		"single_enemy": return GameEnums.TargetType.SINGLE_ENEMY
		"all_enemies": return GameEnums.TargetType.ALL_ENEMIES
		"single_ally": return GameEnums.TargetType.SINGLE_ALLY
		"all_allies": return GameEnums.TargetType.ALL_ALLIES
		"lowest_ally": return GameEnums.TargetType.LOWEST_ALLY
		"self": return GameEnums.TargetType.SELF
		"position_based": return GameEnums.TargetType.POSITION_BASED
		_: return GameEnums.TargetType.SINGLE_ENEMY  # Default

func string_to_effect_type(effect_string: String) -> int:
	match effect_string:
		"damage": return GameEnums.EffectType.DAMAGE
		"heal": return GameEnums.EffectType.HEAL
		"buff": return GameEnums.EffectType.BUFF
		"debuff": return GameEnums.EffectType.DEBUFF
		"special": return GameEnums.EffectType.SPECIAL
		_: return GameEnums.EffectType.DAMAGE  # Default

func action_type_to_string(action_type_enum: int) -> String:
	match action_type_enum:
		ActionType.ATTACK: return "attack"
		ActionType.DEFEND: return "defend"
		ActionType.SUPPORT: return "support"
		ActionType.UTILITY: return "utility"
		_: return "unknown"

func target_type_to_string(target_type_enum: int) -> String:
	match target_type_enum:
		TargetType.SINGLE_ENEMY: return "single_enemy"
		TargetType.ALL_ENEMIES: return "all_enemies"
		TargetType.SINGLE_ALLY: return "single_ally"
		TargetType.ALL_ALLIES: return "all_allies"
		TargetType.LOWEST_ALLY: return "lowest_ally"
		TargetType.SELF: return "self"
		TargetType.POSITION_BASED: return "position_based"
		_: return "unknown"

func effect_type_to_string(effect_type_enum: int) -> String:
	match effect_type_enum:
		EffectType.DAMAGE: return "damage"
		EffectType.HEAL: return "heal"
		EffectType.BUFF: return "buff"
		EffectType.DEBUFF: return "debuff"
		EffectType.SPECIAL: return "special"
		_: return "unknown"

# Similar conversion functions for other enum types
# (Add as needed)
