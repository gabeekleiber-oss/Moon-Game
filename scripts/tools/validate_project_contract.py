#!/usr/bin/env python3
"""Preflight checks for immutable story source and the game's data/scene scaffold.

Run from any directory: python3 scripts/tools/validate_project_contract.py
This is a fast structural check, not a replacement for Godot's headless tests.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EXPECTED_STORY_BLOB = "3b2027c77b9c13ed2943169c3ba010cd1faad84b"
EXPECTED_ACTS = {
    "1": "act01_wisconsin",
    "2": "act02_road",
    "3": "act03_dome",
    "4": "act04_dark_rooms",
    "5": "act05_birthday",
    "6": "act06_lake",
    "7": "act07_morning",
    "8": "act08_inventory",
    "9": "act09_melting",
}
errors: list[str] = []


def check(condition: bool, message: str) -> None:
    """Record a failed invariant without hiding other preflight failures."""
    if not condition:
        errors.append(message)


def read_json(relative: str):
    """Read and parse one repository JSON file, recording a useful failure."""
    path = ROOT / relative
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"{relative}: {exc}")
        return None


def main() -> int:
    story = ROOT / "docs/source/STORY.md"
    check(story.is_file() and story.stat().st_size > 0,
          "docs/source/STORY.md must exist and be non-empty")
    try:
        committed_story = subprocess.run(
            ["git", "rev-parse", "HEAD:docs/source/STORY.md"],
            cwd=ROOT, capture_output=True, text=True, check=True
        ).stdout.strip()
        check(committed_story == EXPECTED_STORY_BLOB,
              "the committed original story blob changed; restore it byte-for-byte")
        diff = subprocess.run(
            ["git", "diff", "--quiet", "HEAD", "--", "docs/source/STORY.md"],
            cwd=ROOT
        )
        check(diff.returncode == 0,
              "working-tree story text differs from HEAD; do not edit the source")
        staged = subprocess.run(
            ["git", "diff", "--cached", "--quiet", "--", "docs/source/STORY.md"],
            cwd=ROOT
        )
        check(staged.returncode == 0,
              "staged story text differs from HEAD; do not commit source edits")
    except (OSError, subprocess.CalledProcessError) as exc:
        errors.append(f"could not verify the story's Git blob: {exc}")

    project_path = ROOT / "project.godot"
    project = project_path.read_text(encoding="utf-8") if project_path.exists() else ""
    check('config/features=PackedStringArray("4.3", "Forward Plus")' in project,
          "project.godot must retain the Godot 4.3 project feature contract")
    check('run/main_scene="res://scenes/main/main.tscn"' in project,
          "project.godot must point at the existing main scene")

    beats = read_json("data/story/beats.json")
    check(isinstance(beats, dict) and set(beats.get("acts", {}).keys()) == set(EXPECTED_ACTS),
          "data/story/beats.json must contain exactly acts 1 through 9")
    if isinstance(beats, dict):
        for act_id in EXPECTED_ACTS:
            act = beats.get("acts", {}).get(act_id, {})
            check(bool(act.get("beats")), f"act {act_id} has no story beats")
            ids = [b.get("id") for b in act.get("beats", [])]
            check(len(ids) == len(set(ids)), f"act {act_id} has duplicate beat IDs")

    index = read_json("data/world/_index.json")
    if isinstance(index, dict):
        rooms = index.get("rooms", [])
        check(len(rooms) >= 50, "world index unexpectedly lost spaces (expected at least 50)")
        check(len(rooms) == len(set(rooms)), "world index contains duplicate room IDs")
        for room_id in rooms:
            room = read_json(f"data/world/{room_id}.json")
            if isinstance(room, dict):
                check(room.get("id") == room_id,
                      f"data/world/{room_id}.json id does not match its index entry")
                # Mansion rooms use the shared architectural coordinate frame and
                # therefore require footprints. Exterior, road, Wisconsin, and
                # dream spaces intentionally use their own streamed/set-piece
                # layouts and keep this field null until their builders exist.
                if room.get("frame") == "mansion":
                    check(bool(room.get("footprint")),
                          f"data/world/{room_id}.json is missing its mansion footprint")

    for act_id, folder in EXPECTED_ACTS.items():
        scene = ROOT / "scenes/acts" / folder / f"{folder}.tscn"
        check(scene.is_file(), f"missing act scene: {scene.relative_to(ROOT)}")

    check(not (ROOT / "redesign").exists(),
          "do not create a parallel redesign/ directory; work in the existing project")

    if errors:
        print(f"PROJECT CONTRACT: FAIL ({len(errors)} issue(s))")
        for error in errors:
            print(f" - {error}")
        return 1
    print("PROJECT CONTRACT: PASS")
    print(" - original story source is unchanged")
    print(" - nine acts and beat IDs are structurally valid")
    print(" - indexed world spaces exist and match their IDs")
    print(" - all nine act scene stubs and the main scene are present")
    print(" - no parallel redesign directory")
    return 0


if __name__ == "__main__":
    sys.exit(main())
