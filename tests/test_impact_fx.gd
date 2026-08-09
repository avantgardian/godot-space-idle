extends GutTest

const IMPACT_FX := preload("res://scripts/components/impact_fx.gd")


func test_spawn_ring_creates_line2d():
	var fx: Node = autofree(IMPACT_FX.new())
	add_child(fx)
	fx.spawn_ring(Color.RED, 3.0, 8, 2.0)
	assert_eq(fx._rings.size(), 1, "one ring spawned")
	assert_true(fx._rings[0].ring is Line2D, "child is Line2D")


func test_spawn_ring_segment_count():
	var fx: Node = autofree(IMPACT_FX.new())
	add_child(fx)
	fx.spawn_ring(Color.WHITE, 1.0, 16, 1.0)
	var ring: Line2D = fx._rings[0].ring
	assert_eq(ring.points.size(), 17, "16 segments + 1 closing point = 17")


func test_spawn_ring_circle_is_closed():
	var fx: Node = autofree(IMPACT_FX.new())
	add_child(fx)
	fx.spawn_ring(Color.WHITE, 1.0, 8, 1.0)
	var ring: Line2D = fx._rings[0].ring
	assert_almost_eq(ring.points[0].x, ring.points[8].x, 0.01, "circle is closed")


func test_spawn_ring_timer_stored():
	var fx: Node = autofree(IMPACT_FX.new())
	add_child(fx)
	fx.spawn_ring(Color.RED, 2.0, 4, 3.5)
	assert_almost_eq(fx._rings[0].timer, 3.5, 0.01, "timer stored")


func test_spawn_glow_creates_sprite():
	var fx: Node = autofree(IMPACT_FX.new())
	add_child(fx)
	fx.spawn_glow(Vector2(100, 200), 0.05, 10.0)
	assert_eq(fx._rings.size(), 1, "one glow spawned")
	assert_true("is_glow" in fx._rings[0], "glow entry has is_glow flag")


func test_spawn_glow_duration_depends_on_mass():
	var fx1: Node = autofree(IMPACT_FX.new())
	add_child(fx1)
	fx1.spawn_glow(Vector2.ZERO, 0.02, 1.0)
	var fx2: Node = autofree(IMPACT_FX.new())
	add_child(fx2)
	fx2.spawn_glow(Vector2.ZERO, 0.1, 1.0)
	var d1: float = fx1._rings[0].timer
	var d2: float = fx2._rings[0].timer
	assert_true(d2 >= d1, "larger mass = longer glow duration")


func test_process_decays_timer():
	var fx: Node = autofree(IMPACT_FX.new())
	add_child(fx)
	fx.spawn_ring(Color.WHITE, 1.0, 4, 2.0)
	var before: float = fx._rings[0].timer
	fx._process(0.5)
	assert_almost_eq(fx._rings[0].timer, before - 0.5, 0.01, "timer decays")


func test_process_removes_expired_rings():
	var fx: Node = autofree(IMPACT_FX.new())
	add_child(fx)
	fx.spawn_ring(Color.WHITE, 1.0, 4, 0.1)
	fx._process(0.2)
	assert_eq(fx._rings.size(), 0, "expired ring removed")


func test_ring_alpha_fades():
	var fx: Node = autofree(IMPACT_FX.new())
	add_child(fx)
	fx.spawn_ring(Color.WHITE, 1.0, 4, 2.0)
	fx._rings[0]["initial"] = 2.0
	fx._process(1.0)
	var ring: Line2D = fx._rings[0].ring
	assert_lt(ring.default_color.a, 0.6, "ring alpha faded")


func test_glow_alpha_fades():
	var fx: Node = autofree(IMPACT_FX.new())
	add_child(fx)
	fx.spawn_glow(Vector2.ZERO, 0.1, 10.0)
	fx._rings[0]["initial"] = 1.0
	fx._rings[0]["timer"] = 1.0
	fx._process(0.5)
	var sprite: Sprite2D = fx._rings[0].ring
	assert_lt(sprite.modulate.a, 1.0, "glow alpha faded")
