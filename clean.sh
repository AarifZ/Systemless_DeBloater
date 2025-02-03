#!/system/bin/sh
MODDIR=${0%/*}

echo " Reverting the changes!"  
#undo debloat
rm -rf $MODDIR/product
rm -rf $MODDIR/system
rm -rf $MODDIR/vendor
rm -rf $MODDIR/system_ext
rm -rf $MODDIR/debloted.txt
echo "Bloated back" 
echo " Reboot to apply changes."
sleep 5