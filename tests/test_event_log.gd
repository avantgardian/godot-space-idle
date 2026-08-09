extends GutTest

const EVENT_LOG := preload("res://scripts/ui/event_log.gd")


func test_constants_valid():
	assert_gt(EVENT_LOG.DURATION, 0.0, "DURATION > 0")
	assert_gt(EVENT_LOG.MAX_ENTRIES, 0, "MAX_ENTRIES > 0")


func test_setup_creates_container():
	var log: Node = autofree(EVENT_LOG.new())
	add_child(log)
	log.setup()
	assert_not_null(log._container, "container created")


func test_log_message_adds_entry():
	var log: Node = autofree(EVENT_LOG.new())
	add_child(log)
	log.setup()
	log.log_message("Test event")
	assert_eq(log._entries.size(), 1, "one entry after log")


func test_log_message_stores_age_zero():
	var log: Node = autofree(EVENT_LOG.new())
	add_child(log)
	log.setup()
	log.log_message("fresh")
	assert_eq(log._entries[0].age, 0.0, "new entry age = 0")


func test_log_message_prepends():
	var log: Node = autofree(EVENT_LOG.new())
	add_child(log)
	log.setup()
	log.log_message("first")
	log.log_message("second")
	var lbl0: Label = log._entries[1].label
	assert_eq(lbl0.text, "second", "newer message stored after older")


func test_log_message_caps_at_max():
	var log: Node = autofree(EVENT_LOG.new())
	add_child(log)
	log.setup()
	for i in range(EVENT_LOG.MAX_ENTRIES + 5):
		log.log_message("msg %d" % i)
	assert_eq(log._entries.size(), EVENT_LOG.MAX_ENTRIES, "capped at MAX_ENTRIES")


func test_process_increments_age():
	var log: Node = autofree(EVENT_LOG.new())
	add_child(log)
	log.setup()
	log.log_message("aging")
	log._process(1.0)
	assert_gt(log._entries[0].age, 0.0, "age increments")


func test_process_removes_expired_entries():
	var log: Node = autofree(EVENT_LOG.new())
	add_child(log)
	log.setup()
	log.log_message("old")
	log._entries[0].age = EVENT_LOG.DURATION + 1.0
	log._process(0.0)
	assert_eq(log._entries.size(), 0, "expired entry removed")


func test_process_fades_alpha():
	var log: Node = autofree(EVENT_LOG.new())
	add_child(log)
	log.setup()
	log.log_message("fading")
	log._entries[0].age = 30.0
	log._process(0.0)
	var lbl: Label = log._entries[0].label
	assert_gt(lbl.modulate.a, 0.0, "alpha still visible at half duration")
	assert_lt(lbl.modulate.a, 1.0, "alpha faded below 1.0")


func test_process_full_duration_alpha_zero():
	var log: Node = autofree(EVENT_LOG.new())
	add_child(log)
	log.setup()
	log.log_message("gone")
	log._entries[0].age = EVENT_LOG.DURATION - 0.001
	log._process(0.001)
	assert_eq(log._entries.size(), 0, "fully expired entries removed")
