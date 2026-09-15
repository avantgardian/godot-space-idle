extends SceneTree

const TRAIL: GDScript = preload("res://scripts/components/trail_component.gd")

# Threshold from #295: 8× trails must stay < 0.08 ms/frame (80 µs).
const TRAIL_8X_BUDGET_US: int = 80
const ITERATIONS: int = 5000
const TRAIL_MAX: int = 600


func _init() -> void:
	var tree_root: Window = get_root()
	var holder: Node2D = Node2D.new()
	tree_root.add_child(holder)

	var trails: Array[TrailComponent] = []
	for _i: int in range(8):
		@warning_ignore("unsafe_cast")
		var t: TrailComponent = TRAIL.new() as TrailComponent
		holder.add_child(t)
		t.setup(Color.CYAN, Color.BLUE, 1.5, TRAIL_MAX)
		trails.append(t)

	# Warm-up (fill ring, populate _vis_buffer once).
	for t: TrailComponent in trails:
		for k: int in range(TRAIL_MAX * 2):
			t.record(Vector2(float(k % 100), float(k % 100)))
		t.clear()

	# Benchmark: record() across 8 trails.
	var start: int = Time.get_ticks_usec()
	for _rep: int in range(ITERATIONS):
		var pos: Vector2 = Vector2(float(_rep % 200), float(_rep % 200))
		for t: TrailComponent in trails:
			t.record(pos)
	var elapsed: int = Time.get_ticks_usec() - start

	# Use float division — elapsed / (ITERATIONS * 8) is the avg µs per record()
	# call (including throttled no-ops). The more relevant perf gate is the
	# total ms/frame for 8 trails.
	var total_calls: int = ITERATIONS * 8
	var avg_us: float = float(elapsed) / float(total_calls)
	var per_frame_us: float = float(elapsed) / float(ITERATIONS)
	var per_frame_ms: float = per_frame_us / 1000.0

	var passed: bool = per_frame_us < float(TRAIL_8X_BUDGET_US)

	var result: Dictionary = {
		"metric": "trail",
		"avg_us_per_record": avg_us,
		"per_frame_us_8x": per_frame_us,
		"per_frame_ms_8x": per_frame_ms,
		"budget_us_8x": TRAIL_8X_BUDGET_US,
		"iterations": ITERATIONS,
		"passed": passed,
	}
	print(JSON.stringify(result))

	if not passed:
		printerr(
			(
				"[bench_trails] FAIL: 8× trails %.3f ms/frame > %.3f ms budget"
				% [per_frame_ms, float(TRAIL_8X_BUDGET_US) / 1000.0]
			)
		)
	else:
		print(
			(
				"[bench_trails] PASS: 8× trails %.3f ms/frame (budget %.3f ms)"
				% [per_frame_ms, float(TRAIL_8X_BUDGET_US) / 1000.0]
			)
		)

	holder.queue_free()
	quit(0 if passed else 1)
