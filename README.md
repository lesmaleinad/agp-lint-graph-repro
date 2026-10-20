# AGP lint task-graph repro

AGP searches the task graph once per Android library, even when there are no lint-vital tasks to update. This repro measures the benefit of returning early when that task map is empty.

The proposed change inside [AGP's callback](https://android.googlesource.com/platform/tools/base/+/mirror-goog-studio-main/build-system/gradle-core/src/main/java/com/android/build/gradle/internal/lint/LintTaskManager.kt#302) is:

```kotlin
if (variantLintTaskToLintVitalTask.isEmpty()) return@whenReady
```

## Run

Use a full JDK (21 recommended), Android SDK platform 36 and build-tools 36.0.0. Set `JAVA_HOME` and `ANDROID_HOME`, and have `curl` and `unzip` on your path.

```sh
./benchmark.sh
```

The script downloads Gradle Profiler and compares the optimization off and on. The defaults are **1,000 modules and 100,000 tasks**, a 6 GB heap, three warmups and five measured builds per mode. Configuration caching is disabled and its saved state is deleted before each build. Build caching is disabled; measured builds run offline.

For a smaller run:

```sh
MODULES=10 NODES=10000 HEAP=2g ./benchmark.sh
```

You can also set `WARMUPS` and `ITERATIONS`. Keep the machine otherwise idle while measuring.

To check that lint behavior is preserved:

```sh
./compare-dry-run.sh
```

This compares release lint with the guard off and on, using one app and one library. It prints the map sizes and compares the task lists and lint-vital enabled states. Logs go in `results/local/dry-run/`. [Verification notes](verification.md) record the other checks we ran.

## Read the results

Open `results/local/profiler/benchmark.html`. Compare **Median** for `total execution time` between `optimization_off` and `optimization_on`. Times are in milliseconds; lower is faster. Warmups are excluded.

Recorded with the defaults on macOS 26.7.1 arm64, JDK 22.0.2, October 20, 2026:

| Scenario | Median |
| --- | ---: |
| Optimization off | 17.426 s |
| Optimization on | 7.685 s |

That is 55.9% less time, or 2.27× faster. The off builds varied from 8.66–26.47 s; on builds took 7.13–9.03 s. Repeat the comparison before drawing conclusions: the scenarios run in order, and machine load affects the timings. [Raw Profiler CSV](results.csv).

The tasks have no actions, so this measures configuration and task-graph overhead rather than Android compilation.

Each run replaces `results/local/profiler/`; copy it to save a run. Review logs for local paths before sharing them.

## How it works

[settings.gradle](settings.gradle) generates the modules; [build.gradle](build.gradle) gives them a shared Kotlin source file and builds the task graph. AGP and Kotlin versions are pinned in [gradle.properties](gradle.properties).

[LintGraphPatch.kt](buildSrc/src/main/kotlin/repro/LintGraphPatch.kt) uses Byte Buddy to try the change without rebuilding AGP. The switch is `-Drepro.lintEmptyMapGuard=true` or `false`. Both modes use the same instrumentation; only the `true` mode skips the callback when its map is empty.
