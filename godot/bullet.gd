extends Area3D

@export var speed: float = 1000.0
@export var damage: int = 300

const Player = preload("res://player.gd")
const Enemy = preload("res://enemy.gd")

func _ready() -> void:
	connect("area_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(area: Area3D) -> void:
	if area is Player:
		area.emit_signal("take_damage", damage)
		queue_free()
	elif area is Enemy:
		area.emit_signal("bullet_hit")
		queue_free()

func _physics_process(delta: float) -> void:
	var tf = transform
	var forward = tf.basis * Vector3(0, 0, 1)
	tf.origin += forward.normalized() * speed * delta
	transform = tf

	if abs(tf.origin.z) > 1000.0:
		queue_free()
