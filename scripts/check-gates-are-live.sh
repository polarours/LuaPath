#!/bin/bash

# check-gates-are-live.sh
# Proves that every gate in this repository can actually fail.
#
# A gate that cannot fail is worse than no gate at all: it prints "PASSED",
# it counts the checks it did not do, and everybody trusts it. The pitfall
# example check was in that state for months. It created a file where it
# meant to create a directory -- os.tmpname() hands back the name of a file
# it has already made -- so the sample was never written out, the sample was
# never run, and a sample that did nothing but raise an error still passed.
# The gate reported "Samples run: 101" while running nothing.
#
# So for every gate this script copies the repository, breaks exactly one
# thing that the gate is supposed to watch, runs the gate, and insists that
# the gate says no. A gate that stays quiet is reported and fails the run.
#
# Usage: scripts/check-gates-are-live.sh
#
#   LUA=lua5.4      interpreter for the gates that need one
#   LUA51=lua5.1    interpreter for the 5.1 baseline gates
#   LUACHECK=luacheck  the linter

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
LUA="${LUA:-lua5.4}"
LUA51="${LUA51:-lua5.1}"
LUACHECK="${LUACHECK:-luacheck}"

LIVE=0
DEAD=0
SKIPPED=0
BROKEN=0

cleanup() {
  rm -rf "$WORK"
}
trap cleanup EXIT

# An interpreter that rejects the 5.3 integer division syntax. The case that
# needs one has to be skipped when the machine has nothing older than 5.3:
# the defect it injects would simply compile there.
find_pre53_interpreter() {
  for candidate in "$LUA51" "$LUA"; do
    command -v "$candidate" >/dev/null 2>&1 || continue
    if ! printf 'return 7 // 2\n' | "$candidate" - >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

# The runtime label the example and stage tests expect, taken from the
# interpreter itself: "5.4", "5.1", "luajit".
runtime_of() {
  local banner
  # Lua 5.1 prints its version banner on stderr, the newer ones on stdout.
  banner="$("$1" -v 2>&1 | head -1)"
  case "$banner" in
    *LuaJIT*) echo "luajit" ;;
    "Lua "*) echo "$banner" | sed -E 's/^Lua ([0-9]+\.[0-9]+).*/\1/' ;;
    *) echo "5.4" ;;
  esac
}

# run_case <name> <setup> <defect> <gate>
#
# setup  -- a command run inside the fresh copy before the defect is added;
#           it may wipe the copy to keep a case fast
# defect -- a command that breaks one thing
# gate   -- a command that runs the gate; it has to fail
run_case() {
  local name="$1" setup="$2" defect="$3" gate="$4"

  # Every case gets a copy of its own. Reusing one copy means that a failed
  # cleanup leaves the previous case's damage behind, and the next defect
  # then does not apply -- which used to look like a dead gate.
  local repo
  repo="$(mktemp -d "$WORK/case.XXXXXX")"
  (cd "$ROOT" && tar --exclude=./.git -cf - .) | (cd "$repo" && tar -xf -)

  ( cd "$repo" && eval "$setup" ) >/dev/null 2>&1

  # The defect has to be applied before the gate is blamed. If the command
  # that breaks the repository did not do its job -- a leftover directory
  # makes "mv" fail, for instance -- the gate is right to pass and the case
  # says nothing about the gate at all.
  ( cd "$repo" && eval "$defect" ) >/dev/null 2>&1
  local defect_status=$?
  if [ "$defect_status" -ne 0 ]; then
    echo "  BROKEN  $name -- the defect did not apply, the case says nothing"
    BROKEN=$((BROKEN + 1))
    return
  fi

  ( cd "$repo" && eval "$gate" ) >/dev/null 2>&1
  local status=$?

  if [ "$status" -ne 0 ]; then
    echo "  live    $name"
    LIVE=$((LIVE + 1))
  else
    echo "  DEAD    $name -- the gate passed a repository it should have rejected"
    DEAD=$((DEAD + 1))
  fi
}

echo "LuaPath Gate Liveness Audit"
echo "============================="
echo ""
echo "Each case breaks one thing and insists that the gate notices."
echo ""

PRE53="$(find_pre53_interpreter || true)"

run_case "validate (5.4): a code block that does not parse" \
  ":" \
  "printf '\n\`\`\`lua\nlocal x = = 1\n\`\`\`\n' >> en/01-basics.md" \
  "$LUA scripts/validate.lua --all references pitfalls lua-mastery-roadmap"

if [ -n "$PRE53" ]; then
  run_case "validate (pre-5.3): a block that quietly needs Lua 5.3" \
    ":" \
    "printf '\n\`\`\`lua\nlocal q = 7 // 2\n\`\`\`\n' >> en/01-basics.md" \
    "$PRE53 scripts/validate.lua --all references pitfalls lua-mastery-roadmap"
else
  echo "  skip   validate (pre-5.3): no interpreter older than 5.3 is installed"
  SKIPPED=$((SKIPPED + 1))
fi

run_case "check-links: a link to a file that is not there" \
  ":" \
  "printf '\n[gone](no-such-file.md)\n' >> en/01-basics.md" \
  "bash scripts/check-links.sh en zh lua-mastery-roadmap pitfalls/en pitfalls/中文版 references"

run_case "check-anchors: a link to a heading that is not there" \
  ":" \
  "printf '\n[gone](01-basics.md#no-such-heading-xyz)\n' >> en/01-basics.md" \
  "$LUA scripts/check-anchors.lua"

run_case "check-example-chapters: an example pointing at a chapter that does not exist" \
  ":" \
  "sed -i 's|^-- Chapter: .*|-- Chapter: no-such-chapter|' examples/beginner/01-moving-average.lua" \
  "$LUA scripts/check-example-chapters.lua"

run_case "check-readme-stats: the README states a number that is wrong" \
  ":" \
  "sed -i 's/| Documentation | 22 chapters/| Documentation | 23 chapters/' README.md" \
  "$LUA scripts/check-readme-stats.lua"

run_case "check-readme-stats: the README drops a number altogether" \
  ":" \
  "sed -i '/| Glossary | 151 terms (EN + ZH) |/d' README.md" \
  "$LUA scripts/check-readme-stats.lua"

run_case "check-stage-refs: a reference to a stage that does not exist" \
  ":" \
  "printf '\n- Prerequisite: (Stage 99)\n' >> lua-mastery-roadmap/01-beginner/ini-parser/README.md" \
  "$LUA scripts/check-stage-refs.lua"

run_case "check-code-mirror: the two language tracks drift apart" \
  ":" \
  "printf '\n\`\`\`lua\nlocal mirror_probe = 1\n\`\`\`\n' >> zh/01-basics.md" \
  "$LUA scripts/check-code-mirror.lua"

run_case "check-stage-files: a README names a file that is not there" \
  ":" \
  "sed -i 's|01-ini-parser.lua      — Main implementation|no_such_file.lua      — Main implementation|' lua-mastery-roadmap/01-beginner/ini-parser/README.md" \
  "$LUA scripts/check-stage-files.lua"

run_case "check-pitfall-examples: a sample that raises an error" \
  ":" \
  "printf '\n\`\`\`lua\nerror(\"DELIBERATELY BROKEN SAMPLE\")\n\`\`\`\n' >> pitfalls/en/truthiness-pitfalls.md" \
  "$LUA scripts/check-pitfall-examples.lua"

run_case "check-stdlib-names: a standard library function that is in no Lua" \
  ":" \
  "printf '\nUse \`math.clamp\` to clamp a value.\n' >> en/09-standard-library.md" \
  "$LUA scripts/check-stdlib-names.lua"

run_case "check-capi-names: a C API function that does not exist" \
  ":" \
  "printf '\nAnd lua_pushstringX(L, s) directly.\n' >> en/11-lua-c-api.md" \
  "$LUA scripts/check-capi-names.lua"

run_case "check-capi-names: the directory it scans is gone" \
  ":" \
  "mv references references_moved" \
  "$LUA scripts/check-capi-names.lua"

run_case "check-stdlib-names: the directory it scans is gone" \
  ":" \
  "mv references references_moved" \
  "$LUA scripts/check-stdlib-names.lua"

run_case "check-code-mirror: the directory it scans is gone" \
  ":" \
  "mv references references_moved" \
  "$LUA scripts/check-code-mirror.lua"

run_case "parity: a chapter that exists only in English" \
  ":" \
  "rm zh/18-security-in-lua.md" \
  "$LUA scripts/parity.lua"

run_case "test-version-facts: a comparison table cell that is wrong" \
  ":" \
  "sed -i 's/| \*\*Generational GC\*\* | ✗ | ✗ | ✗ | ✓ | ✓ | ✗ |/| **Generational GC** | ✗ | ✗ | ✗ | ✗ | ✓ | ✗ |/' references/VERSION_DIFFERENCES.md" \
  "$LUA tests/test-version-facts.lua"

run_case "check-exercise-solutions: a reference solution that raises an error" \
  ":" \
  "printf '\n\`\`\`lua\nerror(\"DELIBERATELY BROKEN SOLUTION\")\n\`\`\`\n' >> en/exercises/beginner-solutions.md" \
  "$LUA scripts/check-exercise-solutions.lua"

run_case "check-external-links: a link to a host that does not exist" \
  "rm -rf en zh pitfalls lua-mastery-roadmap .github *.md; mkdir -p references; printf '[dead](https://no-such-host-luapath-gate-test.invalid/x)\n' > references/one.md" \
  ":" \
  "bash scripts/check-external-links.sh"

run_case "test-examples: an example that raises an error" \
  ":" \
  "printf '\nerror(\"DELIBERATELY BROKEN EXAMPLE\")\n' >> examples/beginner/01-moving-average.lua" \
  "$LUA scripts/test-examples.lua --interpreter $LUA --runtime $(runtime_of "$LUA") --root examples"

run_case "test-roadmap-stages: a stage test that raises an error" \
  ":" \
  "printf '\nerror(\"DELIBERATELY BROKEN STAGE TEST\")\n' >> lua-mastery-roadmap/01-beginner/ini-parser/tests/ini_parser_test.lua" \
  "$LUA tests/test-roadmap-stages.lua --interpreter $LUA --runtime $(runtime_of "$LUA") --root lua-mastery-roadmap"

run_case "lint: an unused variable" \
  ":" \
  "printf '\nlocal unused_variable_for_the_gate_probe = 1\n' >> examples/beginner/01-moving-average.lua" \
  "$LUACHECK examples scripts tests lua-mastery-roadmap"

echo ""
echo "Summary"
echo "-------"
echo "Gates proven live: $LIVE"
echo "Gates that passed a broken repository: $DEAD"
echo "Cases skipped: $SKIPPED"
echo "Cases whose defect did not apply: $BROKEN"
echo ""

if [ "$DEAD" -gt 0 ] || [ "$BROKEN" -gt 0 ]; then
  echo "GATE LIVENESS AUDIT FAILED"
  exit 1
fi

echo "GATE LIVENESS AUDIT PASSED"
exit 0
