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

// @TODO: Remove this RiotDesignValues dependency
#import "RiotDesignValues.h"

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

#pragma mark - Tchap Theme Colors
extern UIColor *kVariant1PrimaryBgColor;
extern UIColor *kVariant1PrimaryTextColor;
extern UIColor *kVariant1PrimarySubTextColor;
extern UIColor *kVariant1PlaceholderTextColor;
extern UIColor *kVariant1ActionColor;
extern UIColor *kVariant1SecondaryBgColor;
extern UIColor *kVariant1SecondaryTextColor;

extern UIColor *kVariant2PrimaryBgColor;
extern UIColor *kVariant2PrimaryTextColor;
extern UIColor *kVariant2PrimarySubTextColor;
extern UIColor *kVariant2SecondaryTextColor;
extern UIColor *kVariant2PlaceholderTextColor;
extern UIColor *kVariant2ActionColor;
extern UIColor *kVariant2SecondaryBgColor;
extern UIColor *kVariant2SecondaryTextColor;

#pragma mark - Tchap Bar Style
extern UIStatusBarStyle kVariant1StatusBarStyle;
extern UIBarStyle kVariant1SearchBarStyle;
extern UIColor *kVariant1SearchBarTintColor;

extern UIStatusBarStyle kVariant2StatusBarStyle;
extern UIBarStyle kVariant2SearchBarStyle;
extern UIColor *kVariant2SearchBarTintColor;

/**
 `DesignValues` class manages the Tchap design parameters
 */
@interface DesignValues : NSObject

@end
