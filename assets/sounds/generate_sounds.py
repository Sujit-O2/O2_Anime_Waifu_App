"""
Real game sound generator using only Python stdlib (wave + math).
Generates all WAV files needed by GameSoundsService.
"""
import wave, struct, math, os

RATE = 44100

def write_wav(filename, frames):
    path = os.path.join(os.path.dirname(__file__), filename)
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)
    print(f"  ✓ {filename}  ({len(frames)//2} samples)")

def silence(dur):
    return b'\x00\x00' * int(RATE * dur)

def tone(freq, dur, vol=0.6, wave_type='sine'):
    n = int(RATE * dur)
    frames = []
    for i in range(n):
        t = i / RATE
        if wave_type == 'sine':
            s = math.sin(2 * math.pi * freq * t)
        elif wave_type == 'square':
            s = 1.0 if math.sin(2 * math.pi * freq * t) >= 0 else -1.0
        elif wave_type == 'sawtooth':
            s = 2 * ((freq * t) % 1.0) - 1.0
        elif wave_type == 'triangle':
            p = (freq * t) % 1.0
            s = 4 * p - 1 if p < 0.5 else 3 - 4 * p
        else:
            s = math.sin(2 * math.pi * freq * t)
        frames.append(int(s * vol * 32767))
    return struct.pack(f'<{n}h', *frames)

def tone_env(freq, dur, attack=0.01, decay=0.05, sustain=0.7, release=0.1, vol=0.7, wave_type='sine'):
    """Tone with ADSR envelope."""
    n = int(RATE * dur)
    a_s = int(RATE * attack)
    d_s = int(RATE * decay)
    r_s = int(RATE * release)
    frames = []
    for i in range(n):
        t = i / RATE
        # Envelope
        if i < a_s:
            env = i / max(a_s, 1)
        elif i < a_s + d_s:
            env = 1.0 - (1.0 - sustain) * (i - a_s) / max(d_s, 1)
        elif i < n - r_s:
            env = sustain
        else:
            env = sustain * (n - i) / max(r_s, 1)
        if wave_type == 'sine':
            s = math.sin(2 * math.pi * freq * t)
        elif wave_type == 'square':
            s = 1.0 if math.sin(2 * math.pi * freq * t) >= 0 else -1.0
        elif wave_type == 'sawtooth':
            s = 2 * ((freq * t) % 1.0) - 1.0
        elif wave_type == 'triangle':
            p = (freq * t) % 1.0
            s = 4 * p - 1 if p < 0.5 else 3 - 4 * p
        else:
            s = math.sin(2 * math.pi * freq * t)
        frames.append(int(s * env * vol * 32767))
    return struct.pack(f'<{n}h', *frames)

def sweep(f_start, f_end, dur, vol=0.6, wave_type='sine'):
    """Frequency sweep (glide)."""
    n = int(RATE * dur)
    frames = []
    phase = 0.0
    for i in range(n):
        t = i / n
        freq = f_start + (f_end - f_start) * t
        if wave_type == 'sine':
            s = math.sin(phase)
        elif wave_type == 'square':
            s = 1.0 if math.sin(phase) >= 0 else -1.0
        elif wave_type == 'sawtooth':
            s = 2 * ((phase / (2 * math.pi)) % 1.0) - 1.0
        else:
            s = math.sin(phase)
        # Fade in/out
        env = min(i / (RATE * 0.02), 1.0) * min((n - i) / (RATE * 0.02), 1.0)
        frames.append(int(s * env * vol * 32767))
        phase += 2 * math.pi * freq / RATE
    return struct.pack(f'<{n}h', *frames)

def chord(freqs, dur, vol=0.5, wave_type='sine'):
    """Multiple tones mixed together."""
    n = int(RATE * dur)
    per = vol / len(freqs)
    result = [0] * n
    for freq in freqs:
        for i in range(n):
            t = i / RATE
            env = min(i / (RATE * 0.01), 1.0) * min((n - i) / (RATE * 0.05), 1.0)
            if wave_type == 'sine':
                s = math.sin(2 * math.pi * freq * t)
            else:
                s = math.sin(2 * math.pi * freq * t)
            result[i] += int(s * env * per * 32767)
    return struct.pack(f'<{n}h', *result)

def noise(dur, vol=0.3):
    """White noise burst."""
    import random
    n = int(RATE * dur)
    frames = []
    for i in range(n):
        env = min(i / (RATE * 0.005), 1.0) * min((n - i) / (RATE * 0.02), 1.0)
        frames.append(int((random.random() * 2 - 1) * env * vol * 32767))
    return struct.pack(f'<{n}h', *frames)

def mix(*parts):
    """Concatenate audio parts."""
    return b''.join(parts)

print("Generating game sound effects...")

# ── TAP (short click) ──────────────────────────────────────────────────────
write_wav('tap.wav', mix(
    tone_env(1200, 0.04, attack=0.002, decay=0.02, sustain=0.0, release=0.01, vol=0.5, wave_type='sine'),
    tone_env(800, 0.03, attack=0.001, decay=0.02, sustain=0.0, release=0.01, vol=0.3, wave_type='sine'),
))

# ── CORRECT (happy ascending) ─────────────────────────────────────────────
write_wav('correct.wav', mix(
    tone_env(523, 0.1, vol=0.6),   # C5
    tone_env(659, 0.1, vol=0.6),   # E5
    tone_env(784, 0.18, vol=0.7),  # G5
))

# ── WRONG (descending buzz) ───────────────────────────────────────────────
write_wav('wrong.wav', mix(
    tone_env(300, 0.12, vol=0.6, wave_type='square'),
    tone_env(220, 0.18, vol=0.5, wave_type='square'),
))

# ── SPIN (rising sweep) ───────────────────────────────────────────────────
write_wav('spin.wav', mix(
    sweep(200, 1200, 0.35, vol=0.55),
    tone_env(1200, 0.1, vol=0.4),
))

# ── REVEAL (shimmer) ──────────────────────────────────────────────────────
write_wav('reveal.wav', mix(
    sweep(600, 1400, 0.15, vol=0.4),
    chord([1047, 1319, 1568], 0.25, vol=0.5),
))

# ── CLICK EFFECT (UI button) ──────────────────────────────────────────────
write_wav('click_effect.wav', mix(
    tone_env(900, 0.03, attack=0.001, decay=0.015, sustain=0.0, release=0.01, vol=0.55),
    tone_env(600, 0.04, attack=0.001, decay=0.02, sustain=0.0, release=0.01, vol=0.35),
))

print("  UI sounds done.")

# ── BATTLE HIT (impact thud) ──────────────────────────────────────────────
write_wav('battle_hit.wav', mix(
    noise(0.04, vol=0.5),
    tone_env(180, 0.12, attack=0.005, decay=0.08, sustain=0.0, release=0.03, vol=0.6, wave_type='square'),
))

# ── ENEMY ATTACK (heavy hit) ─────────────────────────────────────────────
write_wav('enemy_attack.wav', mix(
    noise(0.06, vol=0.6),
    tone_env(120, 0.18, attack=0.005, decay=0.1, sustain=0.0, release=0.05, vol=0.65, wave_type='square'),
    sweep(200, 80, 0.1, vol=0.4),
))

# ── CRITICAL HIT (dramatic crack) ────────────────────────────────────────
write_wav('critical_hit.wav', mix(
    noise(0.03, vol=0.7),
    tone_env(440, 0.05, vol=0.5, wave_type='square'),
    noise(0.03, vol=0.5),
    sweep(600, 100, 0.2, vol=0.5, wave_type='sawtooth'),
))

# ── BATTLE VICTORY (fanfare) ──────────────────────────────────────────────
write_wav('battle_victory.wav', mix(
    tone_env(523, 0.1, vol=0.6),
    tone_env(659, 0.1, vol=0.6),
    tone_env(784, 0.1, vol=0.6),
    tone_env(1047, 0.25, vol=0.7),
    silence(0.05),
    chord([784, 988, 1175], 0.35, vol=0.65),
))

# ── BATTLE DEFEAT (sad descend) ───────────────────────────────────────────
write_wav('battle_defeat.wav', mix(
    tone_env(392, 0.15, vol=0.5),
    tone_env(330, 0.15, vol=0.5),
    tone_env(262, 0.15, vol=0.5),
    tone_env(196, 0.3, vol=0.55, wave_type='triangle'),
))

# ── BLOCK (shield clank) ──────────────────────────────────────────────────
write_wav('block.wav', mix(
    noise(0.02, vol=0.4),
    tone_env(800, 0.08, attack=0.002, decay=0.04, sustain=0.2, release=0.03, vol=0.5, wave_type='square'),
))

# ── SPECIAL ABILITY (power surge) ────────────────────────────────────────
write_wav('special_ability.wav', mix(
    sweep(100, 800, 0.2, vol=0.5, wave_type='sawtooth'),
    chord([440, 554, 659], 0.15, vol=0.55),
    sweep(800, 1600, 0.15, vol=0.45),
))

# ── MAGIC (sparkle sweep) ─────────────────────────────────────────────────
write_wav('magic.wav', mix(
    sweep(400, 1200, 0.12, vol=0.4),
    chord([1047, 1319, 1568, 2093], 0.2, vol=0.45),
    sweep(1200, 600, 0.1, vol=0.3),
))

# ── ACHIEVEMENT UNLOCKED (triumphant) ────────────────────────────────────
write_wav('achievement_unlocked.wav', mix(
    tone_env(523, 0.08, vol=0.6),
    tone_env(659, 0.08, vol=0.6),
    tone_env(784, 0.08, vol=0.6),
    tone_env(1047, 0.08, vol=0.65),
    silence(0.04),
    chord([523, 659, 784, 1047], 0.4, vol=0.7),
))

# ── LEVEL UP (ascending arpeggio) ────────────────────────────────────────
write_wav('level_up.wav', mix(
    tone_env(262, 0.07, vol=0.55),
    tone_env(330, 0.07, vol=0.55),
    tone_env(392, 0.07, vol=0.55),
    tone_env(523, 0.07, vol=0.6),
    tone_env(659, 0.07, vol=0.6),
    tone_env(784, 0.07, vol=0.65),
    tone_env(1047, 0.25, vol=0.7),
))

# ── REWARD COLLECT (coin jingle) ─────────────────────────────────────────
write_wav('reward_collect.wav', mix(
    tone_env(988, 0.07, vol=0.55),
    tone_env(1319, 0.12, vol=0.6),
))

# ── TREASURE FOUND (magical reveal) ──────────────────────────────────────
write_wav('treasure_found.wav', mix(
    sweep(300, 900, 0.15, vol=0.45),
    chord([659, 784, 988, 1175], 0.3, vol=0.6),
    sweep(900, 1400, 0.1, vol=0.4),
))

print("  Battle & achievement sounds done.")

# ── GACHA PULL (slot machine spin) ───────────────────────────────────────
write_wav('gacha_pull.wav', mix(
    sweep(200, 1000, 0.25, vol=0.5, wave_type='sawtooth'),
    noise(0.05, vol=0.3),
    tone_env(880, 0.15, vol=0.55),
))

# ── GACHA LEGENDARY (epic reveal) ────────────────────────────────────────
write_wav('gacha_legendary.wav', mix(
    sweep(100, 600, 0.2, vol=0.5),
    silence(0.05),
    chord([523, 659, 784], 0.1, vol=0.5),
    chord([659, 784, 988], 0.1, vol=0.55),
    chord([784, 988, 1175], 0.1, vol=0.6),
    chord([1047, 1319, 1568], 0.4, vol=0.7),
))

# ── EVENT START ───────────────────────────────────────────────────────────
write_wav('event_start.wav', mix(
    tone_env(440, 0.1, vol=0.5),
    tone_env(554, 0.1, vol=0.55),
    tone_env(659, 0.2, vol=0.6),
))

# ── EVENT COMPLETE ────────────────────────────────────────────────────────
write_wav('event_complete.wav', mix(
    chord([523, 659, 784], 0.15, vol=0.55),
    silence(0.05),
    chord([659, 784, 988, 1175], 0.35, vol=0.65),
))

# ── BATTLE PASS TIER ──────────────────────────────────────────────────────
write_wav('battle_pass_tier.wav', mix(
    sweep(300, 700, 0.12, vol=0.45),
    chord([523, 659, 784], 0.25, vol=0.6),
))

# ── TOURNAMENT START (dramatic) ───────────────────────────────────────────
write_wav('tournament_start.wav', mix(
    tone_env(196, 0.15, vol=0.6, wave_type='square'),
    tone_env(196, 0.15, vol=0.6, wave_type='square'),
    silence(0.05),
    tone_env(262, 0.3, vol=0.65, wave_type='square'),
))

# ── TOURNAMENT WIN ────────────────────────────────────────────────────────
write_wav('tournament_win.wav', mix(
    tone_env(523, 0.08, vol=0.6),
    tone_env(659, 0.08, vol=0.6),
    tone_env(784, 0.08, vol=0.65),
    tone_env(1047, 0.08, vol=0.65),
    silence(0.04),
    chord([784, 988, 1175, 1568], 0.4, vol=0.7),
))

# ── TOURNAMENT CHAMPION (epic fanfare) ───────────────────────────────────
write_wav('tournament_champion.wav', mix(
    tone_env(392, 0.1, vol=0.6, wave_type='square'),
    tone_env(523, 0.1, vol=0.6, wave_type='square'),
    tone_env(659, 0.1, vol=0.65, wave_type='square'),
    tone_env(784, 0.1, vol=0.65, wave_type='square'),
    silence(0.05),
    chord([523, 659, 784, 1047], 0.15, vol=0.65),
    silence(0.03),
    chord([659, 784, 988, 1175, 1568], 0.5, vol=0.75),
))

# ── RANK UP ───────────────────────────────────────────────────────────────
write_wav('rank_up.wav', mix(
    sweep(300, 900, 0.15, vol=0.5),
    chord([659, 784, 988], 0.25, vol=0.6),
))

print("  Gacha & tournament sounds done.")

# ── GUILD WAR START (war horn) ────────────────────────────────────────────
write_wav('guild_war_start.wav', mix(
    tone_env(130, 0.3, vol=0.65, wave_type='sawtooth'),
    silence(0.05),
    tone_env(174, 0.3, vol=0.65, wave_type='sawtooth'),
    silence(0.05),
    tone_env(196, 0.4, vol=0.7, wave_type='sawtooth'),
))

# ── GUILD WAR VICTORY ─────────────────────────────────────────────────────
write_wav('guild_war_victory.wav', mix(
    chord([392, 523, 659], 0.12, vol=0.55),
    chord([523, 659, 784], 0.12, vol=0.6),
    chord([659, 784, 988, 1175], 0.35, vol=0.7),
))

# ── GUILD MEMBER JOINED (chime) ───────────────────────────────────────────
write_wav('guild_member_joined.wav', mix(
    tone_env(880, 0.08, vol=0.45),
    tone_env(1108, 0.12, vol=0.5),
))

# ── TREASURY DEPOSIT (coins) ──────────────────────────────────────────────
write_wav('treasury_deposit.wav', mix(
    tone_env(1047, 0.06, vol=0.45),
    tone_env(1319, 0.06, vol=0.45),
    tone_env(1568, 0.1, vol=0.5),
))

# ── GUILD PERK UNLOCKED ───────────────────────────────────────────────────
write_wav('guild_perk_unlocked.wav', mix(
    sweep(400, 1000, 0.15, vol=0.45),
    chord([659, 784, 988], 0.25, vol=0.6),
))

# ── RAID START (ominous) ──────────────────────────────────────────────────
write_wav('raid_start.wav', mix(
    tone_env(110, 0.2, vol=0.6, wave_type='sawtooth'),
    noise(0.05, vol=0.4),
    tone_env(146, 0.2, vol=0.65, wave_type='sawtooth'),
    noise(0.05, vol=0.4),
    sweep(146, 55, 0.3, vol=0.6, wave_type='sawtooth'),
))

# ── RAID BOSS APPEAR (dramatic boom) ─────────────────────────────────────
write_wav('raid_boss_appear.wav', mix(
    noise(0.08, vol=0.7),
    tone_env(55, 0.4, attack=0.01, decay=0.2, sustain=0.3, release=0.1, vol=0.7, wave_type='square'),
    sweep(300, 60, 0.25, vol=0.55, wave_type='sawtooth'),
))

# ── RAID COMPLETE ─────────────────────────────────────────────────────────
write_wav('raid_complete.wav', mix(
    chord([392, 523, 659], 0.1, vol=0.55),
    chord([523, 659, 784], 0.1, vol=0.6),
    chord([659, 784, 988], 0.1, vol=0.65),
    chord([784, 988, 1175, 1568], 0.4, vol=0.7),
))

# ── RAID TREASURE ─────────────────────────────────────────────────────────
write_wav('raid_treasure.wav', mix(
    sweep(400, 1200, 0.18, vol=0.5),
    chord([1047, 1319, 1568], 0.3, vol=0.65),
))

# ── MINI GAME WIN ─────────────────────────────────────────────────────────
write_wav('mini_game_win.wav', mix(
    tone_env(523, 0.08, vol=0.6),
    tone_env(659, 0.08, vol=0.6),
    tone_env(784, 0.08, vol=0.65),
    tone_env(1047, 0.22, vol=0.7),
))

# ── MINI GAME LOSE ────────────────────────────────────────────────────────
write_wav('mini_game_lose.wav', mix(
    tone_env(392, 0.12, vol=0.55),
    tone_env(330, 0.12, vol=0.55),
    tone_env(262, 0.2, vol=0.55, wave_type='triangle'),
))

# ── MINI GAME ROUND ───────────────────────────────────────────────────────
write_wav('mini_game_round.wav', mix(
    tone_env(784, 0.07, vol=0.5),
    tone_env(988, 0.1, vol=0.55),
))

# ── WIN EFFECT (alias for mini_game_win) ─────────────────────────────────
write_wav('win_effect.wav', mix(
    tone_env(659, 0.08, vol=0.6),
    tone_env(784, 0.08, vol=0.65),
    tone_env(988, 0.08, vol=0.65),
    tone_env(1319, 0.25, vol=0.7),
))

# ── COMBO ─────────────────────────────────────────────────────────────────
write_wav('combo.wav', mix(
    tone_env(659, 0.06, vol=0.5),
    tone_env(784, 0.08, vol=0.55),
))

# ── COMBO BURST ───────────────────────────────────────────────────────────
write_wav('combo_burst.wav', mix(
    tone_env(523, 0.05, vol=0.5),
    tone_env(659, 0.05, vol=0.55),
    tone_env(784, 0.05, vol=0.6),
    tone_env(1047, 0.15, vol=0.65),
))

# ── STREAK BONUS ──────────────────────────────────────────────────────────
write_wav('streak_bonus.wav', mix(
    sweep(400, 1000, 0.12, vol=0.5),
    chord([784, 988, 1175], 0.2, vol=0.6),
))

# ── ALERT (warning beep) ──────────────────────────────────────────────────
write_wav('alert.wav', mix(
    tone_env(880, 0.1, vol=0.6, wave_type='square'),
    silence(0.05),
    tone_env(880, 0.1, vol=0.6, wave_type='square'),
))

# ── NOTIFICATION (soft chime) ─────────────────────────────────────────────
write_wav('notification.wav', mix(
    tone_env(1047, 0.08, vol=0.4),
    tone_env(1319, 0.12, vol=0.45),
))

# ── AFFECTION INCREASE (warm tone) ───────────────────────────────────────
write_wav('affection_increase.wav', mix(
    tone_env(523, 0.08, vol=0.4),
    tone_env(659, 0.12, vol=0.45),
    tone_env(784, 0.15, vol=0.5),
))

# ── AFFECTION DECREASE (sad tone) ────────────────────────────────────────
write_wav('affection_decrease.wav', mix(
    tone_env(392, 0.12, vol=0.45),
    tone_env(330, 0.15, vol=0.45, wave_type='triangle'),
))

print("  Guild, raid, mini-game & combo sounds done.")

# ── BACKGROUND MUSIC: ARCADE (upbeat chiptune loop) ──────────────────────
def bgm_arcade(dur=8.0):
    """Simple chiptune melody loop."""
    melody = [
        (784, 0.15), (784, 0.15), (988, 0.15), (784, 0.15),
        (659, 0.15), (784, 0.3),  (523, 0.15), (659, 0.15),
        (784, 0.15), (988, 0.15), (784, 0.15), (659, 0.15),
        (523, 0.3),  (392, 0.15), (523, 0.15), (659, 0.15),
    ]
    bass = [
        (196, 0.3), (196, 0.3), (220, 0.3), (196, 0.3),
        (174, 0.3), (196, 0.6), (130, 0.3), (174, 0.3),
        (196, 0.3), (220, 0.3), (196, 0.3), (174, 0.3),
        (130, 0.6), (98, 0.3),  (130, 0.3), (174, 0.3),
    ]
    parts = []
    total = 0.0
    mi = 0
    bi = 0
    while total < dur:
        mf, md = melody[mi % len(melody)]
        bf, bd = bass[bi % len(bass)]
        step = min(md, bd)
        parts.append(tone_env(mf, step, vol=0.35, wave_type='square'))
        parts.append(tone_env(bf, step, vol=0.2, wave_type='square'))
        total += step
        mi += 1
        bi += 1
    return b''.join(parts)

write_wav('game_arcade_bgm.wav', bgm_arcade(8.0))

# ── BACKGROUND MUSIC: PUZZLE (calm ambient) ───────────────────────────────
def bgm_puzzle(dur=8.0):
    notes = [
        (523, 0.4), (659, 0.4), (784, 0.4), (659, 0.4),
        (523, 0.4), (440, 0.4), (392, 0.4), (440, 0.4),
        (523, 0.4), (659, 0.4), (784, 0.8),
        (659, 0.4), (523, 0.4), (440, 0.8),
    ]
    parts = []
    total = 0.0
    i = 0
    while total < dur:
        f, d = notes[i % len(notes)]
        parts.append(tone_env(f, d, attack=0.05, decay=0.1, sustain=0.5, release=0.15, vol=0.3))
        total += d
        i += 1
    return b''.join(parts)

write_wav('game_puzzle_bgm.wav', bgm_puzzle(8.0))

# ── BACKGROUND MUSIC: REACTION (fast-paced) ──────────────────────────────
def bgm_reaction(dur=8.0):
    notes = [
        (988, 0.1), (784, 0.1), (988, 0.1), (1175, 0.1),
        (988, 0.1), (784, 0.1), (659, 0.1), (784, 0.1),
        (988, 0.1), (1175, 0.1),(988, 0.1), (784, 0.1),
        (659, 0.2), (523, 0.2),
    ]
    parts = []
    total = 0.0
    i = 0
    while total < dur:
        f, d = notes[i % len(notes)]
        parts.append(tone_env(f, d, attack=0.005, decay=0.03, sustain=0.4, release=0.03, vol=0.38, wave_type='square'))
        total += d
        i += 1
    return b''.join(parts)

write_wav('game_reaction_bgm.wav', bgm_reaction(8.0))

# ── BACKGROUND MUSIC: BRAIN (thoughtful) ─────────────────────────────────
def bgm_brain(dur=8.0):
    notes = [
        (330, 0.5), (392, 0.5), (440, 0.5), (392, 0.5),
        (330, 0.5), (294, 0.5), (262, 0.5), (294, 0.5),
        (330, 0.5), (392, 1.0),
        (440, 0.5), (392, 0.5), (330, 1.0),
    ]
    parts = []
    total = 0.0
    i = 0
    while total < dur:
        f, d = notes[i % len(notes)]
        parts.append(tone_env(f, d, attack=0.08, decay=0.15, sustain=0.4, release=0.2, vol=0.28, wave_type='triangle'))
        total += d
        i += 1
    return b''.join(parts)

write_wav('game_brain_bgm.wav', bgm_brain(8.0))

# ── BACKGROUND MUSIC: GENERAL ─────────────────────────────────────────────
def bgm_general(dur=8.0):
    notes = [
        (440, 0.3), (523, 0.3), (659, 0.3), (784, 0.3),
        (659, 0.3), (523, 0.3), (440, 0.6),
        (392, 0.3), (440, 0.3), (523, 0.3), (659, 0.3),
        (523, 0.3), (440, 0.3), (392, 0.6),
    ]
    parts = []
    total = 0.0
    i = 0
    while total < dur:
        f, d = notes[i % len(notes)]
        parts.append(tone_env(f, d, attack=0.03, decay=0.08, sustain=0.5, release=0.1, vol=0.3))
        total += d
        i += 1
    return b''.join(parts)

write_wav('background_music.wav', bgm_general(8.0))

print("  Background music done.")
print("\nAll sound files generated successfully!")
