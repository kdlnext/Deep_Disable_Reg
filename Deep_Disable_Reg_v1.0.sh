# 1. Initialize build workspace
WORKDIR="$HOME/magisk_pkg_build"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR/META-INF/com/google/android"

# 2. Create standard Magisk update-binary
cat << 'EOF' > "$WORKDIR/META-INF/com/google/android/update-binary"
#!/sbin/sh
umask 022
ui_print() { echo "$1"; }
require_new_magisk() {
  ui_print "Please install via Magisk v20.4+ or KernelSU/APatch"
  exit 1
}
OUTFD=$2
ZIPFILE=$3
mount /data 2>/dev/null
[ -f /data/adb/magisk/util_functions.sh ] || require_new_magisk
. /data/adb/magisk/util_functions.sh
[ $MAGISK_VER_CODE -lt 20400 ] && require_new_magisk
install_module
exit 0
EOF

echo "#MAGISK" > "$WORKDIR/META-INF/com/google/android/updater-script"

# 3. Create module.prop
cat << 'EOF' > "$WORKDIR/module.prop"
id=Deep_Disable_Reg
name=Deep_Disable_Reg
version=v1.0
versionCode=1
author=kdlnext
description=Deep scan and disable regservice/systemhelper/ctautoregist at 15s, 30s, 60s, and 120s after boot (no background daemon)
EOF

# 4. Create service.sh (4 rounds at 15s/30s/60s/120s, then exit)
cat << 'EOF' > "$WORKDIR/service.sh"
#!/system/bin/sh
MODDIR=${0%/*}
LOGFILE="$MODDIR/disable.log"
TARGET_CACHE="$MODDIR/targets.list"

KEYWORDS="regservice|systemhelper|ctautoregist"

# Wait for system boot completion
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 3
done

echo "=== $(date '+%Y-%m-%d %H:%M:%S') Deep_Disable_Reg v1.0 Started ===" > "$LOGFILE"

# Deep scan packages from 3 sources and disable matches
run_deep_disable() {
    ROUND_TAG="$1"
    echo "--- $(date '+%H:%M:%S') Scanning [$ROUND_TAG] ---" >> "$LOGFILE"

    {
        awk '{print $1}' /data/system/packages.list 2>/dev/null
        dumpsys package 2>/dev/null | grep -oE "Package \[[^]]+\]" | sed -E 's/Package \[|\]//g'
        pm list packages -u 2>/dev/null | sed 's/^package://'
    } | grep -iE "$KEYWORDS" | sort -u > "$TARGET_CACHE"

    [ ! -s "$TARGET_CACHE" ] && return

    while read -r pkg; do
        [ -z "$pkg" ] && continue
        # Core system package whitelist
        case "$pkg" in
            "android"|"com.android.systemui"|"com.android.settings"|"com.android.phone")
                continue
                ;;
        esac

        pm disable-user --user 0 "$pkg" >/dev/null 2>&1
        pm disable "$pkg" >/dev/null 2>&1
        cmd appops set "$pkg" RUN_IN_BACKGROUND ignore >/dev/null 2>&1
        cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1

        echo "$(date '+%H:%M:%S') [DISABLED] $pkg" >> "$LOGFILE"
    done < "$TARGET_CACHE"
}

# Round 1: 15s after boot
sleep 15
run_deep_disable "Boot +15s"

# Round 2: 30s after boot (15 + 15)
sleep 15
run_deep_disable "Boot +30s"

# Round 3: 60s after boot (30 + 30)
sleep 30
run_deep_disable "Boot +60s"

# Round 4: 120s after boot (60 + 60)
sleep 60
run_deep_disable "Boot +120s"

echo "=== $(date '+%Y-%m-%d %H:%M:%S') All 4 rounds completed, script exiting ===" >> "$LOGFILE"
exit 0
EOF

# 5. Create customize.sh
cat << 'EOF' > "$WORKDIR/customize.sh"
ui_print "- Installing Deep_Disable_Reg v1.0 by kdlnext..."
ui_print "- Schedule: Deep scan & disable at 15s / 30s / 60s / 120s"
set_perm "$MODPATH/service.sh" 0 0 0755
ui_print "- Installation complete. Reboot to apply."
EOF

# 6. Package as standard ZIP into /storage/emulated/0/Download/
OUT_ZIP="/storage/emulated/0/Download/Deep_Disable_Reg_v1.0.zip"
rm -f "$OUT_ZIP"
cd "$WORKDIR"

if command -v zip >/dev/null 2>&1; then
    zip -r9 "$OUT_ZIP" ./*
else
    python3 -c "import zipfile, os; z = zipfile.ZipFile('$OUT_ZIP', 'w', zipfile.ZIP_DEFLATED); [z.write(os.path.join(r, f), os.path.relpath(os.path.join(r, f), '.')) for r, d, fs in os.walk('.') for f in fs]; z.close()"
fi

rm -rf "$WORKDIR"
ls -lh "$OUT_ZIP"