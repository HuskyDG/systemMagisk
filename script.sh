#!/system/bin/sh

MODDIR="$0"
[ "${MODDIR: 0: 2}" == "./" ] || [ "${MODDIR: 0: 3}" == "../" ] || [ "${MODDIR: 0: 1}" == "/" ] || MODDIR="./$MODDIR"
MODDIR="${MODDIR%/*}"

. "$MODDIR/util_functions.sh"

ui_print "******************************"
ui_print "   SystemMagisk by HuskyDG"
ui_print "******************************"

ui_print "Install Magisk into system directly"
ui_print "Without need to boot image support"
sleep 1
ui_print "This system version is ONLY for testing!!!"
ui_print "It's not recommended to flash this on actual phone"
ui_print "This mods is special for VphoneGaga Android 10"
sleep 1
ui_print "Please restore boot image to stock"
sleep 1
ui_print "You have been WARNED!!!!"
sleep 1

root=/system_root
[ ! -d "$root" ] && root=/system
$BOOTMODE && root=/


[ "$(id -u)" != 0 ] && { abort "! Root user only"; }
find_magisk_apk() {
  local DBAPK
  [ -z $APK ] && APK=/data/app/com.topjohnwu.magisk*/base.apk
  [ -f $APK ] || APK=/data/app/*/com.topjohnwu.magisk*/base.apk
  if [ ! -f $APK ]; then
    DBAPK=$(magisk --sqlite "SELECT value FROM strings WHERE key='requester'" 2>/dev/null | cut -d= -f2)
    [ -z $DBAPK ] && DBAPK=$(strings /data/adb/magisk.db | grep -oE 'requester..*' | cut -c10-)
    [ -z $DBAPK ] || APK=/data/user_de/0/$DBAPK/dyn/current.apk
    [ -f $APK ] || [ -z $DBAPK ] || APK=/data/data/$DBAPK/dyn/current.apk
  fi
  [ -f $APK ] || { abort "! Unable to detect Magisk app"; }
}

if [ "$DEBUG" == 1 ]; then
set -x
fi
api_level_arch_detect
ui_print "- Find Magisk app..."
find_magisk_apk
APK=$(echo $APK)
ui_print "- Found Magisk app: $APK"
mkdir /dev/tmp
cp "$MODDIR/busybox" /dev/tmp/busybox
cp "$MODDIR/magiskpolicy" /dev/tmp/magiskpolicy
chmod 777 /dev/tmp/busybox
chmod 777 /dev/tmp/magiskpolicy
ui_print "- Remount system as read-write..."
mount -o rw,remount $root || abort "! Unable to remount system as read-write"
mount | grep -q " /vendor " && { mount -o rw,remount /vendor || abort "! Unable to remount vendor as read-write"; }
rm -rf $root/magisk
rm -rf $root/magisk.rc
rm -rf $root/system/etc/init/magisk
rm -rf $root/system/etc/init/magisk.rc
mkdir -p $root/system/etc/init/magisk/assets
ui_print "- Extract magisk apk..."
/dev/tmp/busybox unzip -oj "$APK" "lib/$ABI/*" "lib/$ABI32/libmagisk32.so" -d "$root/system/etc/init/magisk" &>/dev/null
cp /dev/tmp/magiskpolicy $root/system/etc/init/magisk/magiskpolicy
( cd $root/system/etc/init/magisk
for file in lib*.so; do
  chmod 755 $file
  mv "$file" "${file:3:${#file}-6}"
done
)
/dev/tmp/busybox unzip -oj "$APK" 'assets/*' -x 'assets/chromeos/*' \
-x 'assets/bootctl' -x 'assets/main.jar' -d $root/system/etc/init/magisk/assets &>/dev/null

sed -i "/^import\ \/magisk.rc/d" $root/init.rc

ui_print "- Inject Magisk services.."
if [ ! -f "$root/init.rc.bak" ]; then
cp $root/init.rc $root/init.rc.bak
else
cp $root/init.rc.bak $root/init.rc
fi

cat <<EOF >>$root/init.rc



          on post-fs-data
              start logd
              start adbd
              mkdir /dev/gaga-magisk
              mkdir /data/adb/magisk
              mount tmpfs tmpfs /dev/gaga-magisk mode=0755
              copy /system/etc/init/magisk/magisk64 /dev/gaga-magisk/magisk64
              chmod 0755 /dev/gaga-magisk/magisk64
              copy /system/etc/init/magisk/magisk64 /data/adb/magisk/magisk64
              chmod 0755 /data/adb/magisk/magisk64
              symlink ./magisk64 /dev/gaga-magisk/magisk
              symlink ./magisk64 /dev/gaga-magisk/su
              symlink ./magisk64 /dev/gaga-magisk/resetprop
              copy /system/etc/init/magisk/magisk32 /dev/gaga-magisk/magisk32 
              copy /system/etc/init/magisk/magisk32 /data/adb/magisk/magisk32
              chmod 0755 /dev/gaga-magisk/magisk32 
              chmod 0755 /data/adb/magisk/magisk32
              copy /system/etc/init/magisk/busybox /data/adb/magisk/busybox
              chmod 0755 /dev/gaga-magisk/busybox
              chmod 0755 /data/adb/magisk/busybox
              copy /system/etc/init/magisk/magiskinit /dev/gaga-magisk/magiskinit 
              copy /system/etc/init/magisk/magiskinit /data/adb/magisk/magiskinit
              chmod 0755 /dev/gaga-magisk/magiskinit
              chmod 0755 /data/adb/magisk/magiskinit 
              copy /system/etc/init/magisk/magiskpolicy /dev/gaga-magisk/magiskpolicy
              copy /system/etc/init/magisk/magiskpolicy /data/adb/magisk/magiskpolicy
              chmod 0755 /dev/gaga-magisk/magiskpolicy
              chmod 0755 /data/adb/magisk/magiskpolicy
              mkdir /dev/gaga-magisk/.magisk 700
              mkdir /dev/gaga-magisk/.magisk/mirror 700
              mkdir /dev/gaga-magisk/.magisk/block 700
              rm /dev/.magisk_unblock
              exec u:r:magisk:s0 root root -- /system/bin/sh /system/etc/init/magisk/prepare.sh
              start FAhW7H9G5sf
              wait /dev/.magisk_unblock 40
              rm /dev/.magisk_unblock


          service FAhW7H9G5sf /dev/gaga-magisk/magisk --post-fs-data
              user root
              seclabel u:r:magisk:s0
              oneshot

          service HLiFsR1HtIXVN6 /dev/gaga-magisk/magisk --service
              class late_start
              user root
              seclabel u:r:magisk:s0
              oneshot

          on property:sys.boot_completed=1
              start YqCTLTppv3ML
              exec_background u:r:magisk:s0 root root -- /system/bin/sh /system/etc/init/magisk/magisksu_survival.sh

          service YqCTLTppv3ML /dev/gaga-magisk/magisk --boot-complete
              user root
              seclabel u:r:magisk:s0
              oneshot

EOF

cat <<EOF >$root/system/etc/init/magisk/prepare.sh
#!/system/bin/sh
          restorecon -R /data/adb/magisk
    mkdir /dev/.sepolicy_load
    for sedir in /data/adb/modules_update /data/adb/modules; do
          for module in \$(ls /data/adb/modules); do
              if ! [ -f "\$sedir/\$module/disable" ] && [ -f "/data/adb/modules/\$module/sepolicy.rule" ] && [ ! -f "/dev/.sepolicy_load/\$module" ]; then
                  ( cat "\sedir/\$module/sepolicy.rule"; echo ) >>/dev/gaga-magisk/.magisk/sepolicy.rules
                  echo >"/dev/.sepolicy_load/\$module"
              fi
          done
    done
          /system/etc/init/magisk/magiskpolicy --live --apply "/dev/gaga-magisk/.magisk/sepolicy.rules"
          cp -a /system/etc/init/magisk/assets/* /data/adb/magisk
EOF

cat <<EOF >$root/system/etc/init/magisk/magisksu_survival.sh
# prevent /system/bin/su from removing

if mount | grep -q " /system/bin " && [ -f "/system/bin/magisk" ]; then
    umount -l /system/bin/su
    rm -rf /system/bin/su
    ln -fs ./magisk /system/bin/su
    mount -o ro,remount /system/bin
    umount -l /system/bin/magisk
    mount --bind /dev/gaga-magisk/magisk /system/bin/magisk
fi
EOF

ui_print "- Patch required sepolicy for Magisk..."
[ -e /vendor/etc/selinux/precompiled_sepolicy.bak ] || cp /vendor/etc/selinux/precompiled_sepolicy /vendor/etc/selinux/precompiled_sepolicy.bak
$root/system/etc/init/magisk/magiskpolicy --load /vendor/etc/selinux/precompiled_sepolicy --magisk --save /vendor/etc/selinux/precompiled_sepolicy
if [ ! -e "/sys/fs/selinux/policy" ]; then
ui_print "WARNING: System doesn't support live sepolicy"
ui_print "- Patch sepolicy with *fake Selinux enforcing*"
$root/system/etc/init/magisk/magiskpolicy --load /vendor/etc/selinux/precompiled_sepolicy --save /vendor/etc/selinux/precompiled_sepolicy 'permissive *'
$root/system/etc/init/magisk/magiskpolicy --load /vendor/etc/selinux/precompiled_sepolicy --save /vendor/etc/selinux/precompiled_sepolicy 'enforce untrusted_app'
fi

rm -rf /dev/tmp
ui_print "- Remount system as read-only"
mount | grep -q " /vendor " && mount -o ro,remount /vendor
mount -o ro,remount $root

ui_print "- All done!"
