#!/system/bin/sh
MODDIR=${0%/*}

# Detect what aapt to use
chmod +x "$MODDIR"/tools/*
[ "$($MODDIR/tools/aapt v)" ] && AAPT=aapt
[ "$($MODDIR/tools/aapt64 v)" ] && AAPT=aapt64
cp -af "$MODDIR"/tools/$AAPT "$MODDIR"/aapt

debloat_list="$MODDIR/bloat_packagelist.txt"
REPLACE=""

# Debug: Check if package list file exists
if [ ! -f "$debloat_list" ]; then
  echo "Error: Package list file '$debloat_list' not found."
  exit 1
fi
rm -rf $MODDIR/data
echo "Reading packages from: $debloat_list"

# Loop through each line in the package list
while IFS= read -r PACKAGE_NAME || [ -n "$PACKAGE_NAME" ]; do
  # Debug: echo the package name read
  echo "Processing package: '$PACKAGE_NAME'"

  # Skip empty lines or lines starting with a #
  if [ -z "$PACKAGE_NAME" ] || echo "$PACKAGE_NAME" | grep -q "^#"; then
    continue
  fi

  # Check if PACKAGE_NAME exists in $MODDIR/debloted.txt
  if grep -q "$PACKAGE_NAME" "$MODDIR/debloted.txt"; then
    echo "Package $PACKAGE_NAME already in debloted.txt – skipping uninstall."
    continue
  fi

  # Get the path of the installed APK (removing the "package:" prefix)
  APP_PATH=$(pm path "$PACKAGE_NAME" | sed "s/package://g")
  if [ -z "$APP_PATH" ]; then
    echo "  Package $PACKAGE_NAME not found, skipping..."
    continue
  fi

  # Get the application label using aapt
  APP_NAME=$("$MODDIR"/aapt dump badging "$APP_PATH" | grep -Eo "application-label:'[^']+'" | sed -e "s/application-label://" -e "s/'//g")

  # Extract the directory portion of the APK path
  APP_PATH_FOLDER=$(dirname "$APP_PATH")

  # If the app is installed in /data/app (i.e. it's an update), check if it’s a system app
  if echo "$APP_PATH_FOLDER" | grep -q "^/data/app/"; then
    # Check if this package is a system app by listing system packages.
    if pm list packages -s -e | grep -q "$PACKAGE_NAME"; then
      pm uninstall-system-updates "$PACKAGE_NAME"
      echo "- Uninstalled updates of $APP_NAME ($PACKAGE_NAME)"
      echo "

      "
      echo "- please Re-Run Action.sh before reboot to apply"
      echo "

      "
      APP_PATH=$(pm path "$PACKAGE_NAME" | sed "s/package://g")
  if [ -z "$APP_PATH" ]; then
    echo "  Package $PACKAGE_NAME not a SYSTEM app, are you crazy bro?..."
    continue
  fi
    else
      echo "Package $PACKAGE_NAME is not a system app – skipping uninstall."
    fi
    continue
  fi

  # For non-/data apps, if the path does not start with /system, prepend /system
  if ! echo "$APP_PATH_FOLDER" | grep -q "^/system/"; then
    APP_PATH_FOLDER="$APP_PATH_FOLDER"
  fi

  # Create the mirror directory structure in $MODDIR
  MIRROR_PATH="$MODDIR$APP_PATH_FOLDER"
  mkdir -p "$MIRROR_PATH"
  echo $MIRROR_PATH
  # Add PACKAGE_NAME to debloted.txt
  echo "$PACKAGE_NAME" >> "$MODDIR/debloted.txt"
  REPLACE="$REPLACE$APP_PATH_FOLDER "
  # Create an empty APK file in the mirror directory
  APK_NAME=$(basename "$APP_PATH")
  echo "- Created mirror directory for $APP_NAME ($PACKAGE_NAME) at $MIRROR_PATH"

done < "$debloat_list"

# Save the list of processed app folders (if needed)
echo "$REPLACE" > "$MODDIR/.lastreplace"

# warn since Magisk's implementation automatically closes if successful
if [ "$KSU" != "true" -a "$APATCH" != "true" ]; then
    echo -e "\nClosing dialog in 20 seconds ..."
    echo -e "Please reboot to apply changes...."
    sleep 20
fi
