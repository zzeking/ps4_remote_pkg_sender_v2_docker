#!/bin/sh

if [ -f "${HOME}/share/.vnc/passwd.txt" ]; then
    vnc_password=$(cat "${HOME}/share/.vnc/passwd.txt")
fi

echo "${vnc_password}" | vncpasswd -f > ${HOME}/.vnc/passwd

[ -z "${DISPLAY}" ] || /usr/bin/vncserver -kill ${DISPLAY}
sudo rm -f /tmp/.X*-lock /tmp/.X11-unix/X*

sleep 3

if [ -z $vnc_password ]; then
    /usr/bin/vncserver "${DISPLAY}" -geometry 1920x1080 -fg -SecurityTypes None,TLSNone
else
    /usr/bin/vncserver "${DISPLAY}" -geometry 1920x1080 -fg
fi
