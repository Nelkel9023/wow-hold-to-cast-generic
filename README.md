# Hold To Cast

Hold-to-cast for **World of Warcraft 3.3.5a (build 12340)**. Hold an action-bar
key and the bound action fires repeatedly until you let go. A normal key press
still behaves exactly as before.

Standalone: one `dinput8.dll`, no addon, no Lua, no configuration, no network.

## How it works

`Wow.exe` loads `dinput8.dll` from its own folder before the system copy, so a
proxy DLL dropped next to the executable is loaded automatically. The proxy
forwards `DirectInput8Create` to the real system DLL and then installs two
MinHook detours in the client process:

| Hook | Purpose |
| --- | --- |
| `CGUIBindings::ExecKey` | Records which key strings the game is currently consuming as bindings. Fires only for real binding input, so typing in chat or a focused edit box never triggers a cast, and neither does input while the window is unfocused. |
| `CGWorldFrame::OnLayerUpdate` | Once per frame: for every action button whose bound key is held, calls the client's own `CGActionBar::UseAction` on the correct slot, throttled to 250 ms. |

Key bindings are re-read once per second (`CGUIBindings::GetCommandKey`), so
rebinding keys in-game is picked up without a restart.

### Slot math

The client's FrameXML computes the action slot from the current bar page
(`ActionButton_GetPagedID`), and this DLL does the same:

- bonus bar (stances, stealth, druid forms): `id + (6 + bonusBarOffset - 1) * 12`
- otherwise: `id + currentPage * 12`

Extra bars (bottom-left, bottom-right, right, left) use fixed bases 60, 48, 24
and 36, matching pages 6, 5, 3 and 4 of the FrameXML source.

## Install

1. Copy `dinput8.dll` into the folder that contains `Wow.exe`.
2. Start the game normally.

Nothing else is required. There is no addon to enable.

To remove it, delete `dinput8.dll`. The game then uses the system DLL again.

## Build

Requirements: [zig](https://ziglang.org/) (any recent version, tested with
0.18-dev) and the [MinHook](https://github.com/TsudaKageyu/minhook) sources.

```
third_party/minhook-master/     <- MinHook checkout (src/, include/)
pwsh -File build/build.ps1      # or: pwsh -File build/build.ps1 -Zig C:\path\to\zig.exe
```

Output: `build/dinput8.dll`, a 32-bit DLL exporting `DirectInput8Create`
undecorated.

## Limits

- Build 12340 only. The addresses are fixed for the stock 3.3.5a executable;
  the DLL checks the PE timestamp (`0x4C2452FE`) and disables itself instead of
  patching a different client.
- Windows only, 32-bit process.
- Throttle is a compile-time constant (`CAST_THROTTLE_MS`), not a setting.
- Mouse buttons are not handled, only keyboard bindings.
- Writes `holdtocast.log` next to `Wow.exe` (a few lines at startup) so you can
  confirm the hooks installed.

## Transparency

This code was written with AI assistance and is published in full so it can be
audited. It performs no network access, no telemetry, no file access beyond
appending to `holdtocast.log`, and touches nothing outside the game process.

Use at your own risk. Modifying a game client may violate the terms of service
of the server you play on; that is your call, not this project's.
