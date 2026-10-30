extends Node

@export var top_enemy_scene: PackedScene
@export var side_enemy_scene: PackedScene
@export var spawn_timer_path: NodePath
@export var benchmark_timer_path: NodePath
var benchmark_value: int = 10
var benchmark_sum: float = 0

static var _workload := BenchmarkRandomTable.workload_500()
static var _spawn_x := BenchmarkRandomTable.spawn_x()
static var _spawn_y := BenchmarkRandomTable.spawn_y()
static var _spawn_top := BenchmarkRandomTable.spawn_top()
static var _heavy_tick := BenchmarkRandomTable.heavy_tick()

var spawn_cursor: int = 0
var side_cursor: int = 0
var tick_cursor: int = 0
var workload_cursor: int = 0

var spawn_timer: Timer
var benchmark_timer: Timer

func _ready() -> void:
	if spawn_timer_path != NodePath(""):
		spawn_timer = get_node(spawn_timer_path) as Timer
		spawn_timer.connect("timeout", Callable(self, "_on_spawn_timeout"))
		
	if benchmark_timer_path != NodePath(""):
		benchmark_timer = get_node(benchmark_timer_path) as Timer
		benchmark_timer.connect("timeout", Callable(self, "_on_benchmark_timeout"))

func spawn_enemy(is_top: bool) -> void:
	var scene: PackedScene
	if is_top:
		scene = top_enemy_scene
	else:
		scene = side_enemy_scene
	if scene == null:
		return
	var instance = scene.instantiate()

	var tf = instance.transform

	if is_top:
		var x = _spawn_x[spawn_cursor & (_spawn_x.size() - 1)]
		tf.origin = Vector3(x, 0.0, -800.0)
	else:
		var y = _spawn_y[spawn_cursor & (_spawn_y.size() - 1)]
		tf.origin = Vector3(0.0, y, -800.0)
	spawn_cursor += 1

	instance.transform = tf
	get_parent().add_child(instance)

func _on_benchmark_timeout() -> void:
	for i in range(benchmark_value):
		spawn_enemy(true)
	for i in range(benchmark_value):
		spawn_enemy(false)
	benchmark_value += 10

func _on_spawn_timeout() -> void:
	var is_top := _spawn_top[side_cursor & (_spawn_top.size() - 1)] != 0
	side_cursor += 1
	spawn_enemy(is_top)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("benchmark_spawn"):
		for i in range(50):
			spawn_enemy(true)
		for i in range(50):
			spawn_enemy(false)
			
	var heavy_tick := _heavy_tick[tick_cursor & (_heavy_tick.size() - 1)] != 0
	tick_cursor += 1

	if heavy_tick:
		var acc: float = 0.0
		var local_data: Array = []
		var table := _workload
		var mask := table.size() - 1
		var cursor := workload_cursor

		for _i in range(500):
			var i := table[cursor & mask]
			cursor += 1
			var f := float(i)

			var x := sin(f * PI / 180.0) * sqrt(f + 1.0)
			acc += pow(x, 1.5)
			local_data.push_back(acc)

		workload_cursor = cursor
		benchmark_sum = acc
