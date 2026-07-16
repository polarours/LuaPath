# Beginner Exercises

## Concept Reinforcement

1. Implement `split(s, sep)` without external libraries.
2. Build `count_words(text)` using tables.
3. Write `clamp` and `lerp` utilities; include edge-case tests.

## Mini Project

Create a command-line “task tracker”:

- Add/list/remove tasks
- Persist tasks to plain text or simple serialization
- Keep module boundaries: parser, store, cli

## Debugging Tasks

1. Fix bug from accidental global variable overwrite.
2. Fix off-by-one loop bug in list rendering.
3. Fix incorrect `#t` usage on table with holes.

## Open-Ended Design Questions

1. How would you represent nullable fields safely with Lua tables?
2. What module API style is easiest to test and why?
3. Where should error handling boundaries live in small scripts?
