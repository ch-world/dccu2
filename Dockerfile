FROM resin/armv7hf-debian-qemu

RUN [ "cross-build-start" ]

RUN sh -c 'echo deb http://ftp.debian.org/debian jessie-backports main > /etc/apt/sources.list.d/backports.list'

RUN apt-get update && apt-get install -y \
      apt-utils

# Fix problem when installing Java with missing man dir
RUN mkdir /usr/share/man/man1
RUN mkdir /usr/share/man/man7

RUN apt-get install -y \
      usbutils \
      wget \
      openssh-server \
      libc6 \
      libstdc++6 \
      libssl1.0.0

RUN apt-get -y -t jessie-backports install \
      openjdk-8-jre-headless \
      && rm -rf /var/lib/apt/lists/*

ADD bin /bin
ADD boot /boot
ADD etc /etc
ADD firmware /firmware
ADD lib /lib
ADD opt /opt
ADD sbin /sbin
ADD usr /usr
ADD www /www

# RUN update-usbids
RUN rm -rf /usr/local/* && \
      mkdir -p /usr/local/tmp && \
      mkdir -p /usr/local/etc/config && \
      mkdir -p /usr/local/etc/config/crRFD && \
      mkdir -p /usr/local/etc/config/rc.d && \
      mkdir -p /usr/local/etc/config/addons/www && \
      mkdir -p /var/status && \
      ln -s ../usr/local/etc/config /etc/config && \
      mkdir /opt/hm && \
      touch /var/rf_address && \
      ln -s /bin /opt/hm/bin && \
      ln -s /etc /opt/hm/etc && \
      ln -s /www /opt/hm/www && \
      ln -s ../init.d/ccu2-logging /etc/rc3.d/S00ccu2-logging && \
      ln -s ../init.d/ccu2-dccu2SystemStart /etc/rc3.d/S01ccu2-dccu2SystemStart && \
      ln -s ../init.d/ccu2-eQ3SystemStart /etc/rc3.d/S02ccu2-eQ3SystemStart && \
      ln -s ../init.d/ccu2-hs485dloader /etc/rc3.d/S49ccu2-hs485dloader && \
      ln -s ../init.d/ccu2-eq3configd /etc/rc3.d/S50ccu2-eq3configd && \
      ln -s ../init.d/ccu2-lighttpd /etc/rc3.d/S50ccu2-lighttpd && \
      ln -s ../init.d/ccu2-FirmwareUpdate /etc/rc3.d/S58ccu2-FirmwareUpdate && \
      ln -s ../init.d/ccu2-SetLGWKey /etc/rc3.d/S59ccu2-SetLGWKey && \
      ln -s ../init.d/ccu2-hs485d /etc/rc3.d/S60ccu2-hs485d && \
      ln -s ../init.d/ccu2-rfd /etc/rc3.d/S61ccu2-rfd && \
      ln -s ../init.d/ccu2-HmIPServer /etc/rc3.d/S62ccu2-HmIPServer && \
      ln -s ../init.d/ccu2-ReGaHss /etc/rc3.d/S70ccu2-ReGaHss && \
      ln -s ../init.d/ccu2-eQ3SystemStarted /etc/rc3.d/S99ccu2-eQ3SystemStarted && \
      echo 'root:root'|chpasswd && \
      sed -i -e 's/^PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config && \
      if grep -Fxq "PermitRootLogin" /etc/ssh/sshd_config; then echo ""; else echo "\nPermitRootLogin yes" >>/etc/ssh/sshd_config; fi


ADD entrypoint.sh /

CMD ["/entrypoint.sh"]

#ssh
EXPOSE 22
#webui
EXPOSE 80
#minissdpd
EXPOSE 1900
#regahss
EXPOSE 1999
#hs485d
EXPOSE 2000
#rfd
EXPOSE 2001
#hmiprf 
EXPOSE 2010
#rega
EXPOSE 8181
#virtualdevices
EXPOSE 9292

RUN [ "cross-build-end" ]