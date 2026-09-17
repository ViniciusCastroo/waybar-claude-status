#!/usr/bin/env python3
import json
import os
import re
import sys
import time
from pathlib import Path


def cache_dir() -> Path:
    base = os.environ.get("XDG_CACHE_HOME")
    if not base:
        base = str(Path.home() / ".cache")
    path = Path(base) / "ai-status.d"
    path.mkdir(parents=True, exist_ok=True)
    return path


def read_hook_input() -> dict:
    if sys.stdin.isatty():
        return {}
    raw = sys.stdin.read()
    if not raw.strip():
        return {}
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return {}
    return data if isinstance(data, dict) else {}


def nested_get(data: dict, path: tuple[str, ...]) -> str:
    value = data
    for key in path:
        if not isinstance(value, dict):
            return ""
        value = value.get(key)
    return str(value) if value else ""


def session_id(data: dict) -> str:
    candidates = [
        os.environ.get("CLAUDE_SESSION_ID", ""),
        os.environ.get("SESSION_ID", ""),
        str(data.get("session_id") or ""),
        str(data.get("sessionId") or ""),
        str(data.get("conversation_id") or ""),
        nested_get(data, ("session", "id")),
        nested_get(data, ("workspace", "current_dir")),
        str(data.get("transcript_path") or ""),
    ]
    for candidate in candidates:
        if candidate:
            return re.sub(r"[^A-Za-z0-9_.-]+", "-", candidate)[-96:]
    return f"ppid-{os.getppid()}"


def main() -> int:
    state = sys.argv[1] if len(sys.argv) > 1 else "idle"
    tool = sys.argv[2] if len(sys.argv) > 2 else "claude"
    if state not in {"busy", "done", "idle"}:
        state = "idle"
    if not re.fullmatch(r"[A-Za-z0-9_.-]+", tool):
        tool = "ai"

    data = read_hook_input()
    sid = session_id(data)
    path = cache_dir() / f"{tool}-{sid}.status"
    path.write_text(f"{state}:{tool}:{int(time.time())}\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
