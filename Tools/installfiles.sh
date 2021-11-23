#!/bin/sh

installFile() {
	echo "installfiles - Copying $2/$1 to $3/$1"

    if [[ $1 == *.appiconset ]] || [[ $1 == *.imageset ]]
    then
		cp -R ../$2/$1 "../$3/"
    else
		cp ../$2/$1 "../$3/$1"
    fi
}


cd $(dirname $0)
echo "installfiles for : $PRODUCT_MODULE_NAME"

echo "Install NSE target files"
installFile "Common.xcconfig" $PRODUCT_MODULE_NAME"NSE" "RiotNSE"
installFile "BuildSettings.swift" $PRODUCT_MODULE_NAME"/Config" "RiotNSE"

echo "Install Shared Extension target files"
installFile "Common.xcconfig" $PRODUCT_MODULE_NAME"ShareExtension" "RiotShareExtension" 
installFile "BuildSettings.swift" $PRODUCT_MODULE_NAME"/Config" "RiotShareExtension"

echo "Install AppIdentifiers Config file"
installFile "AppIdentifiers.xcconfig" $PRODUCT_MODULE_NAME"/Config" "/Config"

echo "Install AppIcon files"
installFile "AppIcon.appiconset" $PRODUCT_MODULE_NAME"/Assets/"$PRODUCT_MODULE_NAME"SharedImages.xcassets" "/Riot/Assets/SharedImages.xcassets"
installFile "TchapLogo.imageset" $PRODUCT_MODULE_NAME"/Assets/"$PRODUCT_MODULE_NAME"SharedImages.xcassets" "/Riot/Assets/SharedImages.xcassets"

cd -
