#!/usr/bin/env python3
"""The ocean wallpapers: one per screen, one continuous fog across the desk, gently moving.

    laptop (left):  a jellyfish, a whale far away, a small moon jellyfish
    front (OLED):   five jellyfish at different depths, one of them a moon jellyfish
    right:          a jellyfish under soft light rays, two tiny jellyfish far away

Neon line art on a dark fog, Catppuccin Mocha colours, like the pigeon in the bar. Each call writes one frame as SVG;
render.sh turns frames into seamless 12-second loops at 24 frames a second (every motion repeats exactly once per
loop) and stills.

    ocean.py <laptop|front|right> <out.svg> [t] [loop]     t = time in seconds (default 0), loop in seconds

The fog is computed in desk coordinates (the layout from hyprctl monitors / host.lua), so it continues from one screen
into the next: laptop 1920x1080 at (0, 360), front 2560x1440 at (1920, 0), right 1920x1080 at (4480, 180).
Everything is drawn from fixed random seeds: the same input always gives the same picture.
"""
import math
import random
import sys

CRUST, MANTLE, BASE, SURFACE0, SURFACE1 = "#11111b", "#181825", "#1e1e2e", "#313244", "#45475a"
MAUVE, BLUE, SAPPHIRE, TEAL, GREEN = "#cba6f7", "#89b4fa", "#74c7ec", "#94e2d5", "#a6e3a1"
PEACH, PINK, LAVENDER, ROSE, TEXT, YELLOW = "#fab387", "#f5c2e7", "#b4befe", "#f5e0dc", "#cdd6f4", "#f9e2af"

TAU = 2 * math.pi
W, H, U, t, LOOP, ph = 1920, 1080, 1.08, 0.0, 12.0, 0.0
defs, body = [], []

SCREENS = {"laptop": (1920, 1080, 0, 360), "front": (2560, 1440, 1920, 0), "right": (1920, 1080, 4480, 180)}
DESK_W, DESK_H = 6400, 1440
PX = 1.44   # one desk unit = a thousandth of the front screen's height
NAME, SCREEN = "front", SCREENS["front"]


# --- Drawing helpers ------------------------------------------------------------------------------------------------
def setup(w, h, time=0.0, loop=12.0):
    """Canvas size and animation time; also usable from other scripts (import gen; gen.setup(...))."""
    global W, H, U, t, LOOP, ph
    W, H, t, LOOP = w, h, time, loop
    U = H / 1000.0                   # one "unit" = a thousandth of the screen height
    ph = TAU * t / LOOP              # loop phase, 0..2pi
    defs.clear()
    body.clear()


def wave(k=1, offset=0.0):           # periodic in the loop: k whole cycles per loop
    return math.sin(k * ph + offset)


def glow_filter(fid, std):
    defs.append(f'<filter id="{fid}" x="-50%" y="-50%" width="200%" height="200%">'
                f'<feGaussianBlur in="SourceGraphic" stdDeviation="{std:.2f}" result="b"/>'
                f'<feMerge><feMergeNode in="b"/><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>')


def blur_filter(fid, std):
    defs.append(f'<filter id="{fid}" x="-50%" y="-50%" width="200%" height="200%">'
                f'<feGaussianBlur stdDeviation="{std:.2f}"/></filter>')


def lin_grad(gid, stops, x1=0, y1=0, x2=1, y2=0, user=None):
    units = ""
    if user:
        x1, y1, x2, y2 = user
        units = ' gradientUnits="userSpaceOnUse"'
    s = "".join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o, c, a in stops)
    defs.append(f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"{units}>{s}</linearGradient>')


def rad_grad(gid, stops, cx=0.5, cy=0.5, r=0.5, user=False):
    units = ' gradientUnits="userSpaceOnUse"' if user else ""
    s = "".join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o, c, a in stops)
    defs.append(f'<radialGradient id="{gid}" cx="{cx}" cy="{cy}" r="{r}"{units}>{s}</radialGradient>')


def background(top, bottom, glow_xy=None, glow_col=MAUVE, glow_a=0.10):
    lin_grad("bg", [(0, top, 1), (1, bottom, 1)], 0, 0, 0, 1)
    body.append(f'<rect width="{W}" height="{H}" fill="url(#bg)"/>')
    if glow_xy:
        gx, gy, gr = glow_xy
        rad_grad("bgglow", [(0, glow_col, glow_a), (1, glow_col, 0)], gx * W, gy * H, gr * H, user=True)
        body.append(f'<rect width="{W}" height="{H}" fill="url(#bgglow)"/>')


def nebula(seed, colors, band, opacity=0.5, freq=1.4, cut=1.25):
    """Soft clouds: fractal noise as alpha over a colour gradient, kept to an elliptical band (cx, cy, rx, ry)."""
    fx, fy = freq / H, freq * 1.6 / H
    defs.append(f'<filter id="neb{seed}" x="0" y="0" width="{W}" height="{H}" filterUnits="userSpaceOnUse">'
                f'<feTurbulence type="fractalNoise" baseFrequency="{fx:.6f} {fy:.6f}" numOctaves="5" seed="{seed}" result="n"/>'
                f'<feColorMatrix in="n" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  3.2 0 0 0 -{cut}" result="m"/>'
                f'<feComposite in="SourceGraphic" in2="m" operator="in"/></filter>')
    stops = [(i / (len(colors) - 1), c, 1) for i, c in enumerate(colors)]
    lin_grad(f"nebc{seed}", stops, 0, 0, 1, 1)
    cx, cy, rx, ry = band
    rad_grad(f"nebm{seed}", [(0, "#fff", 1), (0.55, "#fff", 0.6), (1, "#fff", 0)], cx * W, cy * H, 1, user=True)
    defs.append(f'<mask id="nebmask{seed}" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">'
                f'<ellipse cx="{cx * W}" cy="{cy * H}" rx="{rx * W}" ry="{ry * H}" fill="url(#nebmr{seed})"/></mask>')
    rad_grad(f"nebmr{seed}", [(0, "#fff", 1), (0.6, "#fff", 0.55), (1, "#fff", 0)])
    dx, dy = 14 * U * math.cos(ph + seed), 9 * U * math.sin(ph + seed)       # the clouds drift on a slow circle
    body.append(f'<g mask="url(#nebmask{seed})" opacity="{opacity}"><rect width="{W}" height="{H}" '
                f'fill="url(#nebc{seed})" filter="url(#neb{seed})" transform="translate({dx:.1f} {dy:.1f})"/></g>')


def starfield(seed, n, avoid=None, bright=24, ymax=1.0):
    rng = random.Random(seed)
    palette = [TEXT] * 8 + [LAVENDER, BLUE, PEACH, ROSE, TEAL]
    out = []
    for i in range(n):
        x, y = rng.random() * W, rng.random() * H * ymax
        r = (0.35 + rng.random() ** 3 * 1.1) * U * 1.1
        base = 0.25 + rng.random() * 0.6
        tw = 0.25 * wave(rng.choice([1, 2, 3]), rng.random() * TAU)      # gentle twinkle
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.2f}" fill="{rng.choice(palette)}" '
                   f'opacity="{max(0.05, min(1, base + tw * base)):.2f}"/>')
    body.append("<g>" + "".join(out) + "</g>")
    glow_filter("starglow", 2.2 * U)
    out = []
    for i in range(bright):
        x, y = rng.random() * W, rng.random() * H * ymax
        r = (1.3 + rng.random() * 1.2) * U
        a = 0.7 + 0.3 * wave(1, rng.random() * TAU)
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.2f}" fill="{rng.choice([TEXT, LAVENDER, PEACH, BLUE])}" '
                   f'opacity="{a:.2f}"/>')
    body.append('<g filter="url(#starglow)">' + "".join(out) + "</g>")


def particles(seed, n):
    rng = random.Random(seed)
    out = []
    for i in range(n):
        x, y = rng.random() * W, rng.random() * H
        rr = (8 + rng.random() * 18) * U                # each drifts on a small slow circle
        k = rng.choice([1, 1, 2])
        a0 = rng.random() * TAU
        x += rr * math.cos(k * ph + a0)
        y += rr * math.sin(k * ph + a0)
        r = (0.5 + rng.random() * 1.6) * U
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.2f}" fill="{rng.choice([TEAL, LAVENDER, BLUE, PINK])}" '
                   f'opacity="{0.15 + rng.random() * 0.45:.2f}"/>')
    glow_filter("pglow", 1.6 * U)
    body.append('<g filter="url(#pglow)">' + "".join(out) + "</g>")


def halo(gid, x, y, r, col1, col2, a=0.16):
    rad_grad(gid, [(0, col1, a), (0.5, col2, a / 3), (1, col2, 0)], x * W, y * H, r * H, user=True)
    body.append(f'<rect width="{W}" height="{H}" fill="url(#{gid})"/>')


def light_rays(col, a=0.06):
    blur_filter("rays", 30 * U)
    out = []
    for i, (x, w, ang) in enumerate([(0.30, 0.07, 14), (0.42, 0.05, 11), (0.55, 0.09, 9), (0.70, 0.04, 7)]):
        op = a * (0.75 + 0.25 * wave(1, i * 1.7))
        out.append(f'<rect x="{x * W:.1f}" y="{-0.2 * H:.1f}" width="{w * W:.1f}" height="{1.2 * H:.1f}" fill="{col}" '
                   f'opacity="{op:.3f}" transform="rotate({ang} {x * W:.1f} 0)"/>')
    lin_grad("rayfade", [(0, "#fff", 1), (0.7, "#fff", 0.25), (1, "#fff", 0)], 0, 0, 0, 1)
    defs.append(f'<mask id="raymask" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">'
                f'<rect width="{W}" height="{H}" fill="url(#rayfade)"/></mask>')
    body.append('<g mask="url(#raymask)" filter="url(#rays)">' + "".join(out) + "</g>")


# --- Creatures ------------------------------------------------------------------------------------------------------
def jellyfish(cx, cy, s, grad, opacity, seed, depth_blur=0.0, fade=(LAVENDER, MAUVE), tent=1.0, n=7, arms=4,
              sway=1.0):
    rng = random.Random(seed)
    p = rng.random() * TAU
    cy += s * 0.10 * wave(1, p)                       # bob
    pulse = 1 + 0.045 * wave(2, p)                    # the bell breathes
    bw, bh = s * pulse, s * 1.15 / pulse
    scallop = []
    xs = [cx + bw - 2 * bw * i / n for i in range(n + 1)]
    for i in range(n):
        xm = (xs[i] + xs[i + 1]) / 2
        scallop.append(f"Q {xm:.1f} {cy + 0.16 * s:.1f} {xs[i + 1]:.1f} {cy:.1f}")
    bell = (f"M {cx - bw:.1f} {cy:.1f} C {cx - bw:.1f} {cy - bh * 1.05:.1f} {cx + bw:.1f} {cy - bh * 1.05:.1f} "
            f"{cx + bw:.1f} {cy:.1f} " + " ".join(scallop) + " Z")
    inner = (f"M {cx - bw * 0.62:.1f} {cy - 0.05 * s:.1f} C {cx - bw * 0.62:.1f} {cy - bh * 0.72:.1f} "
             f"{cx + bw * 0.62:.1f} {cy - bh * 0.72:.1f} {cx + bw * 0.62:.1f} {cy - 0.05 * s:.1f}")
    paths = [f'<path d="{bell}" fill="url(#{grad})" fill-opacity="0.10"/>', f'<path d="{inner}" opacity="0.55"/>']
    # oral arms: a few thicker, curly strands from the centre
    for j in range(arms):
        x0 = cx + (j - (arms - 1) / 2) * s * 0.16
        d = f"M {x0:.1f} {cy + 0.05 * s:.1f}"
        L, steps = s * (1.5 + 0.3 * rng.random()), 14
        for k in range(1, steps + 1):
            f = k / steps
            x = x0 + math.sin(f * 5 + j + 1.2 * wave(1, p + j)) * s * 0.10 * f * 1.5
            d += f" L {x:.1f} {cy + 0.05 * s + f * L:.1f}"
        paths.append(f'<path d="{d}" stroke-width="{0.022 * s:.2f}" opacity="{0.75 - 0.1 * j % 2:.2f}"/>')
    # tentacles: long thin ones from the rim, swaying, fading out
    for j in range(n + 1):
        x0 = xs[j]
        d = f"M {x0:.1f} {cy:.1f}"
        L, steps = s * (2.4 + 1.0 * rng.random()) * tent, 22
        for k in range(1, steps + 1):
            f = k / steps
            sway_x = math.sin(f * 3.2 + j * 0.7 + wave(1, p + j * 0.4)) * s * 0.16 * f * sway
            d += f" L {x0 + sway_x:.1f} {cy + f * L:.1f}"
        paths.append(f'<path d="{d}" stroke-width="{0.010 * s:.2f}" stroke="url(#{grad}fade{seed})" opacity="0.8"/>')
    flt = f' filter="url(#jglow{seed})"'
    glow_filter(f"jglow{seed}", 0.035 * s + depth_blur)
    lin_grad(f"{grad}fade{seed}", [(0, fade[0], 0.9), (0.6, fade[1], 0.35), (1, fade[1], 0)], 0, 0, 0, 1,
             user=(0, cy, 0, cy + s * 3.3 * tent))
    body.append(f'<g fill="none" stroke="url(#{grad})" stroke-width="{0.03 * s:.2f}" stroke-linecap="round" '
                f'stroke-linejoin="round" opacity="{opacity}"{flt}>' + "".join(paths) + "</g>")


def moon_jelly(cx, cy, s, c1, c2, opacity, seed, depth_blur=0.0):
    rng = random.Random(seed)
    p = rng.random() * TAU
    cy += s * 0.08 * wave(1, p)
    pulse = 1 + 0.05 * wave(2, p)
    bw, bh = s * 1.15 * pulse, s * 0.62 / pulse
    gid = f"mj{seed}"
    lin_grad(gid, [(0, c1, 1), (1, c2, 1)], 0, 0, 1, 1)
    bell = (f"M {cx - bw:.1f} {cy:.1f} C {cx - bw:.1f} {cy - bh * 1.3:.1f} {cx + bw:.1f} {cy - bh * 1.3:.1f} "
            f"{cx + bw:.1f} {cy:.1f} Q {cx:.1f} {cy + 0.16 * s:.1f} {cx - bw:.1f} {cy:.1f} Z")
    parts = [f'<path d="{bell}" fill="url(#{gid})" fill-opacity="0.12"/>']
    for dx, dy in [(-0.40, -0.24), (-0.14, -0.33), (0.14, -0.33), (0.40, -0.24)]:   # the four gonad rings
        parts.append(f'<ellipse cx="{cx + dx * s * pulse:.1f}" cy="{cy + dy * s:.1f}" rx="{0.10 * s:.1f}" '
                     f'ry="{0.065 * s:.1f}" stroke="{PINK}" opacity="0.38" stroke-width="{0.018 * s:.2f}"/>')
    # a fringe of short tentacles all around the rim
    for j in range(28):
        f0 = j / 27
        x0 = cx - bw + 2 * bw * f0
        y0 = cy + 0.16 * s * 4 * f0 * (1 - f0) * 0.5
        L = s * (0.32 + 0.18 * rng.random())
        d = f"M {x0:.1f} {y0:.1f}"
        for k in range(1, 7):
            f = k / 6
            d += f" L {x0 + math.sin(f * 2.5 + j + wave(1, p + j * 0.3)) * s * 0.05 * f:.1f} {y0 + f * L:.1f}"
        parts.append(f'<path d="{d}" stroke-width="{0.009 * s:.2f}" opacity="0.6"/>')
    # four short frilly oral arms
    for j in range(4):
        x0 = cx + (j - 1.5) * s * 0.12
        d = f"M {x0:.1f} {cy:.1f}"
        for k in range(1, 13):
            f = k / 12
            d += f" L {x0 + math.sin(f * 9 + j * 2 + wave(1, p + j)) * s * 0.05:.1f} {cy + f * s * 0.75:.1f}"
        parts.append(f'<path d="{d}" stroke-width="{0.016 * s:.2f}" opacity="0.6"/>')
    glow_filter(f"mjg{seed}", 0.03 * s + depth_blur)
    body.append(f'<g fill="none" stroke="url(#{gid})" stroke-width="{0.025 * s:.2f}" stroke-linecap="round" '
                f'opacity="{opacity}" filter="url(#mjg{seed})">' + "".join(parts) + "</g>")


def neon_group(content, grad, width, glow_id, glow_std, opacity=1.0):
    glow_filter(glow_id, glow_std)
    return (f'<g fill="none" stroke="url(#{grad})" stroke-width="{width:.2f}" stroke-linecap="round" '
            f'stroke-linejoin="round" opacity="{opacity}" filter="url(#{glow_id})">{content}</g>')


def whale(cx, cy, length, facing_left=True, opacity=1.0, depth_blur=0.0, bubbles=True):
    """A humpback whale drawn in a 200 x 80 box (head left), centred on (cx, cy). depth_blur in pixels."""
    p = 0.4
    s = length / 200.0
    bob = 0.03 * length * wave(1, p)
    drift = 0.04 * length * wave(1, p + 1.6)
    tilt = -3 + 1.5 * wave(1, p + 0.9)
    fluke = 7 * wave(1, p + 2.4)        # the tail beats slowly
    fin = 3 * wave(1, p + 0.3)          # the long fins move a little
    lin_grad("wh", [(0, TEAL, 1), (0.45, SAPPHIRE, 1), (0.8, BLUE, 1), (1, LAVENDER, 1)], 0, 0, 1, 0)
    body_path = ("M 2 38 C 10 26 40 19 70 20 C 100 21 124 24 138 28 L 145 23.5 L 150 29.5 "
                 "C 163 33 175 36 184 38.5 "
                 "L 184 41.5 C 172 44.5 158 47.5 140 50 C 110 57 70 60 40 56 C 20 52 6 46 2 38 Z")
    flukes = ("M 182 40 C 188 36 192 30 199 24 C 197 32 194 37 190 40 C 194 43 197 48 199 56 "
              "C 192 50 188 44 182 40 Z")
    pec = "M 56 50 C 70 66 92 79 118 84 C 104 76 84 62 68 52"
    pec_far = "M 62 49 C 74 60 92 70 110 74"
    mouth = "M 3 39 C 14 42 26 44 38 44.5"
    grooves = "".join(f'<path d="M {6 + 4 * k} {43 + 2.2 * k} C {30 + 6 * k} {50 + 1.5 * k} {50 + 8 * k} {55 + 1 * k} '
                      f'{70 + 9 * k} {57 + 0.6 * k}" stroke-width="0.9" opacity="0.4"/>' for k in range(4))
    inner = (f'<path d="{body_path}" fill="url(#wh)" fill-opacity="0.10"/>'
             f'<g transform="rotate({fluke:.2f} 184 40)"><path d="{flukes}" fill="url(#wh)" fill-opacity="0.10"/></g>'
             f'<path d="{pec_far}" opacity="0.35" stroke-width="1.2" transform="rotate({-fin:.2f} 62 49)"/>'
             f'<g transform="rotate({fin:.2f} 56 50)"><path d="{pec}" fill="url(#wh)" fill-opacity="0.08"/></g>'
             f'<path d="{mouth}" stroke-width="1.2"/>{grooves}')
    eye = f'<circle cx="41" cy="40.5" r="1.6" fill="{PEACH}" stroke="none"/>'
    flip = 1 if facing_left else -1
    tf = (f"translate({cx + drift:.1f} {cy + bob:.1f}) rotate({tilt:.2f}) scale({flip * s:.4f} {s:.4f}) "
          f"translate(-100 -40)")
    glow = 1.2 + depth_blur / s
    body_ = body
    body_.append(f'<g transform="{tf}" opacity="{opacity}">{neon_group(inner, "wh", 1.8, "whglow", glow)}'
                 f'{neon_group(eye, "wh", 0, "eyeglow", 0.8 + depth_blur / s)}</g>')
    if bubbles:   # a few bubbles from the blowhole, rising and fading (each on its own phase: seamless loop)
        rng = random.Random(9)
        bub = []
        for i in range(5):
            f = (t / LOOP + i / 5) % 1.0
            bx = cx + drift + flip * (-70) * s + 0.02 * length * math.sin(TAU * f + i)
            by = cy + bob - 20 * s - f * 0.5 * length
            bub.append(f'<circle cx="{bx:.1f}" cy="{by:.1f}" r="{(0.5 + 0.6 * rng.random()) * 2 * s:.2f}" '
                       f'fill="none" stroke="{TEXT}" stroke-width="{0.6 * U:.2f}" '
                       f'opacity="{0.4 * opacity * math.sin(math.pi * f):.2f}"/>')
        body_.append("".join(bub))


# --- The desk: fog and the three scenes -----------------------------------------------------------------------------
def desk_fog(seed, colors, band, opacity, freq=1.1, cut=1.25, drift=(14, 9)):
    """Fractal-noise clouds computed in desk coordinates and seen through this screen's window: they continue
    from one screen into the next. They drift on a slow circle (seamless loop)."""
    W, H, OX, OY = SCREEN
    fx, fy = freq / DESK_H, freq * 1.6 / DESK_H
    dx = drift[0] * PX * math.cos(ph + seed)
    dy = drift[1] * PX * math.sin(ph + seed)
    defs.append(f'<filter id="dfog{seed}" x="{OX - 60}" y="{OY - 60}" width="{W + 120}" height="{H + 120}" '
                  f'filterUnits="userSpaceOnUse"><feTurbulence type="fractalNoise" baseFrequency="{fx:.6f} {fy:.6f}" '
                  f'numOctaves="5" seed="{seed}" result="n"/><feColorMatrix in="n" type="matrix" values="0 0 0 0 0  '
                  f'0 0 0 0 0  0 0 0 0 0  3.2 0 0 0 -{cut}" result="m"/>'
                  f'<feComposite in="SourceGraphic" in2="m" operator="in"/></filter>')
    stops = "".join(f'<stop offset="{i / (len(colors) - 1)}" stop-color="{c}"/>' for i, c in enumerate(colors))
    defs.append(f'<linearGradient id="dfogc{seed}" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="{DESK_W}" '
                  f'y2="{DESK_H}">{stops}</linearGradient>')
    cx, cy, rx, ry = band
    defs.append(f'<radialGradient id="dfogm{seed}" gradientUnits="userSpaceOnUse" cx="{cx}" cy="{cy}" r="1" '
                  f'gradientTransform="translate({cx} {cy}) scale({rx} {ry}) translate({-cx} {-cy})">'
                  f'<stop offset="0" stop-color="#fff"/><stop offset="0.6" stop-color="#fff" stop-opacity="0.6"/>'
                  f'<stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>')
    defs.append(f'<mask id="dfogmask{seed}" maskUnits="userSpaceOnUse" x="{OX}" y="{OY}" width="{W}" height="{H}">'
                  f'<rect x="{OX}" y="{OY}" width="{W}" height="{H}" fill="url(#dfogm{seed})"/></mask>')
    body.append(f'<g transform="translate({-OX} {-OY})"><g mask="url(#dfogmask{seed})" opacity="{opacity}">'
                  f'<g transform="translate({dx:.1f} {dy:.1f})"><rect x="{OX - 60}" y="{OY - 60}" width="{W + 120}" '
                  f'height="{H + 120}" fill="url(#dfogc{seed})" filter="url(#dfog{seed})"/></g></g></g>')


def base(glow_xy, glow_col):
    background(MANTLE, CRUST, glow_xy, glow_col, 0.10)
    # the fog from the first jellyfish picture, now one band of clouds across the whole desk
    desk_fog(21, [BLUE, SAPPHIRE, TEAL, BLUE, SAPPHIRE], (3300, 780, 4300, 1000), opacity=0.24, freq=1.1)
    seeds = {"laptop": (201, 211), "front": (202, 212), "right": (203, 213)}[NAME]
    starfield(seeds[0], int(W * H / 5200), bright=int(12 * W * H / (1920 * 1080)))
    particles(seeds[1], int(140 * W * H / (1920 * 1080)))


def laptop():
    base((0.68, 0.45, 0.8), BLUE)
    whale(0.25 * W, 0.28 * H, 0.13 * W, facing_left=False, opacity=0.34, depth_blur=3 * U)
    moon_jelly(0.40 * W, 0.70 * H, 0.034 * H, BLUE, LAVENDER, 0.45, 61, depth_blur=1.2 * U)
    lin_grad("jw1", [(0, PINK, 1), (0.5, MAUVE, 1), (1, BLUE, 1)], 0, 0, 1, 1)
    halo("halo", 0.70, 0.42, 0.42, MAUVE, PINK, 0.15)
    jellyfish(0.70 * W, 0.34 * H, 0.11 * H, "jw1", 0.95, 33)


def front():
    """Bloom: five at different depths, spread out (the user picked five of the eight placed below: the closest
    teal one, the moon jellyfish, the faint one top right, a blue one upper left and a lavender one bottom right)."""
    base((0.62, 0.45, 0.9), BLUE)
    nebula(48, [BLUE, MAUVE, TEAL], (0.6, 0.5, 0.8, 0.6), opacity=0.08, freq=1.1)
    cols = [(TEAL, BLUE), (LAVENDER, MAUVE), (BLUE, SAPPHIRE), (PINK, MAUVE)]
    rng = random.Random(56)
    jellies = []
    while len(jellies) < 8:
        depth = rng.random()                                   # 0 = far away, 1 = close
        x, y = 0.34 + 0.62 * rng.random(), 0.12 + 0.55 * rng.random()
        sz = 0.022 + 0.06 * depth
        clash = any(abs(x - x2) * W / H < 1.6 * (sz + sz2) and (y - 1.2 * sz) < (y2 + 3.4 * sz2) and
                    (y2 - 1.2 * sz2) < (y + 3.4 * sz) for d2, x2, y2, k2, sz2 in jellies)
        if not clash:
            jellies.append((depth, x, y, len(jellies), sz))
    # the moon jellyfish: the one in the middle of the depth range, so it's neither the biggest nor a speck
    by_depth = sorted(jellies)
    moon_k = by_depth[len(by_depth) // 2][3]
    keep = {0, 1, 2, 3, moon_k}                                # dropped: a speck beside the moon one, and a 2nd top-right
    for depth, x, y, k, sz in by_depth:
        if k not in keep:
            continue
        c1, c2 = cols[k % 4]
        blur = (1 - depth) * 3 * U
        if k == moon_k:
            moon_jelly(x * W, (y + 0.03) * H, sz * H * 1.05, LAVENDER, PINK, 0.3 + 0.7 * depth, 160 + k,
                         depth_blur=blur)
        else:
            lin_grad(f"bl{k}", [(0, c1, 1), (1, c2, 1)], 0, 0, 1, 1)
            jellyfish(x * W, y * H, sz * H, f"bl{k}", 0.25 + 0.7 * depth, 60 + k, depth_blur=blur, fade=(c1, c2))


def right():
    base((0.45, -0.05, 1.0), TEAL)
    light_rays(TEAL, 0.07)
    lin_grad("lw2", [(0, LAVENDER, 1), (1, MAUVE, 1)], 0, 0, 1, 1)
    jellyfish(0.82 * W, 0.26 * H, 0.024 * H, "lw2", 0.30, 51, depth_blur=2.5 * U, fade=(LAVENDER, MAUVE))
    moon_jelly(0.16 * W, 0.74 * H, 0.022 * H, BLUE, LAVENDER, 0.28, 64, depth_blur=2.5 * U)
    # the "solo" jellyfish (pink to blue, long tentacles) where the whale was, a little right of centre
    lin_grad("so1", [(0, PINK, 1), (0.5, MAUVE, 1), (1, BLUE, 1)], 0, 0, 1, 1)
    halo("halo", 0.58, 0.44, 0.30, MAUVE, BLUE, 0.10)
    jellyfish(0.58 * W, 0.36 * H, 0.085 * H, "so1", 0.95, 55, tent=1.1)


def svg():
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">'
            f'<defs>{"".join(defs)}</defs>{"".join(body)}</svg>')


if __name__ == "__main__":
    NAME, out = sys.argv[1], sys.argv[2]
    SCREEN = SCREENS[NAME]
    setup(SCREEN[0], SCREEN[1], float(sys.argv[3]) if len(sys.argv) > 3 else 0.0,
          float(sys.argv[4]) if len(sys.argv) > 4 else 12.0)
    {"laptop": laptop, "front": front, "right": right}[NAME]()
    with open(out, "w") as f:
        f.write(svg())
