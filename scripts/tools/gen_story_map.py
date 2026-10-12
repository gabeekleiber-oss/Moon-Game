#!/usr/bin/env python3
"""Regenerates data/story/story_map.json from docs/source/STORY.md (read-only) + the BEATS table below.
Line ids are s<NNN> where NNN = the 1-based index of the NON-BLANK line of STORY.md (so STORY.md must never be edited).
Edit BEATS if you learn a better mapping, then re-run: python3 scripts/tools/gen_story_map.py"""
import json, re, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
lines = [l.rstrip("\r\n") for l in (root / "docs/source/STORY.md").read_text(encoding="utf-8").splitlines() if l.strip()]
# line (1-based non-blank index) -> (acts, beats). A line may straddle acts: first act listed is where it starts.
B = {}
def put(rng, acts, beats):
    for n in (range(rng[0], rng[1] + 1) if isinstance(rng, tuple) else [rng]):
        B[n] = (acts, beats)
put(4, [1], ["intruder"]); put(5, [1], ["intruder"]); put(6, [1], ["finger"]); put(7, [1], ["letter"]); put(8, [1], ["letter"])
put((9, 25), [1], ["letter"]); put((26, 27), [1], ["shoo"]); put(28, [1], ["kitchen_items"]); put(29, [1], ["broom"])
put((30, 31), [1], ["tv_hit_1"]); put(32, [1], ["tv_hit_2"]); put(33, [1], ["tv_hit_2", "quit_call"])
put(34, [1], ["quit_call", "phone_throw"]); put(35, [1], ["phone_throw"]); put((36, 39), [1], ["tank_throw"]); put((40, 42), [1], ["family_loaded"])
put(43, [2], ["leave_house"]); put(44, [2], ["night_road", "woods_warning", "inn_passed", "stay_left", "racoon"]); put(45, [2], ["racoon", "road_game", "elsa_voice"])
put((46, 47), [3], ["arrive_5am"]); put(48, [3], ["arrive_5am", "path_up", "steps"]); put(49, [3], ["locked_doors", "staircase", "dome", "moon_eye"])
put(50, [3], ["moon_eye"]); put((51, 56), [3], ["friend_dialogue"]); put(57, [3], ["deny_threat"]); put((58, 59), [3], ["eye_vanishes"])
put((60, 63), [4], ["stumble"]); put(64, [4], ["switch", "lantern"]); put((65, 66), [4], ["birds"]); put((67, 68), [4], ["pick_up_mary_sue"])
put(69, [4], ["leave_the_girl"]); put(70, [4], ["defy"]); put((71, 72), [4], ["run_stairs"]); put((73, 74), [4], ["closet"]); put(75, [4], ["birds_sing"]); put(76, [4], ["cyclone"])
put(77, [5], ["follow", "identical_door", "kitchen", "seat", "hat"]); put((78, 80), [5], ["cake"]); put(81, [5], ["sing"]); put(82, [5], ["sing", "faces"])
put((83, 87), [5], ["frank_exchange"]); put(88, [5, 6], ["frank_leaves", "walk_forest", "clearing"])
put(89, [6], ["father_in_canoe"]); put((90, 98), [6], ["frank_argument"]); put(99, [6], ["approach_canoe"]); put(100, [6], ["approach_canoe", "speak_to_father"])
put((101, 102), [6], ["speak_to_father", "memory"]); put((103, 104), [6], ["plead"]); put((105, 107), [6], ["curse"]); put(108, [6], ["grackle_bass"])
put(109, [6], ["remembering"]); put(110, [6], ["deep_breath"]); put(111, [6], ["hello_son"])
put(112, [7], ["wake", "bed", "portraits", "stairs"]); put(113, [7], ["dining"]); put((114, 119), [7], ["breakfast_talk"]); put((120, 139), [7], ["gronfiser_verse"])
put((140, 143), [7], ["heir_answer"]); put((144, 149), [7], ["hard_question"]); put((150, 152), [7], ["elsa_glare"])
put(153, [8], ["notepad"]); put(154, [8], ["notepad", "military_gallery"]); put(155, [8, 9], ["bird_statues", "gold_statues", "funny_feeling", "plan"])
put(156, [9], ["plan", "family_bags", "lawn_dump"]); put(157, [9], ["lawn_dump"]); put((158, 163), [9], ["elsa_confrontation"])
put(164, [9], ["axe", "chop"]); put(165, [9], ["east_wing", "pot", "stairs_fall", "roll_pot", "light_fire", "pot_on"]); put(166, [9], ["oil_flute", "dance"]); put(167, [9], ["bed"])
LETTER = range(9, 26); VERSE = list(range(90, 96)) + list(range(121, 139)) + [142]
out = []
for n, text in enumerate(lines, 1):
    if n <= 3:                                   # header comment (2 lines) + title
        continue
    acts, beats = B[n]
    t = text.strip()
    kind = "letter" if n in LETTER else "verse" if n in VERSE else "speech" if t[:1] in "“”\"" else "narration"
    e = {"id": "s%03d" % n, "n": n, "act": acts[0], "beats": beats, "kind": kind, "starts": re.sub(r"\s+", " ", t)[:48]}
    if len(acts) > 1: e["also_acts"] = acts[1:]
    out.append(e)
doc = {"_comment": "Maps every line of docs/source/STORY.md (non-blank index n) to its act and beats. Mapping is best-effort at line level (long lines hold several beats). 'starts' is the first 48 chars, checked by tests/test_story_map. Regenerate with scripts/tools/gen_story_map.py. Never edit STORY.md.", "lines": out}
(root / "data/story/story_map.json").write_text(json.dumps(doc, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
beats = json.loads((root / "data/story/beats.json").read_text())["acts"]
used = {b for e in out for b in e["beats"]}
print("lines:", len(out), "| beats with NO source line (world-only):", [b["id"] for a in beats.values() for b in a["beats"] if b["id"] not in used])
