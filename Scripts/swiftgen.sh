SWIFTGEN_BIN="$PODS_ROOT/SwiftGen/bin/swiftgen"

if which $SWIFTGEN_BIN >/dev/null; then
	SRCDIR="$PROJECT_DIR/Tchap"

	$SWIFTGEN_BIN storyboards -t swift4  "$SRCDIR" --output "$SRCDIR/Constants/Storyboards.swift"	
	$SWIFTGEN_BIN strings -t flat-swift4 --param enumName="TchapL10n" "$SRCDIR/Assets/Localizations/fr.lproj/Tchap.strings" --output "$SRCDIR/Constants/Strings.swift"
	$SWIFTGEN_BIN xcassets -t swift4 "$SRCDIR/Assets/Images.xcassets" "$SRCDIR/Assets/SharedImages.xcassets" --output "$SRCDIR/Constants/Images.swift"
else
	echo "warning: SwiftGen not installed, download it from https://github.com/AliSoftware/SwiftGen"
fi
