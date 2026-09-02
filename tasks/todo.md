# Task: Palmier-Pro-Fork mit nativem Hermes-Chat in der Seitenleiste

Ursprungsplan: `~/appz/KoeShot/tasks/todo.md` (bleibt dort als Plan-Original).
Ab Phase 0 lebt die Ausführung hier.

## Overview
`palmier-io/palmier-pro` (natives Swift/macOS, GPLv3, Branch `main`) ist als
`koeseo/palmier-pro` geforkt. Ziel: In der Chat-Seitenleiste spricht statt der
eingebauten Cloud-AI direkt **Hermes** — Profil **`elfi`** (Elfenorakel), das über den
Palmier-MCP (`127.0.0.1:19789`) auch selbst in der App schneiden kann.

**Erhobene Fakten (01.09.2026):**
- Palmier ist kein Electron — natives Swift-Package (`Sources/PalmierPro`, Metal, CoreML).
- Im Repo existiert eine `AgentProvider`-Abstraktion — der Chat ist provider-fähig.
- Hermes bringt einen fertigen `acp_adapter` mit (JSON-RPC/stdio, Auth, Permissions,
  Edit-Approval) — die natürliche Brücke App ↔ Hermes.
- Profil `elfi` existiert lokal (`~/.hermes/profiles/elfi`).

**Nachgetragen 02.09.2026 (Phase 0):**
- Der Upstream hat am 28.08.2026 die öffentliche Quellcode-Entwicklung eingestellt
  (`eba39db`). Der Quellstand hier ist **v0.7.6 / GPLv3**, identisch mit dem Tag
  `last-gpl-source`; Releases ab v0.8.0 sind proprietär und ohne Quellcode. Der Fork
  wird also nie zur installierten Store-App aufschließen — das ist hinnehmbar, weil
  wir den Chat umbauen und nicht Palmiers Feature-Kurve folgen.
- Ohne Palmiers Backend-Keys laufen Login, Cloud-Generierung und Sample-Projekte nicht.
  Für diesen Fork erwünscht.

## Subtasks

### Phase 0 — Fork & Build-Fundament ✅ abgeschlossen 02.09.2026
- [x] 0.1 Fork `koeseo/palmier-pro` angelegt, Clone nach `~/appz/palmier-pro`,
      `origin`=koeseo / `upstream`=palmier-io. Push-URL von `upstream` bewusst auf
      `DISABLED_no_push_to_upstream` gesetzt.
- [x] 0.2 Sync-Skill `palmier-upstream-sync` unter `.agents/skills/`, `.claude/skills`
      als Symlink (KoeHub-Skill-Staffelung). `AGENTS.md` um einen KoeHub-Nachtrag
      ergänzt, `CLAUDE.md` als Symlink darauf.
- [x] 0.3 Build aus dem Quellbaum läuft. **Blocker war die fehlende Metal-Toolchain**
      (`xcodebuild -downloadComponent MetalToolchain`, ~688 MB), nicht Signing und nicht
      fehlende Blobs. Ad-hoc-Signing über `scripts/bundle.sh debug` reicht — kein
      Apple-Entwicklerkonto nötig. Rezept in `KOEHUB-FORK.md`.
- [x] 0.4 Sparkle-Auto-Update tot gelegt, zwei Riegel (Info.plist + Updater.swift),
      Prüfskript `tools/pruefe-sparkle-aus.sh`.

### Phase 1 — Architektur-Scan (im geklonten Code, nicht per GitHub-Suche)
- [ ] 1.1 Chat-Seitenleiste kartieren: `AgentProvider`-Protokoll, Konversations-/
      Streaming-Fluss, wie der eingebaute Cloud-Chat sendet/empfängt, wo Tool-Calls
      durchlaufen. Ergebnis: 1-seitige Karte „wo hängt ein neuer Provider". (medium)
- [ ] 1.2 Hermes-`acp_adapter` lokal sprechen: `python -m acp_adapter` mit Profil `elfi`,
      Handshake/Session/Prompt-Zyklus per Hand über stdio durchspielen, real genutzte
      Methoden dokumentieren. Profil-Auswahl-Mechanik klären (ENV/Flag). (medium)

### Phase 2 — Hermes-Anbindung
- [ ] 2.1 `HermesAgentProvider` in Swift: startet den `acp_adapter` als Subprozess
      (stdio JSON-RPC), mappt Palmiers Chat-Turns auf ACP-Sessions, streamt Antworten
      in die Sidebar. (complex)
- [ ] 2.2 Provider-Auswahl in der Sidebar-UI: „Hermes (elfi)" als wählbarer Chat-Partner;
      Default im Fork = Hermes. (medium)
- [ ] 2.3 Werkzeug-Schleife schließen: dem `elfi`-Profil den Palmier-MCP
      (`http://127.0.0.1:19789/mcp`) als Tool-Server geben. ⚠ Hermes-Config-Änderungen
      laufen nach ARCHON-Regel über `~/appz/archon`. (medium)
- [ ] 2.4 Sicherheits-/Kostenrahmen: Palmiers Generierungs-Tools bleiben tabu;
      Hermes-Permissions so setzen, dass Schreibzugriffe außerhalb des Projekts
      genehmigungspflichtig sind. (medium)

### Phase 3 — Abnahme & Konservierung
- [ ] 3.1 E2E-Beweis: In der Fork-App mit Elfi chatten → „leg den Titel X auf die
      Timeline" → Hermes ruft den Palmier-MCP → Änderung in der App sichtbar UND im
      Export-Frame belegt. (medium)
- [ ] 3.2 Vault-Akte `Architektur/`-Nachtrag + Verweis im Hermes-Roster;
      Memory-Update `palmier-pro-schnittplatz`. `KOEHUB-FORK.md` existiert bereits
      und wird fortgeschrieben. (simple)

## Verification
- [x] Eigener Build startet
- [ ] Eigener Build öffnet bestehende `.palmier`-Projekte
- [ ] Sidebar-Chat läuft nachweislich über Hermes/elfi (Hermes-Log zeigt die Session)
- [ ] Elfi führt einen echten Schnitt-Befehl über den MCP aus (Frame-Beweis)
- [ ] Upstream-Sync-Probelauf ohne Patch-Verlust
- [x] Sparkle im Fork tot (`tools/pruefe-sparkle-aus.sh` grün, kein `SUFeedURL` im Bundle)

## Notes
- **Diktat-Klärung:** „Premiere Pro App" = Palmier Pro; „RPAs" = die eingebauten
  Cloud-AI-Chats; „Elfenoracle Hermes Profil" = `~/.hermes/profiles/elfi`.
- **Architektur-Entscheid:** App ↔ Hermes über den mitgelieferten ACP-Adapter statt
  eines selbstgebauten Protokolls — Auth/Permissions/Streaming sind dort gelöst.
  Verworfen: Hermes-Gateway per HTTP (mehr Eigenbau, keine Edit-Approvals).
- **Elfi arbeitet über den MCP, nicht über App-Interna** — der MCP ist die stabile,
  verifizierte Werkzeugfläche (49 Tools).
- **Plan B ist nicht mehr nötig.** Das Go/No-Go-Gate 0.3 ist bestanden; der Quellbaum
  baut. Der Rückfall „Hermes-Chat als eigenes Sidebar-Fenster neben der Store-App"
  bleibt als Notlösung notiert, wird aber nicht verfolgt.
- **Aufwandsehrlichkeit:** Phase 2 ist der Brocken (Swift-Provider, mehrere Sessions).

## Status
Phase 0 abgeschlossen 02.09.2026. Nächster Schritt: Phase 1.1 (Chat-Seitenleiste
kartieren) — braucht kein Go, ist reines Lesen im Quellbaum.
