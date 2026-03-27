#!/usr/bin/env python3
"""
osz2vsrg - Extract osu!mania 4K charts from .osz files into the VSRG game.

Usage:
  python3 import_osz.py <file.osz>
  python3 import_osz.py ~/Downloads/*.osz

Places songs in:
  - Project: ./song/<foldername>/
  - Or user data: ~/Library/Application Support/Godot/app_userdata/VSRG/songs/<foldername>/
"""

import sys
import os
import zipfile
import re
import shutil

GAME_SONGS_DIR = os.path.expanduser(
    "~/Library/Application Support/Godot/app_userdata/VSRG/songs"
)
PROJECT_SONG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "song")


def parse_osu_header(content: str) -> dict:
    info = {"mode": -1, "keys": 0, "title": "", "artist": "", "version": "", "audio": ""}
    section = ""
    for line in content.split("\n"):
        line = line.strip()
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            if section == "HitObjects":
                break
            continue
        if section == "General":
            if line.startswith("Mode:"):
                info["mode"] = int(line.split(":")[1].strip())
            if line.startswith("AudioFilename:"):
                info["audio"] = line.split(":", 1)[1].strip()
        elif section == "Metadata":
            if line.startswith("Title:"):
                info["title"] = line.split(":", 1)[1].strip()
            elif line.startswith("Artist:"):
                info["artist"] = line.split(":", 1)[1].strip()
            elif line.startswith("Version:"):
                info["version"] = line.split(":", 1)[1].strip()
        elif section == "Difficulty":
            if line.startswith("CircleSize:"):
                info["keys"] = int(float(line.split(":")[1].strip()))
    return info


def safe_dirname(name: str) -> str:
    name = re.sub(r'[<>:"/\\|?*]', '_', name)
    return name.strip('. ')[:80]


def import_osz(osz_path: str, target_dir: str = None):
    if target_dir is None:
        target_dir = GAME_SONGS_DIR

    if not os.path.isfile(osz_path):
        print(f"  File not found: {osz_path}")
        return False

    print(f"\nProcessing: {os.path.basename(osz_path)}")

    try:
        zf = zipfile.ZipFile(osz_path, 'r')
    except zipfile.BadZipFile:
        print("  Not a valid zip/osz file")
        return False

    osu_files = [n for n in zf.namelist() if n.endswith('.osu')]
    if not osu_files:
        print("  No .osu files found")
        return False

    mania_4k_charts = []
    for osu_name in osu_files:
        content = zf.read(osu_name).decode('utf-8', errors='replace')
        info = parse_osu_header(content)
        print(f"  Found: {osu_name}")
        print(f"    Mode={info['mode']} Keys={info['keys']} - {info['artist']} - {info['title']} [{info['version']}]")

        if info["mode"] == 3 and info["keys"] == 4:
            mania_4k_charts.append((osu_name, content, info))
        elif info["mode"] == 3:
            print(f"    -> Skipped (mania but {info['keys']}K, need 4K)")
        else:
            mode_names = {0: "standard", 1: "taiko", 2: "catch", 3: "mania"}
            print(f"    -> Skipped (mode: {mode_names.get(info['mode'], 'unknown')})")

    if not mania_4k_charts:
        print("  No osu!mania 4K charts found in this .osz!")
        print("  This game only supports Mode:3 (mania) with CircleSize:4 (4K)")
        return False

    first_info = mania_4k_charts[0][2]
    folder_name = safe_dirname(f"{first_info['artist']} - {first_info['title']}")
    dest_dir = os.path.join(target_dir, folder_name)
    os.makedirs(dest_dir, exist_ok=True)

    audio_files_copied = set()
    for osu_name, content, info in mania_4k_charts:
        chart_dest = os.path.join(dest_dir, os.path.basename(osu_name))
        with open(chart_dest, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  Saved chart: {os.path.basename(osu_name)}")

        audio = info["audio"]
        if audio and audio not in audio_files_copied:
            try:
                audio_data = zf.read(audio)
                audio_dest = os.path.join(dest_dir, audio)
                with open(audio_dest, 'wb') as f:
                    f.write(audio_data)
                audio_files_copied.add(audio)
                print(f"  Saved audio: {audio}")
            except KeyError:
                print(f"  Warning: audio file '{audio}' not found in archive")

    zf.close()
    print(f"  -> Imported to: {dest_dir}")
    print(f"  -> {len(mania_4k_charts)} chart(s) ready!")
    return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 import_osz.py <file.osz> [file2.osz ...]")
        print(f"\nSongs will be placed in:\n  {GAME_SONGS_DIR}")
        sys.exit(1)

    os.makedirs(GAME_SONGS_DIR, exist_ok=True)

    success = 0
    for path in sys.argv[1:]:
        if import_osz(path):
            success += 1

    print(f"\nDone: {success}/{len(sys.argv)-1} imported successfully")
    if success > 0:
        print("Restart the game and the songs will appear in Song Select!")


if __name__ == "__main__":
    main()
