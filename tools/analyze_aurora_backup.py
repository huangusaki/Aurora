#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Analyze Aurora backup/export zip (aurora_backup_*.zip) and explain what makes it large.

This script is designed to work with Aurora's backup format:
  - A zip containing `data.json` (and optional background image assets).
  - `data.json` is a single JSON object with top-level keys like:
      version, createdAt, sessions, messages, topics, chatPresets, providerConfigs,
      studioContent, preferences

The file can be huge (hundreds of MB). We avoid `json.load()` on the whole file.
Instead we stream-parse the JSON and analyze the `messages` array element-by-element.

Usage:
  python tools/analyze_aurora_backup.py path/to/aurora_backup_xxx.zip
  python tools/analyze_aurora_backup.py path/to/data.json
"""

from __future__ import annotations

import argparse
import dataclasses
import heapq
import io
import json
import os
import sys
import time
import zipfile
from typing import BinaryIO, Dict, Iterable, List, Optional, Tuple


WHITESPACE = b" \t\r\n"


class JsonStreamError(RuntimeError):
    pass


class ByteReader:
    __slots__ = ("_fp", "_buf", "_pos", "_eof", "_chunk", "consumed")

    def __init__(self, fp: BinaryIO, chunk_size: int = 1 << 16):
        self._fp = fp
        self._buf = bytearray()
        self._pos = 0
        self._eof = False
        self._chunk = chunk_size
        self.consumed = 0  # bytes consumed from the decompressed stream

    def _fill(self, n: int) -> int:
        while (len(self._buf) - self._pos) < n and not self._eof:
            chunk = self._fp.read(self._chunk)
            if not chunk:
                self._eof = True
                break
            if self._pos == 0:
                self._buf.extend(chunk)
            else:
                # drop consumed bytes to keep buffer bounded
                self._buf = self._buf[self._pos :] + chunk
                self._pos = 0
        return len(self._buf) - self._pos

    def peek(self) -> Optional[int]:
        if self._fill(1) <= 0:
            return None
        return self._buf[self._pos]

    def next(self) -> Optional[int]:
        if self._fill(1) <= 0:
            return None
        b = self._buf[self._pos]
        self._pos += 1
        self.consumed += 1
        return b

    def expect(self, b: int) -> None:
        got = self.next()
        if got != b:
            raise JsonStreamError(f"Expected byte {b!r}, got {got!r}")


def _skip_ws(r: ByteReader) -> None:
    while True:
        b = r.peek()
        if b is None or b not in WHITESPACE:
            return
        r.next()


def _read_literal(r: ByteReader, literal: bytes) -> None:
    for ch in literal:
        got = r.next()
        if got != ch:
            raise JsonStreamError(f"Expected literal {literal!r}")


def _read_bool(r: ByteReader) -> bool:
    b = r.peek()
    if b == ord("t"):
        _read_literal(r, b"true")
        return True
    if b == ord("f"):
        _read_literal(r, b"false")
        return False
    raise JsonStreamError("Expected boolean")


def _skip_number(r: ByteReader) -> None:
    # JSON number: -? int frac? exp?
    b = r.peek()
    if b is None:
        raise JsonStreamError("Unexpected EOF while reading number")

    # first char: - or digit
    while True:
        b = r.peek()
        if b is None:
            return
        if b in b"-+0123456789.eE":
            r.next()
            continue
        return


def _skip_string_len_preview(
    r: ByteReader, *, preview_bytes: int = 0, base64_check: bool = False
) -> Tuple[int, bytes, bool]:
    """
    Consume a JSON string. Return:
      - raw_len: number of bytes inside the quotes (including escapes)
      - preview: first preview_bytes (raw, may include escape sequences)
      - base64_like: heuristic for long base64 blobs (only if base64_check True)
    """
    r.expect(ord('"'))
    raw_len = 0
    preview = bytearray()

    # base64-ish heuristic
    base64_like = False
    b64_total = 0
    b64_allowed = 0
    b64_upper = 0
    b64_lower = 0
    b64_digit = 0
    b64_plus_slash = 0
    b64_eq = 0
    saw_ws = False
    prefix = bytearray()
    prefix_limit = 64  # to detect "data:image" etc.

    while True:
        b = r.next()
        if b is None:
            raise JsonStreamError("Unexpected EOF inside string")
        if b == ord('"'):
            break

        raw_len += 1
        if preview_bytes and len(preview) < preview_bytes:
            preview.append(b)

        if base64_check:
            if len(prefix) < prefix_limit:
                prefix.append(b)

            # treat escaped sequences as non-base64 for the heuristic
            if b == ord("\\"):
                esc = r.next()
                if esc is None:
                    raise JsonStreamError("Unexpected EOF in escape")
                raw_len += 1
                if preview_bytes and len(preview) < preview_bytes:
                    preview.append(esc)
                if len(prefix) < prefix_limit:
                    prefix.append(esc)

                if esc == ord("u"):
                    for _ in range(4):
                        h = r.next()
                        if h is None:
                            raise JsonStreamError("Unexpected EOF in \\u escape")
                        raw_len += 1
                        if preview_bytes and len(preview) < preview_bytes:
                            preview.append(h)
                        if len(prefix) < prefix_limit:
                            prefix.append(h)

                # escapes make it unlikely to be base64; we still keep scanning
                b64_total += 2
                continue

            if b in WHITESPACE:
                saw_ws = True
            else:
                b64_total += 1
                if (
                    (ord("A") <= b <= ord("Z"))
                    or (ord("a") <= b <= ord("z"))
                    or (ord("0") <= b <= ord("9"))
                    or b in (ord("+"), ord("/"), ord("="))
                ):
                    b64_allowed += 1
                    if ord("A") <= b <= ord("Z"):
                        b64_upper += 1
                    elif ord("a") <= b <= ord("z"):
                        b64_lower += 1
                    elif ord("0") <= b <= ord("9"):
                        b64_digit += 1
                    elif b in (ord("+"), ord("/")):
                        b64_plus_slash += 1
                    elif b == ord("="):
                        b64_eq += 1
            continue

        if b == ord("\\"):
            esc = r.next()
            if esc is None:
                raise JsonStreamError("Unexpected EOF in escape")
            raw_len += 1
            if preview_bytes and len(preview) < preview_bytes:
                preview.append(esc)
            if esc == ord("u"):
                for _ in range(4):
                    h = r.next()
                    if h is None:
                        raise JsonStreamError("Unexpected EOF in \\u escape")
                    raw_len += 1
                    if preview_bytes and len(preview) < preview_bytes:
                        preview.append(h)

    if base64_check and raw_len >= 8192:
        # Common cases:
        # - "data:image/png;base64,...."
        # - plain base64 blob (no whitespace, mostly base64 charset)
        prefix_lower = bytes(prefix).lower()
        if b"data:image" in prefix_lower and b"base64" in prefix_lower:
            base64_like = True
        else:
            ratio = (b64_allowed / b64_total) if b64_total else 0.0
            category_count = int(b64_upper > 0) + int(b64_lower > 0) + int(b64_digit > 0) + int(b64_plus_slash > 0)
            # Be conservative: require no whitespace, mostly base64 charset,
            # and at least some non-letter base64 chars (digits/+// or '=' padding).
            base64_like = (
                (not saw_ws)
                and ratio > 0.99
                and b64_total > 4096
                and category_count >= 2
                and (b64_digit + b64_plus_slash + b64_eq) > 0
            )

    return raw_len, bytes(preview), base64_like


def _read_string_value(r: ByteReader) -> str:
    """
    Read and decode a JSON string into Python str.
    Only use this for small values (keys, sessionId, title, timestamp, role).
    """
    b = r.peek()
    if b != ord('"'):
        raise JsonStreamError("Expected string")

    token = bytearray()
    token.append(r.next())  # opening quote
    escaped = False
    while True:
        ch = r.next()
        if ch is None:
            raise JsonStreamError("Unexpected EOF inside string")
        token.append(ch)
        if escaped:
            escaped = False
            continue
        if ch == ord("\\"):
            escaped = True
            continue
        if ch == ord('"'):
            break
    return json.loads(token.decode("utf-8"))


def _read_string_fast(r: ByteReader) -> str:
    """
    Read a JSON string into Python str.

    Fast path: strings without any backslash escapes are decoded directly as UTF-8.
    Slow path: if a backslash is encountered, fall back to json.loads on the raw token.
    """
    b = r.peek()
    if b != ord('"'):
        raise JsonStreamError("Expected string")

    r.next()  # opening quote
    buf = bytearray()
    while True:
        ch = r.next()
        if ch is None:
            raise JsonStreamError("Unexpected EOF inside string")
        if ch == ord('"'):
            return buf.decode("utf-8", errors="strict")
        if ch == ord("\\"):
            # Slow path: rebuild full token bytes (including already read prefix)
            token = bytearray()
            token.append(ord('"'))
            token.extend(buf)
            token.append(ord("\\"))

            escaped = True
            while True:
                c = r.next()
                if c is None:
                    raise JsonStreamError("Unexpected EOF inside string escape")
                token.append(c)
                if escaped:
                    escaped = False
                    continue
                if c == ord("\\"):
                    escaped = True
                    continue
                if c == ord('"'):
                    break
            return json.loads(token.decode("utf-8"))

        buf.append(ch)


def _skip_value(r: ByteReader) -> None:
    _skip_ws(r)
    b = r.peek()
    if b is None:
        raise JsonStreamError("Unexpected EOF while skipping value")

    if b == ord('"'):
        _skip_string_len_preview(r)
        return
    if b == ord("{"):
        _skip_object(r)
        return
    if b == ord("["):
        _skip_array(r)
        return
    if b == ord("t"):
        _read_literal(r, b"true")
        return
    if b == ord("f"):
        _read_literal(r, b"false")
        return
    if b == ord("n"):
        _read_literal(r, b"null")
        return

    # number
    _skip_number(r)


def _skip_array(r: ByteReader) -> None:
    r.expect(ord("["))
    _skip_ws(r)
    if r.peek() == ord("]"):
        r.next()
        return

    while True:
        _skip_value(r)
        _skip_ws(r)
        b = r.peek()
        if b == ord(","):
            r.next()
            _skip_ws(r)
            continue
        if b == ord("]"):
            r.next()
            return
        raise JsonStreamError("Expected ',' or ']' in array")


def _skip_object(r: ByteReader) -> None:
    r.expect(ord("{"))
    _skip_ws(r)
    if r.peek() == ord("}"):
        r.next()
        return

    while True:
        # key
        _skip_ws(r)
        if r.peek() != ord('"'):
            raise JsonStreamError("Expected string key in object")
        _skip_string_len_preview(r)
        _skip_ws(r)
        r.expect(ord(":"))
        _skip_value(r)
        _skip_ws(r)
        b = r.peek()
        if b == ord(","):
            r.next()
            _skip_ws(r)
            continue
        if b == ord("}"):
            r.next()
            return
        raise JsonStreamError("Expected ',' or '}' in object")


def _read_nullable_string_value(r: ByteReader) -> Optional[str]:
    _skip_ws(r)
    b = r.peek()
    if b == ord("n"):
        _read_literal(r, b"null")
        return None
    return _read_string_fast(r)


def _read_string_array_stats(r: ByteReader) -> Tuple[int, int, int]:
    """
    Return (count, total_raw_len, max_item_raw_len) for an array of strings.
    """
    _skip_ws(r)
    if r.peek() == ord("n"):
        _read_literal(r, b"null")
        return 0, 0, 0

    r.expect(ord("["))
    _skip_ws(r)
    if r.peek() == ord("]"):
        r.next()
        return 0, 0, 0

    count = 0
    total = 0
    max_item = 0
    while True:
        _skip_ws(r)
        if r.peek() != ord('"'):
            # tolerate non-string (shouldn't happen)
            _skip_value(r)
        else:
            item_len, _, _ = _skip_string_len_preview(r)
            total += item_len
            if item_len > max_item:
                max_item = item_len
            count += 1

        _skip_ws(r)
        b = r.peek()
        if b == ord(","):
            r.next()
            continue
        if b == ord("]"):
            r.next()
            break
        raise JsonStreamError("Expected ',' or ']' in string array")

    return count, total, max_item


@dataclasses.dataclass
class MessageStat:
    session_id: Optional[str] = None
    timestamp: Optional[str] = None
    role: Optional[str] = None
    is_user: Optional[bool] = None

    content_raw: int = 0
    reasoning_raw: int = 0
    toolcalls_raw: int = 0
    attachments_raw: int = 0
    images_raw: int = 0
    attachments_count: int = 0
    images_count: int = 0

    content_preview: bytes = b""
    content_base64_like: bool = False
    toolcalls_preview: bytes = b""

    @property
    def weight(self) -> int:
        return (
            self.content_raw
            + self.reasoning_raw
            + self.toolcalls_raw
            + self.attachments_raw
            + self.images_raw
        )


@dataclasses.dataclass
class SessionAgg:
    title: str = ""
    messages: int = 0
    bytes_total: int = 0
    bytes_content: int = 0
    bytes_toolcalls: int = 0


def _parse_session_obj(r: ByteReader) -> Tuple[Optional[str], Optional[str]]:
    _skip_ws(r)
    if r.peek() != ord("{"):
        raise JsonStreamError("Expected session object")
    r.expect(ord("{"))
    session_id: Optional[str] = None
    title: Optional[str] = None

    _skip_ws(r)
    if r.peek() == ord("}"):
        r.next()
        return session_id, title

    while True:
        _skip_ws(r)
        key = _read_string_fast(r)
        _skip_ws(r)
        r.expect(ord(":"))
        _skip_ws(r)

        if key == "sessionId":
            session_id = _read_nullable_string_value(r)
        elif key == "title":
            title = _read_nullable_string_value(r)
        else:
            _skip_value(r)

        _skip_ws(r)
        b = r.peek()
        if b == ord(","):
            r.next()
            continue
        if b == ord("}"):
            r.next()
            break
        raise JsonStreamError("Expected ',' or '}' in session object")

    return session_id, title


def _parse_sessions_array(r: ByteReader) -> Dict[str, str]:
    _skip_ws(r)
    if r.peek() == ord("n"):
        _read_literal(r, b"null")
        return {}

    r.expect(ord("["))
    sessions: Dict[str, str] = {}

    _skip_ws(r)
    if r.peek() == ord("]"):
        r.next()
        return sessions

    while True:
        sid, title = _parse_session_obj(r)
        if sid:
            sessions[sid] = title or ""

        _skip_ws(r)
        b = r.peek()
        if b == ord(","):
            r.next()
            continue
        if b == ord("]"):
            r.next()
            break
        raise JsonStreamError("Expected ',' or ']' in sessions array")

    return sessions


def _parse_message_obj(r: ByteReader, *, preview_bytes: int) -> MessageStat:
    _skip_ws(r)
    if r.peek() != ord("{"):
        raise JsonStreamError("Expected message object")
    r.expect(ord("{"))

    stat = MessageStat()
    _skip_ws(r)
    if r.peek() == ord("}"):
        r.next()
        return stat

    while True:
        _skip_ws(r)
        key = _read_string_fast(r)
        _skip_ws(r)
        r.expect(ord(":"))
        _skip_ws(r)

        if key == "sessionId":
            stat.session_id = _read_nullable_string_value(r)
        elif key == "timestamp":
            stat.timestamp = _read_nullable_string_value(r)
        elif key == "role":
            stat.role = _read_nullable_string_value(r)
        elif key == "isUser":
            stat.is_user = _read_bool(r)
        elif key == "content":
            if r.peek() == ord("n"):
                _read_literal(r, b"null")
            else:
                raw_len, preview, b64_like = _skip_string_len_preview(
                    r, preview_bytes=preview_bytes, base64_check=True
                )
                stat.content_raw = raw_len
                stat.content_preview = preview
                stat.content_base64_like = b64_like
        elif key == "reasoningContent":
            if r.peek() == ord("n"):
                _read_literal(r, b"null")
            else:
                raw_len, _, _ = _skip_string_len_preview(r)
                stat.reasoning_raw = raw_len
        elif key == "toolCallsJson":
            if r.peek() == ord("n"):
                _read_literal(r, b"null")
            else:
                raw_len, preview, _ = _skip_string_len_preview(
                    r, preview_bytes=preview_bytes, base64_check=False
                )
                stat.toolcalls_raw = raw_len
                stat.toolcalls_preview = preview
        elif key == "attachments":
            cnt, total, _ = _read_string_array_stats(r)
            stat.attachments_count = cnt
            stat.attachments_raw = total
        elif key == "images":
            cnt, total, _ = _read_string_array_stats(r)
            stat.images_count = cnt
            stat.images_raw = total
        else:
            _skip_value(r)

        _skip_ws(r)
        b = r.peek()
        if b == ord(","):
            r.next()
            continue
        if b == ord("}"):
            r.next()
            break
        raise JsonStreamError("Expected ',' or '}' in message object")

    return stat


def _parse_messages_array(
    r: ByteReader,
    *,
    sessions: Dict[str, str],
    top_messages: int,
    preview_bytes: int,
    progress_every: int,
) -> Tuple[int, Dict[str, SessionAgg], List[MessageStat], Dict[str, int]]:
    _skip_ws(r)
    if r.peek() == ord("n"):
        _read_literal(r, b"null")
        return 0, {}, [], {}

    r.expect(ord("["))
    _skip_ws(r)
    if r.peek() == ord("]"):
        r.next()
        return 0, {}, [], {}

    per_session: Dict[str, SessionAgg] = {}
    heap: List[Tuple[int, int, MessageStat]] = []
    totals = {
        "content_raw": 0,
        "reasoning_raw": 0,
        "toolcalls_raw": 0,
        "attachments_raw": 0,
        "images_raw": 0,
        "messages": 0,
        "content_base64_like": 0,
    }

    msg_index = 0
    t0 = time.time()

    while True:
        stat = _parse_message_obj(r, preview_bytes=preview_bytes)
        msg_index += 1
        totals["messages"] += 1
        totals["content_raw"] += stat.content_raw
        totals["reasoning_raw"] += stat.reasoning_raw
        totals["toolcalls_raw"] += stat.toolcalls_raw
        totals["attachments_raw"] += stat.attachments_raw
        totals["images_raw"] += stat.images_raw
        if stat.content_base64_like:
            totals["content_base64_like"] += 1

        sid = stat.session_id or "<null>"
        agg = per_session.get(sid)
        if agg is None:
            agg = SessionAgg(title=sessions.get(stat.session_id or "", ""))
            per_session[sid] = agg
        agg.messages += 1
        agg.bytes_total += stat.weight
        agg.bytes_content += stat.content_raw
        agg.bytes_toolcalls += stat.toolcalls_raw

        w = stat.weight
        if top_messages > 0:
            if len(heap) < top_messages:
                heapq.heappush(heap, (w, msg_index, stat))
            else:
                if w > heap[0][0]:
                    heapq.heapreplace(heap, (w, msg_index, stat))

        if progress_every > 0 and (msg_index % progress_every) == 0:
            dt = max(0.001, time.time() - t0)
            rate = msg_index / dt
            print(
                f"[progress] messages={msg_index:,} rate={rate:,.0f}/s",
                file=sys.stderr,
            )

        _skip_ws(r)
        b = r.peek()
        if b == ord(","):
            r.next()
            _skip_ws(r)
            continue
        if b == ord("]"):
            r.next()
            break
        raise JsonStreamError("Expected ',' or ']' in messages array")

    # heap -> descending list
    top_list = [item[2] for item in sorted(heap, key=lambda x: x[0], reverse=True)]
    return msg_index, per_session, top_list, totals


def _parse_preferences_object(r: ByteReader) -> Dict[str, int]:
    """
    Return per-preference-key byte sizes (raw JSON bytes of each value).
    """
    _skip_ws(r)
    if r.peek() == ord("n"):
        _read_literal(r, b"null")
        return {}

    r.expect(ord("{"))
    _skip_ws(r)
    if r.peek() == ord("}"):
        r.next()
        return {}

    sizes: Dict[str, int] = {}
    while True:
        _skip_ws(r)
        key = _read_string_fast(r)
        _skip_ws(r)
        r.expect(ord(":"))
        _skip_ws(r)
        start = r.consumed
        _skip_value(r)
        end = r.consumed
        sizes[key] = end - start

        _skip_ws(r)
        b = r.peek()
        if b == ord(","):
            r.next()
            continue
        if b == ord("}"):
            r.next()
            break
        raise JsonStreamError("Expected ',' or '}' in preferences")
    return sizes


@dataclasses.dataclass
class AnalysisResult:
    source_path: str
    data_json_uncompressed_bytes: Optional[int] = None
    data_json_compressed_bytes: Optional[int] = None
    top_level_value_bytes: Dict[str, int] = dataclasses.field(default_factory=dict)
    pref_value_bytes: Dict[str, int] = dataclasses.field(default_factory=dict)

    sessions_count: int = 0
    messages_count: int = 0
    per_session: Dict[str, SessionAgg] = dataclasses.field(default_factory=dict)
    top_messages: List[MessageStat] = dataclasses.field(default_factory=list)
    msg_totals: Dict[str, int] = dataclasses.field(default_factory=dict)


def _human_bytes(n: int) -> str:
    unit = 1024.0
    if n < unit:
        return f"{n} B"
    for suffix in ("KiB", "MiB", "GiB", "TiB"):
        n /= unit
        if n < unit:
            return f"{n:.2f} {suffix}"
    return f"{n:.2f} PiB"


def _open_backup_stream(path: str) -> Tuple[BinaryIO, AnalysisResult]:
    """
    Return (binary stream for data.json, result w/ sizes if available).
    The caller owns the returned stream and must close it.
    """
    result = AnalysisResult(source_path=path)

    lower = path.lower()
    if lower.endswith(".zip"):
        zf = zipfile.ZipFile(path, "r")
        try:
            info = zf.getinfo("data.json")
        except KeyError:
            zf.close()
            raise SystemExit("zip 内找不到 data.json（不是 Aurora 备份文件？）")
        result.data_json_uncompressed_bytes = info.file_size
        result.data_json_compressed_bytes = info.compress_size
        # ZipExtFile is a streaming decompressor; keep zf alive by attaching it.
        stream = zf.open(info, "r")
        stream._aurora_zipfile = zf  # type: ignore[attr-defined]
        return stream, result

    if lower.endswith(".json"):
        fp = open(path, "rb")
        try:
            st = os.stat(path)
            result.data_json_uncompressed_bytes = st.st_size
        except OSError:
            pass
        return fp, result

    raise SystemExit("请输入 Aurora 的备份 zip 文件（aurora_backup_*.zip）或 data.json")


def analyze_backup(
    path: str,
    *,
    top_messages: int = 20,
    top_sessions: int = 15,
    preview_bytes: int = 120,
    progress_every: int = 5000,
) -> AnalysisResult:
    stream, result = _open_backup_stream(path)
    try:
        r = ByteReader(stream)
        _skip_ws(r)
        if r.peek() != ord("{"):
            raise JsonStreamError("data.json 不是 JSON object（开头不是 '{'）")

        r.expect(ord("{"))
        sessions_map: Dict[str, str] = {}

        # Walk top-level object keys
        while True:
            _skip_ws(r)
            b = r.peek()
            if b is None:
                raise JsonStreamError("Unexpected EOF in top-level object")
            if b == ord("}"):
                r.next()
                break

            key = _read_string_fast(r)
            _skip_ws(r)
            r.expect(ord(":"))
            _skip_ws(r)

            value_start = r.consumed
            if key == "sessions":
                sessions_map = _parse_sessions_array(r)
                result.sessions_count = len(sessions_map)
            elif key == "messages":
                (
                    msg_count,
                    per_session,
                    top_msgs,
                    msg_totals,
                ) = _parse_messages_array(
                    r,
                    sessions=sessions_map,
                    top_messages=top_messages,
                    preview_bytes=preview_bytes,
                    progress_every=progress_every,
                )
                result.messages_count = msg_count
                result.per_session = per_session
                result.top_messages = top_msgs
                result.msg_totals = msg_totals
            elif key == "preferences":
                result.pref_value_bytes = _parse_preferences_object(r)
            else:
                _skip_value(r)

            value_end = r.consumed
            result.top_level_value_bytes[key] = value_end - value_start

            _skip_ws(r)
            b = r.peek()
            if b == ord(","):
                r.next()
                continue
            if b == ord("}"):
                r.next()
                break
            raise JsonStreamError("Expected ',' or '}' after top-level value")

        return result
    finally:
        try:
            zf = getattr(stream, "_aurora_zipfile", None)
            stream.close()
            if zf is not None:
                zf.close()
        except Exception:
            pass


def _print_report(result: AnalysisResult, *, top_sessions: int) -> None:
    print(f"源文件: {result.source_path}")
    if result.data_json_uncompressed_bytes is not None:
        s = _human_bytes(result.data_json_uncompressed_bytes)
        if result.data_json_compressed_bytes is not None:
            c = _human_bytes(result.data_json_compressed_bytes)
            print(f"data.json: 压缩后 {c} / 解压后 {s}")
        else:
            print(f"data.json: {s}")

    if result.top_level_value_bytes:
        print("\n[Top-level 字段大小（raw JSON bytes）]")
        for k, v in sorted(result.top_level_value_bytes.items(), key=lambda kv: kv[1], reverse=True):
            print(f"- {k}: {_human_bytes(v)}")

    if result.pref_value_bytes:
        print("\n[preferences 子项大小 Top 15]")
        for k, v in sorted(result.pref_value_bytes.items(), key=lambda kv: kv[1], reverse=True)[:15]:
            print(f"- {k}: {_human_bytes(v)}")

    if result.messages_count:
        print("\n[消息统计]")
        totals = result.msg_totals or {}
        print(f"- messages: {result.messages_count:,}")
        if totals:
            print(
                "- 大字段累计(raw): "
                f"content={_human_bytes(totals.get('content_raw', 0))}, "
                f"reasoning={_human_bytes(totals.get('reasoning_raw', 0))}, "
                f"toolCallsJson={_human_bytes(totals.get('toolcalls_raw', 0))}, "
                f"attachments={_human_bytes(totals.get('attachments_raw', 0))}, "
                f"images={_human_bytes(totals.get('images_raw', 0))}"
            )
            b64_cnt = totals.get("content_base64_like", 0)
            if b64_cnt:
                print(f"- content 疑似 base64 blob: {b64_cnt:,} 条")

    if result.per_session:
        print(f"\n[Top 会话（按内容体积，Top {top_sessions}）]")
        items = sorted(result.per_session.items(), key=lambda kv: kv[1].bytes_total, reverse=True)[:top_sessions]
        for sid, agg in items:
            title = agg.title.replace("\n", " ").strip()
            if len(title) > 60:
                title = title[:57] + "..."
            print(
                f"- {_human_bytes(agg.bytes_total)}  msgs={agg.messages:,}  "
                f"content={_human_bytes(agg.bytes_content)}  "
                f"tool={_human_bytes(agg.bytes_toolcalls)}  "
                f"sid={sid}  title={title!r}"
            )

    if result.top_messages:
        print("\n[Top 单条消息（按大字段体积）]")
        for i, m in enumerate(result.top_messages, 1):
            title = ""
            if m.session_id:
                title = (result.per_session.get(m.session_id) or SessionAgg()).title
            title = title.replace("\n", " ").strip()
            if len(title) > 48:
                title = title[:45] + "..."

            def _preview(b: bytes) -> str:
                if not b:
                    return ""
                # show raw preview; keep it single-line
                s = b.decode("utf-8", errors="replace").replace("\r", " ").replace("\n", " ")
                if len(s) > 120:
                    s = s[:117] + "..."
                return s

            flags = []
            if m.content_base64_like:
                flags.append("content:base64_like")
            flag_s = f" [{', '.join(flags)}]" if flags else ""

            print(
                f"{i:2d}) total={_human_bytes(m.weight)} "
                f"content={_human_bytes(m.content_raw)} "
                f"reasoning={_human_bytes(m.reasoning_raw)} "
                f"tool={_human_bytes(m.toolcalls_raw)} "
                f"att={_human_bytes(m.attachments_raw)} "
                f"img={_human_bytes(m.images_raw)} "
                f"sid={m.session_id!r} title={title!r} "
                f"ts={m.timestamp!r} role={m.role!r} isUser={m.is_user!r}{flag_s}"
            )
            p = _preview(m.content_preview)
            if p:
                print(f"    content_preview: {p}")
            tp = _preview(m.toolcalls_preview)
            if tp:
                print(f"    toolCallsJson_preview: {tp}")


def main(argv: Optional[List[str]] = None) -> int:
    ap = argparse.ArgumentParser(
        description="分析 Aurora 备份/导出文件为什么这么大（流式解析 data.json）"
    )
    ap.add_argument("path", help="aurora_backup_*.zip 或 data.json 路径")
    ap.add_argument("--top-messages", type=int, default=20, help="输出最大的消息条数")
    ap.add_argument("--top-sessions", type=int, default=15, help="输出最大的会话条数")
    ap.add_argument("--preview-bytes", type=int, default=120, help="每条大消息的预览字节数（raw）")
    ap.add_argument(
        "--progress-every",
        type=int,
        default=5000,
        help="每处理多少条消息输出一次进度（0 关闭）",
    )
    args = ap.parse_args(argv)

    try:
        result = analyze_backup(
            args.path,
            top_messages=max(0, args.top_messages),
            top_sessions=max(0, args.top_sessions),
            preview_bytes=max(0, args.preview_bytes),
            progress_every=max(0, args.progress_every),
        )
    except JsonStreamError as e:
        print(f"[error] 解析失败: {e}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        print("[error] 用户中断", file=sys.stderr)
        return 130

    _print_report(result, top_sessions=max(0, args.top_sessions))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
