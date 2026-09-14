extends SceneTree

const ORBITAL_BODY: GDScript = preload("res://scripts/bodies/orbital_body.gd")
const COLLISION_MGR: GDScript = preload("res://scripts/controllers/collision_manager.gd")

const NBODY_ITERS: int = 2000
const COLLISION_ITERS: int = 2000


func _init() -> void:
	var root: Window = get_root()
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	# ── N-body (planet mutual gravity) micro-bench ─────────────────
	# Mirrors orbital_body.gd:283 bench block — measures inner loop cost.
	var bodies: Array[Node2D] = []
	for i: int in range(8):
		@warning_ignore("unsafe_cast")
		var b: Node2D = ORBITAL_BODY.new() as Node2D
		b.name = "Planet%d" % i
		@warning_ignore("unsafe_property_access")
		b.orbit_radius = 300.0 + float(i) * 80.0
		@warning_ignore("unsafe_property_access")
		b.orbit_period = 20.0 + float(i) * 4.0
		@warning_ignore("unsafe_property_access")
		b.mass = 1.0 + float(i) * 0.2
		@warning_ignore("unsafe_property_access")
		b.collision_radius = 12.0
		@warning_ignore("unsafe_property_access")
		b.planet_name = "P%d" % i
		holder.add_child(b)
		bodies.append(b)

	# Enable mutual gravity so the timed block in _physics_process runs.
	# Use REALISTIC mode, reference_gm from OrbitalBody helper.
	@warning_ignore("unsafe_method_access", "unsafe_cast")
	var ref_gm: float = ORBITAL_BODY.reference_gm_default() as float
	for b: Node2D in bodies:
		@warning_ignore("unsafe_method_access")
		b.configure_planet_gravity(true, 0, 1.0, 150.0, ref_gm)

	# Build peer data (each body sees the other 7).
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

	var nbody_start: int = Time.get_ticks_usec()
	for _k: int in range(NBODY_ITERS):
		# Refresh peer positions (simulates per-frame cost).
		for idx: int in range(bodies.size()):
			var peers2: Array[Dictionary] = []
			for j: int in range(bodies.size()):
				if j == idx:
					continue
				var other2: Node2D = bodies[j]
				@warning_ignore("unsafe_property_access")
				peers2.append({"pos": other2.position, "mass": other2.mass})
			@warning_ignore("unsafe_method_access")
			bodies[idx].set_peer_data(peers2)
		for b2: Node2D in bodies:
			@warning_ignore("unsafe_method_access")
			b2._physics_process(0.016)
	var nbody_elapsed: int = Time.get_ticks_usec() - nbody_start
	var nbody_avg_us: float = float(nbody_elapsed) / float(NBODY_ITERS)
	@warning_ignore("unsafe_method_access", "unsafe_cast")
	var inner_avg_us: float = ORBITAL_BODY.get_planet_gravity_bench_avg_us() as float

	# ── CollisionManager bench ─────────────────────────────────────
	@warning_ignore("unsafe_cast")
	var dummy_script: GDScript = ORBITAL_BODY as GDScript
	var impact_fx: Node = Node.new()
	var event_log: Node = Node.new()
	holder.add_child(impact_fx)
	holder.add_child(event_log)
	# Minimal stubs to satisfy CollisionManager call sites.
	impact_fx.set_meta("stub", true)
	event_log.set_meta("stub", true)
	# Provide no-op methods via adding script stubs is overkill; instead
	# wrap in a helper that replaces _impact_fx/_event_log calls with
	# callables that swallow.
	var find_idx: Callable = func(_body: Node2D) -> int: return -1
	var trigger: Callable = func() -> void: pass

	var mgr: RefCounted = COLLISION_MGR.new(
		bodies, dummy_script, impact_fx, event_log, find_idx, trigger
	)

	# Spread bodies apart so no actual collision resolution (just broadphase).
	for idx2: int in range(bodies.size()):
		bodies[idx2].position = Vector2(float(idx2) * 500.0, 0.0)

	var empty_asteroids: Array = []

	var coll_start: int = Time.get_ticks_usec()
	for _k2: int in range(COLLISION_ITERS):
		@warning_ignore("unsafe_method_access")
		mgr.check_collisions(empty_asteroids)
	var coll_elapsed: int = Time.get_ticks_usec() - coll_start
	var coll_avg_us: float = float(coll_elapsed) / float(COLLISION_ITERS)

	var result: Dictionary = {
		"metric": "physics",
		"nbody_avg_us_per_frame": nbody_avg_us,
		"nbody_inner_avg_us": inner_avg_us,
		"nbody_iters": NBODY_ITERS,
		"collision_avg_us": coll_avg_us,
		"collision_iters": COLLISION_ITERS,
		"passed": true,
	}
	print(JSON.stringify(result))
	print(
		(
			"[bench_physics] nbody %.2f µs/frame (inner %.2f µs) | collision %.2f µs"
			% [nbody_avg_us, inner_avg_us, coll_avg_us]
		)
	)

	holder.queue_free()
	quit(0)
