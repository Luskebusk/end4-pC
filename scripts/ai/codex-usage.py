#!/usr/bin/env python3
"""Read the most recently reported Codex account limits from local sessions."""
import json
import os
from datetime import datetime
from pathlib import Path


def recent_lines(path, chunk_size=65536):
    """Yield lines newest first without reading the full session log."""
    with path.open("rb") as stream:
        stream.seek(0, os.SEEK_END)
        remaining = stream.tell()
        pending = b""
        while remaining:
            size = min(chunk_size, remaining)
            remaining -= size
            stream.seek(remaining)
            parts = (stream.read(size) + pending).split(b"\n")
            pending = parts[0]
            for line in reversed(parts[1:]):
                if line:
                    yield line
        if pending:
            yield pending


def read_usage(home):
    latest = None
    # Limits are account-wide. Compare report timestamps across sessions; file
    # modification times also change for events that contain no usage report.
    paths = sorted((home / "sessions").glob("**/*.jsonl"),
                   key=lambda path: path.stat().st_mtime, reverse=True)
    for path in paths:
        try:
            for line in recent_lines(path):
                try:
                    event = json.loads(line)
                    payload = event.get("payload", {})
                    limits = payload.get("rate_limits")
                    if (event.get("type") != "event_msg"
                            or payload.get("type") != "token_count"
                            or not isinstance(limits, dict)
                            or limits.get("limit_id") not in (None, "codex")
                            or not isinstance(limits.get("primary"), dict)):
                        continue
                    timestamp = event.get("timestamp", "")
                    if latest is None or timestamp > latest[0]:
                        latest = (timestamp, limits)
                    break  # Reports in a session are chronological.
                except (ValueError, TypeError, AttributeError):
                    continue
        except OSError:
            continue
    if latest is None:
        return {"available": False}
    limits = latest[1]
    primary = limits["primary"]
    secondary = limits.get("secondary") or {}
    reported_at = int(datetime.fromisoformat(latest[0].replace("Z", "+00:00")).timestamp())
    return {"available": True, "percentage": primary.get("used_percent", 0) / 100,
            "reportedAt": reported_at,
            "resetsAt": primary.get("resets_at", 0),
            "weeklyPercentage": secondary.get("used_percent", 0) / 100,
            "weeklyResetsAt": secondary.get("resets_at", 0)}


if __name__ == "__main__":
    home = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    print(json.dumps(read_usage(home)))
