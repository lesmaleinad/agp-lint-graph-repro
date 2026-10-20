#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$PWD/.gradle-user-home}"
export REPRO_MODULES_ARG="-PmoduleCount=${MODULES:-1000}"
export REPRO_NODES_ARG="-PgraphNodes=${NODES:-100000}"
export REPRO_HEAP="-Xmx${HEAP:-6g}"

profiler_version=0.26.0
profiler="$PWD/.tools/gradle-profiler-$profiler_version/bin/gradle-profiler"
output="$PWD/results/local/profiler"
mkdir -p .tools "$output"
if [[ ! -x "$profiler" ]]; then
    curl --fail --location --retry 3 \
        "https://github.com/gradle/gradle-profiler/releases/download/v$profiler_version/gradle-profiler-$profiler_version.zip" \
        -o ".tools/gradle-profiler-$profiler_version.zip"
    unzip -q -o ".tools/gradle-profiler-$profiler_version.zip" -d .tools
fi

./gradlew help "$REPRO_MODULES_ARG" "$REPRO_NODES_ARG" \
    "-Dorg.gradle.jvmargs=$REPRO_HEAP -XX:+EnableDynamicAgentLoading" --no-configuration-cache --no-build-cache --quiet

"$profiler" --benchmark --project-dir "$PWD" \
    --gradle-user-home "$GRADLE_USER_HOME" \
    --scenario-file benchmark.scenarios --output-dir "$output" \
    --warmups "${WARMUPS:-3}" --iterations "${ITERATIONS:-5}" "$@"

printf '\nCompare the Median column in %s/benchmark.html\n' "$output"
