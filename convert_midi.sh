#!/bin/bash
set -e

MUSIC_DIR="$(dirname "$0")/assets/music"

SF2=$(find /opt/homebrew/Cellar/fluid-synth -name "VintageDreamsWaves-v2.sf2" 2>/dev/null | head -1)
if [ -z "$SF2" ]; then
  echo "ERROR: Soundfont not found."
  exit 1
fi
echo "Soundfont: $SF2"

for mid in "$MUSIC_DIR"/*.mid; do
  base=$(basename "$mid" .mid)
  wav="$MUSIC_DIR/${base}.wav"
  if [ -f "$wav" ]; then
    echo "  $base.wav already exists, skipping"
    continue
  fi
  echo "  $base.mid → $base.wav"
  fluidsynth -ni -r 44100 -F "$wav" "$SF2" "$mid"
done

echo "Done! All MIDI converted to WAV."
