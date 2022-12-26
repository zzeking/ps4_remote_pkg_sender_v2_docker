# Using Ubuntu 18.04 base image and VNC

FROM ubuntu:18.04
LABEL io.openshift.expose-services="45901:tcp"

USER root

ENV DISPLAY=":40001"
ENV USER="ps4pkg"
ENV UID=1000
ENV GID=0
ENV HOME=/home/${USER}
# ENV web_port=46969
ARG vnc_password=""
EXPOSE 5901 6080

ADD xstartup ${HOME}/.vnc/

RUN useradd -g ${GID} -u ${UID} -r -d ${HOME} -s /bin/bash ${USER}
RUN echo "root:root" | chpasswd
# set password of ${USER} to ${USER}
RUN echo "${USER}:${USER}" | chpasswd

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends apt-utils sudo git curl wget ca-certificates python3 python3-numpy fluxbox && \
    apt-get install -y --no-install-recommends tigervnc-standalone-server tigervnc-common && \
    /bin/echo -e "\n${USER}        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers && \
    wget https://github.com/novnc/noVNC/archive/v1.1.0.tar.gz -O /tmp/noVNC.tar.gz && \
    tar -zxvf /tmp/noVNC.tar.gz -C /opt && \
    git clone https://github.com/novnc/websockify /opt/noVNC-1.1.0/utils/websockify && \
    rm -rf /opt/noVNC-1.1.0/utils/websockify/.git /tmp/noVNC.tar.gz && \
    mv /opt/noVNC-1.1.0/vnc_lite.html /opt/noVNC-1.1.0/index.html && \
    sed -i 's/<title>noVNC<\/title>/<title>Remote_PKG_Sender<\/title>/g' /opt/noVNC-1.1.0/index.html && \
    apt-get remove -y git-man git && \
    apt-get clean

RUN touch ${HOME}/.vnc/passwd ${HOME}/.Xauthority /var/log/ps4remotepkgsenderv2.log

RUN chown -R ${UID}:${GID} ${HOME}
RUN chown ${UID}:${GID} /var/log/ps4remotepkgsenderv2.log
RUN chmod 755 ${HOME}/.vnc/xstartup
RUN chmod 600 ${HOME}/.vnc/passwd

WORKDIR ${HOME}

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

RUN apt-get install -y --no-install-recommends dbus-x11 fcitx-module-dbus fcitx-ui-classic fcitx-googlepinyin locales && \
    apt-get install -y --no-install-recommends libxtst6 libgtk-3-0 libnotify4 libnss3 libxss1 libatspi2.0-0 libappindicator3-1 libsecret-1-0 libgbm1 libasound2 fonts-wqy-microhei xdg-utils desktop-file-utils && \
    app_url="https://github.com/Gkiokan/ps4-remote-pkg-sender/releases/download/v2.8.0/PS4RemotePKGSenderV2_2.8.0_amd64.deb" && \
    wget ${app_url} -O /tmp/PS4RemotePKGSenderV2_2.8.0_amd64.deb && \
    dpkg -i /tmp/PS4RemotePKGSenderV2_2.8.0_amd64.deb && \
    apt-get clean && rm -f /tmp/PS4RemotePKGSenderV2_2.8.0_amd64.deb

RUN locale-gen zh_CN.UTF-8

ENV LC_ALL "zh_CN.UTF-8"


USER ${USER}
WORKDIR ${HOME}


RUN /bin/echo -e 'alias ll="ls -last"' >> ${HOME}/.bashrc

RUN mkdir -p ${HOME}/.fluxbox
RUN /bin/echo -e "session.screen0.toolbar.placement: TopCenter" >> ${HOME}/.fluxbox/init
RUN /bin/echo -e "session.screen0.workspaces:     1 ">> ${HOME}/.fluxbox/init

# Always run the WM last!
RUN /bin/echo -e "export DISPLAY=${DISPLAY}"  >> ${HOME}/.vnc/xstartup
RUN /bin/echo -e "[ -r ${HOME}/.Xresources ] && xrdb ${HOME}/.Xresources\nfbsetroot -solid gray"  >> ${HOME}/.vnc/xstartup
RUN /bin/echo -e "fluxbox &"  >> ${HOME}/.vnc/xstartup
RUN /bin/echo -e 'export GTK_IM_MODULE=fcitx' >> ${HOME}/.vnc/xstartup
RUN /bin/echo -e 'export QT_IM_MODULE=fcitx' >> ${HOME}/.vnc/xstartup
RUN /bin/echo -e 'export XMODIFIERS="@im=fcitx"' >> ${HOME}/.vnc/xstartup
RUN /bin/echo -e "sleep 3"  >> ${HOME}/.vnc/xstartup
RUN /bin/echo -e "fcitx"  >> ${HOME}/.vnc/xstartup
RUN /bin/echo -e "/opt/noVNC-1.1.0/utils/launch.sh --listen 46969 --vnc 127.0.0.1:45901 &"  >> ${HOME}/.vnc/xstartup

RUN /bin/echo -e "while true; do" >> ${HOME}/.vnc/xstartup
RUN /bin/echo -e "    /opt/PS4\ Remote\ PKG\ Sender\ V2/ps4remotepkgsenderv2 --no-sandbox >> /var/log/ps4remotepkgsenderv2.log 2>&1" >> ${HOME}/.vnc/xstartup
RUN /bin/echo -e "done" >> ${HOME}/.vnc/xstartup
