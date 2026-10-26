#!/bin/bash

# check-external-links.sh
# Checks that the external links in the documentation still point at something.
#
# The internal link checker cannot see a page that has been taken down. The
# documentation used to point at eight such pages: the "try" playgrounds that
# lua.org and luajit.org used to have, a performance guide and a security page
# that LuaJIT has since removed, the site that hosted the Busted documentation,
# the PDF of the Lua history, the official forum -- whose domain no longer
# resolves -- and a book that is no longer listed anywhere. A reader who
# follows one of them gets a 404 and no lesson.
#
# This check is separate from the internal one because it needs the network:
# it is slower, and a host that is merely down would fail it. The hosts that
# answer 403 to a bot are listed below, together with the placeholders the
# templates contain.
#
# Usage: scripts/check-external-links.sh

# Directories whose markdown is scanned, and the root documents.
TARGETS="en zh references pitfalls lua-mastery-roadmap .github"
ROOT_DOCS="README.md README_zh-CN.md SECURITY.md CONTRIBUTING.md CODE_OF_CONDUCT.md CHANGELOG.md GLOSSARY.md GLOSSARY.zh-CN.md RELEASE.md"

# Hosts that refuse a bot with a 403. The links are fine in a browser, so
# they are reported as skipped rather than as broken.
BOT_BLOCKED_HOSTS="reddit.com stackoverflow.com"

# Placeholders that are meant to be filled in, not links.
skip_url() {
  local url="$1"
  case "$url" in
    *"<"*|*">"*) return 0 ;;                 # a template with a placeholder in it
    *"yourusername"*) return 0 ;;            # a template repository name
    *"valid-url"*) return 0 ;;
    http://localhost*|http://127.0.0.1*) return 0 ;;
    *example.com*) return 0 ;;
  esac
  local host
  host=$(printf '%s' "$url" | sed -E 's|^[a-z]+://([^/]+).*|\1|')
  for blocked in $BOT_BLOCKED_HOSTS; do
    if [ "$host" = "$blocked" ] || [ "$host" = "www.$blocked" ]; then
      return 0
    fi
  done
  return 1
}

echo "LuaPath External Link Checker"
echo "=============================="
echo ""

# Collect the URLs. Only the markdown link syntax is used for external links,
# and fenced code blocks are skipped: an URL in a snippet is not a link.
FILES=$(for dir in $TARGETS; do
  [ -d "$dir" ] || continue
  find "$dir" -type f -name "*.md"
done
for doc in $ROOT_DOCS; do
  [ -f "$doc" ] && echo "$doc"
done)

# Collect the URLs. A link is written in two ways in this repository: as a
# markdown link, and as a bare "**URL**: https://..." line. Both are picked
# up. Fenced code blocks are skipped: an URL in a snippet is not a link.
# Each URL is checked once: a site that is asked for the same page twenty
# times in a row starts dropping the later connections.
URLS=$(for file in $FILES; do
  awk '/^```/ { infence = !infence; next } infence { next } { print }' "$file" \
    | sed -E 's/`[^`]*`//g' \
    | grep -oE 'https?://[^[:space:]>")`]+' \
    | sed -E 's/\[.*$//; s/\]+$//; s/[.,;:]+$//'
done | sort -u)

TOTAL=0
CHECKED=0
BROKEN=0
SKIPPED=0

while IFS= read -r url; do
  [ -z "$url" ] && continue
  TOTAL=$((TOTAL + 1))
  if skip_url "$url"; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # A host that is slow or briefly down should not fail the run, so the URL
  # is tried three times before it is called broken. A status of 000 means
  # the connection never happened, which is nearly always the network and
  # never the page.
  code=""
  for attempt in 1 2 3; do
    code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 30 \
      --retry 1 --retry-delay 2 \
      -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36" \
      "$url" 2>/dev/null)
    [ "$code" = "200" ] && break
    sleep 3
  done

  CHECKED=$((CHECKED + 1))
  if [ "$code" != "200" ]; then
    echo "  BROKEN ($code): $url"
    BROKEN=$((BROKEN + 1))
  fi
done <<< "$URLS"

echo ""
echo "Summary"
echo "-------"
echo "URLs found:   $TOTAL"
echo "Checked:       $CHECKED"
echo "Skipped:       $SKIPPED"
echo "Broken:        $BROKEN"
echo ""

if [ "$BROKEN" -gt 0 ]; then
  echo "EXTERNAL LINK CHECK FAILED"
  exit 1
fi

echo "EXTERNAL LINK CHECK PASSED"
exit 0
