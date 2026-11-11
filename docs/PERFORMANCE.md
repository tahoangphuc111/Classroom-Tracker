# Interaction performance

## Changes

- Apple search prepares normalized tokens and Telex alternatives once per query. ASCII indices use the existing byte-search implementation; Unicode indices retain Swift string matching semantics. Relevance scoring and tie-break ordering are unchanged.
- Apple keeps filtered lists and section results per category, with source revision, query, subject and item count in the cache context. A same-count completion edit invalidates the result through the source revision. Selection reconciliation uses set intersection instead of scanning the list once per selected item.
- Android converts database entities on `Dispatchers.Default` and suppresses identical entity snapshots before conversion. Main-screen sorting and search run on that dispatcher through `produceState`; cancellation prevents an obsolete calculation from publishing its result after inputs change. The upcoming screen delegates filtering directly to `computeBuckets`, removing its duplicate search pass. Completed search prepares Telex alternatives once per query.

These changes follow [Apple's main-thread guidance](https://developer.apple.com/documentation/xcode/improving-app-responsiveness) and reduce repeated work in view calculations as described in [SwiftUI performance guidance](https://developer.apple.com/documentation/xcode/understanding-and-improving-swiftui-performance).

## Measurement (2026-11-11)

Host: arm64 macOS, Swift 6.4 / Xcode 27. Optimized (`-O`) standalone benchmark, same process and data for both implementations, median of five runs.

| Workload | Previous matcher | Prepared matcher |
| --- | ---: | ---: |
| 10,000 indices × 5 queries × 10 rounds | 1,324.47 ms | 131.77 ms |
| Average per query over 10,000 indices | 26.49 ms | 2.64 ms |

Matching is **10.05× faster** in this synthetic workload. Both paths assert identical match counts. This measures filtering only, excluding relevance scoring, sorting, layout and rendering; it is not an FPS measurement. Runtime results depend on device and data. The benchmark also checks Unicode, Telex, acronym and empty queries against the previous matcher.

The category-cache regression test performs 60 alternating category requests and checks that only three computations occur, then verifies invalidation after a source revision, query change and subject change.

## Validation

- macOS and iOS Release builds succeeded with code signing disabled.
- Apple core logic: 210 assertions passed; sync logic: 6 checks passed.
- Interaction regression tests and the matching benchmark passed.
- Android debug tests: 146 passed; release tests: 147 passed, including fused-filter parity across course selections and queries.

## Reproduce

From the repository root:

```sh
swiftc -O -disable-sandbox \
  -module-cache-path /tmp/classroom-perf-module-cache \
  -D CLASSROOM_TESTING \
  Tests/AppleInteractionPerformanceTests.swift \
  Shared/Models/*.swift Shared/Storage/*.swift \
  Shared/PlatformUICompat.swift Shared/WidgetViews/*.swift Shared/Network/*.swift \
  -o /tmp/classroom-interaction-tests
/tmp/classroom-interaction-tests
```

`CLASSROOM_TESTING` isolates persistence from installed app data. `-disable-sandbox` permits the local Swift preview compiler plugin to run when the compiler is already inside a restricted environment.

For actual frame-rate validation, use a Release build with a large assignment history and record scrolling, rapid query edits, tab switches and completion toggles in Instruments on Apple or a frame-timing trace on Android. Compare frame times and missed frames on the same device, refresh rate, dataset and interaction sequence. No device FPS capture was performed for these changes.
