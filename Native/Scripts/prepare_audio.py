#!/usr/bin/env python3
"""Rebuild original fallback cues or install the local Gamemaster sound pack.
Requires ffmpeg. Licensed originals stay outside the repository.
"""
import argparse
from array import array
import json
import math
from pathlib import Path
import shutil
import subprocess
import tempfile
import wave

AUDIO = Path(__file__).resolve().parents[1] / 'FlagMaster/Resources/Audio'
RATE = 48000
MUSIC_NORMALIZATION = 'loudnorm=I=-23:TP=-3:LRA=11'
# Paths are relative to the pack root.
EFFECTS = {
    'tap': ('Retro_Classic/Menu_UI_Beeps/retro_simple_beep_27.wav', 0.12, -25),
    'correct': ('Sci-Fi/sci-fi_device_item_power_up_flash_01.wav', 0.36, -21),
    'wrong': ('Sci-Fi/sci-fi_code_fail_06.wav', 0.30, -23),
    'timeout': ('Sci-Fi/sci-fi_power_down_object_01.wav', 0.36, -23),
    'countdown': ('Sci-Fi/sci-fi_electric_pulse_power_down_01.wav', 0.10, -27),
    'complete': ('Sci-Fi/sci-fi_shield_device_small_01.wav', 1.30, -20),
    'end': ('Sci-Fi/sci-fi_shield_device_small_01.wav', 0.26, -23),
    'game_over': ('Sci-Fi/sci-fi_power_down_object_01.wav', 0.80, -23),
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


def encode_music(source, destination, prefilter=None):
    filters = ['aformat=channel_layouts=stereo']
    if prefilter:
        filters.append(prefilter)
    filters.append(MUSIC_NORMALIZATION)
    analysis = subprocess.run(
        ['ffmpeg', '-hide_banner', '-nostats', '-i', str(source), '-vn', '-af',
         ','.join(filters) + ':print_format=json', '-f', 'null', '-'],
        check=True, capture_output=True, text=True,
    ).stderr
    measurements, _ = json.JSONDecoder().raw_decode(analysis[analysis.rindex('{'):])
    filters[-1] += (
        f":measured_I={measurements['input_i']}:measured_TP={measurements['input_tp']}"
        f":measured_LRA={measurements['input_lra']}:measured_thresh={measurements['input_thresh']}"
        f":offset={measurements['target_offset']}:linear=true"
    )
    run('-i', source, '-vn', '-af', ','.join(filters),
        '-ar', RATE, '-c:a', 'aac', '-b:a', '192k', destination)


def install(pack):
    music = pack / 'Ω_Bonus_Music_16bit44kOnly'
    tracks = {
        'home': (music / 'music_candyland.wav', None),
        'learning': (music / 'music_bytes_the_retro_adventure 1.wav', 'lowpass=f=4500'),
        'game': (music / 'music_fun_crazy_circus.wav', None),
        'two_lives': (music / 'music_fun_funky_toadstool.wav', None),
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
    for name, (source, prefilter) in tracks.items():
        destination = AUDIO / 'LocalMusic' / f'music_{name}.m4a'
        destination.parent.mkdir(parents=True, exist_ok=True)
        encode_music(source, destination, prefilter)
    print(f'Installed {len(tracks)} music tracks and {len(EFFECTS)} effects.')


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
        encode_music(source, AUDIO / 'music_learning.m4a')
    print('Generated original fallback cues and learning loop.')


def mode_music(only=None):
    # Tempo, chord roots, and an eight-note melody in semitones above middle C.
    themes = {
        'speed_round': (150, (0, -3, -5, -2), (12, 7, 10, 7, 14, 12, 7, 10)),
        'two_lives': (112, (-3, -5, -7, -2), (7, 3, None, 7, 10, 5, 2, None)),
        'review': (88, (0, -5, -3, -7), (7, None, 4, None, 9, 7, None, 4)),
        'region': (102, (-5, 0, -3, -7), (4, 7, 12, None, 9, 7, 4, None)),
        'comparison': (96, (2, -3, -5, 0), (2, None, 9, 5, 2, 7, None, 5)),
        'cards': (108, (-5, -10, 0, -2), (12, 16, None, 19, 14, None, 11, 14)),
    }

    def add_note(samples, pitch, start, length, gain):
        frequency = 261.626 * 2 ** (pitch / 12)
        offset = round(start * RATE)
        count = min(round(length * RATE), len(samples) - offset)
        for i in range(count):
            t = i / RATE
            phase = 2 * math.pi * frequency * t
            envelope = min(1, t / .012) * (1 - i / count) ** 2
            tone = math.sin(phase) + .22 * math.sin(3 * phase)
            samples[offset + i] += round(32767 * gain * envelope * tone)

    with tempfile.TemporaryDirectory() as tmp:
        source = Path(tmp) / 'mode.wav'
        selected_themes = themes if only is None else {only: themes[only]}
        for name, (tempo, roots, melody) in selected_themes.items():
            beat = 60 / tempo
            samples = array('h', [0]) * round(32 * beat * RATE)
            for bar, root in enumerate(roots * 2):
                start = bar * 4 * beat
                for step, pitch in enumerate(melody):
                    if pitch is not None:
                        add_note(samples, pitch + root, start + step * beat / 2, beat * .48, .12)
                for step in (0, 2):
                    add_note(samples, root - 12, start + step * beat, beat * 1.8, .15)
                    add_note(samples, root - 5, start + step * beat, beat * 1.6, .07)
            save(source, samples)
            encode_music(source, AUDIO / f'music_{name}.m4a')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pack', type=Path)
    parser.add_argument('--generate-fallbacks', action='store_true')
    parser.add_argument('--generate-mode-music', action='store_true')
    args = parser.parse_args()
    if not shutil.which('ffmpeg'):
        parser.error('ffmpeg is required')
    if args.generate_fallbacks:
        fallbacks()
    if args.pack:
        install(args.pack.expanduser())
    if args.generate_mode_music:
        mode_music()
    if not (args.pack or args.generate_fallbacks or args.generate_mode_music):
        parser.error('choose --pack, --generate-fallbacks, or --generate-mode-music')
