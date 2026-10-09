# PROMPTS (regular chat)

## Start / resume any role (attach context/<role>_context.md first)
```
You are the <lead|assets|slice|mansion|dream> agent. Continue.
```

## Next step
```
next
```

## Report a problem
```
Godot error after applying step NN: <paste output>. Fix it (one small step), deliver the zip.
```

## First task per role (if checkpoint is empty)
- lead: "Start with L-02 dialogue runner, then L-03 interaction, then L-01 HUD."
- assets: "Start with A-01 the moon and eye as a reusable scene with a small API."
- slice: "Start with S-01 Chapter 1; first step: a runnable room shell with walls, floor and a lamp."
- mansion: "Start with M-01 Chapter 4; first step: exterior terrain, path and a block-out of the house."
- dream: "Start with D-01 Chapter 8; first step: lake scene with water plane, canoe and fog."

## Take over a role on a different account
Same as resume: build the bundle, attach it, same sentence. The bundle contains everything.
