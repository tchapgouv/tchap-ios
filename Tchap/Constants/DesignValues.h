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
extern NSString *const kDesignValuesDidChangeThemeNotification;

#pragma mark - Tchap Colors
extern UIColor *kColorDarkBlue;
extern UIColor *kColorDarkGreyBlue;
extern UIColor *kColorLightNavy;
extern UIColor *kColorGreyishPurple;
extern UIColor *kColorWarmGrey;
extern UIColor *kColorLightGrey;
extern UIColor *kColorDarkGrey;

#pragma mark - Tchap Theme Colors

#pragma mark Variant 1

// Status bar

extern UIStatusBarStyle kVariant1StatusBarStyle;

// Bar

extern UIColor *kVariant1BarBgColor;
extern UIColor *kVariant1BarTitleColor;
extern UIColor *kVariant1BarSubTitleColor;
extern UIColor *kVariant1BarActionColor;

// Button

extern UIColor *kVariant1ButtonBorderedTitleColor;
extern UIColor *kVariant1ButtonBorderedBgColor;
extern UIColor *kVariant1ButtonPlainTitleColor;
extern UIColor *kVariant1ButtonPlainBgColor;

// Body

extern UIColor *kVariant1PrimaryBgColor;
extern UIColor *kVariant1PrimaryTextColor;
extern UIColor *kVariant1PrimarySubTextColor;
extern UIColor *kVariant1PlaceholderTextColor;
extern UIColor *kVariant1SeparatorColor;
extern UIColor *kVariant1SecondaryBgColor;
extern UIColor *kVariant1SecondaryTextColor;
extern UIColor *kVariant1WarnTextColor;
extern UIColor *kVariant1PresenceIndicatorOnlineColor;
extern UIColor *kVariant1OverlayBackgroundColor;

#pragma mark Variant 2

// Status bar

extern UIStatusBarStyle kVariant2StatusBarStyle;

// Bar

extern UIColor *kVariant2BarBgColor;
extern UIColor *kVariant2BarTitleColor;
extern UIColor *kVariant2BarSubTitleColor;
extern UIColor *kVariant2BarActionColor;

// Button

extern UIColor *kVariant2ButtonBorderedTitleColor;
extern UIColor *kVariant2ButtonBorderedBgColor;
extern UIColor *kVariant2ButtonPlainTitleColor;
extern UIColor *kVariant2ButtonPlainBgColor;

// Body

extern UIColor *kVariant2PrimaryBgColor;
extern UIColor *kVariant2PrimaryTextColor;
extern UIColor *kVariant2PrimarySubTextColor;
extern UIColor *kVariant2PlaceholderTextColor;
extern UIColor *kVariant2SeparatorColor;
extern UIColor *kVariant2SecondaryBgColor;
extern UIColor *kVariant2SecondaryTextColor;
extern UIColor *kVariant2WarnTextColor;
extern UIColor *kVariant2PresenceIndicatorOnlineColor;
extern UIColor *kVariant2OverlayBackgroundColor;

/**
 `DesignValues` class manages the Tchap design parameters
 */
@interface DesignValues : NSObject

@end
