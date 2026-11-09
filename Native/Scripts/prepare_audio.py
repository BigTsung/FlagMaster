#!/usr/bin/env python3
"""Rebuild original fallback cues or install the local Gamemaster sound pack.
Requires ffmpeg. Licensed originals stay outside the repository.
"""
import argparse
from array import array
import math
from pathlib import Path
import shutil
import subprocess
import tempfile
import wave

AUDIO = Path(__file__).resolve().parents[1] / 'FlagMaster/Resources/Audio'
RATE = 48000
# Paths are relative to the pack root, so UI and reward cues share a retro palette.
EFFECTS = {
    'tap': ('Retro_Classic/Menu_UI_Beeps/retro_ui_menu_blip_click_01.wav', 0.12, -25),
    'correct': ('Retro/retro_beeps_success_04.wav', 0.36, -21),
    'wrong': ('Retro_Classic/Menu_UI_Beeps/retro_ui_menu_error_03.wav', 0.30, -23),
    'timeout': ('Retro_Classic/Menu_UI_Beeps/retro_simple_beep_03.wav', 0.36, -23),
    'countdown': ('Retro_Classic/Menu_UI_Beeps/retro_ui_menu_short_beep_04.wav', 0.10, -27),
    'complete': ('Retro/retro_beeps_success_02.wav', 1.30, -20),
    'end': ('Retro_Classic/Menu_UI_Beeps/retro_ui_menu_popup_02.wav', 0.26, -23),
    'game_over': ('Retro/retro_fail_sound_02.wav', 0.80, -23),
}


def run(*args):
    return subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', *map(str, args)], check=True, capture_output=True).stdout


def normalize(samples, db):
    rms = math.sqrt(sum(x * x for x in samples) / max(1, len(samples)))
    peak = max(map(abs, samples), default=0)
    gain = min(10 ** (db / 20) * 32767 / max(1, rms), 10 ** (-3 / 20) * 32767 / max(1, peak))
    return array('h', (round(x * gain) for x in samples))


def save(path, samples):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as out:
        out.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        out.writeframes(samples.tobytes())


def install(pack):
    music = pack / 'Ω_Bonus_Music_16bit44kOnly'
    # Keep the exact user-selected file (including its " 1" suffix).
    adventure = music / 'music_bytes_the_retro_adventure 1.wav'
    tracks = {
        'home': (adventure, 'loudnorm=I=-23:TP=-3:LRA=7'),
        # Preserve the theme and tempo while softening the lead for study.
        'learning': (adventure, 'lowpass=f=4500,loudnorm=I=-26:TP=-3:LRA=7'),
        'game': (music / 'music_8bit_jammer.wav', 'loudnorm=I=-23:TP=-3:LRA=7'),
    }
    required = [pack / item[0] for item in EFFECTS.values()] + [track[0] for track in tracks.values()]
    for source in required:
        if not source.is_file():
            raise FileNotFoundError(source)
    for name, (source, duration, db) in EFFECTS.items():
        pcm = run('-i', pack / source, '-af',
                  f'silenceremove=start_periods=1:start_duration=0.002:start_threshold=-50dB,atrim=duration={duration},afade=t=in:d=0.003,areverse,afade=t=in:d=0.025,areverse',
                  '-ac', 1, '-ar', RATE, '-f', 's16le', '-')
        samples = normalize(array('h', pcm), db)
        save(AUDIO / 'LocalEffects' / f'sfx_{name}.wav', samples)
        print(f'{name}: {len(samples) / RATE:.3f}s, peak {20 * math.log10(max(map(abs, samples)) / 32768):.1f} dBFS')
    for name, (source, filters) in tracks.items():
        destination = AUDIO / 'LocalMusic' / f'music_{name}.m4a'
        destination.parent.mkdir(parents=True, exist_ok=True)
        run('-i', source, '-af', filters,
            '-ar', RATE, '-ac', 2, '-c:a', 'aac', '-b:a', '192k', destination)
    print('Installed three music tracks and eight effects.')


def fallbacks():
    # Original sine/bell motifs: a small ticking note, double timeout,
    # neutral closing interval, and a gentle downward life-exhausted cue.
    motifs = {
        'countdown': ([(0, 740, .09)], .11, -27),
        'timeout': ([(0, 660, .11), (.13, 520, .13)], .30, -23),
        'end': ([(0, 392, .25), (.16, 523.25, .29)], .50, -23),
        'game_over': ([(0, 392, .22), (.17, 329.63, .27), (.31, 261.63, .23)], .58, -23),
    }
    for name, (notes, length, db) in motifs.items():
        samples = []
        for i in range(round(length * RATE)):
            t = i / RATE
            value = 0
            for start, frequency, duration in notes:
                u = t - start
                if 0 <= u < duration:
                    env = min(1, u / .006) * (1 - u / duration) ** 2
                    value += .35 * env * (math.sin(2 * math.pi * frequency * u) + .12 * math.sin(4 * math.pi * frequency * u))
            samples.append(round(value * 32767))
        save(AUDIO / f'sfx_{name}.wav', normalize(samples, db))
    # Sparse 32-second C / Am / F / G ambient loop, silent at both loop edges.
    chords = [(130.813, 164.814, 195.998), (110, 130.813, 164.814),
              (87.307, 130.813, 174.614), (97.999, 146.832, 195.998)]
    samples = array('h')
    for i in range(32 * RATE):
        t = i / RATE
        u = t % 8
        envelope = math.sin(math.pi * u / 8) ** 2
        value = sum(math.sin(2 * math.pi * f * t) for f in chords[int(t // 8)]) * .10 * envelope
        samples.append(round(value * 32767))
    with tempfile.TemporaryDirectory() as tmp:
        source = Path(tmp) / 'learning.wav'
        save(source, normalize(samples, -23))
        run('-i', source, '-ac', 2, '-c:a', 'aac', '-b:a', '192k', AUDIO / 'music_learning.m4a')
    print('Generated original fallback cues and learning loop.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pack', type=Path)
    parser.add_argument('--generate-fallbacks', action='store_true')
    args = parser.parse_args()
    if not shutil.which('ffmpeg'):
        parser.error('ffmpeg is required')
    if args.generate_fallbacks:
        fallbacks()
    if args.pack:
        install(args.pack.expanduser())
    if not args.pack and not args.generate_fallbacks:
        parser.error('choose --pack or --generate-fallbacks')
