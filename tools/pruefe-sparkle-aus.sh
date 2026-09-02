#!/bin/bash
# Prüft, dass der Sparkle-Auto-Update im KoeHub-Fork tot ist — beide Riegel.
# Pflicht nach jedem Upstream-Merge und nach jedem Build.
# Exit 0 = alles tot. Exit 1 = mindestens ein Riegel gefallen.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLIST="$ROOT/Sources/PalmierPro/Resources/Info.plist"
UPDATER="$ROOT/Sources/PalmierPro/App/Updater.swift"
APP_PLIST="$ROOT/.build/PalmierPro.app/Contents/Info.plist"
fehler=0

pruefe() { # name, bedingung-erfüllt(0/1), meldung
    if [ "$2" = "0" ]; then
        printf '  OK    %s\n' "$1"
    else
        printf '  FEHLT %s — %s\n' "$1" "$3"
        fehler=1
    fi
}

echo "Sparkle-Riegel im Quellbaum:"

grep -q "SUFeedURL" "$PLIST"; [ $? -eq 1 ] && r=0 || r=1
pruefe "Info.plist ohne SUFeedURL" "$r" "SUFeedURL wieder da — Updater würde starten"

/usr/libexec/PlistBuddy -c "Print :SUEnableAutomaticChecks" "$PLIST" 2>/dev/null | grep -qx "false" && r=0 || r=1
pruefe "Info.plist SUEnableAutomaticChecks=false" "$r" "Wert ist nicht false"

grep -q "KoeHub-Fork" "$UPDATER" && r=0 || r=1
pruefe "Updater.swift trägt den Code-Riegel" "$r" "Marker 'KoeHub-Fork' verschwunden — vermutlich vom Merge überschrieben"

if [ -f "$APP_PLIST" ]; then
    echo "Sparkle-Riegel im gebauten Bundle:"
    # PlistBuddy endet mit 1, wenn der Key fehlt — genau der Fall, den wir wollen.
    # Ohne das "|| true" reisst pipefail diesen Exit-Code durch und die Prüfung
    # meldet einen Feed, der gar nicht da ist.
    { /usr/libexec/PlistBuddy -c "Print :SUFeedURL" "$APP_PLIST" 2>&1 || true; } | grep -q "Does Not Exist" && r=0 || r=1
    pruefe ".build/PalmierPro.app ohne SUFeedURL" "$r" "das gebaute Bundle trägt einen Feed"
else
    echo "  (kein Build unter .build/PalmierPro.app — Bundle-Prüfung übersprungen)"
fi

[ "$fehler" = "0" ] && echo "Sparkle ist tot." || echo "ACHTUNG: Sparkle könnte den Fork überschreiben."
exit "$fehler"
