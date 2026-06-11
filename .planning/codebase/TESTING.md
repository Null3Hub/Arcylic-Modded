# Testing Patterns

**Analysis Date:** 2026-06-11

## Test Framework

**Runner:** None (no Luau test framework installed)
**Assertion Library:** Roblox `assert()` built-in
**Test Runner in CI:** Node.js for static contract tests only

**Run Commands:**
```bash
# Static contract tests (Node.js)
node tests/static-contracts.test.js

# Rojo build verification (CI only)
rojo build default.project.json --output build/default.rbxl
rojo build studio.project.json --output build/studio.rbxl
rojo build test.project.json --output build/test.rbxl

# Formatting check
stylua --check src/ studio/

# Lint check
selene src/ studio/
```

## Test File Organization

**Location:** `tests/` directory (at repository root, NOT inside `src/`)

**Naming:**
- Luau test: `smoke.client.luau` (Rojo-compatible name)
- JS tests: `*.test.js` (Node.js convention)
- Python tests: `*_test.py` (in `.gitignore`)

**Structure:**
```
tests/
├── smoke.client.luau          # Rojo smoke test (compiled into RBXL)
├── static-contracts.test.js   # Static file/content assertions (Node.js)
├── icon_resolver_test.js      # Icon resolver tests (.gitignore)
└── icon_resolver_test.py      # Icon resolver tests (.gitignore)
```

## Test Types

### Smoke Test

**File:** `tests/smoke.client.luau`
**Purpose:** Verify module loading and API surface at runtime in Roblox Studio
**Framework:** Raw `assert()` calls (no test framework)
**Project:** `test.project.json` (compiles into StarterPlayerScripts)

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = require(ReplicatedStorage:WaitForChild("AcrylicUI"))

assert(type(Library) == "table", "AcrylicUI should require to a table")
assert(type(Library.CreateWindow) == "function", "CreateWindow should be available")
assert(type(Library.new) == "function", "new should be available")
assert(type(Library.AddIcons) == "function", "AddIcons should be available")
assert(type(Library.SetIconsType) == "function", "SetIconsType should be available")
assert(type(Library.GetInfo) == "function", "GetInfo should be available")

local info = Library.GetInfo()
assert(type(info) == "table", "GetInfo should return a table")
assert(info.Author == "Arcylic-Modded", "Author should stay stable")
```

**What It Tests:**
- Module requires without errors
- Public API functions exist
- Metadata (Author) is correct

### Static Contract Tests

**File:** `tests/static-contracts.test.js`
**Purpose:** Verify source file content meets architectural contracts
**Framework:** Node.js built-in `assert` module
**Runner:** `node tests/static-contracts.test.js`

```javascript
const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), "utf8");
}

function assertIncludes(file, text) {
  assert.ok(read(file).includes(text), `${file} should include ${text}`);
}

function assertNotIncludes(file, text) {
  assert.ok(!read(file).includes(text), `${file} should not include ${text}`);
}
```

**What It Tests:**
- `Window.luau` must detect encrypted configs before JSON fallback
- `Window.luau` must not expose `Unload` method (only `Destroy`)
- `ConfigEncryption.luau` must have `IsEncrypted` function
- `Types.luau` must have specific type definitions
- `README.md` must have required sections and examples
- CI workflow must run static contract tests
- CI workflow must run Rojo builds

### Icon Resolver Tests (Not in CI)

**Files:** `tests/icon_resolver_test.js`, `tests/icon_resolver_test.py`
**Status:** In `.gitignore`, not executed in CI
**Purpose:** Test icon resolution logic outside Roblox runtime

## Test Coverage

**Coverage Requirements:** None enforced
**Coverage Reporting:** Not configured
**Coverage Gaps:**
- No unit tests for individual components (Button, Toggle, Slider, etc.)
- No tests for config save/load functionality
- No tests for tween animations
- No tests for device detection
- No tests for drag behavior
- No tests for notification system
- No tests for acrylic blur effect

## Mocking

**Framework:** None (no mocking library)

**Approach in Smoke Test:** Direct assertion without mocking
- Uses real Roblox services via `game:GetService()`
- Requires actual modules from `ReplicatedStorage`

**Approach in Static Tests:** File system reading only
- Reads source files as strings
- Checks for presence/absence of specific patterns

## CI Pipeline

**File:** `.github/workflows/ci.yml`

**Jobs:**
1. `test-static` — Run Node.js static contract tests
2. `lint-format` — StyLua format check
3. `lint-static` — Selene static analysis
4. `build-rojo` — Rojo build verification

**Triggers:** Push to `main`, Pull requests to `main`

**Tools Installed:** Aftman (manages Rojo, StyLua, Selene versions)

## Test Project Configuration

**File:** `test.project.json`
```json
{
  "name": "Arcylic-Modded-Test",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "AcrylicUI": {
        "$path": "src"
      }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "SmokeTest": {
          "$path": "tests/smoke.client.luau"
        }
      }
    }
  }
}
```

## What's NOT Tested

1. **Component Behavior** — No tests for Toggle, Slider, Dropdown, etc. state changes
2. **Event Handling** — No tests for mouse/touch input processing
3. **Config Persistence** — No tests for save/load/auto-load
4. **Theme System** — No tests for SetTheme/ResetTheme/GetTheme
5. **Notification System** — No tests for show/dismiss/timing
6. **Drag & Resize** — No tests for window drag/resize
7. **Mobile Support** — No tests for mobile toggle/device detection
8. **Icon Resolution** — Tests exist but excluded from CI
9. **Error Handling** — No tests for pcall/fallback paths
10. **Cleanup** — No tests for Destroy/resource cleanup

## Adding New Tests

**For Luau Runtime Tests:**
- Add test file to `tests/` directory
- Use `.client.luau` or `.server.luau` extension for Rojo
- Add to `test.project.json` under `StarterPlayerScripts` or `ServerScriptService`
- Use `assert()` for assertions (no framework)

**For Static Analysis Tests:**
- Add test file to `tests/` directory
- Use `.test.js` extension
- Use Node.js `assert` module
- Add assertions for file content patterns

**Recommended Test Framework:**
- **Lune** — Luau test runner (outside Roblox)
- **TestEZ** — Roblox-native test framework
- Consider adding for proper unit testing

## Running Tests Locally

```bash
# Static tests (requires Node.js)
node tests/static-contracts.test.js

# Smoke test (requires Roblox Studio + Rojo)
rojo build test.project.json --output build/test.rbxl
# Open build/test.rbxl in Roblox Studio
# Check output window for assertion failures

# Linting/formatting (not tests, but quality checks)
stylua --check src/ studio/
selene src/ studio/
```

---

*Testing analysis: 2026-06-11*
