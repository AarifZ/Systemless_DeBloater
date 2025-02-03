#!/system/bin/sh

BACKUP_DIR="/data/local/tmp/module_backup"
MODULE_DIR="/data/adb/modules/systemless-debloater"

# Check if the module path exists
if [ -d "$MODULE_DIR" ]; then
    echo "Existing module detected. Proceeding with backup and modification."

    # Check if a backup already exists
    if [ -d "$BACKUP_DIR" ]; then
        echo "Backup already exists. Skipping fresh backup."
    else
        echo "Creating new backup..."
        mkdir -p "$BACKUP_DIR"
        cp -rf "$MODULE_DIR" "$BACKUP_DIR"
        echo "Backup complete."
    fi

    # Remove unwanted files
    rm -f "$BACKUP_DIR"/systemless-debloater/action.sh
    rm -f "$BACKUP_DIR"/systemless-debloater/*.sh
    rm -f "$BACKUP_DIR"/systemless-debloater/module.prop
    cp -rf "$BACKUP_DIR"/systemless-debloater/* "$MODPATH/"

    echo "Module list restoration completed."
    rm -rf "BACKUP_DIR"

else
    echo "No existing module found. Exiting..."
fi

# Detect What aapt to use
chmod +x "$MODPATH"/tools/*
[ "$($MODPATH/tools/aapt v)" ] && AAPT=aapt
[ "$($MODPATH/tools/aapt64 v)" ] && AAPT=aapt64
cp -af "$MODPATH"/tools/$AAPT "$MODPATH"/aapt

choose() {
  # Original idea by chainfire and ianmacd @xda-developers
  [ "$1" ] && local delay=$1 || local delay=3
  local error=false
  while true; do
    local count=0
    while true; do
      timeout $delay /system/bin/getevent -lqc 1 2>&1 > $TMPDIR/events &
      sleep 0.5; count=$((count + 1))
      if (`grep -q 'KEY_VOLUMEUP *DOWN' $TMPDIR/events`); then
        return 0
      elif (`grep -q 'KEY_VOLUMEDOWN *DOWN' $TMPDIR/events`); then
        return 1
      fi
      [ $count -gt 6 ] && break
    done
    if $error; then
      error=true
      echo "Volume key not detected. Try again"
    fi
  done
}

debloat_list="$MODPATH/bloat_packagelist.txt"
id=$(grep "id=" $MODPATH/module.prop | cut -d'=' -f2-)
last_install="/data/adb/modules/$id"

if [ -f "$last_install/.lastreplace" ]; then
  REPLACE=""
  ui_print "- Installing... (𝗧𝗵𝗶𝘀 𝗰𝗼𝘂𝗹𝗱 𝘁𝗮𝗸𝗲 𝘀𝗼𝗺𝗲 𝘁𝗶𝗺𝗲 :𝗗)"
else
  REPLACE=$(cat "$last_install/.lastreplace")
  REPLACE="$REPLACE "
  ui_print "- (𝗥𝗲) Installing... (𝗧𝗵𝗶𝘀 𝗰𝗼𝘂𝗹𝗱 𝘁𝗮𝗸𝗲 𝘀𝗼𝗺𝗲 𝘁𝗶𝗺𝗲 :𝗗)"
fi

ui_print
ui_print "| Do you want to install with"
ui_print "|  The default configuration?"
ui_print "|               [● 𝗣𝗿𝗲𝘀𝘀 𝗩𝗼𝗹+]"
ui_print "|"
ui_print "| Or Customize your Installation?"
ui_print "|               [● 𝗣𝗿𝗲𝘀𝘀 𝗩𝗼𝗹-]"
ui_print "|"
ui_print "| Waiting until a key is pressed..."
ui_print

if choose 15; then
  ui_print "- Installing With the default config..."
  CUSTOMIZE=false
else
  ui_print "- OK, Lets customize the installation :D"
  ui_print
  CUSTOMIZE=true
fi

# Loop through each line in the output of the one-liner
while IFS= read -r PACKAGE_NAME; do
  # Check if the line is empty
  if [[ -z "$PACKAGE_NAME" || "$PACKAGE_NAME" =~ ^# ]]; then
    continue
  fi

  #        Get The Path of the App | Remove "package:"
  APP_PATH=$(pm path $PACKAGE_NAME | sed "s/package://g")

  if [ -z "$APP_PATH" ]; then
    continue
  fi

  APP_NAME=$("$MODPATH"/aapt dump badging $APP_PATH | grep -Eo "application-label:'[^']+'" | sed -e "s/application-label://" -e "s/'//g")
  APP_PATH_FOLDER=$(echo $APP_PATH | sed 's|\(.*\)/.*|\1|' | uniq)

  if [ $CUSTOMIZE == true ]; then
    ui_print
    ui_print "UnInstall $APP_NAME ($PACKAGE_NAME)?"
    ui_print "[● 𝗬𝗲𝘀: 𝗩𝗼𝗹+] [● 𝗡𝗼: 𝗩𝗼𝗹-]"

    if ! choose 15; then
      ui_print "- Didn't UnInstall $APP_NAME ($PACKAGE_NAME)"
      continue
    fi

  fi

  if [[ ! -z $(echo "$APP_PATH_FOLDER" | grep -E "^/data/app/.*$") ]]; then
  if pm list packages -s -e | grep -q "$PACKAGE_NAME"; then
    pm uninstall-system-updates $PACKAGE_NAME
    ui_print "- UnInstalled updates of $APP_NAME ($PACKAGE_NAME)"
    fi
    continue
  fi

  # Add /system to paths that start with anything other then /system
  if [ -z $(echo $APP_PATH_FOLDER | grep -E "^\/(system)\/.*$") ]; then
    APP_PATH="$APP_PATH_FOLDER"
  fi

  REPLACE="$REPLACE$APP_PATH_FOLDER "
  ui_print "- UnInstalled $APP_NAME ($PACKAGE_NAME)"

done < "$debloat_list"

echo $REPLACE > "$MODPATH/.lastreplace"

ui_print "- ******************** 𝗡𝗢𝗧𝗜𝗖𝗘 ********************"
ui_print "-        𝗜𝗳 𝗮𝗻𝘆 𝗮𝗽𝗽𝘀 𝗮𝗿𝗲 𝗹𝗲𝗳𝘁, 𝗜𝗻𝘀𝘁𝗮𝗹𝗹 𝘁𝗵𝗲 𝗺𝗼𝗱𝘂𝗹𝗲     "
ui_print "-           𝗔𝗴𝗮𝗶𝗻 𝗪𝗜𝗧𝗛𝗢𝗨𝗧 𝗿𝗲𝗺𝗼𝘃𝗶𝗻𝗴 𝗶𝘁 𝗳𝗶𝗿𝘀𝘁         "
ui_print "-    𝗣𝗹𝗲𝗮𝘀𝗲 𝗿𝗲𝗺𝗼𝘃𝗲 𝗺𝘂𝗹𝘁𝗶𝗽𝗹𝗲 𝘂𝘀𝗲𝗿𝘀 𝗶𝗳 𝗲𝘅𝗶𝘀𝘁𝘀 𝗲𝗹𝘀𝗲 𝗶𝘁'𝗹𝗹 𝗿𝗲𝘁𝘂𝗿𝗻.  "
ui_print "- ************************************************"

ui_print "- ************************************"
ui_print "- Installation Done! Reboot & Enjoy :)"
ui_print "- ************************************"