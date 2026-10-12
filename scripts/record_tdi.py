#!/usr/bin/env python3
"""Capture 4 native physical holds in one XCTest session."""
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import time

root = Path("tdi-output")
root.mkdir(exist_ok=True)
udid = os.environ["SIMULATOR_UDID"]
original = root / "tdi-original-vfr.mp4"
review = root / "tdi-review-60fps.mp4"
testlog = root / "xcuitest.log"

for executable in ("ffmpeg", "ffprobe"):
    if shutil.which(executable) is None:
        raise RuntimeError(f"Missing {executable}: install before simulator capture")

test_cmd = [
    "xcodebuild", "test-without-building",
    "-project", "TDILab.xcodeproj", "-scheme", "TDILab",
    "-destination", f"platform=iOS Simulator,id={udid}",
    "-derivedDataPath", "DerivedData", "-parallel-testing-enabled", "NO",
    "-only-testing:TDILabUITests/TDIInteractionUITests/testFourDistinctPhysicalHolds",
    "CODE_SIGNING_ALLOWED=NO",
]
recorder = None
test_process = None
failure = None

try:
    with testlog.open("w") as log, (root / "recorder.log").open("w") as rec_log:
        # Start the original recording before XCTest. No dependence on
        # Xcode's buffered test-start log messages or method spellings.
        recorder=subprocess.Popen(
            ["xcrun", "simctl", "io", udid, "recordVideo",
             "--codec=h264", "--force", str(original)],
            stdout=rec_log, stderr=subprocess.STDOUT, start_new_session=True)
        time.sleep(2.0)
        if recorder.poll() is not None:
            raise RuntimeError("Simulator recorder exited unexpectedly; inspect recorder.log")
        test_process=subprocess.Popen(
            test_cmd, stdout=log, stderr=subprocess.STDOUT,
            env=dict(os.environ, NSUnbufferedIO="YES"))
        rc=test_process.wait(timeout=600)
        if rc != 0:
            raise RuntimeError(f"XCTest failed with exit {rc}; see xcuitest.log")
        time.sleep(0.8)
except Exception as exc:
    failure=exc
finally:
    if recorder is not None and recorder.poll() is None:
        os.killpg(recorder.pid, signal.SIGINT)
        try:
            recorder.wait(timeout=35)
        except subprocess.TimeoutExpired:
            os.killpg(recorder.pid, signal.SIGKILL)
            recorder.wait(timeout=5)
    if test_process is not None and test_process.poll() is None:
        test_process.terminate()
        try:
            test_process.wait(timeout=12)
        except subprocess.TimeoutExpired:
            test_process.kill()
            test_process.wait(timeout=5)
if failure:
    print("CAPTURE_DIAGNOSTIC:", failure, flush=True)

logs = testlog.read_text(errors="replace")
if not original.exists() or original.stat().st_size < 50000:
    raise RuntimeError("Original screen recording missing") from failure

raw = subprocess.run([
    "ffprobe", "-v", "error", "-select_streams", "v:0",
    "-show_entries", "frame=best_effort_timestamp_time", "-of", "json", str(original)
], check=True, capture_output=True, text=True, timeout=100)
times = [float(f["best_effort_timestamp_time"]) for f in json.loads(raw.stdout)["frames"]
         if "best_effort_timestamp_time" in f]
if len(times) < 100:
    raise RuntimeError("Too few actual source frames")
gaps = [b-a for a,b in zip(times, times[1:])]
metrics = {
    "actual_source_frames": len(times),
    "source_duration_seconds": round(times[-1]-times[0],3),
    "average_real_frame_rate": round(len(times)/max(0.001,times[-1]-times[0]),2),
    "max_gap_seconds": round(max(gaps),3),
    "gaps_over_100ms": sum(g>0.1 for g in gaps),
    "gaps_over_250ms": sum(g>0.25 for g in gaps),
    "gaps_over_1s": sum(g>1 for g in gaps),
    "optional_review_frame_rate": 60,
    "review_note": "Optional review FPS is an output timebase with duplicated source frames, not capture FPS."
}
(root / "frame-quality.json").write_text(json.dumps(metrics,indent=2)+"\n")
if failure:
    raise failure
if not ("TEST EXECUTE SUCCEEDED" in logs or "TEST SUCCEEDED" in logs):
    raise RuntimeError("Xcode did not confirm a successful run")

# Review encoding is optional and never changes original VFR evidence.
# Run full-rate conversion only on explicit request; avoid expensive re-encode.
if os.environ.get("TDI_MAKE_REVIEW_60FPS", "false").lower() == "true":
    vf = "fps=60,format=yuv420p"
    with (root / "transcode.log").open("w") as log:
        result = subprocess.run([
            "ffmpeg", "-hide_banner", "-nostdin", "-loglevel", "error",
            "-i", str(original), "-an", "-vf", vf, "-c:v", "libx264",
            "-preset", "veryfast", "-crf", "18",
            "-pix_fmt", "yuv420p", "-movflags", "+faststart",
            "-y", str(review)
        ], stdout=log, stderr=subprocess.STDOUT, timeout=360)
    if result.returncode != 0 or not review.exists():
        raise RuntimeError("Failed to encode optional 60 FPS review MP4")
print("PASS:", json.dumps(metrics), flush=True)
