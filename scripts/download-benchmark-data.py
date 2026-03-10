#!/usr/bin/env python3
"""Download FLEURS en_us benchmark samples for FreeWispr pipeline testing.

Saves 20 test samples as 16kHz mono WAV files + ground truth .txt files.
Downloads audio tar + metadata TSV directly from HuggingFace Hub,
bypassing the legacy fleurs.py loading script.

Usage:
    uvx --with huggingface_hub,soundfile python scripts/download-benchmark-data.py
"""

import io
import tarfile
from pathlib import Path

import soundfile as sf
from huggingface_hub import hf_hub_download

NUM_SAMPLES = 50
OUTPUT_DIR = Path(__file__).parent / "benchmark-data"
REPO_ID = "google/fleurs"


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print("Downloading FLEURS en_us test metadata...")
    tsv_path = hf_hub_download(
        repo_id=REPO_ID,
        filename="data/en_us/test.tsv",
        repo_type="dataset",
    )

    # Parse TSV: columns are id, file_name, raw_transcription, transcription, ...
    transcripts = {}
    with open(tsv_path) as f:
        for line in f:
            parts = line.strip().split("\t")
            if len(parts) >= 4:
                filename = parts[1]  # e.g. "10001536118832534208.wav"
                transcription = parts[3]  # normalized transcription
                transcripts[filename] = transcription

    print(f"Found {len(transcripts)} test transcriptions")

    print("Downloading FLEURS en_us test audio archive...")
    tar_path = hf_hub_download(
        repo_id=REPO_ID,
        filename="data/en_us/audio/test.tar.gz",
        repo_type="dataset",
    )

    print(f"Extracting {NUM_SAMPLES} samples...")
    count = 0
    with tarfile.open(tar_path, "r:gz") as tar:
        for member in tar:
            if not member.name.endswith(".wav"):
                continue
            if count >= NUM_SAMPLES:
                break

            basename = Path(member.name).name
            transcript = transcripts.get(basename)
            if transcript is None:
                continue

            # Extract audio data
            audio_file = tar.extractfile(member)
            if audio_file is None:
                continue

            audio_data, sr = sf.read(io.BytesIO(audio_file.read()))

            stem = f"sample_{count:04d}"
            wav_path = OUTPUT_DIR / f"{stem}.wav"
            txt_path = OUTPUT_DIR / f"{stem}.txt"

            sf.write(str(wav_path), audio_data, sr)
            txt_path.write_text(transcript.strip() + "\n")

            duration = len(audio_data) / sr
            print(f"  [{count + 1:2d}/{NUM_SAMPLES}] {stem}  ({duration:.1f}s)  {basename}")
            count += 1

    print(f"\nSaved {count} samples to {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
