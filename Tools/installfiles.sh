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
BUILDING_PRODUCT="$BUNDLE_DISPLAY_NAME"
echo "installfiles for : $PRODUCT"

echo "Install NSE target files"
installFile "Common.xcconfig" $BUILDING_PRODUCT"NSE" "RiotNSE"
installFile "BuildSettings.swift" $BUILDING_PRODUCT"/Config" "RiotNSE"

echo "Install Shared Extension target files"
installFile "Common.xcconfig" $BUILDING_PRODUCT"ShareExtension" "RiotShareExtension" 
installFile "BuildSettings.swift" $BUILDING_PRODUCT"/Config" "RiotShareExtension"

echo "Install AppIdentifiers Config file"
installFile "AppIdentifiers.xcconfig" $BUILDING_PRODUCT"/Config" "/Config"

echo "Install AppIcon files"
installFile "AppIcon.appiconset" $BUILDING_PRODUCT"/Assets/"$BUILDING_PRODUCT"SharedImages.xcassets" "/Riot/Assets/SharedImages.xcassets"
installFile "TchapLogo.imageset" $BUILDING_PRODUCT"/Assets/"$BUILDING_PRODUCT"SharedImages.xcassets" "/Riot/Assets/SharedImages.xcassets"

cd -
