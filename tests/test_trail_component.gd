extends GutTest

const TRAIL := preload("res://scripts/components/trail_component.gd")


func test_setup_creates_line2d():
	var t: Node2D = autofree(TRAIL.new())
	add_child(t)
	t.setup(Color.RED, Color.BLUE, 2.0, 100)
	assert_not_null(t._line, "Line2D child created")
	assert_eq(t._line.width, 2.0, "line width stored")


func test_setup_stores_max_points():
	var t: Node2D = autofree(TRAIL.new())
	add_child(t)
	t.setup(Color.RED, Color.BLUE, 1.0, 500)
	assert_eq(t._max_points, 500, "max_points stored")
	assert_eq(t._ring.size(), 500, "ring buffer sized")


func test_setup_fills_ring_with_zeros():
	var t: Node2D = autofree(TRAIL.new())
	add_child(t)
	t.setup(Color.RED, Color.BLUE, 1.0, 10)
	for i in range(10):
		assert_eq(t._ring[i], Vector2.ZERO, "ring slot %d zeroed" % i)


func test_setup_stride_defaults_to_1():
	var t: Node2D = autofree(TRAIL.new())
	add_child(t)
	t.setup(Color.RED, Color.BLUE, 1.0, 100)
	assert_eq(t._stride, 1, "stride = 1 for <= DOWNSAMPLE_THRESHOLD")


func test_setup_stride_for_large_max_points():
	var t: Node2D = autofree(TRAIL.new())
	add_child(t)
	t.setup(Color.RED, Color.BLUE, 1.0, 16000)
	assert_gt(t._stride, 1, "stride > 1 for > DOWNSAMPLE_THRESHOLD")


func test_record_fills_ring():
	var t: Node2D = autofree(TRAIL.new())
	add_child(t)
	t.setup(Color.RED, Color.BLUE, 1.0, 10)
	t.record(Vector2(1, 0))
	t.record(Vector2(2, 0))
	t.record(Vector2(3, 0))
	assert_eq(t._filled, 1, "one fill after 3 records (tick skip)")
	assert_eq(t._head, 1, "head at 1")


func test_record_sets_line_points():
	var t: Node2D = autofree(TRAIL.new())
	add_child(t)
	t.setup(Color.RED, Color.BLUE, 1.0, 10)
	t.record(Vector2(1, 0))
	t.record(Vector2(2, 0))
	t.record(Vector2(3, 0))
	t.record(Vector2(4, 0))
	assert_gt(t._line.points.size(), 0, "line has points after records")


func test_record_skips_when_fading():
	var t: Node2D = autofree(TRAIL.new())
	add_child(t)
	t.setup(Color.RED, Color.BLUE, 1.0, 10)
	t.record(Vector2(1, 0))
	t.record(Vector2(2, 0))
	var filled_before: int = t._filled
	t._fading = true
	t.record(Vector2(3, 0))
	t.record(Vector2(4, 0))
	assert_eq(t._filled, filled_before, "filled unchanged when fading")


func test_clear_resets_state():
	var t: Node2D = autofree(TRAIL.new())
	add_child(t)
	t.setup(Color.RED, Color.BLUE, 1.0, 10)
	t.record(Vector2(1, 0))
	t.record(Vector2(2, 0))
	t.record(Vector2(3, 0))
	t.clear()
	assert_eq(t._filled, 0, "filled reset to 0")
	assert_eq(t._head, 0, "head reset to 0")
	assert_eq(t._tick, 0, "tick reset to 0")
	for i in range(10):
		assert_eq(t._ring[i], Vector2.ZERO, "ring slot %d zeroed" % i)


func test_visible_slice_returns_subset():
	var t: Node2D = autofree(TRAIL.new())
	add_child(t)
	t.setup(Color.RED, Color.BLUE, 1.0, 100)
	for _i in range(5):
		t.record(Vector2(1, 0))
		t.record(Vector2(1, 0))
	var slice: PackedVector2Array = t._visible_slice()
	assert_eq(slice.size(), 5, "5 visible points from 5 stored records (stride=1)")
	assert_eq(slice[0], Vector2(1, 0), "first visible point correct")


func test_fade_out_guards_double_fade():
	var t: Node2D = autofree(TRAIL.new())
	add_child(t)
	t.setup(Color.RED, Color.BLUE, 1.0, 10)
	t._fading = true
	t.fade_out()
	assert_true(t._fading, "still fading - will call queue_free at end")


func test_visible_slice_wrap_around():
	var t: Node2D = autofree(TRAIL.new())
	add_child(t)
	t.setup(Color.RED, Color.BLUE, 1.0, 5)
	for i in range(10):
		t.record(Vector2(float(i), 0))
		t.record(Vector2(float(i), 0))
	assert_eq(t._filled, 5, "ring buffer capped at max_points")
	var slice: PackedVector2Array = t._visible_slice()
	assert_eq(slice.size(), 5, "visible slice has 5 points")
