extends Enemy

@onready var spider_animation_player: AnimationPlayer = $entity_spider/AnimationPlayer
@onready var animation_tree: AnimationTree = $entity_spider/AnimationTree
@onready var spider_hp_bar: ProgressBar = $HP_bar/SubViewport/ProgressBar
@onready var spider_attack_cooldown: Timer = $AttackCooldown
@onready var spider_dodge_timer: Timer = $DodgeTimer
@onready var entity_spider: Node3D = $entity_spider

# Exported Spider-specific parameters
@export var spider_max_health: float = 50.0
@export var spider_damage: float = 10.0
@export var spider_points: int = 10
@export var spider_detection_range: float = 10.0
@export var spider_normal_speed: float = 3.0
@export var spider_retreat_speed: float = 5.0
@export var spider_critical_hp: float = 20.0
@export var spider_dodge_duration: float = 0.7

func _ready() -> void:
	# Set up references for base Enemy class
	self.animation_player = spider_animation_player
	self.hp_bar = spider_hp_bar
	self.attack_cooldown = spider_attack_cooldown
	self.dodge_timer = spider_dodge_timer
	self.entity_model = entity_spider
	
	# Set Spider-specific parameters
	max_health = spider_max_health
	health = max_health
	damage = spider_damage
	points = spider_points
	detection_range = spider_detection_range
	normal_speed = spider_normal_speed
	retreat_speed = spider_retreat_speed
	critical_hp = spider_critical_hp
	dodge_duration = spider_dodge_duration
	
	# Call parent ready
	super()

func _play_animation(anim_name: String) -> void:
	# Map generic animation names to Spider-specific ones
	match anim_name:
		"idle":
			animation_player.play("SpiderIdle")
		"walk":
			animation_player.play("SpiderWalkCycle")
		_:
			animation_player.play(anim_name)
