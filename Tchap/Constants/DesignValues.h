/*
 Copyright 2018 Vector Creations Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <MatrixKit/MatrixKit.h>

// @TODO: Support multiple theme (presently only one theme is supported)
#import "ThemeService.h"

/**
 Posted when the user interface theme has been changed.
 */
extern NSString * _Nonnull const kDesignValuesDidChangeThemeNotification;

#pragma mark - Tchap Colors
extern UIColor * _Nonnull kColorDarkBlue;
extern UIColor * _Nonnull kColorDarkGreyBlue;
extern UIColor * _Nonnull kColorLightNavy;
extern UIColor * _Nonnull kColorGreyishPurple;
extern UIColor * _Nonnull kColorWarmGrey;
extern UIColor * _Nonnull kColorLightGrey;
extern UIColor * _Nonnull kColorDarkGrey;
extern UIColor * _Nonnull kColorPaleGrey;
extern UIColor * _Nonnull kColorCoral;
extern UIColor * _Nonnull kColorPumpkinOrange;
extern UIColor * _Nonnull kColorJadeGreen;
extern UIColor * _Nonnull kColorGreyishBrown;
extern UIColor * _Nonnull kColorLightBlue;
extern UIColor * _Nonnull kColorVerySoftBlue;

#pragma mark - Tchap Theme Colors

#pragma mark Variant 1

// Status bar

extern UIStatusBarStyle kVariant1StatusBarStyle;

// Bar

extern UIColor * _Nonnull kVariant1BarBgColor;
extern UIColor * _Nonnull kVariant1BarTitleColor;
extern UIColor * _Nonnull kVariant1BarSubTitleColor;
extern UIColor * _Nonnull kVariant1BarActionColor;

// Button

extern UIColor * _Nonnull kVariant1ButtonBorderedTitleColor;
extern UIColor * _Nonnull kVariant1ButtonBorderedBgColor;
extern UIColor * _Nonnull kVariant1ButtonPlainTitleColor;
extern UIColor * _Nonnull kVariant1ButtonPlainBgColor;

// Body

extern UIColor * _Nonnull kVariant1PrimaryBgColor;
extern UIColor * _Nonnull kVariant1PrimaryTextColor;
extern UIColor * _Nonnull kVariant1PrimarySubTextColor;
extern UIColor * _Nonnull kVariant1PlaceholderTextColor;
extern UIColor * _Nonnull kVariant1SeparatorColor;
extern UIColor * _Nonnull kVariant1SecondaryBgColor;
extern UIColor * _Nonnull kVariant1SecondaryTextColor;
extern UIColor * _Nonnull kVariant1WarnTextColor;
extern UIColor * _Nonnull kVariant1PresenceIndicatorOnlineColor;
extern UIColor * _Nonnull kVariant1OverlayBackgroundColor;
extern UIColor * _Nonnull kVariant1BoxBgColor;
extern UIColor * _Nonnull kVariant1BoxTextColor;

#pragma mark Variant 2

// Status bar

extern UIStatusBarStyle kVariant2StatusBarStyle;

// Bar

extern UIColor * _Nonnull kVariant2BarBgColor;
extern UIColor * _Nonnull kVariant2BarTitleColor;
extern UIColor * _Nonnull kVariant2BarSubTitleColor;
extern UIColor * _Nonnull kVariant2BarActionColor;

// Button

extern UIColor * _Nonnull kVariant2ButtonBorderedTitleColor;
extern UIColor * _Nonnull kVariant2ButtonBorderedBgColor;
extern UIColor * _Nonnull kVariant2ButtonPlainTitleColor;
extern UIColor * _Nonnull kVariant2ButtonPlainBgColor;

// Body

extern UIColor * _Nonnull kVariant2PrimaryBgColor;
extern UIColor * _Nonnull kVariant2PrimaryTextColor;
extern UIColor * _Nonnull kVariant2PrimarySubTextColor;
extern UIColor * _Nonnull kVariant2PlaceholderTextColor;
extern UIColor * _Nonnull kVariant2SeparatorColor;
extern UIColor * _Nonnull kVariant2SecondaryBgColor;
extern UIColor * _Nonnull kVariant2SecondaryTextColor;
extern UIColor * _Nonnull kVariant2WarnTextColor;
extern UIColor * _Nonnull kVariant2PresenceIndicatorOnlineColor;
extern UIColor * _Nonnull kVariant2OverlayBackgroundColor;
extern UIColor * _Nonnull kVariant2BoxBgColor;
extern UIColor * _Nonnull kVariant2BoxTextColor;

/**
 `DesignValues` class manages the Tchap design parameters
 */
@interface DesignValues : NSObject

@end
