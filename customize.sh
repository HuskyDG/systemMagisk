TMPDIR=/dev/tmp
mkdir /dev/tmp
SKIPUNZIP=1
MODDIR="${0%/*}"



unzip -o "$ZIPFILE" -x "customize.sh" -d "$MODDIR" &>/dev/null
. "$MODDIR/util_functions.sh"

CHECKROOTFS="$(mountpoint -d /)"
[ "${CHECKROOTFS%:*}" != "0" ] && { abort "! System as root only"; }

if [ "$(basename "$ZIPFILE")" == uninstall.zip ]; then
. "$MODDIR/uninstall.sh"
else
. "$MODDIR/script.sh"
fi
