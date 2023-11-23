#!/bin/bash
fenbianlv=`sed -n '1p' /sys/class/drm/card0-HDMI-A-1/modes`
if [[ $fenbianlv == "3840x2160" ]]; then
    echo "<hdmi_test  $fenbianlv>,<PASS>,<0>"
    exit 0
fi
echo "<hdmi_test $fenbianlv>,<FAILT>,<-1>"
exit 1