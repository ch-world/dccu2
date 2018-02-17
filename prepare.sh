#########
# BUILD #
#########

mkdir -p ${BUILD_FOLDER}
cd ${BUILD_FOLDER}

echo "Installing Docker if needed"
if docker -v|grep -qvi version; then
  apt-get install -y docker.io
else
  echo "Docker not needed"
fi

echo
echo "Build Docker container in $DOCKER_BUILD"

# prepare some dirs
rm -rf $DOCKER_BUILD
mkdir $DOCKER_BUILD
mkdir -p $DOCKER_BUILD/etc/init.d
mkdir $DOCKER_BUILD/etc/config_templates
mkdir -p $DOCKER_BUILD/usr/sbin

#clear occu repo bugs
rm -rf $RDIR/dependencies/occu/HMserver/etc/init.d

# copy entrypoint
echo "creating entrypoint"
echo "$pwd"
cp -l $RDIR/Dockerfile $RDIR/entrypoint.sh $DOCKER_BUILD

#get dependency occu
if [ ! -d "$RDIR/dependencies/occu" ]; then
	echo "Cloning OCCU-Repository"
	mkdir -p $RDIR/dependencies/occu
	git clone https://github.com/eq-3/occu $RDIR/dependencies/occu/
else
	echo "OCCU-Repository already there, just pulling changes"
	# TODO git -C $RDIR/dependencies/occu pull
fi

# checkout occu version
git -C $RDIR/dependencies/occu checkout $CCU2_VERSION

# lighttpd
echo "building lighttpd"
cp -l $RDIR/dependencies/occu/$ARCH/packages/lighttpd/bin/* $DOCKER_BUILD/usr/sbin
cp -rl $RDIR/dependencies/occu/$ARCH/packages/lighttpd/etc/lighttpd $DOCKER_BUILD/etc/lighttpd
cp -rl $RDIR/dependencies/occu/$ARCH/packages/lighttpd/lib $DOCKER_BUILD/lib

# linuxbasis
echo "building linuxbasis"
cp -rl $RDIR/dependencies/occu/$ARCH/packages-eQ-3/LinuxBasis/bin $DOCKER_BUILD/bin
cp -rl $RDIR/dependencies/occu/$ARCH/packages-eQ-3/LinuxBasis/lib/* $DOCKER_BUILD/lib/

# hs485d - we love wired :-)
echo "building hs485d - we love wired :-)"
cp -rl $RDIR/dependencies/occu/$ARCH/packages-eQ-3/HS485D/bin/* $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/$ARCH/packages-eQ-3/HS485D/lib/* $DOCKER_BUILD/lib/

# rfd
echo "building rfd"
cp -rl $RDIR/dependencies/occu/$ARCH/packages-eQ-3/RFD/bin/SetInterfaceClock $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/$ARCH/packages-eQ-3/RFD/bin/avrprog $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/$ARCH/packages-eQ-3/RFD/bin/crypttool $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/$ARCH/packages-eQ-3/RFD/bin/rfd $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/$ARCH/packages-eQ-3/RFD/etc/config_templates/* $DOCKER_BUILD/etc/config_templates/
cp -rl $RDIR/dependencies/occu/$ARCH/packages-eQ-3/RFD/etc/crRFD.conf $DOCKER_BUILD/etc/
cp -rlf $RDIR/dependencies/occu/$ARCH/packages-eQ-3/RFD/lib/* $DOCKER_BUILD/lib/

# HMIPServer
echo "building HMIPServer"
cp -rl $RDIR/dependencies/occu/HMserver/* $DOCKER_BUILD/
#rm -rf $DOCKER_BUILD/opt/HMServer/HMServer.jar

# Tante rega ;-)
echo "building ReGaHss ;-)"
cp -rl $RDIR/dependencies/occu/$ARCH/packages-eQ-3/WebUI/bin/* $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/WebUI/bin/* $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/$ARCH/packages-eQ-3/WebUI/etc/rega.conf $DOCKER_BUILD/etc/
cp -rlf $RDIR/dependencies/occu/$ARCH/packages-eQ-3/WebUI/lib/* $DOCKER_BUILD/lib/
cp -rlP $RDIR/dependencies/occu/WebUI/www $DOCKER_BUILD/www

#version info
sed -i 's/WEBUI_VERSION = ".*";/WEBUI_VERSION = "'$CCU2_VERSION-$BUILD_VERSION'";/' $DOCKER_BUILD/www/rega/pages/index.htm
sed -i 's/product == "HM-CCU2"/product == "HM-dccu2-x86_64"/' $DOCKER_BUILD/www/webui/webui.js
#sed -i 's/"http:\/\/update\.homematic\.com\/firmware\/download?cmd=js_check_version&version="+WEBUI_VERSION+"&product=HM-CCU2&serial=" + serial/"https:\/\/gitcdn.xyz\/repo\/ch-world\/dccu2\/master\/release\/latest-release.js?cmd=js_check_version\&version="+WEBUI_VERSION+"\&product=HM-dccu2-armv7hf\&serial=" + serial/' $DOCKER_BUILD/www/webui/webui.js >dada.js
sed -i 's/"http:\/\/update\.homematic\.com\/firmware\/download?cmd=js_check_version&version="+WEBUI_VERSION+"&product=HM-CCU2&serial=" + serial/"https:\/\/cdn.rawgit.com\/ch-world\/dccu2\/master\/release\/latest-release.js?cmd=js_check_version\&version="+WEBUI_VERSION+"\&product=HM-dccu2-armv7hf\&serial=" + serial/' $DOCKER_BUILD/www/webui/webui.js >dada.js
echo "homematic.com.setLatestVersion('$CCU2_VERSION-$BUILD_VERSION', 'HM-dccu2-armv7hf');" > $RDIR/release/latest-release.js

#fix devconfig
sed -i 's/<div class=\\\"StdTableBtn CLASS21701\\\" onclick=\\\"window\.open('\''\/tools\/devconfig\.cgi?sid=\$sid'\'');\\\">devconfig<\/div>/<div class=\\\"cpButton\\\"><div class=\\\"StdTableBtn CLASS21701\\\" onclick=\\\"window\.open\('\''\/tools\/devconfig\.cgi\?sid=\$sid'\''\);\\\">devconfig<\/div><div class=\\\"StdTableBtnHelp\\\"><\/div><\/div>/' $DOCKER_BUILD/www/config/control_panel.cgi
sed -i 's/<\/td><td class=\\\"StdTableBtnHelp\\\"><\/td>/<\/td>/' $DOCKER_BUILD/www/config/control_panel.cgi

# image specific data
echo "building image specific data"
cp -rl $RDIR/dependencies/occu/firmware $DOCKER_BUILD/firmware/

#copy patched files
echo "copy patched files"
cp -rlf $RDIR/x86_32_debian_all/patches/WebUI/www/config/* $DOCKER_BUILD/www/config/

#hack for glitch in repo
echo "hack for glitch in repo"
mv $DOCKER_BUILD/firmware/HmIP-RFUSB/hmip_coprocessor_update.eq3 $DOCKER_BUILD/firmware/HmIP-RFUSB/hmip_coprocessor_update-2.8.6.eq3

# other data
echo "building other data"
cp -rlf $RDIR/all/* $DOCKER_BUILD/
cp -rlf $RDIR/x86_32_debian_all/* $DOCKER_BUILD/

#docker container rm $(docker ps -a | grep "${DOCKER_NAME}" | awk '{print $1}')
#docker rmi -f $(docker image ls |grep "${DOCKER_NAME}"| awk '{print $3}')
