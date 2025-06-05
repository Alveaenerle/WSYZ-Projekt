# Plik modelu do optymalizacji dystrybucji warzyw w Warszawie
# Minimalizuje całkowite roczne koszty transportu od producentów do magazynów i od magazynów do sklepów
# Zawiera ograniczenia dotyczące podaży, pojemności magazynów, zapasów w sklepach i popytu

# --- Zbiory ---
# Definiują indeksy używane w modelu
set P;    # Zbiór producentów (P1, P2, ..., P6)
set M;    # Zbiór magazynów (M1, M2, M3)
set S;    # Zbiór sklepów (S1, S2, ..., S10)
set V;    # Zbiór typów warzyw (Ziemniaki, Kapusta, Buraki, Marchew)
set T;    # Zbiór tygodni w roku (1, 2, ..., 52)

# --- Parametry ---
# Dane wejściowe dla modelu, podane w pliku .dat
param SP{P, V};      # Maksymalna roczna podaż warzywa v przez producenta p (w tonach)
param WC{M};         # Pojemność magazynowa magazynu m (w tonach)
param D{S, V, T};    # Prognozowany popyt na warzywo v w sklepie s w tygodniu t (w tonach)
param SC{S};         # Pojemność magazynowa sklepu s (w tonach)
param MinS{S, V};    # Minimalny poziom zapasów warzywa v w sklepie s (w tonach)
param d_pm{P, M};    # Odległość od producenta p do magazynu m (w km)
param d_ms{M, S};    # Odległość od magazynu m do sklepu s (w km)
param c;             # Koszt transportu za tonę na km (w PLN)

# --- Zmienne ---
# Zmienne decyzyjne dla transportu i zapasów
var X{p in P, m in M, v in V} >= 0;  # Tony warzywa v transportowane od producenta p do magazynu m rocznie
var Y{m in M, s in S, v in V, t in T} >= 0;  # Tony warzywa v transportowane od magazynu m do sklepu s w tygodniu t
var I{s in S, v in V, t in T} >= 0;  # Zapas warzywa v w sklepie s na koniec tygodnia t
var W{m in M, v in V} >= 0;  # Całkowita ilość warzywa v przechowywana w magazynie m rocznie

# --- Funkcja celu ---
# Minimalizacja całkowitego kosztu transportu (od producenta do magazynu + od magazynu do sklepu)
minimize Całkowity_Koszt:
    c * (sum{p in P, m in M, v in V} d_pm[p,m] * X[p,m,v] +
         sum{t in T, m in M, s in S, v in V} d_ms[m,s] * Y[m,s,v,t]);
# Koszt obliczany jako koszt za tonę na km pomnożony przez odległość i ilość transportowaną

# --- Ograniczenia ---
# 1. Ograniczenie podaży producenta
# Zapewnienie, że suma dostaw od każdego producenta nie przekracza ich zdolności podażowej
subject to Ograniczenie_Podaży{p in P, v in V}:
    sum{m in M} X[p,m,v] <= SP[p,v];

# 2. Ograniczenie pojemności magazynu
# Całkowite przechowywanie w każdym magazynie nie może przekraczać jego pojemności
subject to Ograniczenie_Pojemności_Magazynu{m in M}:
    sum{v in V} W[m,v] <= WC[m];

# 3. Definicja przechowywania w magazynie
# Ilość przechowywana w każdym magazynie równa się całkowitemu napływowi od producentów
subject to Definicja_Przechowywania_Magazynu{m in M, v in V}:
    W[m,v] = sum{p in P} X[p,m,v];

# 4. Bilans przepływu w magazynie
# Roczny napływ do każdego magazynu równa się rocznemu odpływowi do sklepów
subject to Bilans_Przepływu_Magazynu{m in M, v in V}:
    sum{p in P} X[p,m,v] = sum{t in T, s in S} Y[m,s,v,t];

# 5. Bilans zapasów w sklepie
# Zapas na koniec tygodnia t = zapas z poprzedniego tygodnia + dostawy - popyt
subject to Bilans_Zapasów_Sklepu{s in S, v in V, t in T: t > 1}:
    I[s,v,t] = I[s,v,t-1] + sum{m in M} Y[m,s,v,t] - D[s,v,t];

# 6. Initial Inventory
# Inventory for week 1 starts from zero, with deliveries covering demand
subject to Początkowy_Zapas{s in S, v in V}:
    I[s,v,1] = sum{m in M} Y[m,s,v,1] - D[s,v,1];


# 7. Store Capacity Constraint
# Total inventory in each store must not exceed its capacity for all weeks
subject to Ograniczenie_Pojemności_Sklepu{s in S, t in T}:
    sum{v in V} I[s,v,t] <= SC[s];

# 8. Ograniczenie minimalnego zapasu
# Zapas w każdym sklepie musi spełniać minimalne poziomy, aby buforować wahania popytu
subject to Ograniczenie_Minimalnego_Zapasu{s in S, v in V, t in T}:
    I[s,v,t] >= MinS[s,v];