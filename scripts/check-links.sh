#!/bin/bash

# check-links.sh
# Validates internal links in markdown files
# Usage: scripts/check-links.sh [directories...]

set -e

DIRECTORIES="${@:-en zh}"
ERRORS=0
WARNINGS=0

echo "LuaPath Link Checker"
echo "========================"
echo ""

# Get all markdown files
for dir in $DIRECTORIES; do
  if [ ! -d "$dir" ]; then
    echo "Directory not found: $dir"
    continue
  fi
  
  echo "Checking $dir/..."
  
  while IFS= read -r file; do
    # Extract all internal links from the file
    # Pattern: [text](relative/path.md#anchor) or [text](relative/path.md)
    # Note: a ']' inside a bracket expression must not be backslash-escaped.
    # GNU grep treats "\]" as the end of the expression, so the previous
    # pattern matched nothing at all and this check was silently vacuous.
    #
    # Fenced code blocks are stripped first: an expression like t[i](x) inside
    # a snippet is not a markdown link.
    links=$(awk '
      /^```/ { infence = !infence; next }
      infence { next }
      { print }
    ' "$file" 2>/dev/null \
      | sed -E 's/`[^`]*`//g' \
      | grep -oE '\[[^]]*\]\([^)]*\)' \
      | sed -E 's/.*\]\((.*)\)$/\1/' \
      | grep -v '^http' | grep -v '^mailto:' || true)
    
    # The extraction above already reduced each link to its URL.
    while IFS= read -r url; do
      if [ -z "$url" ]; then
        continue
      fi
      
      # Skip external links
      if [[ "$url" == http* ]] || [[ "$url" == mailto:* ]]; then
        continue
      fi
      
      # Skip anchor-only links
      if [[ "$url" == \#* ]]; then
        continue
      fi
      
      # Extract path and anchor
      path=$(echo "$url" | cut -d'#' -f1)
      anchor=$(echo "$url" | cut -d'#' -f2-)
      
      # Check if path exists
      if [ -n "$path" ]; then
        # Resolve relative path
        base_dir=$(dirname "$file")
        target="$base_dir/$path"
        
        if [ ! -e "$target" ]; then
          echo "  BROKEN: $file -> $path"
          ERRORS=$((ERRORS + 1))
        elif [ -n "$anchor" ] && [[ "$anchor" != "$url" ]]; then
          # The fragment itself is verified by scripts/check-anchors.lua, which
          # knows how to build a heading slug the way GitHub does.
          WARNINGS=$((WARNINGS + 1))
        fi
      fi
    done <<< "$links"
  done < <(find "$dir" -type f -name "*.md" | sort)
done

echo ""
echo "Summary"
echo "-------"
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ $ERRORS -gt 0 ]; then
  echo "LINK CHECK FAILED"
  exit 1
else
  echo "LINK CHECK PASSED"
  exit 0
fi
