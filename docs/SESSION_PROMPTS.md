# PROMPTS

Start or resume a task (attach context/<ID>.md):
```
Continue.
```
If a chat died before delivering the final zip, apply any `_start` / partial zips it did present, then resume with `make_context.sh <ID>` in a new chat.

Next step:
```
next
```
Report a problem:
```
Godot error after applying step NN: <paste output>. Fix it as one small step and deliver the zip.
```
If a reply came out as an essay instead of a zip:
```
Deliver the zip first, then max 5 lines.
```
If the agent asks for a file: copy that file's contents into the chat (or attach it).
