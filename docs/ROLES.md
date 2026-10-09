# ROLES (5 accounts, one owner per area)

| # | Role | Owns | Chapters |
|---|------|------|----------|
| 1 | **Lead / Core** | docs/*, autoload/*, project.godot, scripts/chapter_base.gd, scenes/ui/*, scenes/fx/postfx*, data/dialogue runner, scenes/main | Title screen, integration, QA/perf |
| 2 | **Assets / Audio** | scenes/props/*, scenes/characters/*, scenes/fx/moon*, assets/audio/*, Audio autoload | Shared kits first (moon+eye, chandelier, armor, birds, nests); then **Ch 10-11** |
| 3 | **Slice** | scenes/chapters/ch01_*, ch02_*, ch03_* | Ch 1-3 |
| 4 | **Mansion** | scenes/chapters/ch04_*, ch05_*, ch06_*, ch07_* | Ch 4-7 |
| 5 | **Dream/Day** | scenes/chapters/ch08_*, ch09_*, epilogue | Ch 8-9 + epilogue; later helps Ch 11 |

Rules
- Only edit files you own. Shared files (events.gd, game.gd, chapter_manager.gd, TASKS.md, HANDOFF.md) are append-only except for Lead.
- Need a prop/system from another role? Add a line to TASKS.md under them; use a placeholder box meanwhile.
- Chapter owners may create sub-scenes inside their own chapter folder freely.
- Lead resolves conflicts and approves DESIGN/ARCHITECTURE changes.
