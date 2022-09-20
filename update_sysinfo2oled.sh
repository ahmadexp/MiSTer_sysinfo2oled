#!/bin/bash

#thanks to venice1200 which this code was forked from i2c2oled

SYSINFO2OLED_PATH="/media/fat/sysinfo2oled"
USERSTARTUP="/media/fat/linux/user-startup.sh"
USERSTARTUPTPL="/media/fat/linux/_user-startup.sh"
INITSCRIPT="${SYSINFO2OLED_PATH}/S60sysinfo2oled"
DAEMONNAME="sysinfo2oled.sh"

# Stop an already running daemon
if [ $(pidof ${DAEMONNAME}) ]; then
    ${INITSCRIPT} stop
    sleep 0.5
fi

# Download/Update i2c2oled Scripts
mkdir /media/fat/sysinfo2oled
cd /media/fat/sysinfo2oled
wget -N --no-use-server-timestamps https://raw.githubusercontent.com/ahmadexp/MiSTer_sysinfo2oled/main/sysinfo2oled.sh
[ -x sysinfo2oled.sh ] || chmod +x sysinfo2oled.sh 

# Old MiSTer layout: remove init script
[[ -e /etc/init.d/sysinfo2oled ]] && /etc/init.d/sysinfo2oled stop && rm /etc/init.d/sysinfo2oled

# New MiSTer layout: setup init script
if [ ! -e ${USERSTARTUP} ] && [ -e /etc/init.d/S99user ]; then
  if [ -e ${USERSTARTUPTPL} ]; then
    echo "Copying ${USERSTARTUPTPL} to ${USERSTARTUP}"
    cp ${USERSTARTUPTPL} ${USERSTARTUP}
  else
    echo "Building ${USERSTARTUP}"
    echo -e "#!/bin/sh\n" > ${USERSTARTUP}
    echo -e 'echo "***" $1 "***"' >> ${USERSTARTUP}
  fi
fi
if [ $(grep -c "sysinfo2oled" ${USERSTARTUP}) = "0" ]; then
  echo -e "Adding sysinfo2oled to ${USERSTARTUP}\n"
  echo -e "\n# Startup sysinfo2oled" >> ${USERSTARTUP}
  echo -e "[[ -e ${INITSCRIPT} ]] && ${INITSCRIPT} \$1" >> ${USERSTARTUP}
fi

${INITSCRIPT} start
exit 0
