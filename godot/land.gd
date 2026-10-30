extends Node

@export var land_path: NodePath
@export var second_land_path: NodePath
@export var camera_path: NodePath
@export var player_path: NodePath

var land: Node3D
var second_land: Node3D
var camera: Camera3D
var player: Node3D

enum CameraMode { TOP, SIDE }

var camera_mode: int = CameraMode.TOP
var last_side_pos: float = 0.0
var last_top_pos: float = 0.0

signal camera_view_changed(new_mode)

func _ready() -> void:
	BenchmarkRandomTable.warm_up()

	if land_path != NodePath(""):
		land = get_node(land_path) as Node3D
	if second_land_path != NodePath(""):
		second_land = get_node(second_land_path) as Node3D
	if camera_path != NodePath(""):
		camera = get_node(camera_path) as Camera3D
	if player_path != NodePath(""):
		player = get_node(player_path) as Node3D
		connect("camera_view_changed", Callable(player, "change_camera_mode"))

func _physics_process(delta: float) -> void:
	_update_terrain(land, delta)
	_update_terrain(second_land, delta)

	if Input.is_action_just_pressed("camera_change") and camera and player:
		if camera_mode == CameraMode.TOP:
			var tf = camera.transform
			tf.basis = tf.basis.rotated(Vector3.FORWARD, PI/2)
			tf.basis = tf.basis.rotated(Vector3.RIGHT, PI/2)
			tf.origin += Vector3(1000, -1000, 0)
			camera.transform = tf

			var ptf = player.transform
			var side_pos = last_side_pos
			last_top_pos = ptf.origin.x
			ptf.origin = Vector3(0, side_pos, ptf.origin.z)
			player.transform = ptf

			camera_mode = CameraMode.SIDE
		elif camera_mode == CameraMode.SIDE:
			var tf = camera.transform
			tf.basis = tf.basis.rotated(Vector3.FORWARD, -PI/2)
			tf.basis = tf.basis.rotated(Vector3.UP, -PI/2)
			tf.origin += Vector3(-1000, 1000, 0)
			camera.transform = tf

			var ptf = player.transform
			var top_pos = last_top_pos
			last_side_pos = ptf.origin.y
			ptf.origin = Vector3(top_pos, 0, ptf.origin.z)
			player.transform = ptf

			camera_mode = CameraMode.TOP

		emit_signal("camera_view_changed", camera_mode)

func _update_terrain(terrain: Node3D, delta: float) -> void:
	if terrain:
		var tf = terrain.transform
		tf.origin.z += 80.0 * delta
		if tf.origin.z >= 32000.0:
			tf.origin.z -= 64000.0
		terrain.transform = tf
