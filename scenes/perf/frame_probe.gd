extends Node
## Frame-time probe (S-12). Loads one scene, lets it settle, samples frames, prints and saves a JSON report.
## Run windowed (needs a renderer): bash scripts/tools/perf.sh [scene ...]   Args: --scene=res:// --frames=120 --warmup=30 --out=/tmp/perf/x.json
## Under software GL (xvfb) frame ms is NOT meaningful; draw calls, objects and SceneStats are. Judge ms on a real GPU (unverified in a real window).

const FRAME_MS_BUDGET := 16.7   ## 60 fps, GTX 1660 class (docs/LIGHTING.md)
const DRAW_CALL_BUDGET := 2500  ## placeholder, human to confirm (same as SceneStats surfaces)

func _ready() -> void:
	var scene := "res://scenes/lighting/lighting_test_room.tscn"
	var frames := 120
	var warmup := 30
	var out := "/tmp/perf/probe.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="): scene = a.get_slice("=", 1)
		elif a.begins_with("--frames="): frames = int(a.get_slice("=", 1))
		elif a.begins_with("--warmup="): warmup = int(a.get_slice("=", 1))
		elif a.begins_with("--out="): out = a.get_slice("=", 1)
	var ps := load(scene) as PackedScene
	if ps == null:
		printerr("FAIL cannot load ", scene)
		get_tree().quit(1)
		return
	var inst := ps.instantiate()
	add_child(inst)
	for i in warmup:
		await get_tree().process_frame
	var ms: Array[float] = []
	var draws := 0
	var last := Time.get_ticks_usec()
	for i in frames:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		ms.append((now - last) / 1000.0)
		last = now
		draws = maxi(draws, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)))
	ms.sort()
	var avg := 0.0
	for v in ms:
		avg += v
	avg /= maxf(ms.size(), 1)
	var p95: float = ms[mini(int(ms.size() * 0.95), ms.size() - 1)]
	var stats := SceneStats.collect(inst)
	var report := {
		"scene": scene, "frames": frames, "avg_ms": snappedf(avg, 0.01), "p95_ms": snappedf(p95, 0.01), "max_ms": snappedf(ms[-1], 0.01),
		"max_draw_calls": draws, "stats": stats, "stats_violations": SceneStats.violations(stats),
		"over_frame_budget": p95 > FRAME_MS_BUDGET, "over_draw_budget": draws > DRAW_CALL_BUDGET,
		"renderer": RenderingServer.get_video_adapter_name(),
	}
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var f := FileAccess.open(out, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(report, "\t"))
	print("PERF ", scene.get_file(), " avg=", report["avg_ms"], "ms p95=", report["p95_ms"], "ms draws=", draws, " ", SceneStats.describe(stats), " adapter=", report["renderer"])
	get_tree().quit()
