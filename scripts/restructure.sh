#!/usr/bin/env bash
set -euo pipefail

# Restructure script for aws-dataflow repository
# - Moves files into a production-like layout
# - Does not delete original files until moved
# - Removes old numbered directories only if empty

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Working in: $ROOT_DIR"

# Create destination directories
mkdir -p notebooks/exploration
mkdir -p src/etl/jobs
mkdir -p sql/queries
mkdir -p docs/assets/dashboards
mkdir -p docs/assets/diagrams
mkdir -p docs/assets/monitoring
mkdir -p scripts

# 1) Move ingestion (notebooks + scripts)
if [ -d "1.ingestion" ]; then
  echo "Moving 1.ingestion -> notebooks/exploration"
  # Move notebooks, python scripts and helper files
  shopt -s dotglob
  mv -v 1.ingestion/* notebooks/exploration/ || true
  shopt -u dotglob
fi

# 2) Move Glue job scripts (*.py) into src/etl/jobs
if [ -d "2.glue/scripts" ]; then
  echo "Moving 2.glue/scripts/*.py -> src/etl/jobs/"
  mkdir -p src/etl/jobs
  mv -v 2.glue/scripts/*.py src/etl/jobs/ 2>/dev/null || true
  # Move other useful files (json job defs) to scripts/ or keep in place
  if compgen -G "2.glue/scripts/*.json" > /dev/null; then
    echo "Moving 2.glue/scripts/*.json -> scripts/"
    mv -v 2.glue/scripts/*.json scripts/ 2>/dev/null || true
  fi
fi

# 3) Move Athena SQL files
if [ -d "3.athena" ]; then
  echo "Moving 3.athena/*.sql -> sql/queries/"
  mv -v 3.athena/*.sql sql/queries/ 2>/dev/null || true
  # Move any other README or docs
  if [ -f 3.athena/README.md ]; then
    mv -v 3.athena/README.md docs/ || true
  fi
fi

# 4) Move QuickSight assets whole folder
if [ -d "4.quicksight" ]; then
  echo "Moving 4.quicksight -> docs/assets/dashboards/"
  # Move contents into dashboards folder
  shopt -s dotglob
  mv -v 4.quicksight/* docs/assets/dashboards/ 2>/dev/null || true
  shopt -u dotglob
fi

# 5) Move architecture images (png, jpg, svg) to docs/assets/diagrams
if [ -d "architecture" ]; then
  echo "Moving images from architecture -> docs/assets/diagrams/"
  mkdir -p docs/assets/diagrams
  find architecture -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.svg" \) -exec mv -v {} docs/assets/diagrams/ \; || true
  # if there are non-image docs (README.md), keep them in architecture/ or move to docs/
  if [ -f architecture/README.md ]; then
    mv -vn architecture/README.md docs/architecture.README.md || true
  fi
fi

# 6) Move cloudwatch logs/images to docs/assets/monitoring
if [ -d "cloudwatch" ]; then
  echo "Moving cloudwatch -> docs/assets/monitoring/"
  shopt -s dotglob
  mv -v cloudwatch/* docs/assets/monitoring/ 2>/dev/null || true
  shopt -u dotglob
fi

# 7) Collect any top-level utility scripts into scripts/
# Move commonly used top-level .sh and .py files (excluding README, LICENSE)
for f in *.sh *.py; do
  if [ -f "$f" ]; then
    case "$f" in
      README.md|LICENSE) ;;
      *) echo "Moving $f -> scripts/"; mv -vn "$f" scripts/ || true ;;
    esac
  fi
done

# 8) Remove numbered directories if empty
for d in 1.ingestion 2.glue 3.athena 4.quicksight architecture cloudwatch; do
  if [ -d "$d" ]; then
    if [ -z "$(ls -A "$d")" ]; then
      echo "Removing empty directory: $d"
      rmdir "$d" || true
    else
      echo "Directory $d not empty, leaving in place (remaining files may need review)."
    fi
  fi
done

# 9) Final summary
echo "Reorganization complete. Current top-level layout:"
ls -la

echo "NOTE: Verify moved files and commit changes."

echo "Suggested next git commands:"
echo "  git add -A"
echo "  git commit -m 'Restructure: move files into production layout'"
echo "  git push origin <branch>"

exit 0
