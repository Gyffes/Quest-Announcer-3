# QA3Icon.tga – 5 grafische Vorschläge (schärfer, sichtbarer)

Basis: `Media/QA3Icon.tga` (853×824).

## 1) Crisp 2x (HUD-freundlich)
- Upscale: **2x Nearest Neighbor** (hart/pixelklar)
- Danach: **Unsharp Mask** (Amount ~45, Radius 0.6, Threshold 1)
- Optional: **+6 Helligkeit**, **+8 Kontrast**
- Effekt: Sehr klare Kanten, gut für kleine HUD-Flächen.

## 2) Smooth 2x (sauber ohne Treppchen)
- Upscale: **2x Lanczos/Bicubic**
- Danach: **Smart Sharpen** (Amount ~70, Radius 0.8)
- Optional: leichte **Klarheit/Clarity +10**
- Effekt: Weniger pixelig, trotzdem deutlich schärfer als Original.

## 3) Contrast Pop 2x (mehr Lesbarkeit)
- Upscale: **2x Bicubic**
- Danach: **Tonwerte/Levels** (Schwarzpunkt leicht anheben, Weißpunkt leicht senken)
- **Sättigung +10 bis +15**
- Schluss: Unsharp Mask (Amount ~55, Radius 0.7)
- Effekt: Icon wirkt kräftiger und bei Bewegung besser erkennbar.

## 4) Edge Boost 2x (Konturen betont)
- Upscale: **2x Lanczos**
- Filter: **High Pass** (Radius 1.2) im Overlay/Soft-Light Mix (30–45%)
- Danach: minimaler **Glow außen** (1–2 px, 20–30% Deckkraft)
- Effekt: Konturen sind sichtbar stärker, besonders auf unruhigem Hintergrund.

## 5) Bold Visibility 2x (starke Ingame-Sichtbarkeit)
- Upscale: **2x Nearest**
- Danach: **Outline/Stroke** in dunkler Farbe (1 px)
- Optional: **inneres Highlight** (sehr dezent)
- Schluss: Kontrast +12, Helligkeit +4
- Effekt: Maximale Trennung vom Hintergrund, sehr gut für schnelle Erkennung.

---

## Empfehlung zum Start
Wenn du nur **eine** Version zuerst testen willst:
- **Vorschlag 2 (Smooth 2x)** für allgemein schönes Ergebnis.
- **Vorschlag 5 (Bold Visibility 2x)**, wenn die Sichtbarkeit im Spiel Priorität hat.
