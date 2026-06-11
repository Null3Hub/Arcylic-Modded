# Codebase Concerns

**Analysis Date:** 2026-06-11

## Tech Debt

**Dual Source Trees (src/ vs studio/AcrylicUI/):**
- Issue: `studio/AcrylicUI/` is a near-complete copy of `src/` with 32 Luau files. Changes in one tree must be manually mirrored to the other. A `build/source-parity-check.ps1` exists but only covers 13 of the files and is not run in CI.
- Files: `src/**`, `studio/AcrylicUI/**`
- Impact: Silent drift between trees causes studio users to get different behavior than executor users. Missing utilities (e.g., `studio/AcrylicUI/Utils/Create.luau` patches `src/Utils/Create.luau` but the base file may diverge).
- Fix approach: Eliminate the duplicate tree. Use a Rojo project that maps `src/` directly for both studio and executor builds. The `studio/AcrylicUI-patches/` directory should be merged into `src/` or applied as post-build transforms.

**Window.luau Monolith (1492 lines):**
- Issue: `src/Core/Window.luau` contains window creation, config save/load, auto-save, auto-load, keybind management, minimize/resize logic, mobile toggle, and all public API methods in a single file.
- Files: `src/Core/Window.luau`
- Impact: High cognitive load; difficult to test individual config or UI behaviors in isolation; merge conflicts likely when multiple features touch the window.
- Fix approach: Extract config management (`SaveConfig`, `LoadConfig`, `DeleteConfig`, `GetConfigs`, auto-save/load) into a dedicated `ConfigManager` module. Extract resize/drag setup into helpers.

**`start-rojo.bat` Hardcoded Path:**
- Issue: `start-rojo.bat` references `%USERPROFILE%\.aftman\bin\rojo.exe` which assumes aftman installed Rojo to a specific location. This is gitignored but still present in the working tree.
- Files: `start-rojo.bat`
- Impact: Fails on machines where Rojo is installed via a different method (e.g., `npm install -g rojo`, system PATH, or different aftman version).
- Fix approach: Use `rojo` directly (rely on PATH) or document the setup requirement. Remove the file from the working tree since it is gitignored.

**Stale Types Definitions:**
- Issue: `src/Types.luau` (line 44-53) declares `WindowConfig` with `Position: UDim2?` but the actual `WindowConfig` in `src/Core/Window.luau` (line 75-82) does not include `Position`. Conversely, `Window.luau`'s `WindowConfig` includes `Parent: Instance?` which IS in `Types.luau`. The `DropdownConfig` in `Types.luau` (line 84-94) includes `Search` which matches the implementation, but the `DropdownConfig` export in `src/Components/Dropdown.luau` (line 47-57) duplicates the type inline rather than importing from `Types.luau`.
- Files: `src/Types.luau`, `src/Core/Window.luau`, `src/Components/Dropdown.luau`
- Impact: Type definitions are not the source of truth; components define their own export types locally, making `Types.luau` a misleading reference.
- Fix approach: Either make `Types.luau` the single source of truth and import from it in all components, or remove `Types.luau` and let each component own its types.

## Known Bugs

**Config Load Callback Inconsistency:**
- Symptoms: When `LoadConfig` applies saved values, some components trigger their callbacks and some do not. Toggle and Dropdown pass `silent = true` to `SetValue`, so callbacks are suppressed. Slider and ColorPicker call `SetValue` without a `silent` parameter, which triggers callbacks during load.
- Files: `src/Components/Toggle.luau:156`, `src/Components/Dropdown.luau:257-261`, `src/Components/Slider.luau:248-251`, `src/Components/ColorPicker.luau:270`
- Trigger: Calling `window:LoadConfig("somename")` after components are registered.
- Workaround: Users must guard callbacks against load-time invocations manually.

**ColorPicker Popup Positioning:**
- Symptoms: The color picker palette popup uses `AbsolutePosition` to position itself relative to the screen, but does not account for the offset between the `ScreenGui` parent and the actual viewport. When the window is scrolled or the parent offset changes, the palette appears at the wrong location.
- Files: `src/Components/ColorPicker.luau:178-184`
- Trigger: Opening a color picker when the window has been scrolled or when the ScreenGui is parented to `CoreGui` vs `PlayerGui`.
- Workaround: None. The palette may appear detached from the preview swatch.

**README Misrepresents Destroy() Behavior:**
- Symptoms: README.md line 82 states "`Destroy()` is the cleanup API. It stops auto-save, destroys sections and components..." but the actual `Destroy()` method at `src/Core/Window.luau:1433-1490` does NOT call `SaveConfig` before stopping auto-save. If the user has unsaved changes, they are lost.
- Files: `README.md:82`, `src/Core/Window.luau:1433-1490`
- Trigger: User calls `window:Destroy()` expecting a final save.
- Workaround: Call `window:SaveConfig()` explicitly before `Destroy()`.

**test.project.json References Missing Path:**
- Symptoms: `test.project.json` (line 13) references `tests/smoke.client.luau` which does exist at `tests/smoke.client.luau`. However, the `build-rojo` CI job builds `test.project.json` to `build/test.rbxl`, and the Rojo build may fail if the smoke test requires runtime services not available at build time.
- Files: `test.project.json:13`, `tests/smoke.client.luau`
- Trigger: Running `rojo build test.project.json` in CI.
- Workaround: The build succeeds (Rojo only embeds the file, doesn't execute it), but the test itself requires a live Roblox environment.

## Security Considerations

**Remote Code Execution via Icon Packs:**
- Risk: `IconResolver._loadPack()` at `src/Utils/IconResolver.luau:211-251` fetches Lua source from hardcoded GitHub URLs and executes it via `loadstring` without any integrity verification, hash pinning, or sandboxing. A compromised or malicious icon pack repository could execute arbitrary code in the user's executor environment.
- Files: `src/Utils/IconResolver.luau:30-37` (PackURLs), `src/Utils/IconResolver.luau:224` (loadstring call)
- Current mitigation: None. The URLs point to specific GitHub repositories but have no content hash validation.
- Recommendations: Add SHA-256 hash pinning for each known pack URL. Consider fetching only asset IDs (JSON data) rather than executable Lua. At minimum, log a warning when executing remote code.

**Config Obfuscation Labeled as "Encryption":**
- Risk: `ConfigEncryption` at `src/Utils/ConfigEncryption.luau` uses a byte-shift cipher (shift each byte by a seed derived from data length) and labels the output as "encrypted." This is trivially reversible by anyone who reads the source code. Users may believe their config data is protected when it is not.
- Files: `src/Utils/ConfigEncryption.luau:56-68` (Encrypt), `src/Utils/ConfigEncryption.luau:1-4` (comment says "encryption")
- Current mitigation: The obfuscation prevents casual reading of config files. The `IsEncrypted` detection pattern (`^%{%d+%}%?`) correctly distinguishes encrypted from plain JSON.
- Recommendations: Rename the module to `ConfigObfuscation` or update comments to clearly state this is obfuscation, not encryption. Document that config data is readable by anyone with access to the source.

**RandomString Generates Control Characters:**
- Risk: `RandomString.new()` at `src/Utils/RandomString.luau:8-15` generates strings using `string.char(math.random(1, 7))`, which produces ASCII control characters (SOH, STX, ETX, EOT, ENQ, ACK, BEL). These are used for ScreenGui names and instance names to avoid detection by Roblox's anti-cheat or moderation systems. This is an intentional anti-detection technique but could trigger automated scanning tools.
- Files: `src/Utils/RandomString.luau:12`
- Current mitigation: None. The strings are short (30 chars) and only used internally.
- Recommendations: If anti-detection is not a requirement, use alphanumeric random strings instead. If it is required, document this as intentional behavior.

**Executor Environment Probing:**
- Risk: `safeGet()` at `src/Core/Window.luau:31-65` probes `_G`, `getgenv()`, and `getfenv()` for file system functions (`writefile`, `readfile`, `isfile`, `makefolder`, `isfolder`, `listfiles`, `delfile`). This is necessary for executor compatibility but exposes the library to environment manipulation.
- Files: `src/Core/Window.luau:31-65`, `src/Core/Window.luau:67-73`
- Current mitigation: All calls are wrapped in `pcall`.
- Recommendations: This is acceptable for the executor use case. Consider documenting which executor APIs are required for config functionality.

## Performance Bottlenecks

**Icon Pack Remote Fetching:**
- Problem: Each unique icon pack is fetched from GitHub via HTTP on first use, with no timeout configuration. If the network is slow or GitHub is unreachable, the UI will block until the fetch completes or fails.
- Files: `src/Utils/IconResolver.luau:84-128` (fetchUrl), `src/Utils/IconResolver.luau:211-251` (_loadPack)
- Cause: Synchronous HTTP request in the icon resolution path. The `_cache` table prevents re-fetching, but the first load for each pack blocks.
- Improvement path: Prefetch icon packs during initialization or offer a preloading API. Add configurable timeouts to the HTTP request. Cache fetched data to disk if executor file APIs are available.

**Window.new() Size Calculation:**
- Problem: `ResolveWindowSizes()` at `src/Core/Window.luau:186-224` is called during `Window.new()` and performs multiple viewport queries and clamping operations. This is not a bottleneck per se but runs on every window creation.
- Files: `src/Core/Window.luau:186-224`
- Cause: Linear computation, but called synchronously during UI construction.
- Improvement path: No immediate action needed. Consider caching viewport size if multiple windows are created.

## Fragile Areas

**Config Encryption/Decryption Round-Trip:**
- Files: `src/Utils/ConfigEncryption.luau:56-93`, `src/Core/Window.luau:1102-1187`
- Why fragile: The `Encrypt` function produces output starting with `{` followed by digits, then `}?`, then byte data. The `IsEncrypted` check uses the pattern `^%{%d+%}%?`. If a plain JSON config happens to start with `{` followed by only digits (e.g., `{"123":"value"}`), it would be misidentified as encrypted. In practice this is unlikely since JSON keys are quoted strings, but the coupling between the encryption format and the detection regex is fragile.
- Safe modification: If changing the encryption format, update both `Encrypt` and `IsEncrypted` together. Run the static contract test (`tests/static-contracts.test.js`) which verifies `IsEncrypted` is present.
- Test coverage: The static contract test checks that `IsEncrypted` exists but does not test its correctness.

**Shared ScreenGui Reference Counting:**
- Files: `src/Core/Window.luau:27-29` (class variables), `src/Core/Window.luau:334-348` (creation), `src/Core/Window.luau:1473-1486` (destruction)
- Why fragile: `Window._sharedScreenGuiCount` tracks how many windows share a single ScreenGui. If a window is destroyed without going through `Destroy()` (e.g., garbage collection), the count becomes stale and the shared ScreenGui is never cleaned up.
- Safe modification: Always call `window:Destroy()` to clean up. Do not rely on garbage collection.
- Test coverage: No tests verify reference counting behavior.

**BaseComponent DisconnectAll:**
- Files: `src/Core/BaseComponent.luau:102-107`
- Why fragile: `DisconnectAll()` iterates `self._connections` and calls `:Disconnect()` on each. If a connection was already disconnected externally, calling `:Disconnect()` again may error depending on the Roblox version.
- Safe modification: Wrap each disconnect in `pcall` or check `Connected` property before disconnecting.
- Test coverage: No tests verify cleanup behavior.

## Scaling Limits

**Config Elements Registry:**
- Current capacity: Unbounded table (`self._configElements` in `Window.luau`). Each flagged component registers here.
- Limit: No practical limit for typical UIs (tens to low hundreds of components). However, `SaveConfig` iterates all elements with `pairs()` on every save, and `LoadConfig` iterates all loaded data with `pairs()`.
- Scaling path: For UIs with hundreds of config flags, consider batching saves or using a dirty-flag approach to save only changed values.

**Icon Pack Cache:**
- Current capacity: Unbounded `_cache` table in `IconResolver.luau`. Each fetched pack stays in memory forever.
- Limit: Memory usage grows with each unique pack fetched. Icon packs can be large (thousands of entries).
- Scaling path: Implement LRU eviction or provide a `ClearCache()` API. Currently there is no way to release cached pack data.

## Dependencies at Risk

**External Icon Pack Repositories:**
- Risk: Icon packs are fetched from `raw.githubusercontent.com` URLs pointing to third-party repositories (`StyearX/Icons`, `Footagesus/Icons`). These repositories could be deleted, renamed, or compromised at any time.
- Impact: All remote icon resolution fails silently. The UI falls back to hiding icons (labels with no image).
- Migration plan: Bundle critical icon assets locally. Provide a fallback icon set. Consider mirroring pack data to a controlled location.

**Roblox Executor APIs:**
- Risk: The library depends on executor-specific APIs (`writefile`, `readfile`, `isfile`, `getgenv`, `gethui`, `loadstring`, `game["HttpGet"]`). These APIs are not standardized and may be removed or changed by executor developers.
- Impact: Config persistence and remote icon loading break silently.
- Migration plan: Wrap all executor API calls in `pcall` (already done). Document which features require which APIs. Provide graceful degradation when APIs are unavailable.

## Missing Critical Features

**Unit Testing:**
- Problem: The test suite consists of a 14-line smoke test (`tests/smoke.client.luau`) that only verifies the library requires successfully, and a 61-line static contract test (`tests/static-contracts.test.js`) that checks file contents. There are no unit tests for individual components, config serialization, icon resolution, or encryption.
- Blocks: Refactoring any component without manual regression testing. Changes to `ConfigEncryption`, `IconResolver`, or component `SetValue`/`GetValue` behavior cannot be verified automatically.

**CI Runtime Tests:**
- Problem: The CI pipeline (`.github/workflows/ci.yml`) runs static analysis (StyLua, Selene) and Rojo builds, but does not execute the smoke test or any runtime validation. The smoke test requires a live Roblox environment which CI does not provide.
- Blocks: Automated verification that the library actually works in a Roblox environment.

**Build/Bundle Script:**
- Problem: The README previously referenced `scripts/build-bundle.ps1` and `scripts/validate-bundle.ps1` (now removed per static contract test). The `src.lua.txt` distribution file exists but there is no documented process for generating it from `src/`.
- Blocks: Contributors cannot regenerate the distribution file after making changes.

## Test Coverage Gaps

**Config Serialization Round-Trip:**
- What's not tested: `SerializeValue`/`DeserializeValue` in `Window.luau` for `Color3`, `EnumItem`, and nested table values. The encryption/decryption round-trip for arbitrary JSON payloads.
- Files: `src/Core/Window.luau:143-184` (serialize/deserialize), `src/Utils/ConfigEncryption.luau:56-93`
- Risk: Data corruption during save/load cycles, especially for non-primitive types.
- Priority: High

**Component SetValue/GetValue During Config Load:**
- What's not tested: Whether `SetValue` with `silent = true` actually suppresses callbacks across all component types. Whether `LoadConfig` correctly applies values to components that register after the load call (pending config data path).
- Files: `src/Components/Toggle.luau:184-190`, `src/Components/Slider.luau:279-283`, `src/Components/Dropdown.luau:676-691`, `src/Core/Window.luau:1040-1068`
- Risk: Silent regressions in config restore behavior.
- Priority: High

**Icon Resolution Edge Cases:**
- What's not tested: Pack path parsing for malformed input (`"/name"`, `"pack/"`, `"pack:Name:extra"`), fallback behavior when remote fetch fails, cache invalidation, custom pack overrides of remote packs.
- Files: `src/Utils/IconResolver.luau:130-326`
- Risk: UI icons disappear or display incorrectly for edge-case inputs.
- Priority: Medium

**Window Lifecycle:**
- What's not tested: Multiple windows sharing a ScreenGui, window destruction while minimized, window destruction while config save is in progress, auto-save timer behavior after destroy.
- Files: `src/Core/Window.luau:27-29`, `src/Core/Window.luau:1289-1311`, `src/Core/Window.luau:1433-1490`
- Resource leaks or errors when windows are created and destroyed rapidly.
- Priority: Medium

**Dropdown Popup Positioning:**
- What's not tested: Dropdown open/up direction logic when near viewport edges, search filtering with special characters, multi-select state persistence across open/close cycles.
- Files: `src/Components/Dropdown.luau:366-403` (_PositionOptionsContainer)
- Risk: Dropdown options appear off-screen or clipped.
- Priority: Low

---

*Concerns audit: 2026-06-11*
