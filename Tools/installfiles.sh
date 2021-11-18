#!/bin/sh

installFile() {
	echo "installfiles - Copying $2/$1 to $3/$1"
	cp ../$2/$1 "../$3/$1"
}

cd $(dirname $0)
echo "installfiles for : $PRODUCT_MODULE_NAME"

echo "install NSE target files"
installFile "Common.xcconfig" $PRODUCT_MODULE_NAME"NSE" "RiotNSE"
installFile "BuildSettings.swift" $PRODUCT_MODULE_NAME"/Config" "RiotNSE"
installFile "AppIdentifiers.xcconfig" $PRODUCT_MODULE_NAME"/Config" "/Config"

cd -
