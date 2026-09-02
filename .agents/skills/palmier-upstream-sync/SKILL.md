---
name: palmier-upstream-sync
description: Den Palmier-Pro-Fork (koeseo/palmier-pro) vom Upstream palmier-io aktualisieren, ohne die KoeHub-Anpassungen zu verlieren — insbesondere den abgeschalteten Sparkle-Auto-Update. Use bei „Palmier updaten", „Palmier syncen", „Palmier Upstream holen" oder wenn in ~/appz/palmier-pro ein Update ansteht.
---

# Palmier Pro — Upstream-Sync (KoeHub-Fork)

Seit 02.09.2026 ist `~/appz/palmier-pro` ein Fork mit eigenen Anpassungen.
`origin` = `koeseo/palmier-pro`, `upstream` = `palmier-io/palmier-pro`.

**Das vollständige Runbook liegt im Repo:** `~/appz/palmier-pro/KOEHUB-FORK.md`
— Konstellation, Anpassungs-Tabelle, Build-Rezept, Fallstricke. **Immer zuerst
lesen**, es bleibt beim Code und überlebt jeden Re-Clone.

## Was diesen Fork von den anderen unterscheidet

Der Upstream hat am 28.08.2026 die **öffentliche Quellcode-Entwicklung eingestellt**
(Commit `eba39db`, „Retire public source development"). Daraus folgt dreierlei:

- **Der Quellcode steht still.** `main` trägt denselben Quellstand wie das Tag
  `last-gpl-source` — Stand v0.7.6, GPLv3. Neuere Releases (v0.8.x) sind proprietär,
  ihr Quellcode wird nicht veröffentlicht.
- **Was der Upstream noch pusht, sind Binär-Artefakte:** `appcast.xml` und
  Release-Metadaten. Ein Sync bringt fast nie Code, sondern Update-Metadaten — genau
  das, was unser Sparkle-Patch tot legt.
- **Ein Sync ist deshalb selten dringend.** Vor jedem Lauf erst nachsehen, ob
  überhaupt Code kommt: `git log --oneline --stat main..upstream/main -- Sources Metal Package.swift`.
  Nur `appcast.xml`-Commits sind kein Grund zu mergen.

## Preflight — nicht raten, nachsehen

```bash
git -C ~/appz/palmier-pro remote -v      # origin = koeseo, upstream-PUSH muss DISABLED sein
git -C ~/appz/palmier-pro status --short # Baum muss sauber sein
```

Die Push-URL von `upstream` steht bewusst auf `DISABLED_no_push_to_upstream`. Nie
nach `upstream` pushen — wir haben dort nichts zu suchen und der Fork ist unsere
einzige Publikationsstelle.

## Ablauf

```bash
cd ~/appz/palmier-pro
git fetch --all --prune --tags

# 1. Sichern — vor jedem Merge, ohne Ausnahme
git branch -f koehub-sicherung main
git tag "koehub-vor-sync-$(date +%Y%m%d)" main
git push origin koehub-sicherung "koehub-vor-sync-$(date +%Y%m%d)"

# 2. Prüfen, was überhaupt kommt
git log --oneline main..upstream/main
git log --oneline --stat main..upstream/main -- Sources Metal Package.swift scripts

# 3. Konflikt-Vorprüfung (read-only) — dann selbst mergen
git merge-tree --write-tree main upstream/main | grep -i conflict || echo "konfliktfrei"
git merge upstream/main -m "merge: Upstream nachgezogen (<N> Commits, <Datum>)"

# 4. Nachweisen, dass unsere Anpassungen den Merge überlebt haben
git log --oneline upstream/main..main
bash tools/pruefe-sparkle-aus.sh          # Pflicht-Gate, siehe unten

# 5. Neu bauen und starten — ein grüner Merge ist kein grüner Build
scripts/bundle.sh debug

# 6. Publizieren
git push origin main
```

Merge, nie Rebase — die in `KOEHUB-FORK.md` dokumentierten Commit-SHAs müssen
gültig bleiben.

## Pflicht-Gate nach jedem Sync: Sparkle muss tot bleiben

Der Auto-Update ist der eine Patch, dessen Verlust den Fork stillschweigend
zerstört: Sparkle zöge das nächste **proprietäre** Upstream-Release über unseren
eigenen Build. Der Verlust fällt nicht auf, bis die App sich selbst ersetzt hat.

Der Patch hat zwei Riegel, beide müssen stehen:

| Riegel | Ort | Prüfung |
|---|---|---|
| Kein Feed in der Bundle-Konfiguration | `Sources/PalmierPro/Resources/Info.plist` | `SUFeedURL` fehlt, `SUEnableAutomaticChecks` ist `false` |
| Harter Riegel im Code | `Sources/PalmierPro/App/Updater.swift` | früher `return` vor `SPUStandardUpdaterController` |

Zwei Riegel, weil sie an verschiedenen Stellen liegen: Ein Merge, der die
Info.plist vom Upstream übernimmt, lässt den Code-Riegel stehen und umgekehrt.
Ein einzelner Riegel wäre bei jedem Konflikt eine stille Wette.

Prüfen — beide Zeilen müssen leer bleiben bzw. den Patch zeigen:

```bash
grep -n "SUFeedURL\|SUEnableAutomaticChecks" Sources/PalmierPro/Resources/Info.plist
grep -n "KoeHub-Fork" Sources/PalmierPro/App/Updater.swift
```

Und am gebauten Bundle gegenprüfen, denn nur das zählt:

```bash
/usr/libexec/PlistBuddy -c "Print :SUFeedURL" .build/PalmierPro.app/Contents/Info.plist
# erwartet: "Does Not Exist"
```

## Konfliktregeln

- **`appcast.xml`** — immer die Upstream-Fassung nehmen (`git checkout --theirs appcast.xml`).
  Die Datei ist für uns tot; ein Konflikt darin ist reine Reibung.
- **`Info.plist`** — nie blind `--theirs`. Upstream-Änderungen von Hand übernehmen,
  danach `SUFeedURL` wieder entfernen und `SUEnableAutomaticChecks` auf `false` setzen.
- **`Updater.swift`** — Upstream-Änderungen übernehmen, unseren `return`-Riegel
  direkt hinter `super.init()` wieder einsetzen.
- **`Package.swift` / `Package.resolved`** — Upstream-Fassung nehmen, danach neu
  bauen. Ein aufgelöster Dependency-Graph aus einem Merge ist nichts wert.
- Alles andere: normaler Merge. Bei Zweifel `KOEHUB-FORK.md`-Tabelle lesen — sie
  sagt, welche Abweichung Absicht war.

## Nicht verhandelbar

- **Anpassungen liegen auf `main`, nie auf einem Nebenbranch.** Der Build läuft aus
  dem ausgecheckten Baum; ein Patch auf einem Nebenbranch ist ein Patch, der nicht wirkt.
- **Erst sichern, dann mergen.** Branch + Tag sind der Rückweg.
- **Jede neue Anpassung in die Tabelle in `KOEHUB-FORK.md`** — mit dem Warum. Ohne
  das weiß beim nächsten Konflikt niemand, welche Abweichung Absicht war.
- **Die installierte Release-App unter `/Applications/Palmier Pro.app` ist tabu.**
  Sie ist der proprietäre v0.8.x-Store-Stand und gehört nicht zu diesem Fork. Unser
  Build lebt ausschließlich unter `~/appz/palmier-pro/.build/PalmierPro.app`.
- **Zweimal gescheitert = Stopp.** Rückweg ist der Tag, nicht ein dritter Versuch.
