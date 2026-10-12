#!/usr/bin/env python3
"""Capture XCUIAutomation videos from Xcode's native .xcresult, not simctl VFR."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

root = Path("tdi-output")
root.mkdir(exist_ok=True)
udid = os.environ["SIMULATOR_UDID"]
result_bundle = root / "TDIGestures.xcresult"
export_dir = root / "xcresult-attachments"
testlog = root / "xcuitest.log"

if result_bundle.exists():
    shutil.rmtree(result_bundle)

test_cmd = [
    "xcodebuild", "test-without-building",
    "-project", "TDILab.xcodeproj", "-scheme", "TDILab",
    "-destination", f"platform=iOS Simulator,id={udid}",
    "-derivedDataPath", "DerivedData",
    "-resultBundlePath", str(result_bundle),
    "-parallel-testing-enabled", "NO",
    "-only-testing:TDILabUITests/TDIInteractionUITests/testFourDistinctPhysicalHolds",
    "CODE_SIGNING_ALLOWED=NO",
]
with testlog.open("w") as log:
    started = time.monotonic()
    test_result = subprocess.run(test_cmd, stdout=log, stderr=subprocess.STDOUT, timeout=600)
    test_duration = round(time.monotonic() - started, 2)

# Always export diagnostic recordings, even if one XCTest assertion fails.
export_dir.mkdir(exist_ok=True)
export_cmd = [
    "xcrun", "xcresulttool", "export", "attachments",
    "--path", str(result_bundle),
    "--output-path", str(export_dir),
]
with (root / "xcresult-export.log").open("w") as log:
    exported = subprocess.run(export_cmd, stdout=log, stderr=subprocess.STDOUT, timeout=120)

videos = sorted(
    (p for p in export_dir.rglob("*") if p.is_file() and p.suffix.lower() in (".mp4", ".mov")),
    key=lambda p: p.stat().st_size, reverse=True,
)
report = {
    "capture_method": "Xcode native XCTest recording via xcresulttool",
    "xctest_exit_code": test_result.returncode,
    "xctest_duration_seconds": test_duration,
    "export_exit_code": exported.returncode,
    "recordings": [],
}

for index, path in enumerate(videos):
    info = json.loads(subprocess.check_output([
        "ffprobe", "-v", "error", "-select_streams", "v:0",
        "-show_entries", "frame=best_effort_timestamp_time",
        "-of", "json", str(path)
    ], timeout=120))
    stamps = [float(frame["best_effort_timestamp_time"])
              for frame in info.get("frames", []) if "best_effort_timestamp_time" in frame]
    gaps = [b - a for a, b in zip(stamps, stamps[1:])]
    dst = root / f"tdi-xcode-recording-{index + 1}.mp4"
    shutil.copyfile(path, dst)
    report["recordings"].append({
        "file": dst.name,
        "frames": len(stamps),
        "duration_seconds": round(stamps[-1] - stamps[0], 3) if len(stamps) > 1 else 0,
        "max_frame_gap_seconds": round(max(gaps), 3) if gaps else None,
        "gaps_over_250ms": sum(gap > 0.25 for gap in gaps),
        "gaps_over_1s": sum(gap > 1 for gap in gaps),
    })

(root / "capture-quality.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report, indent=2), flush=True)

if test_result.returncode != 0:
    raise SystemExit("XCTest failed: inspect xcuitest.log and exported video")
if exported.returncode != 0 or not videos:
    raise SystemExit("Xcode did not export UI test videos; inspect xcresult-export.log")
# Static/idle scenes can legitimately have no new frames, but gaps during
# touch animations must be audited before declaring this recording usable.
if all(item["frames"] < 30 for item in report["recordings"]):
    raise SystemExit("Xcode recording does not contain enough actual frames")
