extends Area3D

@export var speed: float = 200.0
@export var enemy_type: EnemyType = EnemyType.TOP
@export var enemy_movement: EnemyMovement = EnemyMovement.LIN
@export var movement_mod: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var shooting_point_path: NodePath
@export var shooting_timer_path: NodePath
@export var bullet_scene: PackedScene

enum EnemyType {
	TOP,
	SIDE
}
enum EnemyMovement {
	LIN,
	COS,
	SIN,
	LOG,
	SQRT
}

var shooting_point: Marker3D
var shooting_timer: Timer
var time_elapsed: float = 0.0
static var _workload := BenchmarkRandomTable.workload_10k()
static var _movement_mod := BenchmarkRandomTable.movement_mod()
static var _movement_kind := BenchmarkRandomTable.movement_kind()
var workload_cursor: int = 0

signal bullet_hit

func _ready() -> void:
	var spawn_index := BenchmarkRandomTable.next_spawn_index()
	enemy_movement = _movement_kind[spawn_index & (_movement_kind.size() - 1)]
	var mod_mask := _movement_mod.size() - 1
	movement_mod = Vector3(
		_movement_mod[(spawn_index * 3) & mod_mask],
		_movement_mod[(spawn_index * 3 + 1) & mod_mask],
		_movement_mod[(spawn_index * 3 + 2) & mod_mask]
	)
	workload_cursor = spawn_index

	if shooting_point_path != NodePath(""):
		shooting_point = get_node(shooting_point_path) as Marker3D
	if shooting_timer_path != NodePath(""):
		shooting_timer = get_node(shooting_timer_path) as Timer
		shooting_timer.connect("timeout", Callable(self, "_on_shoot_timeout"))

	connect("bullet_hit", Callable(self, "_on_bullet_hit"))

func _on_bullet_hit() -> void:
	queue_free()

func _on_shoot_timeout() -> void:
	if shooting_point and bullet_scene:
		var instance = bullet_scene.instantiate()
		instance.global_transform = shooting_point.global_transform
		get_parent().add_child(instance)

func _physics_process(delta: float) -> void:
	time_elapsed += delta
	var dz = speed * delta
	var tf = transform
	
	var sum := 0.0
	var table := _workload
	var mask := table.size() - 1
	var cursor := workload_cursor
	for _i in range(7000):
		var i := table[cursor & mask]
		cursor += 1
		var f := float(i)
		sum += sqrt(f * PI) * cos(f * 0.01)
	workload_cursor = cursor

	if sum < 0.0:
		print("weird")

	match enemy_movement:
		EnemyMovement.LIN:
			tf.origin.z += dz

		EnemyMovement.COS:
			var phase = movement_mod.x * cos(movement_mod.y * time_elapsed + movement_mod.z) * 500.0
			if enemy_type == EnemyType.TOP:
				tf.origin.x = phase
			else:
				tf.origin.y = phase
			tf.origin.z += dz

		EnemyMovement.SIN:
			var phase = movement_mod.x * sin(movement_mod.y * time_elapsed + movement_mod.z) * 500.0
			if enemy_type == EnemyType.TOP:
				tf.origin.x = phase
			else:
				tf.origin.y = phase
			tf.origin.z += dz

		EnemyMovement.LOG:
			var new_z = tf.origin.z + dz
			var v = movement_mod.x * log(max(abs(new_z), 1.0) + movement_mod.z) * 200.0
			if enemy_type == EnemyType.TOP:
				tf.origin.x = v
			else:
				tf.origin.y = v
			tf.origin.z = new_z

		EnemyMovement.SQRT:
			var new_z2 = tf.origin.z + dz
			var v2 = movement_mod.x * (sqrt(abs(new_z2)) + movement_mod.z) * 100.0
			if enemy_type == EnemyType.TOP:
				tf.origin.x = v2
			else:
				tf.origin.y = v2
			tf.origin.z = new_z2

	transform = tf

	if tf.origin.z >= 800.0:
		queue_free()
