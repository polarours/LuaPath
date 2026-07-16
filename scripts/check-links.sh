#!/bin/bash

# check-links.sh
# Validates internal links in markdown files
# Usage: scripts/check-links.sh [directories...]

set -e

DIRECTORIES="${@:-en zh}"
ERRORS=0
WARNINGS=0

echo "lua-journey Link Checker"
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
    links=$(grep -oE '\[([^\]]+)\]\(([^\)]+)\]' "$file" 2>/dev/null | grep -v '^http' || true)
    
    while IFS= read -r link; do
      if [ -z "$link" ]; then
        continue
      fi
      
      # Extract the URL part
      url=$(echo "$link" | grep -oE '\([^)]+\)' | tr -d '()')
      
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
        
        if [ ! -f "$target" ]; then
          echo "  BROKEN: $file -> $path"
          ERRORS=$((ERRORS + 1))
        elif [ -n "$anchor" ] && [[ "$anchor" != "$url" ]]; then
          # TODO: Check if anchor exists in target file
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
