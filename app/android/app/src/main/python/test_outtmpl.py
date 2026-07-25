"""Guards the download filename template in ytdlp_bridge.

Run with any interpreter that has yt-dlp (the app's own Python dependency):

    python test_outtmpl.py

A merge downloads two formats into one directory. YouTube's VP9/AV1 tiers pair a
.webm video with a .webm (Opus) audio, and both carry the same title — so a
template of title+ext alone resolves them to a single path. With `overwrites`
on, the audio then lands on top of the video, ffmpeg is handed an audio-only
file, `-map 0:v:0` matches nothing, and the download dies as "ffmpeg exited with
code 1". That was every 4K download.
"""

import re
from pathlib import Path

from yt_dlp import YoutubeDL

OLD = "/out/%(title).200B.%(ext)s"

TITLE = "Big Buck Bunny 60fps 4K - Official Blender Foundation Short Film"
VIDEO = {"title": TITLE, "format_id": "313", "ext": "webm"}  # VP9 2160p60, video only
AUDIO = {"title": TITLE, "format_id": "251", "ext": "webm"}  # Opus, audio only


def _live_template():
    """The outtmpl ytdlp_bridge actually uses, so this can't drift from the source."""
    source = (Path(__file__).parent / "ytdlp_bridge.py").read_text(encoding="utf-8")
    match = re.search(r'"outtmpl":\s*os\.path\.join\(out_dir,\s*"([^"]+)"\)', source)
    assert match, "could not find the outtmpl in ytdlp_bridge.py"
    return "/out/" + match.group(1)


def _names(template):
    ydl = YoutubeDL({"outtmpl": template, "restrictfilenames": True, "quiet": True})
    return ydl.prepare_filename(VIDEO), ydl.prepare_filename(AUDIO)


def test_outtmpl_separates_the_two_streams_of_a_merge():
    old_video, old_audio = _names(OLD)
    assert old_video == old_audio, "expected title+ext alone to collide"

    video, audio = _names(_live_template())
    assert video != audio, "each format of a merge needs its own file"
    assert video.endswith(".f313.webm") and audio.endswith(".f251.webm")


if __name__ == "__main__":
    test_outtmpl_separates_the_two_streams_of_a_merge()
    print("ok")
