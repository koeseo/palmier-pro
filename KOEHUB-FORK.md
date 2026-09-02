# KoeHub-Fork von Palmier Pro

Dieses Repo ist `koeseo/palmier-pro`, ein Fork von `palmier-io/palmier-pro`.
Angelegt am 02.09.2026. Es ersetzt nicht die installierte Store-App, sondern steht
neben ihr.

**Zweck:** Palmier Pro ist G-KHAANs Schnittplatz. Der Chat in der Seitenleiste soll
statt der eingebauten Cloud-AI mit Hermes sprechen — Profil `elfi`. Dafür braucht es
einen eigenen Build aus dem Quellbaum, also einen Fork. Ursprungsplan:
`~/appz/KoeShot/tasks/todo.md`. Laufender Stand: `tasks/todo.md` hier im Repo.

## Die Konstellation

| Ort | Was es ist | Wird angefasst? |
|---|---|---|
| `~/appz/palmier-pro` | dieser Fork, Quellbaum + eigener Build | ja, hier wird gearbeitet |
| `~/appz/palmier-pro/.build/PalmierPro.app` | unser Build, ad-hoc signiert | ja |
| `/Applications/Palmier Pro.app` | proprietäre Store-App v0.8.x | **nein, tabu** |
| `~/Documents/Palmier Pro` | G-KHAANs echte Projekte | **nein, tabu** |

| Remote | URL | Push |
|---|---|---|
| `origin` | `https://github.com/koeseo/palmier-pro.git` | erlaubt, einzige Publikationsstelle |
| `upstream` | `https://github.com/palmier-io/palmier-pro.git` | **gesperrt** (`DISABLED_no_push_to_upstream`) |

## Der Upstream steht still — das prägt alles

Am 28.08.2026 hat Palmier mit Commit `eba39db` die öffentliche Quellcode-Entwicklung
eingestellt („Retire public source development"). Konsequenzen:

- `main` trägt denselben Quellstand wie das Tag `last-gpl-source`: **v0.7.6, GPLv3**.
  Nachgeprüft mit `git diff upstream/last-gpl-source main -- Sources Package.swift Metal models` — leer.
- Releases ab v0.8.0 sind **proprietär** (`BINARY_LICENSE.md`), ihr Quellcode wird nicht
  veröffentlicht. Unser Build ist deshalb dauerhaft ein v0.7.6-Stand und wird nie zur
  installierten Store-App aufschließen.
- Was der Upstream noch pusht, sind Binär-Metadaten: `appcast.xml`, Release-Einträge.
  Ein Sync bringt fast nie Code.
- GPLv3 deckt Fork, Umbau und Eigennutzung vollständig. Copyleft wird erst bei
  Weitergabe relevant.

## Unsere Anpassungen (carried commits auf `main`)

| # | Was | Wo | Warum |
|---|---|---|---|
| 1 | Sparkle-Auto-Update tot gelegt | `Sources/PalmierPro/Resources/Info.plist`, `Sources/PalmierPro/App/Updater.swift` | siehe unten — der Patch, dessen Verlust den Fork zerstört |
| 2 | Prüfskript für Patch 1 | `tools/pruefe-sparkle-aus.sh` | ein Merge darf den Riegel nicht stillschweigend lösen |
| 3 | Sync-Skill | `.agents/skills/palmier-upstream-sync/`, `.claude/skills` → Symlink | KoeHub-Skill-Staffelung: ein Bestand, zwei Namen |
| 4 | KoeHub-Nachtrag in `AGENTS.md`, `CLAUDE.md` als Symlink | Repowurzel | KoeHub-Standard: eine Datei, zwei Namen. Upstream hatte `CLAUDE.md` mit `@AGENTS.md` |
| 5 | Dieses Runbook + `tasks/todo.md` | Repowurzel | Fork-Wissen bleibt beim Code |

### Patch 1 im Detail — warum zwei Riegel

Ohne Patch prüft die App beim Start `SUFeedURL` aus der Info.plist, findet den
Upstream-Appcast und lädt beim nächsten Release die **proprietäre** v0.8.x über
unseren eigenen Build. Der Verlust fällt nicht auf, bis die App sich selbst ersetzt hat.

| Riegel | Ort | Wirkung |
|---|---|---|
| `SUFeedURL` entfernt, `SUEnableAutomaticChecks` auf `false` | `Info.plist` | `Updater.init()` steigt am eigenen `guard` aus, `SPUStandardUpdaterController` wird nie erzeugt |
| `if koehubUpdatesDisabled { return }` direkt nach `super.init()` | `Updater.swift` | greift auch, wenn ein Merge die Info.plist vom Upstream übernimmt |

Zwei Riegel, weil sie in verschiedenen Dateien liegen: Ein Merge, der die eine
übernimmt, lässt die andere stehen. Ein einzelner Riegel wäre bei jedem Konflikt
eine stille Wette. Beide tragen den Marker `KoeHub-Fork` bzw. sind im Prüfskript
verdrahtet.

Prüfen: `bash tools/pruefe-sparkle-aus.sh` — Pflicht nach jedem Merge und nach jedem Build.

## Build-Rezept

**Toolchain-Anforderung** (gemessen 02.09.2026): macOS 26 auf Apple Silicon, Xcode 26.6,
Swift 6.3.3 — und die **Metal-Toolchain als separate Xcode-Komponente**. Ohne sie bricht
der Build reproduzierbar ab:

```
error: cannot execute tool 'metal' due to missing Metal Toolchain;
use: xcodebuild -downloadComponent MetalToolchain
```

Der Nachinstall lädt rund 688 MB. Einmalig pro Maschine.

```bash
xcodebuild -downloadComponent MetalToolchain   # einmalig, ~688 MB
cd ~/appz/palmier-pro
scripts/bundle.sh debug                        # ad-hoc signiert, kein Apple-Konto nötig
open .build/PalmierPro.app
```

- **`scripts/bundle.sh debug` ohne weitere Flags** ist der richtige Weg: Modus `dev`,
  Signatur `codesign --sign -` (ad-hoc).
- **`--fast` NICHT verwenden.** Es signiert mit `Developer ID Application: Palmier, Inc.`
  — die haben wir nicht. Ebenso `--sign` und `--dist` (Notarisierung, Provisioning-Profil).
- **`--speech` / `--telemetry` / `release`** ziehen MLX und Sentry/PostHog herein. Für
  unseren Zweck unnötig; `release` erzwingt zusätzlich alle Traits.

### Was ohne Palmiers Backend-Konfiguration fehlt

`scripts/bundle.sh` injiziert `PalmierClerkPublishableKey`, `PalmierConvexDeploymentURL`
und `PalmierConvexHttpURL` aus einer `.env`, die es nur bei Palmier gibt. Der Kommentar
im Skript („app will fatalError on launch") stimmt für den aktuellen Code **nicht** —
`Sources/PalmierPro/Account/AccountService.swift:141` setzt lediglich `isMisconfigured`
und läuft weiter. Tot bleiben damit: Login, Cloud-Generierung, Sample-Projekte,
Credit-Kauf. Für diesen Fork ist das kein Verlust, sondern erwünscht: Palmiers
Generierungs-Werkzeuge sind nach der Kosten-Doktrin ohnehin tabu, und der Chat soll
über Hermes laufen, nicht über Palmiers Cloud.

### Modelle und Binär-Anteile

| Modell | Lizenz | Woher |
|---|---|---|
| Beat This `small0` (`BeatThis.mlmodelc`, 6,6 MB) | MIT | liegt im Repo unter `Sources/PalmierPro/Resources/Models/` |
| SigLIP 2 B/16-256 (Bild-/Textencoder) | Apache 2.0 | **nicht im Repo** — zur Laufzeit von `huggingface.co/palmier-io/siglip2-base-coreml` (`Sources/PalmierPro/Search/SearchIndexConfig.swift:6`) |

Kein Blob im Quellbaum ist proprietär. `BINARY_LICENSE.md` betrifft ausschließlich die
**gebauten Release-Binaries ab v0.8.0** von Palmier, nicht den hier liegenden Quellcode
und nicht unseren eigenen Build daraus. Die `.metallib`-Dateien entstehen beim Build aus
`Metal/` im Quellbaum.

## Der Sync

Vollständig im Skill `palmier-upstream-sync`
(`.agents/skills/palmier-upstream-sync/SKILL.md`). Kurzform:

```bash
cd ~/appz/palmier-pro
git fetch --all --prune --tags
git branch -f koehub-sicherung main
git tag "koehub-vor-sync-$(date +%Y%m%d)" main
git push origin koehub-sicherung "koehub-vor-sync-$(date +%Y%m%d)"
git log --oneline --stat main..upstream/main -- Sources Metal Package.swift scripts
git merge upstream/main -m "merge: Upstream nachgezogen (<N> Commits, <Datum>)"
bash tools/pruefe-sparkle-aus.sh
scripts/bundle.sh debug
git push origin main
```

Merge, nie Rebase — die SHAs in diesem Dokument müssen gültig bleiben.

## Fallstricke

- **`swift build` allein reicht nicht.** Es erzeugt nur das Binary. Die `.app` entsteht
  erst in `scripts/bundle.sh` (Resources flach ziehen, Sparkle-Framework kopieren,
  `.metallib` einsammeln, ad-hoc signieren).
- **Der Metal-Fehler sieht nach Codefehler aus, ist aber eine fehlende Xcode-Komponente.**
  Der Build läuft vier Minuten weit und stirbt erst am Metal-Plugin.
- **`appcast.xml` im Repo ist tot für uns**, wird aber bei jedem Upstream-Push geändert.
  Bei Konflikt einfach die Upstream-Fassung nehmen.
- **`CLAUDE.md` ist ein Symlink auf `AGENTS.md`.** Upstream hatte dort eine echte Datei
  mit `@AGENTS.md`. Ein Merge kann daraus wieder eine Datei machen — dann Symlink
  wiederherstellen.
- **Nie nach `upstream` pushen.** Die Push-URL ist gesperrt; wer sie repariert, hebt
  einen Schutz auf, der Absicht ist.
