import random
import math
from pathlib import Path

SEED = 2025   
UTILISATION = 0.90   
OUTPUT = Path("demand.dat")
STORES = [f"S{i}" for i in range(1, 11)]
VEGETABLES = ["Ziemniaki", "Kapusta", "Buraki", "Marchew"]
WEEKS = list(range(1, 53))

# Roczne moce sześciu producentów (suma w nawiasie)
CAPACITIES = {
    "Ziemniaki": 760,   # 200+90+80+100+140+150
    "Kapusta":   570,   # 90+100+70+50+230+30
    "Buraki":    850,   # 120+240+190+160+90+50
    "Marchew":   840,   # 60+80+150+150+210+190
}

random.seed(SEED)

# 1) Przydzielamy roczne zapotrzebowanie na każdy sklep (proporcjonalnie losowo)
store_demands = {v: {} for v in VEGETABLES}
for veg in VEGETABLES:
    total_demand = CAPACITIES[veg] * UTILISATION
    weights = [random.random() for _ in STORES]
    w_sum = sum(weights)
    for s, w in zip(STORES, weights):
        store_demands[veg][s] = total_demand * w / w_sum

# 2) Generujemy profil sezonowy (sinusoida + szum) i
#    rozbijamy roczną wartość na 52 tygodnie
def weekly_profile(annual):
    raw = []
    for w in WEEKS:
        base = 0.5 * (1 + math.sin(2 * math.pi * (w - 13) / 52))  # maksimum w środku roku
        noise = random.uniform(0.8, 1.2)
        raw.append(max(0.1, base * noise))  # nigdy 0
    scale = annual / sum(raw)
    return [qty * scale for qty in raw]

demand = {s: {v: [] for v in VEGETABLES} for s in STORES}
for v in VEGETABLES:
    for s in STORES:
        demand[s][v] = weekly_profile(store_demands[v][s])

# 3) Zapisujemy do pliku w formacie AMPL‑owym
with OUTPUT.open("w", encoding="utf-8") as f:
    for s in STORES:
        f.write(f"# Sklep {s}\n")
        for v in VEGETABLES:
            parts = [
                f"[{s}, {v}, {w}] {qty:.2f}"
                for w, qty in zip(WEEKS, demand[s][v])
            ]
            f.write(" ".join(parts) + "\n")

print(f"✓ Wygenerowano plik: {OUTPUT.resolve()}")
