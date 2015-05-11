#!/bin/bash

ruby_mode_erubis=`gem list | grep erubis`
libimobiledevice=`brew list libimobiledevice 2>&1`

if [ "$ruby_mode_erubis" = "" ]; then
	echo "install ruby depends module..."
	gem install erubis
	echo "install ruby depends module done."
else
	echo "ruby depends module already install."
fi

if [[ "$libimobiledevice" =~ "Error: No such keg: /usr/local/Cellar/libimobiledevice" ]]; then
	echo "install depends libimobiledevice..."
	brew update >/dev/null 2>&1
	wait
	brew install libimobiledevice
	wait
	echo "install depends libimobiledevice done."
else
	echo "libimobiledevice already install."
	echo "upgrade libimobiledevice..."
	brew upgrade libimobiledevice >/dev/null 2>&1
	echo "upgrade libimobiledevice done."
fi 
