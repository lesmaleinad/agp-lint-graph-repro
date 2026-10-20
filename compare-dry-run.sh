#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$PWD/.gradle-user-home}"
output="$PWD/results/local/dry-run"
mkdir -p "$output"
if [[ $# -eq 0 ]]; then set -- lintRelease :module01:lintVitalRelease; fi

for guard in false true; do
    echo "Guard=$guard"
    rm -rf .gradle/configuration-cache
    if ! ./gradlew "$@" --dry-run --console=plain --no-configuration-cache --no-build-cache \
        -PwithApp=true -PmoduleCount=2 -PgraphNodes=3 -Drepro.showLintState=true \
        "-Drepro.lintEmptyMapGuard=$guard" > "$output/guard-$guard.log" 2>&1; then
        cat "$output/guard-$guard.log" >&2
        exit 1
    fi
    grep '^LINT_MAP ' "$output/guard-$guard.log"
    sed -n '/^LINT_TASK /p' "$output/guard-$guard.log"
    grep -E '^(LINT_TASK |:.* SKIPPED$)' "$output/guard-$guard.log" > "$output/guard-$guard.tasks"
done

diff -u "$output/guard-false.tasks" "$output/guard-true.tasks"
echo "Task lists and lint-vital enabled states match. Logs: $output"
