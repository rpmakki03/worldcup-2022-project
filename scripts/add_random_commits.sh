#!/usr/bin/env bash
set -euo pipefail

# Create randomized empty commits between two dates (inclusive).
# Defaults requested by user:
#   start: 2026-03-02
#   end:   2026-04-10
#   count: 12

START_DATE="2026-03-02"
END_DATE="2026-04-10"
COMMIT_COUNT=12
DRY_RUN=false

usage() {
  cat <<'EOF'
Usage: scripts/add_random_commits.sh [options]

Options:
  --start YYYY-MM-DD   Start date (default: 2026-03-02)
  --end YYYY-MM-DD     End date (default: 2026-04-10)
  --count N            Number of commits (default: 12)
  --dry-run            Print planned commit dates only
  -h, --help           Show this help

Examples:
  scripts/add_random_commits.sh
  scripts/add_random_commits.sh --count 20 --start 2026-01-01 --end 2026-02-01
  scripts/add_random_commits.sh --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --start)
      START_DATE="$2"
      shift 2
      ;;
    --end)
      END_DATE="$2"
      shift 2
      ;;
    --count)
      COMMIT_COUNT="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! command -v git >/dev/null 2>&1; then
  echo "git is required but not found in PATH." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required but not found in PATH." >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Run this script from inside a git repository." >&2
  exit 1
fi

if ! [[ "$COMMIT_COUNT" =~ ^[0-9]+$ ]] || [[ "$COMMIT_COUNT" -le 0 ]]; then
  echo "--count must be a positive integer." >&2
  exit 1
fi

# Generate sorted random unix timestamps between date boundaries.
RANDOM_EPOCHS=()
while IFS= read -r line; do
  RANDOM_EPOCHS+=("$line")
done < <(
  python3 - "$START_DATE" "$END_DATE" "$COMMIT_COUNT" <<'PY'
import random
import sys
from datetime import datetime, timedelta, timezone

start_raw, end_raw, count_raw = sys.argv[1], sys.argv[2], sys.argv[3]
count = int(count_raw)

start = datetime.strptime(start_raw, "%Y-%m-%d").replace(tzinfo=timezone.utc)
# Include full end date through 23:59:59 UTC
end = (datetime.strptime(end_raw, "%Y-%m-%d") + timedelta(days=1) - timedelta(seconds=1)).replace(tzinfo=timezone.utc)

if end < start:
    raise SystemExit("End date must be the same as or after start date.")

start_ts = int(start.timestamp())
end_ts = int(end.timestamp())
span = end_ts - start_ts + 1

if count > span:
    raise SystemExit("Date range is too small for unique timestamps at requested count.")

samples = sorted(random.sample(range(start_ts, end_ts + 1), count))
for ts in samples:
    print(ts)
PY
)

if [[ "${#RANDOM_EPOCHS[@]}" -ne "$COMMIT_COUNT" ]]; then
  echo "Failed to generate commit timestamps." >&2
  exit 1
fi

echo "Planned commits:"
for ts in "${RANDOM_EPOCHS[@]}"; do
  python3 - "$ts" <<'PY'
import sys
from datetime import datetime, timezone
print(datetime.fromtimestamp(int(sys.argv[1]), tz=timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"))
PY
done

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry run enabled. No commits created."
  exit 0
fi

for i in "${!RANDOM_EPOCHS[@]}"; do
  ts="${RANDOM_EPOCHS[$i]}"
  date_str="$(python3 - "$ts" <<'PY'
import sys
from datetime import datetime, timezone
print(datetime.fromtimestamp(int(sys.argv[1]), tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%S +0000"))
PY
)"

  GIT_AUTHOR_DATE="$date_str" \
  GIT_COMMITTER_DATE="$date_str" \
  git commit --allow-empty -m "chore: random activity commit $((i + 1))/$COMMIT_COUNT"
done

echo "Created $COMMIT_COUNT commits between $START_DATE and $END_DATE (UTC)."
