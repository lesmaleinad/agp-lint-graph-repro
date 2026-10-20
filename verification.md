# Verification notes

`./compare-dry-run.sh` compares `lintRelease :module01:lintVitalRelease` with the guard off and on. It uses one app and one library, prints map sizes and skip decisions, and diffs task order and lint-vital enabled states. Task actions do not run.

To compare lint-vital alone:

```sh
./compare-dry-run.sh :module01:lintVitalRelease
```

The following checks passed with both guard settings on October 20, 2026, using the pinned AGP/Gradle/Kotlin versions, Corretto 22.0.2 and macOS 26.7.1:

| Check | Result |
| --- | --- |
| Release lint plus lint-vital; aggregate `lint` plus lint-vital | Matching task lists. Redundant lint-vital report/output tasks disabled. |
| Lint-vital alone; release assembly | Lint-vital stays enabled. |
| Debug assembly | No lint scheduled; app map still populated. |
| `checkReleaseBuilds = false` | App map empty. Release assembly schedules no lint; explicitly requested `lintRelease` still runs. |
| Debuggable or profileable release variant | Map empty; no lint-vital tasks registered. |
| Separate release and staging variants | Four map entries. Full lint disables only the matching variant's lint-vital report/output tasks; aggregate `lint` disables both. |
| Actual lint failure | Full lint exits with status 1 and identical XML/text reports, with release checks both enabled and disabled. Lint-vital alone also exits with status 1 and identical text reports. |

The variant and failure checks used a disposable copy. The fatal issue was a hardcoded `TextView` string, with `HardcodedText` selected as the only check and marked `severity="fatal"` in `lint.xml`. Each actual lint run used `--rerun-tasks --no-build-cache --no-configuration-cache`; reports were deleted first and required to be regenerated.
