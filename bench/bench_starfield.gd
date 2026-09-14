extends SceneTree

const STAR_FIELD: GDScript = preload("res://scripts/components/star_field.gd")

# Threshold from #296: StarField.generate() must stay < 150 ms wall time.
const GENERATE_BUDGET_MS: float = 150.0
const FOCUS_ITERS: int = 2000
const PARALLAX_ITERS: int = 2000


func _init() -> void:
	var root: Window = get_root()

	@warning_ignore("unsafe_cast")
	var field: Node2D = STAR_FIELD.new() as Node2D
	root.add_child(field)

	# Stub viewport size so headless without window still hits 1920×1080 path.
	# StarField.generate() already falls back to 1920×1080 when viewport < 64.

	var seed_val: int = 42
	var min_zoom: float = 0.3

	var gen_start: int = Time.get_ticks_usec()
	@warning_ignore("unsafe_method_access")
	field.generate(seed_val, min_zoom)
	var gen_elapsed_us: int = Time.get_ticks_usec() - gen_start
	var gen_ms: float = float(gen_elapsed_us) / 1000.0

	# Micro-benchmarks (negligible, but tracked for completeness).
	var parallax_start: int = Time.get_ticks_usec()
	for _i: int in range(PARALLAX_ITERS):
		@warning_ignore("unsafe_method_access")
		field.update_parallax(Vector2(float(_i % 100), float(_i % 100)), 1.0)
	var parallax_us: int = Time.get_ticks_usec() - parallax_start
	var parallax_avg_us: float = float(parallax_us) / float(PARALLAX_ITERS)

	var focus_start: int = Time.get_ticks_usec()
	for _i: int in range(FOCUS_ITERS):
		@warning_ignore("unsafe_method_access")
		field.set_focus(float(_i % 100) / 100.0)
	var focus_us: int = Time.get_ticks_usec() - focus_start
	var focus_avg_us: float = float(focus_us) / float(FOCUS_ITERS)

	var passed: bool = gen_ms < GENERATE_BUDGET_MS

	var result: Dictionary = {
		"metric": "starfield",
		"generate_ms": gen_ms,
		"generate_budget_ms": GENERATE_BUDGET_MS,
		"parallax_avg_us": parallax_avg_us,
		"focus_avg_us": focus_avg_us,
		"iterations_parallax": PARALLAX_ITERS,
		"iterations_focus": FOCUS_ITERS,
		"passed": passed,
	}
	print(JSON.stringify(result))

	if not passed:
		printerr(
			(
				"[bench_starfield] FAIL: generate() %.2f ms > %.2f ms budget"
				% [gen_ms, GENERATE_BUDGET_MS]
			)
		)
	else:
		print(
			(
				"[bench_starfield] PASS: generate() %.2f ms (budget %.2f ms)"
				% [gen_ms, GENERATE_BUDGET_MS]
			)
		)

	field.queue_free()
	quit(0 if passed else 1)
