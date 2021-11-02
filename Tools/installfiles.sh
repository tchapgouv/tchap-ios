#!/bin/sh

installFile() {
	echo "installfiles - Copying $2/$1 to RiotNSE/$1"
	cp ../$2/$1 "../RiotNSE/$1"
}

cd $(dirname $0)
echo "installfiles for : $PRODUCT_MODULE_NAME"
installFile "Common.xcconfig" $PRODUCT_MODULE_NAME"NSE"
installFile "BuildSettings.swift" $PRODUCT_MODULE_NAME"/Config"
cd -
