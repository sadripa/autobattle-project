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

# NEW: Target Side - which party to target
enum TargetSide {
	NONE,              # For special condition abilities
	ALLIES,            # Player party
	ENEMIES,           # Enemy party
	ALLIES_AND_ENEMIES # Both parties
}

# NEW: Target Range - how to order the target array
enum TargetRange {
	NONE,   # For special condition abilities
	SELF,   # Starts with self, then closest to farthest
	CLOSE,  # Starts from frontmost (lowest index)
	MID,    # Starts from middle
	LONG,   # Starts from backmost (highest index)
	RANDOM  # Random ordering
}

# NEW: Target Section - filter based on position relative to first
enum TargetSection {
	NONE,   # No section filtering
	BEFORE, # Only characters before the first in original positions
	AFTER   # Only characters after the first in original positions
}

# NEW: Target Size - how many to select
enum TargetSize {
	SINGLE,   # First in array
	DOUBLE,   # First two
	TRIPLE,   # First three
	ADJACENT, # Context-dependent (2 if edge, 3 if middle)
	ALL       # All targets
}

# NEW: Target Filter - stat-based conditions
enum TargetFilter {
	NONE,            # No filtering
	LOWEST_HP,       # Lowest health percentage
	HIGHEST_HP,      # Highest health percentage
	HAS_DEBUFF,      # Has any debuff
	MISSING_HEALTH,  # Missing > 50% health
	HAS_ROLE,        # Specific role (defined in custom params)
	CUSTOM           # Custom filter function
}

# NEW: Target Priority - preference when multiple valid targets
enum TargetPriority {
	NONE,             # No priority
	PROTECT_VALUABLE, # Prioritize high-tier characters
	FINISH_WOUNDED,   # Prioritize low HP
	BREAK_FORMATION   # Prioritize middle positions
}

# NEW: Fallback Behavior - when no valid targets
enum Fallback {
	FAIL,        # Ability doesn't activate
	RANDOM_VALID, # Pick any valid target
	SELF,        # Target self instead
	WAIT         # Skip turn, try again
}

# NEW: Penetration - how ability affects multiple targets
enum Penetration {
	NONE,   # Stops at targets
	PIERCE, # Continues through
	CHAIN,  # Jumps to next valid
	SPLASH  # Affects adjacent after hit
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

# NEW: Conversion functions for new enums
func string_to_target_side(side_string: String) -> int:
	match side_string.to_lower():
		"none": return TargetSide.NONE
		"allies": return TargetSide.ALLIES
		"enemies": return TargetSide.ENEMIES
		"allies_and_enemies": return TargetSide.ALLIES_AND_ENEMIES
		_: return TargetSide.ENEMIES

func string_to_target_range(range_string: String) -> int:
	match range_string.to_lower():
		"none": return TargetRange.NONE
		"self": return TargetRange.SELF
		"close": return TargetRange.CLOSE
		"mid": return TargetRange.MID
		"long": return TargetRange.LONG
		"random": return TargetRange.RANDOM
		_: return TargetRange.CLOSE

func string_to_target_section(section_string: String) -> int:
	match section_string.to_lower():
		"none": return TargetSection.NONE
		"before": return TargetSection.BEFORE
		"after": return TargetSection.AFTER
		_: return TargetSection.NONE

func string_to_target_size(size_string: String) -> int:
	match size_string.to_lower():
		"single": return TargetSize.SINGLE
		"double": return TargetSize.DOUBLE
		"triple": return TargetSize.TRIPLE
		"adjacent": return TargetSize.ADJACENT
		"all": return TargetSize.ALL
		_: return TargetSize.SINGLE

func string_to_target_filter(filter_string: String) -> int:
	match filter_string.to_lower():
		"none": return TargetFilter.NONE
		"lowest_hp": return TargetFilter.LOWEST_HP
		"highest_hp": return TargetFilter.HIGHEST_HP
		"has_debuff": return TargetFilter.HAS_DEBUFF
		"missing_health": return TargetFilter.MISSING_HEALTH
		"has_role": return TargetFilter.HAS_ROLE
		"custom": return TargetFilter.CUSTOM
		_: return TargetFilter.NONE

func string_to_target_priority(priority_string: String) -> int:
	match priority_string.to_lower():
		"none": return TargetPriority.NONE
		"protect_valuable": return TargetPriority.PROTECT_VALUABLE
		"finish_wounded": return TargetPriority.FINISH_WOUNDED
		"break_formation": return TargetPriority.BREAK_FORMATION
		_: return TargetPriority.NONE

func string_to_fallback(fallback_string: String) -> int:
	match fallback_string.to_lower():
		"fail": return Fallback.FAIL
		"random_valid": return Fallback.RANDOM_VALID
		"self": return Fallback.SELF
		"wait": return Fallback.WAIT
		_: return Fallback.FAIL

func string_to_penetration(penetration_string: String) -> int:
	match penetration_string.to_lower():
		"none": return Penetration.NONE
		"pierce": return Penetration.PIERCE
		"chain": return Penetration.CHAIN
		"splash": return Penetration.SPLASH
		_: return Penetration.NONE

# Helper functions for string to enum conversion
func string_to_action_type(action_string: String) -> int:
	match action_string:
		"attack": return ActionType.ATTACK
		"defend": return ActionType.DEFEND
		"support": return ActionType.SUPPORT
		"utility": return ActionType.UTILITY
		_: return ActionType.ATTACK  # Default

func string_to_effect_type(effect_string: String) -> int:
	match effect_string:
		"damage": return EffectType.DAMAGE
		"heal": return EffectType.HEAL
		"buff": return EffectType.BUFF
		"debuff": return EffectType.DEBUFF
		"special": return EffectType.SPECIAL
		_: return EffectType.DAMAGE  # Default

func action_type_to_string(action_type_enum: int) -> String:
	match action_type_enum:
		ActionType.ATTACK: return "attack"
		ActionType.DEFEND: return "defend"
		ActionType.SUPPORT: return "support"
		ActionType.UTILITY: return "utility"
		_: return "unknown"

func effect_type_to_string(effect_type_enum: int) -> String:
	match effect_type_enum:
		EffectType.DAMAGE: return "damage"
		EffectType.HEAL: return "heal"
		EffectType.BUFF: return "buff"
		EffectType.DEBUFF: return "debuff"
		EffectType.SPECIAL: return "special"
		_: return "unknown"
