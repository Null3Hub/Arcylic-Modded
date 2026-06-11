# External Integrations

**Analysis Date:** 2026-06-11

## APIs & External Services

**Icon Pack Downloads (Remote Lua Scripts):**
- Solar icons - `https://raw.githubusercontent.com/StyearX/Icons/main/solar/dist/Icons.lua`
  - Fetched via `game:HttpGet` or executor `request` at runtime
  - Loaded via `loadstring()` and cached in memory
  - Used by: `src/Utils/IconResolver.luau` (line 31)
- Lucide icons - `https://raw.githubusercontent.com/StyearX/Icons/main/lucide/dist/Icons.lua`
  - Same fetch/load pattern
  - Default icon pack (`IconResolver.IconsType = "lucide"`)
  - Used by: `src/Utils/IconResolver.luau` (line 32)
- Gravity icons - `https://raw.githubusercontent.com/StyearX/Icons/main/gravity/dist/Icons.lua`
  - Same fetch/load pattern
  - Used by: `src/Utils/IconResolver.luau` (line 33)
- Craft icons - `https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua`
  - Same fetch/load pattern
  - Used by: `src/Utils/IconResolver.luau` (line 34)
- Geist icons - `https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua`
  - Same fetch/load pattern
  - Used by: `src/Utils/IconResolver.luau` (line 35)
- SFSymbols icons - `https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/sfsymbols/dist/Icons.lua`
  - Same fetch/load pattern
  - Used by: `src/Utils/IconResolver.luau` (line 36)

**Executor Library Source (CDN):**
- Bundled library download - `https://raw.githubusercontent.com/Null3Hub/Arcylic-Modded/refs/heads/main/src.lua.txt`
  - Used by executor example (`Exemple.lua`, line 9)
  - Fetched via `game:HttpGet` or executor `request`
  - Loaded via `loadstring()` at runtime

**HTTP Fetch Strategy (fallback chain in `src/Utils/IconResolver.luau`, lines 84-128):**
1. `game["HttpGet"](game, url, true)` - Primary (works in most executors)
2. `getgenv().request({ Url = url, Method = "GET" })` - Fallback
3. `getgenv().http_request({ Url = url, Method = "GET" })` - Fallback
4. `getgenv().syn.request({ Url = url, Method = "GET" })` - Synapse X fallback
5. `getgenv().http.request({ Url = url, Method = "GET" })` - Fluxus/other fallback
6. `game:GetService("HttpService"):GetAsync(url, true)` - Final fallback (Studio)

## Data Storage

**Databases:**
- Not applicable (no database usage)

**File Storage:**
- Executor file system (when available) - Config persistence
  - Root: `AcrylicConfigs/<configFolder>/`
  - Format: JSON files with `.json` extension
  - Encryption: Byte-shift + Base64 obfuscation (`src/Utils/ConfigEncryption.luau`)
  - Functions used: `writefile`, `readfile`, `isfile`, `makefolder`, `isfolder`, `listfiles`, `delfile`
  - Graceful degradation: Config system silently disables when file APIs unavailable
  - Used by: `src/Core/Window.luau` (lines 67-73, 128-141, 1074-1287)

**Caching:**
- In-memory icon pack cache (`src/Utils/IconResolver.luau`, line 42: `_cache`)
  - Per-session cache keyed by pack name
  - Failed packs cached as `false` to prevent repeated HTTP requests
  - Custom packs cached separately in `_customPacks` table
- In-memory tween cache (`src/Utils/Tween.luau`, line 13: `ActiveTweens`)
  - Per-instance tween tracking for cancellation on conflict

## Authentication & Identity

**Auth Provider:**
- Not applicable (no authentication system)
- Library operates entirely client-side with no user identity management

## Monitoring & Observability

**Error Tracking:**
- Not applicable (no external error tracking service)

**Logs:**
- `warn()` calls prefixed with `[AcrylicUI]` for library-level warnings
  - Icon pack fetch failures (`src/Utils/IconResolver.luau`, lines 219-222, 231-235, 244-248)
  - Config load failures (`src/Core/Window.luau`, lines 1059-1065, 1205-1212)
  - Acrylic blur disabled (`src/Core/Window.luau`, line 432)
  - Notification container uninitialized (`src/Core/Notification.luau`, line 94)
- No structured logging, no log levels, no remote telemetry

## CI/CD & Deployment

**Hosting:**
- GitHub - Source repository
- GitHub Pages (via raw GitHub URLs) - Icon packs and library source distributed via `raw.githubusercontent.com`

**CI Pipeline:**
- GitHub Actions (`.github/workflows/ci.yml`)
  - Triggers: Push to `main`, Pull requests to `main`
  - Jobs:
    1. `test-static` - Runs `node tests/static-contracts.test.js` (asserts file contracts, API surface)
    2. `lint-format` - Installs Aftman, runs `stylua --check src/ studio/`
    3. `lint-static` - Installs Aftman, runs `selene src/ studio/`
    4. `build-rojo` - Installs Aftman, builds all three Rojo projects to `build/`

**Deployment:**
- No automated deployment (library distributed as source code or bundle)
- Manual Rojo build produces `.rbxl` and `.rbxm` artifacts in `build/`
- Bundle generation via `build-bundle.js` produces `src.lua.txt`

## Webhooks & Callbacks

**Incoming:**
- None (no server endpoints, no webhook receivers)

**Outgoing:**
- None (HTTP calls are fetch-only, no webhook sending)

## External References

**Roblox Asset IDs (hardcoded in `src/Constants/Icons.luau`):**
- Window icons: `82603981310445` (minimize), `119943770201674` (close), `120997033468887` (resize), `112235310154264` (mobile toggle)
- Component icons: `10734898355` (button), `105558791071013` (arrow), `93828793199781` (textbox), `10723356507` (config), `88132848916505` (dropdown selected), `128765590084906` (dropdown search)
- Notification icons: `10709775704` (default), `10723356507` (config)

**Font Asset:**
- `rbxasset://fonts/families/GothamSSm.json` - GothamSSm font family (built-in Roblox font)
  - Used by: `src/Constants/Fonts.luau` (lines 9, 11, 13)

**Font:**
- Font.new() API - Modern Roblox font API with weight variants (SemiBold, Bold, Regular)

## Package Registry

**Wally Registry:**
- `https://github.com/UpliftGames/wally-index` - Roblox package registry
  - Package declared but has zero dependencies
  - Used for potential future dependency management

---

*Integration audit: 2026-06-11*
