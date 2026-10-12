# Human review gates

This file lists decisions and checks that cannot honestly be delegated to headless tests. It is a checklist for the project owner, not a new task queue. The executable queue remains docs/TASKS.md.

## What is safe to delegate
Agents may build reversible blockouts, placeholder geometry, data readers, tests, reusable systems, material experiments, lighting prototypes, and documentation when the relevant contract is clear. They may improve presentation inside established story facts and approved shock events.

## What requires human review before it becomes final
- Story and canon: edits to docs/source/STORY.md are prohibited. Changes to data/story/beats.json, docs/ACTS.md, room identity/footprint/door graph, or a new shock require explicit approval.
- Visual target: approve representative screenshots/video of the Wisconsin room, moon/eye, mansion foyer, dark Bird Hall, birthday kitchen replica, lake, and fire clearing before those standards are multiplied across the project.
- Photoreal characters: do not accept realistic faces until a real-window review confirms they are intentionally convincing or intentionally stylized. Use a clearly unfinished/obscured fallback otherwise; never use a real person's likeness.
- Asset licenses: CC0 is preferred. CC-BY requires preserving exact attribution and source URL. Do not use assets marked personal-use-only, unclear licenses, scraped content, or assets without provenance.
- Comfort and shocks: every major camera-directed event needs Reduced Motion review. Any new explicit scare/shock beyond the existing canon list needs approval first.
- Performance: targets in docs are budgets, not claims. Confirm with representative Windows hardware and record resolution, renderer, GPU/CPU, quality preset, route, and observed frame rate.
- Release: do not call the game shippable until clean-start and save/resume paths, all nine acts, Windows export, accessibility, license manifest, and final human visual review pass.

## Minimum real-window review loop
For each milestone build:
1. Launch the game from the Windows editor or exported executable, not only the headless test runner.
2. Capture a screenshot at normal player eye height for the milestone's hero view and one representative interaction.
3. Walk the intended route without a debug menu, objective marker, or external instruction.
4. Repeat the route with Reduced Motion enabled and verify that story information and navigation remain understandable.
5. Note visual artifacts, collision, texture scale/repetition, missing props, lighting leaks, sound-source confusion, camera discomfort, and any point where the next action is unclear.
6. Record results in the active task checkpoint using docs/HANDOFF.md's format. Mark untested items NOT RUN; never infer visual quality from a passing script.

## Owner download checklist
- [ ] Complete the Priority 1 items in docs/ASSET_DOWNLOAD_PACK.md.
- [ ] Drop each download in assets/_inbox/, keeping the request ID in its filename.
- [ ] Include the original asset page URL and author in a sibling .txt file when attribution is required or unclear.
- [ ] Commit/push the inbox files; the next agent imports them through scripts/tools/assets.py so license records and target paths stay aligned.
- [ ] After the first Act 1 vertical slice, review it in a real window before approving asset expansion to every room.
