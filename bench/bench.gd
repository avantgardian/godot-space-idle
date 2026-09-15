extends SceneTree

const TRAIL: GDScript = preload("res://scripts/components/trail_component.gd")
const STAR_FIELD: GDScript = preload("res://scripts/components/star_field.gd")
const ORBITAL_BODY: GDScript = preload("res://scripts/bodies/orbital_body.gd")
const COLLISION_MGR: GDScript = preload("res://scripts/controllers/collision_manager.gd")

const TRAIL_8X_BUDGET_US: int = 80
const GENERATE_BUDGET_MS: float = 150.0


func _init() -> void:
	var tree_root: Window = get_root()
	var holder: Node2D = Node2D.new()
	tree_root.add_child(holder)

	var results: Dictionary = {}

	# ── Trail bench ────────────────────────────────────────────────
	var trails: Array[TrailComponent] = []
	for _i: int in range(8):
		@warning_ignore("unsafe_cast")
		var t: TrailComponent = TRAIL.new() as TrailComponent
		holder.add_child(t)
		t.setup(Color.CYAN, Color.BLUE, 1.5, 600)
		trails.append(t)
	for t2: TrailComponent in trails:
		for k: int in range(1200):
			t2.record(Vector2(float(k % 100), float(k % 100)))
		t2.clear()
	var trail_iters: int = 5000
	var t_start: int = Time.get_ticks_usec()
	for _rep: int in range(trail_iters):
		var pos: Vector2 = Vector2(float(_rep % 200), float(_rep % 200))
		for t3: TrailComponent in trails:
			t3.record(pos)
	var t_elapsed: int = Time.get_ticks_usec() - t_start
	var trail_per_frame_us: float = float(t_elapsed) / float(trail_iters)
	var trail_passed: bool = trail_per_frame_us < float(TRAIL_8X_BUDGET_US)
	results["trail_per_frame_us_8x"] = trail_per_frame_us
	results["trail_per_frame_ms_8x"] = trail_per_frame_us / 1000.0
	results["trail_budget_us_8x"] = TRAIL_8X_BUDGET_US
	results["trail_passed"] = trail_passed

	# ── StarField bench ────────────────────────────────────────────
	@warning_ignore("unsafe_cast")
	var field: Node2D = STAR_FIELD.new() as Node2D
	root.add_child(field)
	var gen_start: int = Time.get_ticks_usec()
	@warning_ignore("unsafe_method_access")
	field.generate(42, 0.3)
	var gen_us: int = Time.get_ticks_usec() - gen_start
	var gen_ms: float = float(gen_us) / 1000.0
	var star_passed: bool = gen_ms < GENERATE_BUDGET_MS
	results["starfield_generate_ms"] = gen_ms
	results["starfield_budget_ms"] = GENERATE_BUDGET_MS
	results["starfield_passed"] = star_passed
	field.queue_free()

	# ── Physics (N-body + collision) bench ─────────────────────────
	var bodies: Array[Node2D] = []
	for i: int in range(8):
		@warning_ignore("unsafe_cast")
		var b: Node2D = ORBITAL_BODY.new() as Node2D
		@warning_ignore("unsafe_property_access")
		b.orbit_radius = 300.0 + float(i) * 80.0
		@warning_ignore("unsafe_property_access")
		b.orbit_period = 20.0 + float(i) * 4.0
		@warning_ignore("unsafe_property_access")
		b.mass = 1.0 + float(i) * 0.2
		@warning_ignore("unsafe_property_access")
		b.collision_radius = 12.0
		holder.add_child(b)
		bodies.append(b)
	@warning_ignore("unsafe_method_access", "unsafe_cast")
	var ref_gm: float = ORBITAL_BODY.reference_gm_default() as float
	for b4: Node2D in bodies:
		@warning_ignore("unsafe_method_access")
		b4.configure_planet_gravity(true, 0, 1.0, 150.0, ref_gm)
	for idx: int in range(bodies.size()):
		var peers: Array[Dictionary] = []
		for j: int in range(bodies.size()):
			if j == idx:
				continue
			var other: Node2D = bodies[j]
			@warning_ignore("unsafe_property_access")
			peers.append({"pos": other.position, "mass": other.mass})
		@warning_ignore("unsafe_method_access")
		bodies[idx].set_peer_data(peers)
	@warning_ignore("unsafe_method_access")
	ORBITAL_BODY.reset_planet_gravity_bench()
	var n_iters: int = 1000
	var n_start: int = Time.get_ticks_usec()
	for _k: int in range(n_iters):
		for b5: Node2D in bodies:
			@warning_ignore("unsafe_method_access")
			b5._physics_process(0.016)
	var n_elapsed: int = Time.get_ticks_usec() - n_start
	results["nbody_avg_us_per_frame"] = float(n_elapsed) / float(n_iters)
	@warning_ignore("unsafe_method_access", "unsafe_cast")
	results["nbody_inner_avg_us"] = ORBITAL_BODY.get_planet_gravity_bench_avg_us() as float

	var impact_fx: Node = Node.new()
	var event_log: Node = Node.new()
	holder.add_child(impact_fx)
	holder.add_child(event_log)
	var find_idx: Callable = func(_body: Node2D) -> int: return -1
	var trigger: Callable = func() -> void: pass
	@warning_ignore("unsafe_cast")
	var mgr: RefCounted = COLLISION_MGR.new(
		bodies, ORBITAL_BODY as GDScript, impact_fx, event_log, find_idx, trigger
	)
	for idx2: int in range(bodies.size()):
		bodies[idx2].position = Vector2(float(idx2) * 500.0, 0.0)
	var c_iters: int = 2000
	var c_start: int = Time.get_ticks_usec()
	var empty: Array = []
	for _k2: int in range(c_iters):
		@warning_ignore("unsafe_method_access")
		mgr.check_collisions(empty)
	results["collision_avg_us"] = float(Time.get_ticks_usec() - c_start) / float(c_iters)

	results["passed"] = trail_passed and star_passed

	print(JSON.stringify(results))
	if results["passed"]:
		print(
			(
				"[bench] PASS — trail %.3f ms/frame | starfield %.2f ms"
				% [results["trail_per_frame_ms_8x"], gen_ms]
			)
		)
	else:
		printerr(
			(
				"[bench] FAIL — trail %.3f ms/frame (budget %.3f) | starfield %.2f ms (budget %.2f)"
				% [
					results["trail_per_frame_ms_8x"],
					float(TRAIL_8X_BUDGET_US) / 1000.0,
					gen_ms,
					GENERATE_BUDGET_MS
				]
			)
		)

	holder.queue_free()
	quit(0 if results["passed"] else 1)
