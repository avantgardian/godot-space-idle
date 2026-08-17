extends GutTest

const ROCKET := preload("res://scripts/components/rocket.gd")


func test_constants_are_valid():
	assert_gt(ROCKET.SPEED, 0.0, "SPEED > 0")
	assert_gt(ROCKET.HOMING_STRENGTH, 0.0, "HOMING_STRENGTH > 0")
	assert_gt(ROCKET.LIFETIME, 0.0, "LIFETIME > 0")
	assert_gt(ROCKET.COLLISION_RADIUS, 0.0, "COLLISION_RADIUS > 0")


func test_init_sets_position():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2(100, 200), Vector2(10, 0), null)
	assert_eq(r.position, Vector2(100, 200), "position set by init")


func test_init_sets_velocity():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2(30, 40), null)
	assert_eq(r._vel, Vector2(30, 40), "velocity stored")


func test_is_alive_defaults_true():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2.ZERO, null)
	assert_true(r.is_alive(), "rocket alive by default")


func test_disable_marks_dead():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2.ZERO, null)
	r.disable()
	assert_false(r.is_alive(), "rocket dead after disable")
	assert_false(r.visible, "rocket hidden after disable")


func test_get_vel_returns_stored():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2(50, -25), null)
	assert_eq(r.get_vel(), Vector2(50, -25), "get_vel returns stored velocity")


func test_set_vel_updates():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2.ZERO, null)
	r.set_vel(Vector2(99, 1))
	assert_eq(r._vel, Vector2(99, 1), "set_vel updates internal velocity")


func test_has_spawn_protection_initially():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2.ZERO, null)
	assert_true(r.has_spawn_protection(), "spawn protection active initially")


func test_spawn_protection_expires():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2.ZERO, null)
	r._spawn_protection = -0.01
	assert_false(r.has_spawn_protection(), "spawn protection expired")


func test_lifetime_decays():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2.ZERO, null)
	r._physics_process(1.0)
	assert_almost_eq(r._lifetime, ROCKET.LIFETIME - 1.0, 0.01, "lifetime decreases")


func test_rocket_dies_when_lifetime_expires():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2.ZERO, null)
	r._lifetime = 0.01
	r._physics_process(0.1)
	assert_false(r.is_alive(), "rocket dead after lifetime expires")


func test_moves_when_alive():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2(0, 0), Vector2(100, 0), null)
	r._physics_process(0.5)
	assert_gt(r._pos.x, 0.0, "rocket moves in velocity direction")


func test_homing_steers_toward_target():
	var r: Node2D = autofree(ROCKET.new())
	var target := Node2D.new()
	target.position = Vector2(500, 0)
	target.name = "Target"
	add_child(target)
	add_child(r)
	r.init(Vector2(0, 0), Vector2(50, 0), target)
	r._physics_process(0.5)
	assert_ne(r._vel.x, 50.0, "velocity changed by homing")


func test_speed_capped():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2(99999, 0), null)
	r._physics_process(0.1)
	assert_true(r._vel.length() <= ROCKET.SPEED * 1.01, "speed capped at SPEED")


func test_speed_cap_after_homing():
	var r: Node2D = autofree(ROCKET.new())
	var target := Node2D.new()
	target.position = Vector2(100, 0)
	target.name = "Target"
	add_child(target)
	add_child(r)
	r.init(Vector2(0, 0), Vector2.ZERO, target)
	r._physics_process(0.5)
	assert_true(r._vel.length() <= ROCKET.SPEED * 1.01, "speed capped after homing")


func test_mass_defaults_to_zero():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2.ZERO, null)
	assert_eq(r.mass, 0.0, "rocket mass = 0")


func test_disable_emits_resolved_once():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2.ZERO, null)
	var emissions: Array = []
	r.resolved.connect(func(reason): emissions.append(reason))
	r.disable()
	r.disable()
	assert_eq(emissions.size(), 1, "resolved emitted exactly once despite double disable")


func test_disable_passes_reason():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2.ZERO, null)
	var got: Array = []
	r.resolved.connect(func(reason): got.append(reason))
	r.disable(ROCKET.Resolution.HIT_TARGET)
	assert_eq(got, [ROCKET.Resolution.HIT_TARGET], "reason forwarded to listeners")


func test_disable_defaults_to_lost():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2.ZERO, null)
	var got: Array = []
	r.resolved.connect(func(reason): got.append(reason))
	r.disable()
	assert_eq(got, [ROCKET.Resolution.LOST], "default reason is LOST")


func test_lifetime_expiry_emits_depleted():
	var r: Node2D = autofree(ROCKET.new())
	add_child(r)
	r.init(Vector2.ZERO, Vector2.ZERO, null)
	var got: Array = []
	r.resolved.connect(func(reason): got.append(reason))
	r._lifetime = 0.01
	r._physics_process(0.1)
	assert_eq(got, [ROCKET.Resolution.DEPLETED], "lifetime expiry resolves with DEPLETED")
