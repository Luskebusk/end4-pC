# Local customizations and upstream updates

This fork contains personal changes on top of [pctrade/end4-pC](https://github.com/pctrade/end4-pC). `origin` is this fork; `upstream` is the original project. The live Quickshell checkout is `~/.config/quickshell/end4-pC`.

## Changes to preserve

- Animated GIF support and aspect-preserving crop in the custom image widget (`modules/ii/background/widgets/images/CustomImage.qml`). Avoid setting `AnimatedImage.sourceSize` to widget dimensions; that previously caused a startup crash.
- Smooth preset switching: apply the Material palette in one update, decode the outgoing wallpaper asynchronously, avoid a duplicate config write, and keep the desktop context menu loaded between openings. See `services/MaterialThemeLoader.qml`, `modules/common/Appearance.qml`, `modules/ii/background/Background.qml`, `scripts/colors/switchwall.sh`, and `modules/ii/desktopMenu/DesktopMenu.qml`.
- AI usage polling and countdown updates (`services/{CodexUsage,ClaudeUsage}.qml`, `scripts/ai/codex-usage.py`, `modules/ii/bar/AiUsagePopup.qml`, `modules/common/Config.qml`). Codex usage comes from the newest local session report; the reset countdown continues between reports.
- Local Ollama Search mode through SearXNG (`services/Ai.qml`, `scripts/ai/searxng-search.py`). Ollama and SearXNG services are deliberately stopped on this PC because they caused game stutter; merging code must not start them.
- AOC workspace resolution control (`services/WorkspaceResolutionService.qml`, `modules/ii/bar/WorkspaceResolution.qml`, bar widget registration). Overrides live in `$XDG_RUNTIME_DIR`, so they clear on reboot. At 1920×1080 the bar uses a compact popup.

User-specific settings such as the bar layout in `~/.config/illogical-impulse/config.json`, Hyprland monitor configuration, and the custom EDID firmware are outside this repository and are **not backed up by this fork**.

## Bringing in upstream changes

Run from this checkout, starting with a clean working tree:

```sh
git status --short
git fetch upstream
git switch -c merge-upstream-YYYY-MM-DD main
git merge upstream/main
```

Resolve conflicts while keeping both upstream improvements and the custom behavior above. Review `git diff main...HEAD`, then verify Quickshell loads, GIF playback, preset transitions and colors, the desktop menu, AI usage refresh, and all workspace resolution buttons, including the compact popup. After verification:

```sh
git switch main
git merge --ff-only merge-upstream-YYYY-MM-DD
git push origin main
```

Keep the merge on the test branch until the live desktop has been checked. Do not use `git reset --hard` or force-push to replace the customized branch.
