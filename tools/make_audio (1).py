"""Original sound effects and music loops for MathPull (synthesized, no samples).

Run from the project root:   python tools/make_audio.py
Needs: Python 3, numpy (pip install numpy) and ffmpeg on the PATH (for the .ogg music).
It writes assets/audio/sfx/*.wav and assets/audio/music/*.ogg.
"""
import os
import subprocess
import wave
import zipfile

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
os.makedirs(f"{OUT}/sfx", exist_ok=True)
os.makedirs(f"{OUT}/music", exist_ok=True)
rng = np.random.default_rng(7)


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def tarr(dur):
    return np.arange(int(round(dur * SR))) / SR


def fade(x, a=0.003, r=0.012):
    n = len(x)
    t = np.arange(n) / SR
    dur = n / SR
    return x * np.minimum(1, t / a) * np.minimum(1, np.maximum(0, (dur - t)) / r)


def voice(f, dur, partials, tau, a=0.003, r=0.012):
    t = tarr(dur)
    y = np.zeros_like(t)
    for mult, amp, dsc in partials:
        y += amp * np.sin(2 * np.pi * f * mult * t) * np.exp(-t / (tau * dsc))
    return fade(y, a, r)


MARIMBA = ((1, 1.0, 1.0), (4, 0.28, 0.45), (9.2, 0.07, 0.25))
BELL = ((1, 1.0, 1.0), (2.0, 0.40, 0.7), (3.01, 0.22, 0.5), (4.2, 0.10, 0.3))
SOFT = ((1, 1.0, 1.0), (2, 0.18, 0.6))
BASS = ((1, 1.0, 1.0), (2, 0.35, 0.6))


def tri(f, t):
    return (2 / np.pi) * np.arcsin(np.sin(2 * np.pi * f * t))


def pad(f, dur, att=0.35, rel=0.5):
    t = tarr(dur)
    y = 0.6 * tri(f, t) + 0.4 * tri(f * 1.004, t)
    return y * np.minimum(1, t / att) * np.minimum(1, np.maximum(0, dur - t) / rel)


def kick(dur=0.25):
    t = tarr(dur)
    f = 50 + 90 * np.exp(-t * 28)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * 14)


def hat(dur=0.06):
    t = tarr(dur)
    x = np.diff(np.diff(rng.standard_normal(len(t) + 2)))
    return x * np.exp(-t / 0.018) * 0.6


def clap(dur=0.16):
    t = tarr(dur)
    x = np.diff(rng.standard_normal(len(t) + 1))
    return (x * np.exp(-t / 0.05) * 0.5) + np.sin(2 * np.pi * 190 * t) * np.exp(-t / 0.04) * 0.4


class Track:
    def __init__(self, seconds, tail=3.0):
        self.n = int(round(seconds * SR))
        self.m = self.n + int(tail * SR)
        self.L = np.zeros(self.m)
        self.R = np.zeros(self.m)

    def add(self, sig, start, gain=1.0, pan=0.0):
        i = int(round(start * SR))
        if i >= self.m:
            return
        j = min(self.m, i + len(sig))
        seg = sig[: j - i] * gain
        ang = (pan + 1) * np.pi / 4
        self.L[i:j] += seg * np.cos(ang)
        self.R[i:j] += seg * np.sin(ang)

    def fold(self):
        """Wrap the tail onto the start so the loop is seamless."""
        n = self.n
        left = self.L[:n].copy()
        right = self.R[:n].copy()
        t = min(self.m - n, n)
        left[:t] += self.L[n : n + t]
        right[:t] += self.R[n : n + t]
        return left, right


def echo(left, right, taps):
    out_l, out_r = left.copy(), right.copy()
    for d, g in taps:
        k = int(d * SR)
        out_l += g * np.roll(right, k)  # ping-pong between the channels
        out_r += g * np.roll(left, k)
    return out_l, out_r


def finish_music(left, right, name, target_rms=0.11):
    x = np.stack([left, right], axis=1)
    x = x - x.mean(axis=0)
    rms = np.sqrt(np.mean(x ** 2))
    x = x * (target_rms / rms)
    x = np.tanh(x * 1.3) / 1.3  # gentle limiter
    peak = np.max(np.abs(x))
    if peak > 0.93:
        x = x * (0.93 / peak)
    pcm = (x * 32767).astype(np.int16)
    path = f"{OUT}/music/{name}.wav"
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-c:a", "libvorbis", "-q:a", "4", f"{OUT}/music/{name}.ogg"],
        check=True,
    )
    os.remove(path)
    return x


CHORDS = {
    "C": (48, [60, 64, 67]),
    "Am": (45, [57, 60, 64]),
    "F": (53, [57, 60, 65]),
    "G": (55, [59, 62, 67]),
    "Em": (52, [59, 64, 67]),
}


def make_game_loop():
    bpm = 112
    beat = 60 / bpm
    eighth = beat / 2
    prog = ["C", "Am", "F", "G", "C", "Am", "F", "G", "F", "C", "G", "Am", "F", "C", "G", "C"]
    N = None
    mel = [
        [76, N, 79, 76, 74, N, 72, N],
        [72, N, 76, 79, 81, N, 79, N],
        [81, N, 79, 76, 79, N, 76, N],
        [74, N, 79, 74, 79, N, 76, 74],
        [76, N, 79, 76, 84, N, 81, 79],
        [81, N, 79, 76, 81, N, 84, N],
        [84, N, 81, 79, 81, N, 79, 76],
        [79, N, 74, 76, 79, N, N, N],
        [81, N, 84, 81, 79, N, 76, 79],
        [76, N, 79, 84, 79, N, 76, N],
        [74, N, 79, 81, 79, N, 74, N],
        [72, N, 76, 81, 79, N, 76, N],
        [81, 79, 76, N, 81, N, 84, N],
        [84, N, 81, 79, 76, N, 79, N],
        [74, 76, 79, N, 81, N, 79, 76],
        [76, N, 72, N, 76, N, N, N],
    ]
    secs = len(prog) * 4 * beat
    melody = Track(secs)
    rest = Track(secs)
    for b, name in enumerate(prog):
        t0 = b * 4 * beat
        root, triad = CHORDS[name]
        for s in range(8):
            ts = t0 + s * eighth
            if mel[b][s]:
                melody.add(voice(hz(mel[b][s]), 0.5, MARIMBA, 0.26), ts, 0.55, -0.25)
            idx = [0, 1, 2, 1, 0, 1, 2, 1][s]
            rest.add(voice(hz(triad[idx]), 0.3, MARIMBA, 0.16), ts, 0.16, 0.45)
        for s, off in ((0, 0), (3, 0), (4, 7), (6, 0)):
            rest.add(voice(hz(root + off), 0.38, BASS, 0.2), t0 + s * eighth, 0.5, 0.0)
        for s in (0, 4):
            rest.add(kick(), t0 + s * eighth, 0.55, 0.0)
        for s in (2, 6):
            rest.add(clap(), t0 + s * eighth, 0.2, 0.1)
        for s in (1, 3, 5, 7):
            rest.add(hat(), t0 + s * eighth, 0.07, -0.15)
    ml, mr = melody.fold()
    ml, mr = echo(ml, mr, [(eighth * 1.5, 0.22), (eighth * 3.0, 0.10)])
    rl, rr = rest.fold()
    return finish_music(ml + rl, mr + rr, "game_loop")


def make_menu_loop():
    bpm = 84
    beat = 60 / bpm
    eighth = beat / 2
    prog = ["C", "F", "Am", "G", "C", "F", "G", "C"]
    N = None
    mel = [
        [79, N, N, 76, N, N, 72, N],
        [81, N, N, 79, N, N, 76, N],
        [76, N, 79, N, 81, N, N, N],
        [74, N, 79, N, 76, N, 74, N],
        [79, N, 84, N, 81, N, 79, N],
        [81, N, 79, N, 76, N, 72, N],
        [74, N, 76, N, 79, N, N, N],
        [76, N, N, N, 72, N, N, N],
    ]
    secs = len(prog) * 4 * beat
    melody = Track(secs)
    rest = Track(secs)
    for b, name in enumerate(prog):
        t0 = b * 4 * beat
        root, triad = CHORDS[name]
        for n in triad:
            rest.add(pad(hz(n - 12), 4 * beat + 0.2), t0, 0.11, 0.0)
        for s in range(8):
            ts = t0 + s * eighth
            if mel[b][s]:
                melody.add(voice(hz(mel[b][s]), 0.9, BELL, 0.45), ts, 0.42, -0.2)
            if s % 2 == 0:
                idx = [0, 1, 2, 1][s // 2]
                rest.add(voice(hz(triad[idx]), 0.5, MARIMBA, 0.25), ts, 0.13, 0.4)
        rest.add(voice(hz(root), 0.9, BASS, 0.4), t0, 0.34, 0.0)
        for s in (2, 6):
            rest.add(hat(), t0 + s * eighth, 0.05, 0.1)
    ml, mr = melody.fold()
    ml, mr = echo(ml, mr, [(eighth * 3.0, 0.28), (eighth * 6.0, 0.14)])
    rl, rr = rest.fold()
    return finish_music(ml + rl, mr + rr, "menu_loop")


# ---------------------------------------------------------------------------
# Sound effects
# ---------------------------------------------------------------------------


def buf(dur):
    return np.zeros(int(round(dur * SR)))


def put(b, sig, start, gain=1.0):
    i = int(round(start * SR))
    j = min(len(b), i + len(sig))
    if i < len(b):
        b[i:j] += sig[: j - i] * gain


def save_sfx(name, sig, peak=0.8):
    sig = sig - sig.mean()
    sig = sig / max(1e-9, np.max(np.abs(sig))) * peak
    k = min(len(sig), int(0.06 * SR))
    sig[-k:] *= np.linspace(1.0, 0.0, k) ** 2
    pcm = (sig * 32767).astype(np.int16)
    with wave.open(f"{OUT}/sfx/{name}.wav", "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def make_sfx():
    # tap: very soft key press
    t = tarr(0.07)
    y = np.sin(2 * np.pi * 650 * t) * np.exp(-t / 0.012)
    y += 0.4 * np.diff(rng.standard_normal(len(t) + 1)) * np.exp(-t / 0.004)
    save_sfx("tap", y, 0.35)

    # tick: countdown wood click
    t = tarr(0.12)
    y = np.sin(2 * np.pi * 1500 * t) * np.exp(-t / 0.018)
    y += 0.6 * np.sin(2 * np.pi * 2300 * t) * np.exp(-t / 0.010)
    y += 0.15 * np.diff(rng.standard_normal(len(t) + 1)) * np.exp(-t / 0.002)
    save_sfx("tick", y, 0.55)

    # go: bright rising chord
    b = buf(1.1)
    for i, n in enumerate((72, 76, 79)):
        put(b, voice(hz(n), 0.5, BELL, 0.2), i * 0.07, 0.8)
    put(b, voice(hz(84), 0.9, BELL, 0.35), 0.21, 1.0)
    put(b, voice(hz(88), 0.9, BELL, 0.3), 0.21, 0.4)
    save_sfx("go", b, 0.85)

    # correct (three pitch levels for a growing streak)
    for level, shift in enumerate((0, 2, 4)):
        b = buf(0.6)
        put(b, voice(hz(79 + shift), 0.4, BELL, 0.18), 0.0, 0.7)
        put(b, voice(hz(84 + shift), 0.5, BELL, 0.22), 0.08, 1.0)
        save_sfx(f"correct_{level + 1}", b, 0.8)

    # bonus: rising sparkle arpeggio
    b = buf(1.2)
    for i, n in enumerate((72, 76, 79, 84, 88)):
        put(b, voice(hz(n), 0.5, BELL, 0.2), i * 0.07, 0.8)
    put(b, voice(hz(91), 0.9, BELL, 0.4), 0.35, 1.0)
    put(b, voice(hz(96), 0.6, BELL, 0.25), 0.45, 0.35)
    save_sfx("bonus", b, 0.9)

    # wrong: soft, short "bonk" (not harsh, the game is also for kids)
    b = buf(0.6)
    put(b, voice(hz(64), 0.35, SOFT, 0.16), 0.0, 0.8)
    put(b, voice(hz(60), 0.4, SOFT, 0.2), 0.14, 1.0)
    save_sfx("wrong", b, 0.6)

    # win: fanfare
    b = buf(2.4)
    for i, n in enumerate((72, 76, 79, 84)):
        put(b, voice(hz(n), 0.6, BELL, 0.3), i * 0.11, 0.9)
    for n in (72, 76, 79, 84, 88):
        put(b, voice(hz(n), 1.6, BELL, 0.9), 0.5, 0.45)
    put(b, voice(hz(96), 0.5, BELL, 0.2), 0.7, 0.25)
    put(b, voice(hz(100), 0.5, BELL, 0.2), 0.85, 0.22)
    save_sfx("win", b, 0.85)

    # lose: gentle descending "aww"
    b = buf(1.5)
    for i, n in enumerate((67, 64, 60)):
        put(b, voice(hz(n), 0.8, SOFT, 0.35), i * 0.22, 0.9)
    save_sfx("lose", b, 0.6)

    # tie: neutral two-note
    b = buf(1.1)
    put(b, voice(hz(79), 0.7, BELL, 0.3), 0.0, 0.8)
    put(b, voice(hz(76), 0.8, BELL, 0.35), 0.22, 0.9)
    save_sfx("tie", b, 0.7)


if __name__ == "__main__":
    make_sfx()
    make_game_loop()
    make_menu_loop()
    print("done: wrote assets/audio/sfx and assets/audio/music")
