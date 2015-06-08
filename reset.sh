#!/bin/bash

function gem_installer()
{
	gem_name=$1
	gem_info=`gem list | grep $gem_name`
	if [ "$gem_info" = "" ]; then
		echo "gem install ruby library $gem_name..."
		gem install $gem_name
		echo "gem install ruby library $gem_name done."
	else
		echo "gem already installed ruby library $gem_name."
	fi

}

function brew_installer()
{	
	module_name=$1
	module_info=`brew list $module_name 2>&1`
	if [[ "$module_info" =~ "Error: No such keg: /usr/local/Cellar/$module_name" ]]; then
		echo "install depends $module_name..."
		brew update >/dev/null 2>&1
		wait
		brew install $module_name
		wait
		echo "install depends $module_name done."
	else
		echo "$module_name already install."
		echo "upgrade $module_name..."
		brew upgrade $module_name >/dev/null 2>&1
		echo "upgrade $module_name done."
	fi 
}

# install ruby library via gem
gem_installer erubis

# install 3rd depends library via brew
brew_installer libimobiledevice
brew_installer imagemagick
brew_installer ideviceinstaller
