extends Area3D

@export var speed: float = 600.0
@export var health: int = 1000
@export var bullet_scene: PackedScene
@export var shooting_point_path: NodePath

enum CameraMode {
	TOP,
	SIDE
}
@export var camera_mode: CameraMode = CameraMode.TOP

var shooting_point: Marker3D

signal take_damage(damage)

func change_camera_mode(new_mode: CameraMode) -> void:
	camera_mode = new_mode

func _ready() -> void:
	if shooting_point_path != NodePath(""):
		shooting_point = get_node(shooting_point_path) as Marker3D
	connect("take_damage", Callable(self, "_on_take_damage"))

func _on_take_damage(damage) -> void:
	health = max(health - damage, 0)
	if health == 0:
		queue_free()

func _physics_process(delta: float) -> void:
	var tf = transform
	match camera_mode:
		CameraMode.TOP:
			if Input.is_action_pressed("ui_up"):
				tf.origin.z -= speed * delta
			if Input.is_action_pressed("ui_down"):
				tf.origin.z += speed * delta
			if Input.is_action_pressed("ui_left"):
				tf.origin.x -= speed * delta
			if Input.is_action_pressed("ui_right"):
				tf.origin.x += speed * delta
		CameraMode.SIDE:
			if Input.is_action_pressed("ui_up"):
				tf.origin.y += speed * delta
			if Input.is_action_pressed("ui_down"):
				tf.origin.y -= speed * delta
			if Input.is_action_pressed("ui_left"):
				tf.origin.z += speed * delta
			if Input.is_action_pressed("ui_right"):
				tf.origin.z -= speed * delta
	transform = tf

	if shooting_point and Input.is_action_just_pressed("fire"):
		var sp = shooting_point as Marker3D
		var bullet_instance = bullet_scene.instantiate()
		bullet_instance.global_transform = sp.global_transform
		get_parent().add_child(bullet_instance)
